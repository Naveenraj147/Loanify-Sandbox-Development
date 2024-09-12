trigger AccountTrigger on Account (after update, after insert, after delete, before insert, before update, before delete) {
    
    AccountTriggerHandler  handler = new AccountTriggerHandler(Trigger.isExecuting, Trigger.size, Trigger.old, Trigger.newMap, Trigger.new,  Trigger.oldMap);
    
    if(trigger.isBefore){
        
        if (trigger.isInsert){        
            handler.onBeforeInsert();
            
        } else if (trigger.isUpdate){
            handler.onBeforeUpdate();   
            
        } else if (trigger.isDelete){
            handler.onBeforeDelete();            
        }       
        
    }    
    
    else if(trigger.isAfter){
        
        if (trigger.isInsert){        
            handler.onAfterInsert();
            
        } else if (trigger.isUpdate){
            if(AvoidUpdates.runOnce()){
                
                handler.onAfterUpdate();     
            }
        } else if (trigger.isDelete){
            handler.onAfterDelete();         
        }   
    }  
    
}