#include "CommandProtocol.h"
module CommandMoteP {
    uses {
        interface Receive;
        interface Boot;
        interface AMPacket;
        interface Packet;
        interface AMSend;
        interface Leds;
    }
    provides interface CommandMoteInterface;
}

implementation {
    uint8_t seqCurrent = 0; //当前期望的序列号
    bool busy = FALSE;
    message_t ackMsg;
    Command cmdBuffer;
    event void Boot.booted(){
        seqCurrent = 3;
    }
    event message_t* Receive.receive(message_t *msg, void* payload, uint8_t len){
        MoteAck *pAck;
        CommandMsg *pCmd = (CommandMsg*)payload;
        uint8_t seq;
        if(len != sizeof(MoteAck) || pCmd->magic != MAGIC_NUM_CMD)
            return msg;

        //如果上一个ack还未发出则drop掉这个包
        if(!busy){
            //返回ack
            busy = TRUE;
            pAck = (MoteAck*)(call Packet.getPayload(&ackMsg, sizeof(MoteAck)));
            pAck->magic = MAGIC_NUM_CMD;
            pAck->seq = pCmd->seq;
            pAck->id = TOS_NODE_ID;
            call AMSend.send(BASE_ID, &ackMsg, sizeof(MoteAck));
        }

        //如果包中的seq与当前保存的seq不相同则发送newCommand消息
        //seq为３表示刚刚启动
        if(seqCurrent == 3 || pCmd->seq == seqCurrent){
            memcpy(&cmdBuffer, &(pCmd->cmd), sizeof(Command));
            //避免过长的操作栈
            signal CommandMoteInterface.newCommand(cmdBuffer);
            seqCurrent = (pCmd->seq + 1) & 1;  //更新期望的seq
        }
        return msg;
    }
    event void AMSend.sendDone(message_t *msg, error_t err){
        busy = FALSE;
    }
}
