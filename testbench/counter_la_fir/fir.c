#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
// initial your fir
	int i;
	uint32_t Mask, Status;
	
// send data length
	reg_fir_datalen = fir_test_len;		

// send taps
	for(i=0; i<N; i++){
		*(reg_fir_coeff+i) = taps[i];	
	}

// check ap_idle = 1 
	// fir_control[2] = ap_idle -> Mask 
	Mask = 0;
	Mask |= (1 << 2);  

	Status = reg_fir_control & Mask;
	while(Status != 4){
		Status = reg_fir_control & Mask;
	}
	
// send ap_start
	// set fir_control[0] = 1 -> ap_start = 1
	reg_fir_control = 1;
	
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	//write down your fir
	int i;
	uint32_t Mask, Status;
	
	for(i=0; i<fir_test_len; i=i+2){
		// check X[n] = 1 is ready to accept input.
		/*
		Status = reg_fir_control & Mask;
		while(Status != 16){
			Status = reg_fir_control & Mask;
		}
		*/
		// send X[n]
		reg_fir_x = i+1;
		reg_fir_x = i+2;
		
		// check when Y[n] is ready
		/*
		Status = reg_fir_control & Mask;
		while(Status != 32){
			Status = reg_fir_control & Mask;
		}
		*/
		// receive Y[n]
		outputsignal[i] = reg_fir_y;
		outputsignal[i+1] = reg_fir_y;
	}
	
	// Read ap_done to set ap_idle 
	Status = reg_fir_control;
	
	return outputsignal;
}