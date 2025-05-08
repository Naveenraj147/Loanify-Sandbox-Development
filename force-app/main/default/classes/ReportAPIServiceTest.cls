@isTest
public class ReportAPIServiceTest {
	@testSetup
    public static void testData(){
        Id autoShopperRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Auto Shopper').getRecordTypeId();
        Contact con = new Contact(LastName = 'Test Member', RecordTypeId = autoShopperRecordTypeId);
        insert con;
        Opportunity opp = new opportunity(Name = 'Test Opp ', Lender_Id__c = '80', Vehicle_VIN__C = 'VIN645466', ForecastCategoryName ='Omitted', Card_Number__c = '7878678767877898', 	Probability= 0, CloseDate = Date.newInstance(2024, 08, 12), StageName = 'New',  Auto_Shopper__c = con.Id );
		insert opp;
        tdc_tsw__Message__c msg = new tdc_tsw__Message__c(Name = 'Outgoing',tdc_tsw__Sender_Number__c = '+11234567890', tdc_tsw__Message_Text_New__c = 'Test' );
		insert msg;
    }

	@IsTest
    public static void getOppCountTest() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03",'+
            	'"requestType":"getLoanCount",'+
                '"reportEndDate":"2025-05-05",'+
                '"creditUnionId":"80"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
	@IsTest
    public static void getOppCountParamMissingTest() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"requestType":"getLoanCount"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    @IsTest
    public static void getOppCountParmEmptyTest() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"",'+
            	'"requestType":"getLoanCount",'+
                '"reportEndDate":"",'+
                '"creditUnionId":""'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    
    @IsTest
    public static void getSMSOptCount() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03",'+
            	'"requestType":"getSMSOptCount",'+
                '"reportEndDate":"2025-05-05",'+
                '"creditUnionId":"80"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    @IsTest
    public static void getCallCount() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03",'+
            	'"requestType":"getCallCount",'+
                '"reportEndDate":"2025-05-05",'+
                '"creditUnionId":"80"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    @IsTest
    public static void getCallDuration() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03",'+
            	'"requestType":"getCallDuration",'+
                '"reportEndDate":"2025-05-05",'+
                '"creditUnionId":"80"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    @IsTest
    public static void getSMSDetails() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03",'+
            	'"requestType":"getSMSDetails",'+
                '"reportEndDate":"2025-05-05",'+
                '"creditUnionId":"80"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    @IsTest
    public static void getEmailDetailsTest() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03",'+
            	'"requestType":"getEmailDetails",'+
                '"reportEndDate":"2025-05-05",'+
                '"creditUnionId":"80"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
    @IsTest
	public static void exceptionTest() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{"reportStartDate":"2025-03-03"'+
            	'"requestType":"getEmailDetails",'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(500, res.statusCode);
    }
    @IsTest
    public static void getEmailDetailsParamMissingTest() {
        // Creating a sample REST request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ReportAPIService/'; //Request URL
        req.httpMethod = 'POST';
        
        String inputJson = '{'+
            	'"requestType":"getEmailDetails"'+
                '}';
        req.requestBody = Blob.valueOf(inputJson);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ReportAPIService.doPost();
        Test.stopTest();
        System.assertEquals(200, res.statusCode);
    }
}