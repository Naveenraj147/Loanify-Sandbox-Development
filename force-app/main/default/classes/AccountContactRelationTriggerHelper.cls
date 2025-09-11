public class AccountContactRelationTriggerHelper {

    public static void handleNewContactRelation(List<AccountContactRelation> newAccConRelationList){

        Set<Id> dealerAccIds = new Set<Id>();
        List<AccountContactRelation> accConrelationList = [SELECT Id, Contact.Active__c, Contact.RecordTypeId, AccountId, Contact.Member_Response_Notification__c FROM AccountContactRelation WHERE Id =:newAccConRelationList];
        String msrRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Bank Service Rep').getRecordTypeId();
        String dealerProRecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();

        for(AccountContactRelation each : accConrelationList){
            if(each.Contact.RecordTypeId == dealerProRecordTypeId && each.Contact.Active__c == true && each.Contact.Member_Response_Notification__c == true ){
                dealerAccIds.add(each.AccountId);
            }
        }

        if(dealerAccIds.size() > 0){
            List<Garage__c> garageList = [SELECT id, Dealer_Email_Available__c  FROM Garage__c 
                                                WHERE Dealer__c in :dealerAccIds  AND Dealer_Email_Available__c = false];
            if(garageList.size() > 0){
                for(Garage__c each : garageList){
                    each.Dealer_Email_Available__c = true;
                }
                update garageList; 
                 TriggerAPIService.logTriggerEvent('SF_DML_UPDATE14', 'SF41', UserInfo.getUserName(), null);
            }
    
            List<Portal_Message__c> pmList = [SELECT id, Is_Pending__c  FROM Portal_Message__c 
                                                WHERE Garage__r.Dealer__c in :dealerAccIds AND (Portal_Type__c = 'Dealer' OR Portal_Type__c = 'Carbots') AND Is_Pending__c = true];
            if(pmList.size() > 0){
                for(Portal_Message__c each : pmList){
                    each.Is_Pending__c = false;
                }
                update pmList;
                 TriggerAPIService.logTriggerEvent('SF_DML_UPDATE15', 'SF41', UserInfo.getUserName(), null);
    
            }
        }
    }
    public static void handleContactRelationUpdate(List<AccountContactRelation> newAccConRelationList, Map<Id, AccountContactRelation> oldAccConRelationMap ){
        Set<Id> activedealerAccIds = new Set<Id>();
        Set<Id> inactivedealerAccIds = new Set<Id>();
        Set<Id> allContactIds = new Set<Id>();
        Set<Id> allAccountIds = new Set<Id>();
        String dealerProRecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();
        for(AccountContactRelation each : newAccConRelationList ){
            if(each.contactId != oldAccConRelationMap.get(each.id).contactId ){
                allContactIds.add(each.contactId);
                allContactIds.add(oldAccConRelationMap.get(each.id).contactId);
                allAccountIds.add(each.AccountId);
            }
            if(each.AccountId != oldAccConRelationMap.get(each.id).AccountId){
                allAccountIds.add(each.AccountId);
                allContactIds.add(each.contactId);
            }
        }
        if(allContactIds.size() > 0){
            Map<Id, Contact> allContactMap = new Map<Id, Contact>([SELECT Id, Name,Active__c, Member_Response_Notification__c FROM Contact WHERE Id =:allContactIds]);
            Map<Id, Account> accoutMap = new Map<Id, account>([SELECT Id, (SELECT Id FROM AccountContactRelations WHERE Contact.Active__c = true AND Contact.Member_Response_Notification__c = true )FROM Account WHERE Id =: allAccountIds ]);
            for(AccountContactRelation each : newAccConRelationList ){
                Contact newContact = allContactMap.get(each.ContactId);
                Contact  oldContact= allContactMap.get(oldAccConRelationMap.get(each.Id).ContactId);
                if(each.contactId != oldAccConRelationMap.get(each.id).contactId){
                    //Active Contact to Inactive Contact
                    if((oldcontact.Active__c == true  && oldcontact.Member_Response_Notification__c == true) && (newcontact.Active__c == false  ||  newcontact.Member_Response_Notification__c == false)){
                        if(accoutMap.containsKey(each.AccountId) && accoutMap.get(each.AccountId).AccountContactRelations.size() == 0){
                            inactivedealerAccIds.add(each.AccountId);
                        }
                    }
                    //Inactive Contact to Active Contact
                    if((oldcontact.Active__c == false || oldcontact.Member_Response_Notification__c == false) && (newcontact.Active__c == true  &&  newcontact.Member_Response_Notification__c == true)){
                        if(accoutMap.containsKey(each.AccountId) && accoutMap.get(each.AccountId).AccountContactRelations.size() > 0){
                            activedealerAccIds.add(each.AccountId);
                        }
                    }
                }
                if(each.AccountId != oldAccConRelationMap.get(each.id).AccountId ){
                    if(newContact.Active__c == true && newContact.Member_Response_Notification__c == true ){
                        if(accoutMap.containsKey(each.AccountId) && accoutMap.get(each.AccountId).AccountContactRelations.size() == 0){
                            activedealerAccIds.add(each.AccountId);
 
                        }
                        if(accoutMap.containsKey(oldAccConRelationMap.get(each.Id).AccountId) && accoutMap.get(oldAccConRelationMap.get(each.Id).AccountId).AccountContactRelations.size() == 0){
                            inactivedealerAccIds.add(each.AccountId);
 
                        }

                    }
                }
            }
            if(activedealerAccIds.size() > 0 || inactivedealerAccIds.size() > 0){
                List<Garage__c> garageList = [SELECT id, Dealer_Email_Available__c  FROM Garage__c 
                                                    WHERE (Dealer__c in :inactivedealerAccIds OR Dealer__c in :activedealerAccIds) AND  Opportunity__r.isClosed = false];
                
                                                    List<Garage__c> garagesToUpdateList = new List<Garage__c>();
                if(garageList.size() > 0){
                    for(Garage__c each : garageList){
                        Garage__c garage = new Garage__c();
                        garage.Id = each.Id;

                        if(inactivedealerAccIds.contains(each.Dealer__c) && each.Dealer_Email_Available__c == true){
                            garage.Dealer_Email_Available__c = false;
                            garagesToUpdateList.add(garage);
                        }
                        else if(activedealerAccIds.contains(each.Dealer__c) && each.Dealer_Email_Available__c == false){
                            garage.Dealer_Email_Available__c = true;
                            garagesToUpdateList.add(garage);
                        }
                        
                    }
                    if(garagesToUpdateList.size() > 0){
                        update garagesToUpdateList; 
                    }
                   
                }
        
                List<Portal_Message__c> pmList = [SELECT id, Is_Pending__c  FROM Portal_Message__c 
                                                    WHERE Garage__r.Dealer__c in :activedealerAccIds AND (Portal_Type__c = 'Dealer' OR Portal_Type__c = 'Carbots') AND Is_Pending__c = true AND  Opportunity__r.isClosed = false];
                if(pmList.size() > 0){
                    for(Portal_Message__c each : pmList){
                        each.Is_Pending__c = false;
                    }
                    update pmList;
        
                }
            }
            
        }
    }

}