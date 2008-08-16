#include "cg_local.h"
#include "../lua-src/lfs.c"

lua_State *L;

int samey = 0;
char *samey2 = "";

void qlua_clearfunc(lua_State *L, int ref) {
	if(ref != 0) {
		lua_unref(L,ref);
	}
}

int qlua_storefunc(lua_State *L, int i, int ref) {
	if(lua_type(L,i) == LUA_TFUNCTION) {
		if(ref != 0) lua_unref(L,ref);
		ref = luaL_ref(L, LUA_REGISTRYINDEX);
	}
	return ref;
}

qboolean qlua_getstored(lua_State *L, int ref) {
	if(ref != 0) {
		lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
		return qtrue;
	}
	return qfalse;
}

int message(lua_State *L) {
	const char *msg = "";

	if(lua_gettop(L) > 0) {
		msg = lua_tostring(L,1);
		if(msg) {
			CG_Printf(msg);
		}
	}
	return 0;
}

int bitwiseAnd(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		lua_pushinteger(L,a & b);
		return 1;
	}
	return 0;
}

int bitwiseOr(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		lua_pushinteger(L,a | b);
		return 1;
	}
	return 0;
}

int bitwiseShift(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		if(b > 0) {
			lua_pushinteger(L,a >> b);
		} else if(b < 0) {
			b = -b;
			lua_pushinteger(L,a << b);
		} else {
			lua_pushinteger(L,a);
		}
		return 1;
	}
	return 0;
}

int bitwiseXor(lua_State *L) {
	int a,b;
	if(lua_gettop(L) == 2) {
		a = lua_tointeger(L,1);
		b = lua_tointeger(L,2);
		lua_pushinteger(L,a ^ b);
		return 1;
	}
	return 0;
}

void error (lua_State *L, const char *fmt, ...) {
	va_list		argptr;
	char		text[4096];

	va_start (argptr, fmt);
	vsprintf (text, fmt, argptr);
	va_end (argptr);

	if(samey2 == text) {
		samey++;
	} else {
		samey2 = text;
		samey = 0;
	}

	if(samey < 3) {
		CG_Printf( "%s%s%s\n",S_COLOR_RED,"CL_LUA_ERROR: ",text );
	}
}

void qlua_gethook(lua_State *L, const char *hook) {
	if(hook != NULL) {
		lua_getglobal(L, "CallHook");
		lua_pushstring(L, hook);
	}
}

void qlua_pcall(lua_State *L, int nargs, int nresults, qboolean washook) {
	if(washook) nargs++;
	if(lua_pcall(L,nargs,nresults,0) != 0) 
		error(L, lua_tostring(L, -1));
}

int qlua_runstr(lua_State *L) {
	const char *str = "";

	if(lua_gettop(L) > 0) {
		if(lua_type(L,1) == LUA_TSTRING) {
			str = lua_tostring(L,1);

			if(luaL_loadstring(L,str) || lua_pcall(L, 0, 0, 0)) {
				lua_error(L);
				return 1;
			}
		}
	}
	return 0;
}

qboolean FS_doScript( const char *filename ) {
	if(luaL_loadfile(L,filename) || lua_pcall(L, 0, 0, 0)) {
		return qfalse;
	}

	/*char		text[20000];
	fileHandle_t	f;
	int			len;

	

	len = trap_FS_FOpenFile( filename, &f, FS_READ );
	if ( len <= 0 ) {
		G_Printf( "^1Unable to find file %s.\n", filename );
		return qfalse;
	}
	if ( len >= sizeof( text ) - 1 ) {
		G_Printf( "^1File %s is too long.\n", filename );
		return qfalse;
	}
	trap_FS_Read( text, len, f );
	text[len] = 0;
	trap_FS_FCloseFile( f );

	if(luaL_loadstring(L,text) || lua_pcall(L, 0, 0, 0)) {
        error(L, lua_tostring(L, -1));
	}*/

	return qtrue;
}

int qlua_includefile(lua_State *L) {
	const char *filename = "";

	luaL_checktype(L,1,LUA_TSTRING);

	lua_pushboolean(L,0);
	lua_setglobal(L,"SERVER");
	lua_pushboolean(L,1);
	lua_setglobal(L,"CLIENT");

	if(lua_gettop(L) > 0) {
		filename = lua_tostring(L,1);
		if(!FS_doScript(filename)) {
			lua_error(L);
			return 1;
		}
	}
	return 0;
}


void InitClientLua( void ) {
	CloseClientLua();
	L = lua_open();

	CG_Printf("-----Initializing ClientSide Lua-----\n");

	lua_pushboolean(L,0);
	lua_setglobal(L,"SERVER");
	lua_pushboolean(L,1);
	lua_setglobal(L,"CLIENT");

	luaL_openlibs(L);
	luaopen_lfs(L);

	lua_register(L,"print",message);
	lua_register(L,"bitAnd",bitwiseAnd);
	lua_register(L,"bitOr",bitwiseOr);
	lua_register(L,"bitXor",bitwiseXor);
	lua_register(L,"bitShift",bitwiseShift);
	lua_register(L,"include",qlua_includefile);
	lua_register(L,"runString",qlua_runstr);

	CG_Printf("----------------Done-----------------\n");
}

void DoLuaInit( void ) {
	//C:/Quake3/luamod_src/code/debug
	//if(luaL_loadfile(L,"lua/init.lua") || lua_pcall(L, 0, 0, 0)) {
    //    error(L, lua_tostring(L, -1));
	//}
	if(!FS_doScript("lua/cl_init.lua")) {
		error(L, lua_tostring(L, -1));
	}
}

void DoLuaIncludes( void ) {
	//C:/Quake3/luamod_src/code/debug
	//if(luaL_loadfile(L,"lua/includes/init.lua") || lua_pcall(L, 0, 0, 0)) {
    //    error(L, lua_tostring(L, -1));
	//}
	if(!FS_doScript("lua/includes/cl_init.lua")) {
		error(L, lua_tostring(L, -1));
	}
}

lua_State *GetClientLuaState( void ) {
	return L;
}

void CloseClientLua( void ) {
	if(L != NULL) {
		lua_close(L);

		CG_Printf("----ClientSide Lua ShutDown-----!\n");

		L = NULL;
	}
}