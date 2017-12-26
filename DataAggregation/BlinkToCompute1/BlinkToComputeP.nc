#include "BlinkToCompute.h"
#include "printf.h"

module BlinkToComputeP {
    uses interface Boot;
    uses interface Leds;
    uses interface Packet;
    uses interface AMPacket;
    uses interface Receive;
    uses interface SplitControl as AMControl;
}
implementation {
    uint16_t counter;
    message_t pkt;
    uint32_t min;
    uint32_t max;
    uint32_t data[2000];
    
    bool busy = FALSE;

    event void Boot.booted() {
        call AMControl.start();
        counter = 0;
    }

    event void AMControl.startDone(error_t err) {
        if (err != SUCCESS) {
            call AMControl.start();
        }
    }

    event void AMControl.stopDone(error_t err) {
    }
    
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        if (len == sizeof(BlinkToRadioMsg)) {
            BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
            
        }
    }
}