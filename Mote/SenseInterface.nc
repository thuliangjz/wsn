#include "DataTransferProtocol.h"
interface SenseInterface {
    //可以通过调用该命令来启动传感器的时钟
    command error_t setSenseInterval(uint32_t interval);
    event void senseDone(SensorData data);
}