public class AccountTriggerHelper {
    
    public void handlePendingRequestsInGarage(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        try{
            Id autoDealerRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer').getRecordTypeId();
            Set<Id> updatedaccountIds = new Set<Id>();
            
            Map<Id, List<String>>  dealerIdToDealerProsEmailMap = new Map<Id, List<String>> ();
            
            for(Account each:newMap.Values()){
                if(each.RecordTypeId == autoDealerRecordTypeId && each.Manager_Email__c != oldMap.get(each.Id).Manager_Email__c && oldMap.get(each.Id).Manager_Email__c == null) {
                    updatedaccountIds.add(each.Id);  
                     if (!dealerIdToDealerProsEmailMap.containsKey(each.Id)) {
                        dealerIdToDealerProsEmailMap.put(each.Id, new List<String>());
                    }
                    dealerIdToDealerProsEmailMap.get(each.Id).add(each.Manager_Email__c);
                }   
            }
            
            if (updatedaccountIds.isEmpty()) {
                System.debug('No accounts with updated emails');
                return;
            }
            List<Contact> activeDealerPros = [SELECT Id, Email, AccountId, RecordType.DeveloperName FROM Contact WHERE AccountId IN :updatedAccountIds AND Active__c = true AND RecordType.DeveloperName = 'Auto_Dealer_pro'];
               for (Contact con : activeDealerPros) {
                if (!dealerIdToDealerProsEmailMap.containsKey(con.AccountId)) {
                    dealerIdToDealerProsEmailMap.put(con.AccountId, new List<String>());
                }
                dealerIdToDealerProsEmailMap.get(con.AccountId).add(con.Email);
            }
              ContactTriggerHelper.sendPendingRequestsToDealer(updatedaccountIds, dealerIdToDealerProsEmailMap);
          
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
    }
}