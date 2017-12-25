#ifndef DATA_TRANSFER_PROTOCOL
#define DATA_TRANSFER_PROTOCOL
#define QUE_SIZE 12
#define PORT_SENSOR_DATA 0x21
#define MAGIC_SENSOR_DATA 0x7e9b
typedef nx_struct {
    nx_uint16_t id;
    nx_uint16_t seq;
    nx_uint16_t humidity;
    nx_uint16_t light;
    nx_uint16_t temperature;
    nx_uint32_t timestamp;
}SensorData;
typedef nx_struct {
    nx_uint16_t magic;
    SensorData data;
}DataPacket;
#endif