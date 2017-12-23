#include "CommandProtocol.h"
interface CommandStationInterface {
    command error_t sendCommand(Command cmd);
    event void commandSendDone();
}