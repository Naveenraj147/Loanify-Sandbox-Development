public class ContactTriggerHelper {
    
    private static final String VALID_PHONE_NUMBER_REGEX = '^\\+1\\d{10}$';
    
    public static String formatPhoneNumber(String phoneNumber, String countryCode){
        Pattern pattern = Pattern.compile(VALID_PHONE_NUMBER_REGEX);
        Matcher matcher = pattern.matcher(phoneNumber);
        
        if (matcher.matches()) {
            return phoneNumber;
        }
        
        String cleanedPhoneNumber = phoneNumber.replaceAll('[^\\d]', '');
        String formattedPhoneNumber;
        if(cleanedPhoneNumber.length() < 10){
            return cleanedPhoneNumber;
        }
        
        if (cleanedPhoneNumber.length() > 10) {
            cleanedPhoneNumber = cleanedPhoneNumber.substring(cleanedPhoneNumber.length() - 10);
        }        
        formattedPhoneNumber = countryCode + cleanedPhoneNumber;
        
        return formattedPhoneNumber;
        
    }
    
    public void handlePendingRequestsInGarage(Map<Id, Contact> newMap){
        try{
            Set<Id> conIds = new Set<Id> ();
            Id recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();
            
            set<Id> accountIds = new set<Id> ();
            Map<Id, List<String>>  dealerIdToDealerProsEmailMap = new Map<Id, List<String>> ();
            Map<Id, List<String>>  dealerIdToDealerProsPhoneMap = new Map<Id, List<String>> ();
            for(Contact con: newMap.Values()){
                if(con.RecordTypeId==recordTypeId && con.AccountId != null){
                    conIds.add(con.Id);
                    accountIds.add(con.AccountId);
                    if(con.Active__c == true && Member_Response_Notification__c == true){
                        if (!dealerIdToDealerProsEmailMap.containsKey(con.AccountId)) {
                            dealerIdToDealerProsEmailMap.put(con.AccountId, new List<String> ());
                        }
                        dealerIdToDealerProsEmailMap.get(con.AccountId).add(con.Email);
                        if(con.phone != null){
                            if (!dealerIdToDealerProsPhoneMap.containsKey(con.AccountId)) {
                                dealerIdToDealerProsPhoneMap.put(con.AccountId, new List<String> ());
                            }
                            dealerIdToDealerProsPhoneMap.get(con.AccountId).add(con.Phone);
                        }
                    } 
                }
            }
            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Manager_Email__c, Phone FROM Account WHERE Id IN :accountIds]);
            
            // Adding Account Manager Emails 
            for (Id accId : accountIds) {
                if (dealerIdToDealerProsEmailMap.containsKey(accId)) {
                    Account relatedAccount = accountMap.get(accId);
                    if (relatedAccount != null && relatedAccount.Manager_Email__c != null) {
                        dealerIdToDealerProsEmailMap.get(accId).add(relatedAccount.Manager_Email__c);
                    }
                }
            }
            if(!conIds.isEmpty()){
                sendPendingRequestsToDealer(accountIds, dealerIdToDealerProsEmailMap,dealerIdToDealerProsPhoneMap);
            }
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
        
    }
    
    public void handlePendingRequestsInGarage1 (Map<Id, Contact> oldMap, Map<Id, Contact> newMap){
        try{
            String recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();
            set<Id> conIds = new set<Id> ();
            Set<Id> accIds = new Set<Id>();
            for(Contact con: newMap.Values()){
                if(con.RecordTypeId == recordTypeId && con.Active__c != oldMap.get(con.Id).Active__c){
                    conIds.add(con.Id);
                    accIds.add(con.AccountId);
                }
            }
            
            if(!ConIds.isEmpty()){
                List<Account> accList = [SELECT Id, Name, Manager_Email__c, RecordType.DeveloperName From Account Where Id =: accIds AND  RecordType.DeveloperName='Auto_Dealer'];
                Set<Id> accountsIdsWithMails = new Set<Id> ();
                Set<Id> accountsIdsWithoutMails = new Set<Id> ();
                for(Account acc: accList){
                    if(acc.Manager_Email__c != null){
                        accountsIdsWithMails.add(acc.Id);
                        
                    } else {
                        accountsIdsWithoutMails.add(acc.Id);
                    }
                }
                system.debug('Account With Email:: '+accountsIdsWithMails);
                if(!accountsIdsWithMails.isEmpty()){
                    List<Contact> activeContactsWithManagerMail = [SELECT Id, Name, Email, AccountId, Active__c FROM Contact WHERE AccountId=:accountsIdsWithMails AND Id=:conIds AND Active__c = true];
                    Map<Id, List<String>>  dealerIdToDealerProsEmailMap = new Map<Id, List<String>> ();
                    Set<Id> activeDealerProAccIds =  new Set<Id> ();
                    for(Contact con: activeContactsWithManagerMail){
                        if(con.Active__c == true) {
                            activeDealerProAccIds.add(con.AccountId);
                            if (!dealerIdToDealerProsEmailMap.containsKey(con.AccountId)) {
                                dealerIdToDealerProsEmailMap.put(con.AccountId, new List<String> ());
                            }
                            dealerIdToDealerProsEmailMap.get(con.AccountId).add(con.Email);
                        }  
                    }
                    List<Account> activeDealerProDealers = [SELECT Id, Manager_Email__c FROM Account WHERE Id IN:activeDealerProAccIds];
                    for(Account acc: activeDealerProDealers){
                        dealerIdToDealerProsEmailMap.get(acc.Id).add(acc.Manager_Email__c);
                    }
                    if(!activeContactsWithManagerMail.isEmpty() && !dealerIdToDealerProsEmailMap.isEmpty()){
                        sendPendingRequestsToDealer(accountsIdsWithMails, dealerIdToDealerProsEmailMap, null);  
                    } 
                } 
                if(!accountsIdsWithoutMails.isEmpty()){
                    List<Contact> activeContactsWithoutManagerMail = [SELECT Id, Name, Email, AccountId, Active__c FROM Contact WHERE AccountId=:accountsIdsWithoutMails AND Id=:conIds AND Active__c = true];
                    Map<Id, List<String>>  dealerIdToDealerProsEmailMapWithoutAccountMail = new Map<Id, List<String>> ();
                    for(Contact con: activeContactsWithoutManagerMail){
                        if(con.Active__c == true) {
                            if (!dealerIdToDealerProsEmailMapWithoutAccountMail.containsKey(con.AccountId)) {
                                dealerIdToDealerProsEmailMapWithoutAccountMail.put(con.AccountId, new List<String> ());
                            }
                            dealerIdToDealerProsEmailMapWithoutAccountMail.get(con.AccountId).add(con.Email);
                        }  
                    }
                    if(!activeContactsWithoutManagerMail.isEmpty() && !dealerIdToDealerProsEmailMapWithoutAccountMail.isEmpty()){
                        sendPendingRequestsToDealer(accountsIdsWithoutMails, dealerIdToDealerProsEmailMapWithoutAccountMail,null);
                    } else{
                        Set<Id> inactiveConAccIds = new Set<Id>();
                        List<Contact> inactiveContactsWithoutManagerMail = [SELECT Id, Name, AccountId, Active__c FROM Contact WHERE AccountId=:accountsIdsWithoutMails AND Id=:conIds AND Active__c = false];
                        for(Contact con: inactiveContactsWithoutManagerMail){
                            inactiveConAccIds.add(con.AccountId);
                        }
                        List<Contact> activeConsRelatedToInactiveCons = [SELECT Id, Name, AccountId, Active__c FROM Contact WHERE AccountId=:inactiveConAccIds AND Active__c = true];
                        if(activeConsRelatedToInactiveCons.isEmpty()){
                            List<Garage__c> garList = [SELECT Id, Name, VIN__C, Active__c, Dealer_Email_Available__c, FastPass_Dealer_Id__c, Pending_Requests__c, Dealer__c FROM Garage__C WHERE Dealer__c IN:inactiveConAccIds];
                            
                            if(!garList.isEmpty()){
                                List<Garage__c> garList1 = new List<Garage__c> ();
                                for(Garage__c gar:garList){
                                    if(gar.Dealer_Email_Available__c == true){
                                        gar.Dealer_Email_Available__c = false;
                                        garList1.add(gar);
                                    } else{
                                        System.debug('Another Active Dealer pro present');
                                    }
                                }
                                system.debug('The Related Garage Dealer Manager Avialble is Unchecked');
                                if(!garList.isEmpty()){
                                    update garList;
                                }
                            } 
                        } 
                    }
                }
            }
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
        
    }
    
    
    // Email Helper class code 
    
    public static void sendPendingRequestsToDealer (Set<Id> accIds, Map<Id, List<String>>  idToEmailMap, Map<Id, List<String>>  idToPhoneMap){
        try{
            OrgWideEmailAddress[] orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Support' LIMIT 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            
            if (orgWideEmail == null) {
                System.debug('No Org-Wide Email Address found');
                return;
            }
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            List<Garage__c> garagesToUpdate = new List<Garage__c>();
            
            List<Garage__c> garageList = [SELECT Id, Name, VIN__C, Active__c, Dealer_Email_Available__c, FastPass_Dealer_Id__c, Pending_Requests__c, Dealer__c FROM Garage__C WHERE Dealer__c IN:accIds];
            set<Id> garageSet = new set<Id> ();
            set<Id> updatedGarages = new set<Id>();
            if(!garageList.isEmpty()){
                for(Garage__c each:garageList){
                    if(each.Dealer_Email_Available__c == false){
                        each.Dealer_Email_Available__c = true;
                        garagesToUpdate.add(each);
                        updatedGarages.add(each.Id); 
                    }
                    if(each.Pending_Requests__c != null){
                        garageSet.add(each.Id);
                    }
                }
                if (!garagesToUpdate.isEmpty()) {
                    update garagesToUpdate;
                }
                
                system.debug('Garage Ids:: '+updatedGarages);
                system.debug('Gargeset:: ' +garageSet);
                if(!garageSet.isEmpty()){
                    List<Garage__c> garageswithPendingRequests = [SELECT Id, Name, VIN__c, FastPass_Dealer_Id__c, Opportunity__C, Pending_Requests__c, Dealer__c, Dealer__r.Manager_Email__c, FastPass_Vehicle_Id__c FROM Garage__c WHERE Id IN:garageSet];
                    List<tdc_tsw__Message_Template__c> smsTemplate = [SELECT Id, tdc_tsw__SMSBodyNew__c FROM tdc_tsw__Message_Template__c WHERE Name = 'Right_Swipe_Automation_SMS'];
                    String dealerportalURL = system.label.Dealer_Portal_Page_URL;

                    for (Garage__c garage : garageswithPendingRequests) {
                        String pendingRequests = garage.Pending_Requests__c;
                        if (String.isNotBlank(pendingRequests)) {
                            List<String> requests = pendingRequests.split(';;');
                            for (String request : requests) {
                                if (request.contains('Subject++') && request.contains('Body++') && request.contains('Type++')) {
                                    String subject = request.substringBetween('Subject++', 'Body++').trim();
                                    String body = request.substringBetween('Body++', 'Type++').trim();
                                    String type = request.substringAfter('Type++ ').trim();
                                    List<String> toAddress = idToEmailMap.get(garage.Dealer__c);
                                    if (toAddress != null && !toAddress.isEmpty()) {
                                        Map<String, Object> params = new Map<String, Object>();
                                        params.put('opportunityId', garage.Opportunity__c);
                                        params.put('dealerId', garage.FastPass_Dealer_Id__c);
                                        params.put('vehicleVin', garage.VIN__c);
                                        params.put('vehicleName', garage.Name);
                                        params.put('type', type);
                                        params.put('linkSharedDate', Date.today());
                                        params.put('garageId', garage.Id);
                                        params.put('fastpassVehicleId', garage.FastPass_Vehicle_Id__c);
                                        
                                        // Convert to JSON string
                                        String jsonParams = JSON.serialize(params);
                                        String encryptedParams = CryptoUtility.encrypt(jsonParams);
                                        String paramsInChatLink = body.substringBetween('?q=', '">click here');
                                        body = body.replaceAll(paramsInChatLink, encryptedParams);
                                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                        email.setOrgWideEmailAddressId(orgWideEmail.Id);
                                        email.setToAddresses(toAddress);
                                        email.setSubject(subject);
                                        email.setHtmlBody(body);
                                        email.setSaveAsActivity(true);
                                        email.setWhatId(garage.Id);
                                        
                                        emailMessages.add(email);
                                        if(body.contains('Note: Click on the link to REPLY') && idToPhoneMap != null ){
                                            body = body.replaceAll('<[^>]*>', '');
                                            body = body.replaceAll('\n', '');
                                            body = body.replaceAll('\t', '');
                                            body = body.substringBefore('Thanks,FastPass');
                                            
                                            // String response = body.substringBetween('<a href="', '">Click here to reply');
                                            // System.debug('response:: '+response);
                                             String messageText = smsTemplate.size()>0 ? smsTemplate[0].tdc_tsw__SMSBodyNew__c : null;
                                             
                                             if(idToPhoneMap.containsKey(garage.Dealer__c) && messageText != null){
                                                 messageText = messageText.replace('{firstMessage}', body);
                                                 String conLink = dealerportalURL+'?q='+encryptedParams;
                                                 messageText = messageText.replace('{Link}', conLink);
                                                 for(String sms : idToPhoneMap.get(garage.Dealer__c) ){
                                                     tdc_tsw.GlobalSMSSender.SendSmsWithPhoneNumberAndMessageText(sms,messageText,garage.Id) ;
                                                 }
                                             }
                                         }
                                    }
                                }
                            }
                        }
                    }
                    
                    if (!emailMessages.isEmpty()) {
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMessages);
                        for (Messaging.SendEmailResult result : results) {
                            if (result.isSuccess()) {
                                System.debug('Email sent successfully');
                            } else {
                                System.debug('Failed to send email: ' + result.getErrors()[0].getMessage());
                            }
                        }
                    }
                }
            }  
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
    }
}