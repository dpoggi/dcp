INSTALL		?= install -p
MKDIR		?= mkdir -p

ifeq ($(shell uname -s),Darwin)
CODESIGN        ?= codesign -f -v
IDENTITY        ?= $(shell echo $${EXPANDED_CODE_SIGN_IDENTITY:-$${CODE_SIGN_IDENTITY}})
STRIP		?= strip -rSTx
else
STRIP		?= strip -ps
endif

ifeq ($(shell id -u),0)
PREFIX		?= /usr/local
else
PREFIX		?= $(HOME)/.local
endif

override CPPFLAGS	:= -DNDEBUG -D_FORTIFY_SOURCE=2 $(CPPFLAGS)
override CFLAGS		:= -std=gnu11 -flto -fPIE -fstack-protector -fno-common -Os -W -Wall -Wextra -Wcast-qual -Wconversion -Wdeprecated -Wmissing-declarations -Wpointer-arith -Wstrict-prototypes -Wundef -Wunused-result -Wvla -Wwrite-strings -Wno-unknown-pragmas -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable $(CFLAGS)
override LDFLAGS	:= -flto -fPIE -Xlinker -pie $(LDFLAGS)

override SOURCES	:= $(wildcard *.c)
override OBJECTS	:= $(SOURCES:%.c=%.o)
override TARGET		:= monotime

.PHONY:		all clean install

all:		$(TARGET)

$(TARGET):	$(OBJECTS)

clean:
	$(RM) $(TARGET) $(OBJECTS)

install:
	$(MKDIR) $(PREFIX)/bin
	$(INSTALL) $(TARGET) $(PREFIX)/bin
	$(STRIP) $(PREFIX)/bin/$(TARGET)
ifeq ($(shell uname -s),Darwin)
ifneq ($(IDENTITY),)
	$(CODESIGN) -s $(IDENTITY) $(PREFIX)/bin/$(TARGET)
endif
endif
