trigger VoiceCallTrigger on VoiceCall (before insert, before update) {
    
    VoiceCallTriggerHandler handler = new VoiceCallTriggerHandler();
    if(trigger.isBefore){
        
        if (trigger.isInsert){        
           
            
        }
        else if (trigger.isUpdate){
            handler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);   
            
        }     
        
    }    
}