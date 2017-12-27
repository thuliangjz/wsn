#include "AM.h"
#include "Serial.h"
#include "CommandProtocol.h"
#include "DataTransferProtocol.h"
#include "msgDefine.h"
#include "printf.h"

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

    interface AMSend as TestSend;

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
    //call Leds.led2Toggle();
  }

  void failBlink() {
    //call Leds.led2Toggle();
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
     /*
      printf("id: %u, seq:%u, hum:%u, light:%u tem:%u, time:%u\n",
      data.id,
      data.seq, 
      data.humidity,
      data.light,
      data.temperature,
      data.timestamp);
      */
      atomic {
      if (!uartFull){
        SensorData* sensorPkt = (SensorData*)(call RadioPacket.getPayload(&uartQueueBufs[uartIn], sizeof(SensorData)));
        sensorPkt->id = data.id;
        sensorPkt->seq = data.seq;
        sensorPkt->humidity = data.humidity;
        sensorPkt->light = data.light;
        sensorPkt->temperature = data.temperature;
        sensorPkt->timestamp = data.timestamp;
        uartIn = (uartIn + 1) % UART_QUEUE_LEN;

        //call Leds.led2Toggle();
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

  
  task void uartSendTask() {
    atomic
      if (uartIn == uartOut && !uartFull) {
        uartBusy = FALSE;
        return;
	    }

    if (call UartSend.send[0x30](AM_BROADCAST_ADDR, uartQueue[uartOut], sizeof(SensorData)) == SUCCESS)
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
      atomic {
        uartOut = (uartOut + 1) % UART_QUEUE_LEN;
        uartFull = FALSE;
      }
    post uartSendTask();
  }

  event message_t *UartReceive.receive[am_id_t id](message_t *msg, void *payload, uint8_t len) {
    call Leds.led0Toggle();
    atomic
      if (!radioFull) {
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
    
    return msg;
  }

  task void radioSendTask() {
    Command cmd;
    Command* cmdPkt;
    
    atomic {
      if (radioIn == radioOut && !radioFull) {
	      radioBusy = FALSE;
	      return;
	    }
    }

    cmdPkt = (Command*)(call UartPacket.getPayload(radioQueue[radioOut], sizeof(Command)));
    cmd.time = cmdPkt->time;
    
    // if (call RadioSend.sendCommand(cmd) == SUCCESS){
    //   call Leds.led0Toggle();
    // }
    // else {
	  //   failBlink();
	  //   post radioSendTask();
    // }

    if ((call TestSend.send(AM_BROADCAST_ADDR, radioQueue[radioOut], sizeof(Command))) == SUCCESS) {
      call Leds.led0Toggle();
    } else {
      failBlink();
      post radioSendTask();
    }
  }

  event void TestSend.sendDone(message_t *msg, error_t error) {
    if (++radioOut >= RADIO_QUEUE_LEN)
      radioOut = 0;
    if (radioFull)
      radioFull = FALSE;
  
    post radioSendTask();
  }

  event void RadioSend.commandSendDone() {
    if (++radioOut >= RADIO_QUEUE_LEN)
      radioOut = 0;
    if (radioFull)
      radioFull = FALSE;
  
    post radioSendTask();
  }
}  
