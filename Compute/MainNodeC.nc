#include "defs.h"
configuration MainNodeC {

}
implementation {
    components MainNodeP as App;
    components MainC;
    components ActiveMessageC;
    components new AMSenderC(COMM_PORT);
    components new AMReceiverC(COMM_PORT);
    components LedsC;
    App.Boot -> MainC;
    App.AMSend -> AMSenderC;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AckInterface -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.Receive -> AMReceiverC;
    App.Leds -> LedsC;
}