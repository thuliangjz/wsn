#include "defs.h"
configuration AssistNodeC {

}
implementation {
    components AssistNodeP as App;
    components MainC;
    components ActiveMessageC;
    components new AMSenderC(COMM_PORT);
    components new AMReceiverC(COMM_PORT);
    components LedsC;
    App.Boot -> MainC;
    App.AMPacket -> AMSenderC;
    App.AMSend -> AMSenderC;
    App.Packet -> AMSenderC;
    App.AckInterface -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.Receive -> AMReceiverC;
    App.Leds -> LedsC;
}