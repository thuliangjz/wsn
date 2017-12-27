#include "defs.h"

#define STATE_LISTENING 0
#define STATE_SERVING 1

module AssistNodeP {
    uses {
        interface Packet;
        interface AMSend;
        interface Receive;
        interface SplitControl as AMControl;
        interface Boot;
    }
}
implementation {
    uint32_t numbers[COUNT_NUMBERS];
    uint8_t bmpRemoteLoss[COUNT_NUMBERS/8] = {0};
    uint8_t bmpLocal[COUNT_NUMBERS/8] = {0};
    int16_t remoteLossCount = 0;
    event void Boot.booted(){
        call AMControl.start();
    }
    event void AMControl.startDone(error_t err){}
    event void AMControl.stopDone(error_t err){}
    event message_t *Receive.receive(message_t *msg, void* payload, uint8_t len){
        
    }
}