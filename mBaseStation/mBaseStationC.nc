#define NEW_PRINTF_SEMANTICS
#include "printf.h"
configuration mBaseStationC {
}
implementation {
  components MainC, mBaseStationP, LedsC;
  components PrintfC, SerialStartC;
  components CommandStationC as RadioSender;
  components new DataTransferC(10000) as RadioReceiver;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new AMSenderC(0x30);
  
   mBaseStationP -> MainC.Boot;

  mBaseStationP.RadioControl -> Radio;
  mBaseStationP.SerialControl -> Serial;
  
  mBaseStationP.UartSend -> Serial.AMSend;
  mBaseStationP.UartReceive -> Serial.Receive;
  mBaseStationP.UartAMPacket -> Serial;
  mBaseStationP.UartPacket -> Serial;
  
  mBaseStationP.RadioSend -> RadioSender.cmdSender;
  mBaseStationP.RadioReceive -> RadioReceiver.DataTransferInterface;
  mBaseStationP.RadioPacket -> Radio.Packet;
  mBaseStationP.RadioAMPacket -> Radio.AMPacket;

  mBaseStationP.TestSend -> AMSenderC;
  
  mBaseStationP.Leds -> LedsC;
}
