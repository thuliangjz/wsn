#ifndef BLINKTOCOMPUTE_H
#define BLINKTOCOMPUTE_H

enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 10
};

typedef nx_struct BlinkToRadioMsg {
  nx_uint16_t sequence_number;
  nx_uint32_t random_integer;
} BlinkToRadioMsg;

#endif
