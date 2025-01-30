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
                    if(con.Active__c == true && con.Member_Response_Notification__c == true){
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
                if(con.RecordTypeId == recordTypeId && (con.Active__c != oldMap.get(con.Id).Active__c || (con.Member_Response_Notification__c != oldMap.get(con.Id).Member_Response_Notification__c && con.Member_Response_Notification__c == true)) ){
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
            System.debug('Inside sendPendingRequestsToDealer3');
            List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Support' LIMIT 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            
            if (orgWideEmail == null) {
                System.debug('No Org-Wide Email Address found');
                return;
            }

			List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            List<Garage__c> garagesToUpdate = new List<Garage__c>();
			Map<String, List<FastPassIntegrationService.CreateResponseWrapperSuccessJson>> garageIdJsonMap = new Map<String, List<FastPassIntegrationService.CreateResponseWrapperSuccessJson>>();
            List<tdc_tsw__Message_Template__c> smsTemplate = [SELECT Id, tdc_tsw__SMSBodyNew__c FROM tdc_tsw__Message_Template__c WHERE Name = 'Right_Swipe_Automation_SMS'];
            Map<Id, Garage__c> garageMap = new Map<Id, Garage__c>([SELECT Id, Name, VIN__C, Active__c, Dealer_Email_Available__c, FastPass_Dealer_Id__c, Pending_Requests__c,Pending_Request_JSON__c, Dealer__c, Opportunity__c, Opportunity__r.Name,Dealer__r.Name, Dealer__r.Manager_Name__c, FastPass_Vehicle_Id__c FROM Garage__C WHERE Dealer__c IN:accIds]);
            set<Id> garageSet = new set<Id> ();
            set<Id> updatedGarages = new set<Id>();
            if(!garageMap.keyset().isEmpty()){
			
			    List<EmailTemplate> emailTemplates = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                                                  FROM EmailTemplate 
                                                  WHERE DeveloperName IN ('Member_Query_For_Test_Drive_1719900621424', 
                                                                          'Member_Response_For_Test_Drive_1719904116801','Right_Swipe_Automation_Email')];
            
                EmailTemplate emailTemp1;
                EmailTemplate emailTemp2;
                EmailTemplate emailTemp3;
                String dealerportalURL = system.label.Dealer_Portal_Page_URL;
            
                for (EmailTemplate template : emailTemplates) {
                    if (template.DeveloperName == 'Member_Query_For_Test_Drive_1719900621424') {
                        emailTemp1 = template;
                    } else if (template.DeveloperName == 'Member_Response_For_Test_Drive_1719904116801') {
                        emailTemp2 = template;
                    }
                    else if (template.DeveloperName == 'Right_Swipe_Automation_Email') {
                        emailTemp3 = template;
                    }
                }
                for(Garage__c each:garageMap.values()){
                    if(each.Dealer_Email_Available__c == false){
                        each.Dealer_Email_Available__c = true;
                        garagesToUpdate.add(each);
                        updatedGarages.add(each.Id); 
                    }
                    if(each.Pending_Request_JSON__c != null){
					Map<String, object> dataMap = (Map<String, object>) JSON.deserializeUntyped(each.Pending_Request_JSON__c );
					if(dataMap.containsKey('testDrive')){
						String testDriveJson = JSON.serialize(dataMap.get('testDrive'));
                         List<FastPassIntegrationService.CreateResponseWrapperSuccessJson> conversations = (List<FastPassIntegrationService.CreateResponseWrapperSuccessJson>) JSON.deserialize(testDriveJson, List<FastPassIntegrationService.CreateResponseWrapperSuccessJson>.class);
							garageIdJsonMap.put(each.Id, conversations);
						}	
                    }
                }
				
				if(garageIdJsonMap.keyset().size() > 0){
					for(String eachGarage:garageIdJsonMap.keyset()){
						List<FastPassIntegrationService.CreateResponseWrapperSuccessJson> dealerJsonList = garageIdJsonMap.get(eachGarage);
						for(FastPassIntegrationService.CreateResponseWrapperSuccessJson eachItem : dealerJsonList ){
                            String bodyType = eachItem.EmailType;
                            String MemberQuery = eachItem.EmailMessage;
                            String subject = eachItem.Subject;
                            Garage__c  garage = garageMap.get(eachGarage);
                            System.debug('garage :: '+garage);
                            String jsonParams =  generateSiteUrl(garage.Opportunity__c, garage.FastPass_Dealer_Id__c, garage.VIN__c, garage.Name, 'testdrive', garage.Id, garage.FastPass_Vehicle_Id__c );
                            String conLink = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
						
						
						String body;
                       // bodyType = 'First Message';
						if(bodyType == 'First Message'){
							body = emailTemp3.HtmlValue;
							body = body.replace('{firstMessage}', MemberQuery);
							body = body.replace('{Link}', '<a href="' +conLink+ '">click here</a>');

                            String messageText = smsTemplate.size()>0 ? smsTemplate[0].tdc_tsw__SMSBodyNew__c : null;
	 
                            if(idToPhoneMap.containsKey(garage.Dealer__c) && messageText != null){
                                messageText = messageText.replace('{firstMessage}', MemberQuery);
                                messageText = messageText.replace('{Link}', conLink);
                                for(String sms : idToPhoneMap.get(garage.Dealer__c) ){
                                    tdc_tsw.GlobalSMSSender.SendSmsWithPhoneNumberAndMessageText(sms,messageText,garage.Id) ;
                                }
                            }

						}
						else if(bodyType == 'Member Response'){
							body = emailTemp2.HtmlValue;
							
							body = garage.Dealer__r.Manager_Name__c != null? body.replace('{{{ManagerName}}}', garage.Dealer__r.Manager_Name__c): body.replace('{{{ManagerName}}}', garage.Dealer__r.Name);
							body = body.replace('{{{MemberName}}}', garage.Opportunity__r.Name);
							memberQuery = memberQuery.replaceAll('\n', '<br/>');
							body = body.replace('{{{MemberResponse}}}', memberQuery);
							body = body.replace ('click here', '<a href="' +conLink+ '">click here</a>');

						}
						else if(bodyType == 'Test Drive'){
						body = emailTemp1.HtmlValue;
						String formattedDateTime = memberQuery.substringBetween('Are you available on', '?');
                        body = garage.Dealer__r.Manager_Name__c != null? body.replace('{{{ManagerName}}}', garage.Dealer__r.Manager_Name__c): body.replace('{{{ManagerName}}}', garage.Dealer__r.Name);
							body = body.replace('{{{MemberName}}}', garage.Opportunity__r.Name);
							body = body.replace('{{{VINNumber}}}', garage.VIN__c);
							body = body.replace('{{{VehicleName}}}', garage.Name);
							body = body.replace('{{{TestDriveDate}}}', formattedDateTime);
							body = body.replace ('click here', '<a href="' +conLink+ '">click here</a>');
							if(memberQuery!=null){
								memberQuery = memberQuery.replaceAll('\n', '<br/>');
								body = body.replace('{{{MemberQuery}}}', memberQuery);
							}else {
								String toRemove = body.substringBetween(formattedDateTime, 'Please <a href="');
								if (toRemove != null) {
									body = body.replace(toRemove, '<br/><br/>');
								}
							}

						}
						List<String> toAddress = idToEmailMap.get(garage.Dealer__c);
                        if(body != null){
                            emailMessages.add(generateEmail(orgWideEmail.Id, toAddress, subject, body, true, garage.Id));
                        }
						
						
						}
					}
				}
                if (!garagesToUpdate.isEmpty()) {
                    update garagesToUpdate;
                }
                
                
                if(!emailMessages.isEmpty()){
                    if (!emailMessages.isEmpty()) {
                        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailMessages); 
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
    Public Static string generateSiteUrl(ID opportunityId, String dealerId, String vehicleVin, String vehicleName, String type, Id garageId, Decimal fastpassVehicleId ){
		Map<String, Object> params = new Map<String, Object>();
		params.put('opportunityId', opportunityId);
		params.put('dealerId', dealerId);
		params.put('vehicleVin', vehicleVin);
		params.put('vehicleName', vehicleName);
		params.put('type', type);
		params.put('linkSharedDate', Date.today());
		params.put('garageId', garageId);
		params.put('fastpassVehicleId', fastpassVehicleId);
		
		// Convert to JSON string
		String jsonParams = JSON.serialize(params);
		return jsonParams;
}
Public Static Messaging.SingleEmailMessage generateEmail(String orgWideEmailId, List<String> toAddress, String subject, String body, Boolean activityStatus, String whatId){
	System.debug('toAddress :: '+ toAddress);
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
	email.setOrgWideEmailAddressId(orgWideEmailId);
	email.setToAddresses(toAddress);
	email.setSubject(subject);
	email.setHtmlBody(body);
	email.setSaveAsActivity(activityStatus);
	email.setWhatId(whatId);
    return email;
}

}