#ifndef COMMAND_PROTOCOL_H
#define COMMAND_PROTOCOL_H

#define MOTE_ID_LIST {10}
#define BASE_ID 30
#define MIGIC_NUM_CMD 0xdb87


typedef nx_struct {
    nx_uint16_t time;
}Command;

typedef nx_struct {
    nx_uint16_t magic;
    nx_uint8_t seq; //seq实际上只要一位即可
    Command cmd;
}CommandMsg;

typedef nx_struct {
    nx_uint16_t magic;
    nx_uint8_t seq;   //前４位为序列号，后４位表示id
    nx_uint16_t　id;
}MoteAck;
//传输命令与传输传感信号采用不同的端口号
#define COMMAND_PORT 27
//超过此时间(单位为毫秒)则基站节点进行重传
#define EXPIRE 2000
#endif