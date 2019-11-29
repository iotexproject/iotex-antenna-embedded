AR		= $(CROSS_COMPILE)ar
CC		= $(CROSS_COMPILE)gcc
CXX		= $(CROSS_COMPILE)g++
STRIP	= $(CROSS_COMPILE)strip
#CFLAGS	= -Wall -g -fPIC -I../trezor-crypto
CFLAGS	= -Wall -g -fPIC -I./src/crypto
CXXFLAGS	= -Wall -g -fPIC -D_DEBUG_JSON_PARSE
LDSHFLAGS	= -rdynamic -shared -fPIC -lcurl
#LDSHFLAGS	= -rdynamic -shared -fPIC -lcurl -L. -ltrezor-crypto
ARFLAGS		= rcv
CODE_STYLE	= astyle --align-pointer=name --align-reference=name --suffix=none --break-blocks --pad-oper --pad-header --break-blocks --keep-one-line-blocks --indent-switches --indent=spaces

SOURCES	= $(wildcard src/*.c) $(wildcard src/crypto/*.c)
HEADERS	= $(wildcard src/*.h) $(wildcard src/crypto/*.h)
OBJECTS	= $(SOURCES:.c=.o) 
TARGETS = libiotexemb.a libiotexemb.so

SCRIPTS=scripts
EXAMPLE=example
UNITTEST=unittest
LIBNAME=libiotexemb
PROJECT_NAME=iotex-antenna-embedded
RELEASE_TARGET_DIR=objs/$(PROJECT_NAME)

.PHONY:all clean distclean test example install help style statistics no_int128 release
.SILENT: clean

all:$(TARGETS)

clean:
	find . -name "*.o" | xargs rm -f
	find . -name "depend.d" | xargs rm -f 
	$(RM) -rf *.o *.a *.so *~ a.out depend.d $(TARGETS) build

distclean:
	make clean
	make clean -C $(UNITTEST)

release:$(TARGETS)
	@$(STRIP) $(LIBNAME).so
	@$(STRIP) $(LIBNAME).a
	@ls *.so *.a -lh
	@mkdir -p $(RELEASE_TARGET_DIR)
	@mkdir -p $(RELEASE_TARGET_DIR)
	@cp README.md $(RELEASE_TARGET_DIR)
	@cp -a $(EXAMPLE) $(RELEASE_TARGET_DIR)
	@cp $(SCRIPTS)/env.sh $(RELEASE_TARGET_DIR)
	@cp src/iotex_emb.h src/u128.h $(RELEASE_TARGET_DIR)
	@cp $(LIBNAME)*.so $(LIBNAME).a $(RELEASE_TARGET_DIR)
	@cd objs && tar cvjf $(PROJECT_NAME).tbz2 $(PROJECT_NAME)

test:$(TARGETS)
	make -C $(UNITTEST)

example:$(TARGETS)
	make -C $(EXAMPLE)

unittest:test
	make -C $(SCRIPTS)

no_int128:
	@make clean && make CFLAGS="-Wall -g -fPIC -D_DEBUG_JSON_PARSE_ -D_NO_128INT_"

style:
	@find -regex '.*/.*\.\(c\|cpp\|h\)$$' | xargs $(CODE_STYLE)

statistics:
	@printf "Header:"
	@find -regex '.*/.*\.\(h\)$$' -not -path "./unittest/*" | xargs wc -l | tail -n 1 | awk '{print $$1}'

	@printf "Source:"
	@find -regex '.*/.*\.\(c\|cpp\)$$' -not -path "./unittest/*" | xargs wc -l | tail -n 1 | awk '{print $$1}'

	@printf "Unittest:"
	@find ./unittest -regex '.*/.*\.\(c\|cpp\)$$' | xargs wc -l | tail -n 1 | awk '{print $$1}'

install:$(TARGETS)
	@echo "Install libiotexemb lib..."
	@mkdir -p $(LOCAL_PACK_PATH)/$(LIB_PATH)
	@cp libiotexemb.so $(LOCAL_PACK_PATH)/$(LIB_PATH)


libiotexemb.a:$(OBJECTS)
	$(AR) $(ARFLAGS) $@ $^

libiotexemb.so:$(OBJECTS)
	$(CC) $(LDSHFLAGS) -o $@ $^

depend.d:$(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -MM $^ > $@

-include depend.d
