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

set(AUTOMATED_INCLUDES Automated.h)
set(BASIC_INCLUDES Basic.h)
set(CONSOLE_INCLUDES Console.h)
set(CURSES_INCLUDES CUCurses.h)
set(FRAMEWORK_INCLUDES CUError.h CUnit.h CUnit_intl.h MyMem.h TestDB.h TestRun.h Util.h)

set(HEADER_FILES ${FRAMEWORK_INCLUDES})

if(${ENABLE_BASIC})
	list(APPEND HEADER_FILES ${BASIC_INCLUDES})
endif()

if(${ENABLE_CONSOLE})
	list(APPEND HEADER_FILES ${CONSOLE_INCLUDES})
endif()

if(${ENABLE_AUTOMATED})
	list(APPEND HEADER_FILES ${AUTOMATED_INCLUDES})
endif()

if(${ENABLE_CURSES})
	list(APPEND HEADER_FILES ${CURSES_INCLUDES})
endif()

install(FILES ${HEADER_FILES}
	DESTINATION include/CUnit
	PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
)
