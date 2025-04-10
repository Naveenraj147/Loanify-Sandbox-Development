trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert)
            AccountContactRelationTriggerHandler.onAfterInsert(Trigger.new);
        if(trigger.isUpdate)
            AccountContactRelationTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }

}