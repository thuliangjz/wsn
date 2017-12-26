#define DEST_NODE_ID 300
configuration MoteC {
}
implementation {
    components MainC, ActiveMessageC;
    components MoteP as app;
    components new DataTransferC(DEST_NODE_ID);
    components CommandMoteC;
    components SenseC;

    app.Boot -> MainC;
    app.AMControl -> ActiveMessageC;
    app.cmdReceiver -> CommandMoteC;
    app.dataSender -> DataTransferC;
    app.sense -> SenseC;
}