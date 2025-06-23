.globl main
main:

#--------------------------------------------------
# Initializing Registers
#--------------------------------------------------
  li      t0, 0x1234
  li      t1, 0x00FF
  li      t2, 0xAAAA
  li      t3, 0x5555
  li      t4, 0x3F800000
  li      t5, 0x40000000
  li      a4, 0x00000010    
  li      a5, 0x00000004    
  li      a6, 0xFFFFFFFF     
  li      a7, 0x0000FFFF     
  fmv.w.x f0, t4
  fmv.w.x f1, t5

#--------------------------------------------------
# Integer ALU
#--------------------------------------------------
  add   s0, a4, a5              # s0 = 0x14
  sub   s1, a4, a5              # s1 = 0x0C
  sll   s2, a4, a5              # s2 = 0x10 << 4 = 0x100
  srl   s3, a4, a5              # s3 = 0x10 >> 4 = 0x1
  sra   s4, a6, a5              # s4 = signed shift right = 0xFFFFFFFF
  and   s5, a6, a7              # s5 = 0xFFFF
  or    s6, a4, a7              # s6 = 0x10 | 0xFFFF = 0xFFFF
  xor   s7, a4, a7              # s7 = 0x10 ^ 0xFFFF = 0xFFEF
  slt   s8, a5, a4              # s8 = 1 (4 < 16 signed)
  sltu  s9, a5, a4              # s9 = 1 (4 < 16 unsigned)

#--------------------------------------------------
# Multiply
#--------------------------------------------------
  mul     s2, t0, t1            # s2 = low64(t0*t1)
  mulh    s3, t0, t1            # s3 = high64 signed
  mulhsu  s4, t0, t1            # s4 = high64 mixed
  mulhu   s5, t0, t1            # s5 = high64 unsigned
  div     s6, t2, t1            # s6 = t2 / t1 (signed)
  divu    s7, t2, t1            # s7 = t2 / t1 (unsigned)
  rem     t0, t2, t1            # t0 = t2 % t1 (signed)
  remu    t1, t2, t1            # t1 = t2 % t1 (unsigned)

#--------------------------------------------------
# Floating-point single-precision
#--------------------------------------------------
  fadd.s  f4, f0, f1            # 1.0 + 2.0 = 3.0
  fsub.s  f5, f1, f0            # 2.0 - 1.0 = 1.0
  fmul.s  f6, f0, f1            # 1.0 * 2.0 = 2.0
  fdiv.s  f7, f0, f1            # 1.0 / 2.0 = 0.5
  fsqrt.s f8, f1                # sqrt(2.0)
  feq.s   t0, f0, f1            # t0 = (1.0 == 2.0)
  flt.s   t1, f0, f1            # t1 = (1.0 < 2.0)
  fle.s   t2, f0, f1            # t2 = (1.0 <= 2.0)

#--------------------------------------------------
# Floating-point double-precision
#--------------------------------------------------
  fadd.d  f9,  f2, f3           # 1.0 + 2.0
  fsub.d  f10, f3, f2           # 2.0 - 1.0
  fmul.d  f11, f2, f3           # 1.0 * 2.0
  fdiv.d  f12, f2, f3           # 1.0 / 2.0
  fsqrt.d f13, f3               # sqrt(2.0)
  feq.d   t3, f2, f3            # t3 = (1.0 == 2.0)
  flt.d   t4, f2, f3            # t4 = (1.0 < 2.0)
  fle.d   t5, f2, f3            # t5 = (1.0 <= 2.0)

#--------------------------------------------------
# Compressed Instructions
#--------------------------------------------------
  addi    s1, s1, 1             # uncompressed
  c.addi  s1, 1                 # compressed equivalent
  c.li    s2, 0x7               # load immediate
  c.lwsp  s3, 0(sp)             # load word from stack pointer
  c.swsp  s3, 4(sp)             # store word to stack
  li      t4, 0x3F800000
  li      t5, 0x40000000 
  fmv.w.x f0, t4
  fmv.w.x f1, t5

#--------------------------------------------------
# Atomic operations
#--------------------------------------------------
  la      a0, atomic_var        # a0 = &atomic_var
  lr.d    a1, (a0)              # a1 = *a0 (load-reserved)
  addi    a2, a1, 5             # a2 = a1 + 5
  sc.d    a3, a2, (a0)          # store-conditional
  amoadd.d a4, a2, (a0)         # atomic add
  amoxor.d a5, a2, (a0)         # atomic xor
  amoor.d  a6, a2, (a0)         # atomic or
  amoand.d a7, a2, (a0)         # atomic and
  amomax.d s1, a2, (a0)         # atomic max

#--------------------------------------------------
# Finish the test
#--------------------------------------------------
  li a0, 0x0
  jal exit

#--------------------------------------------------
# Data section for atomic variable
#--------------------------------------------------
.section .data
.align 8
atomic_var:
  .dword 42
