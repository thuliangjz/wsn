#include "DataTransferProtocol.h"
generic configuration DataTransferC(uint16_t dest){
    provides interface DataTransferInterface;
}
implementation {
    components new DataTransferP(dest);
    components new AMSenderC(PORT_SENSOR_DATA);
    components new AMReceiverC(PORT_SENSOR_DATA);
    components LedsC;

    DataTransferInterface = DataTransferP.Transmitter;
    DataTransferP.AMSend -> AMSenderC;
    DataTransferP.AMPacket -> AMSenderC;
    DataTransferP.Packet -> AMSenderC;
    DataTransferP.Ack -> AMSenderC; 
    DataTransferP.Receive -> AMReceiverC;
    DataTransferP.Leds -> LedsC;
}