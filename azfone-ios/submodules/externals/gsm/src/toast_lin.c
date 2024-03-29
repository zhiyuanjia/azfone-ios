/*
 * Copyright 1992 by Jutta Degener and Carsten Bormann, Technische
 * Universitaet Berlin.  See the accompanying file "COPYRIGHT" for
 * details.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 */

/* $Header: /home/repository/azfone-ios/submodules/externals/gsm/src/toast_lin.c,v 1.1.1.1 2014/11/13 04:07:24 khc Exp $ */

#include	"toast.h"

/*  toast_linear.c -- read and write 16 bit linear sound in host byte order.
 */

extern FILE	*in, *out;

int linear_input (buf) gsm_signal * buf;
{
	return fread( (char *)buf, sizeof(*buf), 160, in );
}

int linear_output P1((buf), gsm_signal * buf) 
{
	return -( fwrite( (char *)buf, sizeof(*buf), 160, out ) != 160 );
}
