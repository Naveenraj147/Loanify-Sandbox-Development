public class OpportunityTriggerHandler {
  private boolean m_isExecuting = false;
    private integer batchSize = 0; 
    private List<Opportunity> newList;
    private List<Opportunity> oldList;
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;
    
    public OpportunityTriggerHandler (Boolean isExecuting, Integer size,  List<Opportunity> oldList, Map<Id, Opportunity> newMap, List<Opportunity> newList, Map<Id,Opportunity> oldMap){
        
        this.m_isExecuting = isExecuting;
        this.batchSize = size;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.oldList = oldList;
    }
    
    public void onBeforeInsert(){
        
        for (Opportunity opp : newList) {
            if (opp.Phone__c != null) {
                opp.Phone__c = ContactTriggerHelper.formatPhoneNumber(opp.Phone__c, '+1');
            }
            if (opp.Mobile__c != null) {
                opp.Mobile__c = ContactTriggerHelper.formatPhoneNumber(opp.Mobile__c, '+1');
            }
        }
        
    }
    
    
    public void onAfterInsert(){
        
    }
    
    public void onBeforeUpdate(){
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.Phone__c != null && opp.Phone__c != oldOpp.Phone__c) {
                opp.Phone__c = ContactTriggerHelper.formatPhoneNumber(opp.Phone__c, '+1');
            }
            if (opp.Mobile__c != null && opp.Mobile__c != oldOpp.Mobile__c) {
                opp.Mobile__c = ContactTriggerHelper.formatPhoneNumber(opp.Mobile__c, '+1');
            }
        }
    }
    
     public void onAfterUpdate(){
       
    }


    public void onBeforeDelete(){
        
    }
    
    public void onAfterDelete(){
        
    }
    
}