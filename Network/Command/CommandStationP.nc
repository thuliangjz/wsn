#include "CommandProtocol.h"
typedef struct {
    uint16_t moteId;
    bool isAcked;
}AckStatus;
module CommandStationP {
    uses {
        interface Packet;
        interface AMSend;
        interface PacketAcknowledgements as AckInterface;
        //注意这里没有使用ActiveMessage的Controller对广播进行控制，考虑到
        //还有别的组件也要使用广播
    }
    provides {
        interface CommandStationInterface as Station;
    } 
}
implementation {
    message_t cmdMsgBuffer;
    uint16_t moteIdList[] = MOTE_ID_LIST;
    uint8_t moteCount = sizeof(moteIdList) / sizeof(uint16_t);
    uint8_t idxToSend = sizeof(moteIdList) / sizeof(uint16_t);
    command error_t Station.sendCommand(Command cmd){
        CommandMsg* pMsg;
        if(idxToSend < moteCount){
            return EBUSY;
        }
        //准备buffer
        call AckInterface.requestAck(&cmdMsgBuffer);
        pMsg = (CommandMsg*)(call Packet.getPayload(&cmdMsgBuffer, sizeof(CommandMsg)));
        pMsg->magic = MAGIC_NUM_CMD;
        pMsg->cmd = cmd;
        idxToSend = 0;
        call AMSend.send(moteIdList[idxToSend], &cmdMsgBuffer, sizeof(CommandMsg));
        return SUCCESS;
    }
    event void AMSend.sendDone(message_t* msg, error_t err){
        bool acked = call AckInterface.wasAcked(&cmdMsgBuffer);
        if(acked){
            ++idxToSend;
        }
        if(idxToSend >= moteCount){
            signal Station.commandSendDone();
            return;
        }
        //上一个命令未传到或者还有需要传输命令的节点
        call AckInterface.requestAck(&cmdMsgBuffer);
        call AMSend.send(moteIdList[idxToSend],&cmdMsgBuffer, sizeof(CommandMsg));
    }
}
