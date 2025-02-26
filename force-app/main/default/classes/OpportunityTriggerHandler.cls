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
        OpportunityTriggerHelper.sendSMSAndEmail(newList, null);
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
        OpportunityTriggerHelper.sendSMSAndEmail(newList, oldMap);
        Set<Id> updatedOppIds = new Set<Id>();
        Set<Id> updatedAccIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.Branch__c != null && opp.Branch__c != oldOpp.Branch__c) {
                updatedOppIds.add(opp.id);
                updatedAccIds.add(opp.Branch__c);
            }
        }
    
        if(updatedAccIds.size() > 0){
            List<Contact> conList = [SELECT id, AccountId FROM Contact WHERE AccountId in :updatedAccIds];
            if(conList.size() > 0){
                for(Contact each : conList){
                    accIds.add(each.AccountId);
                }
            }
        }
        if(updatedOppIds.size() > 0){
            List<Portal_Message__c> pmList = [SELECT id, Opportunity__c, Is_Pending__c, Opportunity__r.Branch__c   FROM Portal_Message__c 
                                                WHERE Opportunity__c in :updatedOppIds AND Opportunity__r.Branch__c in :accIds AND Portal_Type__c = 'MSR' AND Is_Pending__c = true];
            if(pmList.size() > 0){
                for(Portal_Message__c each : pmList){
                    each.Is_Pending__c = false;
                }
                update pmList;

            }
        }
       
    }


    public void onBeforeDelete(){
        
    }
    
    public void onAfterDelete(){
        
    }
    
}