/****************************************************************************
 * quant.S: arm quantization and level-run
 *****************************************************************************
 * Copyright (C) 2009-2012 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at licensing@x264.com.
 *****************************************************************************/

#include "asm.S"

.fpu neon

.section .rodata
.align 4
pmovmskb_byte:
.byte 1,2,4,8,16,32,64,128
.byte 1,2,4,8,16,32,64,128

.text

.macro QUANT_TWO bias0 bias1 mf0 mf1 mf2 mf3 load_mf=no
    vadd.u16    q8,  q8,  \bias0
    vadd.u16    q9,  q9,  \bias1
.ifc \load_mf, yes
    vld1.64     {\mf0-\mf3}, [r1,:128]!
.endif
    vmull.u16   q10, d16, \mf0
    vmull.u16   q11, d17, \mf1
    vmull.u16   q12, d18, \mf2
    vmull.u16   q13, d19, \mf3
    vshr.s16    q14, q14, #15
    vshr.s16    q15, q15, #15
    vshrn.u32   d16, q10, #16
    vshrn.u32   d17, q11, #16
    vshrn.u32   d18, q12, #16
    vshrn.u32   d19, q13, #16
    veor        q8,  q8,  q14
    veor        q9,  q9,  q15
    vsub.s16    q8,  q8,  q14
    vsub.s16    q9,  q9,  q15
    vorr        \bias0, q8,  q9
    vst1.64     {d16-d19}, [r0,:128]!
.endm

.macro QUANT_END d
    vmov        r2,  r3,  \d
    orrs        r0,  r2,  r3
    movne       r0,  #1
    bx          lr
.endm

// quant_2x2_dc( int16_t dct[4], int mf, int bias )
function x264_quant_2x2_dc_neon
    vld1.64     {d0}, [r0,:64]
    vabs.s16    d3,  d0
    vdup.16     d2,  r2
    vdup.16     d1,  r1
    vadd.u16    d3,  d3,  d2
    vmull.u16   q3,  d3,  d1
    vshr.s16    d0,  d0,  #15
    vshrn.u32   d3,  q3,  #16
    veor        d3,  d3,  d0
    vsub.s16    d3,  d3,  d0
    vst1.64     {d3}, [r0,:64]
    QUANT_END   d3
.endfunc

// quant_4x4_dc( int16_t dct[16], int mf, int bias )
function x264_quant_4x4_dc_neon
    vld1.64     {d28-d31}, [r0,:128]
    vabs.s16    q8,  q14
    vabs.s16    q9,  q15
    vdup.16     q0,  r2
    vdup.16     q2,  r1
    QUANT_TWO   q0,  q0,  d4,  d5,  d4,  d5
    vorr        d0,  d0,  d1
    QUANT_END   d0
.endfunc

// quant_4x4( int16_t dct[16], uint16_t mf[16], uint16_t bias[16] )
function x264_quant_4x4_neon
    vld1.64     {d28-d31}, [r0,:128]
    vabs.s16    q8,  q14
    vabs.s16    q9,  q15
    vld1.64     {d0-d3}, [r2,:128]
    vld1.64     {d4-d7}, [r1,:128]
    QUANT_TWO   q0,  q1,  d4,  d5,  d6,  d7
    vorr        d0,  d0,  d1
    QUANT_END   d0
.endfunc

// quant_8x8( int16_t dct[64], uint16_t mf[64], uint16_t bias[64] )
function x264_quant_8x8_neon
    vld1.64     {d28-d31}, [r0,:128]
    vabs.s16    q8,  q14
    vabs.s16    q9,  q15
    vld1.64     {d0-d3},   [r2,:128]!
    vld1.64     {d4-d7},   [r1,:128]!
    QUANT_TWO   q0,  q1,  d4,  d5,  d6,  d7
.rept 3
    vld1.64     {d28-d31}, [r0,:128]
    vabs.s16    q8,  q14
    vabs.s16    q9,  q15
    vld1.64     {d2-d5},   [r2,:128]!
    QUANT_TWO   q1,  q2,  d4,  d5,  d6,  d7, yes
    vorr        q0,  q0,  q1
.endr
    vorr        d0,  d0,  d1
    QUANT_END   d0
.endfunc

.macro DEQUANT_START mf_size offset dc=no
    mov         r3,  #0x2b
    mul         r3,  r3,  r2
    lsr         r3,  r3,  #8            // i_qbits = i_qp / 6
    add         ip,  r3,  r3,  lsl #1
    sub         r2,  r2,  ip,  lsl #1   // i_mf = i_qp % 6
.ifc \dc,no
    add         r1,  r1,  r2, lsl #\mf_size  // dequant_mf[i_mf]
.else
    ldr         r1, [r1,  r2, lsl #\mf_size] // dequant_mf[i_mf][0][0]
.endif
    subs        r3,  r3,  #\offset      // 6 for 8x8
.endm

// dequant_4x4( int16_t dct[16], int dequant_mf[6][16], int i_qp )
.macro DEQUANT size bits
function x264_dequant_\size\()_neon
    DEQUANT_START \bits+2, \bits
.ifc \size, 8x8
    mov         r2,  #4
.endif
    blt         dequant_\size\()_rshift

    vdup.16     q15, r3
dequant_\size\()_lshift_loop:
.ifc \size, 8x8
    subs        r2,  r2,  #1
.endif
    vld1.32     {d16-d17}, [r1,:128]!
    vld1.32     {d18-d19}, [r1,:128]!
    vmovn.s32   d4,  q8
    vld1.32     {d20-d21}, [r1,:128]!
    vmovn.s32   d5,  q9
    vld1.32     {d22-d23}, [r1,:128]!
    vmovn.s32   d6,  q10
    vld1.16     {d0-d3},   [r0,:128]
    vmovn.s32   d7,  q11
    vmul.s16    q0,  q0,  q2
    vmul.s16    q1,  q1,  q3
    vshl.s16    q0,  q0,  q15
    vshl.s16    q1,  q1,  q15
    vst1.16     {d0-d3},   [r0,:128]!
.ifc \size, 8x8
    bgt         dequant_\size\()_lshift_loop
.endif
    bx          lr

dequant_\size\()_rshift:
    vdup.32     q15, r3
    rsb         r3,  r3,  #0
    mov         ip,  #1
    sub         r3,  r3,  #1
    lsl         ip,  ip,  r3

.ifc \size, 8x8
dequant_\size\()_rshift_loop:
    subs        r2,  r2,  #1
.endif
    vdup.32     q10, ip
    vld1.32     {d16-d17}, [r1,:128]!
    vdup.32     q11, ip
    vld1.32     {d18-d19}, [r1,:128]!
    vmovn.s32   d4,  q8
    vld1.32     {d16-d17}, [r1,:128]!
    vmovn.s32   d5,  q9
    vld1.32     {d18-d19}, [r1,:128]!
    vmovn.s32   d6,  q8
    vld1.16     {d0-d3},   [r0,:128]
    vmovn.s32   d7,  q9
    vdup.32     q12, ip
    vdup.32     q13, ip

    vmlal.s16   q10, d0,  d4
    vmlal.s16   q11, d1,  d5
    vmlal.s16   q12, d2,  d6
    vmlal.s16   q13, d3,  d7
    vshl.s32    q10, q10, q15
    vshl.s32    q11, q11, q15
    vshl.s32    q12, q12, q15
    vshl.s32    q13, q13, q15

    vmovn.s32   d0,  q10
    vmovn.s32   d1,  q11
    vmovn.s32   d2,  q12
    vmovn.s32   d3,  q13
    vst1.16     {d0-d3},   [r0,:128]!
.ifc \size, 8x8
    bgt         dequant_\size\()_rshift_loop
.endif
    bx          lr
.endfunc
.endm

DEQUANT 4x4, 4
DEQUANT 8x8, 6

// dequant_4x4_dc( int16_t dct[16], int dequant_mf[6][16], int i_qp )
function x264_dequant_4x4_dc_neon
    DEQUANT_START 6, 6, yes
    blt         dequant_4x4_dc_rshift

    lsl         r1,  r1,  r3
    vdup.16     q2,  r1
    vld1.16     {d0-d3},   [r0,:128]
    vdup.16     q15, r3

    vmul.s16    q0,  q0,  q2
    vmul.s16    q1,  q1,  q2
    vst1.16     {d0-d3},   [r0,:128]
    bx          lr

dequant_4x4_dc_rshift:
    vdup.16     d4,  r1
    vdup.32     q15, r3
    rsb         r3,  r3,  #0
    mov         ip,  #1
    sub         r3,  r3,  #1
    lsl         ip,  ip,  r3

    vdup.32     q10, ip
    vdup.32     q11, ip
    vld1.16     {d0-d3},   [r0,:128]
    vdup.32     q12, ip
    vdup.32     q13, ip

    vmlal.s16   q10, d0,  d4
    vmlal.s16   q11, d1,  d4
    vmlal.s16   q12, d2,  d4
    vmlal.s16   q13, d3,  d4
    vshl.s32    q10, q10, q15
    vshl.s32    q11, q11, q15
    vshl.s32    q12, q12, q15
    vshl.s32    q13, q13, q15

    vmovn.s32   d0,  q10
    vmovn.s32   d1,  q11
    vmovn.s32   d2,  q12
    vmovn.s32   d3,  q13
    vst1.16     {d0-d3},   [r0,:128]
    bx          lr
.endfunc


// int coeff_last( int16_t *l )
function x264_coeff_last4_arm
    ldrd        r2,  r3, [r0]
    subs        r0,  r3,  #0
    movne       r0,  #2
    movne       r2,  r3
    lsrs        r2,  r2,  #16
    addne       r0,  r0,  #1
    bx          lr
.endfunc

.macro COEFF_LAST_1x size
function x264_coeff_last\size\()_neon
.if \size == 15
    sub         r0,  r0,  #2
    vld1.64     {d0-d3}, [r0]
.else
    vld1.64     {d0-d3}, [r0,:128]
.endif
    vtst.16     q0,  q0
    vtst.16     q1,  q1
    vshrn.u16   d0,  q0,  #8
    vshrn.u16   d1,  q1,  #8
    vshrn.u16   d0,  q0,  #4
    vclz.i32    d0,  d0
    mov         ip,  #7
    mov         r3,  #\size - 9
    vmov        r0,  r1,  d0

    subs        r1,  ip,  r1,  lsr #2
    addge       r0,  r1,  #\size - 8
    sublt       r0,  r3,  r0,  lsr #2
    movlt       r0,  #0
    bx          lr
.endfunc
.endm

COEFF_LAST_1x 15
COEFF_LAST_1x 16

function x264_coeff_last64_neon
    vld1.64     {d16-d19}, [r0,:128]!
    vqmovn.u16  d16, q8
    vqmovn.u16  d17, q9
    vld1.64     {d20-d23}, [r0,:128]!
    vqmovn.u16  d18, q10
    vqmovn.u16  d19, q11
    vld1.64     {d24-d27}, [r0,:128]!
    vqmovn.u16  d20, q12
    vqmovn.u16  d21, q13
    vld1.64     {d28-d31}, [r0,:128]!
    vqmovn.u16  d22, q14
    vqmovn.u16  d23, q15

    movrel      r1, pmovmskb_byte
    vld1.64     {d0-d1}, [r1,:128]

    vtst.8      q8,  q8
    vtst.8      q9,  q9
    vtst.8      q10, q10
    vtst.8      q11, q11

    vand        q8,  q8,  q0
    vand        q9,  q9,  q0
    vand        q10, q10, q0
    vand        q11, q11, q0

    vpadd.u8    d0,  d16, d17
    vpadd.u8    d1,  d18, d19
    vpadd.u8    d2,  d20, d21
    vpadd.u8    d3,  d22, d23
    vpadd.u8    d0,  d0,  d1
    vpadd.u8    d1,  d2,  d3
    vpadd.u8    d0,  d0,  d1
    vclz.i32    d0,  d0
    mov         ip,  #31
    vmov        r0,  r1,  d0

    subs        r1,  ip,  r1
    addge       r0,  r1,  #32
    sublt       r0,  ip,  r0
    movlt       r0,  #0
    bx          lr
.endfunc
