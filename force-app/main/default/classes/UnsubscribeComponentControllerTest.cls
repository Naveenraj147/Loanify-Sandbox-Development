@isTest
public class UnsubscribeComponentControllerTest {
    
        @testSetup
        static void setupTestData() {
            Account acc = new Account(Name = 'Test Account');
            insert acc;
    
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@example.com',
                AccountId = acc.Id,
                Member_SMS_Notifications__c = true,
                Member_Email_Notifications__c = true,
                FastPass_Team_Email_Support__c = true,
                FastPass_Team_SMS_Support__c = true
            );
            insert con;
    
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Dealer_SMS_Notifications__c = true,
                Dealer_Email_Notifications__c = true,
                Credit_Union_Email_Notifications__c = true,
                Credit_Union_SMS_Notifications__c = true,
                FastPass_Team_Email_Support__c = true,
                FastPass_Team_SMS_Support__c = true
            );
            insert opp;
        }
    
        @isTest
        static void testGetContactDetails() {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            List<Contact> contacts = UnsubscribeComponentController.getContactDetails(acc.Id);
            System.assert(!contacts.isEmpty(), 'Expected non-empty contact list');
        }
    
        @isTest
        static void testGetUnsubscribeDetails_Contact() {
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            Map<String, Object> inputMap = new Map<String, Object>{
                'recordId' => con.Id,
                'objectName' => 'Contact'
            };
            String response = UnsubscribeComponentController.getUnsubscribeDetails(JSON.serialize(inputMap));
            System.assertNotEquals(null, response);
            System.debug('Contact Unsubscribe Details: ' + response);
        }
    
        @isTest
        static void testGetUnsubscribeDetails_Opportunity() {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Map<String, Object> inputMap = new Map<String, Object>{
                'recordId' => opp.Id,
                'objectName' => 'Opportunity'
            };
            String response = UnsubscribeComponentController.getUnsubscribeDetails(JSON.serialize(inputMap));
            System.assertNotEquals(null, response);
            System.debug('Opportunity Unsubscribe Details: ' + response);
        }
    
        @isTest
        static void testUpdatePreferences_Contact() {
            Contact con = [SELECT Id FROM Contact LIMIT 1];
            Map<String, Object> smsMap = new Map<String, Object>{
                'mn' => false,
                'fpn' => false
            };
            Map<String, Object> emailMap = new Map<String, Object>{
                'mn' => false,
                'fpn' => false
            };
            Map<String, Object> inputMap = new Map<String, Object>{
                'recordId' => con.Id,
                'objectName' => 'Contact',
                'SMS' => smsMap,
                'Email' => emailMap
            };
            String result = UnsubscribeComponentController.updatePreferences(JSON.serialize(inputMap));
            System.assertEquals('Success', result);
        }
    
        @isTest
        static void testUpdatePreferences_Opportunity() {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            Map<String, Object> smsMap = new Map<String, Object>{
                'dn' => false,
                'cun' => false,
                'fpn' => false
            };
            Map<String, Object> emailMap = new Map<String, Object>{
                'dn' => false,
                'cun' => false,
                'fpn' => false
            };
            Map<String, Object> inputMap = new Map<String, Object>{
                'recordId' => opp.Id,
                'objectName' => 'Opportunity',
                'SMS' => smsMap,
                'Email' => emailMap
            };
            String result = UnsubscribeComponentController.updatePreferences(JSON.serialize(inputMap));
            System.assertEquals('Success', result);
        }
    
        @isTest
        static void testUpdatePreferences_InvalidInput() {
            String result = UnsubscribeComponentController.updatePreferences('{}');
            System.assertEquals('Error', result);
        }
}
    