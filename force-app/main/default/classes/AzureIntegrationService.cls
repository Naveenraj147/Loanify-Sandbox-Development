@RestResource(urlMapping='/AzureIntegrationService/*')
global without sharing class AzureIntegrationService {
    
    @HttpPost
    global static CreateResponseWrapper doPost(){
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        String action = '';
        try{
            RestRequest req = RestContext.request;
            system.debug('request = '+req);
            RestResponse res = RestContext.response;
            action = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            System.debug('Action: '+action);
            if(action=='CreateMemberData' || action=='CreateDealerProData' || action=='CreateServiceRepData'){
                wrapper = createContacts();
            }else if(action=='CreateLoanData'){
                wrapper = createOpportunities();
            }else if(action=='CreateDealerData' || action=='CreateBankData'){
                wrapper = createAccounts();
            }else{
                wrapper.error = new Map<String,String>{'NOT_FOUND'=>'Could not find a match for URL'};
                    wrapper.success = new Map<String,String>();
            }
            if(!wrapper.error.isEmpty())
                sendErrorEmail('failed to '+action, JSON.serialize(wrapper.error));
            System.debug('successData: '+wrapper.success);
            System.debug('errorData: '+wrapper.error);
            return wrapper;  
        }catch (Exception e) {
            // Handling exceptions and returning an error message
            RestResponse res = RestContext.response;
            res.statusCode = 500;
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            wrapper.error = new Map<String,String>{'exception'=>errorMessage};
                wrapper.success = new Map<String,String>();
            System.debug('Exception:'+errorMessage);
            sendErrorEmail('failed to '+action, errorMessage);
            return wrapper;
        }
    }
    
    public static CreateResponseWrapper createAccounts(){
        RestRequest req = RestContext.request;
        String action = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        // Deserialize the JSON request body into a list of Contact records
        List<Account> accList = (List<Account>)JSON.deserialize(req.requestBody.tostring(), List<Account>.class);
        Map<String,String> successData = new Map<String,String>();
        Map<String,String> errorData = new Map<String,String>();
        if(!accList.isEmpty()){
            String recTypeName = action=='CreateDealerData' ? 'Auto_Dealer' : 'Bank';
            RecordType accRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType = 'Account' and DeveloperName=:recTypeName];
            //assign record type
            for(Account each : accList){
                each.RecordTypeId = accRecType!=null ? accRecType.Id : null;
            }
            
            List<Database.SaveResult> results = Database.insert(accList, false);
            DatabaseSaveResultsWrapper resultsWrapper = processDatabaseSaveResults(results);
            Set<Id> successIds = resultsWrapper.successIds;
            if(errorData.isEmpty()){
                errorData = resultsWrapper.error;
            }else if(!resultsWrapper.error.isEmpty()){
                for(String error : resultsWrapper.error.keySet()){
                    if(errorData.containsKey(error)){
                        String temp = errorData.get(error);
                        if(temp!=resultsWrapper.error.get(error))
                            temp += resultsWrapper.error.get(error);
                        errorData.put(error, temp);
                    }else
                        errorData.put(error, resultsWrapper.error.get(error));
                }
            }
            if(!successIds.isEmpty()){
                for(Account each : accList){
                    if(successIds.contains(each.Id)){
                        successData.put(each.Name, each.Id);
                    }
                }
            }
        }
        wrapper.success = successData;
        wrapper.error = errorData;
        System.debug('successData: '+successData);
        System.debug('errorData: '+errorData);
        return wrapper;
    }
    
    public static CreateResponseWrapper createContacts(){
        RestRequest req = RestContext.request;
        String action = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        // Deserialize the JSON request body into a list of Contact records
        List<Contact> conList = (List<Contact>)JSON.deserialize(req.requestBody.tostring(), List<Contact>.class);
        String conRecTypeName = action=='CreateMemberData' ? 'Auto_Shopper' : action=='CreateDealerProData' ? 'Auto_Dealer_Pro' : action=='CreateServiceRepData' ? 'Bank_Service_Rep' : null;
        RecordType conRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType = 'Contact' and DeveloperName=:conRecTypeName];
        Set<String> emailSet = new Set<String>();
        //assign record type
        for(Contact each : conList){
            System.debug('Con:'+each);
            each.RecordTypeId = conRecType!=null ? conRecType.Id : null;
            if(each.Email!=null)
                emailSet.add(each.Email);
        }
        
        Map<String,Contact> existingContacts = new Map<String,Contact>();
        for(Contact each : [select Id,Name,Email from Contact where Email in :emailSet]){
            existingContacts.put(each.Email, each);
        }
        System.debug('existingContacts:'+existingContacts);
        List<Contact> newConList = new List<Contact>();
        Map<String,String> successData = new Map<String,String>();
        Map<String,String> errorData = new Map<String,String>();
        String errorCode =  action=='CreateDealerProData' ? 'DEALER_ID_NOT_FOUND' : 'BANK_ID_NOT_FOUND';
        System.debug('here #0');
        for(Contact each : conList){
            System.debug('here #0.1'+ each);
            if((action=='CreateDealerProData' || action=='CreateServiceRepData') && (each.AccountId==null || each.get('AccountId')==null)){
                System.debug('here #0.2'+ each);
                if(errorData.containsKey(errorCode)){
                    System.debug('here #0.3'+ each);
                    String contactNames = errorData.get(errorCode);
                    contactNames += ', '+each.FirstName+' '+each.LastName;
                    errorData.put(errorCode,contactNames);
                }else
                    errorData.put(errorCode, each.FirstName+' '+each.LastName);
                continue;
            }
            System.debug('here #0.4'+ each);
            if(existingContacts.containsKey(each.Email))
                successData.put(each.Email, existingContacts.get(each.Email).Id);
            else
                newConList.add(each);
        }
        
        System.debug('here #1');
        // Inserting the Contact records
        if(!newConList.isEmpty()){
            List<Database.SaveResult> results = Database.insert(newConList, false);
            DatabaseSaveResultsWrapper resultsWrapper = processDatabaseSaveResults(results);
            Set<Id> successIds = resultsWrapper.successIds;
            if(errorData.isEmpty()){
                errorData = resultsWrapper.error;
            }else if(!resultsWrapper.error.isEmpty()){
                for(String error : resultsWrapper.error.keySet()){
                    if(errorData.containsKey(error)){
                        String temp = errorData.get(error);
                        if(temp!=resultsWrapper.error.get(error))
                            temp += resultsWrapper.error.get(error);
                        errorData.put(error, temp);
                    }else
                        errorData.put(error, resultsWrapper.error.get(error));
                }
            }
            if(!successIds.isEmpty()){
                for(Contact each : newConList){
                    if(successIds.contains(each.Id)){
                        successData.put(each.Email, each.Id);
                    }
                }
            }
        }
        System.debug('here #1');
        wrapper.success = successData;
        wrapper.error = errorData;
        System.debug('successData: '+successData);
        System.debug('errorData: '+errorData);
        return wrapper;
    }
    
    public static CreateResponseWrapper createOpportunities(){
        RestRequest req = RestContext.request;
        String action = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        // Deserialize the JSON request body into a list of Opportunity records
        List<Opportunity> oppList = (List<Opportunity>)JSON.deserialize(req.requestBody.tostring(), List<Opportunity>.class);
        Map<String,String> successData = new Map<String,String>();
        Map<String,String> errorData = new Map<String,String>();
        if(!oppList.isEmpty()){
            Map<String,Id> accIdMap = new Map<String,Id>();
            Map<String,Id> conIdMap = new Map<String,Id>();
            Map<Id,Account> accMap = new Map<Id,Account>();
            Map<Id,Contact> conMap = new Map<Id,Contact>();
            for(Opportunity each : oppList){
                if(String.isNotBlank(each.Branch__c))
                    accIdMap.put(each.Branch__c,null);
                if(String.isNotBlank(each.Bank_Service_Rep_Name_MSR__c))
                    conIdMap.put(each.Bank_Service_Rep_Name_MSR__c,null);
                
            }
            if(!accIdMap.isEmpty()){
                List<RecordType> bankRecTypeList = [select Id,Name from RecordType where DeveloperName ='Bank' and SobjectType='Account'];
                System.debug('accIdMap:'+accIdMap);
                accMap = new Map<Id,Account>([select Id,Name from Account where Name in :accIdMap.keySet() and RecordType.DeveloperName ='Bank']);
                for(Account acc : accMap.values()){
                    accIdMap.put(acc.Name, acc.Id);
                }
                System.debug('accIdMap:'+accIdMap);
                List<Account> newAccounts = new List<Account>();
                for(String accName : accIdMap.keySet()){
                    if(accIdMap.get(accName)==null)
                        newAccounts.add(new Account(Name=accName, RecordTypeId=bankRecTypeList[0].Id)); 
                }
                System.debug('newAccounts:'+newAccounts);
                if(!newAccounts.isEmpty()){
                    insert newAccounts;
                    for(Account acc: newAccounts){
                        accIdMap.put(acc.Name, acc.Id);
                    }
                }
                System.debug('accIdMap:'+accIdMap);
            }
            Map<Id,Map<String,Id>> accConsMap = new Map<Id,Map<String,Id>>();
            if(conIdMap!=null){
                conMap = new Map<Id,Contact>([select Id,Name,AccountId from Contact where Name in :conIdMap.keySet() and AccountId!=null and RecordType.DeveloperName ='Bank_Service_Rep']);
                for(Contact con : conMap.values()){
                    if(!accConsMap.containsKey(con.AccountId)){
                        accConsMap.put(con.AccountId, new Map<String,Id>());
                    }
                    Map<String,Id> temp = accConsMap.get(con.AccountId);
                    temp.put(con.Name,con.Id);
                    accConsMap.put(con.AccountId,temp);
                }
            }
            for(Opportunity each : oppList){
                if(String.isNotBlank(each.Branch__c) && accIdMap.containsKey(each.Branch__c)){
                    each.Branch__c = accIdMap.get(each.Branch__c);
                    if(String.isNotBlank(each.Bank_Service_Rep_Name_MSR__c) && accConsMap.containsKey(each.Branch__c)){
                        if(accConsMap.get(each.Branch__c).containsKey(each.Bank_Service_Rep_Name_MSR__c)){
                            each.Bank_Service_Rep_Name_MSR__c = accConsMap.get(each.Branch__c).get(each.Bank_Service_Rep_Name_MSR__c);
                        }else
                            each.Bank_Service_Rep_Name_MSR__c = null;
                    }else
                        each.Bank_Service_Rep_Name_MSR__c = null;
                }else{
                    each.Branch__c = null;
                    each.Bank_Service_Rep_Name_MSR__c = null;
                }
                
            }
            List<Database.SaveResult> results = Database.insert(oppList, false);
            DatabaseSaveResultsWrapper resultsWrapper = processDatabaseSaveResults(results);
            Set<Id> successIds = resultsWrapper.successIds;
            if(errorData.isEmpty()){
                errorData = resultsWrapper.error;
            }else if(!resultsWrapper.error.isEmpty()){
                for(String error : resultsWrapper.error.keySet()){
                    if(errorData.containsKey(error)){
                        String temp = errorData.get(error);
                        if(temp!=resultsWrapper.error.get(error))
                            temp += resultsWrapper.error.get(error);
                        errorData.put(error, temp);
                    }else
                        errorData.put(error, resultsWrapper.error.get(error));
                }
            }
            if(!successIds.isEmpty()){
                for(Opportunity each : oppList){
                    if(successIds.contains(each.Id)){
                        successData.put(each.Name, each.Id);
                    }
                }
            }
        }
        wrapper.success = successData;
        wrapper.error = errorData;
        return wrapper;
    }
    
    public static DatabaseSaveResultsWrapper processDatabaseSaveResults(List<Database.SaveResult> results){
        DatabaseSaveResultsWrapper wrapper = new DatabaseSaveResultsWrapper();
        Map<String,String> errorData = new Map<String,String>();
        Set<Id> successIds = new Set<Id>();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {   
                String error='';
                for(Database.Error each : result.getErrors()) {
                    error = each.getMessage() + (each.getFields()!=null ? ' Fields: ' + each.getFields() : '') +';';   
                    if(errorData.containsKey(each.getStatusCode()+'')){
                        String temp = errorData.get(each.getStatusCode()+'');
                        if(temp!=error)
                            temp += error;
                        errorData.put(each.getStatusCode()+'', temp);
                    }else
                        errorData.put(each.getStatusCode()+'', error);
                }
                
            }else{
                successIds.add(result.getId());
            }
            System.debug('Result:'+result);
        }
        wrapper.error = errorData;
        wrapper.successIds = successIds;
        return wrapper;
    }
    
    public static void sendErrorEmail(String subjectReason, String exceptionMessage){
        
        if(String.isBlank(Label.Exception_Email_Recipients))        
            return;
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        /*List<EmailTemplate> template = [SELECT DeveloperName, Id, Subject, HtmlValue, Body FROM EmailTemplate Where DeveloperName = 'Exception_Email_Template'];
String templateSubject = template[0].Subject;
templateSubject = templateSubject.replace('{reason}', subjectReason);
String body = template[0].HtmlValue;
body = body.replace('{exceptionMessage}', exceptionMessage);*/
        
        String subject = 'AzureIntegrationService - '+subjectReason;
        String body = 'Following exception has occurred in AzureIntegrationService.<br/><br/> Exception:'+exceptionMessage+'<br/><br/>Regards,<br/>Admin';
        
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
    
    global class CreateResponseWrapper {
        public Map<String,String> success;
        public Map<String,String> error;
    }
    
    global class DatabaseSaveResultsWrapper {
        public Set<Id> successIds;
        public Map<String,String> error;
    }
    
    public class ErrorDetails {
        public Integer count;
        public String body;
        public String recordId;
        public String sObjectName;
        public String userId;
        
        
        public ErrorDetails(Integer count, String body, String recordId, String sObjectName, String userId) {
            this.count = count;
            this.body = body;
            this.recordId = recordId;
            this.sObjectName = sObjectName;
            this.userId = userId;
        }
    }
    
    @future(callout=true)
    public static void updateDataInAzure(List<string> serializedDataList) {
        List<ErrorDetails> failedRecords = new List<ErrorDetails>();
        List<String> processedRecords = new List<String>();
        try {
            if(!serializedDataList.isEmpty()){
                Integer count = 1;
                Salesforce_webhook__mdt metaDataField = [SELECT Update_Dealer__c, Update_Branch__c, Update_MSR__c, Update_Dealerhosts__c,Update_Member__c, Access_Token__c 
                                                         FROM Salesforce_webhook__mdt 
                                                         WHERE DeveloperName = 'Azure_Integration_Service'];
                
                if (metaDataField != null && metaDataField.Access_Token__c != null && metaDataField.Access_Token__c != '') {
                    String accessToken = metaDataField.Access_Token__c;
                    System.debug('accessToken:' + accessToken);
                    for(String serializedData:serializedDataList){
                        System.debug('Serialized Data::' + serializedData);
                        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(serializedData);
                        if (data.containsKey('Id')) {
                            String sfId = (String) data.get('Id');
                            data.put('Sf_Uid', sfId);
                            Id recordId = Id.valueOf(sfId);
                            
                            String mobilePhoneNumber = data.containsKey('MobilePhone')? ((String)data.get('MobilePhone')): null;
                            String phoneNumber = data.containsKey('Phone')?((String)data.get('Phone')): null;
                            String managerCellPhone = data.containsKey('Manager_Cell_Phone__c')?((String)data.get('Manager_Cell_Phone__c')):null;
                            String leadMSRCellPhone = data.containsKey('Lead_MSR_Cell_Phone__c')?((String)data.get('Lead_MSR_Cell_Phone__c')):null;
                            String projectManagerCellPhone = data.containsKey('Project_Manager_Cell_Phone__c')?((String)data.get('Project_Manager_Cell_Phone__c')):null;
                            String fIManagerCellPhone = data.containsKey('F_I_Manager_Cell_Phone__c')?((String)data.get('F_I_Manager_Cell_Phone__c')):null;
                            
                            if(mobilePhoneNumber != null){
                                if (mobilePhoneNumber.startsWith('+1')) {
                                    mobilePhoneNumber = mobilePhoneNumber.substring(2);
                                    data.put('MobilePhone', mobilePhoneNumber);
                                } 
                            }
                            if(phoneNumber != null){
                                if (phoneNumber.startsWith('+1')) {
                                    phoneNumber = phoneNumber.substring(2);
                                    data.put('Phone', phoneNumber);
                                }     
                            }
                            if(managerCellPhone != null){
                                if (managerCellPhone.startsWith('+1')) {
                                    managerCellPhone = managerCellPhone.substring(2);
                                    data.put('Manager_Cell_Phone__c', managerCellPhone);
                                }   
                            } 
                            if(leadMSRCellPhone != null){
                                if (leadMSRCellPhone.startsWith('+1')) {
                                    leadMSRCellPhone = leadMSRCellPhone.substring(2);
                                    data.put('Lead_MSR_Cell_Phone__c', leadMSRCellPhone);
                                }   
                            }
                            if(projectManagerCellPhone != null){
                                if (projectManagerCellPhone.startsWith('+1')) {
                                    projectManagerCellPhone = projectManagerCellPhone.substring(2);
                                    data.put('Project_Manager_Cell_Phone__c', projectManagerCellPhone);
                                }   
                            }
                            if(fIManagerCellPhone != null){
                                if (fIManagerCellPhone.startsWith('+1')) {
                                    fIManagerCellPhone = fIManagerCellPhone.substring(2);
                                    data.put('F_I_Manager_Cell_Phone__c', fIManagerCellPhone);
                                }   
                            } 
                            
                            String sObjName = recordId.getSObjectType().getDescribe().getName();
                            String endpointUrl;
                            String requestMethod = 'POST';
                            
                            if (sObjName == 'Contact') {
                                
                                List<Contact> contactList = [SELECT Id, RecordType.DeveloperName FROM Contact WHERE Id =: sfId LIMIT 1];
                                
                                if (!contactList.isEmpty()) {
                                    Contact contact = contactList[0];
                                    if (contact.RecordType.DeveloperName == 'Bank_Service_Rep') {
                                        endpointUrl = metaDataField.Update_MSR__c;
                                    } else if (contact.RecordType.DeveloperName == 'Auto_Dealer_Pro') {
                                        endpointUrl = metaDataField.Update_Dealerhosts__c;
                                    } else if (contact.RecordType.DeveloperName == 'Auto_Shopper') {
                                        endpointUrl = metaDataField.Update_Member__c;
                                        requestMethod = 'PUT';  
                                    }
                                }
                            } 
                            else if (sObjName == 'Account') {
                                
                                List<Account> accountList = [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id =: sfId LIMIT 1];
                                
                                if (!accountList.isEmpty()) {
                                    Account account = accountList[0];
                                    if (account.RecordType.DeveloperName == 'Auto_Dealer') {
                                        endpointUrl = metaDataField.Update_Dealer__c;
                                    } else if (account.RecordType.DeveloperName == 'Bank') {
                                        endpointUrl = metaDataField.Update_Branch__c;
                                    }
                                }
                            }
                            if (endpointUrl != null) {
                                String requestBody = JSON.serialize(data);
                                System.debug('Serialized Data::' + requestBody);
                                
                                HTTPRequest request = new HTTPRequest();
                                request.setEndpoint(endpointUrl);
                                request.setMethod(requestMethod);
                                request.setHeader('Authorization', 'Bearer ' + accessToken);
                                request.setHeader('Content-Type', 'application/json');
                                request.setBody(requestBody);
                                System.debug('Body ::' + request.getBody());
                                
                                HTTPResponse response = new Http().send(request);
                                System.debug('Response::' + response);
                                
                                if (response.getStatusCode() == 200) {
                                    String responseBody = response.getBody();
                                    if (responseBody.contains('error')) {
                                        System.debug('Error occurred in the Response Body for status code 200. Error: ' + responseBody + '\nRecord Id::' + sfId);
                                        failedRecords.add(new ErrorDetails(count++, responseBody, sfId, sObjName, UserInfo.getUserId()));    
                                    } else if(!responseBody.contains('successfully')){
                                        System.debug('Error occurred in the Response Body for status code 200. Error: ' + responseBody +'\nRecord Id::' + sfId);
                                        failedRecords.add(new ErrorDetails(count++, responseBody, sfId, sObjName, UserInfo.getUserId()));
                                    } else {
                                        System.debug(responseBody);
                                    }
                                } else {
                                    System.debug('Error updating data in Azure. Status code: ' + response.getStatusCode());
                                    System.debug('Response body: ' + response.getBody()+'\nRecord Id::' + sfId);
                                    failedRecords.add(new ErrorDetails(count++, 'Status Code: ' + response.getStatusCode()+'<br/>'+ response.getBody(), sfId, sObjName, UserInfo.getUserId()));
                                }
                                processedRecords.add(serializedData);  
                            } 
                        }
                    }
                } 
            }
        } catch (Exception e) {
            String errorMessage = e.getTypeName() + ': ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            System.debug('Exception occurred while updating data in Azure: ' + errorMessage);
            integer count=1;
            List<ErrorDetails>  unProcessedRecords = new List<ErrorDetails>();
            for(String serializedData:serializedDataList){
                if (!processedRecords.contains(serializedData)) {
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(serializedData);
                    if (data.containsKey('Id')) {
                        String sfId = (String) data.get('Id');
                        Id recordId = Id.valueOf(sfId);
                        String sObjName = recordId.getSObjectType().getDescribe().getName();
                        unProcessedRecords.add(new ErrorDetails(count++, 'Pending', sfId, sObjName, UserInfo.getUserId()));
                    }
                }
            }
            if(!unProcessedRecords.isEmpty()){
                String emailBody = errorMessage+' & ' +'Unprocessed Records';
                emailBody += '<table border="1"><tr><th>S.NO</th><th>Record Status</th><th>Record Id</th><th>Object</th><th>User Id</th></tr>';
                for (ErrorDetails error : unProcessedRecords) {
                    emailBody += '<tr><td>' + error.count + '</td><td>' + error.body +'</td><td>'+error.recordId+'</td><td>'+error.sObjectName+'</td><td>'+error.userId+'</td></tr>';
                }
                emailBody += '</table>';
                
                sendErrorEmail('Exception occurred while updating data in Azure', emailBody);
            }
        }
        if (!failedRecords.isEmpty()) {
            String emailBody = '<table border="1"><tr><th>S.NO</th><th>Response Body</th><th>Record Id</th><th>Object</th><th>User Id</th></tr>';
            for (ErrorDetails error : failedRecords) {
                emailBody += '<tr><td>'+error.count+'</td><td>' + error.body+'</td><td>'+error.recordId+'</td><td>'+error.sObjectName+'</td><td>'+error.userId+'</td></tr>';
            }
            emailBody += '</table>';
            
            sendErrorEmail('UpdateDataInAzure failed to sync data', emailBody);
        }
    }
    
    public static String serializeWithNulls(SObject obj) {
        Map<String, Object> objMap = new Map<String, Object>();
        
        for (Schema.SObjectField field : obj.getSObjectType().getDescribe().fields.getMap().values()) {
            String fieldName = String.valueOf(field);
            Object value = obj.get(fieldName);
            if (value != null) {
                objMap.put(fieldName, value);
            } else {
                objMap.put(fieldName, null); 
            }
        }
        
        return JSON.serialize(objMap);
    }
    
    @future(callout=true)
    public static void getAzureAccessToken() {
        
        try {  
            Salesforce_webhook__mdt   metaDataField = [select Audience__c, Client_Id__c, Client_Secret__c, oAuth_URL__c, Access_Token__c, Update_Dealer__c from Salesforce_webhook__mdt where DeveloperName = 'Azure_Integration_Service'];
            
            String requestBody = 'grant_type=client_credentials' +
                '&client_id=' + metaDataField.Client_Id__c  +
                '&client_secret=' + metaDataField.Client_Secret__c  +
                '&audience=' + metaDataField.Audience__c ;
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(metaDataField.oAuth_URL__c );
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody(requestBody);
            
            HttpResponse response = new Http().send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String updatedAccessToken = (String) jsonResponse.get('access_token');
                
                if (metaDataField != null) {
                    Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
                    customMetadata.fullName = 'Salesforce_Webhook__mdt.'+'Azure_Integration_Service';
                    customMetadata.label = 'Azure_Integration_Service';
                    
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
                
            } else {
                System.debug('Failed to obtain access token. Status code: ' + response.getStatusCode());
                sendErrorEmail('getAzureAccessToken'+'Status Code: '+response.getStatusCode(), response.getBody());
            }
            
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            sendErrorEmail('getAzureAccessToken.', errorMessage);
            System.debug('Exception occured while getting the Access Token:'+ errorMessage);
            
        }
    }  
}