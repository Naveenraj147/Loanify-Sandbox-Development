@isTest
private class LeadTriggerHelperTest {

 @TestSetup
 static void makeData(){
    Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Status = 'Open',
            Company = 'TestCompany',
            fastpass_Dealer_Id__c = '1234'
        );
        Id autoShopperRecordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Shopper').getRecordTypeId();
        Contact contact = new Contact(
            FirstName = 'Johnny',
            LastName = 'Doe',
            RecordTypeId = autoShopperRecordTypeId
        );
        insert contact;
        insert lead;
        Opportunity opp = new Opportunity( Auto_Shopper__c = contact.Id, Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.newInstance(2024, 08, 12), Probability = 0, Card_Number__c = '1234567891234567');
        insert opp;
    Garage__c garage = new Garage__c(
            Name = 'Test Garage',
            Lead_Dealer__c = lead.Id,
            VIN__c = 'VIN123',
            FastPass_Vehicle_Id__c = 2345,
            FastPass_Dealer_Id__c = '12345',
            Opportunity__c = opp.Id,
            Pending_Requests__c = 'Subject++ Test Pending Request Subject Body++ Test Pending Request Body Type++ testDrive;;Subject++ Test Pending Request Subject1 Body++ Test Pending Request Body1 Type++ testDrive'

        );
        insert garage;
    
 }   

@isTest
    static void testprocessEmailUpdatedLeads() {
        Lead lead = [SELECT Id, Email, Manager_Email__c, Manager_Name__c FROM Lead LIMIT 1];
            Test.startTest();
            lead.Manager_Email__c = 'testt@xyz.com';
            lead.Dealer_pro_1_Email__c = 'testt@xyz.com';
            lead.Dealer_Pro_1_Name__c = 'Dealer Pro 1';
            lead.Dealer_pro_2_Email__c = 'testt@xyz.com';
            lead.Dealer_Pro_2_Name__c = 'Dealer Pro 2';
            lead.Dealer_pro_3_Email__c = 'testt@xyz.com';
            lead.Dealer_Pro_3_Name__c = 'Dealer Pro 3';
            lead.GM_Email__c = 'testGM@xyz.com';
            lead.GM_Name__c  = 'Test GM';
            lead.Finance_Director_Email__c = 'testFD@xyz.com';
            lead.Finance_Director_Name__c  = 'Test FD';
            lead.Manager_Email__c = 'testManager@xyz.com';
            lead.Manager_Name__c  = 'Test Manager';
            lead.GSM_Name__c  = 'Test GSM';
            lead.GSM_Email__c = 'testgsm@xyz.com';
            lead.Business_Manager_Email__c = 'testBM@xyz.com';
            lead.Business_Manager_Name__c  = 'Test BM';
            lead.F_I_Email__c = 'testFI@xyz.com';
            lead.F_I_Manager_Name__c  = 'Test FI';
            update lead;

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus('Dealer Agreement Signed');
            Database.convertLead(lc);
            Test.stopTest();
        
    }

    @isTest
    static void testContactCreationfromLeads() {

        Id creditUnionRecordTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Credit_Union').getRecordTypeId();

        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Status = 'Open',
            Company = 'TestCompany',
            fastpass_Dealer_Id__c = '12345',
            Contact_1_Name__c = 'Test Contact 1',
            Contact_2_Name__c = 'Test Contact 2',
            Contact_3_Name__c = 'Test Contact 3',
            Contact_4_Name__c = 'Test Contact 4',
            Contact_1_Email__c = 'test1q@xyz.com',
            Contact_2_Email__c = 'test2q@xyz.com',
            Contact_3_Email__c = 'test3q@xyz.com',
            Contact_4_Email__c = 'test4q@xyz.com',
            CEO_Name__c = 'CEO',
            CFO_Name__c = 'CFO',
            CLO_Name__c = 'CLO',
            CExO_Name__c = 'CExO',
            CTO_Name__c = 'CTO',
            COO_Name__c = 'COO',
            CMO_Name__c = 'CMO',
            CIO_Name__c = 'CIO',
            CRO_Name__c = 'CRO',
            Project_Manager_Name__c = 'Project Manager',
            Lead_MSR_Name__c = 'Lead MSR',
            CEO_Email__c = 'test5q@xyz.com',
            CFO_Email__c = 'test6q@xyz.com',
            CLO_Email__c = 'test7q@xyz.com',
            CExO_Email__c = 'test8q@xyz.com',
            CTO_Email__c = 'test9q@xyz.com',
            COO_Email__c = 'test10q@xyz.com',
            CMO_Email__c = 'test11q@xyz.com',
            CIO_Email__c = 'test12q@xyz.com',
            CRO_Email__c = 'test13q@xyz.com',
            Project_Manager_Email__c = 'test14q@xyz.com',
            Lead_MSR_Email__c = 'test15q@xyz.com',
            RecordTypeId = creditUnionRecordTypeId
        );
        Test.startTest();
        insert lead;

        Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus('Agreement Signed');
            Database.convertLead(lc);
            Test.stopTest();
    }   
    
}