#include <lua.h>
#include <lauxlib.h>

#include "skynet.h"

int
luaopen_skynetpb_c(lua_State *L) {
	// read skynet env "proto"
	struct pbc_env * env = NULL;
	const char * protoenv = skynet_command(NULL, "GETENV","protoenv");
	if (protoenv == NULL)
		return luaL_error(L, "Can't GETENV protoenv");
	sscanf(protoenv,"%p",&env);
	if (env == NULL) {
		return luaL_error(L, "Invalid protoenv %s", env);
	}

//	struct pbc_env * env = pbc_new();
	lua_pushlightuserdata(L, env);
    printf("================luaopen skynetpb_c, <%p>\r\n", env);
    lua_setfield(L, LUA_REGISTRYINDEX, "PROTOBUF_ENV");  

	return 0;
}


