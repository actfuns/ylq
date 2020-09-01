#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <stdlib.h>
#include <math.h>

#include "gaoi.h"
#include "skynet.h"

#define INVALID_ID (~0)
#define PRE_DEFAULT_ALLOC 16
#define MAX_RESULT_COUNT 10240
#define MAX_TEAM_COUNT 5

static int8_t GAOI_X_ACTION[25] = {0, -1, 0, 1, 0, -1, 1, 1, -1, -2, 0, 2, 0, -2, -1, 1, 2, 2, 1, -1, -2, -2, 2, 2, -2};
static int8_t GAOI_Y_ACTION[25] = {0, 0, -1, 0, 1, -1, -1, 1, 1, 0, -2, 0, 2, -1, -2, -2, -1, 1, 2, 2, 1, -2, -2, 2, 2};

static uint8_t GAOI_PLAYER_TYPE = 1;
static uint8_t GAOI_NPC_TYPE = 2;
static uint8_t GAOI_MONSTER_TYPE = 3;

struct map_slot {
	uint32_t id;
	void* obj;
	int next;
};

struct map {
	int size;
	int lastfree;
	struct map_slot* slot;
};

struct aoi_teaminfo {
	uint32_t m_iEid;
	uint8_t ml;
	uint8_t sl;
	uint32_t m_lMem[MAX_TEAM_COUNT];
	uint32_t m_lShort[MAX_TEAM_COUNT];
};

struct aoi_object {
	uint32_t m_iEid;
	uint8_t m_iType;
	uint8_t m_iAcType;
	uint8_t m_iWeight;
	uint16_t m_iOtherWeight;
	uint16_t m_iLimit;
	int16_t m_iX;
	int16_t m_iY;
	struct map* m_mView;

	struct aoi_object* prev;
	struct aoi_object* next;

	uint32_t m_iTeamEid;
};

struct aoi_grid {
	int16_t m_iX;
	int16_t m_iY;
	struct aoi_object* m_lPlayerEntity;
	struct aoi_object* m_lNpcEntity;
	struct aoi_object* m_lMonsterEntity;

	struct aoi_object* m_Tail;
};

struct aoi_result {
	uint16_t le_n;
	uint16_t ll_n;
	uint32_t le[MAX_RESULT_COUNT];
	uint32_t ll[MAX_RESULT_COUNT];
};

struct team_tmp
{
	uint8_t ml;
	uint8_t sl;
	uint32_t mmem[MAX_TEAM_COUNT];
    	uint32_t mshort[MAX_TEAM_COUNT];
};

struct aoi_space {
	aoi_Alloc alloc;
	void* alloc_ud;

    	uint16_t m_iMaxX;
    	uint16_t m_iMaxY;
    	uint8_t m_iGridX;
    	uint8_t m_iGridY;
    	uint16_t m_iXSize;
    	uint16_t m_iYSize;
    	struct map* m_mAllObject;
    	struct map* m_mAllGrid;
    	struct map* m_mAllTeam;

    	struct aoi_result* result;
    	struct team_tmp* ttmp;
};

struct result_action {
	uint8_t type;
	struct aoi_space* space;
	struct map* old;
	struct map* new;
};

struct weight_action {
	int32_t add_weight;
	struct aoi_space* space;
};

struct view_action {
	uint8_t type;
	uint32_t* lo;
	uint32_t lo_size;
	uint32_t lo_max;
	struct aoi_space* space;
};

static uint32_t GetEid(struct aoi_object* obj);
static inline struct map_slot* mainposition(struct map* m , uint32_t id);
static void map_insert(struct aoi_space* space , struct map* m, uint32_t id , void* obj);
static void* map_query(struct aoi_space* space, struct map* m, uint32_t id);
static int map_foreach_func1(void* ud, uint32_t key, void* obj);
static int map_foreach_func2(void* ud, uint32_t key, void* obj);
static int map_foreach_func3(void* ud, uint32_t key, void* obj);
static int map_foreach_func4(void* ud, uint32_t key, void* obj);
static int map_foreach_func5(void* ud, uint32_t key, void* obj);
static int map_foreach_func6(void* ud, uint32_t key, void* obj);
static void SyncTeamLeaderView(struct aoi_space* space,uint32_t eid);

//result interface

static void InitResult(struct aoi_result* re) {
	re->ll_n = 0;
	re->le_n = 0;
}

static void InitTtmp(struct team_tmp* ttmp) {
	ttmp->ml = 0;
	ttmp->sl = 0;
	memset(ttmp->mmem,0,sizeof(ttmp->mmem));
	memset(ttmp->mshort,0,sizeof(ttmp->mshort));
}

static void AppendLl(struct aoi_result* re, uint32_t i) {
	if (re->ll_n<MAX_RESULT_COUNT) {
		re->ll[re->ll_n] = i;
		re->ll_n++;
	}
}

static void AppendLe(struct aoi_result* re, uint32_t i) {
	if (re->le_n<MAX_RESULT_COUNT) {
		re->le[re->le_n] = i;
		re->le_n++;
	}
}

//object interface

static void SuppleOtherWeight(struct aoi_object* obj, int16_t i) {
	obj->m_iOtherWeight = obj->m_iOtherWeight + i;
}

static struct map* GetView(struct aoi_object* obj) {
	return obj->m_mView;
}

static uint32_t GetOtherWeight(struct aoi_object* obj) {
	return obj->m_iOtherWeight;
}

static bool IsPlayer(struct aoi_object* obj) {
	return (obj->m_iType == GAOI_PLAYER_TYPE);
}

static bool IsNPC(struct aoi_object* obj) {
	return (obj->m_iType == GAOI_NPC_TYPE);
}

static bool IsMonster(struct aoi_object* obj) {
	return (obj->m_iType == GAOI_MONSTER_TYPE);
}

static bool InTeam(struct aoi_space* space,struct aoi_object* obj) {
	if (obj->m_iTeamEid != 0){
		struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
		if (team){
			uint16_t i;
			for ( i = 0 ; i < team->ml ; i++ ){
				if (team->m_lMem[i] == GetEid(obj))
				{
					return true;
				}
			}
		}
	}
	return false;
}

static bool IsTeamLeader(struct aoi_space* space,struct aoi_object* obj){
	if (InTeam(space,obj)){
		struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
		if (team && team->ml > 0 && team->m_lMem[0] == GetEid(obj)){
			return true;
		}
	}
	return false;
}

static uint8_t GetWeight(struct aoi_object* obj) {
	if (IsNPC(obj))
		return 0;
	return obj->m_iWeight;
}

static int32_t GetMaxOtherWeight(struct aoi_object* obj) {
	if (IsPlayer(obj)) {
		int32_t r = obj->m_iLimit - obj->m_iWeight;
		if (r<0)
			return 0;
		return r;
	}
	return -1;
}

static void SetWeight(struct aoi_object* obj, uint8_t weight) {
	obj->m_iWeight = weight;
}

static uint32_t GetEid(struct aoi_object* obj) {
	return obj->m_iEid;
}

static void GetPos(struct aoi_object* obj, int16_t* now_x, int16_t* now_y) {
	*now_x = obj->m_iX;
	*now_y = obj->m_iY;
}

static void SetPos(struct aoi_object* obj, int16_t now_x, int16_t now_y) {
	obj->m_iX = now_x;
	obj->m_iY = now_y;
}

//grid interface

static struct aoi_object* GetNPCMap(struct aoi_grid* grid) {
	return grid->m_lNpcEntity;
}

static struct aoi_object* GetPlayerMap(struct aoi_grid* grid) {
	return grid->m_lPlayerEntity;
}

static struct aoi_object* GetMonsterMap(struct aoi_grid* grid) {
	return grid->m_lMonsterEntity;
}

static void LinkAoiObject(struct aoi_grid* grid, struct aoi_object* obj) {
	struct aoi_object* root;

	if (IsPlayer(obj)) {
		root = grid->m_lPlayerEntity;
	} else if (IsNPC(obj)) {
		root = grid->m_lNpcEntity;
	} else if (IsMonster(obj)) {
		root = grid->m_lMonsterEntity;
	} else {
		assert(false);
	}

	obj->prev = NULL;
	obj->next = NULL;

	if (root) {
		obj->prev = NULL;
		obj->next = root;
		root->prev = obj;
	}else{
		if (IsPlayer(obj)) {
			grid->m_Tail = obj;
		}
	}

	if (IsPlayer(obj)) {
		grid->m_lPlayerEntity = obj;
	} else if (IsNPC(obj)) {
		grid->m_lNpcEntity = obj;
	} else if (IsMonster(obj)) {
		grid->m_lMonsterEntity = obj;
	} else {
		assert(false);
	}
}

static void UnlinkAoiObject(struct aoi_grid* grid, struct aoi_object* obj) {
	struct aoi_object* root;

	if (IsPlayer(obj)) {
		root = grid->m_lPlayerEntity;
	} else if (IsNPC(obj)) {
		root = grid->m_lNpcEntity;
	} else if (IsMonster(obj)) {
		root = grid->m_lMonsterEntity;
	} else {
		assert(false);
	}

	struct aoi_object* pprev = obj->prev;
	struct aoi_object* pnext = obj->next;
	obj->prev = NULL;
	obj->next = NULL;

	if (pprev) {
		pprev->next = pnext;
	}
	if (pnext) {
		pnext->prev = pprev;
	}

	if (IsPlayer(obj) && obj == grid->m_Tail){
		grid->m_Tail = pprev;
	}

	if (root && root == obj) {
		if (IsPlayer(obj)) {
			grid->m_lPlayerEntity = pnext;
		} else if (IsNPC(obj)) {
			grid->m_lNpcEntity = pnext;
		} else if (IsMonster(obj)) {
			grid->m_lMonsterEntity = pnext;
		} else {
			assert(false);
		}
	}
}

static void LoopChangelinkAoiObject(struct aoi_grid* grid) {
	struct aoi_object* obj = grid->m_Tail;
	if (obj){
		UnlinkAoiObject(grid,obj);
		LinkAoiObject(grid,obj);
	}
}

//space interface

static void rehash(struct aoi_space* space, struct map* m) {
	struct map_slot * old_slot = m->slot;
	int old_size = m->size;
	m->size = 2 * old_size;
	m->lastfree = m->size - 1;
	m->slot = space->alloc(space->alloc_ud, NULL, m->size * sizeof(struct map_slot));
	int i;
	for (i=0; i<m->size; i++) {
		struct map_slot * s = &m->slot[i];
		s->id = INVALID_ID;
		s->obj = NULL;
		s->next = -1;
	}
	for (i=0; i<old_size; i++) {
		struct map_slot * s = &old_slot[i];
		if (s->obj) {
			map_insert(space, m, s->id, s->obj);
		}
	}
	space->alloc(space->alloc_ud, old_slot, old_size * sizeof(struct map_slot));
}

static void map_insert(struct aoi_space* space , struct map* m, uint32_t id , void* obj) {
	struct map_slot *s = mainposition(m, id);
	if (s->id == INVALID_ID || s->obj == NULL) {
		s->id = id;
		s->obj = obj;
		return;
	}
	if (mainposition(m, s->id) != s) {
		struct map_slot* last = mainposition(m, s->id);
		while (last->next != s - m->slot) {
			assert(last->next >= 0);
			last = &m->slot[last->next];
		}
		uint32_t temp_id = s->id;
		void* temp_obj = s->obj;
		last->next = s->next;
		s->id = id;
		s->obj = obj;
		s->next = -1;
		if (temp_obj) {
			map_insert(space, m, temp_id, temp_obj);
		}
		return;
	}
	while (m->lastfree >= 0) {
		struct map_slot* temp = &m->slot[m->lastfree--];
		if (temp->id == INVALID_ID) {
			temp->id = id;
			temp->obj = obj;
			temp->next = s->next;
			s->next = (int)(temp - m->slot);
			return;
		}
	}
	rehash(space, m);
	map_insert(space, m, id , obj);
}

static void* map_query(struct aoi_space* space, struct map* m, uint32_t id) {
	struct map_slot* s = mainposition(m, id);
	for (;;) {
		if (s->id == id) {
			return s->obj;
		}
		if (s->next < 0) {
			break;
		}
		s=&m->slot[s->next];
	}
	return NULL;
}

static void map_foreach(struct aoi_space* space, struct map* m , int (*func)(void* ud, uint32_t id, void* obj), void* ud) {
	int i;
	for (i=0;i<m->size;i++) {
		if (m->slot[i].obj) {
			if (func(ud, m->slot[i].id, m->slot[i].obj)) {
				break;
			}
		}
	}
}

static void* map_drop(struct aoi_space* space, struct map* m, uint32_t id) {
	struct map_slot* s = mainposition(m, id);
	for (;;) {
		if (s->id == id) {
			void* obj = s->obj;
			s->obj = NULL;
			return obj;
		}
		if (s->next < 0) {
			return NULL;
		}
		s=&m->slot[s->next];
	}
}

static void map_delete(struct aoi_space* space, struct map* m) {
	space->alloc(space->alloc_ud, m->slot, m->size * sizeof(struct map_slot));
	space->alloc(space->alloc_ud, m , sizeof(*m));
}

static struct map* map_new(struct aoi_space* space, uint32_t mem) {
	int i;
	struct map* m = space->alloc(space->alloc_ud, NULL, sizeof(*m));

	if (!mem) {
		mem = PRE_DEFAULT_ALLOC;
	}

	m->size = mem;
	m->lastfree = mem - 1;
	m->slot = space->alloc(space->alloc_ud, NULL, m->size * sizeof(struct map_slot));
	for (i=0; i<m->size; i++) {
		struct map_slot* s = &m->slot[i];
		s->id = INVALID_ID;
		s->obj = NULL;
		s->next = -1;
	}
	return m;
}

static void LeaveView(struct aoi_space* space, struct aoi_object* o, struct aoi_object* oo) {
	if (map_query(space, o->m_mView, GetEid(oo))) {
		map_drop(space, o->m_mView, GetEid(oo));
		SuppleOtherWeight(o, -GetWeight(oo));
	}
}

static void EnterView(struct aoi_space* space, struct aoi_object* o, struct aoi_object* oo) {
	if (!map_query(space, o->m_mView, GetEid(oo))) {
		map_insert(space, o->m_mView, GetEid(oo), (void*)oo);
		SuppleOtherWeight(o, GetWeight(oo));
	}
}

static int32_t GridKey(struct aoi_space* space, uint32_t i, uint32_t j){
	if (i>=0 && i<space->m_iXSize && j>=0 && j<space->m_iYSize)
		return i + j*space->m_iXSize;
	return -1;
}

static uint32_t GetViewList(struct aoi_space* space, struct aoi_object* obj, uint32_t* lo, uint32_t lo_max) {
	struct view_action via;
	via.space = space;
	via.type = 0;
	via.lo = lo;
	via.lo_max = lo_max;
	via.lo_size = 0;
	map_foreach(space, obj->m_mView, map_foreach_func5, (void*)&via);
	return via.lo_size;
}

static uint32_t GetViewListByType(struct aoi_space* space, struct aoi_object* obj, uint8_t type, uint32_t* lo, uint32_t lo_max) {
	struct view_action via;
	via.space = space;
	via.type = type;
	via.lo = lo;
	via.lo_max = lo_max;
	via.lo_size = 0;
	map_foreach(space, obj->m_mView, map_foreach_func5, (void*)&via);
	return via.lo_size;
}

static struct aoi_grid* NewGrid(struct aoi_space* space, uint32_t id, int16_t x, int16_t y) {
	struct aoi_grid* grid = space->alloc(space->alloc_ud, NULL, sizeof(*grid));
	grid->m_iX = x;
	grid->m_iY = y;
	grid->m_lPlayerEntity = NULL;
	grid->m_lNpcEntity = NULL;
	grid->m_lMonsterEntity = NULL;
	grid->m_Tail = NULL;
	return grid;
}

static int FreeGrid(void* ud, uint32_t key, void* obj) {
	struct aoi_space* space = (struct aoi_space*)ud;
	struct aoi_grid* gobj = (struct aoi_grid*)obj;
	gobj->m_lPlayerEntity = NULL;
	gobj->m_lNpcEntity = NULL;
	gobj->m_lMonsterEntity = NULL;
	gobj->m_Tail = NULL;
	space->alloc(space->alloc_ud, gobj, sizeof(*gobj));
	return 0;
}

static struct aoi_object* NewObject(struct aoi_space* space, uint32_t id, uint8_t type, uint8_t ac_type, uint8_t weight, uint16_t limit) {
	struct aoi_object* object = space->alloc(space->alloc_ud, NULL, sizeof(*object));
	object->m_iEid = id;
	object->m_iType = type;
	object->m_iAcType = ac_type;
	object->m_iWeight = weight;
	object->m_iLimit = limit;
	object->m_iOtherWeight = 0;
	object->m_iX = -1;
	object->m_iY = -1;
	object->prev = NULL;
	object->next = NULL;
	object->m_mView = map_new(space, 0);
	object->m_iTeamEid = 0;
	return object;
}

static int FreeObject(void* ud, uint32_t key, void* obj) {
	struct aoi_space* space = (struct aoi_space*)ud;
	struct aoi_object* pobj = (struct aoi_object*)obj;
	pobj->prev = NULL;
	pobj->next = NULL;
	map_delete(space, pobj->m_mView);
	space->alloc(space->alloc_ud, pobj, sizeof(*pobj));
	return 0;
}

static int FreeTeam(void* ud, uint32_t key, void* obj) {
	struct aoi_space* space = (struct aoi_space*)ud;
	struct aoi_teaminfo* team = (struct aoi_teaminfo*)obj;
	space->alloc(space->alloc_ud, team, sizeof(*team));
	return 0;
}

//outside interface

struct aoi_space* AoiCreateSpace(aoi_Alloc my_alloc, void* ud, uint16_t max_x, uint16_t max_y, uint8_t grid_x, uint8_t grid_y) {
	struct aoi_space* space = my_alloc(ud, NULL, sizeof(*space));
	space->alloc = my_alloc;
	space->alloc_ud = ud;

	space->m_iMaxX = max_x;
	space->m_iMaxY = max_y;
	space->m_iGridX = grid_x;
	space->m_iGridY = grid_y;
	space->m_iXSize = floor(max_x/grid_x) + 1;
	space->m_iYSize = floor(max_y/grid_y) + 1;

	space->m_mAllObject = map_new(space, 0);
	space->m_mAllGrid = map_new(space, 0);
	space->m_mAllTeam = map_new(space, 0);

	uint32_t i, j;
	for (i=0; i<space->m_iXSize; i++) {
		for (j=0; j<space->m_iYSize; j++) {
			int32_t key = GridKey(space, i, j);
			assert(key>=0);
			struct aoi_grid* grid = NewGrid(space, key, i, j);
			map_insert(space, space->m_mAllGrid, key, (void*)grid);
		}
	}

	space->result = my_alloc(ud, NULL, sizeof(struct aoi_result));
	InitResult(space->result);

	space->ttmp = my_alloc(ud,NULL,sizeof(struct team_tmp));
	InitTtmp(space->ttmp);

	return space;
}

void AoiRelease(struct aoi_space* space) {
	map_foreach(space, space->m_mAllGrid, FreeGrid, (void*)space);
	map_delete(space, space->m_mAllGrid);
	space->m_mAllGrid = NULL;

	map_foreach(space, space->m_mAllObject, FreeObject, (void*)space);
	map_delete(space, space->m_mAllObject);
	space->m_mAllObject = NULL;

	map_foreach(space, space->m_mAllTeam, FreeTeam, (void*)space);
	map_delete(space, space->m_mAllTeam);
	space->m_mAllTeam = NULL;

	space->alloc(space->alloc_ud, space->result, sizeof(struct aoi_result));
	space->result = NULL;

	space->alloc(space->alloc_ud, space->ttmp, sizeof(struct team_tmp));
	space->ttmp = NULL;

	space->alloc(space->alloc_ud, space, sizeof(*space));
}

static struct aoi_teaminfo* NewTeam(struct aoi_space* space, uint32_t id, uint32_t* mmem, uint8_t ml, uint32_t* mshort, uint8_t sl) {
	struct aoi_teaminfo* object = space->alloc(space->alloc_ud, NULL, sizeof(*object));
	object->m_iEid = id;
	object->ml = ml;
	object->sl = sl;
	uint8_t i;
	for( i = 0; i < ml ; i++ ){
		object->m_lMem[i] = mmem[i];
	}
	for( i = 0; i < sl ; i++ ){
		object->m_lShort[i] = mshort[i];
	}
	return object;
}

static void SetTeamID(struct aoi_object* obj, uint32_t eid) {
	obj->m_iTeamEid = eid;
}

static void SetTeamInfo(struct aoi_teaminfo* obj, struct team_tmp* tmp) {
	obj->ml = tmp->ml;
	obj->sl = tmp->sl;
	uint8_t i;
	for( i = 0; i < tmp->ml ; i++ ){
		obj->m_lMem[i] = tmp->mmem[i];
	}
	for( i = 0; i < tmp->sl ; i++ ){
		obj->m_lShort[i] = tmp->mshort[i];
	}
}

static void AoiUpdateTeamMemPos(struct aoi_space* space, uint32_t eid) {
	struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, eid);
	if (!team){
		return;
	}

	uint32_t ileader = team->m_lMem[0];
	struct aoi_object* leader = (struct aoi_object*)map_query(space, space->m_mAllObject, ileader);
	if (!leader){
		return;
	}

	int16_t grid_x, grid_y,now_x,now_y;
	GetPos(leader, &grid_x, &grid_y);
	int32_t new_key = GridKey(space, grid_x, grid_y);
	assert(new_key>=0);
	struct aoi_grid* new_grid = (struct aoi_grid*)map_query(space, space->m_mAllGrid, new_key);
	assert(new_grid);

	uint16_t i;
	for( i = 1; i < team->ml ; i ++ ){
		uint32_t id = team->m_lMem[i];
		struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, id);
		if (obj){
			GetPos(obj, &now_x, &now_y);
			if (grid_x != now_x || grid_y != now_y) {
		        		if (now_x >= 0 && now_y >= 0) {
		        			int32_t old_key = GridKey(space, now_x, now_y);
		        			if (old_key >= 0) {
		        				struct aoi_grid* old_grid = (struct aoi_grid*)map_query(space, space->m_mAllGrid, old_key);
		        				if (old_grid) {
		        					UnlinkAoiObject(old_grid, obj);
		        				}
		        			}
		        		}
		        		SetPos(obj, grid_x, grid_y);
		        		LinkAoiObject(new_grid, obj);
			}
		}
	}
}

void AoiCreateTeam(struct aoi_space* space, void* ud, aoi_Callback my_callback, aoi_ReviceTeamInfo my_recive, uint32_t eid){
	struct team_tmp* tmp = space->ttmp;
	InitTtmp(tmp);

	my_recive(ud,tmp->mshort,&tmp->sl);
	my_recive(ud,tmp->mmem,&tmp->ml);

	struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, eid);
	assert(!team);

	team = NewTeam(space, eid, tmp->mmem, tmp->ml, tmp->mshort, tmp->sl);
	map_insert(space, space->m_mAllTeam, eid, (void*)team);

	uint16_t i;
	struct aoi_object* leader = NULL;

	for (i=0;i<team->sl;i++){
	 	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
	 	if (obj){
	 		SetTeamID(obj,eid);
	 	}
	}
	for (i=0;i<team->ml;i++){
		struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[i]);
		if (obj){
			if (i==0){
				leader = obj;
			}
			SetTeamID(obj,eid);
		}
	}

	struct aoi_result* result = space->result;
	InitResult(result);

	int16_t now_x, now_y;

	if (leader){
		GetPos(leader, &now_x, &now_y);
		float x = now_x * space->m_iGridX;
		float y = now_y * space->m_iGridY;
		AoiUpdateObjectPos(space, ud, my_callback, GetEid(leader), x, y, true, false);
	}

	for (i=0;i<team->sl;i++){
	 	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
	 	if (obj){
			GetPos(obj, &now_x, &now_y);
			float x = now_x * space->m_iGridX;
			float y = now_y * space->m_iGridY;
			AoiUpdateObjectPos(space, ud, my_callback, GetEid(obj), x, y, true, false);
	 	}
	}

	my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);

	// struct aoi_result* result = space->result;
	// InitResult(result);
	// if (leader != 0){
	// 	AdjustTeamleaderView(space,leader);
	// 	SyncTeamLeaderView(space,leader);
	// }
	// my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
}

void AoiRemoveTeam(struct aoi_space* space, uint32_t eid){
	struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, eid);
	if (team){
		uint16_t i;
		for (i=0;i<team->sl;i++){
		 	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
		 	if (obj)
		 	{
		 		SetTeamID(obj,0);
		 	}
		}
		for (i=0;i<team->ml;i++){
			struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[i]);
			if (obj){
				SetTeamID(obj,0);
			}
		}
		map_drop(space, space->m_mAllTeam, eid);
        		FreeTeam((void*)space, eid, (void*)team);
	}
}

void AoiUpdateTeam(struct aoi_space* space, void* ud, aoi_Callback my_callback, aoi_ReviceTeamInfo my_recive, uint32_t eid){
	struct team_tmp* tmp = space->ttmp;
	InitTtmp(tmp);

	my_recive(ud,tmp->mshort,&tmp->sl);
	my_recive(ud,tmp->mmem,&tmp->ml);

	struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, eid);
	if (!team){
		return;
	}
	uint16_t i;
	struct map* old_short = map_new(space, 16);
	for (i=0;i<team->sl;i++){
	 	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
	 	if (obj)
	 	{
	 		SetTeamID(obj,0);
	 		map_insert(space, old_short, GetEid(obj), (void*)obj);
	 	}
	}
	for (i=0;i<team->ml;i++){
		struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[i]);
		if (obj){
			SetTeamID(obj,0);
		}
	}

	SetTeamInfo(team,tmp);

	struct aoi_object* leader = NULL;
	for (i=0;i<team->sl;i++){
	 	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
	 	if (obj){
	 		SetTeamID(obj,eid);
	 	}
	}
	for (i=0;i<team->ml;i++){
		struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[i]);
		if (obj){
			if (i==0){
				leader = obj;
			}
			SetTeamID(obj,eid);
		}

	}

	struct aoi_result* result = space->result;
	InitResult(result);

	int16_t now_x, now_y;
	if (leader){
		GetPos(leader, &now_x, &now_y);
		float x = now_x * space->m_iGridX;
		float y = now_y * space->m_iGridY;
		AoiUpdateObjectPos(space, ud, my_callback, GetEid(leader), x, y, true, false);
	}
	for (i=0;i<team->sl;i++){
	 	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
	 	if (obj && !map_query(space, old_short, team->m_lShort[i])){
			GetPos(obj, &now_x, &now_y);
			float x = now_x * space->m_iGridX;
			float y = now_y * space->m_iGridY;
			AoiUpdateObjectPos(space, ud, my_callback, GetEid(obj), x, y, true, false);
	 	}
	}

	my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);

	// AoiUpdateTeamMemPos(space,eid);
	// struct aoi_result* result = space->result;
	// InitResult(result);
	// if (leader != 0){
	// 	AdjustTeamleaderView(space,leader);
	// 	SyncTeamLeaderView(space,leader);
	// }
	// my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
}


void AoiCreateObject(struct aoi_space* space, void* ud, aoi_Callback my_callback, uint32_t eid, uint8_t type, uint8_t ac_type, uint8_t weight, uint16_t limit, float x, float y) {
	assert(weight>=0 && limit>=0 && x>=0 && x<=space->m_iMaxX && y>=0 && y<=space->m_iMaxY);

	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
	assert(!obj);

	obj = NewObject(space, eid, type, ac_type, weight, limit);
	map_insert(space, space->m_mAllObject, eid, (void*)obj);

	AoiUpdateObjectPos(space, ud, my_callback, eid, x, y, true, true);
}

static bool IsNear(struct aoi_object* obj, struct aoi_object* target){
	int16_t now_x, now_y, t_x, t_y;
	GetPos(obj, &now_x, &now_y);
	GetPos(target, &t_x, &t_y);
	int16_t dis = 0;
	if (abs(now_y - t_y) > dis){
		return false;
	}
	if (abs(now_x - t_x) > dis){
		return false;
	}
	return true;
}

static bool AoiKickObjectView(struct aoi_space* space, struct aoi_object* obj, int32_t kick_weight){
	if (!obj){
		return false;
	}
	struct map* now_view = GetView(obj);
	uint32_t weight_cnt = 0;
	uint32_t i;
	struct aoi_result* result = space->result;
	AppendLl(result, 0);
	AppendLl(result, GetEid(obj));
	uint32_t ll = result->ll_n;

	for (i=0;i<now_view->size;i++) {
		if (weight_cnt >= kick_weight) {
			break;
		}
		struct aoi_object* target = (struct aoi_object*)now_view->slot[i].obj;
		if (!target){
			continue;
		}
		if (!IsPlayer(target)){
			continue;
		}
		if (target->m_iTeamEid != 0 && target->m_iTeamEid == obj->m_iTeamEid){
			continue;
		}

		if (!InTeam(space,target)){
			weight_cnt = weight_cnt + GetWeight(target);
			AppendLl(result, GetEid(target));
		}else if(IsTeamLeader(space,target)){
			struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, target->m_iTeamEid);
			if (team){
				weight_cnt = weight_cnt + team->ml;
				uint16_t j = 0;
				for (j=0;j<team->ml;j++){
					AppendLl(result, team->m_lMem[j]);
				}
			}
		}
	}
	if (weight_cnt >= kick_weight){
		uint32_t i = ll;
		while (i < result->ll_n) {
			struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[i]);
			if (oo) {
				LeaveView(space, oo, obj);
				LeaveView(space, obj, oo);
			}
			i++;
		}
		if (IsTeamLeader(space,obj)){
			SyncTeamLeaderView(space,GetEid(obj));
		}
		i = ll;
		while (i < result->ll_n) {
			struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[i]);
			if (oo && IsTeamLeader(space,oo)) {
				SyncTeamLeaderView(space,GetEid(oo));
			}
			i++;
		}
		return true;
	}
	return false;
}

void AoiUpdateObjectPos(struct aoi_space* space, void* ud, aoi_Callback my_callback, uint32_t eid, float x, float y, bool force,bool back) {
	assert(x>=0 && x<=space->m_iMaxX && y>=0 && y<=space->m_iMaxY);
	uint16_t grid_x = floor(x/space->m_iGridX);
	uint16_t grid_y = floor(y/space->m_iGridY);
	int32_t new_key = GridKey(space, grid_x, grid_y);
	assert(new_key>=0);

	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
	struct aoi_grid* new_grid = (struct aoi_grid*)map_query(space, space->m_mAllGrid, new_key);
	assert(obj && new_grid);

	int16_t now_x, now_y;
	GetPos(obj, &now_x, &now_y);

	if (grid_x == now_x && grid_y == now_y) {
		if (!force) {
			struct aoi_result* result = space->result;
			InitResult(result);
			my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
			return;
		}
	} else {
        		if (now_x >= 0 && now_y >= 0) {
        			int32_t old_key = GridKey(space, now_x, now_y);
        			if (old_key >= 0) {
        				struct aoi_grid* old_grid = (struct aoi_grid*)map_query(space, space->m_mAllGrid, old_key);
        				if (old_grid) {
        					UnlinkAoiObject(old_grid, obj);
        				}
        			}
        		}

        		SetPos(obj, grid_x, grid_y);
        		LinkAoiObject(new_grid, obj);
	}

	if (IsTeamLeader(space,obj)){
		AoiUpdateTeamMemPos(space,obj->m_iTeamEid);
	}

	struct map* new_view = map_new(space, 256);
	struct map* new_view2 = map_new(space, 256);
	struct map* old_view = GetView(obj);
	int32_t my_weight,my_left_weight;
	int32_t need_weight;
	uint32_t my_eid=0;

	struct aoi_result* result = space->result;
	if (back){
		InitResult(result);
	}

	uint32_t i;
	if (IsPlayer(obj)) {
		my_weight = GetWeight(obj);
		my_left_weight = GetMaxOtherWeight(obj);
		need_weight = my_left_weight * 2 / 3;
		my_eid = GetEid(obj);
		if ( obj->m_iTeamEid != 0 ){
			struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
			if (team){
				if (InTeam(space,obj)){
					my_weight = team->ml;
				}
				for ( i = 0 ; i < team->ml ; i++ ){
					if (my_left_weight<=0) {
						break;
					}
					struct aoi_object* mem = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[i]);
					if ( mem && GetEid(mem) != my_eid ){
						my_left_weight = my_left_weight - GetWeight(mem);
						map_insert(space, new_view, GetEid(mem), (void*)mem);
					}
				}
				for ( i = 0 ; i < team->sl ; i++ ){
					if (my_left_weight<=0) {
						break;
					}
					struct aoi_object* mem = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lShort[i]);
					if ( mem && GetEid(mem) != my_eid ){
						my_left_weight = my_left_weight - GetWeight(mem);
						map_insert(space, new_view, GetEid(mem), (void*)mem);
					}
				}
			}
		}
		for (i=0;i<old_view->size;i++) {
			if (my_left_weight<=0) {
				break;
			}
			if (old_view->slot[i].obj == NULL){
				continue;
			}
			struct aoi_object* oldobj = (struct aoi_object*)old_view->slot[i].obj;
			if (IsNear(obj,oldobj) && !map_query(space, new_view, GetEid(oldobj)) ){
				if (IsNPC(oldobj)){
					map_insert(space, new_view, GetEid(oldobj), (void*)oldobj);
				}else if (IsMonster(oldobj)){
					int32_t p_weight = GetWeight(oldobj);
					if (my_left_weight >= p_weight) {
						my_left_weight = my_left_weight - p_weight;
						map_insert(space, new_view, GetEid(oldobj), (void*)oldobj);
					}
				}else if (IsPlayer(oldobj)){
					if (my_eid != GetEid(oldobj)) {
						if (oldobj->m_iTeamEid != 0 && oldobj->m_iTeamEid == obj->m_iTeamEid){
							continue;
						}
						int32_t p_weight = GetWeight(oldobj);
						if (InTeam(space,oldobj) && !IsTeamLeader(space,oldobj)){
							continue;
						}
						if (IsTeamLeader(space,oldobj)){
							struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, oldobj->m_iTeamEid);
							if (team){
								uint16_t j;
								p_weight = 0;
								for ( j = 0 ; j < team->ml ; j++){
									if (!map_query(space, new_view, team->m_lMem[j])){
										p_weight = p_weight + 1;
									}
								}
							}
						}
						int32_t p_left_weight = GetMaxOtherWeight(oldobj) - GetOtherWeight(oldobj);
						if (!InTeam(space,obj)){
							if (map_query(space, GetView(oldobj), GetEid(obj))) {
								p_left_weight = p_left_weight + my_weight;
							}
						}else if  (IsTeamLeader(space,obj)){
							struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
							if (team){
								uint16_t j;
								for ( j = 0 ; j < team->ml ; j++){
									if (map_query(space, GetView(oldobj), team->m_lMem[j])){
										p_left_weight = p_left_weight + 1;
									}
								}
							}
						}

						if (p_weight > 0 && my_left_weight >= p_weight) {
							if (p_left_weight >= my_weight){
								if (!InTeam(space,oldobj)){
									my_left_weight = my_left_weight - p_weight;
									if (oldobj && !map_query(space, new_view, GetEid(oldobj))){
										map_insert(space, new_view, GetEid(oldobj), (void*)oldobj);
									}
								}else if (IsTeamLeader(space,oldobj)){
									my_left_weight = my_left_weight - p_weight;
									struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, oldobj->m_iTeamEid);
									if (team){
										uint16_t j;
										for ( j = 0 ; j < team->ml ; j++){
											struct aoi_object* mem = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[j]);
											if (mem && !map_query(space, new_view, GetEid(mem))){
												map_insert(space, new_view, GetEid(mem), (void*)mem);
											}
										}
									}
								}
							}else{
								if (!InTeam(space,oldobj) || IsTeamLeader(space,oldobj)){
									if (!map_query(space, new_view2, GetEid(oldobj))){
										map_insert(space, new_view2, GetEid(oldobj), (void*)oldobj);
									}
								}
							}
						}
					}
				}
			}
		}
		for (i = 0; i < 25; i++) {
			int8_t dx = GAOI_X_ACTION[i];
			int8_t dy = GAOI_Y_ACTION[i];

			int32_t key = GridKey(space, grid_x+dx, grid_y+dy);
			if (key >= 0) {
				struct aoi_grid* o = (struct aoi_grid*)map_query(space, space->m_mAllGrid, key);
				if (o) {
					struct aoi_object* npc = GetNPCMap(o);
					while (npc) {
						if (!map_query(space, new_view, GetEid(npc))){
							map_insert(space, new_view, GetEid(npc), (void*)npc);
						}
						npc = npc -> next;
					}
				}
			}
		}
		for (i = 0; i < 9; i++) {
			if (my_left_weight<=0) {
				break;
			}

			int8_t dx = GAOI_X_ACTION[i];
			int8_t dy = GAOI_Y_ACTION[i];

			int32_t key = GridKey(space, grid_x+dx, grid_y+dy);
			if (key >= 0) {
				struct aoi_grid* o = (struct aoi_grid*)map_query(space, space->m_mAllGrid, key);
				if (o) {
					struct aoi_object* pl = GetMonsterMap(o);
					while (pl) {
						if (my_left_weight<=0){
							break;
						}

						if (my_eid != GetEid(pl) && !map_query(space, new_view, GetEid(pl))) {
							int32_t p_weight = GetWeight(pl);
							if (my_left_weight >= p_weight) {
								my_left_weight = my_left_weight - p_weight;
								map_insert(space, new_view, GetEid(pl), (void*)pl);
							}
						}

						pl = pl -> next;
					}
				}
			}
		}
		for (i = 0; i < 9; i++) {
			if (my_left_weight<=0) {
				break;
			}

			int8_t dx = GAOI_X_ACTION[i];
			int8_t dy = GAOI_Y_ACTION[i];

			int32_t key = GridKey(space, grid_x+dx, grid_y+dy);
			if (key >= 0) {
				struct aoi_grid* o = (struct aoi_grid*)map_query(space, space->m_mAllGrid, key);
				if (o) {
					LoopChangelinkAoiObject(o);
					struct aoi_object* pl = GetPlayerMap(o);
					while (pl) {
						if (my_left_weight<=0){
							break;
						}
						if (pl->m_iTeamEid != 0 && pl->m_iTeamEid == obj->m_iTeamEid){
							pl = pl -> next;
							continue;
						}
						if (InTeam(space,pl) && !IsTeamLeader(space,pl)){
							pl = pl -> next;
							continue;
						}
						if (my_eid != GetEid(pl) && !map_query(space, new_view, GetEid(pl))) {
							int32_t p_weight = GetWeight(pl);
							if (IsTeamLeader(space,pl)){
								struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, pl->m_iTeamEid);
								if (team){
									p_weight = 0;
									uint16_t j;
									for ( j = 0 ; j < team->ml ; j++){
										if (!map_query(space, new_view, team->m_lMem[j])){
											p_weight = p_weight + 1;
										}
									}
								}
							}
							int32_t p_left_weight = GetMaxOtherWeight(pl) - GetOtherWeight(pl);
							if (!InTeam(space,obj)){
								if (map_query(space, GetView(pl), GetEid(obj))) {
									p_left_weight = p_left_weight + my_weight;
								}
							}else if  (IsTeamLeader(space,obj)){
								struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
								if (team){
									uint16_t j;
									for ( j = 0 ; j < team->ml ; j++){
										if (map_query(space, GetView(pl), team->m_lMem[j])){
											p_left_weight = p_left_weight + 1;
										}
									}
								}
							}

							if (p_weight>0 && my_left_weight >= p_weight) {
								if (p_left_weight >= my_weight){
									if (!InTeam(space,pl)){
										my_left_weight = my_left_weight - p_weight;
										if (pl && !map_query(space, new_view, GetEid(pl))){
											map_insert(space, new_view, GetEid(pl), (void*)pl);
										}
									}else if (IsTeamLeader(space,pl)){
										my_left_weight = my_left_weight - p_weight;
										struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, pl->m_iTeamEid);
										if (team){
											uint16_t j;
											for ( j = 0 ; j < team->ml ; j++){
												struct aoi_object* mem = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[j]);
												if (mem && !map_query(space, new_view, GetEid(mem))){
													map_insert(space, new_view, GetEid(mem), (void*)mem);
												}
											}
										}
									}
								}else{
									if (!InTeam(space,pl) || IsTeamLeader(space,pl)){
										if (!map_query(space, new_view2, GetEid(pl))){
											map_insert(space, new_view2, GetEid(pl), (void*)pl);
										}
									}
								}
							}
						}
						pl = pl -> next;
					}
				}
			}
		}
		for (i=0;i<new_view2->size;i++) {
			if (my_left_weight<=need_weight) {
				break;
			}
			if (new_view2->slot[i].obj == NULL){
				continue;
			}
			struct aoi_object* pl = (struct aoi_object*)new_view2->slot[i].obj;
			if (!pl){
				continue;
			}
			if (InTeam(space,pl) && !IsTeamLeader(space,pl) ){
				continue;
			}
			if (AoiKickObjectView(space,pl,my_weight)){
				int32_t p_weight = GetWeight(pl);
				if (IsTeamLeader(space,pl)){
					struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, pl->m_iTeamEid);
					if (team){
						p_weight = team->ml;

					}
				}
				if (!InTeam(space,pl)){
					my_left_weight = my_left_weight - p_weight;
					if (pl && !map_query(space, new_view, GetEid(pl))){
						map_insert(space, new_view, GetEid(pl), (void*)pl);
					}
				}else if (IsTeamLeader(space,pl)){
					my_left_weight = my_left_weight - p_weight;
					struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, pl->m_iTeamEid);
					if (team){
						uint16_t j;
						for ( j = 0 ; j < team->ml ; j++){
							struct aoi_object* mem = (struct aoi_object*)map_query(space, space->m_mAllObject, team->m_lMem[j]);
							if (mem && !map_query(space, new_view, GetEid(mem))){
								map_insert(space, new_view, GetEid(mem), (void*)mem);
							}
						}
					}
				}
			}
		}
	} else if (IsNPC(obj)) {
		my_eid = GetEid(obj);
		for (i = 0; i < 25; i++) {
			int8_t dx = GAOI_X_ACTION[i];
			int8_t dy = GAOI_Y_ACTION[i];

			int32_t key = GridKey(space, grid_x+dx, grid_y+dy);
			if (key >= 0) {
				struct aoi_grid* o = (struct aoi_grid*)map_query(space, space->m_mAllGrid, key);
				if (o) {
					struct aoi_object* pl = GetPlayerMap(o);
					while (pl) {
						map_insert(space, new_view, GetEid(pl), (void*)pl);
						pl = pl -> next;
					}
				}
			}
		}
	} else if (IsMonster(obj)) {
		my_weight = GetWeight(obj);
		my_eid = GetEid(obj);

		for (i = 0; i < 9; i++) {
			int8_t dx = GAOI_X_ACTION[i];
			int8_t dy = GAOI_Y_ACTION[i];

			int32_t key = GridKey(space, grid_x+dx, grid_y+dy);
			if (key >= 0) {
				struct aoi_grid* o = (struct aoi_grid*)map_query(space, space->m_mAllGrid, key);
				if (o) {
					struct aoi_object* pl = GetPlayerMap(o);
					while (pl) {
						if (my_eid != GetEid(pl)) {
							int32_t p_left_weight = GetMaxOtherWeight(pl) - GetOtherWeight(pl);
							if (map_query(space, pl->m_mView, GetEid(obj))) {
								p_left_weight = p_left_weight + my_weight;
							}

							if (p_left_weight >= my_weight) {
								map_insert(space, new_view, GetEid(pl), (void*)pl);
							}

						}

						pl = pl -> next;
					}
				}
			}
		}

	} else {
		assert(false);
	}

	AppendLl(result, 0);
	AppendLl(result, my_eid);
	uint32_t ll = result->ll_n;
	struct result_action rea1;
	rea1.type = 1;
	rea1.space = space;
	rea1.old = old_view;
	rea1.new = new_view;
	map_foreach(space, old_view, map_foreach_func1, (void*)&rea1);

	AppendLe(result, 0);
	AppendLe(result, my_eid);
	uint32_t le = result->le_n;
	struct result_action rea2;
	rea2.type = 0;
	rea2.space = space;
	rea2.old = old_view;
	rea2.new = new_view;
	map_foreach(space, new_view, map_foreach_func1, (void*)&rea2);

	while (ll < result->ll_n) {
		struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[ll]);
		if (oo) {
			LeaveView(space, oo, obj);
			LeaveView(space, obj, oo);
		}
		ll++;
	}

	while (le < result->le_n) {
		struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->le[le]);
		if (oo) {
			EnterView(space, oo, obj);
			EnterView(space, obj, oo);
		}
		le++;
	}

	if (my_eid != 0){
		SyncTeamLeaderView(space,my_eid);
	}

	map_delete(space, new_view);
	map_delete(space, new_view2);

	new_view = NULL;
	new_view2 = NULL;

	if (back){
		my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
	}
}

// static void AdjustTeamleaderView(struct aoi_space* space,uint32_t eid){
// 	struct aoi_object* oleader = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
// 	if (oleader && IsPlayer(oleader) && IsTeamLeader(space,oleader)){
// 		struct aoi_result* result = space->result;
// 		struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, oleader->m_iTeamEid);
// 		if (team){
// 			AppendLl(result, 0);
// 			AppendLl(result, eid);
// 			uint32_t ll = result->ll_n;
// 			struct map* old_view = GetView(oleader);
// 			struct aoi_object* obj = NULL;
// 			int32_t team_weight = 0;
// 			int32_t p_left_weight = 0;
// 			uint32_t i = 0;
// 			uint32_t j = 0;
// 			for (i=0;i<old_view->size;i++) {
// 				obj = old_view->slot[i].obj;
// 				if (obj == NULL){
// 					continue;
// 				}
// 				if (obj->m_iTeamEid == oleader->m_iTeamEid){
// 					continue;
// 				}
// 				if (InTeam(space,obj) && !IsTeamLeader(space,obj)){
// 					continue;
// 				}
// 				team_weight = 0;
// 				for (j=0;j<team->ml;j++){
// 					if (!map_query(space, GetView(obj), team->m_lMem[j])){
// 						team_weight ++ ;
// 					}
// 				}
// 				p_left_weight = GetMaxOtherWeight(obj) - GetOtherWeight(obj);
// 				if (p_left_weight < team_weight){
// 					if (InTeam(space,obj)){
// 						struct aoi_teaminfo* team2 = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
// 						for (j=0;j<team2->ml;j++){
// 							AppendLl(result, team2->m_lMem[j]);
// 						}
// 					}
// 					else{
// 						AppendLl(result, GetEid(obj));
// 					}
// 				}
// 			}
// 			while (ll < result->ll_n) {
// 				struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[ll]);
// 				if (oo) {
// 					LeaveView(space, oo, oleader);
// 					LeaveView(space, oleader, oo);
// 				}
// 				ll++;
// 			}
// 		}
// 	}
// }

static void SyncTeamLeaderView(struct aoi_space* space,uint32_t eid){
	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
	if (obj && IsPlayer(obj) && IsTeamLeader(space,obj)){
		struct map* new_view = map_new(space, 256);
		struct map* leader_view = GetView(obj);
		struct aoi_object* oo = NULL;
		uint32_t i = 0;
		for (i=0;i<leader_view->size;i++) {
			oo = leader_view->slot[i].obj;
			if (oo){
				map_insert(space, new_view, GetEid(oo), (void*)oo);
			}
		}
		map_insert(space, new_view, GetEid(obj), (void*)obj);
		struct aoi_result* result = space->result;
		struct aoi_teaminfo* team = (struct aoi_teaminfo*)map_query(space, space->m_mAllTeam, obj->m_iTeamEid);
		if (team){
			uint32_t j,ll,el;
			for ( j = 1 ; j < team->ml ; j++){
				uint32_t mem_eid = team->m_lMem[j];
				struct aoi_object* mem = (struct aoi_object*)map_query(space, space->m_mAllObject, mem_eid);
				if (mem){
					map_drop(space, new_view, GetEid(mem));
					struct map* old_view = GetView(mem);
					struct result_action rea1;
					rea1.type = 1;
					rea1.space = space;
					rea1.old = old_view;
					rea1.new = new_view;
					AppendLl(result, 0);
					AppendLl(result, mem_eid);
					ll = result->ll_n;
					map_foreach(space, old_view, map_foreach_func1, (void*)&rea1);

					struct result_action rea2;
					rea2.type = 0;
					rea2.space = space;
					rea2.old = old_view;
					rea2.new = new_view;
					AppendLe(result,0);
					AppendLe(result,mem_eid);
					el = result->le_n;
					map_foreach(space, new_view, map_foreach_func1, (void*)&rea2);
					map_insert(space, new_view, GetEid(mem), (void*)mem);

					while (ll < result->ll_n) {
						struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[ll]);
						if (oo) {
							LeaveView(space, oo, mem);
							LeaveView(space, mem, oo);
						}
						ll++;
					}

					while (el < result->le_n) {
						struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->le[el]);
						if (oo) {
							EnterView(space, oo, mem);
							EnterView(space, mem, oo);
						}
						el++;
					}
				}
			}
		}
		map_delete(space, new_view);
		new_view = NULL;
	}
}

void AoiUpdateObjectWeight(struct aoi_space* space, void* ud, aoi_Callback my_callback, uint32_t eid, uint8_t weight) {
	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
	assert(obj && IsPlayer(obj) && weight>=0);

	uint8_t my_weight = GetWeight(obj);
	SetWeight(obj, weight);

	int8_t add_weight = weight - my_weight;

	struct aoi_result* result = space->result;
	if (add_weight==0) {
		InitResult(result);
		my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
		return;
	} else {
		struct map* old_view = GetView(obj);

		if (add_weight > 0) {
			InitResult(result);

			struct weight_action wea;
			wea.space = space;
			wea.add_weight = add_weight;
			map_foreach(space, old_view, map_foreach_func2, (void*)&wea);

			uint32_t i = 0;
			while (i < result->ll_n) {
				struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[i]);
				if (oo) {
					LeaveView(space, oo, obj);
					LeaveView(space, obj, oo);
				}
				i++;
			}

			int8_t over_num = GetOtherWeight(obj) - GetMaxOtherWeight(obj);
			if (over_num>0) {
				struct map* old_view2 = GetView(obj);

				struct weight_action wea2;
				wea2.space = space;
				wea2.add_weight = over_num;
				map_foreach(space, old_view2, map_foreach_func6, (void*)&wea2);

				uint32_t j = i;
				while (j < result->ll_n) {
					struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[j]);
					if (oo) {
						LeaveView(space, oo, obj);
						LeaveView(space, obj, oo);
					}
					j++;
				}
			}

			my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
		} else {
			InitResult(result);

			struct weight_action wea;
			wea.space = space;
			wea.add_weight = add_weight;
			map_foreach(space, old_view, map_foreach_func3, (void*)&wea);

			my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
		}
	}
}

void AoiRemoveObject(struct aoi_space* space, void* ud, aoi_Callback my_callback, uint32_t eid) {
	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
	assert(obj);

	struct aoi_result* result = space->result;

	InitResult(result);

	struct map* old_view = GetView(obj);
	map_foreach(space, old_view, map_foreach_func4, (void*)space);

	uint32_t i = 0;
	while (i < result->ll_n) {
		struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, result->ll[i]);
		if (oo) {
			LeaveView(space, oo, obj);
			LeaveView(space, obj, oo);
		}
		i++;
	}

	int16_t now_x, now_y;
	GetPos(obj, &now_x, &now_y);
        	if (now_x >= 0 && now_y >= 0) {
        		int32_t old_key = GridKey(space, now_x, now_y);
        		if (old_key >= 0) {
        			struct aoi_grid* old_grid = (struct aoi_grid*)map_query(space, space->m_mAllGrid, old_key);
        			if (old_grid) {
        				UnlinkAoiObject(old_grid, obj);
        			}
        		}
        	}
        	map_drop(space, space->m_mAllObject, eid);
        	FreeObject((void*)space, eid, (void*)obj);

	my_callback(ud, result->le, result->le_n, result->ll, result->ll_n);
}

void AoiGetView(struct aoi_space* space, uint32_t eid, uint8_t type, uint32_t* lo, uint32_t lo_max, uint32_t* lo_size) {
	struct aoi_object* obj = (struct aoi_object*)map_query(space, space->m_mAllObject, eid);
	assert(obj);

	if (!type) {
		*lo_size = GetViewList(space, obj, lo, lo_max);
	} else {
		*lo_size = GetViewListByType(space, obj, type, lo, lo_max);
	}
}


static inline struct map_slot* mainposition(struct map* m , uint32_t id) {
	uint32_t hash = id & (m->size-1);
	return &m->slot[hash];
}

static int map_foreach_func1(void* ud, uint32_t key, void* obj) {
	struct result_action* ac = (struct result_action*)ud;
	uint8_t type = ac->type;
	struct aoi_space* space = ac->space;
	struct aoi_result* result = space->result;
	struct map* old = ac->old;
	struct map* new = ac->new;

	if (type) {
		if (!map_query(space, new, key)) {
			AppendLl(result, key);
		}
	} else {
		if (!map_query(space, old, key)) {
			AppendLe(result, key);
		}
	}

	return 0;
}

static int map_foreach_func2(void* ud, uint32_t key, void* obj) {
	struct weight_action* ac = (struct weight_action*)ud;
	struct aoi_space* space = ac->space;
	struct aoi_result* result = space->result;
	int8_t add_weight = ac->add_weight;

	struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, key);
	if (oo) {
		int32_t max_other_weight = GetMaxOtherWeight(oo);
		if (max_other_weight<0) {
			SuppleOtherWeight(oo, add_weight);
		} else {
			int32_t left_weight = max_other_weight - GetOtherWeight(oo);
			if (add_weight>left_weight) {
				AppendLl(result, key);
			} else {
				SuppleOtherWeight(oo, add_weight);
			}
		}
	}

	return 0;
}

static int map_foreach_func3(void* ud, uint32_t key, void* obj) {
	struct weight_action* ac = (struct weight_action*)ud;
	struct aoi_space* space = ac->space;
	int8_t add_weight = ac->add_weight;

	struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, key);
	if (oo) {
		SuppleOtherWeight(oo, add_weight);
	}

	return 0;
}

static int map_foreach_func4(void* ud, uint32_t key, void* obj) {
	struct aoi_space* space = (struct aoi_space*)ud;
	struct aoi_result* result = space->result;

	struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, key);
	if (oo) {
		AppendLl(result, key);
	}

	return 0;
}

static int map_foreach_func5(void* ud, uint32_t key, void* obj) {
	struct view_action* ac = (struct view_action*)ud;
	struct aoi_space* space = ac->space;
	uint8_t type = ac->type;
	uint32_t* lo = ac->lo;
	uint32_t lo_max = ac->lo_max;
	uint32_t lo_size = ac->lo_size;

	if (lo_size>=lo_max) {
		return 1;
	}

	struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, key);
	if (oo) {
		if (!type) {
			lo[lo_size] = key;
			ac->lo_size++;
		} else {
			if (oo->m_iAcType==type) {
				lo[lo_size] = key;
				ac->lo_size++;
			}
		}
	}

	return 0;
}

static int map_foreach_func6(void* ud, uint32_t key, void* obj) {
	struct weight_action* ac = (struct weight_action*)ud;
	struct aoi_space* space = ac->space;
	struct aoi_result* result = space->result;
	int8_t add_weight = ac->add_weight;

	if (add_weight<=0) {
		return 1;
	}

	struct aoi_object* oo = (struct aoi_object*)map_query(space, space->m_mAllObject, key);
	if (oo) {
		uint8_t other_weight = GetWeight(oo);
		if (other_weight>0) {
			AppendLl(result, key);
			ac->add_weight = ac->add_weight - other_weight;
		}
	}

	return 0;
}