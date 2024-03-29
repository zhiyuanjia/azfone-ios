/*****************************************************************************
 * mc.S: arm motion compensation
 *****************************************************************************
 * Copyright (C) 2009-2012 x264 project
 *
 * Authors: David Conrad <lessen42@gmail.com>
 *          Mans Rullgard <mans@mansr.com>
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
.text

// note: prefetch stuff assumes 64-byte cacheline, true for the Cortex-A8
// They also use nothing above armv5te, but we don't care about pre-armv6

// void prefetch_ref( uint8_t *pix, intptr_t stride, int parity )
function x264_prefetch_ref_arm
    sub         r2, r2, #1
    add         r0, r0, #64
    and         r2, r2, r1
    add         r0, r0, r2, lsl #3
    add         r2, r1, r1, lsl #1
    pld         [r0]
    pld         [r0, r1]
    pld         [r0, r1, lsl #1]
    add         r3, r0, r1, lsl #2
    pld         [r0, r2]
    pld         [r3]
    pld         [r3, r1]
    pld         [r3, r1, lsl #1]
    pld         [r3, r2]
    bx          lr
.endfunc

// void prefetch_fenc( uint8_t *pix_y,  intptr_t stride_y,
//                     uint8_t *pix_uv, intptr_t stride_uv, int mb_x )
function x264_prefetch_fenc_arm
    ldr         ip, [sp]
    push        {lr}
    and         lr, ip, #3
    smulbb      lr, lr, r1      // note: this assumes stride_y is <= 16 bits signed
    and         ip, ip, #6
    smulbb      ip, ip, r3
    add         r0, r0, #64
    add         r2, r2, #64
    add         r0, r0, lr, lsl #2
    pld         [r0]
    add         lr, r0, r1, lsl #1
    pld         [r0, r1]
    pld         [lr]
    add         r2, r2, ip, lsl #2
    pld         [lr, r1]
    pld         [r2]
    add         ip, r2, r3, lsl #1
    pld         [r2, r3]
    pld         [ip]
    pld         [ip, r3]
    pop         {pc}
.endfunc


// void *x264_memcpy_aligned( void *dst, const void *src, size_t n )
function x264_memcpy_aligned_neon
    orr         r3,  r0,  r1,  lsr #1
    movrel      ip,  memcpy_table
    and         r3,  r3,  #0xc
    ldr         pc,  [ip, r3]
.endfunc

.macro MEMCPY_ALIGNED srcalign dstalign
function memcpy_aligned_\dstalign\()_\srcalign\()_neon
    mov         r3, r0
.if \srcalign == 8 && \dstalign == 8
    sub         r2, #16
    vld1.64     {d0}, [r1,:64]!
    vst1.64     {d0}, [r3,:64]!
    .set r1align, 128
    .set r3align, 128
.else
    .set r1align, \srcalign * 8
    .set r3align, \dstalign * 8
.endif
    tst         r2, #16
    beq         32f
    sub         r2, #16
    vld1.64     {d0-d1}, [r1,:r1align]!
    vst1.64     {d0-d1}, [r3,:r3align]!
32: // n is a multiple of 32
    tst         r2, #32
    beq         640f
    sub         r2, #32
    vld1.64     {d0-d3}, [r1,:r1align]!
    vst1.64     {d0-d3}, [r3,:r3align]!
640: // n is a multiple of 64
    cmp         r2, #0
    beq         1f
64:
    subs        r2, #64
    vld1.64     {d0-d3}, [r1,:r1align]!
    vld1.64     {d4-d7}, [r1,:r1align]!
    vst1.64     {d0-d3}, [r3,:r3align]!
    vst1.64     {d4-d7}, [r3,:r3align]!
    bgt         64b
1:   // end
.if \srcalign == 8 && \dstalign == 8
    vld1.64     {d0}, [r1,:64]!
    vst1.64     {d0}, [r3,:64]!
.endif
    bx          lr
.endfunc
.endm

MEMCPY_ALIGNED 16, 16
MEMCPY_ALIGNED 16, 8
MEMCPY_ALIGNED  8, 16
MEMCPY_ALIGNED  8, 8

.section .rodata
memcpy_table:
.word memcpy_aligned_16_16_neon
.word memcpy_aligned_16_8_neon
.word memcpy_aligned_8_16_neon
.word memcpy_aligned_8_8_neon
.text

.ltorg

// void x264_memzero_aligned( void *dst, size_t n )
function x264_memzero_aligned_neon
    vmov.i8     q0, #0
    vmov.i8     q1, #0
memzero_loop:
    subs        r1, #128
.rept 4
    vst1.64     {d0-d3}, [r0,:128]!
.endr
    bgt         memzero_loop
    bx          lr
.endfunc


// void pixel_avg( uint8_t *dst,  intptr_t dst_stride,
//                 uint8_t *src1, intptr_t src1_stride,
//                 uint8_t *src2, intptr_t src2_stride, int weight );
.macro AVGH w h
function x264_pixel_avg_\w\()x\h\()_neon
    ldr         ip, [sp, #8]
    push        {r4-r6,lr}
    cmp         ip, #32
    ldrd        r4, r5, [sp, #16]
    mov         lr, #\h
    beq         x264_pixel_avg_w\w\()_neon
    rsbs        r6,  ip,  #64
    blt         x264_pixel_avg_weight_w\w\()_add_sub_neon     // weight > 64
    cmp         ip,  #0
    bge         x264_pixel_avg_weight_w\w\()_add_add_neon
    b           x264_pixel_avg_weight_w\w\()_sub_add_neon     // weight < 0
.endfunc
.endm

AVGH  4, 2
AVGH  4, 4
AVGH  4, 8
AVGH  8, 4
AVGH  8, 8
AVGH  8, 16
AVGH 16, 8
AVGH 16, 16

// 0 < weight < 64
.macro load_weights_add_add
    vdup.8      d30, ip
    vdup.8      d31, r6
.endm

.macro load_add_add d1 d2
    vld1.32     {\d1}, [r2], r3
    vld1.32     {\d2}, [r4], r5
.endm

.macro weight_add_add dst s1 s2
    vmull.u8    \dst, \s1, d30
    vmlal.u8    \dst, \s2, d31
.endm

// weight > 64
.macro load_weights_add_sub
    rsb         r6,  #0
    vdup.8      d30, ip
    vdup.8      d31, r6
.endm

.macro load_add_sub d1 d2
    vld1.32     {\d1}, [r2], r3
    vld1.32     {\d2}, [r4], r5
.endm

.macro weight_add_sub dst s1 s2
    vmull.u8    \dst, \s1, d30
    vmlsl.u8    \dst, \s2, d31
.endm

// weight < 0
.macro load_weights_sub_add
    rsb         ip,  #0
    vdup.8      d31, r6
    vdup.8      d30, ip
.endm

.macro load_sub_add d1 d2
    vld1.32     {\d2}, [r4], r5
    vld1.32     {\d1}, [r2], r3
.endm

.macro weight_sub_add dst s1 s2
    vmull.u8    \dst, \s2, d31
    vmlsl.u8    \dst, \s1, d30
.endm

.macro AVG_WEIGHT ext
function x264_pixel_avg_weight_w4_\ext\()_neon
    load_weights_\ext
1:  // height loop
    subs            lr,  lr,  #2
    load_\ext       d0[], d1[]
    weight_\ext     q8,  d0,  d1
    load_\ext       d2[], d3[]
    vqrshrun.s16    d0,  q8,  #6
    weight_\ext     q9,  d2,  d3
    vst1.32         {d0[0]}, [r0,:32], r1
    vqrshrun.s16    d1,  q9,  #6
    vst1.32         {d1[0]}, [r0,:32], r1
    bgt             1b
    pop             {r4-r6,pc}
.endfunc

function x264_pixel_avg_weight_w8_\ext\()_neon
    load_weights_\ext
1:  // height loop
    subs            lr,  lr,  #4
    load_\ext       d0,  d1
    weight_\ext     q8,  d0,  d1
    load_\ext       d2,  d3
    weight_\ext     q9,  d2,  d3
    load_\ext       d4,  d5
    weight_\ext     q10, d4,  d5
    load_\ext       d6,  d7
    weight_\ext     q11, d6,  d7
    vqrshrun.s16    d0,  q8,  #6
    vqrshrun.s16    d1,  q9,  #6
    vqrshrun.s16    d2,  q10, #6
    vqrshrun.s16    d3,  q11, #6
    vst1.64         {d0}, [r0,:64], r1
    vst1.64         {d1}, [r0,:64], r1
    vst1.64         {d2}, [r0,:64], r1
    vst1.64         {d3}, [r0,:64], r1
    bgt             1b
    pop             {r4-r6,pc}
.endfunc

function x264_pixel_avg_weight_w16_\ext\()_neon
    load_weights_\ext
1:  // height loop
    subs            lr,  lr,  #2
    load_\ext       d0-d1, d2-d3
    weight_\ext     q8,  d0,  d2
    weight_\ext     q9,  d1,  d3
    load_\ext       d4-d5, d6-d7
    weight_\ext     q10, d4,  d6
    weight_\ext     q11, d5,  d7
    vqrshrun.s16    d0,  q8,  #6
    vqrshrun.s16    d1,  q9,  #6
    vqrshrun.s16    d2,  q10, #6
    vqrshrun.s16    d3,  q11, #6
    vst1.64         {d0-d1}, [r0,:128], r1
    vst1.64         {d2-d3}, [r0,:128], r1
    bgt             1b
    pop             {r4-r6,pc}
.endfunc
.endm

AVG_WEIGHT add_add
AVG_WEIGHT add_sub
AVG_WEIGHT sub_add

function x264_pixel_avg_w4_neon
    subs        lr,  lr,  #2
    vld1.32     {d0[]}, [r2], r3
    vld1.32     {d2[]}, [r4], r5
    vrhadd.u8   d0,  d0,  d2
    vld1.32     {d1[]}, [r2], r3
    vld1.32     {d3[]}, [r4], r5
    vrhadd.u8   d1,  d1,  d3
    vst1.32     {d0[0]}, [r0,:32], r1
    vst1.32     {d1[0]}, [r0,:32], r1
    bgt         x264_pixel_avg_w4_neon
    pop         {r4-r6,pc}
.endfunc

function x264_pixel_avg_w8_neon
    subs        lr,  lr,  #4
    vld1.64     {d0}, [r2], r3
    vld1.64     {d2}, [r4], r5
    vrhadd.u8   d0,  d0,  d2
    vld1.64     {d1}, [r2], r3
    vld1.64     {d3}, [r4], r5
    vrhadd.u8   d1,  d1,  d3
    vst1.64     {d0}, [r0,:64], r1
    vld1.64     {d2}, [r2], r3
    vld1.64     {d4}, [r4], r5
    vrhadd.u8   d2,  d2,  d4
    vst1.64     {d1}, [r0,:64], r1
    vld1.64     {d3}, [r2], r3
    vld1.64     {d5}, [r4], r5
    vrhadd.u8   d3,  d3,  d5
    vst1.64     {d2}, [r0,:64], r1
    vst1.64     {d3}, [r0,:64], r1
    bgt         x264_pixel_avg_w8_neon
    pop         {r4-r6,pc}
.endfunc

function x264_pixel_avg_w16_neon
    subs        lr,  lr,  #4
    vld1.64     {d0-d1}, [r2], r3
    vld1.64     {d2-d3}, [r4], r5
    vrhadd.u8   q0,  q0,  q1
    vld1.64     {d2-d3}, [r2], r3
    vld1.64     {d4-d5}, [r4], r5
    vrhadd.u8   q1,  q1,  q2
    vst1.64     {d0-d1}, [r0,:128], r1
    vld1.64     {d4-d5}, [r2], r3
    vld1.64     {d6-d7}, [r4], r5
    vrhadd.u8   q2,  q2,  q3
    vst1.64     {d2-d3}, [r0,:128], r1
    vld1.64     {d6-d7}, [r2], r3
    vld1.64     {d0-d1}, [r4], r5
    vrhadd.u8   q3,  q3,  q0
    vst1.64     {d4-d5}, [r0,:128], r1
    vst1.64     {d6-d7}, [r0,:128], r1
    bgt         x264_pixel_avg_w16_neon
    pop         {r4-r6,pc}
.endfunc


function x264_pixel_avg2_w4_neon
    ldr         ip,  [sp, #4]
    push        {lr}
    ldr         lr,  [sp, #4]
avg2_w4_loop:
    subs        ip,  ip,  #2
    vld1.32     {d0[]},  [r2], r3
    vld1.32     {d2[]},  [lr], r3
    vrhadd.u8   d0,  d0,  d2
    vld1.32     {d1[]},  [r2], r3
    vld1.32     {d3[]},  [lr], r3
    vrhadd.u8   d1,  d1,  d3
    vst1.32     {d0[0]}, [r0,:32], r1
    vst1.32     {d1[0]}, [r0,:32], r1
    bgt         avg2_w4_loop
    pop         {pc}
.endfunc

function x264_pixel_avg2_w8_neon
    ldr         ip,  [sp, #4]
    push        {lr}
    ldr         lr,  [sp, #4]
avg2_w8_loop:
    subs        ip,  ip,  #2
    vld1.64     {d0}, [r2], r3
    vld1.64     {d2}, [lr], r3
    vrhadd.u8   d0,  d0,  d2
    vld1.64     {d1}, [r2], r3
    vld1.64     {d3}, [lr], r3
    vrhadd.u8   d1,  d1,  d3
    vst1.64     {d0}, [r0,:64], r1
    vst1.64     {d1}, [r0,:64], r1
    bgt         avg2_w8_loop
    pop         {pc}
.endfunc

function x264_pixel_avg2_w16_neon
    ldr         ip,  [sp, #4]
    push        {lr}
    ldr         lr,  [sp, #4]
avg2_w16_loop:
    subs        ip,  ip,  #2
    vld1.64     {d0-d1}, [r2], r3
    vld1.64     {d2-d3}, [lr], r3
    vrhadd.u8   q0,  q0,  q1
    vld1.64     {d4-d5}, [r2], r3
    vld1.64     {d6-d7}, [lr], r3
    vrhadd.u8   q2,  q2,  q3
    vst1.64     {d0-d1}, [r0,:128], r1
    vst1.64     {d4-d5}, [r0,:128], r1
    bgt         avg2_w16_loop
    pop         {pc}
.endfunc

function x264_pixel_avg2_w20_neon
    ldr         ip,  [sp, #4]
    push        {lr}
    sub         r1,  r1,  #16
    ldr         lr,  [sp, #4]
avg2_w20_loop:
    subs        ip,  ip,  #2
    vld1.64     {d0-d2},  [r2], r3
    vld1.64     {d4-d6},  [lr], r3
    vrhadd.u8   q0,  q0,  q2
    vrhadd.u8   d2,  d2,  d6
    vld1.64     {d4-d6},  [r2], r3
    vld1.64     {d16-d18},[lr], r3
    vrhadd.u8   q2,  q2,  q8
    vst1.64     {d0-d1},  [r0,:128]!
    vrhadd.u8   d6,  d6,  d18
    vst1.32     {d2[0]},  [r0,:32], r1
    vst1.64     {d4-d5},  [r0,:128]!
    vst1.32     {d6[0]},  [r0,:32], r1
    bgt         avg2_w20_loop
    pop         {pc}
.endfunc


.macro weight_prologue type
    push        {r4-r5,lr}
    ldr         r4,  [sp, #4*3]     // weight_t
    ldr         ip,  [sp, #4*3+4]   // h
.ifc \type, full
    ldr         lr,  [r4, #32]      // denom
.endif
    ldrd        r4,  r5,  [r4, #32+4]    // scale, offset
    vdup.16     q0,  r4
    vdup.16     q1,  r5
.ifc \type, full
    rsb         lr,  lr,  #0
    vdup.16     q2,  lr
.endif
.endm

// void mc_weight( uint8_t *src, intptr_t src_stride, uint8_t *dst, intptr_t dst_stride,
//                 const x264_weight_t *weight, int height )
function x264_mc_weight_w20_neon
    weight_prologue full
    sub         r1, #16
weight20_loop:
    subs        ip,  #2
    vld1.8      {d17-d19}, [r2], r3
    vmovl.u8    q10, d17
    vmovl.u8    q11, d18
    vmovl.u8    q14, d19
    vld1.8      {d16-d18}, [r2], r3
    vmovl.u8    q12, d16
    vmovl.u8    q13, d17
    vmovl.u8    q15, d18
    vmul.s16    q10, q10, q0
    vmul.s16    q11, q11, q0
    vmul.s16    q12, q12, q0
    vmul.s16    q13, q13, q0
    vmul.s16    d28, d28, d0
    vmul.s16    d29, d30, d0
    vrshl.s16   q10, q10, q2
    vrshl.s16   q11, q11, q2
    vrshl.s16   q12, q12, q2
    vrshl.s16   q13, q13, q2
    vrshl.s16   q14, q14, q2
    vadd.s16    q10, q10, q1
    vadd.s16    q11, q11, q1
    vadd.s16    q12, q12, q1
    vadd.s16    q13, q13, q1
    vadd.s16    q14, q14, q1
    vqmovun.s16 d16, q10
    vqmovun.s16 d17, q11
    vqmovun.s16 d18, q12
    vqmovun.s16 d19, q13
    vqmovun.s16 d20, q14
    vst1.8      {d16-d17}, [r0,:128]!
    vst1.32     {d20[0]},  [r0,:32], r1
    vst1.8      {d18-d19}, [r0,:128]!
    vst1.32     {d20[1]},  [r0,:32], r1
    bgt         weight20_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w16_neon
    weight_prologue full
weight16_loop:
    subs        ip,  #2
    vld1.8      {d16-d17}, [r2], r3
    vld1.8      {d18-d19}, [r2], r3
    vmovl.u8    q10, d16
    vmovl.u8    q11, d17
    vmovl.u8    q12, d18
    vmovl.u8    q13, d19
    vmul.s16    q10, q10, q0
    vmul.s16    q11, q11, q0
    vmul.s16    q12, q12, q0
    vmul.s16    q13, q13, q0
    vrshl.s16   q10, q10, q2
    vrshl.s16   q11, q11, q2
    vrshl.s16   q12, q12, q2
    vrshl.s16   q13, q13, q2
    vadd.s16    q10, q10, q1
    vadd.s16    q11, q11, q1
    vadd.s16    q12, q12, q1
    vadd.s16    q13, q13, q1
    vqmovun.s16 d16, q10
    vqmovun.s16 d17, q11
    vqmovun.s16 d18, q12
    vqmovun.s16 d19, q13
    vst1.8      {d16-d17}, [r0,:128], r1
    vst1.8      {d18-d19}, [r0,:128], r1
    bgt         weight16_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w8_neon
    weight_prologue full
weight8_loop:
    subs        ip,  #2
    vld1.8      {d16}, [r2], r3
    vld1.8      {d18}, [r2], r3
    vmovl.u8    q8,  d16
    vmovl.u8    q9,  d18
    vmul.s16    q8,  q8,  q0
    vmul.s16    q9,  q9,  q0
    vrshl.s16   q8,  q8,  q2
    vrshl.s16   q9,  q9,  q2
    vadd.s16    q8,  q8,  q1
    vadd.s16    q9,  q9,  q1
    vqmovun.s16 d16, q8
    vqmovun.s16 d18, q9
    vst1.8      {d16}, [r0,:64], r1
    vst1.8      {d18}, [r0,:64], r1
    bgt         weight8_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w4_neon
    weight_prologue full
weight4_loop:
    subs        ip,  #2
    vld1.32     {d16[]}, [r2], r3
    vld1.32     {d18[]}, [r2], r3
    vmovl.u8    q8,  d16
    vmovl.u8    q9,  d18
    vmul.s16    d16, d16, d0
    vmul.s16    d17, d18, d0
    vrshl.s16   q8,  q8,  q2
    vadd.s16    q8,  q8,  q1
    vqmovun.s16 d16, q8
    vst1.32     {d16[0]}, [r0,:32], r1
    vst1.32     {d16[1]}, [r0,:32], r1
    bgt         weight4_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w20_nodenom_neon
    weight_prologue nodenom
    sub         r1, #16
weight20_nodenom_loop:
    subs        ip,  #2
    vld1.8      {d17-d19}, [r2], r3
    vmovl.u8    q10, d17
    vmovl.u8    q11, d18
    vmovl.u8    q14, d19
    vld1.8      {d16-d18}, [r2], r3
    vmovl.u8    q12, d16
    vmovl.u8    q13, d17
    vmovl.u8    q15, d18
    vmov        q8,  q1
    vmov        q9,  q1
    vmla.s16    q8,  q10, q0
    vmla.s16    q9,  q11, q0
    vmov        q10, q1
    vmov        q11, q1
    vmla.s16    q10, q12, q0
    vmla.s16    q11, q13, q0
    vmov        q12, q1
    vmla.s16    d24, d28, d0
    vmla.s16    d25, d30, d0
    vqmovun.s16 d16, q8
    vqmovun.s16 d17, q9
    vqmovun.s16 d18, q10
    vqmovun.s16 d19, q11
    vqmovun.s16 d20, q12
    vst1.8      {d16-d17}, [r0,:128]!
    vst1.32     {d20[0]},  [r0,:32], r1
    vst1.8      {d18-d19}, [r0,:128]!
    vst1.32     {d20[1]},  [r0,:32], r1
    bgt         weight20_nodenom_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w16_nodenom_neon
    weight_prologue nodenom
weight16_nodenom_loop:
    subs        ip,  #2
    vld1.8      {d16-d17}, [r2], r3
    vld1.8      {d18-d19}, [r2], r3
    vmovl.u8    q12, d16
    vmovl.u8    q13, d17
    vmovl.u8    q14, d18
    vmovl.u8    q15, d19
    vmov        q8,  q1
    vmov        q9,  q1
    vmov        q10, q1
    vmov        q11, q1
    vmla.s16    q8,  q12, q0
    vmla.s16    q9,  q13, q0
    vmla.s16    q10, q14, q0
    vmla.s16    q11, q15, q0
    vqmovun.s16 d16, q8
    vqmovun.s16 d17, q9
    vqmovun.s16 d18, q10
    vqmovun.s16 d19, q11
    vst1.8      {d16-d17}, [r0,:128], r1
    vst1.8      {d18-d19}, [r0,:128], r1
    bgt         weight16_nodenom_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w8_nodenom_neon
    weight_prologue nodenom
weight8_nodenom_loop:
    subs        ip,  #2
    vld1.8      {d16}, [r2], r3
    vld1.8      {d18}, [r2], r3
    vmovl.u8    q8,  d16
    vmovl.u8    q9,  d18
    vmov        q10, q1
    vmov        q11, q1
    vmla.s16    q10, q8,  q0
    vmla.s16    q11, q9,  q0
    vqmovun.s16 d16, q10
    vqmovun.s16 d17, q11
    vst1.8      {d16}, [r0,:64], r1
    vst1.8      {d17}, [r0,:64], r1
    bgt         weight8_nodenom_loop
    pop         {r4-r5,pc}
.endfunc

function x264_mc_weight_w4_nodenom_neon
    weight_prologue nodenom
weight4_nodenom_loop:
    subs        ip,  #2
    vld1.32     {d16[]}, [r2], r3
    vld1.32     {d18[]}, [r2], r3
    vmovl.u8    q8,  d16
    vmovl.u8    q9,  d18
    vmov        q10, q1
    vmla.s16    d20, d16, d0
    vmla.s16    d21, d18, d0
    vqmovun.s16 d16, q10
    vst1.32     {d16[0]}, [r0,:32], r1
    vst1.32     {d16[1]}, [r0,:32], r1
    bgt         weight4_nodenom_loop
    pop         {r4-r5,pc}
.endfunc

.macro weight_simple_prologue
    push        {lr}
    ldr         lr,  [sp, #4]       // weight_t
    ldr         ip,  [sp, #8]       // h
    ldr         lr,  [lr]           // offset
    vdup.8      q1,  lr
.endm

.macro weight_simple name op
function x264_mc_weight_w20_\name\()_neon
    weight_simple_prologue
weight20_\name\()_loop:
    subs        ip,  #2
    vld1.8      {d16-d18}, [r2], r3
    vld1.8      {d19-d21}, [r2], r3
    \op         q8,  q8,  q1
    \op         q9,  q9,  q1
    \op         q10, q10, q1
    vst1.8      {d16-d18}, [r0,:64], r1
    vst1.8      {d19-d21}, [r0,:64], r1
    bgt         weight20_\name\()_loop
    pop         {pc}
.endfunc

function x264_mc_weight_w16_\name\()_neon
    weight_simple_prologue
weight16_\name\()_loop:
    subs        ip,  #2
    vld1.8      {d16-d17}, [r2], r3
    vld1.8      {d18-d19}, [r2], r3
    \op         q8,  q8,  q1
    \op         q9,  q9,  q1
    vst1.8      {d16-d17}, [r0,:128], r1
    vst1.8      {d18-d19}, [r0,:128], r1
    bgt         weight16_\name\()_loop
    pop         {pc}
.endfunc

function x264_mc_weight_w8_\name\()_neon
    weight_simple_prologue
weight8_\name\()_loop:
    subs        ip,  #2
    vld1.8      {d16}, [r2], r3
    vld1.8      {d17}, [r2], r3
    \op         q8,  q8,  q1
    vst1.8      {d16}, [r0,:64], r1
    vst1.8      {d17}, [r0,:64], r1
    bgt         weight8_\name\()_loop
    pop         {pc}
.endfunc

function x264_mc_weight_w4_\name\()_neon
    weight_simple_prologue
weight4_\name\()_loop:
    subs        ip,  #2
    vld1.32     {d16[]}, [r2], r3
    vld1.32     {d17[]}, [r2], r3
    \op         q8,  q8,  q1
    vst1.32     {d16[0]}, [r0,:32], r1
    vst1.32     {d17[0]}, [r0,:32], r1
    bgt         weight4_\name\()_loop
    pop         {pc}
.endfunc
.endm

weight_simple offsetadd, vqadd.u8
weight_simple offsetsub, vqsub.u8


// void mc_copy( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride, int height )
function x264_mc_copy_w4_neon
    ldr         ip,  [sp]
copy_w4_loop:
    subs        ip,  ip,  #4
    vld1.32     {d0[]},  [r2], r3
    vld1.32     {d1[]},  [r2], r3
    vld1.32     {d2[]},  [r2], r3
    vld1.32     {d3[]},  [r2], r3
    vst1.32     {d0[0]}, [r0,:32], r1
    vst1.32     {d1[0]}, [r0,:32], r1
    vst1.32     {d2[0]}, [r0,:32], r1
    vst1.32     {d3[0]}, [r0,:32], r1
    bgt         copy_w4_loop
    bx          lr
.endfunc

function x264_mc_copy_w8_neon
    ldr         ip,  [sp]
copy_w8_loop:
    subs        ip,  ip,  #4
    vld1.32     {d0}, [r2], r3
    vld1.32     {d1}, [r2], r3
    vld1.32     {d2}, [r2], r3
    vld1.32     {d3}, [r2], r3
    vst1.32     {d0}, [r0,:64], r1
    vst1.32     {d1}, [r0,:64], r1
    vst1.32     {d2}, [r0,:64], r1
    vst1.32     {d3}, [r0,:64], r1
    bgt         copy_w8_loop
    bx          lr
.endfunc

function x264_mc_copy_w16_neon
    ldr         ip,  [sp]
copy_w16_loop:
    subs        ip,  ip,  #4
    vld1.32     {d0-d1}, [r2], r3
    vld1.32     {d2-d3}, [r2], r3
    vld1.32     {d4-d5}, [r2], r3
    vld1.32     {d6-d7}, [r2], r3
    vst1.32     {d0-d1}, [r0,:128], r1
    vst1.32     {d2-d3}, [r0,:128], r1
    vst1.32     {d4-d5}, [r0,:128], r1
    vst1.32     {d6-d7}, [r0,:128], r1
    bgt         copy_w16_loop
    bx          lr
.endfunc

function x264_mc_copy_w16_aligned_neon
    ldr         ip,  [sp]
copy_w16_aligned_loop:
    subs        ip,  ip,  #4
    vld1.32     {d0-d1}, [r2,:128], r3
    vld1.32     {d2-d3}, [r2,:128], r3
    vld1.32     {d4-d5}, [r2,:128], r3
    vld1.32     {d6-d7}, [r2,:128], r3
    vst1.32     {d0-d1}, [r0,:128], r1
    vst1.32     {d2-d3}, [r0,:128], r1
    vst1.32     {d4-d5}, [r0,:128], r1
    vst1.32     {d6-d7}, [r0,:128], r1
    bgt         copy_w16_aligned_loop
    bx          lr
.endfunc


// void x264_mc_chroma_neon( uint8_t *dst, intptr_t i_dst_stride,
//                           uint8_t *src, intptr_t i_src_stride,
//                           int dx, int dy, int i_width, int i_height );
function x264_mc_chroma_neon
    push            {r4-r6, lr}
    ldrd            r4,  r5,  [sp, #16]
    ldr             r6,  [sp, #24]

    asr             lr,  r5,  #3
    mul             lr,  r3,  lr
    add             r2,  r2,  r4,  asr #3
    cmp             r6, #4
    add             r2,  r2,  lr

    and             r4, r4, #7
    and             r5, r5, #7
    pld             [r2]
    pld             [r2, r3]

    bgt             mc_chroma_w8
    beq             mc_chroma_w4

// calculate cA cB cC cD
.macro CHROMA_MC_START r0 r1
    muls            lr,  r4,  r5
    rsb             r6,  lr,  r5,  lsl #3
    rsb             ip,  lr,  r4,  lsl #3
    sub             r4,  lr,  r4,  lsl #3
    sub             r4,  r4,  r5,  lsl #3
    add             r4,  r4,  #64

    beq             2f

    add             r5,  r2,  r3

    vdup.8          d0,  r4
    lsl             r3,  r3,  #1
    vdup.8          d1,  ip
    vld1.64         {\r0}, [r2], r3
    vdup.8          d2,  r6
    vld1.64         {\r1}, [r5], r3
    vdup.8          d3,  lr
    ldr             r4,  [sp, #28]

    vext.8          d5,  d4,  d5,  #1
    vext.8          d7,  d6,  d7,  #1
.endm

.macro CHROMA_MC width, align
mc_chroma_w\width:
    CHROMA_MC_START d4,  d6
// since the element size varies, there's a different index for the 2nd store
.if \width == 4
    .set st2, 1
.else
    .set st2, 2
.endif

    vtrn.32         d4,  d5
    vtrn.32         d6,  d7

    vtrn.32         d0,  d1
    vtrn.32         d2,  d3

1:  // height loop, interpolate xy
    pld             [r5]
    vmull.u8        q8,  d4,  d0
    vmlal.u8        q8,  d6,  d2
    vld1.64         {d4},     [r2], r3
    vext.8          d5,  d4,  d5,  #1
    vtrn.32         d4,  d5
    vmull.u8        q9,  d6,  d0
    vmlal.u8        q9,  d4,  d2
    vld1.64         {d6},     [r5], r3
    vadd.i16        d16, d16, d17
    vadd.i16        d17, d18, d19
    vrshrn.u16      d16, q8,  #6
    subs            r4,  r4,  #2
    pld             [r2]
    vext.8          d7,  d6,  d7,  #1
    vtrn.32         d6,  d7
    vst1.\align     {d16[0]},   [r0,:\align], r1
    vst1.\align     {d16[st2]}, [r0,:\align], r1
    bgt             1b

    pop             {r4-r6, pc}

2:  // dx or dy are 0
    tst             r6,  r6
    add             ip,  ip,  r6
    vdup.8          d0,  r4
    vdup.8          d1,  ip
    vtrn.32         d0,  d1
    ldr             r4,  [sp, #28]

    beq             4f

    vext.32         d1,  d0,  d1,  #1
    add             r5,  r2,  r3
    lsl             r3,  r3,  #1
    vld1.32         {d4[0]},  [r2], r3
    vld1.32         {d4[1]},  [r5], r3

3:  // vertical interpolation loop
    pld             [r5]
    vmull.u8        q8,  d4,  d0
    vld1.32         {d4[0]},  [r2], r3
    vmull.u8        q9,  d4,  d1
    vld1.32         {d4[1]},  [r5], r3
    vadd.i16        d16, d16, d17
    vadd.i16        d17, d18, d19
    vrshrn.u16      d16, q8,  #6
    subs            r4,  r4,  #2
    pld             [r2]
    vst1.\align     {d16[0]},   [r0,:\align], r1
    vst1.\align     {d16[st2]}, [r0,:\align], r1
    bgt             3b

    pop             {r4-r6, pc}

4:  // dy is 0
    vld1.64         {d4},     [r2], r3
    vld1.64         {d6},     [r2], r3
    vext.8          d5,  d4,  d5,  #1
    vext.8          d7,  d6,  d7,  #1
    vtrn.32         d4,  d5
    vtrn.32         d6,  d7

5:  // horizontal interpolation loop
    vmull.u8        q8,  d4,  d0
    vmull.u8        q9,  d6,  d0
    subs            r4,  r4,  #2
    vld1.64         {d4},     [r2], r3
    vext.8          d5,  d4,  d5,  #1
    vtrn.32         d4,  d5
    vadd.i16        d16, d16, d17
    vadd.i16        d17, d18, d19
    pld             [r2]
    vrshrn.u16      d16, q8,  #6
    vld1.64         {d6},     [r2], r3
    vext.8          d7,  d6,  d7,  #1
    vtrn.32         d6,  d7
    pld             [r2]
    vst1.\align     {d16[0]},   [r0,:\align], r1
    vst1.\align     {d16[st2]}, [r0,:\align], r1
    bgt             5b

    pop             {r4-r6, pc}
.endm

    CHROMA_MC 2, 16
    CHROMA_MC 4, 32

// the optimial timing for width 8 is different enough that it's not
// readable to put it in the same macro as width 2/4
mc_chroma_w8:
    CHROMA_MC_START d4-d5, d6-d7

1:  // height loop, interpolate xy
    pld             [r5]
    vmull.u8        q8,  d4,  d0
    vmlal.u8        q8,  d5,  d1
    vld1.64         {d4, d5}, [r2], r3
    vmlal.u8        q8,  d6,  d2
    vext.8          d5,  d4,  d5,  #1
    vmlal.u8        q8,  d7,  d3
    vmull.u8        q9,  d6,  d0
    subs            r4,  r4,  #2
    vmlal.u8        q9,  d7,  d1
    vmlal.u8        q9,  d4,  d2
    vmlal.u8        q9,  d5,  d3
    vrshrn.u16      d16, q8,  #6
    vld1.64         {d6, d7}, [r5], r3
    pld             [r2]
    vrshrn.u16      d17, q9,  #6
    vext.8          d7,  d6,  d7,  #1
    vst1.64         {d16}, [r0,:64], r1
    vst1.64         {d17}, [r0,:64], r1
    bgt             1b

    pop             {r4-r6, pc}

2:  // dx or dy are 0
    tst             r6,  r6
    add             ip,  ip,  r6
    vdup.8          d0,  r4
    vdup.8          d1,  ip
    ldr             r4,  [sp, #28]

    beq             4f

    add             r5,  r2,  r3
    lsl             r3,  r3,  #1
    vld1.64         {d4}, [r2], r3
    vld1.64         {d6}, [r5], r3

3:  // vertical interpolation loop
    pld             [r5]
    vmull.u8        q8,  d4,  d0
    vmlal.u8        q8,  d6,  d1
    vld1.64         {d4}, [r2], r3
    vmull.u8        q9,  d6,  d0
    vmlal.u8        q9,  d4,  d1
    vld1.64         {d6}, [r5], r3
    vrshrn.u16      d16, q8,  #6
    vrshrn.u16      d17, q9,  #6
    subs            r4,  r4,  #2
    pld             [r2]
    vst1.64         {d16}, [r0,:64], r1
    vst1.64         {d17}, [r0,:64], r1
    bgt             3b

    pop             {r4-r6, pc}

4:  // dy is 0
    vld1.64         {d4, d5}, [r2], r3
    vld1.64         {d6, d7}, [r2], r3
    vext.8          d5,  d4,  d5,  #1
    vext.8          d7,  d6,  d7,  #1

5:  // horizontal interpolation loop
    pld             [r2]
    subs            r4,  r4,  #2
    vmull.u8        q8,  d4,  d0
    vmlal.u8        q8,  d5,  d1
    vld1.64         {d4,  d5}, [r2], r3
    vmull.u8        q9,  d6,  d0
    vmlal.u8        q9,  d7,  d1
    pld             [r2]
    vext.8          d5,  d4,  d5,  #1
    vrshrn.u16      d16, q8,  #6
    vrshrn.u16      d17, q9,  #6
    vld1.64         {d6, d7}, [r2], r3
    vext.8          d7,  d6,  d7,  #1
    vst1.64         {d16}, [r0,:64], r1
    vst1.64         {d17}, [r0,:64], r1
    bgt             5b

    pop             {r4-r6, pc}
.endfunc


// hpel_filter_v( uint8_t *dst, uint8_t *src, int16_t *buf, intptr_t stride, int width )
function x264_hpel_filter_v_neon
    ldr             ip,  [sp]
    sub             r1,  r1,  r3,  lsl #1
    push            {lr}
    add             lr,  r1,  ip
    vmov.u8         d30, #5
    vmov.u8         d31, #20

filter_v_loop:
    subs            ip,  ip,  #16
    vld1.64         {d0-d1},   [r1,:128], r3
    vld1.64         {d2-d3},   [r1,:128], r3
    vld1.64         {d4-d5},   [r1,:128], r3
    vld1.64         {d6-d7},   [r1,:128], r3
    vld1.64         {d16-d17}, [r1,:128], r3
    vld1.64         {d18-d19}, [r1,:128], r3
    sub             r1,  lr,  ip

    vaddl.u8        q10, d0,  d18
    vmlsl.u8        q10, d2,  d30
    vmlal.u8        q10, d4,  d31
    vmlal.u8        q10, d6,  d31
    vmlsl.u8        q10, d16, d30

    vaddl.u8        q11, d1,  d19
    vmlsl.u8        q11, d3,  d30
    vmlal.u8        q11, d5,  d31
    vmlal.u8        q11, d7,  d31
    vmlsl.u8        q11, d17, d30

    vqrshrun.s16    d0,  q10, #5
    vst1.64         {d20-d21}, [r2,:128]!
    vqrshrun.s16    d1,  q11, #5
    vst1.64         {d22-d23}, [r2,:128]!
    vst1.64         {d0-d1},   [r0,:128]!
    bgt             filter_v_loop
    pop             {pc}
.endfunc

// hpel_filter_c( uint8_t *dst, int16_t *buf, int width );
function x264_hpel_filter_c_neon
    sub             r1,  #16
    vld1.64         {d0-d3}, [r1,:128]!

    // unrolled 2x: 4% faster
filter_c_loop:
    subs            r2,  r2,  #16
    vld1.64         {d4-d7}, [r1,:128]!
    vext.16         q8,  q0,  q1,  #6
    vext.16         q12, q1,  q2,  #3
    vadd.s16        q8,  q8,  q12
    vext.16         q9,  q0,  q1,  #7
    vext.16         q11, q1,  q2,  #2
    vadd.s16        q9,  q9,  q11
    vext.16         q10, q1,  q2,  #1
    vext.16         q11, q1,  q2,  #6
    vadd.s16        q10, q1,  q10
    vsub.s16        q8,  q8,  q9    // a-b
    vext.16         q15, q2,  q3,  #3
    vsub.s16        q9,  q9,  q10   // b-c

    vext.16         q12, q1,  q2,  #7
    vshr.s16        q8,  q8,  #2    // (a-b)/4
    vadd.s16        q11, q11, q15
    vext.16         q14, q2,  q3,  #2
    vsub.s16        q8,  q8,  q9    // (a-b)/4-b+c
    vadd.s16        q12, q12, q14
    vext.16         q13, q2,  q3,  #1

    vshr.s16        q8,  q8,  #2    // ((a-b)/4-b+c)/4
    vadd.s16        q13, q2,  q13
    vadd.s16        q8,  q8,  q10   // ((a-b)/4-b+c)/4+c = (a-5*b+20*c)/16
    vsub.s16        q11, q11, q12   // a-b
    vsub.s16        q12, q12, q13   // b-c
    vshr.s16        q11, q11, #2    // (a-b)/4
    vqrshrun.s16    d30, q8,  #6
    vsub.s16        q11, q11, q12   // (a-b)/4-b+c
    vshr.s16        q11, q11, #2    // ((a-b)/4-b+c)/4
    vld1.64         {d0-d3}, [r1,:128]!
    vadd.s16        q11, q11, q13   // ((a-b)/4-b+c)/4+c = (a-5*b+20*c)/16

    vext.16         q8,  q2,  q3,  #6
    vqrshrun.s16    d31, q11,  #6
    vext.16         q12, q3,  q0,  #3
    vadd.s16        q8,  q8,  q12
    vext.16         q9,  q2,  q3,  #7
    vst1.64         {d30-d31}, [r0,:128]!
    bxle            lr
    subs            r2,  r2,  #16

    vext.16         q11, q3,  q0,  #2
    vadd.s16        q9,  q9,  q11
    vext.16         q10, q3,  q0,  #1
    vext.16         q11, q3,  q0,  #6
    vadd.s16        q10, q3,  q10
    vsub.s16        q8,  q8,  q9    // a-b
    vext.16         q15, q0,  q1,  #3
    vsub.s16        q9,  q9,  q10   // b-c

    vext.16         q12, q3,  q0,  #7
    vshr.s16        q8,  q8,  #2    // (a-b)/4
    vadd.s16        q11, q11, q15
    vext.16         q14, q0,  q1,  #2
    vsub.s16        q8,  q8,  q9    // (a-b)/4-b+c
    vadd.s16        q12, q12, q14
    vext.16         q13, q0,  q1,  #1

    vshr.s16        q8,  q8,  #2    // ((a-b)/4-b+c)/4
    vadd.s16        q13, q0,  q13
    vadd.s16        q8,  q8,  q10   // ((a-b)/4-b+c)/4+c = (a-5*b+20*c)/16
    vsub.s16        q11, q11, q12   // a-b
    vsub.s16        q12, q12, q13   // b-c
    vshr.s16        q11, q11, #2    // (a-b)/4
    vqrshrun.s16    d30, q8,  #6
    vsub.s16        q11, q11, q12   // (a-b)/4-b+c
    vshr.s16        q11, q11, #2    // ((a-b)/4-b+c)/4
    vadd.s16        q11, q11, q13   // ((a-b)/4-b+c)/4+c = (a-5*b+20*c)/16

    vqrshrun.s16    d31, q11,  #6
    vst1.64         {d30-d31}, [r0,:128]!
    bgt             filter_c_loop
    bx              lr
.endfunc

// hpel_filter_h( uint8_t *dst, uint8_t *src, int width );
function x264_hpel_filter_h_neon
    sub             r1,  #16
    vmov.u8         d30, #5
    vld1.64         {d0-d3}, [r1,:128]!
    vmov.u8         d31, #20

    // unrolled 3x because it's 5% faster, due to mitigating
    // the high latency of multiplication and vqrshrun
filter_h_loop:
    subs            r2,  r2,  #16
    vld1.64         {d4-d5}, [r1,:128]!
    vext.8          q8,  q0,  q1,  #14
    vext.8          q12, q1,  q2,  #3
    vaddl.u8        q13, d16, d24
    vext.8          q9,  q0,  q1,  #15
    vaddl.u8        q14, d17, d25

    vext.8          q10, q1,  q2,  #1
    vmlal.u8        q13, d2,  d31
    vmlsl.u8        q13, d18, d30
    vext.8          q11, q1,  q2,  #2
    vmlal.u8        q13, d20, d31
    vmlsl.u8        q13, d22, d30

    vmlsl.u8        q14, d19, d30
    vmlal.u8        q14, d3,  d31
    vmlal.u8        q14, d21, d31
    vmlsl.u8        q14, d23, d30
    vqrshrun.s16    d6,  q13, #5

    vld1.64         {d0-d1}, [r1,:128]!
    vext.8          q8,  q1,  q2,  #14
    vext.8          q12, q2,  q0,  #3
    vaddl.u8        q13, d16, d24
    vqrshrun.s16    d7,  q14, #5
    vext.8          q9,  q1,  q2,  #15
    vaddl.u8        q14, d17, d25

    vst1.64         {d6-d7}, [r0,:128]!
    bxle            lr
    subs            r2,  r2,  #16

    vext.8          q10, q2,  q0,  #1
    vmlal.u8        q13, d4,  d31
    vmlsl.u8        q13, d18, d30
    vext.8          q11, q2,  q0,  #2
    vmlal.u8        q13, d20, d31
    vmlsl.u8        q13, d22, d30

    vmlsl.u8        q14, d19, d30
    vmlal.u8        q14, d5,  d31
    vmlal.u8        q14, d21, d31
    vmlsl.u8        q14, d23, d30
    vqrshrun.s16    d6,  q13, #5

    vld1.64         {d2-d3}, [r1,:128]!
    vext.8          q8,  q2,  q0,  #14
    vext.8          q12, q0,  q1,  #3
    vaddl.u8        q13, d16, d24
    vqrshrun.s16    d7,  q14, #5
    vext.8          q9,  q2,  q0,  #15
    vaddl.u8        q14, d17, d25

    vst1.64         {d6-d7}, [r0,:128]!
    bxle            lr
    subs            r2,  r2,  #16

    vext.8          q10, q0,  q1,  #1
    vmlal.u8        q13, d0,  d31
    vmlsl.u8        q13, d18, d30
    vext.8          q11, q0,  q1,  #2
    vmlal.u8        q13, d20, d31
    vmlsl.u8        q13, d22, d30

    vmlsl.u8        q14, d19, d30
    vmlal.u8        q14, d1,  d31
    vmlal.u8        q14, d21, d31
    vmlsl.u8        q14, d23, d30

    vqrshrun.s16    d6, q13, #5
    vqrshrun.s16    d7, q14, #5
    vst1.64         {d6-d7}, [r0,:128]!
    bgt             filter_h_loop
    bx              lr
.endfunc


// frame_init_lowres_core( uint8_t *src0, uint8_t *dst0, uint8_t *dsth, uint8_t *dstv,
//                         uint8_t *dstc, intptr_t src_stride, intptr_t dst_stride, int width,
//                         int height )
function x264_frame_init_lowres_core_neon
    push            {r4-r10,lr}
    vpush           {d8-d15}
    ldrd            r4,  r5,  [sp, #96]
    ldrd            r6,  r7,  [sp, #104]
    ldr             lr,  [sp, #112]
    sub             r10, r6,  r7            // dst_stride - width
    and             r10, r10, #~15

lowres_yloop:
    mov             ip,  r7                 // width
    mov             r6,  r0                 // src0
    add             r8,  r0,  r5            // src1 = src0 + src_stride
    add             r9,  r0,  r5,  lsl #1   // src2 = src1 + src_stride

    vld2.8          {d8, d10}, [r6,:128]!
    vld2.8          {d12,d14}, [r8,:128]!
    vld2.8          {d16,d18}, [r9,:128]!

lowres_xloop:
    subs            ip,  ip,  #16

    vld2.8          {d9, d11}, [r6,:128]!
    vld2.8          {d13,d15}, [r8,:128]!
    vrhadd.u8       q0,  q4,  q6
    vld2.8          {d17,d19}, [r9,:128]!
    vrhadd.u8       q5,  q5,  q7
    vld2.8          {d20,d22}, [r6,:128]!
    vrhadd.u8       q1,  q6,  q8
    vld2.8          {d24,d26}, [r8,:128]!
    vrhadd.u8       q7,  q7,  q9
    vext.8          q4,  q4,  q10, #1
    vrhadd.u8       q0,  q0,  q5
    vext.8          q6,  q6,  q12, #1
    vrhadd.u8       q1,  q1,  q7
    vld2.8          {d28,d30}, [r9,:128]!
    vrhadd.u8       q4,  q4,  q6
    vext.8          q8,  q8,  q14, #1
    vrhadd.u8       q6,  q6,  q8
    vst1.64         {d0-d1},   [r1,:128]!
    vrhadd.u8       q2,  q4,  q5
    vst1.64         {d2-d3},   [r3,:128]!
    vrhadd.u8       q3,  q6,  q7
    vst1.64         {d4-d5},   [r2,:128]!
    vst1.64         {d6-d7},   [r4,:128]!

    ble             lowres_xloop_end
    subs            ip,  ip,  #16

    vld2.8          {d21,d23}, [r6,:128]!
    vld2.8          {d25,d27}, [r8,:128]!
    vrhadd.u8       q0,  q10, q12
    vld2.8          {d29,d31}, [r9,:128]!
    vrhadd.u8       q11, q11, q13
    vld2.8          {d8, d10}, [r6,:128]!
    vrhadd.u8       q1,  q12, q14
    vld2.8          {d12,d14}, [r8,:128]!
    vrhadd.u8       q13, q13, q15
    vext.8          q10, q10, q4,  #1
    vrhadd.u8       q0,  q0,  q11
    vext.8          q12, q12, q6,  #1
    vrhadd.u8       q1,  q1,  q13
    vld2.8          {d16,d18}, [r9,:128]!
    vrhadd.u8       q10, q10, q12
    vext.8          q14, q14, q8,  #1
    vrhadd.u8       q12, q12, q14
    vst1.64         {d0-d1},   [r1,:128]!
    vrhadd.u8       q2,  q10, q11
    vst1.64         {d2-d3},   [r3,:128]!
    vrhadd.u8       q3,  q12, q13
    vst1.64         {d4-d5},   [r2,:128]!
    vst1.64         {d6-d7},   [r4,:128]!

    bgt             lowres_xloop

lowres_xloop_end:
    subs            lr,  lr,  #1
    add             r0,  r0,  r5,  lsl #1
    add             r1,  r1,  r10
    add             r2,  r2,  r10
    add             r3,  r3,  r10
    add             r4,  r4,  r10
    bgt             lowres_yloop

    vpop            {d8-d15}
    pop             {r4-r10,pc}
.endfunc
