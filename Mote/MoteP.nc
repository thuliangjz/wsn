#include "CommandProtocol.h"
#include "DataTransferProtocol.h"

#define SENSE_TIME_DEFAULT 1000

module MoteP {
    uses {
        interface CommandMoteInterface as cmdReceiver;
        interface DataTransferInterface as dataSender;
        interface SenseInterface as sense;
        interface Boot;
        interface SplitControl as AMControl;
    }
}
implementation {
    event void Boot.booted(){
        call AMControl.start();
    }
    event void AMControl.startDone(error_t err){
        if(err == SUCCESS){
            call sense.setSenseInterval(SENSE_TIME_DEFAULT);
        }
    }
    event void AMControl.stopDone(error_t err){
    }
    event void sense.senseDone(SensorData data){
        call dataSender.sendData(data);        
    }
    //针对中转节点设置转发函数
    event void dataSender.dataReceived(SensorData data){
        call dataSender.sendData(data);
    }
    event void cmdReceiver.newCommand(Command cmd){
        call sense.setSenseInterval(cmd.time);
    }
}