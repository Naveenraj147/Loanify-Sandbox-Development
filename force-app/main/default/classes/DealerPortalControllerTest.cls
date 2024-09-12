@isTest
public class DealerPortalControllerTest {


    @isTest
    static void testDealerPortalController() {
        
        Account dealerAccount = new Account(Name = 'Test Dealer', FastPass_Dealer_Id__c = '12345', Manager_Email__c = 'manager@test.com');
        insert dealerAccount;

        Contact dealerPro = new Contact(FirstName = 'Dealer', LastName = 'Pro', AccountId = dealerAccount.Id, Email = 'dealerpro@test.com', RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Dealer Pro').getRecordTypeId(), Active__c = true);
        insert dealerPro;
        
        Contact Member = new Contact(FirstName = 'Dealer', LastName = 'Pro', Email = 'dealerpro22@test.com', RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId(), Active__c = true);
        insert Member;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), Auto_Shopper__c = Member.Id, Card_Number__c = '1234');
        insert opp;

        Garage__c garage = new Garage__c(Name = 'Test Garage', VIN__c = 'VIN123456789', Opportunity__c = opp.Id, Dealer__c = dealerAccount.Id);
        insert garage;

        EmailMessage emailMsg = new EmailMessage(Subject = 'Test Drive Requested by Dealer Pro for #1234 in #VIN123456789', TextBody = 'Test Email Body', FromAddress = 'manager@test.com', ToAddress = 'dealerpro@test.com', RelatedToId = garage.Id);
        insert emailMsg;
        
        // Set the parameters for the controller
        PageReference pageRef = Page.DealerPortalPage; // Replace 'DealerPortal' with your actual Visualforce page name
        Test.setCurrentPage(pageRef);
        
        
        Map<String, Object> params = new Map<String, Object>();
            params.put('opportunityId', opp.Id);
            params.put('dealerId', dealerAccount.FastPass_Dealer_Id__c);
            params.put('vehicleVin', garage.VIN__c);
            params.put('vehicleName', garage.Name);
            params.put('type', 'testDrive');
            params.put('linkSharedDate', Date.today());
            params.put('garageId', garage.Id);
            
            // Convert to JSON string
            String jsonParams = JSON.serialize(params);
        
        ApexPages.currentPage().getParameters().put('id', garage.Id);
       // ApexPages.currentPage().getParameters().put('q', CryptoUtility.encrypt(jsonParams));
        
        // Instantiate the controller
        DealerPortalController controller = new DealerPortalController();
        
        // Test initialization and data loading
       
        
        // Test loading conversations
        controller.handlePicklistChange();
       

        // Test sending a message
        controller.newMessage = 'This is a test response';
        controller.selectedDealer = 'Agent'; // Assuming Agent is the key for a valid dealer in the dealerNameEmailMap
        controller.sendMessage();
        controller.loadDealerOptions('12345');
        
       
    }

}