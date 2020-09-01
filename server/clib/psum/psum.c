#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <stdlib.h>
#include <gdsl/gdsl_types.h>
#include <gdsl/gdsl_hash.h>

#include "skynet_malloc.h"
#include "psum.h"

struct psum_space {
	double power;
	double eppower;
	double value[PLAYER_ATTR_CNT][PMO_CNT];
};

static void
psum_debug_print(const char* s) {
    FILE *f = fopen("psum_debug.log", "a");
    if (f == NULL)
        return;
    fprintf(f, "debug: %s\n", s);
    fflush(f);
    fclose(f);
}

static void
psum_init(struct psum_space *space){
	space->power = -1;
	space->eppower = 0;
	memset(space->value,0,sizeof(space->value));
	int i=0;
	for(;i<PLAYER_ATTR_CNT;i++)
	{
		int j =PMO_RESULT_BEGIN;
		for(;j<=PMO_RESULT_END;j++)
			space->value[i][j] = -1;
	}
}

struct psum_space *
psum_create() {
	struct psum_space *space = skynet_malloc(sizeof(*space));
	psum_init(space);
	return space;
}

void
psum_release(struct psum_space *space) {
	skynet_free(space);
}

void
psum_update(struct psum_space * space , const uint8_t attr ,uint8_t module, double value,bool add){
	if (add)
		space->value[attr][module]=space->value[attr][module]+value;
	else
		space->value[attr][module]=value;

	space->power = -1;
	int i=PMO_RESULT_BEGIN;
	for(;i<=PMO_RESULT_END;i++)
		space->value[attr][i] = -1;
}

void psum_seteppower(struct psum_space * space , double value){
	space->eppower = value;
	space->power = -1;
}

double psum_geteppower(struct psum_space * space){
	return space->eppower;
}

void psum_setpower(struct psum_space * space, double value){
	space->power = value;
}

double psum_getpower(struct psum_space * space){
	return space->power;
}

double psum_getbaseratio(struct psum_space * space , const uint8_t attr){
	if (space->value[attr][PMO_BASE_RATIO] != -1){
		return space->value[attr][PMO_BASE_RATIO];
	}
	double result = 0;
	result = result + space->value[attr][PMO_BR_SKILL];
	result = result + space->value[attr][PMO_BR_EQUIP];
	result = result + space->value[attr][PMO_BR_STONE];
	result = result + space->value[attr][PMO_BR_ORG];
	space->value[attr][PMO_BASE_RATIO] = result;
	return result;
}

double psum_getattradd(struct psum_space * space , const uint8_t attr){
	if (space->value[attr][PMO_ATTR_ADD] != -1){
		return space->value[attr][PMO_ATTR_ADD];
	}
	double result = 0;
	result = result + space->value[attr][PMO_ADD_SKILL];
	result = result + space->value[attr][PMO_ADD_EQUIP];
	result = result + space->value[attr][PMO_ADD_STONE];
	space->value[attr][PMO_ATTR_ADD] = result;
	return result;
}

double psum_getattr(struct psum_space * space , const uint8_t attr){
	if (space->value[attr][PMO_ATTR] != -1){
		return space->value[attr][PMO_ATTR];
	}
	double result = floor(psum_find(space,attr,PMO_BASE));
	result = result * (psum_getbaseratio(space,attr)+10000) / 10000;
	result = floor(result + floor(psum_getattradd(space,attr)));
	space->value[attr][PMO_ATTR]=result;
	return result;
}

double psum_find(struct psum_space * space , const uint8_t attr, uint8_t module){
	return space->value[attr][module];
}

void psum_reset(struct psum_space * space, uint8_t module,bool cache) {
	int i=0;
	for(;i<PLAYER_ATTR_CNT;i++)
		if (cache)
			space->value[i][module] = -1;
		else
			space->value[i][module] = 0;
}

void psum_clear(struct psum_space * space , uint8_t module) {
	psum_reset(space,module,false);
	switch(module){
		case PMO_BASE:
			psum_reset(space,PMO_ATTR,true);
			break;
		case PMO_BR_SKILL:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_BASE_RATIO,true);
			break;
		case PMO_BR_EQUIP:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_BASE_RATIO,true);
			break;
		case PMO_BR_STONE:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_BASE_RATIO,true);
			break;
		case PMO_ADD_SKILL:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_ATTR_ADD,true);
			break;
		case PMO_ADD_EQUIP:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_ATTR_ADD,true);
			break;
		case PMO_ADD_STONE:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_ATTR_ADD,true);
			break;
		case PMO_BR_ORG:
			psum_reset(space,PMO_ATTR,true);
			psum_reset(space,PMO_BASE_RATIO,true);
			break;
	}
}

void psum_print(struct psum_space * space , uint8_t module){
	int i=0;
	char tmp[100];
	char key[50];
	for(;i<PLAYER_ATTR_CNT;i++){
		switch(i){
			case 0:
				sprintf(key,"maxhp");
				break;
			case 1:
				sprintf(key,"attack");
				break;
			case 2:
				sprintf(key,"defense");
				break;
			case 3:
				sprintf(key,"speed");
				break;
			case 4:
				sprintf(key,"critical_ratio");
				break;
			case 5:
				sprintf(key,"res_critical_ratio");
				break;
			case 6:
				sprintf(key,"critical_damage");
				break;
			case 7:
				sprintf(key,"abnormal_attr_ratio");
				break;
			case 8:
				sprintf(key,"res_abnormal_ratio");
				break;
			case 9:
				sprintf(key,"cure_critical_ratio");
				break;
		}

		sprintf(tmp,"i=%d key = %s value = %lf",i,key,space->value[i][module]);
		psum_debug_print(tmp);
	}

}

