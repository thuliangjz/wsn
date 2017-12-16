#include "MessageFormat.h"

module SenseC
{
	uses interface Leds;
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface SplitControl as RadioControl;
	uses interface Packet as RadioPacket;
	uses interface AMSend as RadioSend;
	uses interface Receive as RadioReceive;

	uses interface Read<uint16_t> as TemRead;
	uses interface Read<uint16_t> as HumRead;
	uses interface Read<uint16_t> as LigRead;
}
implementation {
	bool busy = FALSE;
	bool temdone = FALSE;
	message_t pkt;
	uint16_t temperature;
	uint16_t humidity;
	uint16_t timer_period = 100;
	uint16_t SHT_sequence = 1;
	uint16_t Lig_sequence = 1;

	event void Boot.booted() 
	{
		call RadioControl.start();
	}

	event RadioControl.startDone(error_t err)
	{
		if (err == SUCCESS) {
			call Timer0.startPeriodic(timer_period);
		}
		else {
			call RadioControl.start();
		}
	}

	event RadioControl.stopDone(error_t err)
	{

	}

	event void Timer0.fired() 
	{
		call LigRead.read();
		call TemRead.read();
		call HumRead.read();
	}

	event void TemRead.readDone(error_t result, uint16_t data)
	{
		if (result == SUCCESS) {
			call Leds.led1Toggle();
			temperature = data;
			temdone = TRUE;
		}
	}

	event void HumRead.readDone(error_t result, uint16_t data)
	{
		if (result == SUCCESS) {
			call Leds.led1Toggle();
			humidity = data;
			if (!busy && temdone) {
				SHTMsg *btrpkt = (SHTMsg*)(call RadioPacket.getPayload(&pkt, sizeof(SHTMsg)));
				btrpkt->nodeid = TOS_NODE_ID;
				btrpkt->type = 0x01;
				btrpkt->temperature = temperature;
				btrpkt->humidity = humidity;
				btrpkt->sequence = SHT_sequence;
				btrpkt->recordingTime = Timer0.getNow();
				SHT_sequence = SHT_sequence + 1;
				temdone = FALSE;
				if (call RadioSend.send(0, &pkt, sizeof(SHTMsg)) == SUCCESS) {
					busy = TRUE;
				}
			}
		}
	}

	event void LigRead.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			call Leds.led2Toggle();
			if (!busy) {
				LigMsg *btrpkt = (LigMsg*)(call RadioPacket.getPayload(&pkt, sizeof(LigMsg)));
				btrpkt->nodeid = TOS_NODE_ID;
				btrpkt->type = 0x02;
				btrpkt->light = data;
				btrpkt->sequence = Lig_sequence;
				btrpkt->recordingTime = Timer0.getNow();
				Lig_sequence = Lig_sequence + 1;
				if (call RadioSend.send(0, &pkt, sizeof(LigMsg)) == SUCCESS) {
					busy = TRUE;
				}
			}
		}
	}

	event void RadioSend.sendDone(message_t *msg, error_t error) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event message_t* RadioReceive.receive(message_t *msg, void *payload, uint8_t len) {
		if (len == sizeof(ModifyMsg)) {
			ModifyMsg *btrpkt = (ModifyMsg*)payload;
			timer_period = btrpkt->new_period;
		}
		return msg;
	}
}