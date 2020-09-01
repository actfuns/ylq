.PHONY: all clean build jemalloc gdsl

include platform.mk

BUILD_PATH ?= .
LUA_CLIB_PATH ?= $(BUILD_PATH)/clualib
CSERVICE_PATH ?= $(BUILD_PATH)/cservice
INCLUDE_PATH ?= $(BUILD_PATH)/include
CLIB_PATH ?= $(BUILD_PATH)/clib

CFLAGS = -g3 -O2 -Wall -I$(LUA_INC) -Iskynet-src -I$(GDSL_INC) $(MYCFLAGS)

all : build

build:
	-mkdir $(LUA_CLIB_PATH)
	-mkdir $(CSERVICE_PATH)
	-mkdir $(INCLUDE_PATH)
	-mkdir $(CLIB_PATH)

# lua
LUA_STATICLIB := 3rd/lua/liblua.a
LUA_INC ?= 3rd/lua

$(LUA_STATICLIB) : 3rd/lua/**
	cd 3rd/lua && $(MAKE) MYCFLAGS="-g3 -O2 -fPIC -I../../skynet-src" $(PLAT)

# jemalloc
JEMALLOC_STATICLIB := 3rd/jemalloc/lib/libjemalloc_pic.a
JEMALLOC_INC := 3rd/jemalloc/include/jemalloc

all : jemalloc

MALLOC_STATICLIB := $(JEMALLOC_STATICLIB)

$(JEMALLOC_STATICLIB) : | 3rd/jemalloc/autogen.sh
	cd 3rd/jemalloc && ./autogen.sh --with-jemalloc-prefix=je_ --disable-valgrind --with-malloc-conf="background_thread:true,dirty_decay_ms:0,muzzy_decay_ms:0"
	cd 3rd/jemalloc && $(MAKE) CC=$(CC)

jemalloc : $(MALLOC_STATICLIB)

# gdsl
GDSL_STATICLIB := 3rd/gdsl/lib/libgdsl.a
GDSL_INC := 3rd/gdsl/include

all : gdsl

$(GDSL_STATICLIB) : | 3rd/gdsl/configure
	cd 3rd/gdsl && ./configure --prefix=$(PWD)/3rd/gdsl
	cd 3rd/gdsl && $(MAKE) CC=$(CC) && $(MAKE) install

gdsl : $(GDSL_STATICLIB)

# skynet
CSERVICE = snlua logger gate harbor
LUA_CLIB = skynet socketdriver bson mongo md5 netpack \
  clientsocket memory measure multicast \
  cluster crypt sharedata stm sproto lpeg \
  mysqlaux debugchannel cjson

SKYNET_SRC = skynet_main.c skynet_handle.c skynet_module.c skynet_mq.c \
  skynet_server.c skynet_start.c skynet_timer.c skynet_error.c \
  skynet_harbor.c skynet_env.c skynet_monitor.c skynet_socket.c socket_server.c \
  malloc_hook.c skynet_daemon.c skynet_log.c

all : \
  $(BUILD_PATH)/skynet \
  $(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(BUILD_PATH)/skynet : $(foreach v, $(SKYNET_SRC), skynet-src/$(v)) $(LUA_STATICLIB) $(MALLOC_STATICLIB) $(GDSL_STATICLIB)
	$(CC) $(CFLAGS) -o $@ -Wl,--whole-archive $^ -Wl,--no-whole-archive -I$(JEMALLOC_INC) $(LDFLAGS) $(EXPORT) $(SKYNET_LIBS) $(SKYNET_DEFINES)

define CSERVICE_TEMP
  $$(CSERVICE_PATH)/$(1).so : service-src/service_$(1).c | $$(CSERVICE_PATH)
	$$(CC) $$(CFLAGS) $$(SHARED) $$< -o $$@
endef

$(foreach v, $(CSERVICE), $(eval $(call CSERVICE_TEMP,$(v))))

$(LUA_CLIB_PATH)/skynet.so : lualib-src/lua-skynet.c lualib-src/lua-seri.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -Ilualib-src

$(LUA_CLIB_PATH)/socketdriver.so : lualib-src/lua-socket.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/bson.so : lualib-src/lua-bson.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/cjson.so: 3rd/lua-cjson/lua_cjson.c 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c
	install -p -m 0644 3rd/lua-cjson/*.h $(INCLUDE_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/mongo.so : lualib-src/lua-mongo.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

$(LUA_CLIB_PATH)/md5.so : 3rd/lua-md5/md5.c 3rd/lua-md5/md5lib.c 3rd/lua-md5/compat-5.2.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I3rd/lua-md5

$(LUA_CLIB_PATH)/netpack.so : lualib-src/lua-netpack.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/clientsocket.so : lualib-src/lua-clientsocket.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/memory.so : lualib-src/lua-memory.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/measure.so : lualib-src/lua-measure.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/multicast.so : lualib-src/lua-multicast.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/cluster.so : lualib-src/lua-cluster.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/crypt.so : lualib-src/lua-crypt.c lualib-src/lsha1.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/sharedata.so : lualib-src/lua-sharedata.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/stm.so : lualib-src/lua-stm.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/sproto.so : lualib-src/sproto/sproto.c lualib-src/sproto/lsproto.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -Ilualib-src/sproto

$(LUA_CLIB_PATH)/lpeg.so : 3rd/lpeg/lpcap.c 3rd/lpeg/lpcode.c 3rd/lpeg/lpprint.c 3rd/lpeg/lptree.c 3rd/lpeg/lpvm.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -I3rd/lpeg

$(LUA_CLIB_PATH)/mysqlaux.so : lualib-src/lua-mysqlaux.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@	

$(LUA_CLIB_PATH)/debugchannel.so : lualib-src/lua-debugchannel.c
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@	

clean :
	rm -f $(BUILD_PATH)/skynet $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so $(INCLUDE_PATH)/*.h $(CLIB_PATH)/*.so

cleanall: clean
ifneq (,$(wildcard 3rd/jemalloc/Makefile))
	cd 3rd/jemalloc && $(MAKE) clean
	rm -rf 3rd/jemalloc/lib
endif
ifneq (,$(wildcard 3rd/gdsl/Makefile))
	cd 3rd/gdsl && $(MAKE) clean
	rm -rf 3rd/gdsl/include
	rm -rf 3rd/gdsl/lib
endif
	cd 3rd/lua && $(MAKE) clean
