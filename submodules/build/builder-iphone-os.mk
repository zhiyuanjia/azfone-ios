############################################################################
# builder-generic.mk
# Copyright (C) 2009  Belledonne Communications,Grenoble France
#
############################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
############################################################################

host?=armv7-apple-darwin
config_site:=iphone-config.site
library_mode:= --disable-shared --enable-static
linphone_configure_controls = \
				--with-readline=none  \
				--enable-gtk_ui=no \
				--enable-console_ui=no \
				--enable-bellesip \
				--with-gsm=$(prefix) \
				--with-srtp=$(prefix) \
				--with-antlr=$(prefix) \
				--disable-strict \
				--disable-nls \
				--disable-theora \
				--disable-sdl \
				--disable-x11 \
				--disable-tutorials \
				--disable-tools \
				--enable-msg-storage=yes


#path
BUILDER_SRC_DIR?=$(shell pwd)/../
ifeq ($(enable_debug),yes)
BUILDER_BUILD_DIR?=$(shell pwd)/../build-$(host)-debug
linphone_configure_controls += CFLAGS="-g"
prefix?=$(BUILDER_SRC_DIR)/../liblinphone-sdk/$(host)-debug
else
BUILDER_BUILD_DIR?=$(shell pwd)/../build-$(host)
prefix?=$(BUILDER_SRC_DIR)/../liblinphone-sdk/$(host)
endif

LINPHONE_SRC_DIR=$(BUILDER_SRC_DIR)/linphone
LINPHONE_BUILD_DIR=$(BUILDER_BUILD_DIR)/linphone
LINPHONE_IPHONE_VERSION=$(shell git describe --always)

all: build-linphone build-msilbc build-msamr build-msx264 build-mssilk build-msbcg729 build-mswebrtc build-msopenh264

# setup the switches that might trigger a linphone reconfiguration

enable_gpl_third_parties?=yes
enable_ffmpeg?=yes
enable_zrtp?=yes

SWITCHES:=

ifeq ($(enable_zrtp), yes)
                linphone_configure_controls+= --enable-zrtp
                SWITCHES += enable_zrtp
else
                linphone_configure_controls+= --disable-zrtp
                SWITCHES += disable_zrtp
endif

ifeq ($(enable_tunnel), yes)
                linphone_configure_controls+= --enable-tunnel
                SWITCHES += enable_tunnel
else
                linphone_configure_controls+= --disable-tunnel
                SWITCHES += disable_tunnel
endif

ifeq ($(enable_gpl_third_parties),yes)
	SWITCHES+= enable_gpl_third_parties

	ifeq ($(enable_ffmpeg), yes)
		linphone_configure_controls+= --enable-ffmpeg
		SWITCHES += enable_ffmpeg
	else
		linphone_configure_controls+= --disable-ffmpeg
		SWITCHES += disable_ffmpeg
	endif

else # !enable gpl
	linphone_configure_controls+= --disable-ffmpeg
	SWITCHES += disable_gpl_third_parties disable_ffmpeg
endif

SWITCHES := $(addprefix $(LINPHONE_BUILD_DIR)/,$(SWITCHES))

mode_switch_check: $(SWITCHES)

#generic rule to force recompilation of linphone if some options require it
$(LINPHONE_BUILD_DIR)/enable_% $(LINPHONE_BUILD_DIR)/disable_%:
	mkdir -p $(LINPHONE_BUILD_DIR)
	cd $(LINPHONE_BUILD_DIR) && rm -f *able_$*
	touch $@
	cd $(LINPHONE_BUILD_DIR) && rm -f Makefile && rm -f oRTP/Makefile && rm -f mediastreamer2/Makefile

# end of switches parsing

speex_dir=externals/speex
gsm_dir=externals/gsm

MSILBC_SRC_DIR:=$(BUILDER_SRC_DIR)/msilbc
MSILBC_BUILD_DIR:=$(BUILDER_BUILD_DIR)/msilbc

LIBILBC_SRC_DIR:=$(BUILDER_SRC_DIR)/libilbc-rfc3951
LIBILBC_BUILD_DIR:=$(BUILDER_BUILD_DIR)/libilbc-rfc3951

ifneq (,$(findstring arm,$(host)))
	#SPEEX_CONFIGURE_OPTION := --enable-fixed-point --disable-float-api
	CFLAGS := $(CFLAGS) -marm
	SPEEX_CONFIGURE_OPTION := --disable-float-api --enable-arm5e-asm --enable-fixed-point
endif

ifneq (,$(findstring armv7,$(host)))
	SPEEX_CONFIGURE_OPTION += --enable-armv7neon-asm
endif

clean-makefile: clean-makefile-linphone clean-makefile-msbcg729
clean: clean-linphone clean-msbcg729
init:
	mkdir -p $(prefix)/include
	mkdir -p $(prefix)/lib/pkgconfig

veryclean: veryclean-linphone veryclean-msbcg729
	rm -rf $(BUILDER_BUILD_DIR)

# list of the submodules to build, the order is important
MS_MODULES      := msilbc libilbc msamr mssilk msx264 mswebrtc msopenh264
SUBMODULES_LIST := polarssl

ifeq ($(enable_tunnel),yes)
SUBMODULES_LIST += tunnel
endif

SUBMODULES_LIST += libantlr cunit belle-sip srtp speex libgsm libvpx libxml2 bzrtp ffmpeg opus

.NOTPARALLEL build-linphone: init $(addprefix build-,$(SUBMODULES_LIST)) mode_switch_check $(LINPHONE_BUILD_DIR)/Makefile
	cd $(LINPHONE_BUILD_DIR)  && export PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig export CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) make newdate && make && make install
	mkdir -p $(prefix)/share/linphone/tutorials && cp -f $(LINPHONE_SRC_DIR)/coreapi/help/*.c $(prefix)/share/linphone/tutorials/

clean-linphone: $(addprefix clean-,$(SUBMODULES_LIST)) $(addprefix clean-,$(MS_MODULES))
	cd  $(LINPHONE_BUILD_DIR) && make clean

veryclean-linphone: $(addprefix veryclean-,$(SUBMODULES_LIST)) $(addprefix veryclean-,$(MS_MODULES))
#-cd $(LINPHONE_BUILD_DIR) && make distclean
	-cd $(LINPHONE_SRC_DIR) && rm -f configure

clean-makefile-linphone: $(addprefix clean-makefile-,$(SUBMODULES_LIST)) $(addprefix clean-makefile-,$(MS_MODULES))
	cd $(LINPHONE_BUILD_DIR) && rm -f Makefile && rm -f oRTP/Makefile && rm -f mediastreamer2/Makefile


$(LINPHONE_SRC_DIR)/configure:
	cd $(LINPHONE_SRC_DIR) && ./autogen.sh

$(LINPHONE_BUILD_DIR)/Makefile: $(LINPHONE_SRC_DIR)/configure
	mkdir -p $(LINPHONE_BUILD_DIR)
	@echo -e "\033[1mPKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
        $(LINPHONE_SRC_DIR)/configure -prefix=$(prefix) --host=$(host) ${library_mode} \
        ${linphone_configure_controls}\033[0m"
	cd $(LINPHONE_BUILD_DIR) && \
	PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
	$(LINPHONE_SRC_DIR)/configure -prefix=$(prefix) --host=$(host) ${library_mode} \
	${linphone_configure_controls}


#libphone only (asume dependencies are met)
build-liblinphone: $(LINPHONE_BUILD_DIR)/Makefile
	cd $(LINPHONE_BUILD_DIR)  && export PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig export CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) make newdate &&  make  && make install

clean-makefile-liblinphone:
	 cd $(LINPHONE_BUILD_DIR) && rm -f Makefile && rm -f oRTP/Makefile && rm -f mediastreamer2/Makefile

clean-liblinphone:
	 cd  $(LINPHONE_BUILD_DIR) && make clean

#speex

$(BUILDER_SRC_DIR)/$(speex_dir)/configure:
	 cd $(BUILDER_SRC_DIR)/$(speex_dir) && ./autogen.sh

$(BUILDER_BUILD_DIR)/$(speex_dir)/Makefile: $(BUILDER_SRC_DIR)/$(speex_dir)/configure
	mkdir -p $(BUILDER_BUILD_DIR)/$(speex_dir)
	cd $(BUILDER_BUILD_DIR)/$(speex_dir)/\
	&& CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) CFLAGS="$(CFLAGS) -O2" \
	$(BUILDER_SRC_DIR)/$(speex_dir)/configure -prefix=$(prefix) --host=$(host) ${library_mode} --disable-ogg  $(SPEEX_CONFIGURE_OPTION)

build-speex: $(BUILDER_BUILD_DIR)/$(speex_dir)/Makefile
	cd $(BUILDER_BUILD_DIR)/$(speex_dir) && make  && make install

clean-speex:
	cd  $(BUILDER_BUILD_DIR)/$(speex_dir)  && make clean

veryclean-speex:
#	-cd $(BUILDER_BUILD_DIR)/$(speex_dir) && make distclean
	-rm -f $(BUILDER_SRC_DIR)/$(speex_dir)/configure

clean-makefile-speex:
	cd $(BUILDER_BUILD_DIR)/$(speex_dir) && rm -f Makefile


#GSM

build-libgsm:
	cp -rf $(BUILDER_SRC_DIR)/$(gsm_dir) $(BUILDER_BUILD_DIR)/$(gsm_dir)
	rm -rf $(BUILDER_BUILD_DIR)/$(gsm_dir)/gsm/.git
	rm -f $(prefix)/lib/libgsm.a
	rm -rf $(prefix)/include/gsm
	cd $(BUILDER_BUILD_DIR)/$(gsm_dir)\
	&& mkdir -p $(prefix)/include/gsm \
	&& host_alias=$(host)  . $(BUILDER_SRC_DIR)/build/$(config_site) \
	&&  make -j1 CC="$${CC}" INSTALL_ROOT=$(prefix)  GSM_INSTALL_INC=$(prefix)/include/gsm  install

clean-libgsm:
	cd $(BUILDER_BUILD_DIR)/$(gsm_dir)\
	&& make clean

veryclean-libgsm:
	 -cd $(BUILDER_BUILD_DIR)/$(gsm_dir) \
	&& make uninstall



# msilbc  plugin

$(MSILBC_SRC_DIR)/configure:
	cd $(MSILBC_SRC_DIR) && ./autogen.sh

$(MSILBC_BUILD_DIR)/Makefile: $(MSILBC_SRC_DIR)/configure
	mkdir -p $(MSILBC_BUILD_DIR)
	cd $(MSILBC_BUILD_DIR) && \
	PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
	$(MSILBC_SRC_DIR)/configure -prefix=$(prefix) --host=$(host) $(library_mode)

build-msilbc: build-libilbc $(MSILBC_BUILD_DIR)/Makefile
	cd $(MSILBC_BUILD_DIR) && make  && make install

clean-msilbc:
	cd  $(MSILBC_BUILD_DIR) && make  clean

veryclean-msilbc:
#	-cd $(MSILBC_BUILD_DIR) && make distclean
	-cd $(MSILBC_SRC_DIR) && rm configure

clean-makefile-msilbc:
	cd $(MSILBC_BUILD_DIR) && rm -f Makefile

# libilbc

$(LIBILBC_SRC_DIR)/configure:
	cd $(LIBILBC_SRC_DIR) && ./autogen.sh

$(LIBILBC_BUILD_DIR)/Makefile: $(LIBILBC_SRC_DIR)/configure
	mkdir -p $(LIBILBC_BUILD_DIR)
	cd $(LIBILBC_BUILD_DIR) && \
	PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
	$(LIBILBC_SRC_DIR)/configure -prefix=$(prefix) --host=$(host) $(library_mode)

build-libilbc: $(LIBILBC_BUILD_DIR)/Makefile
	cd $(LIBILBC_BUILD_DIR) && make  && make install

clean-libilbc:
	cd  $(LIBILBC_BUILD_DIR) && make clean

veryclean-libilbc:
	-cd $(LIBILBC_BUILD_DIR) && make distclean

clean-makefile-libilbc:
	cd $(LIBILBC_BUILD_DIR) && rm -f Makefile

#openssl
#srtp
#zrtp
include builders.d/*.mk
#sdk generation and distribution

multi-arch:
	arm_archives=`find $(prefix) -name *.a` ;\
	mkdir -p $(prefix)/../apple-darwin; \
	cp -rf $(prefix)/include  $(prefix)/../apple-darwin/. ; \
	cp -rf $(prefix)/share  $(prefix)/../apple-darwin/. ; \
	for archive in $$arm_archives ; do \
	        i386_path=`echo $$archive | sed -e "s/armv7/i386/"` ;\
	        armv6_path=`echo $$archive | sed -e "s/armv7/armv6/"` ;\
        	if  test ! -f "$$armv6_path"; then \
			armv6_path= ; \
		fi; \
	        armv7s_path=`echo $$archive | sed -e "s/armv7/armv7s/"` ;\
        	if  test ! -f "$$armv7s_path"; then \
			armv7s_path= ; \
		fi; \
        	destpath=`echo $$archive | sed -e "s/-debug//"` ;\
        	destpath=`echo $$destpath | sed -e "s/armv7-//"` ;\
        	if test -f "$$i386_path"; then \
                	echo "Mixing $$archive into $$destpath"; \
                	mkdir -p `dirname $$destpath` ; \
                	lipo -create $$archive $$armv7s_path $$armv6_path $$i386_path -output $$destpath; \
        	else \
                	echo "WARNING: archive `basename $$archive` exists in arm tree but does not exists in i386 tree."; \
        	fi \
	done
	if ! test -f $(prefix)/../apple-darwin/lib/libtunnel.a ; then \
		cp -f $(BUILDER_SRC_DIR)/../submodules/binaries/libdummy.a $(prefix)/../apple-darwin/lib/libtunnel.a ; \
	fi


delivery-sdk: multi-arch
	echo "Generating SDK zip file for version $(LINPHONE_IPHONE_VERSION)"
	cd $(BUILDER_SRC_DIR)/../ \
	&& zip -r $(BUILDER_SRC_DIR)/liblinphone-iphone-sdk-$(LINPHONE_IPHONE_VERSION).zip \
	liblinphone-sdk/apple-darwin \
	liblinphone-tutorials \
	-x liblinphone-tutorials/hello-world/build\* \
	-x liblinphone-tutorials/hello-world/hello-world.xcodeproj/*.pbxuser \
	-x liblinphone-tutorials/hello-world/hello-world.xcodeproj/*.mode1v3

download-sdk:
	cd $(BUILDER_SRC_DIR)/../
	rm -fr liblinphone-iphone-sdk-latest*
	wget http://linphone.org/snapshots/ios/liblinphone-iphone-sdk-latest.zip
	unzip -o -q liblinphone-iphone-sdk-latest.zip
	rm -fr ../../liblinphone-sdk/
	mv liblinphone-sdk ../..

.PHONY delivery:
	cd $(BUILDER_SRC_DIR)/../../ \
	&& zip  -r   $(BUILDER_SRC_DIR)/linphone-iphone.zip \
	linphone-iphone  \
	-x linphone-iphone/build\* \
	--exclude linphone-iphone/.git\* --exclude \*.[od] --exclude \*.so.\* --exclude \*.a  --exclude linphone-iphone/liblinphone-sdk/apple-darwin/\* --exclude \*.lo

ipa:
	cd $(BUILDER_SRC_DIR)/../ \
	&& xcodebuild  -configuration Release \
	&& xcrun -sdk iphoneos PackageApplication -v build/Release-iphoneos/linphone.app -o $(BUILDER_SRC_DIR)/../linphone-iphone.ipa

