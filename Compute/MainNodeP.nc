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
        interface AMPacket;
        interface Packet;
        interface SplitControl as AMControl;
        interface PacketAcknowledgements as AckInterface;
        interface Leds;
    }
}
implementation {
    uint32_t numbers[COUNT_NUMBERS];        //存放收到的数字的槽
    uint8_t numBitmp[COUNT_NUMBERS / 8]={0};    //记录哪些位置被放置上数据的位视图
    uint8_t state = STATE_LISTENING;
    int16_t countLatest = 0;
    int16_t totalLoss = 0;
    //Report阶段需要用到的变量
    int16_t reportNumIdx = 0;
    int16_t reportNodeIdx = 0;
    uint16_t assistNodes[] = ASSIST_NODE_IDS;
    message_t reportMsg;
    bool firstReceived = FALSE;
    task void ReportTask();
    task void ComputeTask();
    uint32_t getMid();
    int16_t partition(uint32_t *arr, int16_t l, int16_t r);
    event void Boot.booted(){
        //初始化位视图
        uint16_t i;
        for(i = 0; i < COUNT_NUMBERS; ++i){
            numbers[i] = 0;
        }
        for(i = 0; i < COUNT_NUMBERS/8 ; ++i){
            numBitmp[i] = 0;
        }
        firstReceived = FALSE;
        call AMControl.start();
    }
    event void AMControl.startDone(error_t err){
        if(err != SUCCESS){
            call AMControl.start();
        }
    }
    event void AMControl.stopDone(error_t err){}
    task void ComputeTask(){
        AnswerPacket *pAnswer;
        AnswerPacket answer;
        uint16_t i = 1;
        call Leds.led1Toggle();
        answer.group = GROUP_ID;
        answer.max = numbers[0];
        answer.min = numbers[0];
        answer.sum = 0;
        //计算所有可以在一次扫描中完成的计算
        for(i = 0; i < COUNT_NUMBERS; ++i){
            answer.max = numbers[i] > answer.max ? numbers[i] : answer.max;
            answer.min = numbers[i] < answer.min ? numbers[i] : answer.min;
            answer.sum += numbers[i];
        }
        answer.average = answer.sum / COUNT_NUMBERS;
        answer.median = getMid();
        //复用reportMsg作为向监听节点汇报的结构
        pAnswer = (AnswerPacket*)(call Packet.getPayload(&reportMsg, sizeof(AnswerPacket)));
        *pAnswer = answer;
        call Leds.led1Toggle();
        call AckInterface.requestAck(&reportMsg);
        call AMSend.send(RESULT_ID, &reportMsg, sizeof(AnswerPacket));
    }
    task void ReportTask(){
        ReportPacket *pReport = (ReportPacket*)(call Packet.getPayload(&reportMsg, sizeof(ReportPacket)));
        if(reportNumIdx > COUNT_NUMBERS){
            //reportNumIdx可以为2000，这个包对于辅助节点意味着收包过程的结束
            //进入扫尾阶段
            state = STATE_SWAPING;
            return;
        }
        while(reportNumIdx < COUNT_NUMBERS && CHECK_BMP(numBitmp,reportNumIdx)){
            ++reportNumIdx;
        }
        //printf("reporting number: %u\n", reportNumIdx);
        //printfflush();
        pReport->seq = reportNumIdx;
        reportNodeIdx = 0;  //开始向第一个节点发送消息

        call AckInterface.requestAck(&reportMsg);
        call AMSend.send(assistNodes[reportNodeIdx], &reportMsg, sizeof(ReportPacket));
    }
    //复用AMSend同时向辅助节点和监听节点发送消息
    event void AMSend.sendDone(message_t* msg, error_t err){
        bool acked = call AckInterface.wasAcked(&reportMsg);
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
                call AMSend.send(assistNodes[reportNodeIdx], &reportMsg, sizeof(AnswerPacket));
            }
        }
        else{
            //处于向listen节点发送包的状态
                call Leds.led1Toggle();
                call AckInterface.requestAck(&reportMsg);
                call AMSend.send(RESULT_ID, &reportMsg, sizeof(AnswerPacket));
        }
    }
    event message_t *Receive.receive(message_t *msg, void* payload, uint8_t len){
        //计算节点收到的包只会为numberPacket形式
        //注意以包中的seq作为索引时是从1开始进行索引的
        NumberPacket *pPkt = (NumberPacket*)payload;
        uint16_t source = call AMPacket.source(msg);
        int16_t seq = pPkt->seq - 1;
        bool flag;
        //防干扰
        if(!(source == LISTENER_ID || 
        source == assistNodes[0] ||
        source == assistNodes[1])){
            return msg;
        }
        if(state == STATE_LISTENING && source == LISTENER_ID){
            //如果收到的序列号小于expected，则说明第二次广播已经开始，状态跳转
            if(!firstReceived){
                firstReceived = TRUE;
                countLatest = seq;
            }
            if(seq < countLatest){
                state = STATE_REPORTING;
                if(totalLoss <= 0){
                        state = STATE_COMPUTING;
                        post ComputeTask();
                        return msg;
                }
                post ReportTask();
                return msg;
            }
            if(seq - countLatest){
                call Leds.led0Toggle();
            }
            totalLoss += seq - countLatest;
            countLatest = seq;
            ++countLatest;
            SET_BMP(numBitmp,seq);
            numbers[seq] = pPkt->number;
        }
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
        //在计算阶段drop掉所有的包
        return msg;
    }
    uint32_t getMid(){
        int16_t l = 0, r = COUNT_NUMBERS, p, i;
        uint32_t other;
        do {
            p = partition(numbers, l, r);
            if(p < 999){
                l = p + 1;
            }
            else if(p > 1000){
                r = p;
            }
            else{
                break;
            }
        } while(TRUE);
        if(p == 999){
            //找到索引为1000的值，实际是在右侧找到最小值
            other = numbers[1000];
            for(i = 1001; i < COUNT_NUMBERS; ++i){
                if(numbers[i] < other){
                    other = numbers[i];
                }
            }
        }
        else{
            //在左侧找最大值
            other = numbers[0];
            for(i = 1; i < 1000; ++i){
                if(numbers[i] > other){
                    other = numbers[i];
                }
            }
        }
        return (numbers[p] + other) / 2;
    }
    int16_t partition(uint32_t *arr, int16_t l, int16_t r){
            int16_t x = arr[r - 1];
            int16_t j = l, i = l, tmp;
            for(; i < r -1; ++i){
                if(arr[i] <= x){
                    tmp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = tmp;
                    ++j;
                }
            }
            tmp = arr[j];
            arr[j] = arr[r - 1];
            arr[r - 1] = tmp;
            return j;
    }
}