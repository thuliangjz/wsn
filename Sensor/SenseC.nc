configuration SenseC {
	provides interface SenseInterface;
}
implementation {
	components SenseP;
	components new TimerMilliC() as Timer;
	components new SensirionSht11C() as Sht11;
	components new HamamatsuS1087ParC();

	SenseP.Timer -> Timer;
	SenseP.TemRead->Sht11.Temperature;
	SenseP.HumRead->Sht11.Humidity;
	SenseP.LigRead->HamamatsuS1087ParC;
	SenseInterface = SenseP.SenseInterface;
}