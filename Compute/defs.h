#ifndef DEFS_H
#define DEFS_H

#define COMM_PORT 0
#define ASSIST_NODE_IDS {4, 5}
#define MAIN_NODE_ID 6
#define ASSIST_NODE_COUNT 2
#define LISTENER_ID 1000
#define LISTENER_PORT 0
#define RESULT_ID 0

#define COUNT_NUMBERS 2000
#define GROUP_ID 2
#define CHECK_BMP(bmp,i) (((bmp)[(i)/8]>>((i)%8))&1)
#define SET_BMP(bmp,i) (bmp)[(i)/8]=(bmp)[(i)/8]|(1<<((i)%8))
#define CLEAR_BMP(bmp,i) (bmp)[(i)/8]=(bmp)[(i)/8]&~(1<<((i)%8))

typedef nx_struct {
    nx_uint16_t seq;
    nx_uint32_t number;
}NumberPacket; 

typedef nx_struct {
    nx_uint16_t seq;
}ReportPacket;

typedef nx_struct {
    nx_uint8_t group;
    nx_uint32_t max;
    nx_uint32_t min;
    nx_uint32_t sum;
    nx_uint32_t average;
    nx_uint32_t median;
}AnswerPacket;
#endif