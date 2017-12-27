#include "CommandProtocol.h"
configuration CommandMoteC {
    provides interface CommandMoteInterface;   
}
implementation {
    components CommandMoteP as mote;
    components new AMSenderC(COMMAND_PORT);
    components new AMReceiverC(COMMAND_PORT);


    CommandMoteInterface = mote.CommandMoteInterface;
    mote.Receive -> AMReceiverC;
    mote.Packet -> AMSenderC;
    mote.AMSend -> AMSenderC;
}