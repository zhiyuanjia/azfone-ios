/*
 The oRTP library is an RTP (Realtime Transport Protocol - rfc3550) stack.
 Copyright (C) 2011 Belledonne Communications

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef ortp_zrtp_h
#define ortp_zrtp_h

#include <ortp/rtpsession.h>

#ifdef __cplusplus
extern "C"{
#endif

typedef struct OrtpZrtpParams {
	const char *zid_file; // File where to store secrets and other information
	const char *uri; /* the sip URI of correspondant */
} OrtpZrtpParams;

typedef struct _OrtpZrtpContext OrtpZrtpContext ;

ORTP_PUBLIC bool_t ortp_zrtp_available(void);

/**
  * @deprecated Use ortp_zrtp_transport_modifier_new() instead. Using #srtp_transport_new will prevent usage of multiple
  * encryptions and/or custom packets transmission.
*/
ORTP_PUBLIC OrtpZrtpContext* ortp_zrtp_context_new(RtpSession *s, OrtpZrtpParams *params);
ORTP_PUBLIC void ortp_zrtp_context_destroy(OrtpZrtpContext *ctx);
/**
 * can be used to give more time for establishing zrtp session
 * */
ORTP_PUBLIC void ortp_zrtp_reset_transmition_timer(OrtpZrtpContext* ctx, RtpSession *s);

ORTP_PUBLIC OrtpZrtpContext* ortp_zrtp_multistream_new(OrtpZrtpContext* activeContext, RtpSession *s, OrtpZrtpParams *params);

ORTP_PUBLIC void ortp_zrtp_sas_verified(OrtpZrtpContext* ctx);
ORTP_PUBLIC void ortp_zrtp_sas_reset_verified(OrtpZrtpContext* ctx);



ORTP_PUBLIC int ortp_zrtp_transport_modifier_new(OrtpZrtpContext* ctx, RtpTransportModifier **rtpt, RtpTransportModifier **rtcpt );
ORTP_PUBLIC void ortp_zrtp_transport_modifier_destroy(RtpTransportModifier *tp);


#ifdef __cplusplus
}
#endif

#endif
