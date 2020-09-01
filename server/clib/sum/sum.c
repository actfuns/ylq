#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <stdlib.h>
#include <gdsl/gdsl_types.h>
#include <gdsl/gdsl_hash.h>

#include "skynet_malloc.h"
#include "sum.h"

#define SUM_HASH_SIZE 50
#define SUM_LIST_SIZE 2

struct sum_space {
	double power;
	double skilllv;
	double value[PARTNER_ATTR_CNT][MO_CNT];
};

static void
sum_debug_print(const char* s) {
    FILE *f = fopen("sum_debug.log", "a");
    if (f == NULL)
        return;
    fprintf(f, "debug: %s\n", s);
    fflush(f);
    fclose(f);
}

static void
sum_init(struct sum_space *space){
	space->power = -1;
	space->skilllv = 0;
	memset(space->value,0,sizeof(space->value));
	int i=0;
	for(;i<PARTNER_ATTR_CNT;i++)
	{
		int j =MO_RESULT_BEGIN;
		for(;j<=MO_RESULT_END;j++)
			space->value[i][j] = -1;
	}
}

struct sum_space *
sum_create() {
	struct sum_space *space = skynet_malloc(sizeof(*space));
	sum_init(space);
	return space;
}

void
sum_release(struct sum_space *space) {
	skynet_free(space);
}

void
sum_update(struct sum_space * space , const uint8_t attr ,uint8_t module, double value,bool add){
	if (add)
		space->value[attr][module]=space->value[attr][module]+value;
	else
		space->value[attr][module]=value;

	space->power = -1;
	int i=MO_RESULT_BEGIN;
	for(;i<=MO_RESULT_END;i++)
		space->value[attr][i] = -1;
}

void sum_setsklv(struct sum_space * space , double value){
	space->skilllv = value;
	space->power = -1;
}

double sum_getsklv(struct sum_space * space){
	return space->skilllv;
}

void sum_setpower(struct sum_space * space, double value){
	space->power = value;
}

double sum_getpower(struct sum_space * space){
	return space->power;
}

double sum_getbaseratio(struct sum_space * space , const uint8_t attr){
	if (space->value[attr][MO_BASE_RATIO] != -1){
		return space->value[attr][MO_BASE_RATIO];
	}
	double result = 0;
	result = result + space->value[attr][MO_BR_SKILL];
	result = result + space->value[attr][MO_BR_EQUIP];
	result = result + space->value[attr][MO_BR_EQUIP_SET];
	result = result + space->value[attr][MO_BR_AWAKE];
	result = result + space->value[attr][MO_BR_HOUSE];
	result = result + space->value[attr][MO_BR_SOUL];
	space->value[attr][MO_BASE_RATIO] = result;
	return result;
}

double sum_getattradd(struct sum_space * space , const uint8_t attr){
	if (space->value[attr][MO_ATTR_ADD] != -1){
		return space->value[attr][MO_ATTR_ADD];
	}
	double result = 0;
	result = result + space->value[attr][MO_ADD_SKILL];
	result = result + space->value[attr][MO_ADD_EQUIP];
	result = result + space->value[attr][MO_ADD_EQUIP_SET];
	result = result + space->value[attr][MO_ADD_AWAKE];
	result = result + space->value[attr][MO_ADD_HOUSE];
	result = result + space->value[attr][MO_ADD_SOUL];
	space->value[attr][MO_ATTR_ADD] = result;
	return result;
}

double sum_getattr(struct sum_space * space , const uint8_t attr){
	if (space->value[attr][MO_ATTR] != -1){
		return space->value[attr][MO_ATTR];
	}
	double result = floor(sum_find(space,attr,MO_BASE));
	result = result * (sum_getbaseratio(space,attr)+10000) / 10000;
	result = floor(result + floor(sum_getattradd(space,attr)));
	space->value[attr][MO_ATTR]=result;
	return result;
}

double sum_find(struct sum_space * space , const uint8_t attr, uint8_t module){
	return space->value[attr][module];
}

void sum_reset(struct sum_space * space, uint8_t module,bool cache) {
	int i=0;
	for(;i<PARTNER_ATTR_CNT;i++)
		if (cache)
			space->value[i][module] = -1;
		else
			space->value[i][module] = 0;
}

void sum_clear(struct sum_space * space , uint8_t module) {
	sum_reset(space,module,false);
	switch(module){
		case MO_BASE:
			sum_reset(space,MO_ATTR,true);
			break;
		case MO_BR_SKILL:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_BASE_RATIO,true);
			break;
		case MO_BR_EQUIP:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_BASE_RATIO,true);
			break;
		case MO_BR_EQUIP_SET:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_BASE_RATIO,true);
			break;
		case MO_BR_AWAKE:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_BASE_RATIO,true);
			break;
		case MO_BR_HOUSE:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_BASE_RATIO,true);
			break;
		case MO_BR_SOUL:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_BASE_RATIO,true);
			break;
		case MO_ADD_SKILL:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_ATTR_ADD,true);
			break;
		case MO_ADD_EQUIP:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_ATTR_ADD,true);
			break;
		case MO_ADD_EQUIP_SET:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_ATTR_ADD,true);
			break;
		case MO_ADD_AWAKE:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_ATTR_ADD,true);
			break;
		case MO_ADD_HOUSE:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_ATTR_ADD,true);
			break;
		case MO_ADD_SOUL:
			sum_reset(space,MO_ATTR,true);
			sum_reset(space,MO_ATTR_ADD,true);
			break;
	}
}

void sum_print(struct sum_space * space , uint8_t module){
	int i=0;
	char tmp[100];
	char key[50];
	for(;i<PARTNER_ATTR_CNT;i++){
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
			case 10:
				sprintf(key,"skill");

		}
		sprintf(tmp,"key = %s value = %lf",key,space->value[i][module]);
		sum_debug_print(tmp);
	}

}

