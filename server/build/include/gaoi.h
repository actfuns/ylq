#ifndef _GAOI_H
#define _GAOI_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef void* (*aoi_Alloc)(void *ud, void * ptr, size_t sz);
typedef void (*aoi_Callback)(void *ud, uint32_t* le, uint32_t le_n, uint32_t* ll, uint32_t ll_n);
typedef void (*aoi_ReviceTeamInfo)(void *ud, uint32_t* m, uint8_t *l);

struct aoi_space;

struct aoi_space* AoiCreateSpace(aoi_Alloc my_alloc, void* ud, uint16_t iMaxX, uint16_t iMaxY, uint8_t iGridX, uint8_t iGridY);
void AoiRelease(struct aoi_space* oAoi);

void AoiCreateObject(struct aoi_space* oAoi, void* ud, aoi_Callback my_callback, uint32_t iEid, uint8_t iType, uint8_t iAcType, uint8_t iWeight, uint16_t iLimit, float fX, float fY);
void AoiRemoveObject(struct aoi_space* oAoi, void* ud, aoi_Callback my_callback, uint32_t iEid);
void AoiUpdateObjectPos(struct aoi_space* oAoi, void* ud, aoi_Callback my_callback, uint32_t iEid, float fX, float fY, bool bForce,bool bBack);
void AoiUpdateObjectWeight(struct aoi_space* oAoi, void* ud, aoi_Callback my_callback, uint32_t iEid, uint8_t iWeight);

void AoiGetView(struct aoi_space* oAoi, uint32_t iEid, uint8_t iType, uint32_t* lo, uint32_t lo_max, uint32_t* lo_size);

void AoiCreateTeam(struct aoi_space* oAoi, void* ud, aoi_Callback my_callback, aoi_ReviceTeamInfo my_recive, uint32_t iEid);

void AoiRemoveTeam(struct aoi_space* oAoi, uint32_t iEid);

void AoiUpdateTeam(struct aoi_space* oAoi, void* ud, aoi_Callback my_callback, aoi_ReviceTeamInfo my_recive, uint32_t iEid);

#endif
