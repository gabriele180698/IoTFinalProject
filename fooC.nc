#include "Timer.h"
#include "foo.h"
#include "printf.h"

#define	NUM_MOTES	5

module fooC @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as Timer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}

implementation {

  message_t packet;
  //+++++++++++++++++++++++++++++++++++++++++
  //+++DA CAMBIARE le variabili dichiarate+++
  //+++++++++++++++++++++++++++++++++++++++++
  bool locked;
  
  // array di struct per gestire i messaggi
	rcvMsg_t nodeArray[NUM_MOTES];	
	// initialization
	uint16_t c = 0;
  
  // questo e' il numero progressivo utile per contare i messaggi consecutivi
  uint16_t this_prog_num = 0;
    
  //***************** Boot interface ********************//
  event void Boot.booted() {
    call AMControl.start(); // start the radio  	
		
		while (c < NUM_MOTES) {
			nodeArray[c] -> counter = 0;	
			nodeArray[c] -> prog_num = -1;	

			c++;
		}  


  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	call MilliTimer.startPeriodic(500); // peridoicity of 500ms	
		}
    
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  // do nothing
	  if (err != SUCCESS) {
			call SplitControl.stop();
		}
    
  }
  
  //***************** MilliTimer interface ********************//
  event void Timer.fired() {
  
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
    	Noi dobbiamo ricevere il messaggio, leggere l'ID del mote che lo ha inviato e usarlo come
    	indice per la struttura dati, a questo punto controllo se il numero progressivo
    	che è arrivato legato al messaggio è progressivo a quello che avevamo ricevuto 
    	e finalmente possiamo aggiornare il contatore nell'array delle strutture.     
    */
    
    if (len != sizeof(fooMessage_t)) {return bufPtr;}
    
    else {
      fooMessage_t* rcm = (fooMessage_t*)payload;
			
			uint16_t check_p = arrayNode[(rcm -> nodeID) - 1] -> prog_num;
  		
  		if((check_p + 1) == (rcm -> prog_num)) {
  			// so, they are consecutive messages
  			(arrayNode[(rcm -> nodeID) - 1] -> counter) ++; 
  			if((arrayNode[(rcm -> nodeID) - 1] -> counter) == 10) {
  				printf("My nodeID: %d; His nodeID: %d", TOS_NODE_ID, rcm -> nodeID);		
  				
  			}
  			
  		} else {
  			// so, they are not consecutive messages
  			arrayNode[(rcm -> nodeID) - 1] -> counter = 0; 
  			
  		}
  		
  		arrayNode[(rcm -> nodeID) - 1] -> prog_num = (rcm -> prog_num);
  			
      
      
    //  printf("Sender NodeID: %d, CounterMsg: %d, Mote status: %d%d%d\n", rcm -> nodeID, rcm -> counter, mask[2], mask[1], mask[0]);
	  
      
      return bufPtr;
    }
    
    
  }


}
