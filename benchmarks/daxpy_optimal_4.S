.data
    N:      .dword 4096          # Tamaño de los vectores
    Alpha:  .dword 2             # Escalar a multiplicar

.bss
    .align 3
    X: .zero 32768               # Vector X (4096)*8 bytes
    Y: .zero 32768               # Vector Y (4096)*8 bytes
    Z: .zero 32768               # Vector Z (4096)*8 bytes

.text
.globl main
main:
    la t0, N
    ld t1, 0(t0)         
    la t2, Alpha
    ld t3, 0(t2)            
    fcvt.d.l f10, t3        

    la s2, X
    la s3, Y
    la s4, Z

    mv s5, s2            
    mv s6, s3               
    mv s7, s4               

    li t4, 0
    srai t5, t1, 2
              
loop:
    beq t4, t5, end

    fld f5, 0(s5)
    fld f6, 0(s6)
    fmul.d f7, f10, f5
    fadd.d f8, f7, f6
    fsd f8, 0(s7)

    fld f9, 8(s5)
    fld f11, 8(s6)
    fmul.d f12, f10, f9
    fadd.d f13, f12, f11
    fsd f13, 8(s7)

    fld f14, 16(s5)
    fld f15, 16(s6)
    fmul.d f16, f10, f14
    fadd.d f17, f16, f15
    fsd f17, 16(s7)

    fld f18, 24(s5)
    fld f19, 24(s6)
    fmul.d f20, f10, f18
    fadd.d f21, f20, f19
    fsd f21, 24(s7)

    addi s5, s5, 32
    addi s6, s6, 32
    addi s7, s7, 32
    addi t4, t4, 1
    j loop

end:
    li a0, 0x0
    jal exit