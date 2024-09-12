@isTest
public class OpportunityTestClass {
    @isTest
    public Static Void opportunityTrihherHandlerTest(){
        
         Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = accountDescribe.getRecordTypeInfosByDeveloperName();
        Id autoDealerRecordTypeId = recordTypeMap.get('Auto_Dealer').getRecordTypeId();
        
        List<Account> accountsToUpdate = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
                accountsToUpdate.add(new Account(
                    Name = 'Test Account ' + i,
                    Market__c = 'Nocal',
                    Active__c = false,
                    Phone = '+19900887766',
                    Manager_Cell_Phone__c = '+10077881199',
                    RecordTypeId = autoDealerRecordTypeId,
                    BillingStreet = 'Test Street',
                    BillingPostalCode = '09089',
                    BillingCity = 'Test City',
                    BillingState = 'LA',
                    Manager_Name__c = 'Test Manger',
                    Manager_Email__c = 'testmanager@test.com',
                    Website = 'www.test.com',
                    Brand__c = 'Test Brand',
                    Lead_MSR_Cell_Phone__c = '+11100229988',
                    Project_Manager_Cell_Phone__c = '+12200998877',
                    F_I_Manager_Cell_Phone__c = '+13399008877'   
                ));
        }
        insert accountsToUpdate;
        
        Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap2 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id AutoShopperTypeId = recordTypeMap2.get('Auto_Shopper').getRecordTypeId();
        
        List<Contact> contactsToUpdate1 = new List<Contact> ();
        for(Integer j = 0; j < 10; j++) {
         
          contactsToUpdate1.add(new Contact(LastName = 'Contact' + j, FirstName = 'Test', Title='Test Title', Phone='+10066995546', MobilePhone = '+16644009900', Email = 'Testcon'+ j + '@gmail.com', RecordTypeId =  AutoShopperTypeId)); 
        }
        insert contactsToUpdate1;
        
        List<Opportunity> oppList = new List<Opportunity> ();
        for(integer k=0; k<10; k++){
            oppList.add(new opportunity(Auto_Shopper__c =contactsToUpdate1[k].Id, Name= 'Test Opp '+ k, StageName= 'Waiting On Vehicle', CloseDate = Date.newInstance(2024, 8, 3),  AccountId=accountsToUpdate[k].Id,   ForecastCategoryName = 'Omitted', Probability= 80, Phone__c = '(878) 987-9876', Mobile__c = '(898) 8976-908'));
              }
        insert oppList;
        
        List<Opportunity>  updateOpp = [Select Id, Name, Phone__c, Mobile__c from Opportunity Where Id IN:oppList];
        
        for(Opportunity opp: updateOpp){
            opp.Phone__c = '987-(7867) 908';
            opp.Mobile__c = '876-9087 (8761)';
        }
        
        Test.startTest();
        update updateOpp;
        Test.stopTest();
        
        delete oppList;
    }

}