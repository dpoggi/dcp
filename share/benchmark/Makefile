INSTALL		?= install
MKDIR		?= mkdir -p
STRIP		?= strip

PREFIX		?= $(HOME)/.local

CPPFLAGS	+= -DNDEBUG
CFLAGS		+= -std=gnu11 -fno-common -Os -W -Wall -Werror -Wcast-qual -Wconversion -Wdeprecated -Wmissing-declarations -Wpointer-arith -Wstrict-prototypes -Wundef -Wunused-result -Wvla -Wwrite-strings -Wno-unknown-pragmas -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable
STRIPFLAGS	?= -p -s

SOURCES		:= $(wildcard *.c)
OBJECTS		:= $(SOURCES:%.c=%.o)
TARGET		:= monotime

.PHONY:		all install clean

all:		$(TARGET)

$(TARGET):	$(OBJECTS)

install:
	$(MKDIR) $(PREFIX)/bin
	$(INSTALL) -p $(TARGET) $(PREFIX)/bin
	$(STRIP) $(STRIPFLAGS) $(PREFIX)/bin/$(TARGET)

clean:
	$(RM) $(TARGET) $(OBJECTS)
