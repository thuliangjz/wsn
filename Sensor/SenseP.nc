#include "DataTransferProtocol.h"
module SenseP {
    provides interface SenseInterface;

	uses interface Read<uint16_t> as TemRead;
	uses interface Read<uint16_t> as HumRead;
	uses interface Read<uint16_t> as LigRead;
    uses interface Timer<TMilli>;
}
implementation {
    SensorData sensorDataBuf;
    uint16_t seq = 0;
    bool reading = FALSE;
    command error_t SenseInterface.setSenseInterval(uint32_t interval){
        Timer.startPeriodic(interval);
    }
    event void Timer.fired(){
        if(reading)
            return;
        reading = TRUE;
        call HumRead.read();
    }
	event void HumRead.readDone(error_t result, uint16_t data){
        sensorDataBuf.humidity = data;
        call TemRead.read();
    }
    event void TemRead.readDone(error_t result, uint16_t data){
        sensorDataBuf.temperature = data;
        call LigRead.read();
    }
    event void LigRead.readDone(error_t result, uint16_t data){
        sensorDataBuf.light = data;
        sensorDataBuf.id = TOS_NODE_ID;
        sensorDataBuf.seq = seq++;
        sensorDataBuf.timestamp = call Timer.getNow();
        signal SenseInterface.senseDone(sensorDataBuf);
        reading = FALSE;
    }
}