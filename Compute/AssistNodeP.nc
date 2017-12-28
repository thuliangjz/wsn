#include "defs.h"

#define STATE_LISTENING 0
#define STATE_RECORDING 1
#define STATE_SERVING 2
#define MAX_IDLE_TIME 50

module AssistNodeP {
    uses {
        interface Packet;
        interface PacketAcknowledgements as AckInterface;
        interface AMSend;
        interface Receive;
        interface AMPacket;
        interface SplitControl as AMControl;
        interface Boot;
        interface Leds;
    }
}
implementation {
    uint32_t numbers[COUNT_NUMBERS];
    uint8_t bmpRemoteLoss[COUNT_NUMBERS/8] = {0};
    uint8_t bmpLocal[COUNT_NUMBERS/8] = {0};
    uint8_t state = STATE_LISTENING;
    bool serving;
    int16_t servingIdx = 0;
    int16_t numNewpkt = 0;
    int16_t remoteLossTotal = 0;
    message_t msgServe;

    event void Boot.booted(){
        uint16_t i;
        for(i = 0; i < COUNT_NUMBERS; ++i){
            numbers[i] = 0;
        }
        for(i = 0; i < COUNT_NUMBERS/8; ++i){
            bmpLocal[i] = 0;
            bmpRemoteLoss[i] = 0;
        }
        call AMControl.start();
    }
    event void AMControl.startDone(error_t err){}
    event void AMControl.stopDone(error_t err){}
    task void servingTask(){
        int16_t idxLast = (servingIdx - 1) % COUNT_NUMBERS;
        NumberPacket *pNumPkt;
        //注意bmpRemoteLocal为1的位表示主节点需要该序列号对应的数据
        while(servingIdx != idxLast && !(CHECK_BMP(bmpRemoteLoss,servingIdx) &&
        CHECK_BMP(bmpLocal,servingIdx))){
            ++servingIdx;
            servingIdx %= COUNT_NUMBERS;
        }
        if(!(CHECK_BMP(bmpRemoteLoss,servingIdx) &&
        CHECK_BMP(bmpLocal,servingIdx))){
            serving = FALSE;
            return;
        }
        pNumPkt = (NumberPacket*)(call Packet.getPayload(&msgServe, sizeof(NumberPacket)));
        pNumPkt->seq = servingIdx + 1;      //注意这是模拟广播节点传送序列号，从1开始
        pNumPkt->number = numbers[servingIdx];
        call Leds.led2Toggle();
        call AckInterface.requestAck(&msgServe);
        call AMSend.send(MAIN_NODE_ID, &msgServe, sizeof(NumberPacket));
    }
    event void AMSend.sendDone(message_t* msg, error_t err){
        bool acked = call AckInterface.wasAcked(msg);
        if(acked){
            CLEAR_BMP(bmpRemoteLoss,servingIdx);
            --remoteLossTotal;
            //servingIdx从新的地方开始
            ++servingIdx;
            servingIdx %= COUNT_NUMBERS;
            post servingTask();
            return;
        }
        else{
            call AckInterface.requestAck(&msgServe);
            call AMSend.send(MAIN_NODE_ID, &msgServe, sizeof(NumberPacket));
        }
    }
    event message_t *Receive.receive(message_t *msg, void* payload, uint8_t len){
        uint16_t source = call AMPacket.source(msg);
        NumberPacket *pNumPkt;
        ReportPacket *pReportPkt;
        uint16_t seq;
        if(state == STATE_LISTENING){
            if(source == LISTENER_ID){
                call Leds.led0Toggle();
                pNumPkt = (NumberPacket*)payload;
                seq = pNumPkt->seq - 1;
                SET_BMP(bmpLocal, seq);
                numbers[seq] = pNumPkt->number;
            }
            else if(source == MAIN_NODE_ID){
                state = STATE_RECORDING;
                //按照STATE_RECORDING部分的逻辑继续进行处理
            }
        }
        if(state == STATE_RECORDING){
            if(source == LISTENER_ID){
                pNumPkt = (NumberPacket*)payload;
                seq = pNumPkt->seq - 1;
                SET_BMP(bmpLocal, seq);
                numbers[seq] = pNumPkt->number;
            }
            else{
                call Leds.led2Toggle();
                pReportPkt = (ReportPacket*)payload;
                if(pReportPkt->seq < COUNT_NUMBERS){
                    SET_BMP(bmpRemoteLoss,pReportPkt->seq);
                    ++remoteLossTotal;
                    if(CHECK_BMP(bmpLocal,pReportPkt->seq)){
                        call Leds.led1Toggle();
                    }
                }
                else{
                    //Report阶段终止的信号
                    state = STATE_SERVING;
                    servingIdx = 0;
                    serving = TRUE;
                    post servingTask();
                    //不要继续按照STATE_SERVING部分的逻辑进行处理
                    return msg;
                }
            }
        }
        if(state == STATE_SERVING && source == LISTENER_ID){
            pNumPkt = (NumberPacket*)(payload);
            seq = pNumPkt->seq - 1;
            numNewpkt++;
            SET_BMP(bmpLocal,seq);
            numbers[seq] = pNumPkt->number;
            //如果检测到主节点确实没有或者有一段时间没有传包了，则启动serveTask
            if(!serving && remoteLossTotal > 0 && (CHECK_BMP(bmpRemoteLoss,seq) || numNewpkt > MAX_IDLE_TIME)){
                servingIdx = seq;
                serving = TRUE;
                numNewpkt = 0;
                post servingTask();
            }
        }
        return msg;   
    }
}