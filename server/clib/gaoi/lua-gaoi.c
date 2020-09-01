#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>

#include "skynet_malloc.h"
#include "gaoi.h"

#define check_aoi(L, idx)\
    *(struct aoi_space**)luaL_checkudata(L, idx, "gaoi_meta")

static void my_callback(void *ud, uint32_t* le, uint32_t le_n, uint32_t* ll, uint32_t ll_n) {
    lua_State* L = (lua_State*)ud;
    uint32_t i;

    i = 0;
    lua_createtable(L, le_n, 0);
    while (i < le_n) {
        lua_pushinteger(L, le[i]);
        i++;
        lua_rawseti(L, -2, i);
    }

    i = 0;
    lua_createtable(L, ll_n, 0);
    while (i < ll_n) {
        lua_pushinteger(L, ll[i]);
        i++;
        lua_rawseti(L, -2, i);
    }
}

static void * my_alloc(void * ud, void *ptr, size_t sz) {
    if (ptr == NULL) {
        void *p = skynet_malloc(sz);
        return p;
    }
    skynet_free(ptr);
    return NULL;
}

static int gaoi_gc(lua_State* L) {
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        return 0;
    }
    AoiRelease(oAoi);
    oAoi = NULL;
    return 0;
}

static int CreateSpace(lua_State* L){
    uint16_t iMaxX = luaL_checkinteger(L, 1);
    uint16_t iMaxY = luaL_checkinteger(L, 2);
    uint8_t iGridX = luaL_checkinteger(L, 3);
    uint8_t iGridY = luaL_checkinteger(L, 4);

    struct aoi_space* oAoi = AoiCreateSpace(my_alloc, NULL, iMaxX, iMaxY, iGridX, iGridY);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "CreateSpace error: fail to create aoi");
        return 2;
    }

    *(struct aoi_space**)lua_newuserdata(L, sizeof(void*)) = oAoi;
    luaL_getmetatable(L, "gaoi_meta");
    lua_setmetatable(L, -2);
    return 1;
}

static int CreateObject(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "CreateObject error: aoi not args");
        return 2;
    }

    uint32_t iEid = luaL_checkinteger(L, 2);
    uint8_t iType = luaL_checkinteger(L, 3);
    uint8_t iAcType = luaL_checkinteger(L, 4);
    uint8_t iWeight = luaL_checkinteger(L, 5);
    uint16_t iLimit = luaL_checkinteger(L, 6);
    float fX = luaL_checknumber(L, 7);
    float fY = luaL_checknumber(L, 8);

    AoiCreateObject(oAoi, (void*)L, my_callback, iEid, iType, iAcType, iWeight, iLimit, fX, fY);

    return 2;
}

static int RemoveObject(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "RemoveObject error: aoi not args");
        return 2;
    }

    uint32_t iEid = luaL_checkinteger(L, 2);

    AoiRemoveObject(oAoi, (void*)L, my_callback, iEid);

    return 2;
}

static int UpdateObjectPos(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "UpdateObjectPos error: aoi not args");
        return 2;
    }

    uint32_t iEid = luaL_checkinteger(L, 2);
    float fX = luaL_checknumber(L, 3);
    float fY = luaL_checknumber(L, 4);
    bool bForce = lua_toboolean(L, 5);

    AoiUpdateObjectPos(oAoi, (void*)L, my_callback, iEid, fX, fY, bForce, true);

    return 2;
}

static int UpdateObjectWeight(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "UpdateObjectWeight error: aoi not args");
        return 2;
    }

    uint32_t iEid = luaL_checkinteger(L, 2);
    uint8_t iWeight = luaL_checkinteger(L, 3);

    AoiUpdateObjectWeight(oAoi, (void*)L, my_callback, iEid, iWeight);

    return 2;
}

static int GetView(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "GetView error: aoi not args");
        return 2;
    }

    uint32_t iEid = luaL_checkinteger(L, 2);
    uint8_t iType = luaL_checkinteger(L, 3);

    uint32_t lOut[2048];
    uint32_t iOut = 0;
    AoiGetView(oAoi, iEid, iType, lOut, 2048, &iOut);

    uint32_t i = 0;
    lua_createtable(L, iOut, 0);
    while (i < iOut) {
        lua_pushinteger(L, lOut[i]);
        i++;
        lua_rawseti(L, -2, i);
    }
    return 1;
}

static void my_recive(void *ud, uint32_t* m, uint8_t *l) {
    lua_State* L = (lua_State*)ud;
    lua_pushnil(L);
    while (lua_next(L, -2) != 0) {
        uint32_t type2 = lua_type(L, -2);
        uint32_t type1 = lua_type(L, -1);
        if (type2 == LUA_TNUMBER && type1 == LUA_TNUMBER ){
            uint32_t eid = (uint32_t)lua_tonumber(L,-2);
            uint8_t pos = (uint8_t)lua_tonumber(L,-1);
            if ( pos >= 1 && pos <= 5){
                m[pos-1] = eid;
                if (pos > *l){
                    *l = pos;
                }
            }
        }
        lua_pop(L,1);
    }
    lua_pop(L,1);
}

static int CreateSceneTeam(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "CreateSceneTeam error: aoi not args");
        return 2;
    }
    uint32_t iEid = luaL_checkinteger(L, 2);
    AoiCreateTeam(oAoi, (void*)L, my_callback, my_recive, iEid);

    return 2;
}

static int RemoveSceneTeam(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "RemoveSceneTeam error: aoi not args");
        return 2;
    }
    uint32_t iEid = luaL_checkinteger(L, 2);
    AoiRemoveTeam(oAoi, iEid);

    return 0;
}

static int UpdateSceneTeam(lua_State* L){
    struct aoi_space* oAoi = check_aoi(L, 1);
    if (oAoi == NULL) {
        lua_pushnil(L);
        lua_pushstring(L, "UpdateSceneTeam error: aoi not args");
        return 2;
    }
    uint32_t iEid = luaL_checkinteger(L, 2);
    AoiUpdateTeam(oAoi, (void*)L, my_callback, my_recive, iEid);

    return 2;
}

static const struct luaL_Reg gaoi_methods [] = {
    {"CreateObject" , CreateObject },
    {"RemoveObject", RemoveObject},
    {"UpdateObjectPos" , UpdateObjectPos },
    {"UpdateObjectWeight", UpdateObjectWeight},
    {"GetView", GetView},
    {"CreateSceneTeam" , CreateSceneTeam },
    {"RemoveSceneTeam" , RemoveSceneTeam },
    {"UpdateSceneTeam" , UpdateSceneTeam },
    {NULL, NULL},
};

static const struct luaL_Reg l_methods[] = {
    { "CreateSpace" , CreateSpace },
    {NULL, NULL},
};

int luaopen_gaoi_core(lua_State* L) {
    luaL_checkversion(L);

    luaL_newmetatable(L, "gaoi_meta");

    lua_newtable(L);
    luaL_setfuncs(L, gaoi_methods, 0);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gaoi_gc);
    lua_setfield(L, -2, "__gc");

    luaL_newlib(L, l_methods);

    return 1;
}
