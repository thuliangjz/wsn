#include "DataTransferProtocol.h"
interface DataTransferInterface {
    command error_t sendData(SensorData data);
    event void dataReceived(SensorData data);
}