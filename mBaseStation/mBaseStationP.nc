#include "AM.h"
#include "Serial.h"
#include "CommandProtocol.h"
#include "DataTransferProtocol.h"
#include "msgDefine.h"

module mBaseStationP @safe() {
  uses {
    interface Boot;
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;

    interface AMSend as UartSend[am_id_t id];
    interface Receive as UartReceive[am_id_t id];
    interface Packet as UartPacket;
    interface AMPacket as UartAMPacket;

    interface CommandStationInterface as RadioSend;
    interface DataTransferInterface as RadioReceive;
    interface Packet as RadioPacket;
    interface AMPacket as RadioAMPacket;

    interface Leds;
  }
}

implementation
{
  enum {
    UART_QUEUE_LEN = 12,
    RADIO_QUEUE_LEN = 12,
  };

  message_t  uartQueueBufs[UART_QUEUE_LEN];
  message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN];
  uint8_t    uartIn, uartOut;
  bool       uartBusy, uartFull;

  message_t  radioQueueBufs[RADIO_QUEUE_LEN];
  message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
  uint8_t    radioIn, radioOut;
  bool       radioBusy, radioFull;

  task void uartSendTask();
  task void radioSendTask();

  void dropBlink() {
    call Leds.led2Toggle();
  }

  void failBlink() {
    call Leds.led2Toggle();
  }

  event void Boot.booted() {
    uint8_t i;

    for (i = 0; i < UART_QUEUE_LEN; i++)
      uartQueue[i] = &uartQueueBufs[i];
    uartIn = uartOut = 0;
    uartBusy = FALSE;
    uartFull = TRUE;

    for (i = 0; i < RADIO_QUEUE_LEN; i++)
      radioQueue[i] = &radioQueueBufs[i];
    radioIn = radioOut = 0;
    radioBusy = FALSE;
    radioFull = TRUE;

    call RadioControl.start();
    call SerialControl.start();
  }

  event void RadioControl.startDone(error_t error) {
    if (error == SUCCESS) {
      radioFull = FALSE;
    }
  }

  event void SerialControl.startDone(error_t error) {
    if (error == SUCCESS) {
      uartFull = FALSE;
    }
  }

  event void SerialControl.stopDone(error_t error) {}
  event void RadioControl.stopDone(error_t error) {}

  uint8_t count = 0;

  event void RadioReceive.dataReceived(SensorData data) {
    atomic {
      if (!uartFull){
        SensorData* sensorPkt = (SensorData*)(call RadioPacket.getPayload(&uartQueueBufs[uartIn], sizeof(SensorData)));
        sensorPkt->seq = data.seq;
        sensorPkt->humidity = data.humidity;
        sensorPkt->light = data.light;
        sensorPkt->temperature = data.temperature;
        uartIn = (uartIn + 1) % UART_QUEUE_LEN;
      
        if (uartIn == uartOut)
          uartFull = TRUE;

        if (!uartBusy){
          post uartSendTask();
          uartBusy = TRUE;
        }
	    } else
	      dropBlink();
    }
  }

  uint8_t tmpLen;
  
  task void uartSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr, src;
    message_t* msg;
    atomic
      if (uartIn == uartOut && !uartFull) {
        uartBusy = FALSE;
        return;
	    }

    msg = uartQueue[uartOut];
    tmpLen = len = call RadioPacket.payloadLength(msg);
    id = call RadioAMPacket.type(msg);
    addr = call RadioAMPacket.destination(msg);
    src = call RadioAMPacket.source(msg);
    call UartPacket.clear(msg);
    call UartAMPacket.setSource(msg, src);

    if (call UartSend.send[id](addr, uartQueue[uartOut], len) == SUCCESS)
      call Leds.led1Toggle();
    else {
      failBlink();
      post uartSendTask();
    }
  }

  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	  if (msg == uartQueue[uartOut]){
	    if (++uartOut >= UART_QUEUE_LEN)
	      uartOut = 0;
	    if (uartFull)
	      uartFull = FALSE;
	  }
    post uartSendTask();
  }

  event message_t *UartReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
    message_t *ret = msg;
    bool reflectToken = FALSE;

    atomic
      if (!radioFull) {
        reflectToken = TRUE;
        ret = radioQueue[radioIn];
        radioQueue[radioIn] = msg;
        if (++radioIn >= RADIO_QUEUE_LEN)
          radioIn = 0;
        if (radioIn == radioOut)
          radioFull = TRUE;

        if (!radioBusy) {
          radioBusy = TRUE;
          post radioSendTask();
        }
	    } else
	      dropBlink();

    if (reflectToken) {
      //call UartTokenReceive.ReflectToken(Token);
    }
    
    return ret;
  }

  task void radioSendTask() {
    Command cmd;
    ModifyMsg* modifyPkt;
    
    atomic {
      if (radioIn == radioOut && !radioFull) {
	      radioBusy = FALSE;
	      return;
	    }
    }

    modifyPkt = (ModifyMsg*)(call UartPacket.getPayload(&radioQueue[radioOut], sizeof(ModifyMsg)));
    cmd.time = modifyPkt->new_period;
    
    if (call RadioSend.sendCommand(cmd) == SUCCESS)
      call Leds.led0Toggle();
    else {
	    failBlink();
	    post radioSendTask();
    }
  }

  event void RadioSend.commandSendDone() {
    if (++radioOut >= RADIO_QUEUE_LEN)
      radioOut = 0;
    if (radioFull)
      radioFull = FALSE;
  
    post radioSendTask();
  }
}  
