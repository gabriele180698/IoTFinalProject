
#ifndef RADIO_FOO_TO_LEDS_H
#define RADIO_FOO_TO_LEDS_H

typedef nx_struct fooMessage {
  nx_uint16_t nodeID;
	uint16_t prog_num;
	
} fooMessage_t; 

typedef nx_struct rcvMsg {
  
	uint16_t prog_num;
	nx_uint16_t counter;

} rcvMsg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif



















