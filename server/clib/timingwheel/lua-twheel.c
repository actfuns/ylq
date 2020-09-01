/**
 *
 * Copyright (C) 2015 by David Lin
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALING IN
 * THE SOFTWARE.
 *
 */

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>

#include <lua.h>
#include <lauxlib.h>

#include "twheel.h"

#define check_timer(L, idx)\
    *(struct TimeWheel**)luaL_checkudata(L, idx, "timer_meta")

static void
my_callback(void *ud, uint64_t handle) {
    lua_State* L = (lua_State*)ud;
    lua_pushinteger(L, handle);
    uint32_t iLen = lua_rawlen(L, -2);
    lua_rawseti(L, -2, iLen + 1);
}

static int timer_gc(lua_State* L) {
    struct TimeWheel* timer = check_timer(L, 1);
    if (timer == NULL) {
        return 0;
    }
    timewheel_release(timer);
    timer = NULL;
    return 0;
}

static int ltimer_create(lua_State* L){
    uint64_t t = luaL_checkinteger(L, 1);

    struct TimeWheel* timer = timewheel_create(t);
    if (timer == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: fail to create timer");
        return 2;
    }

    *(struct TimeWheel**)lua_newuserdata(L, sizeof(void*)) = timer;
    luaL_getmetatable(L, "timer_meta");
    lua_setmetatable(L, -2);
    return 1;
}

static int ltimer_update(lua_State* L){
    struct TimeWheel* timer = check_timer(L, 1);
    if (timer == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: timer not args");
        return 2;
    }
    uint64_t t = luaL_checkinteger(L, 2);

    timewheel_update(timer, t, my_callback, (void*)L);
    return 0;
}

static int ltimer_add_time(lua_State* L){
    struct TimeWheel* timer = check_timer(L, 1);
    if (timer == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: timer not args");
        return 2;
    }

    uint64_t handle = luaL_checkinteger(L, 2);
    uint32_t delay = luaL_checkinteger(L, 3);

    timewheel_add_time(timer, handle, delay);
    return 0;
}

static const struct luaL_Reg ltimer_methods [] = {
    { "ltimer_update" , ltimer_update },
    { "ltimer_add_time" , ltimer_add_time },
    {NULL, NULL},
};

static const struct luaL_Reg l_methods[] = {
    { "ltimer_create" , ltimer_create },
    {NULL, NULL},
};

int luaopen_ltimer(lua_State* L) {
    luaL_checkversion(L);

    luaL_newmetatable(L, "timer_meta");

    lua_newtable(L);
    luaL_setfuncs(L, ltimer_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, timer_gc);
    lua_setfield(L, -2, "__gc");

    luaL_newlib(L, l_methods);

    return 1;
}
