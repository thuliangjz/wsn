configuration mBaseStationC {
}
implementation {
  components MainC, mBaseStationP, LedsC;
  components CommandStationC as RadioSender;
  components new DataTransferC(0) as RadioReceiver;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  
   mBaseStationP -> MainC.Boot;

  mBaseStationP.RadioControl -> Radio;
  mBaseStationP.SerialControl -> Serial;
  
  mBaseStationP.UartSend -> Serial;
  mBaseStationP.UartReceive -> Serial.Receive;
  mBaseStationP.UartPacket -> Serial;
  mBaseStationP.UartAMPacket -> Serial;
  
  mBaseStationP.RadioSend -> RadioSender.cmdSender;
  mBaseStationP.RadioReceive -> RadioReceiver.DataTransferInterface;
  mBaseStationP.RadioPacket -> Radio.Packet;
  mBaseStationP.RadioAMPacket -> Radio.AMPacket;
  
  mBaseStationP.Leds -> LedsC;
}
