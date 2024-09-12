@isTest
private class FastPassIntegrationServiceTest {
    
    // Helper method to create test data
    private static void createTestData() {
        Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = accountDescribe.getRecordTypeInfosByDeveloperName();
        Id autoDealerRecordTypeId = recordTypeMap.get('Auto_Dealer').getRecordTypeId();
        Id bankRecordTypeId = recordTypeMap.get('Bank').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        List<Account> accountsToUpdate = new List<Account>();
        for (Integer i = 0; i < 20; i++) {
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
                FastPass_Dealer_Id__c = '202434'+i,
                BillingState = 'LA',
                Manager_Name__c = 'Test Manger',
                Website = 'www.test.com',
                Brand__c = 'Test Brand',
                Lead_MSR_Cell_Phone__c = '+11100229988',
                Project_Manager_Cell_Phone__c = '+12200998877',
                F_I_Manager_Cell_Phone__c = '+13399008877'   
            ));
        }
        insert accountsToUpdate;
        system.debug('Accounts Inserted::'+ accountsToUpdate);
        Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap1 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id autoShopperRecordTypeId = recordTypeMap1.get('Auto_Shopper').getRecordTypeId();
        Id dealerProRecordTypeId = recordTypeMap1.get('Auto_Dealer_Pro').getRecordTypeId();
        List<Contact> contactsToUpdate = new List<Contact> ();
        for(Integer j = 0; j < 20; j++) {
            if(Math.mod(j, 2) == 0){
                contactsToUpdate.add(new Contact(LastName = 'Contact' + j, Active__c = true, AccountId = accountsToUpdate[j].Id,  FirstName = 'Test', Title='Test Title', Phone='+1006677554'+j, MobilePhone = '+1664488990'+j, Email = 'Testcon@gmail.com', RecordTypeId = dealerProRecordTypeId));
                
            } else{
                contactsToUpdate.add(new Contact(LastName = 'Contact' + j, Active__c = false, FirstName = 'Test', Title='Test Title', Phone='+1006677554'+j, MobilePhone = '+1664488990'+j, Email = 'Testcon'+ j + '@gmail.com', RecordTypeId = autoShopperRecordTypeId));
            }
        }
        insert contactsToUpdate;
        system.debug('Contacts Inserted::'+ contactsToUpdate);
        system.debug('Contact Name::' +  contactsToUpdate[1].LastName);
        List<Opportunity> oppList = new List<Opportunity> ();
        for(integer k=0; k<=20; k++){
            
            oppList.add(new opportunity(Name = 'Test Opp '+k, Vehicle_VIN__C = '645466',AccountId = accountsToUpdate[0].Id, ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898'+k, 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), Dealer__c = accountsToUpdate[0].Id, StageName = 'New',  Auto_Shopper__c = contactsToUpdate[1].Id ));
        }
        insert oppList;
        system.debug('Opportunities Inserted::'+ oppList);
         Garage__c gar = new Garage__c ();
        gar.Active__c = false;
        gar.Dealer__c = accountsToUpdate[0].Id; 
        gar.Dealer_Email_Available__c = true;
        gar.Dealer_pro_1__c = contactsToUpdate[0].Id;
        gar.Dealer_pro_2__c = contactsToUpdate[2].Id;
        gar.Dealer_pro_3__c = contactsToUpdate[4].Id;
        gar.VIN__c = '645466';
        gar.Fastpass_Dealer_Id__c = '202434';
        gar.Pending_Requests__c = 'Subject++ Test Pending Request Subject Body++ Test Pending Request Body Type++ testDrive;;Subject++ Test Pending Request Subject1 Body++ Test Pending Request Body1 Type++ testDrive';
        gar.Year__c = 2014;
        gar.Opportunity__c = oppList[0].Id;
        gar.Name = 'Thar';
        
        insert gar;
        Opportunity opp = [SELECT Id, Name, Card_Number__c, Auto_Shopper__r.Name from Opportunity where Id =: oppList[0].Id];
        String subjectPattern = 'Query requested by ' +opp.Auto_Shopper__r.Name+ ' for '+'#' +  opp.Card_Number__c + ' in #' +'645466';
        String subjectPattern1 = 'Test Drive requested by ' +opp.Auto_Shopper__r.Name +' for '+'#' +  opp.Card_Number__c + ' in #' +'645466';
        // Create EmailMessages related to the Opportunity
        system.debug('Subject Pattern in test class:: ' +subjectPattern1);
        system.debug('Subject Pattern in test class:: ' +subjectPattern);
        List<EmailMessage> emailMessageList = new List<EmailMessage> ();
        for(integer l=0; l<10; l++){
            emailMessageList.add(new EmailMessage(Subject=subjectPattern1, ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="', RelatedToId=gar.Id));
            emailMessageList.add(new EmailMessage(Subject=subjectPattern1, ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Dealer Response: Sure.</body>', RelatedToId=gar.Id));
            emailMessageList.add(new EmailMessage(Subject=subjectPattern1, ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Response: Thank You.Please <a href="',RelatedToId=gar.Id));
            emailMessageList.add(new EmailMessage(Subject=subjectPattern1, ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/>', RelatedToId=gar.Id));            
        }
        for(integer m=0; m<10; m++){
            emailMessageList.add(new EmailMessage(Subject=subjectPattern, ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hello Test Auto Shopper 3,<br/> Member Query: Can you provide the vehicle details.Please <a href="', RelatedToId=gar.Id));
            emailMessageList.add(new EmailMessage(Subject=subjectPattern, ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hello Test Auto Shopper 3,<br/> Dealer Response: Sure.</body> ', RelatedToId=gar.Id));        
        }
        insert emailMessageList;   
    }
    private class MockFastPassIntegrationService implements HttpCalloutMock {
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
    static void requestForTestDriveTest() {
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323'); 
        insert gar;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDrive", "LoanId" : "7878678767877898", "FastPassDealerId" : "202434" , "VehicleVIN" : "645466", "TestDriveDate" : "2024-06-15T12:44:00.000Z", "VehicleName": "Nissan", "MemberQuery" : "Test Query"}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
        System.assertNotEquals(null, responseList);
        System.assert(responseList.size() > 0);
    }
    
    @isTest
    static void requestForTestDriveWithMemberResponseTest() {
        
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323'); 
        insert gar;
        EmailMessage EM =  new EmailMessage(Subject='Test Drive requested by Test Member for #7878678767877898 in #VIN645466', ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="', RelatedToId=gar.Id);
		insert EM;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'Post';
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDrive", "LoanId" : "7878678767877898", "FastPassDealerId" : "2323", "VehicleVIN" : "VIN645466", "VehicleName": "Nissan", "MemberQuery" : "Provide the full details of vehicle"}]');
        RestContext.request = request;
        FastPassIntegrationService.doPost(); 
    }
    
    
    @isTest
    static void askDealerTest() {
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323'); 
        insert gar;
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "askDealer", "LoanId" : "7878678767877898", "FastPassDealerId" : "202434",  "VehicleName": "Ford", "VehicleVIN" : "VIN645466", "MemberQuery" : "Test Query"}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
        System.assertNotEquals(null, responseList);
        System.assert(responseList.size() > 0);
    }
    
    @isTest
    static void requestTestDriveResponseTest() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDriveConversation", "LoanId" : "7878678767877898", "FastPassDealerId" : "202434", "VehicleVIN" : "645466", "PageNumber" : 1}]');
        RestContext.request = request;
        
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
        request.requestUri = '/FastPassIntegrationService';
        responseList = FastPassIntegrationService.doPost();
        System.assertNotEquals(null, responseList);
        System.assert(responseList.size() > 0);
    }
    
    @isTest
    static void askDealerResponseTest() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "askDealerConversation", "LoanId" : "7878678767877898", "FastPassDealerId" : "202434", "VehicleVIN" : "645466", "PageNumber" : 1}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();        
        request.requestUri = '/FastPassIntegrationService';
        responseList = FastPassIntegrationService.doPost();
        System.assertNotEquals(null, responseList);
        System.assert(responseList.size() > 0);
    }
    
    @isTest
    static void invalidRequestType() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDrove", "LoanId" : "7878678767877898", "FastPassDealerId" : "202434" , "VehicleVIN" : "645466", "TestDriveDate" : "2024-06-15T12:44:00.000Z", "VehicleName": "Nissan", "MemberQuery" : "Test Query"}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
        System.assertNotEquals(null, responseList);
        System.assert(responseList.size() > 0);
    }
    
    @isTest
    static void vehicleAdditionInsertTest() {
        Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = accountDescribe.getRecordTypeInfosByDeveloperName();
        Id autoDealerRecordTypeId = recordTypeMap.get('Auto_Dealer').getRecordTypeId();
        Account acc = new Account ();
        acc.RecordTypeId = autoDealerRecordTypeId;
        acc.Name = 'Test Account To Insert';
        acc.FastPass_Dealer_Id__c = '1202434';
        acc.Market__c = 'Nocal';
        acc.Active__c = true;
        acc.Phone = '+19900887766';
        Insert acc;
        
        Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap1 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id dealerProRecordTypeId = recordTypeMap1.get('Auto_Dealer_Pro').getRecordTypeId();
        Id autoShopperRecordTypeId = recordTypeMap1.get('Auto_Shopper').getRecordTypeId();
        List<Contact> contactsToUpdate = new List<Contact> ();
        for(Integer i = 0; i < 10; i++) {
            if(math.mod(i, 2)==0){
                contactsToUpdate.add(new Contact(LastName = 'Contact' + i, AccountId = acc.Id,  FirstName = 'Test', Title='Test Title', Phone='+1006677554'+i, MobilePhone = '+1664488990'+i, Email = 'Testcon@gmail.com', RecordTypeId = dealerProRecordTypeId));
            }else {
                contactsToUpdate.add(new Contact(LastName = 'Contact' + i, FirstName = 'Test', Title='Test Title', Phone='+1006677554'+i, MobilePhone = '+1664488990'+i, Email = 'Testcon@gmail.com', RecordTypeId = autoShopperRecordTypeId));  
            }
        }  
        insert contactsToUpdate;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp To Insert'; 
        opp.Vehicle_VIN__C = '645466';
        opp.AccountId = acc.Id; 
        opp.ForecastCategoryName ='Omitted'; 
        opp.Card_Number__c = '7878678767877898'; 	
        opp.Probability= 0; 
        opp.CloseDate = Date.newInstance(2024, 08, 12); 
        opp.Dealer__c = acc.Id; 
        opp.StageName = 'New';  
        opp.Auto_Shopper__c = contactsToUpdate[1].Id;
        insert opp;
        
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "vehicleAdditionToGarage", "LoanId" : "7878678767877898", "FastPassDealerId" : "1202434" , "VehicleVIN" : "645466", "VehicleName" : "Thar", "Year": 2014}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void vehicleAdditionwithoutOppTest(){
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "vehicleAdditionToGarage", "LoanId" : "7878678767877898", "FastPassDealerId" : "1202434" , "VehicleVIN" : "645466", "VehicleName" : "Thar", "Year": 2014}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
        
        RestRequest request1 = new RestRequest();
        request1.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request1.addHeader('Content-Type', 'application/json');
        request1.requestBody = Blob.valueOf('[{"RequestType" : "vehicleRemovalInGarage", "LoanId" : "7878678767877898", "FastPassDealerId" : "1202434" , "VehicleVIN" : "645466", "VehicleName" : "Thar", "Year": 2014}]');
        RestContext.request = request1;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList2 = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void vehicleAdditionUpdateTest() {
       Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323', Active__c = false); 
        insert gar;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "vehicleAdditionToGarage", "LoanId" : "7878678767877898", "FastPassDealerId" : "1202434" , "VehicleVIN" : "VIN645466", "VehicleName" : "Thar", "Year": 2014}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    
    @isTest
    static void vehicleRemovalTest() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "vehicleRemovalInGarage", "LoanId" : "78786787678778980" , "VehicleVIN" : "645466"}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void vehicleAdditionNullParams() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "vehicleAdditionToGarage", "LoanId" : null, "FastPassDealerId" : null , "VehicleVIN" : null, "VehicleName" : null, "Year": null}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void vehicleRemovalNullParams() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "vehicleRemovalInGarage", "LoanId" : null, "VehicleVIN" : null}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void requestForTestDriveNullParams() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDrive", "LoanId" : null, "FastPassDealerId" : null , "VehicleVIN" : null, "TestDriveDate" : null, "VehicleName": null, "MemberQuery" : null}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void askDealerNullParams() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "askDealer", "LoanId" : null, "FastPassDealerId" : null,  "VehicleName": null, "VehicleVIN" : null, "MemberQuery" : null}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void requestTestDriveResponseNullParams() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDriveConversation", "LoanId" : null, "FastPassDealerId" : null, "VehicleVIN" : null, "PageNumber" : null}]');
        RestContext.request = request;
        
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();
        request.requestUri = '/FastPassIntegrationService';
        responseList = FastPassIntegrationService.doPost();
    }
    
    @isTest
    static void testAskDealerResponseNullparams() {
        createTestData();
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"RequestType" : "askDealerConversation", "LoanId" : null, "FastPassDealerId" : null, "VehicleVIN" : null, "PageNumber" : null}]');
        RestContext.request = request;
        List<FastPassIntegrationService.CreateResponseWrapper> responseList = FastPassIntegrationService.doPost();        
        request.requestUri = '/FastPassIntegrationService';
        responseList = FastPassIntegrationService.doPost();
        System.assertNotEquals(null, responseList);
        System.assert(responseList.size() > 0);
    }
    @isTest
    static void accountHelperClassCodeCoverage(){
         Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = accountDescribe.getRecordTypeInfosByDeveloperName();
        Id autoDealerRecordTypeId = recordTypeMap.get('Auto_Dealer').getRecordTypeId();
        Id bankRecordTypeId = recordTypeMap.get('Bank').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        List<Account> accountsToUpdate = new List<Account>();
        for (Integer i = 0; i < 20; i++) {
            accountsToUpdate.add(new Account(
                Name = 'Test Account ' + i,
                Market__c = 'Nocal',
                Active__c = true,
                Phone = '+19900887766',
                Manager_Cell_Phone__c = '+10077881199',
                RecordTypeId = autoDealerRecordTypeId,
                BillingStreet = 'Test Street',
                BillingPostalCode = '09089',
                BillingCity = 'Test City',
                FastPass_Dealer_Id__c = '1202434'+i,
                BillingState = 'LA',
                Manager_Name__c = 'Test Manger',
                Website = 'www.test.com',
                Brand__c = 'Test Brand',
                Lead_MSR_Cell_Phone__c = '+11100229988',
                Project_Manager_Cell_Phone__c = '+12200998877',
                F_I_Manager_Cell_Phone__c = '+13399008877'   
            ));
        }
        insert accountsToUpdate;
        system.debug('Accounts Inserted::'+ accountsToUpdate);
        Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap1 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id autoShopperRecordTypeId = recordTypeMap1.get('Auto_Shopper').getRecordTypeId();
        Id dealerProRecordTypeId = recordTypeMap1.get('Auto_Dealer_Pro').getRecordTypeId();
        List<Contact> contactsToUpdate = new List<Contact> ();
        for(Integer j = 0; j < 20; j++) {
            if(Math.mod(j, 2) == 0){
                contactsToUpdate.add(new Contact(LastName = 'Contact' + j, Active__c = true, AccountId = accountsToUpdate[j].Id,  FirstName = 'Test', Title='Test Title', Phone='+1006677554'+j, MobilePhone = '+1664488990'+j, Email = 'Testcon@gmail.com', RecordTypeId = dealerProRecordTypeId));
                
            } else{
                contactsToUpdate.add(new Contact(LastName = 'Contact' + j, Active__c = false, FirstName = 'Test', Title='Test Title', Phone='+1006677554'+j, MobilePhone = '+1664488990'+j, Email = 'Testcon'+ j + '@gmail.com', RecordTypeId = autoShopperRecordTypeId));
            }
        }
        insert contactsToUpdate;
        system.debug('Contacts Inserted::'+ contactsToUpdate);
        system.debug('Contact Name::' +  contactsToUpdate[1].LastName);
        List<Opportunity> oppList = new List<Opportunity> ();
        for(integer k=0; k<=20; k++){
            
            oppList.add(new opportunity(Name = 'Test Opp '+k, Vehicle_VIN__C = '645466',AccountId = accountsToUpdate[0].Id, ForecastCategoryName ='Omitted', Card_Number__c = '1878678767877898'+k, 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), Dealer__c = accountsToUpdate[0].Id, StageName = 'New',  Auto_Shopper__c = contactsToUpdate[1].Id ));
        }
        insert oppList;
        
        Garage__c gar = new Garage__c ();
        gar.Active__c = true;
        gar.Dealer__c = accountsToUpdate[0].Id; 
        gar.Dealer_Email_Available__c = false;
        gar.Dealer_pro_1__c = contactsToUpdate[0].Id;
        gar.Dealer_pro_2__c = contactsToUpdate[2].Id;
        gar.Dealer_pro_3__c = contactsToUpdate[4].Id;
        gar.VIN__c = '645466';
        gar.Fastpass_Dealer_Id__c = '202434';
        gar.Pending_Requests__c = 'Subject++ Test Pending Request Subject Body++ Test Pending Request Body Contains ?q=opportunityId, dealerId ">click here Type++ testDrive;;Subject++ Test Pending Request Subject1 Body++ Test Pending Request Body1 Contains ?q=opportunityId, dealerId ">click here Type++ testDrive';
        gar.Year__c = 2014;
        gar.Opportunity__c = oppList[0].Id;
        gar.Name = 'Thar';
        
        insert gar;
        
        system.debug('Opportunities Inserted::'+ oppList);
        Opportunity opp = [SELECT Id, Name, Card_Number__c, Auto_Shopper__r.Name from Opportunity where Id =: oppList[0].Id];
        String subjectPattern = 'Query requested by ' +opp.Auto_Shopper__r.Name+ ' for '+'#' +  opp.Card_Number__c + ' in #' +'645466';
        String subjectPattern1 = 'Test Drive requested by ' +opp.Auto_Shopper__r.Name +' for '+'#' +  opp.Card_Number__c + ' in #' +'645466';
        // Create EmailMessages related to the Opportunity
        system.debug('Subject Pattern in test class:: ' +subjectPattern1);
        system.debug('Subject Pattern in test class:: ' +subjectPattern);
        EmailMessage emailMessage = new EmailMessage ();
       
        emailMessage.Subject=subjectPattern1; 
        emailMessage.ToAddress='testmanager@test.com'; 
        emailMessage.CCAddress='Testcon@gmail.com'; 
        emailMessage.FromAddress='test@example.com'; 
        emailMessage.Status='3'; 
        emailMessage.HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="'; 
        emailMessage.RelatedToId=gar.Id;
           
        
        insert emailMessage;   
        
       Test.StartTest();
        List<Account> accToUpdate = new List<Account>();
        for(Account each:accountsToUpdate){
            each.Active__c = true;
            each.Manager_Email__c = 'testmanager@test.com';
            accToUpdate.add(each);
        }
        update accToUpdate;
        
        List<Contact> conToUpdate = new List<Contact>();
        for(Contact con:contactsToUpdate){
            if(Math.mod(contactsToUpdate.size(), 2) == 0){
            con.Title = 'Test-Title';
            con.Active__c = false;
            conToUpdate.add(con);
            } else {
            con.Title = 'Test-Title';
            con.Active__c = true;
            conToUpdate.add(con);
            }
        }
        
        update conToUpdate;
        delete oppList;
        delete conToUpdate;
        delete accToUpdate;
        
        Test.StopTest();
    }
    
    @isTest
   static void contactHelperClassCodeCoverage(){
         Test.StartTest();
        Schema.DescribeSObjectResult accountDescribe = Account.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap = accountDescribe.getRecordTypeInfosByDeveloperName();
        Id autoDealerRecordTypeId = recordTypeMap.get('Auto_Dealer').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        List<Account> accountsToUpdate = new List<Account>();
        for (Integer i = 0; i < 20; i++) {
            accountsToUpdate.add(new Account(
                Name = 'Test Account ' + i,
                Market__c = 'Nocal',
                Active__c = true,
                Phone = '+19900887766',
                Manager_Cell_Phone__c = '+10077881199',
                RecordTypeId = autoDealerRecordTypeId,
                BillingStreet = 'Test Street',
                BillingPostalCode = '09089',
                BillingCity = 'Test City',
                FastPass_Dealer_Id__c = '2202434'+i,
                BillingState = 'LA',
                Manager_Name__c = 'Test Manger',
                Website = 'www.test.com',
                Brand__c = 'Test Brand',
                Lead_MSR_Cell_Phone__c = '+11100229988',
                Project_Manager_Cell_Phone__c = '+12200998877',
                F_I_Manager_Cell_Phone__c = '+13399008877'   
            ));
        }
        insert accountsToUpdate;
        system.debug('Accounts Inserted::'+ accountsToUpdate);
       
        Garage__c gar = new Garage__c ();
        gar.Active__c = true;
        gar.Dealer__c = accountsToUpdate[0].Id; 
        gar.Dealer_Email_Available__c = false;
        gar.VIN__c = '645466';
        gar.Fastpass_Dealer_Id__c = '202434';
        gar.Pending_Requests__c = 'Subject++ Test Pending Request Subject Body++ Test Pending Request Body Contains ?q=opportunityId, dealerId ">click here Type++ testDrive;;Subject++ Test Pending Request Subject1 Body++ Test Pending Request Body1 Contains ?q=opportunityId, dealerId ">click here Type++ testDrive';
        gar.Year__c = 2014;
       
        
         Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeMap1 = contactDescribe.getRecordTypeInfosByDeveloperName();
        Id autoShopperRecordTypeId = recordTypeMap1.get('Auto_Shopper').getRecordTypeId();
        Id dealerProRecordTypeId = recordTypeMap1.get('Auto_Dealer_Pro').getRecordTypeId();
        List<Contact> contactsToUpdate = new List<Contact> ();
        for(Integer j = 0; j < 20; j++) {
            if(Math.mod(j, 2) == 0){
                contactsToUpdate.add(new Contact(LastName = 'Contact' + j, Active__c = false, AccountId = accountsToUpdate[j].Id,  FirstName = 'Test', Title='Test Title', Phone='+1006677554'+j, MobilePhone = '+1664488990'+j, Email = 'Testcon@gmail.com', RecordTypeId = dealerProRecordTypeId));
                
            } else{
                contactsToUpdate.add(new Contact(LastName = 'Contact' + j, Active__c = false, FirstName = 'Test', Title='Test Title', Phone='+1006677554'+j, MobilePhone = '+1664488990'+j, Email = 'Testcon'+ j + '@gmail.com', RecordTypeId = autoShopperRecordTypeId));
            }
        }
        insert contactsToUpdate;
        system.debug('Contacts Inserted::'+ contactsToUpdate);
        system.debug('Contact Name::' +  contactsToUpdate[1].LastName);
        
        List<Opportunity> oppList = new List<Opportunity> ();
        for(integer k=0; k<=20; k++){
            
            oppList.add(new opportunity(Name = 'Test Opp '+k, Vehicle_VIN__C = '645466',AccountId = accountsToUpdate[0].Id, ForecastCategoryName ='Omitted', Card_Number__c = '2878678767877898'+k, 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), Dealer__c = accountsToUpdate[0].Id, StageName = 'New',  Auto_Shopper__c = contactsToUpdate[1].Id ));
        }
        insert oppList;
        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity Limit 1];
        gar.Opportunity__c = opportunityList[0].Id;
        gar.Name = 'Thar';
        insert gar;
        
        system.debug('Opportunities Inserted::'+ oppList);
        Opportunity opp = [SELECT Id, Name, Card_Number__c, Auto_Shopper__r.Name from Opportunity where Id =: oppList[0].Id];
        String subjectPattern = 'Query requested by ' +opp.Auto_Shopper__r.Name+ ' for '+'#' +  opp.Card_Number__c + ' in #' +'645466';
        String subjectPattern1 = 'Test Drive requested by ' +opp.Auto_Shopper__r.Name +' for '+'#' +  opp.Card_Number__c + ' in #' +'645466';
        // Create EmailMessages related to the Opportunity
        system.debug('Subject Pattern in test class:: ' +subjectPattern1);
        system.debug('Subject Pattern in test class:: ' +subjectPattern);
        EmailMessage emailMessage = new EmailMessage ();
       
        emailMessage.Subject=subjectPattern1; 
        emailMessage.ToAddress='testmanager@test.com'; 
        emailMessage.CCAddress='Testcon@gmail.com'; 
        emailMessage.FromAddress='test@example.com'; 
        emailMessage.Status='3'; 
        emailMessage.HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="'; 
        emailMessage.RelatedToId=gar.Id;
           
        
        insert emailMessage;   
        
      
        List<Account> accToUpdate = new List<Account>();
        for(Account each:accountsToUpdate){
            each.Active__c = true;
            each.Manager_Email__c = 'testmanager@test.com';
            accToUpdate.add(each);
        }
        update accToUpdate;
        
       List<Contact> conToUpdate = new List<Contact>();
        for(Contact con:contactsToUpdate){
            if(Math.mod(contactsToUpdate.size(), 2) == 0){
            con.Title = 'Test-Title';
            con.Active__c = true;
            conToUpdate.add(con);
            } else {
            con.Title = 'Test-Title';
            con.Active__c = true;
            conToUpdate.add(con);
            }
        }
        
        update conToUpdate;
        delete oppList;
        delete conToUpdate;
        delete accToUpdate;
        
        Test.StopTest();
    }

	@isTest
    static void testDriveRequestResponse(){
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323'); 
        insert gar;
        EmailMessage EM =  new EmailMessage(Subject='Query requested by Test Member for #7878678767877898 in #VIN645466', ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="', RelatedToId=gar.Id);
		insert EM;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'Post';
        request.requestBody = Blob.valueOf('[{"RequestType" : "askDealerConversation", "LoanId" : "7878678767877898", "FastPassDealerId" : "2323", "VehicleVIN" : "VIN645466", "PageNumber" : 1}]');
        RestContext.request = request;
        FastPassIntegrationService.doPost();           
    }
    @istest
    static void askDealerRequestResponse(){
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323'); 
        insert gar;
        EmailMessage EM =  new EmailMessage(Subject='Test Drive requested by Test Member for #7878678767877898 in #VIN645466', ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="', RelatedToId=gar.Id);
		insert EM;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'Post';
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDriveConversation", "LoanId" : "7878678767877898", "FastPassDealerId" : "2323", "VehicleVIN" : "VIN645466", "PageNumber" : 1}]');
        RestContext.request = request;
        FastPassIntegrationService.doPost();        
    }
     @istest
    static void askDealerPendingRequestResponse(){
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323', Pending_Request_JSON__c = '{"askDealer":[{"VehicleVIN":"VIN75244","Sender":"Member","MarketCheckId":"123321","LoanId":"1234123443214321","EmailMessage":"Can you provide the full details of the mentioned vehicle including price, Millage and Vehicle Specifications","CreatedDate":"2024-09-05T04:39:53.311Z"}],"testDrive":[{"VehicleVIN":"VIN75244","Sender":"Member","MarketCheckId":"123321","LoanId":"1234123443214321","EmailMessage":"Can you provide the test drive for BMW M5 on 10th September 2024 at 03:45 AM. Can you please provide the test drive at home location 2","CreatedDate":"2024-09-05T04:44:48.133Z"}]}'); 
        insert gar;
        //EmailMessage EM =  new EmailMessage(Subject='Test Drive requested by Test Member for #7878678767877898 in #VIN645466', ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="', RelatedToId=gar.Id);
		//insert EM;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'Post';
        request.requestBody = Blob.valueOf('[{"RequestType" : "testDriveConversation", "LoanId" : "7878678767877898", "FastPassDealerId" : "2323", "VehicleVIN" : "VIN645466", "PageNumber" : 1}]');
        RestContext.request = request;
        FastPassIntegrationService.doPost();        
    }
    @isTest
    static void testDrivePendingRequestResponse(){
        Test.setMock(HttpCalloutMock.class, new MockFastPassIntegrationService());
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        Garage__c gar = new Garage__c(VIN__c = 'VIN645466', Name = 'Test Car', Opportunity__c = opp.Id, FastPass_Dealer_Id__c = '2323',Pending_Request_JSON__c = '{"askDealer":[{"VehicleVIN":"VIN75244","Sender":"Member","MarketCheckId":"123321","LoanId":"1234123443214321","EmailMessage":"Can you provide the full details of the mentioned vehicle including price, Millage and Vehicle Specifications","CreatedDate":"2024-09-05T04:39:53.311Z"}],"testDrive":[{"VehicleVIN":"VIN75244","Sender":"Member","MarketCheckId":"123321","LoanId":"1234123443214321","EmailMessage":"Can you provide the test drive for BMW M5 on 10th September 2024 at 03:45 AM. Can you please provide the test drive at home location 2","CreatedDate":"2024-09-05T04:44:48.133Z"}]}'); 
        insert gar;
       // EmailMessage EM =  new EmailMessage(Subject='Query requested by Test Member for #7878678767877898 in #VIN645466', ToAddress='testmanager@test.com', CCAddress='Testcon@gmail.com', FromAddress='test@example.com', Status='3', HtmlBody='Hi Aero Steel,<br/> Member Query: Can You provide the test drove at home location.Please <a href="', RelatedToId=gar.Id);
		//insert EM;
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/FastPassIntegrationService/';
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'Post';
        request.requestBody = Blob.valueOf('[{"RequestType" : "askDealerConversation", "LoanId" : "7878678767877898", "FastPassDealerId" : "2323", "VehicleVIN" : "VIN645466", "PageNumber" : 1}]');
        RestContext.request = request;
        FastPassIntegrationService.doPost();           
    }

}