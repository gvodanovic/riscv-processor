#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define ARRAY_SIZE 8

// Simple pseudo-random generator (linear congruential)
uint32_t rand32(uint32_t seed) {
    return seed * 1664525u + 1013904223u;
}

// Compute Fibonacci
uint32_t fibonacci(uint32_t n) {
    uint32_t a = 0, b = 1, t;
    for (uint32_t i = 0; i < n; ++i) {
        t = a + b;
        a = b;
        b = t;
    }
    return a;
}

// Reverse byte order
uint32_t reverse_bytes(uint32_t x) {
    return ((x >> 24) & 0x000000FF) |
           ((x >> 8)  & 0x0000FF00) |
           ((x << 8)  & 0x00FF0000) |
           ((x << 24) & 0xFF000000);
}

// Simple float-based test
float float_sum(float* arr, int len) {
    float sum = 0.0f;
    for (int i = 0; i < len; ++i) {
        sum += arr[i];
    }
    return sum;
}

// Double precision test
double double_product(double* arr, int len) {
    double prod = 1.0;
    for (int i = 0; i < len; ++i) {
        prod *= arr[i];
    }
    return prod;
}

int main() {
    // Integer section
    uint32_t arr[ARRAY_SIZE];
    uint32_t seed = 1234;

    printf("Random values:\n");
    for (int i = 0; i < ARRAY_SIZE; ++i) {
        seed = rand32(seed);
        arr[i] = seed;
        printf("arr[%d] = %u\n", i, arr[i]);
    }

    uint32_t fib = fibonacci(12);
    uint32_t checksum = 0;
    for (int i = 0; i < ARRAY_SIZE; ++i) {
        checksum ^= arr[i];
    }
    uint32_t rev = reverse_bytes(checksum);

    printf("Fibonacci(12) = %u\n", fib);
    printf("Checksum = 0x%08X, Reversed = 0x%08X\n", checksum, rev);

    // Floating-point section
    float fvalues[ARRAY_SIZE] = {1.5f, 2.0f, -0.5f, 3.25f, 4.0f, 0.0f, -1.0f, 2.75f};
    double dvalues[ARRAY_SIZE] = {1.1, 1.5, 2.0, 0.5, 1.25, 2.25, 1.0, 1.2};

    float fsum = float_sum(fvalues, ARRAY_SIZE);
    double dprod = double_product(dvalues, ARRAY_SIZE);

    printf("Float sum = %.2f\n", fsum);
    printf("Double product = %.5f\n", dprod);

    // String manipulation section
    char msg1[] = "cva6";
    char msg2[5];
    memcpy(msg2, msg1, 5);
    int string_ok = strcmp(msg1, msg2) == 0;
    printf("String comparison: %s\n", string_ok ? "OK" : "FAIL");

    return 0;
}
