
#ifndef _TWHEEL_H_
#define _TWHEEL_H_

#include <stdint.h>

#define TIME_NEAR_SHIFT 8
#define TIME_NEAR (1 << TIME_NEAR_SHIFT)
#define TIME_NEAR_MASK (TIME_NEAR - 1)
#define TIME_FAR_SHIFT 6
#define TIME_FAR (1 << TIME_FAR_SHIFT)
#define TIME_FAR_MASK (TIME_FAR - 1)

#define LOCK(X) while (__sync_lock_test_and_set(&((X)->lock),1)) {}
#define UNLOCK(X) __sync_lock_release(&((X)->lock))

typedef void (time_Callback)(void *ud, uint64_t handle);

struct TimeNode {
    uint32_t time;
    uint64_t handle;
    struct TimeNode* next;
};

struct TimeList {
    struct TimeNode head;
    struct TimeNode* tail;
};

struct TimeWheel {
    uint32_t lock;
    uint32_t curr_time;
    uint64_t start_time;
    struct TimeList near[TIME_NEAR];
    struct TimeList far[4][TIME_FAR];
    struct TimeList overflow;
};


//user interface

struct TimeWheel*
timewheel_create(uint64_t t);

void
timewheel_release(struct TimeWheel* TW);

void
timewheel_add_time(struct TimeWheel* TW, uint64_t handle , uint32_t t);

void
timewheel_update(struct TimeWheel* TW, uint64_t t, time_Callback cb, void* ud);

#endif
