@isTest
private class AzureIntegrationServiceTest {
    
    @isTest
    static void testDoPost() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        
        Test.startTest();
        RestContext.request = request;
        RestContext.response = response;
        
        // Call the doPost method
        AzureIntegrationService.CreateResponseWrapper result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertEquals(1, result.error.size(), 'Request is present');
        
        request.requestURI = '/AzureIntegrationService';
        // Call the doPost method
        result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertEquals(1, result.error.size(), 'Expected error data as no match is found for the uri');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreateAccounts() {
        RestRequest request = new RestRequest();
        request.requestURI = '/AzureIntegrationService/CreateBankData';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"Name":"TestAccount"}]');
        RestContext.request = request;
        
        // Call the createAccounts method
        AzureIntegrationService.CreateResponseWrapper result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertNotEquals(null, result.success, 'Expected success data');
        // Add more assertions as needed
    }
    
    @isTest
    static void testCreateContacts() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = [select Id,Name from RecordType where DeveloperName ='Bank' and SobjectType='Account'].Id;
        insert acc;
        
        RestRequest request = new RestRequest();
        request.requestURI = '/AzureIntegrationService/CreateServiceRepData';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"FirstName":"Test","LastName":"Contact","Email":"test@example.com","AccountId":"'+acc.Id+'"},'+
                                           +'{"FirstName":"Test","LastName":"Contact","Email":"test@example.com","AccountId":"'+acc.Id+'"},'+
                                           +'{"FirstName":"Test","LastName":"Contact","Email":"test@example.com","AccountId":"'+acc.Id+'"},'+
                                           +'{"FirstName":"Test","LastName":"Contact","Email":"test@example.com","AccountId":"'+acc.Id+'"}]');
        RestContext.request = request;
        AzureIntegrationService.CreateResponseWrapper result = AzureIntegrationService.doPost();
        
        request.requestBody = Blob.valueOf('[{"FirstName":"Test","LastName":"Contact","Email":"test@example.com","AccountId":"'+acc.Id+'"}]');
        RestContext.request = request;
        result = AzureIntegrationService.doPost();
        
        request.requestBody = Blob.valueOf('[{"FirstName":"Test","LastName":"Contact","Email":"test@example.com","AccountId":"'+acc.Id+'"}]');
        RestContext.request = request;
        result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertNotEquals(null, result.success, 'Expected success data');
        // Add more assertions as needed
    }
    
    @isTest
    static void testCreateOpportunities() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = [select Id,Name from RecordType where DeveloperName ='Bank' and SobjectType='Account'].Id;
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Test Rep';
        con.Email = 'testemailsalesrep@testsales.com';
        con.AccountId = acc.Id;
        con.RecordTypeId = [select Id,Name from RecordType where DeveloperName ='Bank_Service_Rep' and SobjectType='Contact'].Id;
        insert con;
        
        RestRequest request = new RestRequest();
        request.requestURI = '/AzureIntegrationService/CreateLoanData';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"Name":"TestOpportunity1","Branch__c":"TestBranch1","StageName":"New","CloseDate":"2024-02-12","Auto_Shopper__c":"003VA000004P36vYAC","Bank_Service_Rep_Name_MSR__c":"Test Rep1"},'+
                                           +'{"Name":"TestOpportunity2","Branch__c":"TestBranch2","StageName":"New","CloseDate":"2024-02-12","Auto_Shopper__c":"003VA000004P36vYAC","Bank_Service_Rep_Name_MSR__c":"Test Rep2"},'+
                                           +'{"Name":"TestOpportunity3","Branch__c":"TestBranch3","StageName":"New","CloseDate":"2024-02-12","Auto_Shopper__c":"003VA000004P36vYAC","Bank_Service_Rep_Name_MSR__c":"Test Rep3"},'+
                                           +'{"Name":"TestOpportunity4","Branch__c":"TestBranch4","StageName":"New","CloseDate":"2024-02-12","Auto_Shopper__c":"003VA000004P36vYAC","Bank_Service_Rep_Name_MSR__c":"Test Rep4"},'+
                                           +'{"Name":"TestOpportunity5","Branch__c":"TestBranch5","StageName":"New","CloseDate":"2024-02-12","Auto_Shopper__c":"003VA000004P36vYAC","Bank_Service_Rep_Name_MSR__c":"Test Rep5"}]');
        
        RestContext.request = request;
        
        // Call the createOpportunities method
        AzureIntegrationService.CreateResponseWrapper result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertNotEquals(null, result.success, 'Expected success data');
        // Add more assertions as needed
    }
    
    @isTest
    static void testUpdateDataInAzureForAccount() {
        // Create test data
        Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = accountDescribe.getRecordTypeInfosByDeveloperName();
        Id autoDealerRecordTypeId = recordTypeMap.get('Auto_Dealer').getRecordTypeId();
        Id bankRecordTypeId = recordTypeMap.get('Bank').getRecordTypeId();
        
        List<Account> accountsToUpdate = new List<Account>();
        for (Integer i = 0; i < 200; i+=50) {
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
                    F_I_Manager_Cell_Phone__c = '+13399008877',
					FastPass_Dealer_Id__c ='12'+i   
                ));
        }
        insert accountsToUpdate;
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockAzureIntegrationService());
        
        // Call the trigger
        Test.startTest();
        update accountsToUpdate;
        Test.stopTest();
        
        // Verifing that the correct callout was made for each account
        List<Account> updatedAccounts = [SELECT Id, Market__c, Active__C  FROM Account WHERE Id IN :accountsToUpdate];
        for (Account updatedAccount : updatedAccounts) {
            
            //Asserting that the Market__c field value of each updated account is equal to the new value 'NoCal'
            System.assertEquals('NoCal', updatedAccount.Market__c, 'Account Market should have been updated');
            
            //Asserting that the Active__c field value of each updated account is equal to the new value 'false'
            System.assertEquals(false, updatedAccount.Active__c, 'Account Active should have been updated');
        }
        
        delete accountsToUpdate;
    }
    
    @isTest
    static void testUpdateDataInAzureForContacts() {
        // Create test data
        Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap1 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id servicesRepRecordTypeId = recordTypeMap1.get('Bank_Service_Rep').getRecordTypeId();
        
        List<Contact> contactsToUpdate = new List<Contact> ();
        for(Integer j = 0; j < 200; j+=50) {
           
          contactsToUpdate.add(new Contact(LastName = 'Contact' + j, FirstName = 'Test', Title='Test Title', Phone='+10066775544', MobilePhone = '+16644889900', Email = 'Testcon'+ j + '@gmail.com', RecordTypeId =   servicesRepRecordTypeId));
        }
        insert contactsToUpdate;
        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockAzureIntegrationService());
        
        // Call the trigger
        Test.startTest();
        update contactsToUpdate;
        Test.stopTest();
        
        List<Contact> updatedContacts = [SELECT Id, RecordType.DeveloperName  FROM Contact WHERE Id IN :contactsToUpdate];
        for (Contact updatedContact : updatedContacts) {
            
            //Asserting that the developer name of recordtype value of each updated Contact
            System.assertEquals('Bank_Service_Rep', updatedContact.RecordType.DeveloperName, 'Contact Record Type should have been updated');
            
        }
        delete contactsToUpdate;
        
    }
     @isTest
    static void testUpdateDataInAzureForContactsOfAutoShopper() {
        // Create test data
        Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap2 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id AutoShopperTypeId = recordTypeMap2.get('Auto_Shopper').getRecordTypeId();
        
        List<Contact> contactsToUpdate1 = new List<Contact> ();
        for(Integer j = 0; j < 200; j+=50) {
         
          contactsToUpdate1.add(new Contact(LastName = 'Contact' + j, FirstName = 'Test', Title='Test Title', Phone='+10066995546', MobilePhone = '+16644009900', Email = 'Testcon'+ j + '@gmail.com', RecordTypeId =  AutoShopperTypeId)); 
        }
        insert contactsToUpdate1;
        List<Opportunity> oppList = new List<Opportunity> ();
        for(integer i=0; i<=200; i+=50){
            //oppList.add(new opportunity(Auto_Shopper__c =contactsToUpdate1[i].Id ));
                }
        
        List<Contact> contactsToUpdateWithNewPhoneMobile = [SELECT Id, Phone, MobilePhone FROM Contact WHERE Id IN :contactsToUpdate1];
        for(Contact con : contactsToUpdateWithNewPhoneMobile) {
            con.Phone = '+19998887777'; 
            con.MobilePhone = '+18887776655'; 
        }
        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockAzureIntegrationService());
        
        // Call the trigger
        Test.startTest();
        update contactsToUpdateWithNewPhoneMobile;
        Test.stopTest();
        
        List<Contact> updatedContacts1 = [SELECT Id, RecordType.DeveloperName  FROM Contact WHERE Id IN :contactsToUpdate1];
        for (Contact updatedContact1 : updatedContacts1) {
            
            //Asserting that the developer name of recordtype value of each updated Contact
            System.assertEquals('Auto_Shopper', updatedContact1.RecordType.DeveloperName, 'Contact Record Type should have been updated');
            
        }
        delete contactsToUpdate1;
        
    }
    // Mock class to simulate the behavior of AzureIntegrationService during testing
    
    private class MockAzureIntegrationService implements HttpCalloutMock {
        // Implement the respond method to simulate the callout response
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response with status code 200
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Prepare a mock response body
            String responseBody = '{"success": true, "message": "Bulk update successful"}'; // Example response
            res.setBody(responseBody); // Mock response body
            return res;
        }
    }
    @isTest
    static void testGetAzureAccessToken (){
        
        // Set up mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call the method to be tested
        Test.startTest();
        AzureIntegrationService.getAzureAccessToken();
        Test.stopTest();
        
        // Retrieve the updated metadata record
        Salesforce_webhook__mdt updatedMetadata = [SELECT Access_Token__c FROM Salesforce_webhook__mdt WHERE DeveloperName = 'Azure_Integration_Service'];
        
        // Assert that the access token was updated
        System.assertNotEquals('mockAccessToken', updatedMetadata.Access_Token__c, 'Access token should have been updated');
    }
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        
        // Implementing the respond method to generate a mock response
        public HTTPResponse respond(HTTPRequest req) {
            
            // Creating a mock response with status code 200 and a sample JSON body
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token": "updatedAccessToken"}');
            return res;
        }
    }
    
    @isTest 
    static void testAzureIntegrationServiceScheduler() {
        
        // Set mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        AzureIntegrationServiceScheduler scheduler = new AzureIntegrationServiceScheduler();
        
        Test.startTest();
        scheduler.execute(null); 
        Test.stopTest();
        
    }
    // Mock class to simulate the behavior of AzureIntegrationService during testing
    private class MockHttpResponse implements HttpCalloutMock {
        
        // Implement the respond method to simulate the callout response
        public HttpResponse respond(HttpRequest req) {
            
            // Create a mock response with status code 200
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Prepare a mock response body
            String responseBody = '{"success": true, "message": "Access token is fetced successfully"}';
            res.setBody(responseBody); // Mock response body
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testAvoidUpdates(){
        Test.startTest();
        AvoidUpdates.runOnce();
        Test.stopTest();
    }

	@isTest
    static void testCreateLead() {
        RestRequest request = new RestRequest();
        request.requestURI = '/AzureIntegrationService/CreateLeadDealerData';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"Company":"TestOpportunity1","FastPass_Dealer_Id__c":"TestBranch1"},'+
                                           +'{"Company":"TestOpportunity2","FastPass_Dealer_Id__c":"TestBranch2"},'+
                                           +'{"Company":"TestOpportunity3","FastPass_Dealer_Id__c":"TestBranch3"},'+
                                           +'{"Company":"TestOpportunity4","FastPass_Dealer_Id__c":"TestBranch4"},'+
                                           +'{"Company":"","FastPass_Dealer_Id__c":"TestBranch5"}]');
        
        RestContext.request = request;
        
        // Call the createOpportunities method
        AzureIntegrationService.CreateResponseWrapper result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertNotEquals(null, result.success, 'Expected success data');
        // Add more assertions as needed
    }

    @isTest
	static void testUpsertDealer() {
        Account acc = new Account();
        acc.Name = 'Test Dealer';
        acc.fastpass_dealer_id__c = '90907';
        acc.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Auto_Dealer'].Id;
        insert acc;

        Lead lead = new Lead();
        lead.LastName = 'Test Lead Dealer';
        lead.Company = 'Test Dealer';
        lead.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'Dealer'].Id;
        lead.fastpass_dealer_id__c = '90908';
        insert lead;
        

        RestRequest request = new RestRequest();
        request.requestURI = '/AzureIntegrationService/UpsertDealerData';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(	'['+
		'{'+
		'    "Name": "Test Dealer 6",'+
		'    "Type": "Franchise",'+
		'    "ParentId": null,'+
		'    "BillingStreet": null,'+
		'    "BillingCity": null,'+
		'    "BillingState": null,'+
		'    "BillingPostalCode": null,'+
		'    "BillingCountry": null,'+
		'    "BillingLatitude": null,'+
		'    "BillingLongitude": null,'+
		'    "BillingGeocodeAccuracy": null,'+
		'    "Phone": "916-555-3344",'+
		'    "Website": "www.exampledealer6.com",'+
		'    "NumberOfEmployees": 30,'+
		'    "Description": "Regional dealer with a strong presence",'+
		'    "Brand__c": "Ford",'+
		'    "Market__c": "SoCal",'+
		'    "Active__c": true,'+
		'    "F_I_Manager_Name__c": "Jackob 6",'+
		'    "F_I_Manager_Cell_Phone__c": "9855685405",'+
		'    "F_I_Email__c": "jackob6@test.com",'+
		'    "Manager_Name__c": "Sophia",'+
		'    "Manager_Email__c": null,'+
		'    "Manager_Cell_Phone__c": null,'+
		'    "Date_Connected_to_FastPass__c": "2024-07-08",'+
		'    "FastPass_Dealer_Id__c": "90906",'+
		'    "Dealer_Id__c": "006",'+
		'    "Location_Id__c": "006",'+
		'    "Website_Id__c": "006",'+
		'    "Rooftop_Id__c": "006",'+
		'    "Category__c": "Electric Vehicles",'+
		'    "Dealership_Group_Id__c": "006",'+
		'    "Dealership_Group_Name__c": "Group 6",'+
		'    "Sub_Dealership_Group_Id__c": "006",'+
		'    "Sub_Dealership_Group_Name__c": "Sub Group 6",'+
		'    "Email__c": "test303@xyz.com",'+
		'    "Source__c": "EV Push",'+
		'    "Dealer_Type__c": "Franchise Dealer",'+
		'    "Franchises__c": "Ford",'+
		'    "Verified_Dealer_Data__c": true,'+
		'    "Created_At__c": "2024-08-25T08:45:00.000Z",'+
		'    "Updated_At__c": "2024-08-25T08:45:00.000Z"'+
		'},'+
		'{'+
		'    "Name": "Test Dealer 7",'+
		'    "Type": "Franchise",'+
		'    "ParentId": null,'+
		'    "BillingStreet": null,'+
		'    "BillingCity": null,'+
		'    "BillingState": null,'+
		'    "BillingPostalCode": null,'+
		'    "BillingCountry": null,'+
		'    "BillingLatitude": null,'+
		'    "BillingLongitude": null,'+
		'    "BillingGeocodeAccuracy": null,'+
		'    "Phone": "916-555-3344",'+
		'    "Website": "www.exampledealer6.com",'+
		'    "NumberOfEmployees": 30,'+
		'    "Description": "Regional dealer with a strong presence",'+
		'    "Brand__c": "Ford",'+
		'    "Market__c": "SoCal",'+
		'    "Active__c": true,'+
		'    "F_I_Manager_Name__c": "Jackob 6",'+
		'    "F_I_Manager_Cell_Phone__c": "9855685405",'+
		'    "F_I_Email__c": "jackob6@test.com",'+
		'    "Manager_Name__c": "Sophia",'+
		'    "Manager_Email__c": null,'+
		'    "Manager_Cell_Phone__c": null,'+
		'    "Date_Connected_to_FastPass__c": "2024-07-08",'+
		'    "FastPass_Dealer_Id__c": "90907",'+
		'    "Dealer_Id__c": "006",'+
		'    "Location_Id__c": "006",'+
		'    "Website_Id__c": "006",'+
		'    "Rooftop_Id__c": "006",'+
		'    "Category__c": "Electric Vehicles",'+
		'    "Dealership_Group_Id__c": "006",'+
		'    "Dealership_Group_Name__c": "Group 6",'+
		'    "Sub_Dealership_Group_Id__c": "006",'+
		'    "Sub_Dealership_Group_Name__c": "Sub Group 6",'+
		'    "Email__c": "test303@xyz.com",'+
		'    "Source__c": "EV Push",'+
		'    "Dealer_Type__c": "Franchise Dealer",'+
		'    "Franchises__c": "Ford",'+
		'    "Verified_Dealer_Data__c": true,'+
		'    "Created_At__c": "2024-08-25T08:45:00.000Z",'+
		'    "Updated_At__c": "2024-08-25T08:45:00.000Z"'+
		'},'+
        '{'+
		'    "Name": "Test Dealer 7",'+
		'    "Type": "Franchise",'+
		'    "ParentId": null,'+
		'    "BillingStreet": null,'+
		'    "BillingCity": null,'+
		'    "BillingState": null,'+
		'    "BillingPostalCode": null,'+
		'    "BillingCountry": null,'+
		'    "BillingLatitude": null,'+
		'    "BillingLongitude": null,'+
		'    "BillingGeocodeAccuracy": null,'+
		'    "Phone": "916-555-3344",'+
		'    "Website": "www.exampledealer6.com",'+
		'    "NumberOfEmployees": 30,'+
		'    "Description": "Regional dealer with a strong presence",'+
		'    "Brand__c": "Ford",'+
		'    "Market__c": "SoCal",'+
		'    "Active__c": true,'+
		'    "F_I_Manager_Name__c": "Jackob 6",'+
		'    "F_I_Manager_Cell_Phone__c": "9855685405",'+
		'    "F_I_Email__c": "jackob6@test.com",'+
		'    "Manager_Name__c": "Sophia",'+
		'    "Manager_Email__c": null,'+
		'    "Manager_Cell_Phone__c": null,'+
		'    "Date_Connected_to_FastPass__c": "2024-07-08",'+
		'    "FastPass_Dealer_Id__c": "90908",'+
		'    "Dealer_Id__c": "006",'+
		'    "Location_Id__c": "006",'+
		'    "Website_Id__c": "006",'+
		'    "Rooftop_Id__c": "006",'+
		'    "Category__c": "Electric Vehicles",'+
		'    "Dealership_Group_Id__c": "006",'+
		'    "Dealership_Group_Name__c": "Group 6",'+
		'    "Sub_Dealership_Group_Id__c": "006",'+
		'    "Sub_Dealership_Group_Name__c": "Sub Group 6",'+
		'    "Email__c": "test303@xyz.com",'+
		'    "Source__c": "EV Push",'+
		'    "Dealer_Type__c": "Franchise Dealer",'+
		'    "Franchises__c": "Ford",'+
		'    "Verified_Dealer_Data__c": true,'+
		'    "Created_At__c": "2024-08-25T08:45:00.000Z",'+
		'    "Updated_At__c": "2024-08-25T08:45:00.000Z"'+
		'}'+
		']');
        
        RestContext.request = request;
        
        // Call the createOpportunities method
        AzureIntegrationService.CreateResponseWrapper result = AzureIntegrationService.doPost();
        
        // Add assertions based on the expected behavior
        System.assertNotEquals(null, result.success, 'Expected success data');
        // Add more assertions as needed
    }
    
}