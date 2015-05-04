############################################################################
# mssilk.mk 
# Copyright (C) 2011  Belledonne Communications,Grenoble France
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
mssilk_dir?=mssilk
enable_silk?=yes

configure-options=
ifeq ($(LINPHONE_CCACHE), ccache)
	configure-options+= --disable-strict
endif

$(BUILDER_SRC_DIR)/$(mssilk_dir)/configure:
	echo -e "\033[01;32m Running autogen for mssilk in $(BUILDER_SRC_DIR)/$(mssilk_dir) \033[0m"
	cd $(BUILDER_SRC_DIR)/$(mssilk_dir) && ./autogen.sh

$(BUILDER_BUILD_DIR)/$(mssilk_dir)/Makefile: $(BUILDER_SRC_DIR)/$(mssilk_dir)/configure
	@echo -e "\033[01;32m Running configure in $(BUILDER_BUILD_DIR)/$(mssilk_dir) \033[0m"
	mkdir -p $(BUILDER_BUILD_DIR)/$(mssilk_dir)
	cd $(BUILDER_BUILD_DIR)/$(mssilk_dir)/ \
		&& PKG_CONFIG_LIBDIR=$(prefix)/lib/pkgconfig CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
		$(BUILDER_SRC_DIR)/$(mssilk_dir)/configure -prefix=$(prefix) --host=$(host) ${library_mode} \
		--enable-static ${configure-options}

ifeq ($(enable_silk),yes)

build-mssilk: $(BUILDER_BUILD_DIR)/$(mssilk_dir)/Makefile
	echo -e "\033[01;32m building silk \033[0m"
	cd $(BUILDER_BUILD_DIR)/$(mssilk_dir) \
		&& PKG_CONFIG_PATH=$(prefix)/lib/pkgconfig \
		CONFIG_SITE=$(BUILDER_SRC_DIR)/build/$(config_site) \
		make -j1 && make install
ifeq ($(host),armv7-apple-darwin)
	echo -e "\033[01;32m Getting BINARY version of silk for armV7 \033[0m"
	cp $(BUILDER_SRC_DIR)/$(mssilk_dir)/ios_bin/armv7/libSKP_SILK_SDK.a $(prefix)/lib/
endif

else

build-mssilk:
	echo "SILK is disabled"

endif # enable_silk	

clean-mssilk: 
	-cd  $(BUILDER_BUILD_DIR)/$(mssilk_dir) && make clean

veryclean-mssilk: 
	-cd $(BUILDER_BUILD_DIR)/$(mssilk_dir) && make distclean 
	rm -f $(BUILDER_SRC_DIR)/$(mssilk_dir)/configure

clean-makefile-mssilk: 
	-cd $(BUILDER_BUILD_DIR)/$(mssilk_dir) && rm -f Makefile
