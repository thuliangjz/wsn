#ifndef MASSAGE_FORMAT_H
#define MASSAGE_FORMAT_H

typedef nx_struct SHTMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t type;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t sequence;
	nx_uint32_t recordingTime;
}SHTMsg;

typedef nx_struct LigMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t type;
	nx_uint16_t light;
	nx_uint16_t sequence;
	nx_uint32_t recordingTime;
}LigMsg;

typedef nx_struct ModifyMsg
{
	nx_uint16_t nodeid;
	nx_uint16_t new_period;
}ModifyMsg;

#endif