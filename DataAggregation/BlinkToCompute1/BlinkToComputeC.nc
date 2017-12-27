#include "BlinkToRadio.h"

configuration BlinkToComputeC {
}
implementation {
    components MainC;
    components LedsC;
    components BlinkToComputeP as App;
    components ActiveMessageC;
    components new AMReceiverC(AM_BLINKTORADIO);

    App.Boot -> MainC;
    App.Leds -> LedsC;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.Receive -> AMReceiverC;
}