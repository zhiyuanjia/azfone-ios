## Process this file with automake to produce Makefile.in. -*-Makefile-*-

# $Id: Makefile.am,v 1.1.1.1 2014/11/13 04:07:32 khc Exp $

# Disable automatic dependency tracking if using other tools than gcc and gmake
#AUTOMAKE_OPTIONS = no-dependencies

if BUILD_VORBIS_PSY
  VPSY_LIB=$(top_builddir)/libspeex/libspeexdsp.la
else
  VPSY_LIB=
endif

INCLUDES = -I$(top_builddir) @OGG_CFLAGS@

man_MANS = speexenc.1 speexdec.1

EXTRA_DIST = $(man_MANS) getopt_win.h getopt.c getopt1.c wave_out.c wave_out.h skeleton.h

include_HEADERS = 
noinst_HEADERS = wav_io.h

bin_PROGRAMS = speexenc speexdec

speexenc_SOURCES = speexenc.c wav_io.c skeleton.c
speexenc_LDADD = $(top_builddir)/libspeex/libspeex.la $(top_builddir)/libspeex/libspeexdsp.la \
	$(OGG_LIBS)  @FFT_LIBS@	

speexdec_SOURCES = speexdec.c wav_io.c
speexdec_LDADD = $(top_builddir)/libspeex/libspeex.la $(top_builddir)/libspeex/libspeexdsp.la $(VPSY_LIB) \
	$(OGG_LIBS)  @FFT_LIBS@
