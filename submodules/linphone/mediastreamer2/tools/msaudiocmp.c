/*
mediastreamer2 library - modular sound and video processing and streaming
Copyright (C) 2014  Belledonne Communications SARL
Author: Simon Morlat <simon.morlat@linphone.org>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#include "mediastreamer2/mscommon.h"
#include "mediastreamer2/dsptools.h"

static void completion_cb(void *user_data, int percentage){
	fprintf(stdout,"%i %% completed\r",percentage);
	fflush(stdout);
}

int main(int argc, char *argv[]){
	double ret=0;
	if (argc<3){
		fprintf(stderr,"%s: file1 file2\nCompare two wav audio files and display a similarity factor between 0 and 1.\n",argv[0]);
		return -1;
	}
	ortp_set_log_level_mask(ORTP_MESSAGE|ORTP_WARNING|ORTP_ERROR|ORTP_FATAL);
	if (ms_audio_diff(argv[1],argv[2],&ret,completion_cb,NULL)==0){
		fprintf(stdout,"%s and %s are similar with a degree of %g.\n",argv[1],argv[2],ret);
		return 0;
	}else{
		fprintf(stderr,"Error encountered during processing, exiting.\n");
	}
	return -1;
}
