#include <stdint.h>
#include <stdio.h>

int main() {

	const int n_iter = 10, fc_x = 4, fc_y = 4, N = 10;
	float t_amb = 25.0, fc_temp = 60.5, sum, x[N*N], x_tmp[N*N];

	for (int i = 0; i < N*N; ++i) {
		x[i] = t_amb;
	}

	x[fc_x*N+fc_y] = fc_temp;

	for (int k = 0; k < n_iter; ++k) {

		for (int i = 0; i < N; ++i) {

			for (int j = 0; j < N; ++j) {

				if ((i*N+j) != (fc_x*N+fc_y)) {

					sum = 0;

					if (i + 1 < N) {
						sum = sum + x[(i+1)*N + j];
					} else {
						sum = sum + t_amb;
					}
						
					if (i - 1 >= 0) {
						sum = sum + x[(i-1)*N + j];
					} else {
						sum = sum + t_amb;
					}
						
					if (j + 1 < N) {
						sum = sum + x[i*N + j+1];
					} else {
						sum = sum + t_amb;
					}

					if (j - 1 >= 0) {
						sum = sum + x[i*N + j-1];
					} else {
						sum = sum + t_amb;
					}

					x_tmp[i*N + j] = sum / 4;
				}
			}
		}

		for (int i = 0; i < N*N; ++i) {
			if(i != (fc_x*N+fc_y)) {
				x[i] = x_tmp[i];
			}
		}
	}
	
	return 0;
}
