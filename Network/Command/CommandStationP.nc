#include "CommandProtocol.h"

typedef struct {
    uint8_t moteId;
    bool isAcked;
}AckStatus;
module CommandStationP {
    uses {
        interface Boot;
        interface Timer<TMilli> as Timer;
        interface Packet;
        interface AMPacket;
        interface AMSend;
        interface Receive;
        //注意这里没有使用ActiveMessage的Controller对广播进行控制，考虑到
        //还有别的组件也要使用广播
    }
    provides {
        interface CommandStationInterface as Station;
    } 
}
implementation {
    uint8_t moteIdList[] = MOTE_ID_LIST;
    message_t cmdBuffer;
    uint8_t seqCurrent = 0;     //当前发送命令的序列号,起始为０
    AckStatus ackList[sizeof(moteIdList)];
    uint8_t numAcked;       //记录总共收到多少个ack的辅助变量
    uint8_t moteCount = sizeof(moteIdList);     //记录节点数目的常量
    
    void resetAckList(){
        uint8_t i;
        for(i = 0; i < moteCount; ++i){
            ackList[i].moteId = moteIdList[i];
            ackList[i].isAcked = FALSE;           
        }
        numAcked = 0;
    }
    event void Boot.booted(){
        resetAckList();
        numAcked = moteCount;   //避免初始状态下发送返回EBUSY
    }
    command error_t Station.sendCommand(Command cmd){
        CommandMsg *pMsg;
        if(numAcked < moteCount){
            return EBUSY;
        }
        pMsg = (CommandMsg*)(call Packet.getPayload(&cmdBuffer, sizeof(CommandMsg)));
        pMsg->magic = MAGIC_NUM_CMD;
        pMsg->seq = seqCurrent;
        pMsg->cmd = cmd;
        call AMSend.send(AM_BROADCAST_ADDR, &cmdBuffer, sizeof(CommandMsg));
        resetAckList();
        return SUCCESS;
    }
    event void AMSend.sendDone(message_t* msg, error_t err){
        call Timer.startOneShot(EXPIRE); //启动计时器
    }
    event void Timer.fired(){
        if(numAcked == moteCount){
            return;
        }
        //重新广播
        call AMSend.send(AM_BROADCAST_ADDR, &cmdBuffer, sizeof(CommandMsg));
    }
    event message_t *Receive.receive(message_t* msg, void* payload, uint8_t len){
        MoteAck* pAck = (MoteAck*)payload;
        //获取Ack中的序列号和节点id
        uint8_t seqAck, idAck, i;
        if(len != sizeof(MoteAck) || pAck->magic != MAGIC_NUM_CMD || numAcked >= moteCount)
            return msg;
        seqAck = pAck->seq;
        idAck = pAck->Id;
        //printf("seqAck:%u, idAck:%u, seqCurrent:%u\n", seqAck, idAck, seqCurrent);
        if(seqAck == seqCurrent){
            for(i = 0; i < moteCount; ++i){
                if(ackList[i].moteId == idAck && !ackList[i].isAcked){
                    ackList[i].isAcked = TRUE;
                    ++numAcked;
                }
            }
        }
        if(numAcked == moteCount){
            //printf("all received\n");
            //更新序列号
            ++seqCurrent;
            seqCurrent &= 1;
            signal Station.commandSendDone();
        }
        //printfflush();
        return msg;
    }
}