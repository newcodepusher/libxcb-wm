MAINTAINERCLEANFILES = Makefile.in

lib_LTLIBRARIES = libxcb-ewmh.la

xcbinclude_HEADERS = xcb_ewmh.h

AM_CFLAGS = $(CWARNFLAGS)

libxcb_ewmh_la_SOURCES = ewmh.c ewmh.c.m4 atomlist.m4 xcb_ewmh.h.m4
libxcb_ewmh_la_CPPFLAGS = $(XCB_CFLAGS) $(XPROTO_CFLAGS)
libxcb_ewmh_la_LIBADD = $(XCB_LIBS) $(XPROTO_LIBS)
libxcb_ewmh_la_LDFLAGS = -version-info 1:0:0

pkgconfig_DATA = xcb-ewmh.pc

EXTRA_DIST = xcb-ewmh.pc.in

BUILT_SOURCES = ewmh.c xcb_ewmh.h
CLEANFILES = $(BUILT_SOURCES)

ewmh.c: ewmh.c.m4 atomlist.m4
	$(M4) -I$(srcdir) $< >$@

xcb_ewmh.h: xcb_ewmh.h.m4 atomlist.m4
	$(M4) -I$(srcdir) $< >$@
