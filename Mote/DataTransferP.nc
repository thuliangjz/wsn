#include "DataTransferProtocol.h"
#include "printf.h"

generic module DataTransferP (uint16_t destId) {
    provides interface DataTransferInterface as Transmitter;
    uses {
        interface AMSend;
        interface Receive;
        interface Packet;
        interface AMPacket;
        interface PacketAcknowledgements as Ack;
        interface Leds;
    }
}
implementation {
    message_t msgQue[QUE_SIZE];
    int8_t head = 0, tail = 0;  //tail永远指向下一个可以使用的缓冲区
    int8_t queLenght = 0;
    uint16_t dest = destId;
    bool busy = FALSE;
    //message_t allocateBuffer();
    //message_t pop();
    task void sendTask();

    command error_t Transmitter.sendData(SensorData data){
        DataPacket *pContent;
        //当队列已满时不在接受上层传来的包，返回EBUSY提示队列已满
        if(queLenght >= QUE_SIZE)
            return EBUSY;
        atomic{
            //将一个包放入队列中，当这个函数被时钟中断时
            //或者包还没有放进去,队列状态保持原状
            //或者包已经放进去，队列状态已更新
            ++tail;
            ++queLenght;
            tail %= QUE_SIZE;
            pContent = (DataPacket*)(call Packet.getPayload(&msgQue[tail], sizeof(DataPacket)));
            pContent->magic = MAGIC_SENSOR_DATA;
            pContent->data = data;
        }
        if(!busy){
            //如果为busy，则说明sendTask已经被调用，
            //在sendDone函数中会再次触发sendTask
            post sendTask();
        }
        return SUCCESS;
    }
    task void sendTask(){
        if(queLenght == 0){
            busy = FALSE;
            return;
        }
        busy = TRUE;
        call Ack.requestAck(&msgQue[head]);
        call AMSend.send(dest, &msgQue[head], sizeof(DataPacket));
    }
    event void AMSend.sendDone(message_t *msg, error_t err){
        //检查是否发送成功，如果成功从队列中弹出开头，触发下一个发送事件
        bool acked = call Ack.wasAcked(msg);
        if(acked){
            //从队列中弹出head
            atomic{
                ++head;
                head %= QUE_SIZE;
                --queLenght;
            }
        }
        post sendTask();
    }
    event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len){
        //检查魔数是否匹配，通知上层有新的数据传来
        DataPacket *pData = (DataPacket*)payload;
        if(len != sizeof(DataPacket) || pData->magic != MAGIC_SENSOR_DATA){
            return msg;
        }
        signal Transmitter.dataReceived(pData->data);
        return msg;
    }
}