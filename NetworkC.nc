#include "AM.h"
#include "TinyError.h"
module NetworkC{
    uses {
        interface Boot;
        interface Packet;
        interface AMPacket;
        interface AMSend;
        interface SplitControl as AMControl;
        interface Acks; //设置数据包需要ack的接口
    }
    provides {
        interface NetworkInterface;
    }
}
implementation {
    bool commandBusy = FALSE;
    message_t commandMsg;

    //在加载成功之后启动广播
    event void Boot.booted(){
        call AMControl.start();
    }
    event void AMControl.startDone(error_t err){
        if(err != SUCCESS){
            call AMControl.start();
            return;
        }
        Acks.requestAck(&commandMsg);
    }
    event void AMControl.stopDone(error_t err){
    }

    command error_t sendCommandData(void *data,
     uint8_t len){
        if(commandBusy){
            return EBUSY;
        }  
        void *pBuffer = call Packet.getPayload(&pkt, len);
        if(!pBuffer){
            return ESIZE;
        }
        memcpy(pBuffer, data, len);
        call AMSend.send(AM_BROADCAST_ADDR, &commandMsg ,len);
        busy = TRUE;
    }
    event void AMSend.sendDone(message_t*msg, error_t err){
        if(msg == &commandMsg){
            busy = FALSE;
        }
    }
}