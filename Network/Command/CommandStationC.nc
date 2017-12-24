#include "CommandProtocol.h"
configuration CommandStationC {
   provides {
        interface CommandStationInterface as cmdSender;
    }
}
implementation {
    components new AMSenderC(COMMAND_PORT);
    components CommandStationP as Station;
    Station.Packet -> AMSenderC;
    Station.AMSend -> AMSenderC;
    Station.AckInterface -> AMSenderC;
    //接口转移
    cmdSender = Station.Station;
}