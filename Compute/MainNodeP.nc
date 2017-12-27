#include "defs.h"
//位图单个字节从低位起开始进行索引
#define STATE_LISTENING 0
#define STATE_REPORTING 1
#define STATE_SWAPING 2
#define STATE_COMPUTING 3

module MainNodeP {
    uses {
        interface Receive;
        interface Boot;
        interface AMSend;
        interface Packet;
        interface SplitControl as AMControl;
        interface PacketAcknowledgements as AckInterface;
    }
}
implementation {
    uint32_t numbers[COUNT_NUMBERS];        //存放收到的数字的槽
    uint8_t numBitmp[COUNT_NUMBERS / 8]={0};    //记录哪些位置被放置上数据的位视图
    uint8_t state = STATE_LISTENING;
    int16_t countLatest = 1;
    int16_t totalLoss = 0;
    //Report阶段需要用到的变量
    int16_t reportNumIdx = 0;
    int16_t reportNodeIdx = 0;
    uint16_t assistNodes[] = ASSIST_NODE_IDS;
    message_t reportMsg;
    task void ReportTask();
    task void ComputeTask();
    void sortNumbers();
    event void Boot.booted(){
        //初始化位视图
        call AMControl.start();
    }
    event void AMControl.startDone(error_t err){}
    event void AMControl.stopDone(error_t err){}
    task void ComputeTask(){
        AnswerPacket answer;
        AnswerPacket *pAnswer;
        uint16_t i = 1;
        answer.group = GROUP_ID;
        answer.max = numbers[0];
        answer.min = numbers[0];
        answer.sum = 0;
        //计算所有可以在一次扫描中完成的计算
        for(; i < COUNT_NUMBERS; ++i){
            answer.max = numbers[i] > answer.max ? numbers[i] : answer.max;
            answer.min = numbers[i] < answer.min ? numbers[i] : answer.min;
            answer.sum += numbers[i];
        }
        answer.average = answer.sum / COUNT_NUMBERS;
        sortNumbers();
        answer.median = (numbers[COUNT_NUMBERS/2] + numbers[COUNT_NUMBERS/2 + 1])/2;
        //复用reportMsg作为向监听节点汇报的结构
        pAnswer = (AnswerPacket*)(call Packet.getPayload(&reportMsg, sizeof(AnswerPacket)));
        *pAnswer = answer;
        call AckInterface.requestAck(&reportMsg);
        call AMSend.send(LISTENER_ID, &reportMsg, sizeof(AnswerPacket));
    }
    task void ReportTask(){
        ReportPacket *pReport = (ReportPacket*)(call Packet.getPayload(&reportMsg, sizeof(ReportPacket)));
        if(reportNumIdx > COUNT_NUMBERS){
            //reportNumIdx可以为2000，这个包对于辅助节点意味着收包过程的结束
            //进入扫尾阶段
            state = STATE_SWAPING;
            return;
        }
        while(reportNumIdx < COUNT_NUMBERS && !CHECK_BMP(numBitmp,reportNumIdx)){
            ++reportNumIdx;
        }
        pReport->seq = reportNumIdx;
        reportNodeIdx = 0;  //开始向第一个节点发送消息
        call AckInterface.requestAck(&reportMsg);
        call AMSend.send(assistNodes[reportNodeIdx], &reportMsg, sizeof(ReportPacket));
    }

    event void AMSend.sendDone(message_t* msg, error_t err){
        bool acked = AckInterface.wasAcked(&reportMsg);
        if(state != STATE_COMPUTING){
            if(acked){
                ++reportNodeIdx;
                if(reportNodeIdx < ASSIST_NODE_COUNT){
                    call AckInterface.requestAck(&reportMsg);
                    call AMSend.send(assistNodes[reportNodeIdx], &reportMsg, sizeof(ReportPacket));
                }
                else{
                    //更新ReportTask中扫描的序列号，有可能出现reportNumIdx为COUNT +1的情况
                    ++reportNumIdx;
                    post ReportTask();
                }
            }
            else{
                    call AckInterface.requestAck(&reportMsg);
                    call AMSend.send(assistNodes[reportNodeIdx], &reportMsg, sizeof(ReportPacket));
            }
        }
        else{
            if(!acked){
                call AckInterface.requestAck(&reportMsg);
                call AMSend.send(LISTENER_ID, &reportMsg, sizeof(AnswerPacket));
            }
        }
    }
    event message_t *Receive.receive(message_t *msg, void* payload, uint8_t len){
        //计算节点收到的包只会为numberPacket形式
        //注意以包中的seq作为索引时是从1开始进行索引的
        NumberPacket *pPkt = (NumberPacket*)payload;
        uint16_t seq = pPkt->seq;
        bool flag;
        if(state == STATE_LISTENING){
            //如果收到的序列号小于expected，则说明第二次广播已经开始，状态跳转
            if(seq < countLatest){
                state = STATE_REPORTING;
                post ReportTask();
            }
            totalLoss += pPkt->seq - countLatest;
            countLatest = pPkt->seq;
            ++countLatest;
            SET_BMP(numBitmp,seq);
            numbers[seq] = pPkt->number;
        }
        //在计算阶段drop掉所有的包
        else if(state != STATE_COMPUTING) {
            flag = CHECK_BMP(numBitmp,seq);
            if(!flag){
                numbers[seq] = pPkt->number;
                SET_BMP(numBitmp,seq);
                --totalLoss;
            }
            if(totalLoss == 0){
                state = STATE_COMPUTING;
                post ComputeTask();
            }
        }
        return msg;
    }
    //使用插入排序对节点进行排序
    void sortNumbers(){
        int16_t i, j;
        uint32_t tmp;
        for(i = 1; i < COUNT_NUMBERS; ++i){
            for(j = i - 1; j > 0; --j){
                if(numbers[j] > tmp){
                    numbers[j + 1] = numbers[j];
                }
                else{
                    numbers[j + 1] = tmp;
                }
            }
        }
    }
}