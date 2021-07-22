#include "Timer.h"
#include "foo.h"
#include "printf.h"

#define	NUM_MOTES	5

module fooC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}

implementation {

  message_t packet;
  bool locked;
  
  // array of struct to handle the msges
	rcvMsg_t nodeArray[NUM_MOTES];	
	// initialization
	uint16_t c = 0;
  
  // progressive number of the own mote 
  uint16_t this_prog_num = 0;
    
  //***************** Boot interface ********************//
  event void Boot.booted() {
    call AMControl.start(); // start the radio  	
		
		while (c < NUM_MOTES) {
			nodeArray[c].counter = 0;	
			nodeArray[c].prog_num = -1;	

			c++;
		}  


  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call MilliTimer.startPeriodic(500); // peridoicity of 500ms	
		} else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  // do nothing
	  if (err != SUCCESS) {
			call AMControl.stop();
		}
    
  }
  
  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
  
    if (locked) {
      return;
    } else {
		fooMessage_t* rcm = (fooMessage_t*)call Packet.getPayload(&packet, sizeof(fooMessage_t));
    	if (rcm == NULL) {
			return;
		}
		
		rcm->nodeID = TOS_NODE_ID; // we enter the struct to set the nodeID
		rcm->prog_num = this_prog_num; // we enter the struct to bind the progressive counter with the msg 
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(fooMessage_t)) == SUCCESS) {
			locked = TRUE;
      	}
    }

		this_prog_num++; // here increase the progressive number for the messages    
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE; // unlock the radio
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
  
    /*
    	The logic of this function is the most importnt. Every mote handle this way the msg
    	that it receive. 
    */
    
    if (len != sizeof(fooMessage_t)) {
    	return bufPtr;
    }
    
    else {
    	
      fooMessage_t* rcm = (fooMessage_t*)payload;
			uint16_t check_p = nodeArray[(rcm -> nodeID) - 1].prog_num;
  		
  		// Check of the progressive number in order to count properly the progressive numbers
  		if((check_p + 1) == (rcm -> prog_num)) {
  			// they are consecutive messages
  			(nodeArray[(rcm -> nodeID) - 1].counter) ++; 
  
  			if((nodeArray[(rcm -> nodeID) - 1].counter) == 10) {
  				
  				printf("This is a proximity alarm message, I want to notify you that somebody is too close to you, that's not safe. Get the distance &%d&%d&!\n", TOS_NODE_ID, rcm -> nodeID);		
  				
  			}
  			
  		} else {
  			// they are not consecutive messages
  			nodeArray[(rcm -> nodeID) - 1].counter = 0; 
  			
  		}
  		
  		nodeArray[(rcm -> nodeID) - 1].prog_num = (rcm -> prog_num);  
      
      return bufPtr;
    }
    
    
  }

}
