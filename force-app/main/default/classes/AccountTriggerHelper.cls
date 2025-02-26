public class AccountTriggerHelper {
    
    public void handlePendingRequestsInGarage(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        try{
            Id autoDealerRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer').getRecordTypeId();
            Set<Id> updatedaccountIds = new Set<Id>();
            
            Map<Id, List<String>>  dealerIdToDealerProsEmailMap = new Map<Id, List<String>> ();
            
            for(Account each:newMap.Values()){
                if(each.RecordTypeId == autoDealerRecordTypeId && each.Manager_Email__c != oldMap.get(each.Id).Manager_Email__c && oldMap.get(each.Id).Manager_Email__c == null) {
                    updatedaccountIds.add(each.Id);  
                }   
            }
            if(updatedaccountIds.size() > 0){
                List<Garage__c> garageList = [SELECT Id, Dealer_Email_Available__c FROM Garage__c WHERE Dealer__c =: updatedaccountIds AND Dealer_Email_Available__c = false ];
                for(Garage__c each:garageList){
                    each.Dealer_Email_Available__c = true;
                }
                if(garageList.size() > 0){
                    update garageList;
                }
                List<Portal_Message__c> pmList = [SELECT id, Is_Pending__c  FROM Portal_Message__c WHERE Garage__r.Dealer__c in :updatedaccountIds AND Portal_Type__c = 'Dealer' AND Is_Pending__c = true];
                for(Portal_Message__c each:pmList){
                    each.Is_Pending__c = false;
                }
                if(pmList.size() > 0){
                    update pmList;
                }
            }
        } 
        catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
    }
}