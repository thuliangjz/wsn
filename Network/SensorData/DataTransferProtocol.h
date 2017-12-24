#ifndef DATA_TRANSFER_PROTOCOL
#define DATA_TRANSFER_PROTOCOL
#define QUE_SIZE 12
#define PORT_SENSOR_DATA 0x21
#define MAGIC_SENSOR_DATA 0x7e9b
typedef nx_struct {
    uint16_t seq;
    uint16_t humidity;
    uint16_t light;
    uint16_t temperature;
}SensorData;
typedef nx_struct {
    uint16_t magic;
    SensorData data;
}DataPacket;
#endif