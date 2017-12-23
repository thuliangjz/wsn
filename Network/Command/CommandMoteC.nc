#include "CommandProtocol.h"
configuration CommandMoteC {
    provides interface CommandMoteInterface;   
}
implementation {
    components CommandMoteP as mote;
    components new AMSenderC(COMMAND_PORT);
    components new AMReceiverC(COMMAND_PORT);

    //测试用
    components LedsC;

    CommandMoteInterface = mote.CommandMoteInterface;
    mote.Receive -> AMReceiverC;
    mote.AMSend -> AMSenderC;
    mote.Packet -> AMSenderC;
    mote.AMPacket -> AMSenderC;
    mote.Leds -> LedsC;
}