#include "CommandProtocol.h"
configuration CommandStationC {
   provides {
        interface CommandStationInterface as cmdSender;
    }
}
implementation {
    components new AMSenderC(COMMAND_PORT);
    components new AMReceiverC(COMMAND_PORT);
    components new TimerMilliC() as Timer;
    components CommandStationP as App;
    components MainC, PrintfC, SerialStartC;
    App.Timer -> Timer;
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
    App.Boot -> MainC; 
    //接口转移
    cmdSender = App.Station;
}