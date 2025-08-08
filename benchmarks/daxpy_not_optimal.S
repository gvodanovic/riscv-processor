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
    # Cargar valores iniciales
    la t0, N                     # Dirección de N
    ld t1, 0(t0)                 # t1 = N

    la t2, Alpha                 # Dirección de Alpha
    ld t3, 0(t2)                 # t3 = Alpha (entero)
    fcvt.d.l f10, t3             # f10 = (double) Alpha

    la s2, X                     # Base de X
    la s3, Y                     # Base de Y
    la s4, Z                     # Base de Z

    mv s5, s2                    # Offset X -> s5
    mv s6, s3                    # Offset Y -> s6
    mv s7, s4                    # Offset Z -> s7

    li t4, 0                     # i = 0 (contador)
    
loop:
    fld f5, 0(s5)                # f5 = X[i]
    fld f6, 0(s6)                # f6 = Y[i]
    fmul.d f7, f10, f5           # f7 = alpha * X[i]
    fadd.d f8, f7, f6            # f8 = f7 + Y[i]
    fsd f8, 0(s7)                # Z[i] = f8

    addi s5, s5, 8               # avanzar en X
    addi s6, s6, 8               # avanzar en Y
    addi s7, s7, 8               # avanzar en Z

    addi t4, t4, 1               # i++
    blt  t4, t1, loop            # while i < N

end:
    li a0, 0x0
    jal exit