#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#include <lua.h>
#include <lauxlib.h>
#include <gdsl/gdsl_types.h>
#include <gdsl/gdsl_list.h>

#include "skynet_malloc.h"
#include "sum.h"

#define check_sum(L, idx)\
    *(struct sum_space**)luaL_checkudata(L, idx, "sum_meta")

static void sum_debug_print(const char* s) {
    FILE *f = fopen("sum_debug.log", "a");
    if (f == NULL)
        return;
    fprintf(f, "debug: %s\n", s);
    fflush(f);
    fclose(f);
}

static int sum_gc(lua_State* L) {
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        return 0;
    }
    sum_release(sum);
    sum = NULL;
    return 0;
}

static int lsum_create(lua_State* L){
    struct sum_space* sum = sum_create();
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: fail to create sum");
        return 2;
    }

    *(struct sum_space**)lua_newuserdata(L, sizeof(void*)) = sum;
    luaL_getmetatable(L, "sum_meta");
    lua_setmetatable(L, -2);
    return 1;
}

static void lsum_resetdaobiao(lua_State* L,const char * dname){
    lua_pushstring(L, dname);
    lua_newtable(L);
    lua_rawset(L, LUA_REGISTRYINDEX);
}

static void lsum_setdaobiao(lua_State* L,const char * dname,const uint8_t attr,double value){
    lua_pushstring(L, dname);
    lua_rawget(L, LUA_REGISTRYINDEX);
    lua_pushnumber(L, attr);
    lua_pushnumber(L, value);
    lua_rawset(L,-3);
    lua_pop(L,1);
}

static int lsum_getdaobiao(lua_State* L,const char * dname,const uint8_t attr){
    lua_pushstring(L, dname);
    lua_rawget(L, LUA_REGISTRYINDEX);
    lua_pushnumber(L, attr);
    lua_rawget(L, -2);
    if (lua_isnil(L, -1)){
        lua_pop(L,2);
        return 0;
    }
    double v = lua_tonumber(L,-1);
    lua_pop(L,2);
    return v;
}

static int lsum_receivedaobiao(lua_State* L,const char * dname){
    lsum_resetdaobiao(L,dname);
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        uint32_t type2 = lua_type(L, -2);
        uint32_t type1 = lua_type(L, -1);
        if (type2 == LUA_TNUMBER && type1 == LUA_TNUMBER ){
            const uint8_t attr = (uint8_t)lua_tonumber(L,-2);
            double value = (double)lua_tonumber(L,-1);
            lsum_setdaobiao(L,dname,attr,value);
        }
        else
            sum_debug_print("receive daobiao data err");
        lua_pop(L,1);
    }
    lua_pop(L,1);
    return 0;
}

static int lsum_powerdata(lua_State* L){
    const char* dname = luaL_checkstring(L, 1);
    lsum_receivedaobiao(L,dname);
    return 0;
}

static int lsum_set(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    uint8_t module = (uint8_t)luaL_checknumber(L, 3);
    double v = (double)luaL_checknumber(L, 4);

    sum_update(sum, attr, module, v, false);
    return 0;
}

static int lsum_add(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    uint8_t module = (uint8_t)luaL_checknumber(L, 3);
    double v = (double)luaL_checknumber(L, 4);

    sum_update(sum, attr, module, v, true);
    return 0;
}

static int lsum_setsklv(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    double v = (double)luaL_checknumber(L, 2);
    sum_setsklv(sum, v);
    return 0;
}

static int lsum_getbaseratio(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    double result = sum_getbaseratio(sum,attr);
    lua_pushnumber(L, result);
    return 1;
}

static int lsum_getattradd(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    double result = sum_getattradd(sum,attr);
    lua_pushnumber(L, result);
    return 1;
}

static int lsum_getattr(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    double result = sum_getattr(sum,attr);
    lua_pushnumber(L, result);
    return 1;
}

static int lsum_getpower(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    double result = sum_getpower(sum);
    if (result != -1){
        lua_pushnumber(L, result);
        return 1;
    }
    const char* dname = luaL_checkstring(L, 2);
    int i=0;
    result = 0;
    for(;i<PARTNER_ATTR_CNT-1;i++){
        double mul = lsum_getdaobiao(L,dname,i)/(100.0);
        double v = sum_getattr(sum,i);
        result = result + v * mul;
    }
    result = floor(result + sum_getsklv(sum)*lsum_getdaobiao(L,dname,10));
    result = floor(result - lsum_getdaobiao(L, dname, 11));
    sum_setpower(sum,result);
    lua_pushnumber(L, result);
    return 1;
}

static int lsum_clear(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    uint8_t module = (uint8_t)luaL_checknumber(L, 2);
    sum_clear(sum, module);
    return 0;
}

static int lsum_print(lua_State* L){
    struct sum_space* sum = check_sum(L, 1);
    if (sum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: sum not args");
        return 2;
    }
    uint8_t module = (uint8_t)luaL_checknumber(L, 2);
    sum_print(sum, module);
    return 0;
}

static const struct luaL_Reg lsum_methods [] = {
    { "set" , lsum_set },
    { "add" , lsum_add },
    { "clear" , lsum_clear },
    { "setsklv" , lsum_setsklv },
    { "getattr" , lsum_getattr},
    { "getbaseratio" , lsum_getbaseratio},
    { "getattradd" , lsum_getattradd},
    { "getpower" , lsum_getpower},
    { "print" , lsum_print },
    {NULL, NULL},
};

static const struct luaL_Reg l_methods[] = {
    { "lsum_create" , lsum_create },
    { "lsum_powerdata" , lsum_powerdata },
    {NULL, NULL},
};

int luaopen_lsum(lua_State* L) {
    luaL_checkversion(L);

    luaL_newmetatable(L, "sum_meta");

    lua_newtable(L);
    luaL_setfuncs(L, lsum_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, sum_gc);
    lua_setfield(L, -2, "__gc");

    luaL_newlib(L, l_methods);

    return 1;
}
