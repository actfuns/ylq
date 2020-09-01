
#include "twheel.h"

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <inttypes.h>

static struct TimeNode*
timelist_clear(struct TimeList* l){
    struct TimeNode* ret = (l -> head).next;
    (l -> head).next = 0;
    l -> tail = &(l -> head);
    return ret;
}

static void
timelist_add(struct TimeList* l, struct TimeNode* n){
    (l -> tail) -> next = n;
    n -> next = 0;
    l -> tail = n;
}

static void
timewheel_add_node(struct TimeWheel* TW, struct TimeNode* node){
    uint32_t curr_time = TW -> curr_time;
    uint32_t delay_time = node -> time;

    //overflow
    if (delay_time < curr_time) {
        timelist_add(&TW -> overflow, node);
        return;
    }

    //judge time zone to near-far put
    if ((delay_time|TIME_NEAR_MASK) == (curr_time|TIME_NEAR_MASK)){
        timelist_add(&TW -> near[(delay_time&TIME_NEAR_MASK)], node);
    }else{
        uint32_t t1 = curr_time >> TIME_NEAR_SHIFT;
        uint32_t t2 = delay_time >> TIME_NEAR_SHIFT;
        uint32_t i;
        for(i = 0; i < 4; i++){
            if ((t1 | TIME_FAR_MASK) == (t2 | TIME_FAR_MASK)){
                break;
            }
            t1 >>= TIME_FAR_SHIFT;
            t2 >>= TIME_FAR_SHIFT;
        }
        timelist_add(&TW -> far[i][(t2 & TIME_FAR_MASK)], node);
    }
}

static void
timewheel_shift(struct TimeWheel* TW){
    LOCK(TW);

    TW -> curr_time ++;
    uint32_t t = TW -> curr_time;

    if (t == 0) {
        struct TimeNode* next = timelist_clear(&(TW -> overflow));
        while(next){
            struct TimeNode* temp = next -> next;
            timewheel_add_node(TW, next);
            next = temp;
        }
    } else {
        if (!(t & TIME_NEAR_MASK)){
            t >>= TIME_NEAR_SHIFT;
            uint32_t level = 0;
            while(t){
                if (t & TIME_FAR_MASK){
                    struct TimeNode* next = timelist_clear(&(TW -> far[level][(t&TIME_FAR_MASK)]));
                    while(next){
                        struct TimeNode* temp = next -> next;
                        timewheel_add_node(TW, next);
                        next = temp;
                    }
                    break;
                }
                t >>= TIME_FAR_SHIFT;
                level ++;
            }
        }
    }

    UNLOCK(TW);
}

static void
timewheel_execute(struct TimeWheel* TW, time_Callback cb, void* ud){
    LOCK(TW);
    struct TimeNode* next = timelist_clear(&(TW -> near[(TW -> curr_time & TIME_NEAR_MASK)]));
    UNLOCK(TW);

    while(next) {
        cb(ud, next -> handle);
        struct TimeNode* temp = next;
        next = next -> next;
        free(temp);
        temp = NULL;
    }
}

void
timewheel_release(struct TimeWheel*  TW){
    LOCK(TW);

    uint32_t i, j;
    for(i = 0; i < TIME_NEAR; i++){
        struct TimeNode* next = timelist_clear(&TW -> near[i]);
        while(next) {
            struct TimeNode* temp = next;
            next = next -> next;
            free(temp);
            temp = NULL;
        }
    }

    for(i = 0; i < 4; i++){
        for(j = 0; j < TIME_FAR; j++){
            struct TimeNode* next = timelist_clear(&TW -> far[i][j]);
            while(next) {
                struct TimeNode* temp = next;
                next = next -> next;
                free(temp);
                temp = NULL;
            }
        }
    }

    struct TimeNode* next = timelist_clear(&TW -> overflow);
    while(next) {
        struct TimeNode* temp = next;
        next = next -> next;
        free(temp);
        temp = NULL;
    }

    free(TW);
    TW = NULL;
}

struct TimeWheel*
timewheel_create(uint64_t t){
    struct TimeWheel* TW = malloc(sizeof(*TW));
    memset(TW, 0, sizeof(*TW));
    TW -> start_time = t;
    TW -> curr_time = 0;
    TW -> lock = 0;

    //clear & init time list
    uint32_t i, j;
    for(i = 0; i < TIME_NEAR; i++){
        timelist_clear(&TW -> near[i]);
    }

    for(i = 0; i < 4; i++){
        for(j = 0; j < TIME_FAR; j++){
            timelist_clear(&TW -> far[i][j]);
        }
    }

    timelist_clear(&TW -> overflow);

    return TW;
}

void
timewheel_add_time(struct TimeWheel* TW, uint64_t handle , uint32_t t){
    LOCK(TW);

    assert(t > 0);
    uint32_t curr_time = TW -> curr_time;
    uint32_t delay_time = curr_time + t;

    struct TimeNode* node = malloc(sizeof(*node));
    memset(node, 0, sizeof(*node));
    node -> time = delay_time;
    node -> handle = handle;
    node -> next = 0;

    timewheel_add_node(TW, node);

    UNLOCK(TW);
}

void
timewheel_update(struct TimeWheel* TW, uint64_t t, time_Callback cb, void* ud){
    assert(t >= TW -> start_time);
    int64_t diff = t - (TW -> start_time + TW -> curr_time);
    assert(diff >= 0);

    if (diff == 0)
        return;

    int64_t i;
    for (i = 0; i < diff; i++){
        timewheel_shift(TW);
        timewheel_execute(TW, cb, ud);
    }
}
