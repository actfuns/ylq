#include "xor.h"

static uint64_t ORX_KEY_MAP[8] ={};


void
xor_init(uint64_t k){
    int i;
    for(i=0;i<8;i++){
        ORX_KEY_MAP[i] = (k>>(i*8))&0xff;
    }
};

void
xor_code(unsigned char *buff,uint32_t size){
    int i;
    int mark = size%10+1;
    int sp_mark = size%2 ? size%20 : size/7;
    for(i=0;i<size;i++){
        if (i%mark == 0)
            continue;
        if(i == sp_mark)
            buff[i] ^= 0xa3;
        else
            buff[i] ^= ORX_KEY_MAP[i%8];
    };

};

