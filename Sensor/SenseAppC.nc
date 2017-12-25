/*configuration SenseAppC
{}
implementation
{
	components MainC, LedsC, ActiveMessageC;
	components SenseC as Sensor;
	components new TimerMillic() as Timer0;
	components new SensirionSht11C() as Sht11;
	components new HamamatsuS1087ParC();
	components new AMSenderC(6);
	components new AMReceiverC(6);

	Sensor->MainC.Boot;
	Sensor.Leds->LedsC;
	Sensor.Timer0->Timer0;
	Sensor.RadioSend->AMSenderC;
	Sensor.RadioPacket->AMSenderC;
	Sensor.RadioAMPacket->AMSenderC;
	Sensor.RadioControl->ActiveMessageC;
	Sensor.RadioReceive->AMReceiverC;
	
	Sensor.TemRead->Sht11.Temperature;
	Sensor.HumRead->Sht11.Humidity;
	Sensor.LigRead->HamamatsuS1087ParC;
}*/