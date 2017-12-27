#define NEW_PRINTF_SEMANTICS
#include "printf.h"


#define DEST_NODE_ID 300
configuration MoteC {
}
implementation {
    components MainC,PrintfC, SerialStartC;
    components ActiveMessageC;
    components MoteP as app;
    components new DataTransferC(DEST_NODE_ID);
    components CommandMoteC;
    components SenseC;
    components LedsC;

    app.Boot -> MainC;
    app.AMControl -> ActiveMessageC;
    app.cmdReceiver -> CommandMoteC;
    app.dataSender -> DataTransferC;
    app.sense -> SenseC;
    app.Leds -> LedsC;
}