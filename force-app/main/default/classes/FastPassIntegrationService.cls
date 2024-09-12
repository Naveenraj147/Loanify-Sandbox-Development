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
                
                if (requestType == 'testDrive') {
                    wrapper = requestForTestDrive(requestBody);
                } else if (requestType == 'askDealer') {
                    wrapper = askDealer(requestBody);
                } else if (requestType == 'testDriveConversation') {
                    wrapper = requestTestDriveResponse(requestBody);
                } else if (requestType == 'askDealerConversation') {
                    wrapper = requestAskDealerResponse(requestBody);
                } else if (requestType == 'vehicleAdditionToGarage'){
                    wrapper = vehicleAddition(requestBody);
                }else if (requestType == 'vehicleRemovalInGarage'){
                    wrapper = vehicleRemovalInGarage(requestBody);
                } else {
                    wrapper.error = new Map<String, String>{'Message' => 'Could not find a match for RequestType'};
                        wrapper.success = new SuccesWrapper() ;
                    sendErrorEmail('Failed to ' + requestType, JSON.serialize(wrapper.error));
                }
                /*if (!wrapper.error.isEmpty()) {
sendErrorEmail('Failed to ' + requestType, JSON.serialize(wrapper.error));
System.debug('successData: ' + wrapper.success);
System.debug('errorData: ' + wrapper.error);
}*/
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
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('Failed to process vehicleAddition', 'Required fields are missing: '+nullFields +'<br/> Request Type: vehicleAdditionToGarage');
                return wrapper;
            }
            
            
            List<Opportunity> oppList = [SELECT Id, Name, Card_Number__c FROM Opportunity WHERE Card_Number__c =: memberLoanId LIMIT 1];
            
            if(oppList.size() > 0 ){
                Opportunity opp = oppList[0];
                List<Garage__c> garageList = [SELECT Id, Name, Active__c, VIN__c FROM Garage__c WHERE VIN__c =:vehicleVIN AND Opportunity__c =: opp.Id Limit 1 ];
                if (!garageList.isEmpty()){
                    Garage__c garage = garageList[0];
                    if( garage.Active__c == false){
                        garage.Active__c = true;
                        update garage;
                        
                        SuccesWrapper wrapp = new SuccesWrapper();
                        wrapp.message = 'Vehicle is inserted in garage';
                        wrapp.data = new List<CreateResponseWrapperSuccess>();
                        wrapper.success = wrapp;
                        wrapper.error = new Map<String, String>{};
                            return wrapper;
                    }
                }
                else {
                    List<Account> accList = [SELECT Id, Name, FastPass_Dealer_Id__c, Manager_Email__c, RecordType.DeveloperName FROM Account WHERE FastPass_Dealer_Id__c =: dealerMarketcheckId AND RecordType.DeveloperName = 'Auto_Dealer'];
                    List<Contact> conList;
                    if(accList.size() > 0 ){
                        conList   = [SELECT Id, Name, AccountId, Active__c, RecordType.DeveloperName FROM Contact WHERE AccountId =: accList[0].Id AND RecordType.DeveloperName = 'Auto_dealer_Pro' AND Active__c = true order by CreatedDate asc];
                        
                    }
                    
                    createGarageRecord(dealerMarketcheckId, opp.Id, modelYear, vehicleVIN, vehicleName, accList, conList, null );
                }
                SuccesWrapper wrapp = new SuccesWrapper();
                wrapp.message = 'Vehicle successfully added into Garage';
                wrapp.data = new List<CreateResponseWrapperSuccess>();
                wrapper.success = wrapp;
                wrapper.error = new Map<String, String>{};
                    } else {
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
    
    public static Garage__c createGarageRecord(String dealerMarketcheckId, String oppId, Integer modelYear, String vehicleVIN, String vehicleName,  List<Account> accList, List<Contact> conList, Integer fastpassVehicleId  ){
        //  List<Account> accList = [SELECT Id, Name, Marketcheck_Id__c, Manager_Email__c, RecordType.DeveloperName FROM Account WHERE Marketcheck_Id__c =: dealerMarketcheckId AND RecordType.DeveloperName = 'Auto_Dealer'];
        Garage__c garage = new Garage__c ();
        garage.Active__c = true;
        garage.Opportunity__c = oppId;
       	garage.FastPass_Dealer_Id__c = dealerMarketcheckId;
        garage.Year__c = modelYear;
        garage.VIN__c = vehicleVIN;
        garage.Name = vehicleName;
        
        if(accList.size() > 0){
            Account acc = accList[0];
            garage.Dealer__c = acc.Id;
            
            // List<Contact> conList = [SELECT Id, Name, AccountId, Active__c, RecordType.DeveloperName FROM Contact WHERE AccountId =: acc.Id AND RecordType.DeveloperName = 'Auto_dealer_Pro' AND Active__c = true Order by CreatedDate desc];
            
            
            if(acc.Manager_Email__c != null || !conList.isEmpty()){
                garage.Dealer_Email_Available__c = true;
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
        insert garage;
        return garage;
    }
    
    global static CreateResponseWrapper vehicleRemovalInGarage(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN'); 
            
            List<String> blankFields = new List<String>();
            if (String.isBlank(memberLoanId)) {
                blankFields.add('LoanId');
            }
            
            if (String.isBlank(vehicleVIN)) {
                blankFields.add('vehicleVIN');
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
                List<Garage__c> garageList = [SELECT Id, Name, Active__c, VIN__c FROM Garage__c WHERE VIN__c =:vehicleVIN AND Opportunity__c =: opp.Id ];
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
                    sendErrorEmail('failed to process vehicleRemovalInGarage.', 'No matching vehicle is found in the garage. <br/>Request Type: vehicleRemovalInGarage<br/> VIN: '+vehicleVIN+'<br/>Opportunity Id: '+opp.Id);  
                }
            }
            else{
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId.'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process vehicleRemovalInGarage.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: vehicleRemovalInGarage<br/> VIN: '+vehicleVIN+'LoanId: '+memberLoanId);
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
    
    global static CreateResponseWrapper requestForTestDrive(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            String testDriveDateTime = (String) requestBody.get('TestDriveDate');
            String vehicleName = (String) requestBody.get('VehicleName');
            String memberQuery = (String) requestBody.get('MemberQuery');
            Integer fastpassVehicleId = (Integer) requestBody.get('FastpassVehicleId');
            
            
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
                sendErrorEmail('failed to process requestFortestDrive.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Test Drive Request');
                return wrapper;
            }
            
            List<Opportunity> oppList = [SELECT Id, Name, Auto_Shopper__c, Vehicle_VIN__c, Auto_Shopper__r.Name, Card_Number__c 
                                         FROM Opportunity 
                                         WHERE Card_Number__c = :memberLoanId LIMIT 1];
            
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            
            if (opp == null) {
                wrapper.error = new Map<String, String>{'Message' => 'No matching opportunity found for the provided LoanId'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestForTestDrive.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: Test Drive<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>LoanId: '+memberLoanId);
                return wrapper;
            }
            
            List<Garage__c> garageList = [SELECT Id, Name, VIN__c, Pending_Requests__c, Pending_Request_JSON__c, FastPass_Vehicle_Id__c from Garage__c WHERE FastPass_Vehicle_Id__c =: fastpassVehicleId AND Opportunity__c =: opp.Id ];
            Garage__c garage = garageList.size() > 0 ? garageList[0] : null; 
            
            
            List<Account> accList = [SELECT Id, Name, FastPass_Dealer_Id__c, Manager_Name__c, Manager_Email__c, RecordType.DeveloperName 
                                     FROM Account 
                                     WHERE RecordType.DeveloperName = 'Auto_Dealer' 
                                     AND FastPass_Dealer_Id__c =: dealerMarketcheckId
                                     LIMIT 1];
            Account acc = accList.size() > 0 ? accList[0] : null;
            List<String> ccAddress = new List<String>();
            List<Contact> conList;
            if (acc <> null) {
                conList = [SELECT Id, AccountId, Name, Email, RecordType.DeveloperName from Contact Where AccountId =:acc.Id AND RecordType.DeveloperName = 'Auto_Dealer_Pro' AND Active__c = true order by CreatedDate asc];
                for(Contact each : conList){
                    ccAddress.add(each.Email);
                }
            }
            if (garage == null) {
                garage = createGarageRecord(dealerMarketcheckId, opp.Id, null, vehicleVIN, vehicleName, accList, conList, fastpassVehicleId );
            }
            OrgWideEmailAddress[] orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName = 'Support' Limit 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            if (orgWideEmail == null) {
                wrapper.error = new Map<String, String>{'Message' => 'From address is not found'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestForTestDrive.', 'No Org-Wide Email Address found');
                return wrapper;
            }
            String dealerportalURL = system.label.Dealer_Portal_Page_URL;
            // Create JSON object
            Map<String, Object> params = new Map<String, Object>();
            params.put('opportunityId', opp.Id);
            params.put('dealerId', dealerMarketcheckId);
            params.put('vehicleVin', vehicleVIN);
            params.put('vehicleName', vehicleName);
            params.put('type', 'testDrive');
            params.put('linkSharedDate', Date.today());
            params.put('garageId', garage.Id);
            
            // Convert to JSON string
            String jsonParams = JSON.serialize(params);
            List<EmailTemplate> emailTemplates = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                                                  FROM EmailTemplate 
                                                  WHERE DeveloperName IN ('Member_Query_For_Test_Drive_1719900621424', 
                                                                          'Member_Response_For_Test_Drive_1719904116801')];
            
            EmailTemplate emailTemp1;
            EmailTemplate emailTemp2;
            
            for (EmailTemplate template : emailTemplates) {
                if (template.DeveloperName == 'Member_Query_For_Test_Drive_1719900621424') {
                    emailTemp1 = template;
                } else if (template.DeveloperName == 'Member_Response_For_Test_Drive_1719904116801') {
                    emailTemp2 = template;
                }
            }
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String subject = emailTemp1.Subject;
            String htmlBody = emailTemp1.HtmlValue;
            String htmlBody1 = emailTemp2.HtmlValue;
            String subject1 = emailTemp2.Subject;
            String conLink = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
            
            if(testDriveDateTime!= null){
                System.Debug('testDriveDateTime Condition :: Inside');
                String datePart = testDriveDateTime.substring(0, 10);
                String timePart = testDriveDateTime.substring(11, 19);
                // Create a Datetime object
                Datetime dt = Datetime.newInstanceGmt(
                    Integer.valueOf(datePart.substring(0, 4)),
                    Integer.valueOf(datePart.substring(5, 7)),
                    Integer.valueOf(datePart.substring(8, 10)),
                    Integer.valueOf(timePart.substring(0, 2)),
                    Integer.valueOf(timePart.substring(3, 5)),
                    Integer.valueOf(timePart.substring(6, 8))
                );
                
                // Convert the datetime to the desired format
                String formattedDateTime = dt.format('dd\'th\' MMMM yyyy \'at\' hh:mm a', 'en_US');
                if (subject != null) {
                    subject = subject.replace('{{{Opportunity.Auto_Shopper__c}}}', opp.Auto_Shopper__r.Name);
                    subject = subject.replace('{{{VINNumber}}}', vehicleVIN);
                    subject = subject.replace('{{{Opportunity.Card_Number__c}}}', memberLoanId);
                }
                if(htmlBody != null){
                    htmlBody = acc <> null?  acc.Manager_Name__c <> null? htmlBody.replace('{{{ManagerName}}}', acc.Manager_Name__c):htmlBody.replace('{{{ManagerName}}}', acc.Name):htmlBody;
                    htmlBody = htmlBody.replace('{{{MemberName}}}', opp.Auto_Shopper__r.Name);
                    htmlBody = htmlBody.replace('{{{VINNumber}}}', vehicleVIN);
                    htmlBody = htmlBody.replace('{{{VehicleName}}}', vehicleName);
                    htmlBody = htmlBody.replace('{{{TestDriveDate}}}', formattedDateTime);
                    htmlBody = htmlBody.replace ('click here', '<a href="' +conLink+ '">click here</a>');
                    if(memberQuery!=null){
						memberQuery = memberQuery.replaceAll('\n', '<br/>');
                        htmlBody = htmlBody.replace('{{{MemberQuery}}}', memberQuery);
                    }else {
                        /*system.debug('Html Body::'+ htmlBody);
htmlBody = htmlBody.remove('Member Query: {{{MemberQuery}}}');*/
                        String toRemove = htmlBody.substringBetween(formattedDateTime, 'Please <a href="');
                        if (toRemove != null) {
                            htmlBody = htmlBody.replace(toRemove, '<br/><br/>');
                        }
                    }
                }
            } else {
                if(htmlBody1 != null){
                    htmlBody1 = acc <> null? acc.Manager_Name__c <> null? htmlBody1.replace('{{{ManagerName}}}', acc.Manager_Name__c):htmlBody1.replace('{{{ManagerName}}}', acc.Name):htmlBody1.replace('{{{ManagerName}}}','');
                    htmlBody1 = htmlBody1.replace('{{{MemberName}}}', opp.Auto_Shopper__r.Name);
                    htmlBody1 = htmlBody1.replace('{{{MemberResponse}}}', memberQuery);
                    htmlBody1 = htmlBody1.replace ('click here', '<a href="' +conLink+ '">click here</a>');
                }
                if(subject1 != null){
                    subject1 = subject1.replace('{{{Opportunity.Auto_Shopper__c}}}', opp.Auto_Shopper__r.Name);
                    subject1 = subject1.replace('{{{VINNumber}}}', vehicleVIN);
                    subject1 = subject1.replace('{{{Opportunity.Card_Number__c}}}', memberLoanId);
                }
            }
             System.debug('htmlBody :: '+ htmlBody);
            System.debug('memberQuery :: '+ memberQuery);
            String mailAddress = acc != null? acc.Manager_Email__c : null;
            //String mailAddress = null;
            if(mailAddress != null && mailAddress != ''){
                email.setToAddresses(new List<String> { mailAddress });
                email.setCCAddresses(ccAddress );
            }else{
                email.setToAddresses(ccAddress);
            }
            email.setOrgWideEmailAddressId(orgWideEmail.Id);
            if(testDriveDateTime != null){
                System.debug('Email 1');
                email.setSubject(subject);
                email.setHtmlBody(htmlBody);
            } else {
                System.debug('Email 2');
                email.setSubject(subject1);
                email.setHtmlBody(htmlBody1);
            }
            email.setSaveAsActivity(true); 
            email.setWhatId(garage.Id);
            emailList.add(email);
            
            if(mailAddress == null && ccAddress.size() == 0){
                Garage__c garagesWithPendingRequest = new Garage__c();
                garagesWithPendingRequest.Id = garage.Id;
                garagesWithPendingRequest.Last_Member_Response_Test_Drive__c = System.now();
                CreateResponseWrapperSuccess emailDetails = new CreateResponseWrapperSuccess();
                emailDetails.VehicleVIN = VehicleVIN;
                emailDetails.LoanId = memberLoanId;
                emailDetails.MarketCheckId = dealerMarketcheckId;
                emailDetails.Sender = 'Member';
                emailDetails.CreatedDate = System.now();
                String emailBody = email.getHtmlBody();
                if(emailBody.contains('Member Query:')){
                    System.debug('emailBody :: ' +emailBody);
                    String EmailMessage = emailBody.substringBetween('Member Query: ', 'Please <a href="');
                    if(EmailMessage!=null){
                        String Vehicle = emailBody.substringBetween('Vehicle Name: ', '<br />');
                        String testDriveDate = emailBody.substringBetween('Test Drive Date: ', '<br />');
                        EmailMessage = EmailMessage.replaceAll('<[^>]*>', '');
                        EmailMessage = EmailMessage.replaceAll('\n', '');
                        EmailMessage = decodeHtmlEntities(EmailMessage);
                        String body = 'Can you provide the test drive for '+vehicle+' on '+testDriveDate+'. ';
                        body += EmailMessage;
                        emailDetails.EmailMessage = body;
                    }
                }
                else if(emailBody.contains('Member Response:')){
                    String EmailMessage = emailBody.substringBetween('Member Response:', 'Please <a href="');
                    if(EmailMessage!=null){
                        EmailMessage = EmailMessage.replaceAll('<[^>]*>', '');
                        EmailMessage = EmailMessage.replaceAll('\n', '');
                        EmailMessage = decodeHtmlEntities(EmailMessage);
                        emailDetails.EmailMessage = EmailMessage;
                    }
                }
                else{
                     String Vehicle = emailBody.substringBetween('Vehicle Name: ', '<br />');
                    String testDriveDate = emailBody.substringBetween('Test Drive Date: ', '<br/>');
                    emailDetails.EmailMessage = 'Can you provide the test drive for '+vehicle+' on '+testDriveDate+'.';
                }
                
                garagesWithPendingRequest.Pending_Request_JSON__c = processPendingReqJson(garage.Pending_Request_JSON__c, 'testDrive', JSON.serialize(emailDetails));
                
                if(garage.Pending_Requests__c <> null){
                    garagesWithPendingRequest.Pending_Requests__c = garage.Pending_Requests__c + ';; Subject++'+email.getSubject()+'Body++'+email.getHtmlBody()+'Type++ testDrive';
                }
                else{
                    garagesWithPendingRequest.Pending_Requests__c = 'Subject++'+email.getSubject()+'Body++'+email.getHtmlBody()+'Type++ testDrive'  ;
                    
                }
                update garagesWithPendingRequest;
            }
            
            
            if (!Test.isRunningTest() && emailList.size() > 0 && (mailAddress <> null || ccAddress.size()>0)) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
                Garage__c garageWithoutPendingRequest = new Garage__c();
                garageWithoutPendingRequest.Id = garage.Id;
                garageWithoutPendingRequest.Last_Member_Response_Test_Drive__c = System.now();
                update garageWithoutPendingRequest;
                for (Messaging.SendEmailResult result : results) {
                    if (result.isSuccess()) {
                        SuccesWrapper wrapp = new SuccesWrapper();
                        wrapp.message = 'Test Drive request sent successfully';
                        wrapp.data = new List<CreateResponseWrapperSuccess>();
                        wrapper.success = wrapp;
                        wrapper.error = new Map<String, String>{};
                            } 
                    else {
                        wrapper.error = new Map<String, String>{'Message' => 'Failed to send Test Drive request.<br/> Error: ' + result.getErrors()[0].getMessage()};
                            wrapper.success = new SuccesWrapper();
                        sendErrorEmail('failed to process requestFortestDrive.', result.getErrors()[0].getMessage()+'<br/> Request Type: Test Drive<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>Opportunity Id: '+opp.Id+'<br/> Dealer Id: '+acc.Id);
                    }  
                }
            }
            else if(emailList.size() > 0 && mailAddress == null && ccAddress.size() == 0){
                SuccesWrapper wrapp = new SuccesWrapper();
                wrapp.message = 'Test Drive request sent successfully';
                wrapp.data = new List<CreateResponseWrapperSuccess>();
                wrapper.success = wrapp;
                wrapper.error = new Map<String, String>{};
                    }
            return wrapper;
            
        } catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('failed to process requestForTestDrive.',  errorMessage );
            return wrapper;
        }
    }
    global static CreateResponseWrapper askDealer(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            String memberQuery = (String) requestBody.get('MemberQuery');
            String vehicleName = (String) requestBody.get('VehicleName');
            
            List<String> blankFields = new List<String>();
            
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
            if (String.isBlank(memberQuery)){
                blankFields.add('MemberQuery');
            }
            if (!blankFields.isEmpty()) {
                String nullFields = String.join(blankFields, ', ');
                wrapper.error = new Map<String, String>{
                    'Error' => 'Required fields are missing: ' + nullFields
                        };
                            wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process askDealer.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Ask Dealer Request');
                return wrapper;
            }
            
            List<Opportunity> oppList = [SELECT Id, Name, Auto_Shopper__c, Vehicle_VIN__c, Auto_Shopper__r.Name, Card_Number__c 
                                         FROM Opportunity 
                                         WHERE Card_Number__c = :memberLoanId 
                                         LIMIT 1];
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            
            if (opp == null) {
                wrapper.error = new Map<String, String>{'Error' => 'No matching opportunity found for the provided LoanId'};
                    wrapper.success =  new SuccesWrapper(); 
                sendErrorEmail('failed to process askDealer.', 'No matching opportunity found for the provided LoanId.<br/>Request Type: Test Drive<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>LoanId: '+memberLoanId);
                return wrapper;
                
            }
            
            List<Garage__c> garageList = [SELECT Id, Name, VIN__c,Pending_Requests__c,Pending_Request_JSON__c from Garage__c WHERE VIN__c =: vehicleVIN AND Opportunity__c =: opp.Id ];
            Garage__c garage = garageList.size() > 0 ? garageList[0] : null; 
            
            
            List<Account> accList =  [SELECT Id, Name, Manager_Name__c, Manager_Email__c, FastPass_Dealer_Id__c, RecordType.DeveloperName 
                                     FROM Account 
                                     WHERE RecordType.DeveloperName = 'Auto_Dealer' 
                                     AND FastPass_Dealer_Id__c =: dealerMarketcheckId 
                                     LIMIT 1];
            Account acc = accList.size() > 0 ? accList[0] : null;
            
            /*if (acc == null) {
wrapper.error = new Map<String, String>{'Message' => 'No matching dealer found for the provided MarketCheckId'};
wrapper.success =  new SuccesWrapper(); 
sendErrorEmail('failed to process askDealer', 'No matching dealer found for the provided MarketCheckId');
return wrapper;
}*/
            List<Contact> conList;
            List<String> ccAddress = new List<String>();
            if (acc <> null) {
                conList = [SELECT Id, AccountId, Name, Email, RecordType.DeveloperName from Contact Where AccountId =:acc.Id AND RecordType.DeveloperName = 'Auto_Dealer_Pro' AND Active__c = true order by CreatedDate asc];
                for(Contact each : conList){
                    ccAddress.add(each.Email);
                }      
            }
            if (garage == null) {
                /* wrapper.error = new Map<String, String>{'Message' => 'No matching car is found in garage for the provided VIN and LoanId'};
wrapper.success = new SuccesWrapper();
sendErrorEmail('failed to process askDealer', 'No matching car is found in garage for the provided VIN and LoanId');
return wrapper; */
                garage = createGarageRecord(dealerMarketcheckId, opp.Id, null, vehicleVIN, vehicleName, accList, conList, null);
            }
            OrgWideEmailAddress[] orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName = 'Support' Limit 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            if (orgWideEmail == null) {
                wrapper.error = new Map<String, String>{'Message' => 'From Address is not found'};
                    wrapper.success =  new SuccesWrapper(); 
                sendErrorEmail('failed to process askDealer.', 'Orgwide address is not found');
                return wrapper;
            }
            String dealerportalURL = system.label.Dealer_Portal_Page_URL;
            // Create JSON object
            Map<String, Object> params = new Map<String, Object>();
            params.put('opportunityId', opp.Id);
            params.put('dealerId', dealerMarketcheckId);
            params.put('vehicleVin', vehicleVIN);
            params.put('vehicleName', vehicleName);
            params.put('type', 'askDealer');
            params.put('linkSharedDate', Date.today());
            params.put('garageId', garage.Id);
            String jsonParams = JSON.serialize(params);
            List<EmailTemplate> emailTemplate = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                                                 FROM EmailTemplate 
                                                 WHERE DeveloperName = 'Member_Response_For_Test_Drive_1719904116801' Limit 1];
            EmailTemplate empTemp = emailTemplate[0];                                                             
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String subject = empTemp.Subject;
            String htmlBody = empTemp.HtmlValue;
            String conLink = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
            if(subject != null){
                subject = subject.replace('Test Drive', 'Query');
                subject = subject.replace('{{{Opportunity.Auto_Shopper__c}}}', opp.Auto_Shopper__r.Name);
                subject = subject.replace('{{{VINNumber}}}', vehicleVIN);
                subject = subject.replace('{{{Opportunity.Card_Number__c}}}', memberLoanId);
            }
            if(htmlBody != null){
                htmlBody = acc <> null?  acc.Manager_Name__c <> null? htmlBody.replace('{{{ManagerName}}}', acc.Manager_Name__c):htmlBody.replace('{{{ManagerName}}}', acc.Name):htmlBody.replace('{{{ManagerName}}}','');
                htmlBody = htmlBody.replace('{{{MemberName}}}', opp.Auto_Shopper__r.Name);
                htmlBody = htmlBody.replace('{{{MemberResponse}}}', memberQuery);
                htmlBody = htmlBody.replace('Member Response', 'Member Query');
                htmlBody = htmlBody.replace('click here', '<a href="' +conLink+ '">click here</a>');
                htmlBody = htmlBody.replace('has responded for the recent discussion on the test drive.', 'is asking query.');
            }
            //String invalidAddrss = 'samplemail.com';
            String mailAddress = acc <> null? acc.Manager_Email__c : null;
            if(mailAddress != null && mailAddress != ''){
                email.setToAddresses(new List<String> { mailAddress });
                email.setCCAddresses(ccAddress );
            }else{
                email.setToAddresses(ccAddress);
            }
            email.setOrgWideEmailAddressId(orgWideEmail.Id);
            email.setSubject(subject);
            email.setHtmlBody(htmlBody);
            email.setSaveAsActivity(true); 
            email.setWhatId(garage.Id);
            emailList.add(email);
            
            if(mailAddress == null && ccAddress.size() == 0){
                Garage__c garageWithPendingRequest = new Garage__c();
                garageWithPendingRequest.Id = garage.Id;
                garageWithPendingRequest.Last_Member_Response_Ask_Dealer__c = System.now();
                garageWithPendingRequest.Pending_Requests__c = garage.Pending_Requests__c;
                
                CreateResponseWrapperSuccess emailDetails = new CreateResponseWrapperSuccess();
                emailDetails.VehicleVIN = VehicleVIN;
                emailDetails.LoanId = memberLoanId;
                emailDetails.MarketCheckId = dealerMarketcheckId;
                String memberQueryReq = email.getHtmlBody().substringBetween('Member Query:', 'Please <a href="');
                if(memberQueryReq!=null){
                    memberQueryReq = memberQueryReq.replaceAll('<[^>]*>', '');
                    memberQueryReq = memberQueryReq.replaceAll('\n', '');
                    memberQueryReq = decodeHtmlEntities(memberQueryReq);
                    emailDetails.EmailMessage = memberQueryReq;
                }
                emailDetails.Sender = 'Member';
                emailDetails.CreatedDate = System.now();
                String pendingReqJson = JSON.serialize(emailDetails);
                System.debug('Pending_Request_JSON__c  :: '+ garageWithPendingRequest.Pending_Request_JSON__c);
                
				garageWithPendingRequest.Pending_Request_JSON__c = processPendingReqJson(garage.Pending_Request_JSON__c, 'askDealer', JSON.serialize(emailDetails));
                if(garage.Pending_Requests__c <> null){
                    garageWithPendingRequest.Pending_Requests__c = garage.Pending_Requests__c + ';; Subject++'+email.getSubject()+'Body++'+email.getHtmlBody()+'Type++ askDealer';
                   /* Map<String, object> data = (Map<String, object>) JSON.deserializeUntyped(garage.Pending_Request_JSON__c );
                    if(data.containsKey('askDealer')){
                        String askDealerJson = JSON.serialize(data.get('askDealer'));
                        garageWithPendingRequest.Pending_Request_JSON__c = '{"askDealer":['+pendingReqJson + ',' + garage.Pending_Request_JSON__c.subStringAfter('[');
                    }*/
                }
                else{
                    garageWithPendingRequest.Pending_Requests__c = 'Subject++'+email.getSubject()+'Body++'+email.getHtmlBody()+'Type++ askDealer';
                  //  garageWithPendingRequest.Pending_Request_JSON__c = '{"askDealer":['+pendingReqJson+']}';
                    
                }
                update garageWithPendingRequest;
            }
            
            if (!Test.isRunningTest() && emailList.size() > 0 && (mailAddress <> null || ccAddress.size()>0)) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
                Garage__c garageWithoutPendingRequest = new Garage__c();
                garageWithoutPendingRequest.Id = garage.Id;
                garageWithoutPendingRequest.Last_Member_Response_Ask_Dealer__c = System.now();
                update garageWithoutPendingRequest;
                for (Messaging.SendEmailResult result : results) {
                    if (result.isSuccess()) {
                        SuccesWrapper wrapp = new SuccesWrapper();
                        wrapp.message = 'Ask Dealer request sent successfully';
                        wrapp.data = new List<CreateResponseWrapperSuccess>();
                        wrapper.success = wrapp;
                        wrapper.error = new Map<String, String>{};
                            } else {
                                
                                wrapper.error = new Map<String, String>{'Message' => 'Failed to send Ask dealer request.<br/> Error: ' + result.getErrors()[0].getMessage()};
                                    wrapper.success = new SuccesWrapper();
                                sendErrorEmail('failed to process askDealer.', result.getErrors()[0].getMessage()+'<br/> Request Type: Ask Dealer<br/>VIN: '+vehicleVIN+'<br/>Vehicle Name: '+vehicleName+'<br/>Opportunity Id: '+opp.Id+'<br/> Dealer Id: '+acc.Id);
                                
                            }  
                }
            }  else if(emailList.size() > 0 && mailAddress == null && ccAddress.size() == 0){
                SuccesWrapper wrapp = new SuccesWrapper();
                wrapp.message = 'Ask Dealer request sent successfully';
                wrapp.data = new List<CreateResponseWrapperSuccess>();
                wrapper.success = wrapp;
                wrapper.error = new Map<String, String>{};
                    }
            return wrapper;
        }
        catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('failed to process askDealer.',  errorMessage );
            return wrapper;
        }
    }
    
    public static String decodeHtmlEntities(String input) {
        // List of common HTML entities and their replacements
        Map<String, String> htmlEntities = new Map<String, String>{
            '&nbsp;' => '',
                '&lt;' => '',
                '&gt;' => '',
                '&amp;' => '',
                '&quot;' => '',
                '&#39;' => ''
                };
                    
                    // Replace each entity as empty
                    for (String entity : htmlEntities.keySet()) {
                        input = input.replace(entity, htmlEntities.get(entity));
                    }
        
        return input;
    }
    global static CreateResponseWrapper requestTestDriveResponse(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            Integer pageNumber = (Integer) requestBody.get('PageNumber');
            
            List<String> blankFields  = new List<String> ();
            if (String.isBlank(memberLoanId)){
                blankFields.add('LoanId');
            }
            if(String.isBlank(dealerMarketcheckId)){
                blankFields.add('FastPassDealerId');
            }
            if(String.isBlank(vehicleVIN)){
                blankFields.add('vehicleVIN');
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
            List<Garage__c> garList = [SELECT Id, Name, VIN__c, FastPass_Dealer_Id__c,Pending_Requests__c,Pending_Request_JSON__c  From Garage__c WHERE VIN__c =:vehicleVIN AND FastPass_Dealer_Id__c =: dealerMarketcheckId LIMIT 1];
            Garage__c gar = garList.size() > 0 ? garList[0] : null;
            if(gar == null){
                wrapper.error = new Map<String, String>{'Message' => 'No Vehicle found in garage'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestTestDriveResponse.', 'No Vehicle found in garage.<br/>Request Type: Test Drive Response<br/>VIN: '+vehicleVIN+'<br/>Opportunity Id: '+opp.Id);
                return wrapper;       
            }
			Map<String, DateTime> pendingReqDTMap = new Map<String, DateTime>();
            if(gar.Pending_Request_JSON__c != null){
                Map<String, object> dataMap = (Map<String, object>) JSON.deserializeUntyped(gar.Pending_Request_JSON__c );
                
                if(dataMap.containsKey('testDrive')){
                    String testDriveJson = JSON.serialize(dataMap.get('testDrive'));
                    List<FastPassIntegrationService.CreateResponseWrapperSuccess> conversations = (List<FastPassIntegrationService.CreateResponseWrapperSuccess>) JSON.deserialize(testDriveJson, List<FastPassIntegrationService.CreateResponseWrapperSuccess>.class);
                    if(conversations.size() > 0){
                        for(FastPassIntegrationService.CreateResponseWrapperSuccess eachConversation:conversations){
                            if(eachConversation.EmailMessage != null && eachConversation.CreatedDate != null ){
                                 pendingReqDTMap.put(eachConversation.EmailMessage, eachConversation.CreatedDate );
                            }
                        }
                    }
                    
                } 
            }
        
            
            String subjectPattern = 'Test Drive requested by ' + opp.Auto_Shopper__r.Name +' for ' +'#'+opp.Card_Number__c + ' in #' +  vehicleVIN;
            
            system.debug('Subject Pattern in Main Class::' + subjectPattern);
            List<EmailMessage> allEmails = [
                SELECT Id, Subject, FromAddress, ToAddress, Status, HtmlBody, TextBody, CreatedDate
                FROM EmailMessage
                WHERE RelatedToId = :gar.Id
                AND Subject LIKE :('%' + subjectPattern + '%')
                ORDER BY CreatedDate DESC];
            
            // Map to track unique combinations of HtmlBody and Date for specific phrases
            Map<String, Date> uniqueEmailsMap = new Map<String, Date>();
            //List<EmailMessage> uniqueEmails = new List<EmailMessage>();
            Set<Id> emailIds = new Set<Id>();
            system.debug('All mails:: '+ allEmails);
            for (EmailMessage email : allEmails) {
                // Extracting the date part of CreatedDate
                Date emailDate = email.CreatedDate.date();
                // Checking the email body for the Member Response Or Member Query
                Boolean isMemberQueryOrResponse = email.TextBody != null && 
                    (email.TextBody.contains('Member Query:') || email.TextBody.contains('Member Response:'));
                
                if (isMemberQueryOrResponse) {
                    // For emails with "Member Query:" or "Member Response:", check for duplicates
                    String uniqueKey = email.TextBody + '|' + emailDate;
                    system.debug('Unique key (Member Query/Response):: ' + uniqueKey);
                    
                    if (!uniqueEmailsMap.containsKey(uniqueKey)) {
                        uniqueEmailsMap.put(uniqueKey, emailDate);
                        //uniqueEmails.add(email);
                        emailIds.add(email.Id);
                    }
                } else if (email.HtmlBody != null && email.HtmlBody.contains('Dealer Response:')) {
                    // Include emails with "Dealer Response:" directly
                    //uniqueEmails.add(email);
                    emailIds.add(email.Id);
                } else if (email.HtmlBody != null && !email.HtmlBody.contains('Dealer Response:') && !email.HtmlBody.contains('Member Query:') && !email.HtmlBody.contains('Member Response:')){
                    emailIds.add(email.Id);
                }
            }
            
            List<EmailMessage> filteredMails = [SELECT Id, Subject, FromAddress, ToAddress, Status, HtmlBody, TextBody, CreatedDate FROM EmailMessage WHERE Id IN : emailIds ORDER BY CreatedDate DESC LIMIT 50 OFFSET :index];
            List<AggregateResult> coverastionCount = [SELECT COUNT(id) total FROM EmailMessage WHERE Id IN : emailIds];
            integer count = 0;
            
            if (!coverastionCount.isEmpty()) {
                count = (Integer) coverastionCount[0].get('total');
            }
            
            Decimal totalPages = count <= 50 ? 1: Math.ceil(count/50.0);
            
            system.debug('emailMessages::' +filteredMails);
            List<CreateResponseWrapperSuccess> conversations = new List<CreateResponseWrapperSuccess>();
            for (EmailMessage email : filteredMails) {
                CreateResponseWrapperSuccess emailDetails = new CreateResponseWrapperSuccess();
                emailDetails.VehicleVIN = VehicleVIN;
                emailDetails.LoanId = memberLoanId;
                emailDetails.MarketCheckId = dealerMarketcheckId;
                emailDetails.CreatedDate = email.CreatedDate;
                String emailBody = email.HtmlBody;
                
                //Extract the specific line based on the keywords
                if(emailBody.contains('Member Response:')){
                    system.debug('Email Body::'+emailBody);
                    String memberResponse = emailBody.substringBetween('Member Response:', 'Please <a href="');
                    if(memberResponse!=null){
                        memberResponse = memberResponse.replaceAll('<br/>','\n');
                        memberResponse = memberResponse.replaceAll('<[^>]*>', '');
                        memberResponse = memberResponse.replaceAll('\n', '');
                        memberResponse = decodeHtmlEntities(memberResponse);
                        emailDetails.EmailMessage = memberResponse;
                    }
                    emailDetails.Sender = 'Member';
                    
                } else if(emailBody.contains('Member Query:')){
                    String memberQuery = emailBody.substringBetween('Member Query: ', 'Please <a href="');
                    if(memberQuery!=null){
                        memberQuery = memberQuery.replaceAll('<br/>','\n');
                        memberQuery = memberQuery.replaceAll('<[^>]*>', '');
                        memberQuery = memberQuery.replaceAll('\n\n', '');
						
                        memberQuery = decodeHtmlEntities(memberQuery);
                        String vehicle = emailBody.substringBetween('Vehicle Name: ', '<br />');
                        String testDriveDate = emailBody.substringBetween('Test Drive Date: ', '<br />');
                        String body = 'Can you provide the test drive for '+vehicle+' on '+testDriveDate+'. ';
                        body += memberQuery;
                        emailDetails.EmailMessage = body;
                    }
                    emailDetails.Sender = 'Member';
                    
                }else if(emailBody.contains('Dealer Response:')){
                    //String dealerResponse = extractLine(emailBody, 'Dealer Response');
                    system.debug('Email Body::'+emailBody);
                    String dealerResponse = emailBody.substringBetween('Dealer Response: ', '</body>');
                    system.debug('Dealer Response::' +dealerResponse);
                    if(dealerResponse!=null){
                        dealerResponse = dealerResponse.replaceAll('<[^>]*>', '');
                        dealerResponse = dealerResponse.replaceAll('\n', '');
                        dealerResponse = decodeHtmlEntities(dealerResponse);
                        emailDetails.EmailMessage = dealerResponse;
                    } else {
                        dealerResponse = emailBody.substringAfter('Dealer Response: ');
                        emailDetails.EmailMessage = dealerResponse;
                    }
                    
                    emailDetails.Sender = 'Dealer';
                }else if(!emailBody.contains('Member Query:') && !emailBody.contains('Member Response:') && !emailBody.contains('Dealer Response:')){
                    system.debug('email body::'+emailBody);
                    String Vehicle = emailBody.substringBetween('Vehicle Name: ', '<br />');
                    String testDriveDate = emailBody.substringBetween('Test Drive Date: ', '<br/>');
                    system.debug('Test Drive Date:: ' + testDriveDate);
                    emailDetails.EmailMessage = 'Can you provide the test drive for '+vehicle+' on '+testDriveDate+'.';
                    emailDetails.Sender = 'Member';
                }
                if(pendingReqDTMap.ContainsKey(emailDetails.EmailMessage)){
                    emailDetails.CreatedDate = pendingReqDTMap.get(emailDetails.EmailMessage);
                }
                conversations.add(emailDetails);
            }
            if(filteredMails.size() == 0 && gar.Pending_Requests__c != null && gar.Pending_Request_JSON__c != null && pageNumber == 1 ) {
                
                Map<String, object> dataMap = (Map<String, object>) JSON.deserializeUntyped(gar.Pending_Request_JSON__c );
                
                if(dataMap.containsKey('testDrive')){
                    String testDriveJson = JSON.serialize(dataMap.get('testDrive'));
                    conversations = (List<FastPassIntegrationService.CreateResponseWrapperSuccess>) JSON.deserialize(testDriveJson, List<FastPassIntegrationService.CreateResponseWrapperSuccess>.class);
                }   
            }
            system.debug('Conversations::' +conversations);
            SuccesWrapper wrapp = new SuccesWrapper();
            wrapp.message = 'Conversations Fetched Successfully';
            wrapp.data = conversations;
            wrapp.currentPage = pageNumber;
            wrapp.totalPages = (Integer)totalPages;
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
    
    global static CreateResponseWrapper requestAskDealerResponse(Map<String, Object> requestBody) {
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            String memberLoanId = (String) requestBody.get('LoanId');
            String dealerMarketcheckId = (String) requestBody.get('FastPassDealerId');
            String vehicleVIN = (String) requestBody.get('VehicleVIN');
            Integer pageNumber = (Integer) requestBody.get('PageNumber');
            
            List<String> blankFields  = new List<String> ();
            if (String.isBlank(memberLoanId)){
                blankFields.add('LoanId');
            }
            if(String.isBlank(dealerMarketcheckId)){
                blankFields.add('FastPassDealerId');
            }
            if(String.isBlank(vehicleVIN)){
                blankFields.add('vehicleVIN');
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
                sendErrorEmail('failed to process requestTestDriveResponse.', 'Required fields are missing: '+nullFields+'<br/>Request Type: Ask Dealer Response');
                
                return wrapper;
            }
            
            Integer index = (PageNumber - 1) * 50;
            List<opportunity>  oppList = [SELECT Id, Auto_Shopper__r.Name, Card_Number__c, Vehicle_VIN__c
                                          FROM Opportunity 
                                          WHERE Card_Number__c = :memberLoanId
                                          LIMIT 1];
            
            Opportunity opp = oppList.size() > 0 ? oppList[0] : null;
            if(opp == null){
                wrapper.error = new Map<String, String>{'Message' => 'No Opportunity found with the provided LoanId'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestAskDealerResponse.', 'No Opportunity found with the provided LoanId.<br/>Request Type: Test Drive Response<br/>VIN: '+vehicleVIN+'<br/>LoanId: '+memberLoanId);
                return wrapper;       
            }
            List<Garage__c> garList = [SELECT Id, Name, VIN__c, FastPass_Dealer_Id__c,Pending_Requests__c,Pending_Request_JSON__c  From Garage__c WHERE VIN__c =:vehicleVIN AND FastPass_Dealer_Id__c =: dealerMarketcheckId LIMIT 1];
            Garage__c gar = garList.size() > 0 ? garList[0] : null;
            if(gar == null){
                wrapper.error = new Map<String, String>{'Message' => 'No Vehicle found in garage'};
                    wrapper.success = new SuccesWrapper();
                sendErrorEmail('failed to process requestAskDealerResponse.', 'No Vehicle found in garage.<br/>Request Type: Test Drive Response<br/>VIN: '+vehicleVIN+'<br/>Opportunity Id: '+opp.Id);
                return wrapper;       
            }
            String subjectPattern = 'Query requested by ' + opp.Auto_Shopper__r.Name +' for ' +'#'+opp.Card_Number__c + ' in #' +  vehicleVIN;
            List<EmailMessage> allEmails = [
                SELECT Id, Subject, FromAddress, ToAddress, Status, HtmlBody, TextBody, CreatedDate
                FROM EmailMessage
                WHERE RelatedToId = :gar.Id
                AND Subject LIKE :('%' + subjectPattern + '%')
                ORDER BY CreatedDate DESC];
            
            // Map to track unique combinations of HtmlBody and Date for specific phrases
            Map<String, Date> uniqueEmailsMap = new Map<String, Date>();
            List<EmailMessage> uniqueEmails = new List<EmailMessage>();
            Set<Id> emailIds = new Set<Id>();
            system.debug('All mails:: '+ allEmails);
            for (EmailMessage email : allEmails) {
                // Extracting the date part of CreatedDate
                Date emailDate = email.CreatedDate.date();
                // Checking the email body for the Member Response Or Member Query
                Boolean isMemberQueryOrResponse = email.TextBody != null && 
                    email.TextBody.contains('Member Query:');
                
                if (isMemberQueryOrResponse) {
                    // For emails with "Member Query:", check for duplicates
                    String uniqueKey = email.TextBody + '|' + emailDate;
                    system.debug('Unique key (Member Query):: ' + uniqueKey);
                    
                    if (!uniqueEmailsMap.containsKey(uniqueKey)) {
                        uniqueEmailsMap.put(uniqueKey, emailDate);
                        uniqueEmails.add(email);
                        emailIds.add(email.Id);
                    }
                } else if (email.HtmlBody != null && email.HtmlBody.contains('Dealer Response:')) {
                    // Include emails with "Dealer Response:" directly
                    uniqueEmails.add(email);
                    emailIds.add(email.Id);
                }
            }
            
            List<EmailMessage> filteredMails = [SELECT Id, Subject, FromAddress, ToAddress, Status, HtmlBody, TextBody, CreatedDate FROM EmailMessage WHERE Id IN : emailIds ORDER BY CreatedDate DESC LIMIT 50 OFFSET :index];
            List<AggregateResult> coverastionCount = [SELECT COUNT(id) total FROM EmailMessage WHERE Id IN : emailIds];
            integer count = 0;
            
            if (!coverastionCount.isEmpty()) {
                count = (Integer) coverastionCount[0].get('total');
            }
            
            Decimal totalPages = count <= 50 ? 1: Math.ceil(count/50.0);
            Map<String, DateTime> pendingReqDTMap = new Map<String, DateTime>();
            if(filteredMails.size() > 0){
                if(gar.Pending_Request_JSON__c != null){
                    Map<String, object> dataMap = (Map<String, object>) JSON.deserializeUntyped(gar.Pending_Request_JSON__c );
                    if(dataMap.containsKey('askDealer')){
                        String testDriveJson = JSON.serialize(dataMap.get('askDealer'));
                        List<FastPassIntegrationService.CreateResponseWrapperSuccess> conversations = (List<FastPassIntegrationService.CreateResponseWrapperSuccess>) JSON.deserialize(testDriveJson, List<FastPassIntegrationService.CreateResponseWrapperSuccess>.class);
                        if(conversations.size() > 0){
                            for(FastPassIntegrationService.CreateResponseWrapperSuccess eachConversation:conversations){
                                if(eachConversation.EmailMessage != null && eachConversation.CreatedDate != null ){
                                    pendingReqDTMap.put(eachConversation.EmailMessage, eachConversation.CreatedDate );
                                }
                            }
                        }
                    } 
                }
            }
            
            
            List<CreateResponseWrapperSuccess> conversations = new List<CreateResponseWrapperSuccess>();
            for (EmailMessage email : filteredMails) {
                CreateResponseWrapperSuccess emailDetails = new CreateResponseWrapperSuccess();
                emailDetails.VehicleVIN = VehicleVIN;
                emailDetails.LoanId = memberLoanId;
                emailDetails.MarketCheckId = dealerMarketcheckId;
                emailDetails.CreatedDate = email.CreatedDate;
                String emailBody = email.HtmlBody;
                if(emailBody.contains('Dealer Response:')){
                    system.debug('Email Body::'+emailBody);
                    String dealerResponse = emailBody.substringBetween('Dealer Response: ', '</body>');
                    if(dealerResponse!=null){
                        dealerResponse = dealerResponse.replaceAll('<[^>]*>', '');
                        dealerResponse = dealerResponse.replaceAll('\n', '');
                        dealerResponse = decodeHtmlEntities(dealerResponse);
                        emailDetails.EmailMessage = dealerResponse;
                    } else {
                        dealerResponse = emailBody.substringAfter('Dealer Response: ');
                        emailDetails.EmailMessage = dealerResponse;
                    }
                    
                    emailDetails.Sender = 'Dealer';
                } else if(emailBody.contains('Member Query:')){
                    String memberQuery = emailBody.substringBetween('Member Query:', 'Please <a href="');
                    if(memberQuery!=null){
                        memberQuery = memberQuery.replaceAll('<[^>]*>', '');
                        memberQuery = memberQuery.replaceAll('\n', '');
                        memberQuery = decodeHtmlEntities(memberQuery);
                        emailDetails.EmailMessage = memberQuery;
                    }
                    emailDetails.Sender = 'Member';    
                }
                if(pendingReqDTMap.ContainsKey(emailDetails.EmailMessage)){
                    emailDetails.CreatedDate = pendingReqDTMap.get(emailDetails.EmailMessage);
                }
                conversations.add(emailDetails);  
            }
			
			System.debug('filteredMails');
            if(filteredMails.size() == 0 && gar.Pending_Requests__c != null && gar.Pending_Request_JSON__c != null && pageNumber == 1 ) {
                System.debug('filteredMails');
                List<String> pendingEmails = gar.Pending_Requests__c.split(';;');
                System.debug('filteredMails  '+ pendingEmails.size());
                
              
                Map<String, object> data = (Map<String, object>) JSON.deserializeUntyped(gar.Pending_Request_JSON__c );
                System.Debug(data);
                
                if(data.containsKey('askDealer')){
                    String askDealerJson = JSON.serialize(data.get('askDealer'));
                    conversations = (List<FastPassIntegrationService.CreateResponseWrapperSuccess>) JSON.deserialize(askDealerJson, List<FastPassIntegrationService.CreateResponseWrapperSuccess>.class);
                    System.Debug(data.get('askDealer'));
                }
            }
            SuccesWrapper wrapp = new SuccesWrapper();
            wrapp.message = 'Conversations Fetched Successfully';
            wrapp.data = conversations;
            wrapp.currentPage = pageNumber;
            wrapp.totalPages = (Integer)totalPages;
            wrapper.success = wrapp;
            wrapper.error = new Map<String, String>{};
                return wrapper;
        }catch(Exception e){
            wrapper.error = new Map<String, String>{'Message' => 'Somthing went wrong.'};
                wrapper.success = new SuccesWrapper();
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            sendErrorEmail('failed to process askDealerResponse.',  errorMessage );
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
    }
    
    global class CreateResponseWrapperSuccess {
        Public String VehicleVIN;
        Public String LoanId;
        Public String MarketCheckId;
        Public DateTime CreatedDate;
        public String Sender;
        public String EmailMessage;
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

    public static String processPendingReqJson(String jsonStr, String request, String newJson){
        Map<String, object> data;
        if(jsonStr != null){
            data = (Map<String, object>) JSON.deserializeUntyped(jsonStr );
        }
        
        if(data != null && data.containsKey(request)){
            System.Debug('Inside Already req :: '); 
            String askDealerJson = JSON.serialize(data.get(request));
             System.Debug('askDealerJson :: ' + askDealerJson); 
            String replaceStr = '"'+request+'":'+ askDealerJson;
              
            askDealerJson = '"'+request+'":['+newJson + ',' + askDealerJson.subStringAfter('['); //
            System.Debug('Old JSON :: '+jsonStr);
            System.Debug('replaceStr :: '+ replaceStr); 
            System.Debug('New JSON :: '+askDealerJson); 
           // jsonStr = jsonStr.replace(replaceStr,askDealerJson);
           //	data.remove(request);
            //data.put(request, askDealerJson);
            //jsonStr = JSON.serialize(data);
            System.Debug('After Replace :: '+jsonStr);
            
            Integer requestIndex = jsonStr.indexOf('"'+request+'":');
            if (requestIndex != -1) {
                Integer askDealerEndIndex = jsonStr.indexOf(']', requestIndex) + 1;
                String req = jsonStr.substring(requestIndex, askDealerEndIndex);
                System.Debug('req :: '+req);
                jsonStr = jsonStr.replace(req,askDealerJson);
            }
        }
        else if(jsonStr != null){
             System.Debug('Inside 2nd req :: '); 
            jsonStr = jsonStr.substringBefore(']}')+'],'+'"'+request+'":['+newJson+']}';
        }
        else{
            System.Debug('Inside New :: '); 
            jsonStr = '{"'+request+'":['+newJson+']}';
        }
        
        return jsonStr;
    }
}