#ifndef __FIR_H__
#define __FIR_H__

#define N 11
#define fir_test_len 64
#include <stdint.h>

// User fir
#define reg_fir_control (*(volatile uint32_t*)0x30000000)
#define reg_fir_datalen (*(volatile uint32_t*)0x30000010)
#define reg_fir_coeff ((volatile uint32_t*)0x30000040)
#define reg_fir_coeff_1 ((volatile uint32_t*)0x30000044)
#define reg_fir_coeff_2 ((volatile uint32_t*)0x30000048)
#define reg_fir_coeff_3 ((volatile uint32_t*)0x3000004C)
#define reg_fir_coeff_4 ((volatile uint32_t*)0x30000050)
#define reg_fir_coeff_5 ((volatile uint32_t*)0x30000054)
#define reg_fir_coeff_6 ((volatile uint32_t*)0x30000058)
#define reg_fir_coeff_7 ((volatile uint32_t*)0x3000005C)
#define reg_fir_coeff_8 ((volatile uint32_t*)0x30000060)
#define reg_fir_coeff_9 ((volatile uint32_t*)0x30000064)
#define reg_fir_coeff_10 ((volatile uint32_t*)0x30000068)
#define reg_fir_x (*(volatile uint32_t*)0x30000080)
#define reg_fir_y (*(volatile uint32_t*)0x30000084)

int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
int outputsignal[fir_test_len*3];

#endif
