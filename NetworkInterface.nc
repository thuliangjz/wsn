#include "TinyError.h"

interface NetworkInterface {
    /*
    发送传感器数据的接口
    data:传输的数据指针，只进行拷贝，len:传输数据的长度
    以最大的可能性保证消息传输成功，设值一个传输队列，
    每来到一个消息就自动的加入消息队列中，如果队列已满则将第一个元去掉
    除非长度超过了一个数据包的长度，否则都会返回SUCCESS(过长时返回ESIZE)
    */
    command error_t sendSenserData(void* data, unit8_t len);
    /*
    发送设置命令的接口
    参数同sendSenserData
    返回值：
    ESIZE:参数过长
    EBUSY:上一个包还未发送成功
    SUCCESS:发送成功
    */
    command error_t sendCommandData(void *data, uint8_t len);
}