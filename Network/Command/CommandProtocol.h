#ifndef COMMAND_PROTOCOL_H
#define COMMAND_PROTOCOL_H

#define MOTE_ID_LIST {100, 200}
#define MAGIC_NUM_CMD 0xdb87


typedef nx_struct {
    nx_uint16_t time;
}Command;

typedef nx_struct {
    nx_uint16_t magic;
    Command cmd;
}CommandMsg;

//传输命令与传输传感信号采用不同的端口号
#define COMMAND_PORT 27
#endif