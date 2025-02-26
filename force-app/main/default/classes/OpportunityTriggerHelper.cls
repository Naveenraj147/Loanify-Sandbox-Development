public class OpportunityTriggerHelper {
    public static void sendSMSAndEmail(List<Opportunity> newOppList, Map<Id, Opportunity> oldMap){
    
        List<tdc_tsw__Message_Template__c> smsTempList = [SELECT Id, Name FROM tdc_tsw__Message_Template__c WHERE Name = 'CU Member Pre-Time/Date Notification' LIMIT 1];
        tdc_tsw__Message_Template__c smsTemplate = smsTempList.size() > 0 ? smsTempList[0] : null ;
        set<Id> msrUpdatedOppIds = new Set<Id>();
        set<Id> msrUpdatedBranchIds = new Set<Id>();
        
        for(Opportunity eachOpp : newOppList){
            if((eachOpp.Mobile__c != null || eachOpp.Phone__c != null) && smsTemplate != null){
                String smsField = eachOpp.Mobile__c != null? 'Mobile__c' : 'Phone__c';
                if(oldMap == null){
                    tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId(smsField, smsTemplate.Id, eachOpp.Id);
                }
                else if((eachOpp.Phone__c == null && eachOpp.Mobile__c != null && oldMap.get(eachOpp.Id).Mobile__c == null) || (eachOpp.Mobile__c == null && eachOpp.Phone__c != null && oldMap.get(eachOpp.Id).Phone__c == null) ){
                    tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId(smsField, smsTemplate.Id, eachOpp.Id);
                }
            }
            if(eachOpp.Bank_Service_Rep_Name_MSR__c != null && oldMap.get(eachOpp.Id).Bank_Service_Rep_Name_MSR__c == null && eachOpp.Download_Stamp__c != null ){
                msrUpdatedOppIds.add(eachOpp.Id);
                msrUpdatedBranchIds.add(eachOpp.Branch__c);
            } 
        }
        if(msrUpdatedBranchIds.size() > 0){
           List<Contact> conList =  [SELECT Id, Account.ParentId FROM Contacts WHERE Account.ParentId IN:msrUpdatedBranchIds AND Primary_Contact = true];
            
            // List<Opportunity> oppList = [SELECT Id, Branch__c, Branch__r.ParentId FROM Opportunity WHERE Id =:msrUpdatedOppIds];
        }
    }

}