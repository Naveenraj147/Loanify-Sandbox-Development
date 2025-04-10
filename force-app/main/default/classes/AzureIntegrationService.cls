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
            if(action=='CreateMemberData' || action=='CreateDealerProData' || action=='CreateServiceRepData' || action=='CreateCarbotsMemberData' || action=='CreateCUnexusMemberData'){
                wrapper = createContacts();
            }else if(action=='CreateLoanData'){
                wrapper = createOpportunities();
            }else if(action=='CreateDealerData' || action=='CreateBankData'){
                wrapper = createAccounts();
            }else if(action=='CreateLeadDealerData' || action=='CreateLeadBankData'){
                wrapper = createLeads();
            }else if(action=='UpsertDealerData'){
                wrapper = upsertDealer();
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
        String conRecTypeName = action=='CreateMemberData' ? 'Auto_Shopper' : action=='CreateDealerProData' ? 'Auto_Dealer_Pro' : action=='CreateServiceRepData' ? 'Bank_Service_Rep' : action=='CreateCarbotsMemberData' ? 'Auto_Shopper_Carbots' : action=='CreateCUnexusMemberData' ? 'Auto_Shopper_CUnexus' : null;
        RecordType conRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType = 'Contact' and DeveloperName=:conRecTypeName];
        Set<String> emailSet = new Set<String>();
        //assign record type
        for(Contact each : conList){
            System.debug('Con:'+each);
            if(conRecTypeName == 'Auto_Shopper_Carbots'){
                each.Source__c = 'Carbots';
            }
            else if(conRecTypeName == 'Auto_Shopper_CUnexus'){
                each.Source__c = 'CUNexus';
            }
            
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
            Map<Id,AccountContactRelation> conMap = new Map<Id,AccountContactRelation>();
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
                conMap = new Map<Id,AccountContactRelation>([select Id, Contact.Name, AccountId, ContactId from AccountContactRelation where Contact.Name in :conIdMap.keySet() and AccountId!=null and Contact.RecordType.DeveloperName ='Bank_Service_Rep']);
                for(AccountContactRelation con : conMap.values()){
                    if(!accConsMap.containsKey(con.AccountId)){
                        accConsMap.put(con.AccountId, new Map<String,Id>());
                    }
                    Map<String,Id> temp = accConsMap.get(con.AccountId);
                    temp.put(con.Contact.Name,con.ContactId);
                    accConsMap.put(con.AccountId,temp);
                }
            }
            String msrNullTable = '<table border="1"><tr><th>Card Number</th><th>Branch Name - Id </th><th>MSR Name</th> <th>MSR Ids</th></tr>';
            Boolean sendNullEmail = false;
            for(Opportunity each : oppList){
                if(String.isNotBlank(each.Branch__c) && accIdMap.containsKey(each.Branch__c)){
                    String branchName = each.Branch__c;
                    each.Branch__c = accIdMap.get(each.Branch__c);
                    if(String.isNotBlank(each.Bank_Service_Rep_Name_MSR__c) && accConsMap.containsKey(each.Branch__c)){
                        if(accConsMap.get(each.Branch__c).containsKey(each.Bank_Service_Rep_Name_MSR__c)){
                            each.Bank_Service_Rep_Name_MSR__c = accConsMap.get(each.Branch__c).get(each.Bank_Service_Rep_Name_MSR__c);
                        }else{
                            msrNullTable += '<tr><td>'+ each.Card_Number__c + '</td><td>' + branchName + '-' + each.Branch__c + '</td><td>' + each.Bank_Service_Rep_Name_MSR__c + '</td><td>' + accConsMap.get(each.Branch__c) +'</td></tr>';
                            each.Bank_Service_Rep_Name_MSR__c = null;
                            sendNullEmail = true;
                        }
                            
                    }else{
                        if(String.isNotBlank(each.Bank_Service_Rep_Name_MSR__c) ){
                            msrNullTable += '<tr><td>' + branchName + '-' + each.Branch__c + '</td><td>' + each.Bank_Service_Rep_Name_MSR__c + '</td><td>' + 'NA' +'</td></tr>';
                            sendNullEmail = true;
                        }
                        each.Bank_Service_Rep_Name_MSR__c = null;
                        
                    }
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
            if(sendNullEmail){
                msrNullTable += '</table>';
                sendErrorEmail('Opportunity MSR is blank ', msrNullTable);
            }
        }
        
        wrapper.success = successData;
        wrapper.error = errorData;
        return wrapper;
    }
    
    public static CreateResponseWrapper createLeads(){
        RestRequest req = RestContext.request;
        String action = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        // Deserialize the JSON request body into a list of Contact records
        List<Lead> leadList = (List<Lead>)JSON.deserialize(req.requestBody.tostring(), List<Lead>.class);
        Map<String,String> successData = new Map<String,String>();
        Map<String,String> errorData = new Map<String,String>();
        if(!leadList.isEmpty()){
            String recTypeName = action=='CreateLeadDealerData' ? 'Dealer' : 'Credit_Union';
            RecordType accRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType = 'Lead' and DeveloperName=:recTypeName];
            //assign record type
            for(Lead each : leadList){
                each.RecordTypeId = accRecType!=null ? accRecType.Id : null;
                if(each.LastName == null){
                    each.LastName = each.Company;
                }
            }
            
            List<Database.SaveResult> results = Database.insert(leadList, false);
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
                for(Lead each : leadList){
                    if(successIds.contains(each.Id)){
                        successData.put(each.Company, each.Id);
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
    public static CreateResponseWrapper upsertDealer(){
        RestRequest req = RestContext.request;
        String action = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        // Deserialize the JSON request body into a list of Contact records
        List<Object> objList = (List<Object>) JSON.deserializeUntyped(req.requestBody.tostring());

        Set<String> fpDealerIdSet = new Set<String>();
        Map<String,String> fpDealerIdAccIdMap = new Map<String,String>();
        Map<String,String> fpDealerIdLeadIdMap = new Map<String,String>();
        List<Object> accObjList = new List<Object>();
        List<Object> leadObjList = new List<Object>();
        String queryFields = null;
        String LeadQueryFields = null;
        Set<String> queryFieldsList;
        List<String> leadQueryFieldsList;

        for(Object each : objList){
            Map<String, Object> eachMap = (Map<String, Object>) each;
            String fastPassDealerId = (String) eachMap.get('FastPass_Dealer_Id__c');
            fpDealerIdSet.add(fastPassDealerId);
            if(queryFields == null){
                queryFields = String.join(eachMap.keySet(), ',');
                queryFieldsList = eachMap.keySet();
            }
        }
        if(queryFields != null ){
            leadQueryFieldsList = queryFields.split(',');
            leadQueryFieldsList.add('Company');
            if(leadQueryFieldsList.contains('Name')) 
                 leadQueryFieldsList[leadQueryFieldsList.indexOf('Name')] = 'LastName';
            if(leadQueryFieldsList.contains('BillingStreet')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingStreet')] = 'Street';
            if(leadQueryFieldsList.contains('BillingCity')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingCity')] = 'City';
            if(leadQueryFieldsList.contains('BillingState')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingState')] = 'State';
            if(leadQueryFieldsList.contains('BillingPostalCode')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingPostalCode')] = 'PostalCode';
            if(leadQueryFieldsList.contains('BillingCountry')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingCountry')] = 'Country';
            if(leadQueryFieldsList.contains('BillingLatitude')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingLatitude')] = 'Latitude';
            if(leadQueryFieldsList.contains('BillingLongitude')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingLongitude')] = 'Longitude';
            if(leadQueryFieldsList.contains('BillingGeocodeAccuracy')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('BillingGeocodeAccuracy')] = 'GeocodeAccuracy';
            if(leadQueryFieldsList.contains('Email__c')) 
                leadQueryFieldsList[leadQueryFieldsList.indexOf('Email__c')] = 'Email';
                if(leadQueryFieldsList.contains('Type')) 
                leadQueryFieldsList.remove(leadQueryFieldsList.indexOf('Type'));
                if(leadQueryFieldsList.contains('ParentId')) 
                leadQueryFieldsList.remove(leadQueryFieldsList.indexOf('ParentId'));
                if(leadQueryFieldsList.contains('Category__c')) 
                leadQueryFieldsList.remove(leadQueryFieldsList.indexOf('Category__c'));


            LeadQueryFields = String.join(leadQueryFieldsList, ',');
            System.debug('LeadqueryFields :: '+ LeadQueryFields);
            
        }
        System.debug('queryFields :: '+ queryFields);
        if(fpDealerIdSet.size() > 0){
          //  List<Account> accList = [SELECT queryFields FROM Account WHERE FastPass_Dealer_Id__c =: fpDealerIdSet];
          String query ='SELECT ' + queryFields + ' FROM Account WHERE FastPass_Dealer_Id__c =: fpDealerIdSet';
          String leadQuery ='SELECT ' + LeadQueryFields + ' FROM Lead WHERE FastPass_Dealer_Id__c =: fpDealerIdSet AND IsConverted = false';

          List<Account> accList = Database.query(query);
          Map<Id, Account> accMap = new Map<Id, Account>(accList);
          List<Lead> leadList = Database.query(leadQuery);
          Map<Id, Lead> leadMap = new Map<Id, Lead>(leadList);
          //  List<Lead> leadList = [SELECT Id, FastPass_Dealer_Id__c FROM Lead WHERE FastPass_Dealer_Id__c =: fpDealerIdSet AND IsConverted = false];
            RecordType leadRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType = 'Lead' and DeveloperName = 'Dealer' ];

            for(Account each : accList){
                fpDealerIdAccIdMap.put(each.FastPass_Dealer_Id__c, each.Id);
            }
            for(Lead each : leadList){
                fpDealerIdLeadIdMap.put(each.FastPass_Dealer_Id__c, each.Id);
            }
            for(Object each : objList){
                Map<String, Object> eachMap = (Map<String, Object>) each;
                String fastPassDealerId = (String) eachMap.get('FastPass_Dealer_Id__c');
                if(fpDealerIdAccIdMap.containsKey(fastPassDealerId)){
                    accObjList.add(each);
                }else{
                    eachMap.put('LastName', eachMap.get('Name'));
                    eachMap.put('Company', eachMap.get('Name'));
                    eachMap.put('Street', eachMap.get('BillingStreet'));
                    eachMap.put('City', eachMap.get('BillingCity'));
                    eachMap.put('State', eachMap.get('BillingState'));
                    eachMap.put('PostalCode', eachMap.get('BillingPostalCode'));
                    eachMap.put('Country', eachMap.get('BillingCountry'));
                    eachMap.put('Latitude', eachMap.get('BillingLatitude'));
                    eachMap.put('Longitude', eachMap.get('BillingLongitude'));
                    eachMap.put('GeocodeAccuracy', eachMap.get('BillingGeocodeAccuracy'));
                    leadObjList.add(each);
                }
            }
            Map<String,String> successData = new Map<String,String>();
            Map<String,String> errorData = new Map<String,String>();
            if(accObjList.size() > 0){
                List<Account> updateAccList = new  List<Account>();
                for(Object each : objList){
                    Map<String, Object> eachMap = (Map<String, Object>) each;
                    if(fpDealerIdAccIdMap.containsKey((String)(eachMap.get('FastPass_Dealer_Id__c')))){
                    Account acc = new Account();
                    
                        acc.Id =  fpDealerIdAccIdMap.get((String)(eachMap.get('FastPass_Dealer_Id__c')));
                        acc.Bypass_Validation__c = true;
                        acc.Name = (String)eachMap.get('Name');
                    
                    for(String eachQueryField : queryFieldsList){
                            if(eachMap.keySet().contains(eachQueryField)){
                                
                                    String accountId = (string)(eachMap.get('FastPass_Dealer_Id__c'));
                                    String accountJson = JSON.serialize(accMap.get(fpDealerIdAccIdMap.get(accountId)));
                                    Object accObj = (Object) JSON.deserializeUntyped(accountJson);
                                    Map<String, Object> accEachObjMap = (Map<String, Object>) accObj;
                                    
                                    if(accEachObjMap.ContainsKey(eachQueryField) && accEachObjMap.get(eachQueryField) != eachMap.get(eachQueryField) && (accEachObjMap.get(eachQueryField) == 'null' || accEachObjMap.get(eachQueryField) == null || accEachObjMap.get(eachQueryField) == '' )){
                                        acc.put(eachQueryField, eachMap.get(eachQueryField));
                                        System.debug('Field Name :: '+ eachQueryField);
                                        System.debug('old Value :: '+ accEachObjMap.get(eachQueryField));
                                        System.debug('New Value :: '+ eachMap.get(eachQueryField));
                                    }
                                
                            }
                    }
                    updateAccList.add(acc);
                }
                }
                List<Database.SaveResult> results = Database.update(updateAccList, false);
                    List<Account> accValUpdateList = new List<Account>();
                    for(Account each : updateAccList){
                        each.Bypass_Validation__c = false;
                        accValUpdateList.add(each);
                    }
                    Database.update(accValUpdateList, false);

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
                        for(Account each : updateAccList){
                            if(successIds.contains(each.Id)){
                                successData.put(each.Name, each.Id);
                            }
                        }
                    }
            }

            if(leadObjList.size() > 0){
                List<Lead> upsertLeadList = new  List<Lead>();
                for(Object each : objList){
                    Map<String, Object> eachMap = (Map<String, Object>) each;
                    Lead lead = new Lead();
                    System.debug('fpDealerIdLeadIdMap :: '+ fpDealerIdLeadIdMap);
                    if(fpDealerIdLeadIdMap.containsKey((String)(eachMap.get('FastPass_Dealer_Id__c')))){
                        lead.Id =  fpDealerIdLeadIdMap.get((String)(eachMap.get('FastPass_Dealer_Id__c')));
                        lead.put('Company', ((String) eachMap.get('Company')));
                        for(String eachQueryField : leadQueryFieldsList){

                            if(eachMap.keySet().contains(eachQueryField)){
                                if(fpDealerIdLeadIdMap.containsKey((string)eachMap.get('FastPass_Dealer_Id__c'))){
                                    String leadId = (string)(eachMap.get('FastPass_Dealer_Id__c'));
                                    String leadJson = JSON.serialize(leadMap.get(fpDealerIdLeadIdMap.get(leadId)));
                                    Object leadObj = (Object) JSON.deserializeUntyped(leadJson);
                                    Map<String, Object> leadEachObjMap = (Map<String, Object>) leadObj;
                                    
                                    if(leadEachObjMap.containsKey(eachQueryField) && leadEachObjMap.get(eachQueryField) != eachMap.get(eachQueryField) && eachMap.get(eachQueryField) != null && (leadEachObjMap.get(eachQueryField) == 'null' || leadEachObjMap.get(eachQueryField) == null || leadEachObjMap.get(eachQueryField) == '' )){
                                        System.debug('Field Name :: '+ eachQueryField);
                                        System.debug('old Value :: '+ leadEachObjMap.get(eachQueryField));
                                        System.debug('New Value :: '+ eachMap.get(eachQueryField));


                                        Schema.SObjectField field = Schema.SObjectType.Lead.fields.getMap().get(eachQueryField);
                                        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

                                        // Convert value based on field type
                                        if (fieldDescribe.getType() == Schema.DisplayType.DOUBLE) {
                                            lead.put(eachQueryField, Decimal.valueOf((String) eachMap.get(eachQueryField)));
                                        } else if (fieldDescribe.getType() == Schema.DisplayType.INTEGER) {
                                            lead.put(eachQueryField, Integer.valueOf((String) eachMap.get(eachQueryField)));
                                        } else if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                                            lead.put(eachQueryField, Date.valueOf((String) eachMap.get(eachQueryField)));
                                        } else if (fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
                                            lead.put(eachQueryField, Datetime.valueOf((String) eachMap.get(eachQueryField)));
                                        } else {
                                            // For other types, directly assign the value
                                            lead.put(eachQueryField, eachMap.get(eachQueryField));
                                        }

                                        //lead.put(eachQueryField, eachMap.get(eachQueryField));
                                        
                                    }
                                }
                                
                            }
                            
                        }
                        upsertLeadList.add(lead);
                        
                    }
                    else if(!(fpDealerIdAccIdMap.containsKey((String)(eachMap.get('FastPass_Dealer_Id__c'))))){
                        Lead newLead = (Lead)JSON.deserialize(JSON.serialize(each), Lead.class);
                        upsertLeadList.add(newLead);
                    }
                }
            
                
                if(upsertLeadList.size() > 0){
                    System.debug('upsertLeadList.size() :: '+ upsertLeadList.size());
                    System.debug('upsertLeadList :: '+ upsertLeadList);
                    
                  //  Database.upsert(leadUpsertList, false);
                    List<Database.UpsertResult> results = Database.upsert(upsertLeadList, false);
                DatabaseSaveResultsWrapper resultsWrapper = processDatabaseUpsertResults(results);
                Set<Id> successIds = resultsWrapper.successIds;
                    System.debug('leadUpsertList upsert Success :: ');
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
                        for(Lead each : upsertLeadList){
                            if(successIds.contains(each.Id)){
                                successData.put(each.Company, each.Id);
                            }
                        }
                    }
                    System.debug('successData: '+successData);
                    System.debug('errorData: '+errorData);
                }
            }
            wrapper.success = successData;
            wrapper.error = errorData;
        }
        

        /*
        List<Account> accList = (List<Account>)JSON.deserialize(req.requestBody.tostring(), List<Account>.class);
        Map<String,String> successData = new Map<String,String>();
        Map<String,String> errorData = new Map<String,String>();
        if(!accList.isEmpty()){
            RecordType accRecType = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType where SobjectType = 'Account' and DeveloperName = 'Auto_Dealer' ];
            //assign record type
            Set<String> fastpassDealerIdsSet = new Set<String>();
            for(Account each : accList){
                fastpassDealerIdsSet.add(each.FastPass_Dealer_Id__c);
            }
            if(fastpassDealerIdsSet.size() > 0){
                List<Account> existingAccList = [Select Id, FastPass_Dealer_Id__c from Account where FastPass_Dealer_Id__c =: fastpassDealerIdsSet];
                Map<String,String> fpDealerIdMap = new Map<String,String>();
                if(existingAccList.size() > 0){
                    for(Account each : existingAccList){
                        fpDealerIdMap.put(each.FastPass_Dealer_Id__c, each.Id);
                    }
                }
                for(Account each : accList){
                    if(fpDealerIdMap.containsKey(each.FastPass_Dealer_Id__c)){
                        each.Id = fpDealerIdMap.get(each.FastPass_Dealer_Id__c);
                    }
                    else{
                        each.RecordTypeId = accRecType!=null ? accRecType.Id : null;
                    }
                }

                List<Database.UpsertResult> results = Database.upsert(accList, false);
                DatabaseSaveResultsWrapper resultsWrapper = processDatabaseUpsertResults(results);
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
        }
        wrapper.success = successData;
        wrapper.error = errorData;
        System.debug('successData: '+successData);
        System.debug('errorData: '+errorData); */
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

    public static DatabaseSaveResultsWrapper processDatabaseUpsertResults(List<Database.UpsertResult> results){
        DatabaseSaveResultsWrapper wrapper = new DatabaseSaveResultsWrapper();
        Map<String,String> errorData = new Map<String,String>();
        Set<Id> successIds = new Set<Id>();
        for (Database.UpsertResult result : results) {
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
                            Boolean isConverted = data.containsKey('IsConverted')? true:false;
                            
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
                            // if(isConverted == true){
                            //     data.put('IsConverted', true);
                            // }
                            
                            
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
                            else if (sObjName == 'Lead'){
                                
                                List<Lead> leadList = [SELECT Id, Company, RecordType.DeveloperName FROM Lead WHERE Id =: sfId LIMIT 1];
                                if(leadList.size() > 0){
                                    Lead lead = leadList[0];
                                    data.put('Name', lead.company);
                                    if (lead.RecordType.DeveloperName == 'Dealer') {
                                        endpointUrl = metaDataField.Update_Dealer__c;
                                    } else if (lead.RecordType.DeveloperName == 'Credit_Union') {
                                        endpointUrl = metaDataField.Update_Branch__c;
                                    }
                                }
                            }
                            if (endpointUrl != null) {
                                System.debug('===> Inside Endpoint URL ');
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