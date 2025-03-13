@RestResource(urlMapping='/FastPassIntegrationService/*')
global with sharing class FastPassIntegrationService {
    @HttpPost
    global static List<CreateResponseWrapper> doPost() {
        List<CreateResponseWrapper> responseList = new List<CreateResponseWrapper>();
        try {
            RestRequest req = RestContext.request;
            // Explicitly deserialize the JSON request body as a list of map
            List<Object> rawRequestBodyList = (List<Object>) JSON.deserializeUntyped(req.requestBody.toString());
            List<Map<String, Object>> requestBodyList = new List<Map<String, Object>>();
            
            for (Object obj : rawRequestBodyList) {
                requestBodyList.add((Map<String, Object>) obj);
            }
            
            for (Map<String, Object> requestBody : requestBodyList) {
                CreateResponseWrapper wrapper = new CreateResponseWrapper();
                String requestType = (String) requestBody.get('RequestType');
                system.debug('requestType ==>' + requestType );
                system.debug('requestType ==>' + requestType == 'askDealerConversation' );
                if (requestType == 'askDealer') {
                    wrapper = requestForTestDrive(requestBody);
                }
                 else if (requestType == 'askDealerConversation') {
                    system.debug('Inside  askDealerConversation ==>' );
                    requestBody.put('PortalType', 'Dealer');
                    wrapper = requestTestDriveResponse(requestBody);
                }
                 else if (requestType == 'vehicleAdditionToGarage'){
                    wrapper = vehicleAddition(requestBody);
                }
                else if (requestType == 'vehicleRemovalInGarage'){
                    wrapper = vehicleRemovalInGarage(requestBody);
                } 
                else if (requestType == 'defaultMemberMessage'){
                     wrapper = sendRightSwipeNotification(requestBody);
                 }
                 else if(requestType == 'askMSR'){
                    wrapper = requestMSRMessage(requestBody);
                 }
                 else if (requestType == 'askAdvisor') {
                    requestBody.put('PortalType', 'Advisor');
                    wrapper = requestMSRMessage(requestBody);
                }
                else if (requestType == 'askMSRConversation') {
                    requestBody.put('PortalType', 'MSR');
                    wrapper = requestTestDriveResponse(requestBody);
                }
                else if (requestType == 'askAdvisorConversation') {
                    requestBody.put('PortalType', 'Advisor');
                    wrapper = requestTestDriveResponse(requestBody);
                }
                else if (requestType == 'topFiveList') {
                    wrapper = processTopFiveList(requestBody);
                }
                else {
                    wrapper.error = new Map<String, String>{'Message' => 'Could not find a match for RequestType'};
                        wrapper.success = new SuccesWrapper() ;
                    sendErrorEmail('Failed to ' + requestType, JSON.serialize(wrapper.error));
                }
               
                responseList.add(wrapper);
            }
            return responseList;  
        } catch (Exception e) {
            // Handling Exceptions and returning an error message
            RestResponse res = RestContext.response;
            res.statusCode = 500;
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            CreateResponseWrapper wrapper = new CreateResponseWrapper();
            wrapper.error = new Map<String, String>{'exception' => 'An internal error has occurred.'};
                wrapper.success = new SuccesWrapper();
            System.debug('Exception:' + errorMessage);
            sendErrorEmail('failed to process request', errorMessage);
            responseList.add(wrapper);
            return responseList;
        }
    }
    
    global static CreateResponseWrapper vehicleAddition(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN'); 
            String vehicleName = (String) requestBody.get('VehicleName');
            Integer modelYear = (Integer) requestBody.get('ModelYear');
            Integer fastpassVehicleId =  Integer.valueOf(requestBody.get('fastpassVehicleId'));
            Integer price = (Integer) requestBody.get('Price');
            String stockNumber = (String) requestBody.get('StockNumber');
            String model = (String) requestBody.get('Model');
            String make = (String) requestBody.get('Make');
            String chatId = (String) requestBody.get('ChatId');
            String chatLink;
            List<String> blankFields = new List<String>();
            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            if (String.isBlank(dealerMarketcheckId)) {
                blankFields.add('FastPassDealerId');
            }
            if (String.isBlank(vehicleVIN)) {
                blankFields.add('vehicleVIN');
            }
            if (String.isBlank(vehicleName)) {
                blankFields.add('vehicleName');
            }
            if (fastpassVehicleId == null) {
                blankFields.add('fastpassVehicleId');
            }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('Failed to process vehicleAddition', 'Required fields are missing: '+nullFields +'<br/> Request Type: vehicleAdditionToGarage');
                return wrapper;
            }
            
            
            List<Opportunity> oppList = [SELECT Id, Name, Card_Number__c, Auto_Shopper__r.FirstName, Auto_Shopper__r.RecordType.DeveloperName FROM Opportunity WHERE Card_Number__c =: memberLoanId LIMIT 1];
            SuccesWrapper wrapp = new SuccesWrapper();
            Garage__c garageRecord;
            if(oppList.size() > 0 ){
                Opportunity opp = oppList[0];
                List<Garage__c> garageList = [SELECT Id, Name, Active__c, VIN__c, FastPass_Vehicle_Id__c FROM Garage__c WHERE FastPass_Vehicle_Id__c =:fastpassVehicleId AND Opportunity__c =: opp.Id Limit 1 ];
                if (!garageList.isEmpty()){
                    Garage__c garage = garageList[0];
                    garageRecord = garage; 
                    if( garage.Active__c == false){
                        garage.Active__c = true;
                        update garage;
                        
                        wrapp.message = 'Vehicle successfully added into Garage';
                        wrapp.data = new List<CreateResponseWrapperSuccess>();
                        wrapper.success = wrapp;
                        wrapper.error = new Map<String, String>{};
                            return wrapper;
                    }
                }
                else {
                    List<Account> accList = [SELECT Id, Name, FastPass_Dealer_Id__c, Manager_Email__c, RecordType.DeveloperName FROM Account WHERE FastPass_Dealer_Id__c =: dealerMarketcheckId AND RecordType.DeveloperName = 'Auto_Dealer'];
                    List<Contact> conList;
                    List<Lead> leadList;
                    if(accList.size() > 0 ){
                        conList   = [SELECT Id, Name, AccountId, Active__c, RecordType.DeveloperName FROM Contact WHERE AccountId =: accList[0].Id AND RecordType.DeveloperName = 'Auto_dealer_Pro' AND Active__c = true order by CreatedDate asc];
                    }
                    else{
                        leadList = [SELECT Id, FastPass_Dealer_Id__c, Manager_Email__c, Manager_Name__c, Dealer_Pro_1_Email__c, Dealer_Pro_2_Email__c, Dealer_Pro_3_Email__c FROM Lead WHERE FastPass_Dealer_Id__c =: dealerMarketcheckId];
                    }
                    
                    garageRecord = createGarageRecord(dealerMarketcheckId, opp.Id, modelYear, vehicleVIN, vehicleName, accList, conList, fastpassVehicleId, make, model, stockNumber, price, leadList, chatId );
                    sendNotification('New Vehicle Added', opp.Auto_Shopper__r.FirstName+ ' added a new vehicle 🚘 to the garage', garageRecord.Id, null);
                }
                if(opp.Auto_Shopper__r.RecordType.DeveloperName == 'Auto_Shopper_Carbots'){
                    String dealerportalURL = system.label.Dealer_Portal_Page_URL;
                    // Create JSON object
                    Map<String, Object> params = new Map<String, Object>();
                    params.put('opportunityId', opp.Id);
                    params.put('dealerId', dealerMarketcheckId);
                    params.put('vehicleVin', vehicleVIN);
                    params.put('vehicleName', vehicleName);
                    params.put('type', 'testDrive');
                    params.put('linkSharedDate', Date.today()+30);
                    params.put('garageId', garageRecord.Id);
                    params.put('fastpassVehicleId', fastpassVehicleId);
                    params.put('isMember', true);
                    
                    // Convert to JSON string
                    String jsonParams = JSON.serialize(params);
                    wrapp.chatId = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
                    
                }
                
                
                wrapp.message = 'Vehicle successfully added into Garage';
                 
                wrapp.data = new List<CreateResponseWrapperSuccess>();
                wrapper.success = wrapp;
                wrapper.error = new Map<String, String>{};
            }
            else {
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId.'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('Failed to process vehicleAddition.', 'No matching opportunity found for the provided LoanId.'+'<br/>Request Type: vehicleAdditionToGarage <br/> VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>LoanId: '+memberLoanId);
            }
            return wrapper;
        }
        catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('Failed to process vehicleAddition.',  errorMessage);
            return wrapper;
        }
        
    }
    
    public static Garage__c createGarageRecord(String dealerMarketcheckId, String oppId, Integer modelYear, String vehicleVIN, String vehicleName,  List<Account> accList, List<Contact> conList, Integer fastpassVehicleId, String make, String model, String stockNumber, Integer price, List<Lead> leadList, String chatId  ){
        //  List<Account> accList = [SELECT Id, Name, Marketcheck_Id__c, Manager_Email__c, RecordType.DeveloperName FROM Account WHERE Marketcheck_Id__c =: dealerMarketcheckId AND RecordType.DeveloperName = 'Auto_Dealer'];
        Garage__c garage = new Garage__c ();
        garage.Active__c = true;
        garage.Opportunity__c = oppId;
       	garage.FastPass_Dealer_Id__c = dealerMarketcheckId;
        garage.Year__c = modelYear;
        garage.VIN__c = vehicleVIN;
        garage.Name = vehicleName.length() > 80 ? vehicleName.substring(0, 80) : vehicleName;
        if(vehicleName.length() > 80 ){
            garage.Full_Name__c = vehicleName;
        }
        garage.FastPass_Vehicle_Id__c = fastpassVehicleId;
        garage.Make__c = make;
        garage.Model__c = model;
        garage.Price__c = price;
        garage.Stock_Number__c = stockNumber;
        garage.Chat_Id__c = chatId;
        
        if(accList.size() > 0){
            Account acc = accList[0];
            garage.Dealer__c = acc.Id;
            
            // List<Contact> conList = [SELECT Id, Name, AccountId, Active__c, RecordType.DeveloperName FROM Contact WHERE AccountId =: acc.Id AND RecordType.DeveloperName = 'Auto_dealer_Pro' AND Active__c = true Order by CreatedDate desc];
            
            
            if(acc.Manager_Email__c != null || !conList.isEmpty()){
                garage.Dealer_Email_Available__c = true;
            }
            else{
                garage.Dealer_Email_Available__c = false;
            }                        
            Integer conListSize = conList.Size();
            if(conListSize > 0){
                garage.Dealer_pro_1__c = conList[0].Id;
            }
            if(conListSize > 1){
                garage.Dealer_pro_2__c = conList[1].Id;
            }
            if(conListSize > 2){
                garage.Dealer_pro_3__c = conList[2].Id;
            }
        }
        else if(leadList.size() > 0){
            Lead lead = leadList[0];
            garage.Lead_Dealer__c = lead.Id;
            if(lead.Manager_Email__c != null || lead.Dealer_Pro_2_Email__c != null ||  lead.Dealer_Pro_2_Email__c != null || lead.Dealer_Pro_3_Email__c != null ){
                garage.Dealer_Email_Available__c = true;
            }
            else{
                garage.Dealer_Email_Available__c = false;
            } 

        }
        
        insert garage;
        return garage;
    }
    
    global static CreateResponseWrapper vehicleRemovalInGarage(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            Integer fastpassVehicleId = Integer.valueOf(requestBody.get('fastpassVehicleId')); 
            
            List<String> blankFields = new List<String>();
            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            
            if (fastpassVehicleId == null) {
                blankFields.add('fastpassVehicleId');
            }
            
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('Failed to process vehicleRemoval', 'Required fields are missing: '+nullFields+'<br/>Request Type: vehicleRemovalInGarage');
                return wrapper;
            }
            
            List<Opportunity> oppList = [SELECT Id, Name, Card_Number__c FROM Opportunity WHERE Card_Number__c =: memberLoanId LIMIT 1];
            
            if(oppList.size() > 0){
                Opportunity opp = oppList[0];
                List<Garage__c> garageList = [SELECT Id, Name, Active__c, VIN__c FROM Garage__c WHERE FastPass_Vehicle_Id__c =:fastpassVehicleId AND Opportunity__c =: opp.Id ];
                if(garageList.size() > 0 ){
                    Garage__c garage = garageList[0];
                    garage.Active__c = false;
                    update garage;
                    
                    SuccesWrapper wrapp = new SuccesWrapper();
                    wrapp.message = 'Vehicle removed successfully from Garage.';
                    wrapp.data = new List<CreateResponseWrapperSuccess>();
                    wrapper.success = wrapp;
                    wrapper.error = new Map<String, String>{};
                        }
                else{
                    wrapper.error = new Map<String, String>{'Message' => 'No matching vehicle is found in the garage.'};
                        wrapper.success = new SuccesWrapper();
                    sendErrorEmail('failed to process vehicleRemovalInGarage.', 'No matching vehicle is found in the garage. <br/>Request Type: vehicleRemovalInGarage<br/> FastpassVehicleId: '+fastpassVehicleId+'<br/>Opportunity Id: '+opp.Id);  
                }
            }
            else{
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId.'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process vehicleRemovalInGarage.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: vehicleRemovalInGarage<br/> FastpassVehicleId: '+fastpassVehicleId+'LoanId: '+memberLoanId);
            }
            
            return wrapper;
        }
        catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('failed to process vehicleRemovalInGarage.',  errorMessage );
            return wrapper;
        }
    }
   
    global class CreateResponseWrapper {
        public SuccesWrapper success;
        public Map<String,String> error;
    }
    global class SuccesWrapper{
        Public String message;
        Public List<CreateResponseWrapperSuccess> data;
        Public integer currentPage;
        Public integer totalPages;
        Public String chatId;
    }
    
    global class CreateResponseWrapperSuccess {
        Public String VehicleVIN;
        Public String LoanId;
        Public String MarketCheckId;
        Public DateTime CreatedDate;
        public String Sender;
        public String EmailMessage;
    }    
    global class CreateResponseWrapperSuccessJson {
        Public String VehicleVIN;
        Public String LoanId;
        Public String MarketCheckId;
        Public DateTime CreatedDate;
        public String Sender;
        public String EmailMessage;
        public String Email;
        public String Status;
        public String Subject;
        public String EmailType;


    }    

    public static void sendErrorEmail(String subjectReason, String exceptionMessage){
        
        if(String.isBlank(Label.Exception_Email_Recipients))        
            return;
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        String subject = 'FastPassIntegrationService - '+subjectReason;
        String body = 'Following exception has occurred in FastPassIntegrationService.<br/><br/> Exception: '+exceptionMessage+'<br/><br/>Regards,<br/>Admin';
        
        List<String> sendTo = new List<String>();
        List<String> emailIdsiLst;
        emailIdsiLst = Label.Exception_Email_Recipients.split(',');
        for(string each:emailIdsiLst){
            sendTo.add(each);
        }
        email.setToAddresses(sendTo);
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setSaveAsActivity(true); 
        emailList.add(email);
        if(!Test.isRunningTest() && emailList.size()>0){
            Messaging.sendEmail(emailList);
        }
    }

    @future(callout=true)
    public static void getAccessToken(){
        Salesforce_API__mdt metaSFAPI = Salesforce_API__mdt.getInstance('Salesforce_API');
        if(metaSFAPI == null || ( metaSFAPI != null && (String.isBlank(metaSFAPI.Client_Id__c) || String.isBlank(metaSFAPI.Client_Secret__c) || String.isBlank(metaSFAPI.refresh_token__c))) ){
            String errorMessage = 'MetaData has Empty or Blank value while refreshToken';
           // sendErrorEmail('Salesforce API - MetaData has Blank Value', errorMessage);
            return;
        }
        String clientID = metaSFAPI.Client_Id__c;
        String secret = metaSFAPI.Client_Secret__c;
        String baseUrl = metaSFAPI.Base_Url__c;
        String refresh = metaSFAPI.refresh_token__c;
        
        String body ='grant_type=refresh_token'+'&client_secret='+secret+'&client_id='+clientID+'&refresh_token='+refresh;
        String EP = baseUrl+'/services/oauth2/token';
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        
        request.setMethod('POST');
        request.setBody(body);
        request.setEndpoint(EP);
        try{
            response = http.send(request);
            if(response.getStatusCode() == 200){
                system.debug('Response Body :: ' + response.getBody());
                Map<String,Object> bodyMap = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
                system.debug('bodyMap::'+bodyMap);
                system.debug('access_token__c --->'+bodyMap.get('access_token'));
                String updatedAccessToken = (String) bodyMap.get('access_token'); 
                system.debug('updatedAccessToken --->'+ updatedAccessToken);
                Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                    customMetadata.fullName = 'Salesforce_API__mdt.'+'Salesforce_API';
                    customMetadata.label = 'Salesforce_API';
                    
                    Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue();
                    customField1.field = 'Access_Token__c'; 
                    customField1.value = updatedAccessToken;
                    customMetadata.values.add(customField1);
                    
                    Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                    mdContainer.addMetadata(customMetadata);
                    if(!Test.isRunningTest()){
                        Metadata.Operations.enqueueDeployment(mdContainer, null);
                    }
            }
            else{
                system.debug('Response Body :: ' + response.getBody());
                String errorMessage = 'Status: '+response.getStatus()+'<br/>Status Code: '+response.getStatuscode()+'<br/>Message: '+response.getBody()+'<br/>User: '+Userinfo.getUserId();
                sendErrorEmail('Salesforce API - Refresh Failed', errorMessage);
            }
        }
        catch(exception e){
            system.debug(e.getMessage());
            String errorMessage = 'Status: '+response.getStatus()+'<br/>Status Code: '+response.getStatuscode()+'<br/>Message: '+response.getBody()+'<br/>Exeception: '+e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>Type: '+e.getTypeName()+'<br/>User: '+Userinfo.getUserId();
            System.debug(System.LoggingLevel.DEBUG, 'Exeception: '+e.getMessage()+' \nErrorMessage: '+errorMessage);
            sendErrorEmail('Salesforce API - Refresh Failed', errorMessage);
        }
        
    }
    public static void sendNotification(String title, String body, string targetId, Set<String> userIdSet){
        List<CustomNotificationType> notificationTypeList = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='SMS_Notification' Limit 1];
        Set<String> recipientUserIdSet = new Set<String>();
        if(notificationTypeList.size() > 0){
            CustomNotificationType notificationType = notificationTypeList[0];
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(targetId);
            if(userIdSet == null){
                List<String> userNameList = System.Label.Users_to_notify_member_query.split(',');
                if(userNameList.size() > 0){
                    List<User> usersToSend = [SELECT Id, Username FROM user WHERE Username IN :userNameList ];
                    //Map<Id,User> userMap = new Map<Id,User>([SELECT Id, Username FROM user WHERE Username IN :userNameList ]);
                    System.debug('userIdSet :: '+ userIdSet);
                    for(User each : usersToSend){
                        System.debug('userIdSet :: '+ userIdSet);
                        recipientUserIdSet.add(each.Id);
                    }
                } 
            }
            else{
                 recipientUserIdSet = userIdSet ;
            }
            
                
            if(recipientUserIdSet.size() > 0){
                System.Debug('Notificaation send');
                notification.send(recipientUserIdSet);
            
                
            }
        
        }
    }

    global static CreateResponseWrapper requestForTestDrive(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            String testDriveDateTime = (String) requestBody.get('TestDriveDate');
            String vehicleName = (String) requestBody.get('VehicleName');
            String memberQuery = (String) requestBody.get('MemberQuery');
            Integer fastpassVehicleId = (Integer.valueOf(requestBody.get('FastpassVehicleId')));
            String chatId = (String) requestBody.get('ChatId');

            List<String> blankFields = new List<String>();
            List<Contact> conList =  new List<Contact>();
            List<Lead> leadList =  new List<Lead>();
            Lead lead;
            
            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            if (String.isBlank(dealerMarketcheckId)) {
                blankFields.add('FastPassDealerId');
            }
            if (String.isBlank(vehicleVIN)) {
                blankFields.add('VehicleVIN');
            }
            if (String.isBlank(VehicleName)) {
                blankFields.add('VehicleName');
            }
            if ((FastpassVehicleId == null)) {
                blankFields.add('FastpassVehicleId');
            }
            if (String.isBlank(testDriveDateTime) && String.isBlank(memberQuery)){
                blankFields.add('MemberQuery or TestDriveDate');
            }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestForAskDealer.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Ask Dealer Request');
                return wrapper;
            }
            
            List<Opportunity> oppList = [SELECT Id, Name, Auto_Shopper__c, Vehicle_VIN__c, Auto_Shopper__r.Name, Card_Number__c, Auto_Shopper__r.FirstName, Auto_Shopper__r.Email, Auto_Shopper__r.RecordTypeId
                                         FROM Opportunity 
                                         WHERE Card_Number__c = :memberLoanId LIMIT 1];
            
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            
            if (opp == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestForAskDealer.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: Test Drive<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>LoanId: '+memberLoanId);
                return wrapper;
            }
            
            List<Garage__c> garageList = [SELECT Id, Name, VIN__c, Pending_Requests__c, Pending_Request_JSON__c, FastPass_Vehicle_Id__c, Chat_Id__c, Send_Generic_Notification__c, Dealer_Email_Available__c  from Garage__c WHERE FastPass_Vehicle_Id__c =: fastpassVehicleId AND Opportunity__c =: opp.Id ];
            Garage__c garage = garageList.size() > 0 ? garageList[0] : null; 
            
            
            List<Account> accList = [SELECT Id, Name, FastPass_Dealer_Id__c, Manager_Name__c, Manager_Email__c, RecordType.DeveloperName 
                                     FROM Account 
                                     WHERE RecordType.DeveloperName = 'Auto_Dealer' 
                                     AND FastPass_Dealer_Id__c =: dealerMarketcheckId
                                     LIMIT 1];
            Account acc = accList.size() > 0 ? accList[0] : null;

            if (acc <> null) {
                conList = [SELECT Id, AccountId, Name, Email, RecordType.DeveloperName from Contact Where AccountId =:acc.Id AND RecordType.DeveloperName = 'Auto_Dealer_Pro' AND Active__c = true order by CreatedDate asc];    
            }
            else{
                leadList = [SELECT Id, FastPass_Dealer_Id__c, Manager_Name__c, Manager_Email__c, Dealer_Pro_1_Email__c, Dealer_Pro_2_Email__c, Dealer_Pro_3_Email__c, Company FROM Lead WHERE FastPass_Dealer_Id__c =: dealerMarketcheckId];
                lead = leadList.size() > 0 ? leadList[0] : null;
            }
            if (garage == null) {
                garage = createGarageRecord(dealerMarketcheckId, opp.Id, null, vehicleVIN, vehicleName, accList, conList, fastpassVehicleId, null, null, null, null, leadList, chatId );
            }
            String recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Shopper_Carbots').getRecordTypeId();

            Portal_Message__c  portalMessage = new Portal_Message__c();
            portalMessage.Message__c = memberQuery;
            portalMessage.Is_Member_Message__c = true;
            portalMessage.Garage__c = garage.Id;
            portalMessage.Opportunity__c = opp.Id;
            portalMessage.Portal_Type__c = opp.Auto_Shopper__r.RecordTypeId == recordTypeId? 'Carbots' :'Dealer';
            portalMessage.Is_Pending__c = !garage.Dealer_Email_Available__c;
            portalMessage.Sender_Email__c = opp.Auto_Shopper__r.Email;
            portalMessage.Message_Sent_Date_Time__c = System.Now();
            if(testDriveDateTime != null){
                portalMessage.Request_Type__c = 'Test_Drive';
            }
            insert portalMessage;
            String dealerName = acc!= null? acc.Name : lead != null? lead.Company : '';
            String body = '🏬 '+ dealerName + ' \n 🚘 '+ garage.Name; 
            String title = 'New message from '+ (opp.Auto_Shopper__r.FirstName);
            FastPassIntegrationService.sendNotification(title, body, garage.Id, null);

            Garage__c updateGarage = new Garage__c();
            updateGarage.Id = garage.Id;
            updateGarage.Last_Member_Response_Test_Drive__c = System.now();
            if(garage.Send_Generic_Notification__c == true){
                updateGarage.Send_Generic_Notification__c = false;
            }
            if(chatId != null){
                updateGarage.Chat_Id__c = chatId;
            }
            update updateGarage;

            SuccesWrapper wrapp = new SuccesWrapper();
                wrapp.message = 'Ask Dealer request sent successfully';
                wrapp.data = new List<CreateResponseWrapperSuccess>();
                wrapper.success = wrapp;
                wrapper.error = new Map<String, String>{};
                    
            
        }
        catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            System.debug('errorMessage :: ' + errorMessage);
            //sendErrorEmail('failed to process requestForAskDealer.',  errorMessage );
            
        }
        return wrapper;
    }

    public static CreateResponseWrapper sendRightSwipeNotification(Map<String, Object> requestBody){
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            String testDriveDateTime = (String) requestBody.get('TestDriveDate');
            String vehicleName = (String) requestBody.get('VehicleName');
            String memberQuery = (String) requestBody.get('MemberQuery');
            Integer fastpassVehicleId = (Integer.valueOf(requestBody.get('FastpassVehicleId')));
            String chatId = (String) requestBody.get('ChatId');
            String portalType = (String) requestBody.get('PortalType');

            List<String> blankFields = new List<String>();
            List<Contact> conList;
            List<Lead> leadList;
            Lead lead;
            String dealerName;
            String memberName;
            
            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            if (String.isBlank(dealerMarketcheckId)) {
                blankFields.add('FastPassDealerId');
            }
            if (String.isBlank(vehicleVIN)) {
                blankFields.add('vehicleVIN');
            }
            if (String.isBlank(VehicleName)) {
                blankFields.add('VehicleName');
            }
            if ((FastpassVehicleId == null)) {
                blankFields.add('FastpassVehicleId');
            }
            if (String.isBlank(memberQuery)){
                blankFields.add('MemberQuery');
            }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process defaultMemberMessage.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Ask Dealer Request');
                return wrapper;
            }

            List<Opportunity> oppList = [SELECT Id, Name, Auto_Shopper__c, Vehicle_VIN__c, Auto_Shopper__r.Name, Card_Number__c, Auto_Shopper__r.FirstName, Auto_Shopper__r.Email
                                         FROM Opportunity 
                                         WHERE Card_Number__c = :memberLoanId LIMIT 1];
            
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            if (opp == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process defaultMemberMessage.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: Test Drive<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>LoanId: '+memberLoanId);
                return wrapper;
            }
           
            List<Garage__c> garageList = [SELECT Id, Name, VIN__c, Pending_Requests__c, Pending_Request_JSON__c, FastPass_Vehicle_Id__c, Chat_Id__c, Dealer_Email_Available__c from Garage__c WHERE FastPass_Vehicle_Id__c =: fastpassVehicleId AND Opportunity__c =: opp.Id ];
            Garage__c garage = garageList.size() > 0 ? garageList[0] : null; 
            if (garage == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching Vehicle found for the provided Fastpass Vehicle Id'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process defaultMemberMessage.', 'No matching Vehicle found for the provided Fastpass Vehicle Id.<br/>Request Type: Default Member Message<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>LoanId: '+memberLoanId);
                return wrapper;
            }

            Portal_Message__c  portalMessage = new Portal_Message__c();
            portalMessage.Message__c = memberQuery;
            portalMessage.Is_Member_Message__c = true;
            portalMessage.Garage__c = garage.Id;
            portalMessage.Opportunity__c = opp.Id;
            portalMessage.Portal_Type__c = 'Dealer';
            portalMessage.Is_Pending__c = !garage.Dealer_Email_Available__c;
            portalMessage.Sender_Email__c = opp.Auto_Shopper__r.Email;
            portalMessage.Request_Type__c = 'First_Message';
            portalMessage.Message_Sent_Date_Time__c = System.Now();
            insert portalMessage;

            
            SuccesWrapper wrapp = new SuccesWrapper();
            wrapp.message = 'Default Member Message request sent successfully';
            wrapp.data = new List<CreateResponseWrapperSuccess>();
            wrapper.success = wrapp;
            wrapper.error = new Map<String, String>{};

    }
    catch(Exception e){
        wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
        wrapper.success = new SuccesWrapper();
        String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
        sendErrorEmail('failed to process defaultMemberMessage.',  errorMessage );
        return wrapper;
    }
    return wrapper;
	}
    global static CreateResponseWrapper requestMSRMessage(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String memberQuery = (String) requestBody.get('MemberQuery');
            String portalType = (String) requestBody.get('PortalType');
            List<String> blankFields = new List<String>();

            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            if (String.isBlank(memberQuery)){
                blankFields.add('MemberQuery');
            }
            // if (String.isBlank(memberQuery)){
            //     blankFields.add('PortalType');
            // }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                          //  wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestMSRMessage.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Ask MSR Request');
                return wrapper;
            }
            List<Opportunity> oppList = [SELECT Id, Name, Branch__c, Branch__r.ParentId, Card_Number__c, Auto_Shopper__r.Email, Bank_Service_Rep_Name_MSR__c
                                         FROM Opportunity 
                                         WHERE Card_Number__c = :memberLoanId LIMIT 1];
            
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            if (opp == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId'};
                   // wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process defaultMemberMessage.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: MSR Member Message<br/>LoanId: '+memberLoanId);
                return wrapper;
            }
            Portal_Message__c  portalMessage = new Portal_Message__c();
            portalMessage.Message__c = memberQuery;
            portalMessage.Is_Member_Message__c = true;
            portalMessage.Sender_Email__c = opp.Auto_Shopper__r.Email;
            portalMessage.Opportunity__c = opp.Id;
            portalMessage.Portal_Type__c = portalType == 'Advisor'?  'Advisor': 'MSR';
            portalMessage.Message_Sent_Date_Time__c = System.Now();
           // portalMessage.Portal_Type__c = 'MSR';
            
            if(opp.Bank_Service_Rep_Name_MSR__c != null){
                portalMessage.Is_Pending__c = false;
            }
            else if(opp.Branch__c != null && opp.Branch__r.ParentId != null){
                List<Contact> msrContactList =[SELECT Id
                                              FROM Contact 
                                              WHERE Primary_Contact__c = true AND AccountId =: opp.Branch__r.ParentId];
                portalMessage.Is_Pending__c = msrContactList.size() > 0? false :true;
            }
            else{
                portalMessage.Is_Pending__c = true;
            }
            insert portalMessage;


            SuccesWrapper wrapp = new SuccesWrapper();
            String successMessage = portalType == 'Advisor'? 'Advisor Member Message request sent successfully': 'MSR Member Message request sent successfully';
            wrapp.message = successMessage;
            wrapp.data = new List<CreateResponseWrapperSuccess>();
            wrapper.success = wrapp;
            wrapper.error = new Map<String, String>{};
        }
        catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
           // wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('failed to process MSR Member Message request .',  errorMessage );
           
        }
        return wrapper;
        
    }
    global static CreateResponseWrapper requestTestDriveResponse(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String portalType = (String) requestBody.get('PortalType');
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            Integer pageNumber = (Integer) requestBody.get('PageNumber');
            Integer fastpassVehicleId = Integer.valueOf(requestBody.get('fastpassVehicleId'));
            
            List<String> blankFields  = new List<String> ();
            if (String.isBlank(memberLoanId)){
                blankFields.add('LoanId');
            }
            if (String.isBlank(portalType)){
                blankFields.add('PortalType');
            }
            if(!String.isBlank(portalType) && portalType == 'Dealer' ){
                if(String.isBlank(dealerMarketcheckId)){
                    blankFields.add('FastPassDealerId');
                }
                if(String.isBlank(vehicleVIN)){
                    blankFields.add('vehicleVIN');
                }
                if(fastpassVehicleId == null){
                    blankFields.add('fastpassVehicleId');
                }
            }
            
            if(pageNumber == null){
                blankFields.add('PageNumber');
            }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Message' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestTestDriveResponse.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Test Drive Response');
                return wrapper;
            }
            Integer index = (PageNumber - 1) * 50;
            List<opportunity>  oppList = [SELECT Id, Auto_Shopper__r.Name, Dealer__r.Id, Card_Number__c, Vehicle_VIN__c
                                          FROM Opportunity 
                                          WHERE Card_Number__c = :memberLoanId
                                          LIMIT 1];
            
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            if(opp == null){
                wrapper.error = new Map<String, String>{'Message' => 'No Opportunity found with the provided LoanId'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestTestDriveResponse.', 'No Opportunity found with the provided LoanId.<br/>Request Type: Test Drive Response<br/>VIN: '+vehicleVIN+'<br/>LoanId: '+memberLoanId);
                return wrapper;       
            }
            List<Portal_Message__c> allPortalMessage;
            integer count = 0;
            String chatId;
            if(PortalType == 'Dealer'){
                List<Garage__c> garList = [SELECT Id, Name, VIN__c, FastPass_Dealer_Id__c,Pending_Requests__c,Pending_Request_JSON__c,FastPass_Vehicle_Id__c,Chat_Id__c  From Garage__c WHERE FastPass_Vehicle_Id__c =:fastpassVehicleId AND Opportunity__c =: opp.Id LIMIT 1];
                Garage__c gar = garList.size() > 0 ? garList[0] : null;
                if(gar == null){
                    wrapper.error = new Map<String, String>{'Message' => 'No Vehicle found in garage'};
                        wrapper.success = new SuccesWrapper();
                    sendErrorEmail('failed to process requestTestDriveResponse.', 'No Vehicle found in garage.<br/>Request Type: Test Drive Response<br/>VIN: '+vehicleVIN+'<br/>Opportunity Id: '+opp.Id);
                    return wrapper;       
                }
                chatId = gar != null? gar.Chat_Id__c : null;
                allPortalMessage = [SELECT Id, Opportunity__c, CreatedDate, Message__c, Is_Member_Message__c, Message_Sent_Date_Time__c 
                                                        FROM Portal_Message__c
                                                        WHERE Opportunity__c = :opp.Id AND Garage__c = :gar.Id
                                                        ORDER BY CreatedDate DESC
                                                        LIMIT 50 OFFSET :index];
                List<AggregateResult> portalMessageCount = [SELECT COUNT(id) total FROM Portal_Message__c WHERE Opportunity__c = :opp.Id AND Garage__c = :gar.Id];
                if (!portalMessageCount.isEmpty()) {
                    count = (Integer) portalMessageCount[0].get('total');
                }

            }
            else{
                
                allPortalMessage = [SELECT Id, Opportunity__c, CreatedDate, Message__c, Is_Member_Message__c, Portal_Type__c, Message_Sent_Date_Time__c 
                                                        FROM Portal_Message__c
                                                        WHERE Opportunity__c = :opp.Id AND Garage__c = null AND Portal_Type__c =: portalType
                                                        ORDER BY CreatedDate DESC 
                                                        LIMIT 50 OFFSET :index];
                List<AggregateResult> portalMessageCount = [SELECT COUNT(id) total FROM Portal_Message__c WHERE Opportunity__c = :opp.Id AND Garage__c = null AND Portal_Type__c =: portalType];
                if (!portalMessageCount.isEmpty()) {
                    count = (Integer) portalMessageCount[0].get('total');
                }
                system.debug('count ==> '+ count);

            }
            
            Decimal totalPages = count <= 50 ? 1: Math.ceil(count/50.0);
            List<CreateResponseWrapperSuccess> conversations = new List<CreateResponseWrapperSuccess>();
            for (Portal_Message__c eachPM : allPortalMessage) {
                CreateResponseWrapperSuccess emailDetails = new CreateResponseWrapperSuccess();
                emailDetails.VehicleVIN = vehicleVIN;
                emailDetails.LoanId = memberLoanId;
                emailDetails.MarketCheckId = dealerMarketcheckId;
                emailDetails.CreatedDate = eachPM.Message_Sent_Date_Time__c;
                emailDetails.EmailMessage = eachPM.Message__c;
                emailDetails.Sender = eachPM.Is_Member_Message__c? 'Member' : PortalType == 'Dealer'? 'Dealer' : PortalType == 'Advisor'? 'Advisor' : 'MSR' ;
                conversations.add(emailDetails);
            }
                        
            SuccesWrapper wrapp = new SuccesWrapper();
            wrapp.message = 'Conversations Fetched Successfully';
            wrapp.data = conversations;
            wrapp.currentPage = pageNumber;
            wrapp.totalPages = (Integer)totalPages;
            wrapp.chatId = chatId;
            wrapper.success = wrapp;
            wrapper.error = new Map<String, String>{};
                return wrapper;
            
        }catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('failed to process TestDriveResponse.',  errorMessage );
            return wrapper;
        }
        
    }
    public static CreateResponseWrapper processTopFiveList(Map<String, Object> requestBody){
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String processType = (String) requestBody.get('ProcessType');
            Integer fastpassVehicleId = (Integer.valueOf(requestBody.get('FastpassVehicleId')));
            List<String> blankFields = new List<String>();

            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            if (String.isBlank(processType)){
                blankFields.add('ProcessType');
            }
            if (fastpassVehicleId == null){
                blankFields.add('FastpassVehicleId');
            }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                sendErrorEmail('failed to process processTopFiveList.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Top Five List');
                return wrapper;
            }
            if(processType != 'add' && processType != 'remove'){
                wrapper.error = new Map<String, String>{
                    'Error' => 'Invalid ProcessType: ' + processType
                        };
                sendErrorEmail('failed to process processTopFiveList.', 'Invalid ProcessType: ' + processType+'<br/>Request Type: Top Five List');
                return wrapper;
            }

            Opportunity opp = getOpportunity(memberLoanId);

            if (opp == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId'};
                sendErrorEmail('failed to process processTopFiveList.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: Top Five List<br/>LoanId: '+memberLoanId);
                return wrapper;
            }

            List<Garage__c> garageList = [SELECT Id, Name, VIN__c, FastPass_Vehicle_Id__c, Chat_Id__c, Dealer_Email_Available__c from Garage__c WHERE FastPass_Vehicle_Id__c =: fastpassVehicleId AND Opportunity__c =: opp.Id ];
            Garage__c garage = garageList.size() > 0 ? garageList[0] : null; 
            if (garage == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching Vehicle found for the provided Fastpass Vehicle Id'};
                wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process processTopFiveList.', 'No matching Vehicle found for the provided Fastpass Vehicle Id.<br/>Request Type: Top Five List<br/>LoanId: '+memberLoanId);
                return wrapper;
            }
            else{
                Garage__c updateGarage = new Garage__c();
                updateGarage.Id = garage.Id;
                updateGarage.Is_Vehicle_In_Top_List__c = processType == 'add'? True: False;
                update updateGarage;

                String message = processType == 'add' ? 'Vehicle added to Top 5 List': 'Vehicle removed from Top 5 List';

                SuccesWrapper wrapp = new SuccesWrapper();
                wrapp.message = message;
                wrapp.data = new List<CreateResponseWrapperSuccess>();
                wrapper.success = wrapp;
                wrapper.error = new Map<String, String>{};
            }

        }
        catch(Exception e){
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            System.debug('errorMessage :: '+ errorMessage);
        }
        return wrapper;
    }

    public static Opportunity getOpportunity(String memberLoanId){
        List<Opportunity> oppList = [SELECT Id, Name, Branch__c, Branch__r.ParentId, Card_Number__c, Auto_Shopper__r.Email, Bank_Service_Rep_Name_MSR__c
                                         FROM Opportunity 
                                         WHERE Card_Number__c = :memberLoanId LIMIT 1];
        Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
        return opp;
    }
}