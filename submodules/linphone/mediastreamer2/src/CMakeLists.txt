############################################################################
# CMakeLists.txt
# Copyright (C) 2014  Belledonne Communications, Grenoble France
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

if(MSVC)
	find_library(LIBGCC NAMES gcc)
	find_library(LIBMINGWEX NAMES mingwex)
endif()


find_program(AWK_PROGRAM awk)
if(NOT AWK_PROGRAM)
	message(FATAL_ERROR "You need the awk program to build mediastreamer2.")
endif()

set(BASE_SOURCE_FILES
	base/eventqueue.c
	base/mscommon.c
	base/msfactory.c
	base/msfilter.c
	base/msqueue.c
	base/mssndcard.c
	base/msticker.c
	base/mswebcam.c
	base/mtu.c
	otherfilters/itc.c
	otherfilters/join.c
	otherfilters/tee.c
	otherfilters/void.c
)

set(BASE_GENERATED_SOURCE_FILES
	${CMAKE_CURRENT_BINARY_DIR}/basedescs.h
	${CMAKE_CURRENT_BINARY_DIR}/gitversion.h
)
set_source_files_properties(${BASE_GENERATED_SOURCE_FILES} PROPERTIES GENERATED TRUE)
find_package(Git)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/gitversion.h
	COMMAND ${CMAKE_COMMAND} -DGIT_EXECUTABLE=${GIT_EXECUTABLE} -DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR} -P ${CMAKE_CURRENT_SOURCE_DIR}/gitversion.cmake)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/basedescs.h
	COMMAND ${CMAKE_COMMAND} -DAWK_PROGRAM=${AWK_PROGRAM} -DAWK_SCRIPTS_DIR=${CMAKE_CURRENT_SOURCE_DIR}/../
		-DINPUT_DIR=${CMAKE_CURRENT_SOURCE_DIR} -DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}
		-DTYPE=base -DSOURCE_FILES="${BASE_SOURCE_FILES}"
		-P ${CMAKE_CURRENT_SOURCE_DIR}/generate_descs_header.cmake)

add_definitions(
	-DMEDIASTREAMER2_EXPORTS
	-DMEDIASTREAMER2_INTERNAL_EXPORTS
	-D_TRUE_TIME
	-DMS2_INTERNAL
	-DMS2_FILTERS
)

set(BASE_LIBS
	${LIBGCC}
	${LIBMINGWEX}
	${ORTP_LIBRARIES}
)
if(WIN32)
	list(APPEND BASE_LIBS ole32 oleaut32 uuid)
endif()
if(HAVE_DLOPEN)
	list(APPEND BASE_LIBS dl)
endif()

if(ENABLE_STATIC)
	add_library(mediastreamer_base STATIC ${BASE_SOURCE_FILES} ${BASE_GENERATED_SOURCE_FILES})
	target_link_libraries(mediastreamer_base ${BASE_LIBS})
else()
	add_library(mediastreamer_base SHARED ${BASE_SOURCE_FILES} ${BASE_GENERATED_SOURCE_FILES})
	set_target_properties(mediastreamer_base PROPERTIES VERSION ${MEDIASTREAMER_VERSION} SOVERSION ${MEDIASTREAMER_SO_VERSION} LINKER_LANGUAGE C)
	target_link_libraries(mediastreamer_base ${BASE_LIBS})
	if(MSVC)
		if(CMAKE_BUILD_TYPE STREQUAL "Debug")
			install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Debug/mediastreamer_base.pdb
				DESTINATION bin
				PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
			)
		endif()
	endif()
endif()

install(TARGETS mediastreamer_base
	RUNTIME DESTINATION bin
	LIBRARY DESTINATION lib
	ARCHIVE DESTINATION lib
	PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)



set(VOIP_SOURCE_FILES
	audiofilters/alaw.c
	audiofilters/audiomixer.c
	audiofilters/chanadapt.c
	audiofilters/devices.c
	audiofilters/devices.h
	audiofilters/dtmfgen.c
	audiofilters/equalizer.c
	audiofilters/flowcontrol.c
	audiofilters/g711.c
	audiofilters/g711.h
	audiofilters/genericplc.c
	audiofilters/l16.c
	audiofilters/msfileplayer.c
	audiofilters/msfilerec.c
	audiofilters/msg722.c
	audiofilters/msvolume.c
	audiofilters/tonedetector.c
	audiofilters/ulaw.c
	audiofilters/waveheader.h
	otherfilters/msrtp.c
	utils/_kiss_fft_guts.h
	utils/dsptools.c
	utils/g722.h
	utils/g722_decode.c
	utils/g722_encode.c
	utils/kiss_fft.c
	utils/kiss_fft.h
	utils/kiss_fftr.c
	utils/kiss_fftr.h
	voip/audioconference.c
	voip/audiostream.c
	voip/bitratecontrol.c
	voip/bitratedriver.c
	voip/ice.c
	voip/mediastream.c
	voip/msvoip.c
	voip/private.h
	voip/qosanalyzer.c
	voip/qosanalyzer.h
	voip/qualityindicator.c
	voip/ringstream.c
)

if(ENABLE_ALSA)
	list(APPEND VOIP_SOURCE_FILES audiofilters/alsa.c)
endif()
if(ENABLE_ARTSC)
	list(APPEND VOIP_SOURCE_FILES audiofilters/arts.c)
endif()
if(ENABLE_MACSND)
	list(APPEND VOIP_SOURCE_FILES audiofilters/macsnd.c)
endif()
if(ENABLE_MACAQSND)
	list(APPEND VOIP_SOURCE_FILES audiofilters/aqsnd.c)
endif()
if(ENABLE_OSS)
	list(APPEND VOIP_SOURCE_FILES audiofilters/oss.c)
endif()
if(ENABLE_PORTAUDIO)
	list(APPEND VOIP_SOURCE_FILES audiofilters/pasnd.c)
endif()
if(ENABLE_PULSEAUDIO)
	list(APPEND VOIP_SOURCE_FILES audiofilters/pulseaudio.c)
endif()
if(ENABLE_QSA)
	list(APPEND VOIP_SOURCE_FILES audiofilters/qsa.c)
endif()
if(IOS)
	list(APPEND VOIP_SOURCE_FILES audiofilters/msiounit.m audiofilters/aac-eld.c)
endif()
if(WIN32)
	list(APPEND VOIP_SOURCE_FILES audiofilters/winsnd3.c)
endif()

if(GSM_FOUND)
	list(APPEND VOIP_SOURCE_FILES audiofilters/gsm.c)
endif()
if(OPUS_FOUND)
	list(APPEND VOIP_SOURCE_FILES audiofilters/msopus.c)
endif()
if(ENABLE_RESAMPLE)
	list(APPEND VOIP_SOURCE_FILES audiofilters/msresample.c)
endif()
if(SPEEX_FOUND)
	list(APPEND VOIP_SOURCE_FILES
		audiofilters/msspeex.c
		audiofilters/speexec.c
	)
endif()

if(ENABLE_VIDEO)
	list(APPEND VOIP_SOURCE_FILES
		utils/bits_rw.c
		videofilters/extdisplay.c
		videofilters/mire.c
		videofilters/pixconv.c
		videofilters/sizeconv.c
		voip/layouts.c
		voip/layouts.h
		voip/msvideo.c
		voip/msvideo_neon.c
		voip/msvideo_neon.h
		voip/rfc2429.h
		voip/rfc3984.c
		voip/videostarter.c
		voip/videostream.c
	)
	if(WIN32)
		add_definitions(-DHAVE_DIRECTSHOW)
		list(APPEND VOIP_SOURCE_FILES
			videofilters/msdscap-mingw.cc
			videofilters/drawdib-display.c
		)
		set_source_files_properties(videofilters/msdscap-mingw.cc PROPERTIES LANGUAGE CXX)
	endif(WIN32)
	if(APPLE)
		list(APPEND VOIP_SOURCE_FILES
			utils/opengles_display.c
			utils/opengles_display.h
			utils/shaders.c
			utils/shaders.h
			videofilters/msosxdisplay.m
			videofilters/qtcapture.m
		)
	endif()
	if(FFMPEG_FOUND)
		list(APPEND VOIP_SOURCE_FILES
			utils/ffmpeg-priv.c
			utils/ffmpeg-priv.h
			utils/swscale.h
			videofilters/h264dec.c
			videofilters/jpegwriter.c
			videofilters/nowebcam.c
			videofilters/videodec.c
			videofilters/videoenc.c
			voip/nowebcam.h
		)
	endif()
	if(GLX_FOUND)
		list(APPEND VOIP_SOURCE_FILES
			utils/opengles_display.c
			utils/shaders.c
			videofilters/glxvideo.c
		)
	endif()
	if(SDL_FOUND)
		list(APPEND VOIP_SOURCE_FILES videofilters/videoout.c)
	endif()
	if(THEORA_FOUND)
		list(APPEND VOIP_SOURCE_FILES videofilters/theora.c)
	endif()
	if(V4L_FOUND)
		if(HAVE_LINUX_VIDEODEV_H)
			list(APPEND VOIP_SOURCE_FILES videofilters/msv4l.c)
		endif()
		if(HAVE_LINUX_VIDEODEV2_H)
			list(APPEND VOIP_SOURCE_FILES videofilters/msv4l2.c)
		endif()
	endif()
	if(VPX_FOUND)
		list(APPEND VOIP_SOURCE_FILES
			videofilters/vp8.c
			voip/vp8rtpfmt.c
			voip/vp8rtpfmt.h
		)
	endif()
	if(X11_FOUND)
		list(APPEND VOIP_SOURCE_FILES utils/x11_helper.c)
	endif()
	if(XV_FOUND)
		list(APPEND VOIP_SOURCE_FILES videofilters/x11video.c)
	endif()
endif()

set(VOIP_GENERATED_SOURCE_FILES
	${CMAKE_CURRENT_BINARY_DIR}/voipdescs.h
)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/voipdescs.h
	COMMAND ${CMAKE_COMMAND} -DAWK_PROGRAM=${AWK_PROGRAM} -DAWK_SCRIPTS_DIR=${CMAKE_CURRENT_SOURCE_DIR}/../
		-DINPUT_DIR=${CMAKE_CURRENT_SOURCE_DIR} -DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}
		-DTYPE=voip -DSOURCE_FILES="${VOIP_SOURCE_FILES}"
		-P ${CMAKE_CURRENT_SOURCE_DIR}/generate_descs_header.cmake)
if(APPLE OR GLX_FOUND)
find_program(XXD_PROGRAM xxd)
if(NOT XXD_PROGRAM)
	message(FATAL_ERROR "You need the xxd program to build mediastreamer2.")
endif()
find_program(SED_PROGRAM sed)
if(NOT SED_PROGRAM)
	message(FATAL_ERROR "You need the sed program to build mediastreamer2.")
endif()
list(APPEND VOIP_GENERATED_SOURCE_FILES
	${CMAKE_CURRENT_BINARY_DIR}/yuv2rgb.fs.h
	${CMAKE_CURRENT_BINARY_DIR}/yuv2rgb.vs.h
)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/yuv2rgb.fs.h
	COMMAND ${CMAKE_COMMAND} -DXXD_PROGRAM=${XXD_PROGRAM} -DSED_PROGRAM=${SED_PROGRAM}
		-DINPUT_DIR=${CMAKE_CURRENT_SOURCE_DIR} -DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}
		-DSOURCE_FILE="yuv2rgb.fs"
		-P ${CMAKE_CURRENT_SOURCE_DIR}/generate_yuv2rgb_header.cmake)
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/yuv2rgb.vs.h
	COMMAND ${CMAKE_COMMAND} -DXXD_PROGRAM=${XXD_PROGRAM} -DSED_PROGRAM=${SED_PROGRAM}
		-DINPUT_DIR=${CMAKE_CURRENT_SOURCE_DIR} -DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}
		-DSOURCE_FILE="yuv2rgb.vs"
		-P ${CMAKE_CURRENT_SOURCE_DIR}/generate_yuv2rgb_header.cmake)
endif()
set_source_files_properties(${VOIP_GENERATED_SOURCE_FILES} PROPERTIES GENERATED TRUE)


set(VOIP_LIBS
	${LIBGCC}
	${LIBMINGWEX}
	${ORTP_LIBRARIES}
	mediastreamer_base
)
if(WIN32)
	list(APPEND VOIP_LIBS ole32 oleaut32 uuid)
	if(ENABLE_VIDEO)
		list(APPEND VOIP_LIBS gdi32 user32 vfw32)
	endif()
endif()
if(HAVE_DLOPEN)
	list(APPEND VOIP_LIBS dl)
endif()
if(GSM_FOUND)
	list(APPEND VOIP_LIBS ${GSM_LIBRARIES})
endif()
if(OPUS_FOUND)
	list(APPEND VOIP_LIBS ${OPUS_LIBRARIES})
endif()
if(SPEEX_FOUND)
	list(APPEND VOIP_LIBS ${SPEEX_LIBRARIES})
endif()
if(ALSA_FOUND)
	list(APPEND VOIP_LIBS ${ALSA_LIBRARIES})
endif()
if(ARTS_FOUND)
	list(APPEND VOIP_LIBS ${ARTS_LIBRARIES})
endif()
if(PORTAUDIO_FOUND)
	list(APPEND VOIP_LIBS ${PORTAUDIO_LIBRARIES})
endif()
if(PULSEAUDIO_FOUND)
	list(APPEND VOIP_LIBS ${PULSEAUDIO_LIBRARIES})
endif()
if(QSA_FOUND)
	list(APPEND VOIP_LIBS ${QSA_LIBRARIES})
endif()
if(FFMPEG_FOUND)
	list(APPEND VOIP_LIBS ${FFMPEG_LIBRARIES})
	if(MSVC)
		add_definitions(-Dinline=__inline)
	endif()
endif()
if(V4L_FOUND)
	list(APPEND VOIP_LIBS ${V4L_LIBRARIES})
endif()
if(X11_FOUND)
	list(APPEND VOIP_LIBS ${X11_LIBRARIES})
endif()
if(XV_FOUND)
	list(APPEND VOIP_LIBS ${XV_LIBRARIES})
endif()
if(GLX_FOUND)
	list(APPEND VOIP_LIBS ${GLX_LIBRARIES})
endif()
if(VPX_FOUND)
	list(APPEND VOIP_LIBS ${VPX_LIBRARIES})
endif()

if(ENABLE_STATIC)
	add_library(mediastreamer_voip STATIC ${VOIP_SOURCE_FILES} ${VOIP_GENERATED_SOURCE_FILES})
	target_link_libraries(mediastreamer_voip ${VOIP_LIBS})
else()
	add_library(mediastreamer_voip SHARED ${VOIP_SOURCE_FILES} ${VOIP_GENERATED_SOURCE_FILES})
	set_target_properties(mediastreamer_voip PROPERTIES VERSION ${MEDIASTREAMER_VERSION} SOVERSION ${MEDIASTREAMER_SO_VERSION} LINKER_LANGUAGE CXX)
	target_link_libraries(mediastreamer_voip ${VOIP_LIBS})
	if(MSVC)
		if(CMAKE_BUILD_TYPE STREQUAL "Debug")
			install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Debug/mediastreamer_voip.pdb
				DESTINATION bin
				PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
			)
		endif()
	endif()
endif()
string(REPLACE ";" " " APPLE_SPECIFIC_LINK_FLAGS_STR "${APPLE_SPECIFIC_LINK_FLAGS}")
if(NOT "${APPLE_SPECIFIC_LINK_FLAGS_STR}" STREQUAL "")
	set_target_properties(mediastreamer_voip PROPERTIES LINK_FLAGS ${APPLE_SPECIFIC_LINK_FLAGS_STR})
endif()

install(TARGETS mediastreamer_voip
	RUNTIME DESTINATION bin
	LIBRARY DESTINATION lib
	ARCHIVE DESTINATION lib
	PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

if(ENABLE_VIDEO)
	install(FILES voip/nowebcamCIF.jpg
		DESTINATION ${PACKAGE_DATA_DIR}/images
        PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
	)
endif()
