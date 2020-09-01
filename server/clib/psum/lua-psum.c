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
#include "psum.h"

#define check_psum(L, idx)\
    *(struct psum_space**)luaL_checkudata(L, idx, "psum_meta")

static void psum_debug_print(const char* s) {
    FILE *f = fopen("psum_debug.log", "a");
    if (f == NULL)
        return;
    fprintf(f, "debug: %s\n", s);
    fflush(f);
    fclose(f);
}

static int psum_gc(lua_State* L) {
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        return 0;
    }
    psum_release(psum);
    psum = NULL;
    return 0;
}

static int lpsum_create(lua_State* L){
    struct psum_space* psum = psum_create();
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: fail to create psum");
        return 2;
    }

    *(struct psum_space**)lua_newuserdata(L, sizeof(void*)) = psum;
    luaL_getmetatable(L, "psum_meta");
    lua_setmetatable(L, -2);
    return 1;
}

static void lpsum_resetdaobiao(lua_State* L,const char * dname){
    lua_pushstring(L, dname);
    lua_newtable(L);
    lua_rawset(L, LUA_REGISTRYINDEX);
}

static void lpsum_setdaobiao(lua_State* L,const char * dname,const uint8_t attr,double value){
    lua_pushstring(L, dname);
    lua_rawget(L, LUA_REGISTRYINDEX);
    lua_pushnumber(L, attr);
    lua_pushnumber(L, value);
    lua_rawset(L,-3);
    lua_pop(L,1);
}

static int lpsum_getdaobiao(lua_State* L,const char * dname,const uint8_t attr){
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

static int lpsum_receivedaobiao(lua_State* L,const char * dname){
    lpsum_resetdaobiao(L,dname);
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        uint32_t type2 = lua_type(L, -2);
        uint32_t type1 = lua_type(L, -1);
        if (type2 == LUA_TNUMBER && type1 == LUA_TNUMBER ){
            const uint8_t attr = (uint8_t)lua_tonumber(L,-2);
            double value = (double)lua_tonumber(L,-1);
            lpsum_setdaobiao(L,dname,attr,value);
        }
        else
            psum_debug_print("receive daobiao data err");
        lua_pop(L,1);
    }
    lua_pop(L,1);
    return 0;
}

static int lpsum_powerdata(lua_State* L){
    const char* dname = luaL_checkstring(L, 1);
    lpsum_receivedaobiao(L,dname);
    return 0;
}

static int lpsum_set(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    uint8_t module = (uint8_t)luaL_checknumber(L, 3);
    double v = (double)luaL_checknumber(L, 4);

    psum_update(psum, attr, module, v, false);
    return 0;
}

static int lpsum_multiset(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    uint8_t module = (uint8_t)luaL_checknumber(L, 2);
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        uint32_t type2 = lua_type(L, -2);
        uint32_t type1 = lua_type(L, -1);
        if (type2 == LUA_TNUMBER && type1 == LUA_TNUMBER ){
            const uint8_t attr = (uint8_t)lua_tonumber(L,-2);
            double v = (double)lua_tonumber(L,-1);
            psum_update(psum, attr, module, v, false);
        }
        else
            psum_debug_print("multiset data err");
        lua_pop(L,1);
    }
    lua_pop(L,1);
    return 0;
}

static int lpsum_add(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    uint8_t module = (uint8_t)luaL_checknumber(L, 3);
    double v = (double)luaL_checknumber(L, 4);

    psum_update(psum, attr, module, v, true);
    return 0;
}

static int lpsum_seteppower(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    double v = (double)luaL_checknumber(L, 2);
    psum_seteppower(psum, v);
    return 0;
}

static int lpsum_getbaseratio(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    double result = psum_getbaseratio(psum,attr);
    lua_pushnumber(L, result);
    return 1;
}

static int lpsum_getattradd(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    double result = psum_getattradd(psum,attr);
    lua_pushnumber(L, result);
    return 1;
}

static int lpsum_getattr(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    const uint8_t attr = (uint8_t)luaL_checknumber(L, 2);
    double result = psum_getattr(psum,attr);
    lua_pushnumber(L, result);
    return 1;
}

static int lpsum_getpower(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    double result = psum_getpower(psum);
    if (result != -1){
        lua_pushnumber(L, result);
        return 1;
    }
    const char* dname = luaL_checkstring(L, 2);
    int i=0;
    result = 0;
    for(;i<PLAYER_ATTR_CNT;i++){
        double mul = lpsum_getdaobiao(L,dname,i)/(100.0);
        double v = psum_getattr(psum,i);
        result = result + v * mul;
    }
    result = floor(result + psum_geteppower(psum) - lpsum_getdaobiao(L, dname, 10));
    psum_setpower(psum,result);
    lua_pushnumber(L, result);
    return 1;
}

static int lpsum_clear(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    uint8_t module = (uint8_t)luaL_checknumber(L, 2);
    psum_clear(psum, module);
    return 0;
}

static int lpsum_print(lua_State* L){
    struct psum_space* psum = check_psum(L, 1);
    if (psum == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "error: psum not args");
        return 2;
    }
    uint8_t module = (uint8_t)luaL_checknumber(L, 2);
    psum_print(psum, module);
    return 0;
}

static const struct luaL_Reg lpsum_methods [] = {
    { "set" , lpsum_set },
    { "multiset" , lpsum_multiset },
    { "add" , lpsum_add },
    { "clear" , lpsum_clear },
    { "seteppower" , lpsum_seteppower },
    { "getattr" , lpsum_getattr},
    { "getbaseratio" , lpsum_getbaseratio},
    { "getattradd" , lpsum_getattradd},
    { "getpower" , lpsum_getpower},
    { "print" , lpsum_print },
    {NULL, NULL},
};

static const struct luaL_Reg l_methods[] = {
    { "lpsum_create" , lpsum_create },
    { "lpsum_powerdata" , lpsum_powerdata },
    {NULL, NULL},
};

int luaopen_lpsum(lua_State* L) {
    luaL_checkversion(L);

    luaL_newmetatable(L, "psum_meta");

    lua_newtable(L);
    luaL_setfuncs(L, lpsum_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, psum_gc);
    lua_setfield(L, -2, "__gc");

    luaL_newlib(L, l_methods);

    return 1;
}
