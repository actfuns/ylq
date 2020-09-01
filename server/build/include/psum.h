#ifndef _SUM_H
#define _SUM_H

#include <stdint.h>
#include <stddef.h>
#include <math.h>

// lua层同步定义
#define PLAYER_ATTR_CNT 10
#define PMO_CNT 11

#define PMO_RESULT_BEGIN 7
#define PMO_RESULT_END 9

typedef enum
{
    PMO_BASE = 0,

    PMO_BR_SKILL = 1,
    PMO_BR_EQUIP = 2,
    PMO_BR_STONE = 3,

    PMO_ADD_SKILL = 4,
    PMO_ADD_EQUIP = 5,
    PMO_ADD_STONE = 6,

    PMO_ATTR = 7,
    PMO_BASE_RATIO = 8,
    PMO_ATTR_ADD = 9,

    PMO_BR_ORG = 10,
} psum_modules;

struct psum_space;

struct psum_space * psum_create();
void psum_release(struct psum_space *);

void psum_update(struct psum_space * space , const uint8_t attr ,uint8_t module, double value,bool add);
void psum_seteppower(struct psum_space * space , double value);
void psum_setpower(struct psum_space * space , double value);

double psum_getbaseratio(struct psum_space * space , const uint8_t attr);
double psum_getattradd(struct psum_space * space , const uint8_t attr);
double psum_getattr(struct psum_space * space , const uint8_t attr);
double psum_geteppower(struct psum_space * space );
double psum_getpower(struct psum_space * space );

double psum_find(struct psum_space * space ,  const uint8_t attr, uint8_t module);

void psum_clear(struct psum_space * space , uint8_t module);
void psum_result_clear(struct psum_space * space , uint8_t module);

void psum_print(struct psum_space * space , uint8_t module);
#endif
