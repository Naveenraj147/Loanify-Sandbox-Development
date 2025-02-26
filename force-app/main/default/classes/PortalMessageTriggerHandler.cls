public class PortalMessageTriggerHandler {

    // After Insert Handler
    public static void afterInsert(List<Portal_Message__c> newPortalMessage) {
        System.debug('Inside PortalMessageTriggerHandler afterInsert');
        PortalMessageTriggerHelper.updatePortalMessage(newPortalMessage);
    }
    public static void afterUpdate(List<Portal_Message__c> newPortalMessages, Map<Id, Portal_Message__c> oldPortalMessageMap) {
        System.debug('Inside PortalMessageTriggerHandler afterInsert');
        List<Portal_Message__c> updatedPending = new List<Portal_Message__c>();
        for(Portal_Message__c portalMessage :newPortalMessages){
            if(portalMessage.Is_Pending__c != true && portalMessage.Is_Pending__c != oldPortalMessageMap.get(portalMessage.Id).Is_Pending__c){
                updatedPending.add(portalMessage);
            }
        }   
        if(updatedPending.size() > 0){
            PortalMessageTriggerHelper.updatePortalMessage(updatedPending);
        }
        
    }
}