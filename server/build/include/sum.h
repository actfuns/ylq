#ifndef _SUM_H
#define _SUM_H

#include <stdint.h>
#include <stddef.h>
#include <math.h>

// lua层同步定义
#define PARTNER_ATTR_CNT 11
#define MO_CNT 16

#define MO_RESULT_BEGIN 13
#define MO_RESULT_END 15

typedef enum
{
    MO_BASE = 0,

    MO_BR_SKILL = 1,
    MO_BR_EQUIP = 2,
    MO_BR_EQUIP_SET = 3,
    MO_BR_AWAKE = 4,
    MO_BR_HOUSE = 5,
    MO_BR_SOUL =  6,

    MO_ADD_SKILL = 7,
    MO_ADD_EQUIP = 8,
    MO_ADD_EQUIP_SET = 9,
    MO_ADD_AWAKE = 10,
    MO_ADD_HOUSE = 11,
    MO_ADD_SOUL = 12,

    MO_ATTR = 13,
    MO_BASE_RATIO = 14,
    MO_ATTR_ADD = 15,
} sum_modules;

struct sum_space;

struct sum_space * sum_create();
void sum_release(struct sum_space *);

void sum_update(struct sum_space * space , const uint8_t attr ,uint8_t module, double value,bool add);
void sum_setsklv(struct sum_space * space , double value);
void sum_setpower(struct sum_space * space , double value);

double sum_getbaseratio(struct sum_space * space , const uint8_t attr);
double sum_getattradd(struct sum_space * space , const uint8_t attr);
double sum_getattr(struct sum_space * space , const uint8_t attr);
double sum_getsklv(struct sum_space * space );
double sum_getpower(struct sum_space * space );

double sum_find(struct sum_space * space ,  const uint8_t attr, uint8_t module);

void sum_clear(struct sum_space * space , uint8_t module);
void sum_result_clear(struct sum_space * space , uint8_t module);

void sum_print(struct sum_space * space , uint8_t module);
#endif
