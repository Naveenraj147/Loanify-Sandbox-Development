@isTest
public class CallerListTableControllerTest {
    @testSetup
    static void createData(){
        /*Test.startTest();
System.runAs(new User(Id = UserInfo.getUserId())) {
MessagingChannel testChannel = new MessagingChannel(
MasterLabel = '+15126168756'
//  Name = 'Test Channel'
// Add any other required fields
);
insert testChannel;
}
Test.stopTest();
*/
        String recTypeIdContact = [SELECT Id,Name FROM RecordType WHERE Name = 'Auto Shopper' AND SObjectType = 'Contact' ORDER BY Name asc LIMIT 1].Id;
        
        contact con = new contact();
        con.LastName = 'test opp';
        con.Email = 'Test99@xyz.com';
        con.RecordTypeId = recTypeIdContact;
        insert con;
        
        Opportunity opp = new Opportunity();
        opp.Auto_Shopper__c = con.Id;
        opp.Name = 'test opp';
        opp.StageName = 'Prospecting';
        opp.CloseDate = system.today();
        
        insert opp;
        
        VoiceCall VC1 = new VoiceCall();
        VC1.CallCenterId = [SELECT Id, Name FROM CallCenter Limit 1].Id;
        VC1.VendorType = 'ContactCenter'; 
        VC1.CallType = 'Inbound';
        VC1.FromPhoneNumber = '+19999999999';
        VC1.ToPhoneNumber = '+19999999999';
        VC1.CallStartDateTime = System.now().addMinutes( - 3 );
        VC1.CallEndDateTime = System.now();
        VC1.CallDisposition = 'completed';
        VC1.RelatedRecordId = con.Id;
        VC1.Opportunity__c = opp.Id;
        insert VC1;
        
        VoiceCall VC2 = new VoiceCall();
        VC2.CallCenterId = [SELECT Id, Name FROM CallCenter Limit 1].Id;
        VC2.VendorType = 'ContactCenter'; 
        VC2.CallType = 'Outbound';
        VC2.FromPhoneNumber = '+19999999998';
        VC2.ToPhoneNumber = '+19999999998';
        VC2.CallStartDateTime = System.now().addMinutes( - 3 );
        VC2.CallEndDateTime = System.now();
        VC2.CallDisposition = 'completed';
        VC2.RelatedRecordId = con.Id;
        insert VC2;
        
        
        Id userId = UserInfo.getUserId(); // ID of the user for whom you want to create the presence record


        ServicePresenceStatus SPSList = [SELECT Id, DeveloperName, MasterLabel FROM ServicePresenceStatus Where ServicePresenceStatus.DeveloperName = 'All_Available'];
        
        
        
        UserServicePresence USP = new UserServicePresence();
        USP.UserId = UserId;
        USP.ServicePresenceStatusId = SPSList.Id;
        insert USP;
    }
    @isTest
    static void testGetContacts() {
        // Test data setup
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'TestFirstName' + i,
                LastName = 'TestLastName' + i,
                Phone = '123456789' + i,
                Email = 'test1'+ i +'@xyz.com'
            ));
        }
        insert contacts;
        
        String recTypeIdContact = [SELECT Id,Name FROM RecordType WHERE Name = 'Auto Shopper' AND SObjectType = 'Contact' ORDER BY Name asc LIMIT 1].Id;
        contact con = new contact();
        con.LastName = 'test opp';
        con.Email = 'Test993@xyz.com';
        con.RecordTypeId = recTypeIdContact;
        insert con;
        
        
        List<Contact> conList = [SELECT Id from Contact ];
        List<Opportunity> oppList = [SELECT Id from Opportunity ];
        List<MessagingChannel> MCList = [SELECT Id from MessagingChannel ];
        
        
        MessagingEndUser ME = new MessagingEndUser();
        ME.Name = 'Test Name';
        ME.MessageType = 'Text';
        ME.MessagingChannelId = MCList.size() > 0? MCList[0].Id:null;
        ME.MessagingConsentStatus = 'ImplicitlyOptedIn';
        ME.MessagingPlatformKey = contacts[0].Phone != null? contacts[0].Phone : contacts[0].MobilePhone;
        insert ME;
        
        CallerListTableController.navigateSMSPage(contacts[0].Id, oppList[0].Id);
        CallerListTableController.getRelatedCallLogs(oppList[0].Id);
        CallerListTableController.getVoiceCall(contacts[0].Id, oppList[0].Id);
        CallerListTableController.getOmniStatus();
        CallerListTableController.relateOppWithVoiceCall(oppList[0].Id, '+19999999998');
        // Call the method under test
        
        List<Contact> returnedContacts = CallerListTableController.getContacts();
   
    }
}