@isTest
private class CustomerEmailHandlerTest {
    @isTest
    static void testHandleInboundEmail() {
        // Creating test Contact (Auto Shopper)
        Contact testCon = new Contact(FirstName = 'Test', LastName = 'Contact1', Email = 'testconemail@gmail.com', RecordTypeId = '012Hs000000Ew7lIAC');
        insert testCon;
        
        // Creating test Opportunity
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', Card_Number__c = '1234597890123456', StageName = 'Prospect', CloseDate = system.Today().addMonths(5), Auto_Shopper__c = testCon.Id);
        insert testOpp;
        
        // Creating test inbound email
        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Subject 1234597890123456';
        testEmail.htmlBody = 'Test HTML Body';
        testEmail.plainTextBody = 'Test Plain Text Body';
        testEmail.fromAddress = 'testsender@example.com';
        // Creating test inbound envelope
        Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
        //testEnvelope.fromAddress = 'test@example.com';
        //testEnvelope.toAddress = 'test@yourorg.com';
        
        // Creating test email headers
        List<Messaging.InboundEmail.Header> testHeaders = new List<Messaging.InboundEmail.Header>();
        
        // Header for 'From'
        Messaging.InboundEmail.Header fromHeader = new Messaging.InboundEmail.Header();
        fromHeader.name = 'From';
        fromHeader.value = '"Test Sender" <testsender@example.com>';
        testHeaders.add(fromHeader);
        
        // Header for ToAddress 
        Messaging.InboundEmail.Header ToHeader = new Messaging.InboundEmail.Header();
        fromHeader.name = 'To';
        fromHeader.value = '<test@yourorg.com>';
        testHeaders.add(ToHeader);
        
        // Header for 'Cc
        Messaging.InboundEmail.Header ccHeader = new Messaging.InboundEmail.Header();
        ccHeader.name = 'Cc';
        ccHeader.value = 'testccaddress1@gmail.com'+','+'testaccaddress2@gmail.com';
        testHeaders.add(ccHeader);
        // Adding test headers to the email
        testEmail.headers = testHeaders;
        
        // Creating test binary attachment
        Messaging.InboundEmail.BinaryAttachment testAttachment = new Messaging.InboundEmail.BinaryAttachment();
        testAttachment.fileName = 'TestAttachment.txt';
        testAttachment.body = Blob.valueOf('Test attachment body');
        
        // Adding test attachment to the email
        testEmail.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{testAttachment};
            
        // Calling handleInboundEmail method
        Test.startTest();
        CustomerEmailHandler handler = new CustomerEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(testEmail, testEnvelope);
        Test.stopTest();
        
        // Retrieving created EmailMessage
        EmailMessage[] emailMessages = [SELECT Id, RelatedToId, Subject, HtmlBody, TextBody, MessageDate, FromName, FromAddress, BccAddress, CcAddress FROM EmailMessage];
        
        // Asserting that an EmailMessage was created
        System.assertEquals(1, emailMessages.size(), 'An EmailMessage should have been created');
        
        // Asserting the values of the created EmailMessage
        EmailMessage createdEmail = emailMessages[0];
        System.assertEquals(testOpp.Id, createdEmail.RelatedToId, 'RelatedToId should match the Opportunity Id');
        System.assertEquals(testEmail.subject, createdEmail.Subject, 'Subject should match the email subject');
        System.assertEquals(testEmail.htmlBody, createdEmail.HtmlBody, 'HtmlBody should match the email html body');
        System.assertEquals(testEmail.plainTextBody, createdEmail.TextBody, 'TextBody should match the email plain text body');
        
        // Retrieving created Attachment
        Attachment[] attachments = [SELECT Id, Name, ParentId FROM Attachment];
        
        // Asserting that an Attachment was created
        System.assertEquals(1, attachments.size(), 'An Attachment should have been created');
        
        // Asserting the values of the created Attachment
        Attachment createdAttachment = attachments[0];
        System.assertEquals(testAttachment.fileName, createdAttachment.Name, 'Attachment name should match');
        System.assertEquals(createdEmail.Id, createdAttachment.ParentId, 'Attachment ParentId should match the EmailMessage Id');
        
    }
     @isTest
    static void testHandleInboundEmailException() {
        // Creating test Contact (Auto Shopper)
        Contact testCon = new Contact(FirstName = 'Test', LastName = 'Contact1', Email = 'testconemail@gmail.com', RecordTypeId = '012Hs000000Ew7lIAC');
        insert testCon;
        
        // Creating test Opportunity
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', Card_Number__c = '1234597890123456', StageName = 'Prospect', CloseDate = system.Today().addMonths(5), Auto_Shopper__c = testCon.Id);
        insert testOpp;
        
        // Creating test inbound email
        Messaging.InboundEmail testEmail = new Messaging.InboundEmail();
        testEmail.subject = 'Test Subject 1234597890123456';
        testEmail.htmlBody = 'Test HTML Body';
        testEmail.plainTextBody = 'Test Plain Text Body';
        testEmail.fromAddress = 'testsender@example.com';
        // Creating test inbound envelope
        Messaging.InboundEnvelope testEnvelope = new Messaging.InboundEnvelope();
        //testEnvelope.fromAddress = 'test@example.com';
        //testEnvelope.toAddress = 'test@yourorg.com';
        
        // Creating test email headers
        List<Messaging.InboundEmail.Header> testHeaders = new List<Messaging.InboundEmail.Header>();
        
        // Header for 'From'
        Messaging.InboundEmail.Header fromHeader = new Messaging.InboundEmail.Header();
        fromHeader.name = 'From';
        fromHeader.value = '"Test Sender" <testsender@example.com>';
        testHeaders.add(fromHeader);
        
        // Header for ToAddress 
        Messaging.InboundEmail.Header ToHeader = new Messaging.InboundEmail.Header();
        fromHeader.name = 'To';
        fromHeader.value = '<test@yourorg.com>';
        testHeaders.add(ToHeader);
        
        // Header for 'Cc
        Messaging.InboundEmail.Header ccHeader = new Messaging.InboundEmail.Header();
        ccHeader.name = 'cC';
        ccHeader.value = 'testccaddress1@gmail.com'+','+'testaccaddress2@gmail.com';
        testHeaders.add(ccHeader);
        // Adding test headers to the email
        testEmail.headers = testHeaders;
        
        // Creating test binary attachment
        Messaging.InboundEmail.BinaryAttachment testAttachment = new Messaging.InboundEmail.BinaryAttachment();
        testAttachment.fileName = 'TestAttachment.txt';
        testAttachment.body = Blob.valueOf('Test attachment body');
        
        // Adding test attachment to the email
        testEmail.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{testAttachment};
            
        // Calling handleInboundEmail method
        Test.startTest();
        CustomerEmailHandler handler = new CustomerEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(testEmail, testEnvelope);
        Test.stopTest();
        
    }
}