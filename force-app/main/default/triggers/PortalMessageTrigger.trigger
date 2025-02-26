trigger PortalMessageTrigger on Portal_Message__c (after insert, after update) {
    System.debug('Inside PortalMessageTrigger');
    if(Trigger.isAfter) {
        System.debug('Inside PortalMessageTrigger isAfter');
        if(Trigger.isInsert) {
            System.debug('Inside PortalMessageTrigger isAfter isInsert');
            PortalMessageTriggerHandler.afterInsert(Trigger.new);
        }
        else if(Trigger.isUpdate) {
            PortalMessageTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}