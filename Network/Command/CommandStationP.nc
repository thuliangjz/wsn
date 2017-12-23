#include "CommandProtocol.h"

typedef struct {
    uint16_t moteId;
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
    uint16_t moteIdList[] = MOTE_ID_LIST;
    message_t cmdBuffer;
    uint8_t seqCurrent = 0;     //当前发送命令的序列号,起始为０
    AckStatus ackList[sizeof(moteIdList)];
    uint8_t numAcked;       //记录总共收到多少个ack的辅助变量
    uint8_t moteCount = sizeof(moteIdList);     //记录节点数目的常量


    uint8_t idxMoteSend;
    task void sendCmdP2P();

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
        idxMoteSend = 0;
        numAcked = 0;
        //准备commandMsg的内容，以后只进行发送
        pMsg = (CommandMsg*)(call Packet.getPayload(&cmdBuffer, sizeof(CommandMsg)));
        pMsg->magic = MAGIC_NUM_CMD;
        pMsg->seq = seqCurrent;
        pMsg->cmd = cmd;
        //所有节点都置为未ack
        resetAckList();
        post sendCmdP2P();
        return SUCCESS;
    }
    event void AMSend.sendDone(message_t* msg, error_t err){
        if(idxMoteSend < moteCount){
            //保证发送的串行化
            post sendCmdP2P();
        }
        else{
            Timer.startOneShot(EXPIRE);
        }
    }
    event void Timer.fired(){
        if(numAcked == moteCount){
            return;
        }
        //重启发送任务
        idxMoteSend = 0;
        post sendCmdP2P();
    }
    event message_t *Receive.receive(message_t* msg, void* payload, uint8_t len){
        MoteAck* pAck = (MoteAck*)payload;
        //获取Ack中的序列号和节点id
        uint8_t seqAck, idAck, i;
        if(len != sizeof(MoteAck) || pAck->magic != MAGIC_NUM_CMD || numAcked >= moteCount)
            return msg;
        seqAck = pAck->seq;
        idAck = pAck->Id;
        if(seqAck == seqCurrent){
            for(i = 0; i < moteCount; ++i){
                if(ackList[i].moteId == idAck && !ackList[i].isAcked){
                    ackList[i].isAcked = TRUE;
                    ++numAcked;
                }
            }
        }
        if(numAcked == moteCount){
            //更新序列号
            ++seqCurrent;
            seqCurrent &= 1;
            signal Station.commandSendDone();
        }
        return msg;
    }
    task void sendCmdP2P(){
        if(idxMoteSend >= moteCount)
            return;
        while(idxMoteSend < moteCount && ackList[idxMoteSend].isAcked){
            ++idxMoteSend;
        }
        if(idxMoteSend >= moteCount)
            return;
        call AMSend.send(moteIdList[idxMoteSend], &cmdBuffer, sizeof(CommandMsg));
        ++idxMoteSend;
    }
}