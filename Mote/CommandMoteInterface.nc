#include "CommandProtocol.h"
interface CommandMoteInterface {
    event void newCommand(Command cmd);
}