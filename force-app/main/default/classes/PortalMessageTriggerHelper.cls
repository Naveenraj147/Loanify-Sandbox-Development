public class PortalMessageTriggerHelper {
    public static String orgWideEmailId;
    
    public static void updatePortalMessage(List<Portal_Message__c> newList){
        try {
            System.debug('Inside PortalMessageTriggerHelper updatePortalMessage');
            set <String> pmIds = new set<String>();
            set <String> pmMSRIds = new set<String>();
            set <String> pmMSRMessageIds = new set<String>();
            set <String> pmDealerMessageIds = new set<String>();
            set <String> pmCBMessageIds = new set<String>();
            // New sets for Advisor portal type
            set <String> pmAdvisorIds = new set<String>();
            set <String> pmAdvisorMessageIds = new set<String>();
            Map<Id, List<String>>  dealerIdToDealerProsPhoneMap = new Map<Id, List<String>> ();
            Map<String, String>  garageToDealerIdMap = new Map<String, String> ();
            
            
            set <String> firstSMSIds = new set<String>();
            for(Portal_Message__c pm: newList){
                //Member message for dealer
                if(pm.Is_Pending__c != true && pm.Is_Member_Message__c == true && (pm.Portal_Type__c == 'Dealer'|| pm.Portal_Type__c == 'Carbots') ){
                    pmIds.add(pm.Id);
                }
                //Member message for MSR
                else if(pm.Is_Pending__c != true && pm.Is_Member_Message__c == true && pm.Portal_Type__c == 'MSR'){
                    pmMSRIds.add(pm.Id);
                }
                //MSR message for Member
                else if( pm.Is_Member_Message__c == false && pm.Portal_Type__c == 'MSR'){
                    pmMSRMessageIds.add(pm.Id);
                }
                //Dealer Message for Member
                else if( pm.Is_Member_Message__c == false && (pm.Portal_Type__c == 'Dealer'|| pm.Portal_Type__c == 'Carbots')){
                    pmCBMessageIds.add(pm.Id);
                }
                //Member message for Advisor
                else if(pm.Is_Pending__c != true && pm.Is_Member_Message__c == true && pm.Portal_Type__c == 'Advisor'){
                    pmAdvisorIds.add(pm.Id);
                }
                //Advisor message for Member
                else if( pm.Is_Member_Message__c == false && pm.Portal_Type__c == 'Advisor'){
                    pmAdvisorMessageIds.add(pm.Id);
                }
            }
            List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName = 'Support' Limit 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            orgWideEmailId = orgWideEmail != null? orgWideEmail.Id : null;
            
            if(pmIds.size() > 0){
                List<Portal_Message__c> pmList = [SELECT Id, Name, Opportunity__r.Name, Message__c, garage__r.FastPass_Vehicle_Id__c, Garage__r.Dealer__c, Garage__r.Lead_Dealer__c, garage__r.FastPass_Dealer_Id__c, garage__r.VIN__c, garage__r.Name,Opportunity__r.Card_Number__c, Request_Type__c, garage__r.Stock_Number__c, Portal_Type__c, Garage__r.Dealer__r.Name, Garage__r.Lead_Dealer__r.Name
                                                  FROM Portal_Message__c
                                                  WHERE Id IN:pmIds];
                if(pmList.size() > 0){
                    List<EmailTemplate> emailTemplates = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                                                          FROM EmailTemplate 
                                                          WHERE DeveloperName IN ('Member_Query_For_Test_Drive_1719900621424','Member_Response_For_Test_Drive_1719904116801', 'Right_Swipe_Automation_Email')];
                    EmailTemplate testDriveEmailTemp;
                    EmailTemplate queryEmailTemp;
                    EmailTemplate rightSwipEmailTemp;
                    tdc_tsw__Message_Template__c smsTemplate;
                    
                    List<tdc_tsw__Message_Template__c> smsTemplateList = [SELECT Id, tdc_tsw__SMSBodyNew__c FROM tdc_tsw__Message_Template__c WHERE Name = 'Right_Swipe_Automation_SMS' Limit 1];
                    if(smsTemplateList.size() > 0){
                        smsTemplate = smsTemplateList[0];
                    }
                    
                    for (EmailTemplate template : emailTemplates) {
                        if (template.DeveloperName == 'Member_Query_For_Test_Drive_1719900621424') {
                            testDriveEmailTemp = template;
                        } else if (template.DeveloperName == 'Member_Response_For_Test_Drive_1719904116801') {
                            queryEmailTemp = template;
                        }
                        else if (template.DeveloperName == 'Right_Swipe_Automation_Email') {
                            rightSwipEmailTemp = template;
                        }
                    }
                    
                    Set<String> dealerIds = new Set<String>();
                    Set<String> leadDealerIds = new Set<String>();
                    Map<Id, Account> accountMap;
                    Map<Id, Lead> leadMap;
                    
                    for(Portal_Message__c pm: pmList){
                        if(pm.Garage__r.Dealer__c != null){
                            dealerIds.add(pm.Garage__r.Dealer__c);
                            garageToDealerIdMap.put(pm.Garage__c, pm.Garage__r.Dealer__c);
                        }
                        else if(pm.Garage__r.Lead_Dealer__c != null){
                            leadDealerIds.add(pm.Garage__r.Lead_Dealer__c);
                            garageToDealerIdMap.put(pm.Garage__c, pm.Garage__r.Lead_Dealer__c);
                        }
                    }
                    accountMap = new Map<Id, Account>([SELECT Id, Name, Manager_Email__c, Manager_Name__c,Manager_Cell_Phone__c FROM Account WHERE Id IN: dealerIds]);
                    LeadMap = new Map<Id, Lead>([SELECT Id, Name, Company, Manager_Email__c, Manager_Name__c, Manager_Cell_Phone__c, Dealer_Pro_1_Email__c, Dealer_Pro_2_Email__c, Dealer_Pro_3_Email__c, Dealer_pro_1_Phone__c, Dealer_pro_2_Phone__c, Dealer_pro_3_Phone__c FROM Lead WHERE Id IN: leadDealerIds]);
                    List<AccountContactRelation> activeContacts = [SELECT AccountId, ContactId, Contact.Email, Contact.Member_Email_Notifications__c, Contact.Member_SMS_Notifications__c,  Contact.Phone, Contact.MobilePhone FROM AccountContactRelation WHERE AccountId In :dealerIds AND Contact.Email!= null AND Contact.Active__c = true AND Contact.Member_Response_Notification__c = true ];  
                    Map<Id, List<String>> emailMap = new Map<Id, List<String>>();
                    List<String> smsPhoneList = new List<String>();
                    
                    for (AccountContactRelation con : activeContacts) {
                        if (!emailMap.containsKey(con.AccountId)) {
                            emailMap.put(con.AccountId, new List<String>());
                            dealerIdToDealerProsPhoneMap.put(con.AccountId, new List<String>());
                        }
                        if(con.Contact.Member_Email_Notifications__c != true){
                            emailMap.get(con.AccountId).add(con.Contact.Email);
                        }
                        
                        if((con.Contact.Phone != null || con.Contact.MobilePhone != null) && con.Contact.Member_SMS_Notifications__c == false){
                            dealerIdToDealerProsPhoneMap.get(con.AccountId).add(con.Contact.Phone!=null? con.Contact.Phone: con.Contact.MobilePhone );
                        }
                        
                    }
                    system.debug('After Active Contacts ===>' +dealerIdToDealerProsPhoneMap);
                    
                    
                    
                    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                    String dealerportalURL = system.label.Dealer_Portal_Page_URL;
                    Map<String, String> garageSMSMap = new Map<String, String>();
                    for(Portal_Message__c pm: pmList){
                        Portal_Message__c protalMessage = pm;
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        String subject;
                        String htmlBody;
                        String managerName;
                        
                        List<String> toAdress  = new List<String>();
                        List<String> ccAdress  = new List<String>();
                        
                        if(protalMessage.garage__r.Dealer__c != null){
                            if(accountMap.containsKey(protalMessage.garage__r.Dealer__c) && accountMap.get(protalMessage.garage__r.Dealer__c).Manager_Email__c != null){
                                toAdress.add(accountMap.get(protalMessage.garage__r.Dealer__c).Manager_Email__c);
                                managerName = accountMap.get(protalMessage.garage__r.Dealer__c).Manager_Name__c != null ? accountMap.get(protalMessage.garage__r.Dealer__c).Manager_Name__c : accountMap.get(protalMessage.garage__r.Dealer__c).Name;
                                if(emailMap.containsKey(protalMessage.garage__r.Dealer__c)){
                                    ccAdress.addAll(emailMap.get(protalMessage.garage__r.Dealer__c));
                                }
                                if((accountMap.get(protalMessage.garage__r.Dealer__c).Manager_Cell_Phone__c) != null ){
                                    if(!dealerIdToDealerProsPhoneMap.containsKey(protalMessage.garage__r.Dealer__c)){
                                        dealerIdToDealerProsPhoneMap.put(protalMessage.garage__r.Dealer__c, new List<String>());
                                    }
                                    dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Dealer__c).add(accountMap.get(protalMessage.garage__r.Dealer__c).Manager_Cell_Phone__c);
                                }
                            }
                            else{
                                if(emailMap.containsKey(protalMessage.garage__r.Dealer__c) ){
                                    toAdress.addAll(emailMap.get(protalMessage.garage__r.Dealer__c));
                                    managerName =  accountMap.get(protalMessage.garage__r.Dealer__c).Name;
                                    
                                }
                            }
                            
                        }
                        else if(protalMessage.garage__r.Lead_Dealer__c != null) {
                            system.debug('Inside Lead Dealer ===>');
                            if(LeadMap.containsKey(protalMessage.garage__r.Lead_Dealer__c)){
                                Lead leadDealer = LeadMap.get(protalMessage.garage__r.Lead_Dealer__c);
                                if( leadDealer.Manager_Email__c != null) {
                                    toAdress.add(leadDealer.Manager_Email__c);
                                    dealerIdToDealerProsPhoneMap.put(protalMessage.garage__r.Lead_Dealer__c, new List<String>());
                                    managerName = leadDealer.Manager_Name__c != null ? leadDealer.Manager_Name__c : leadDealer.Company;
                                    if(leadDealer.Manager_Cell_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Manager_Cell_Phone__c);
                                    }
                                    if(leadDealer.Dealer_Pro_1_Email__c != null ){
                                        ccAdress.add(leadDealer.Dealer_Pro_1_Email__c);
                                    }
                                    if(leadDealer.Dealer_pro_1_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Dealer_pro_1_Phone__c);
                                    }
                                    if(leadDealer.Dealer_Pro_2_Email__c != null ){
                                        ccAdress.add(leadDealer.Dealer_Pro_2_Email__c);
                                    }
                                    if(leadDealer.Dealer_pro_2_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Dealer_pro_2_Phone__c);
                                    }
                                    if(leadDealer.Dealer_Pro_3_Email__c != null ){
                                        ccAdress.add(leadDealer.Dealer_Pro_3_Email__c);
                                    }
                                    if(leadDealer.Dealer_pro_3_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Dealer_pro_3_Phone__c);
                                    }
                                    system.debug('After Lead Manager Contacts ===>' +dealerIdToDealerProsPhoneMap);
                                }
                                else if(LeadMap.containsKey(protalMessage.garage__r.Lead_Dealer__c)){
                                    managerName = leadDealer.Company;
                                    dealerIdToDealerProsPhoneMap.put(protalMessage.garage__r.Lead_Dealer__c, new List<String>());
                                    if(leadDealer.Dealer_Pro_1_Email__c != null ){
                                        toAdress.add(leadDealer.Dealer_Pro_1_Email__c);
                                    }
                                    if(leadDealer.Dealer_Pro_2_Email__c != null ){
                                        toAdress.add(leadDealer.Dealer_Pro_2_Email__c);
                                    }
                                    if(leadDealer.Dealer_Pro_3_Email__c != null ){
                                        toAdress.add(leadDealer.Dealer_Pro_3_Email__c);
                                    }
                                    if(leadDealer.Dealer_pro_1_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Dealer_pro_1_Phone__c);
                                    }
                                    if(leadDealer.Dealer_pro_2_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Dealer_pro_2_Phone__c);
                                    }
                                    if(leadDealer.Dealer_pro_3_Phone__c != null ){
                                        dealerIdToDealerProsPhoneMap.get(protalMessage.garage__r.Lead_Dealer__c).add(leadDealer.Dealer_pro_3_Phone__c);
                                    }
                                    system.debug('After Lead Contacts ===>' +dealerIdToDealerProsPhoneMap);
                                }
                            }
                            
                        }
                        
                        
                        if( toAdress.size() > 0 || (protalMessage.Request_Type__c == 'First_Message' && dealerIdToDealerProsPhoneMap.size() > 0) ){
                            email.setWhatId(protalMessage.garage__c);
                            Map<String, Object> params = new Map<String, Object>();
                            params.put('opportunityId', protalMessage.Opportunity__c);
                            params.put('dealerId', protalMessage.garage__r.FastPass_Dealer_Id__c);
                            params.put('vehicleVin', protalMessage.garage__r.VIN__c);
                            params.put('portalType', protalMessage.Portal_Type__c);
                            params.put('vehicleName', protalMessage.garage__r.Name);
                            params.put('linkSharedDate', Date.today());
                            params.put('garageId', protalMessage.garage__c);
                            params.put('fastpassVehicleId', protalMessage.garage__r.FastPass_Vehicle_Id__c);
                            params.put('stockNumber', protalMessage.garage__r.Stock_Number__c);
                            
                            // Convert to JSON string
                            String jsonParams = JSON.serialize(params);
                            String conLink = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
                            
                            if(protalMessage.Request_Type__c == 'Test_Drive'){
                                
                                String memberQuery  = protalMessage.Message__c;
                                Pattern dateTimePattern = Pattern.compile('on (\\w{3} \\d{1,2}, \\d{4}, \\d{1,2}:\\d{2} (AM|PM) GMT[+-]\\d{1,2}:\\d{2})');
                                Matcher matcher = dateTimePattern.matcher(memberQuery);
                                
                                String extractedDateTime ;
                                if (matcher.find()) {
                                    extractedDateTime = matcher.group(1);
                                }
                                
                                // Output the extracted date and time
                                System.debug('Extracted Date and Time: ' + extractedDateTime);
                                subject = testDriveEmailTemp.Subject; 
                                htmlBody = testDriveEmailTemp.HtmlValue;
                                subject = subject.replace('{{{Opportunity.Auto_Shopper__c}}}', protalMessage.Opportunity__r.Name);
                                subject = subject.replace('{{{VINNumber}}}', +protalMessage.garage__r.VIN__c +' #' + string.valueOf(protalMessage.garage__r.FastPass_Vehicle_Id__c));
                                subject = subject.replace('{{{Opportunity.Card_Number__c}}}', protalMessage.Opportunity__r.Card_Number__c);
                                htmlBody = managerName != null? htmlBody.replace('{{{ManagerName}}}', managerName): htmlBody.replace('{{{ManagerName}}}','');
                                htmlBody = htmlBody.replace('{{{MemberName}}}', protalMessage.Opportunity__r.Name);
                                htmlBody = htmlBody.replace('{{{VINNumber}}}',protalMessage.garage__r.VIN__c);
                                htmlBody = htmlBody.replace('{{{VehicleName}}}', protalMessage.garage__r.Name);
                                if(extractedDateTime != null){
                                    htmlBody = htmlBody.replace('{{{TestDriveDate}}}', extractedDateTime);
                                }
                                else{
                                    htmlBody = htmlBody.replace('{{{TestDriveDate}}}', '');
                                }
                                
                                htmlBody = htmlBody.replace ('click here', '<a href="' +conLink+ '">click here</a>');
                                memberQuery = memberQuery.replaceAll('\n', '<br/>');
                                htmlBody = htmlBody.replace('{{{MemberQuery}}}', memberQuery);
                                String body;
                                if(protalMessage.Garage__r.Dealer__c != null){
                                    body = '🏬 '+ String.valueOf(protalMessage.garage__r.Dealer__r.Name)+ ' \n 🚘 '+ protalMessage.garage__r.Name; 
                                    htmlBody = htmlBody.replace('{{{Recipient.Id}}}', protalMessage.Garage__r.Dealer__c);
                                }
                                else if(protalMessage.Garage__r.Lead_Dealer__c != null){
                                    body = '🏬 '+ String.valueOf(protalMessage.garage__r.Lead_Dealer__r.Name) + ' \n 🚘 '+ protalMessage.garage__r.Name; 
                                }
                                else{
                                    body = '🏬 '+ ' \n 🚘 '+ protalMessage.garage__r.Name;
                                }
                                // String body = '🏬 '+ ('test Company ')+ ' \n 🚘 '+ protalMessage.garage__r.Name; 
                                String title = 'New message from '+ (protalMessage.Opportunity__r.Name);
                                FastPassIntegrationService.sendNotification(title, body, protalMessage.garage__c, null);
                                 TriggerAPIService.logTriggerEvent('MSG_BELL_NOTIFICATION3', 'SF23', UserInfo.getUserName(), null);
                            }
                            else if(protalMessage.Request_Type__c == 'First_Message'){
                                firstSMSIds.add(protalMessage.Id);
                                subject = rightSwipEmailTemp.Subject; 
                                htmlBody = rightSwipEmailTemp.HtmlValue;
                                String memberQuery = protalMessage.Message__c.replaceAll('\n', '<br/>');
                                htmlBody = htmlBody.replace('{firstMessage}', memberQuery);
                                htmlBody = htmlBody.replace('{Link}', '<a href="' +conLink+ '">click here</a>');
                                String messageText = smsTemplateList.size()>0 ? smsTemplateList[0].tdc_tsw__SMSBodyNew__c : null;
                                if(protalMessage.Garage__r.Dealer__c != null){
                                    htmlBody = htmlBody.replace('{{{Recipient.Id}}}', protalMessage.Garage__r.Dealer__c);
                                }
                                
                                
                                if(messageText != null){
                                    system.debug('Inside messageText ===>' );
                                    messageText = messageText.replace('{firstMessage}', MemberQuery);
                                    messageText = messageText.replace('{Link}', conLink);
                                    String dealerId = protalMessage.garage__r.Dealer__c != null? protalMessage.garage__r.Dealer__c: protalMessage.garage__r.Lead_Dealer__c ;
                                    if(dealerId != null && dealerIdToDealerProsPhoneMap.containsKey(dealerId) ){
                                        system.debug('Inside Dealer Check ===>' );
                                        for(String each : dealerIdToDealerProsPhoneMap.get(dealerId)){
                                            system.debug('Inside SMS sending ===>' );
                                            tdc_tsw.GlobalSMSSender.SendSmsWithPhoneNumberAndMessageText(each,messageText,protalMessage.garage__c) ;
                                        }
                                    }
                                }
                                
                                List<String> emailIdsiLst;
                            }
                            else{
                                subject = queryEmailTemp.Subject; 
                                htmlBody = queryEmailTemp.HtmlValue;
                                subject = subject.replace('{{{Opportunity.Auto_Shopper__c}}}', protalMessage.Opportunity__r.Name);
                                subject = subject.replace('{{{VINNumber}}}', +protalMessage.garage__r.VIN__c +' #' + string.valueOf(protalMessage.garage__r.FastPass_Vehicle_Id__c));
                                subject = subject.replace('{{{Opportunity.Card_Number__c}}}', protalMessage.Opportunity__r.Card_Number__c);
                                
                                htmlBody = managerName != null? htmlBody.replace('{{{ManagerName}}}', managerName):htmlBody.replace('{{{ManagerName}}}','');
                                htmlBody = htmlBody.replace('{{{MemberName}}}', protalMessage.Opportunity__r.Name);
                                String memberQuery = protalMessage.Message__c.replaceAll('\n', '<br/>');
                                htmlBody = htmlBody.replace('{{{MemberResponse}}}', memberQuery  );
                                htmlBody = htmlBody.replace ('click here', '<a href="' +conLink+ '">click here</a>');
                                String body;
                                if(protalMessage.Garage__r.Dealer__c != null){
                                    body = '🏬 '+ String.valueOf(protalMessage.garage__r.Dealer__r.Name)+ ' \n 🚘 '+ protalMessage.garage__r.Name; 
                                    htmlBody = htmlBody.replace('{{{Recipient.Id}}}', protalMessage.Garage__r.Dealer__c);
                                }
                                else if(protalMessage.Garage__r.Lead_Dealer__c != null){
                                    body = '🏬 '+ String.valueOf(protalMessage.garage__r.Lead_Dealer__r.Name) + ' \n 🚘 '+ protalMessage.garage__r.Name; 
                                }
                                else{
                                    body = '🏬 '+ ' \n 🚘 '+ protalMessage.garage__r.Name;
                                }
                                
                                String title = 'New message from '+ (protalMessage.Opportunity__r.Name);
                                FastPassIntegrationService.sendNotification(title, body, protalMessage.garage__c, null);
                                
                                
                            }
                            if(toAdress.size() > 0){
                                email.setToAddresses(toAdress);
                                email.setCCAddresses(ccAdress);
                                
                            }
                            else{
                                email.setToAddresses(ccAdress);
                            }
                            email.setSubject(subject);
                            email.setHtmlBody(htmlBody);
                            email.setSaveAsActivity(true); 
                            email.setUseSignature(false);
                            if(orgWideEmailId != null){
                                email.setOrgWideEmailAddressId(orgWideEmailId);
                            }
                            if(email.getToAddresses() != null && email.getToAddresses().size() > 0){
                                emailList.add(email);
                            }
                            
                            
                        }
                    }
                    if(emailList.size() > 0){
                        Messaging.sendEmail(emailList);
                        TriggerAPIService.logTriggerEvent('MSG_EMAIL_DLR4', 'SF1', UserInfo.getUserName(), null);
                    }
                    // if(garageSMSMap.keySet().size() > 0){
                    //     for(String eachGarageId :garageSMSMap.keySet()){
                    //         if(garageToDealerIdMap.containsKey(eachGarageId) && dealerIdToDealerProsPhoneMap.containsKey(garageToDealerIdMap.get(eachGarageId)) && garageSMSMap.containsKey(eachGarageId)){
                    //             for(String each : dealerIdToDealerProsPhoneMap.get(garageToDealerIdMap.get(eachGarageId))){
                    //                // tdc_tsw.GlobalSMSSender.SendSmsWithPhoneNumberAndMessageText(each,garageSMSMap.get(eachGarageId),eachGarageId) ;
                    //             }
                    
                    //         }
                    //     }
                    // }
                }
            }
            if(pmMSRIds.size() > 0){
                List<Portal_Message__c> pmList = [SELECT Id, Name, Opportunity__r.Name, Message__c, Opportunity__r.Auto_Shopper__r.Name, Opportunity__r.Auto_Shopper__c, Opportunity__r.Bank_Service_Rep_Name_MSR__c, Opportunity__r.Bank_Service_Rep_Name_MSR__r.AccountId, Opportunity__r.Branch__c, Opportunity__r.Branch__r.Name, Opportunity__r.Branch__r.ParentId
                                                  FROM Portal_Message__c
                                                  WHERE Id IN:pmMSRIds];
                if(pmList.size() > 0) {
                    Set<String> contactIds = new Set<String>();
                    Set<String> parrentAccountIds = new Set<String>();
                    
                    for(Portal_Message__c eachPM : pmList){
                        if(eachPM.Opportunity__r.Bank_Service_Rep_Name_MSR__c != null){
                            contactIds.add(eachPM.Opportunity__r.Bank_Service_Rep_Name_MSR__c);
                        }
                        else if(eachPM.Opportunity__r.Branch__c != null){
                            // accountIds.add(eachPM.Opportunity__r.Branch__c);
                            if(eachPM.Opportunity__r.Branch__r.ParentId != null){
                                parrentAccountIds.add(eachPM.Opportunity__r.Branch__r.ParentId);
                            }
                        }
                        
                    } 
                    if(ParrentAccountIds.size() > 0 || contactIds.size() > 0){
                        Map<Id, AccountContactRelation> contactMap = new Map<Id, AccountContactRelation>([SELECT Id, Contact.Name, Contact.Email, Contact.Member_Email_Notifications__c, AccountId  FROM AccountContactRelation WHERE (AccountId IN: ParrentAccountIds AND Contact.Primary_Contact__c = true) OR ContactId IN: contactIds]);
                        Map<Id, String> contactNameMap = new Map<Id, String>();
                        Map<Id, String> msrEmailMap = new Map<Id, String>();
                        Map<Id, List<String>> accountEmailMap =  new Map<Id, List<String>>();
                        Map<Id,String> contactEmailMap = new Map<Id,String>();
                        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                        String dealerportalURL = system.label.Dealer_Portal_Page_URL;
                        List<EmailTemplate> emailTemplates = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                                                              FROM EmailTemplate 
                                                              WHERE DeveloperName ='MSR_Notification_for_Member_Message'];
                        if(contactMap.values().size() > 0){
                            for (AccountContactRelation con : contactMap.values()) {
                                if(ParrentAccountIds.contains(con.AccountId)){
                                    if (!accountEmailMap.containsKey(con.AccountId)) {
                                        accountEmailMap.put(con.AccountId, new List<String>());
                                    }
                                    accountEmailMap.get(con.AccountId).add(con.Contact.Email);
                                }
                                contactNameMap.put(con.ContactId, con.Contact.Name);
                                if(con.Contact.Member_Email_Notifications__c == false){
                                    msrEmailMap.put(con.ContactId, con.Contact.Email );
                                }
                                
                                
                            }
                            // List<EmailTemplate> emailTemplates = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                            //                                     FROM EmailTemplate 
                            //                                     WHERE DeveloperName ='Member_Query_For_MSR'];
                            if(emailTemplates.size() > 0){
                                EmailTemplate emailTemp = emailTemplates[0];
                                for(Portal_Message__c eachPM : pmList){
                                    
                                    EmailTemplate eachTemp = emailTemp;
                                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                    
                                    Map<String, Object> params = new Map<String, Object>();
                                    params.put('opportunityId', eachPM.Opportunity__c);
                                    params.put('portalType', 'MSR');
                                    params.put('linkSharedDate', Date.today());
                                    // Convert to JSON string
                                    String jsonParams = JSON.serialize(params);
                                    String conLink = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
                                    
                                    
                                    String subject = eachTemp.Subject; 
                                    String htmlBody = eachTemp.HtmlValue;
                                    htmlBody = htmlBody.replace ('click here', '<a href="' +conLink+ '">click here</a>');
                                    email.setWhatId(eachPM.Opportunity__c);
                                    if(eachPM.Opportunity__r.Bank_Service_Rep_Name_MSR__c != null){
                                        htmlBody = htmlBody.replace('{{{Credit_UnionName}}}', contactNameMap.get(eachPM.Opportunity__r.Bank_Service_Rep_Name_MSR__c));
                                        email.setToAddresses(new List<String>{msrEmailMap.get(eachPM.Opportunity__r.Bank_Service_Rep_Name_MSR__c)});
                                    }
                                    else{
                                        htmlBody = htmlBody.replace('{{{Credit_UnionName}}}', eachPM.Opportunity__r.Branch__r.Name);
                                        List<String> fullEmailList; // = accountEmailMap.get(eachPM.Opportunity__r.Branch__r.ParentId);
                                        if(eachPM.Opportunity__r.Branch__r.ParentId != null && accountEmailMap.containsKey(eachPM.Opportunity__r.Branch__r.ParentId)){
                                            fullEmailList = (accountEmailMap.get(eachPM.Opportunity__r.Branch__r.ParentId));
                                        }
                                        email.setToAddresses(fullEmailList);
                                        
                                    }
                                    subject = subject.contains('{{{Opportunity.Name}}}')? subject.replace('{{{Opportunity.Name}}}', eachPM.Opportunity__r.Name): subject;
                                    htmlBody = htmlBody.replace('{{{Opportunity.Auto_Shopper__c}}}',eachPM.Opportunity__r.Auto_Shopper__r.Name);
                                    htmlBody = htmlBody.replace('{{{Opportunity.Bank_Service_Rep_Name_MSR__r.Id}}}',eachPM.Opportunity__r.Bank_Service_Rep_Name_MSR__c);
                                    
                                    email.setSubject(subject);
                                    email.setHtmlBody(htmlBody);
                                    email.setUseSignature(false);
                                    if(orgWideEmailId != null){
                                        email.setOrgWideEmailAddressId(orgWideEmailId);
                                    }
                                    emailList.add(email);
                                    
                                    
                                }
                                if(emailList.size() > 0){
                                    Messaging.sendEmail(emailList);
                                    TriggerAPIService.logTriggerEvent('MSG_EMAIL_MSR2', 'T19', UserInfo.getUserName(), null);
                                }
                            }
                        }
                    }    
                }
            }
            
            if(pmMSRMessageIds.size() > 0){
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                
                List<Portal_Message__c> pmList = [SELECT Id, Name, Opportunity__r.Name, Opportunity__r.Mobile__c, Opportunity__r.Phone__c, Message__c,Opportunity__c, Opportunity__r.Auto_Shopper__c, Opportunity__r.Branch__c, Opportunity__r.Credit_Union_Email_Notifications__c, Opportunity__r.Branch__r.Name, Opportunity__r.Auto_Shopper__r.FirstName, Opportunity__r.Auto_Shopper__r.Name, Opportunity__r.Auto_Shopper__r.Email
                                                  FROM Portal_Message__c
                                                  WHERE Id IN:pmMSRMessageIds];
                List<EmailTemplate> template = [SELECT Id, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Member_Notification_for_MSR_Message' LIMIT 1];
                
                if(pmList.size() > 0 && template.size() > 0){
                    for(Portal_Message__c eachPM : pmList){
                        EmailTemplate temp = template[0]; 
                        if(eachPM.Opportunity__r.Auto_Shopper__r.Email != null && eachPM.Opportunity__r.Credit_Union_Email_Notifications__c == false ){
                            emailList.add(createMembernotificationFromMSR(eachPM, temp));
                        }
                        if(eachPM.Opportunity__r.Mobile__c != null || eachPM.Opportunity__r.Phone__c != null){
                            String apiField = eachPM.Opportunity__r.Mobile__c != null? eachPM.Opportunity__r.Mobile__c : eachPM.Opportunity__r.Phone__c;
                        }
                    }
                    if(emailList.size() > 0){
                        Messaging.sendEmail(emailList);
                        TriggerAPIService.logTriggerEvent('MSG_EMAIL_MBR3', 'SF10', UserInfo.getUserName(), null);
                    }
                }
            }
            
            if(pmCBMessageIds.size() > 0){
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                List<EmailTemplate> template = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Email_Notification_to_Member' LIMIT 1];
                List<Portal_Message__c> pmList = [SELECT Id, Name, Opportunity__r.Name, Message__c,Opportunity__c, Opportunity__r.Auto_Shopper__c, Garage__c, Opportunity__r.Auto_Shopper__r.Name, Garage__r.Send_Generic_Notification__c, Garage__r.Is_Vehicle_In_Top_List__c, Opportunity__r.Auto_Shopper__r.Email, Opportunity__r.Dealer_Email_Notifications__c
                                                  FROM Portal_Message__c
                                                  WHERE Id IN:pmCBMessageIds]; 
                EmailTemplate emailTemp = template.size() > 0? template[0] : null; 
                if(pmList.size() > 0 && emailTemp != null){
                    for(Portal_Message__c eachPM : pmList){
                        if(eachPM.Opportunity__r.Auto_Shopper__r.Email != null && eachPM.Garage__r.Send_Generic_Notification__c != true && eachPM.Garage__r.Is_Vehicle_In_Top_List__c == true && eachPM.Opportunity__r.Dealer_Email_Notifications__c == false){ 
                            Messaging.SingleEmailMessage emailTempRender = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, eachPM.Garage__c);
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            String subject = emailTempRender.getSubject(); 
                            String htmlBody = emailTempRender.getHtmlBody();
                            htmlBody = htmlBody.replace('{Opportunity_Id}', eachPM.Opportunity__c);
                            emailList.add(createEmail(subject, htmlBody,new List<String>{eachPM.Opportunity__r.Auto_Shopper__r.Email}, null, eachPM.garage__c ));
                        }
                    }
                    if(emailList.size() > 0){
                        Messaging.sendEmail(emailList);
                        TriggerAPIService.logTriggerEvent('MSG_EMAIL_MBR4', 'SF9', UserInfo.getUserName(), null);
                    }
                }
            }
            
            
            // Process Member messages to Advisors
            if(pmAdvisorIds.size() > 0){
                System.debug('Inside Advisor Update - pmAdvisorIds size: ' + pmAdvisorIds.size());
                System.debug('pmAdvisorIds contents: ' + pmAdvisorIds);
                List<Portal_Message__c> pmList = [SELECT Id, Name, Opportunity__r.Name, Message__c, Opportunity__c, 
                                                  Opportunity__r.OwnerId, Opportunity__r.Owner.Email, Opportunity__r.Owner.Name,
                                                  Opportunity__r.Auto_Shopper__c, Opportunity__r.Auto_Shopper__r.Name, 
                                                  Opportunity__r.Auto_Shopper__r.FirstName, Opportunity__r.Auto_Shopper__r.Email
                                                  FROM Portal_Message__c
                                                  WHERE Id IN:pmAdvisorIds]; 
                
                
                System.debug('Advisor pmList size: ' + pmList.size());
                if(pmList.size() > 0){
                    List<User> userList = [SELECT Id, Email FROM User WHERE Profile.Name = 'Dealer and CU Sales Representative'];
                    for(Portal_Message__c pm : pmList) {
                        System.debug('Portal Message: ' + pm.Id + ', Opportunity: ' + pm.Opportunity__c + ', Owner Email: ' + (pm.Opportunity__r.Owner.Email != null ? pm.Opportunity__r.Owner.Email : 'null'));
                    }
                    
                    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                    // You can change this template name later as needed
                    List<EmailTemplate> template = [SELECT Id, Name, Subject, HtmlValue, DeveloperName 
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName = 'Member_Message_Notification_for_Agent' LIMIT 1];
                    
                    System.debug('Email template found: ' + (template.size() > 0 ? 'Yes, ID: ' + template[0].Id : 'No'));
                    EmailTemplate emailTemp = template.size() > 0 ? template[0] : null;
                    
                    if(emailTemp != null && userList.size() > 0){
                        List<String> toAddressList = new List<String>();
                        for(User each : userList){
                            toAddressList.add(each.Email);                            
                        }
                        
                        String recordLink = URL.getOrgDomainUrl().toExternalForm() + '/';
                        for(Portal_Message__c eachPM : pmList){
                            // Check if the opportunity has an agent assigned
                            System.debug('Processing message for email: ' + eachPM.Id + ', Owner Email: ' + (eachPM.Opportunity__r.Owner.Email != null ? eachPM.Opportunity__r.Owner.Email : 'null'));
                            if(eachPM.Opportunity__c != null){
                                // Create email to advisor
                                Messaging.SingleEmailMessage emailTempRender = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, eachPM.Opportunity__c);
                                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                String subject = emailTempRender.getSubject();
                                String htmlBody = emailTempRender.getHtmlBody();
                                
                                // Replace any placeholders in the template
                                htmlBody = eachPM.Opportunity__c != null ? 
                                    htmlBody.replace('{recordLink}', recordLink + eachPM.Opportunity__c) : 
                                htmlBody.replace('{recordLink}', '');
                                
                                // Add email to the list
                                System.debug('Adding email to list for: ' + eachPM.Opportunity__r.Owner.Email);
                                emailList.add(createEmail(subject, htmlBody, toAddressList, null, eachPM.Opportunity__c));
                            } else {
                                System.debug('Skipping email - OwnerId: ' + (eachPM.Opportunity__r.OwnerId != null ? eachPM.Opportunity__r.OwnerId : 'null') + 
                                             ', Owner Email: ' + (eachPM.Opportunity__r.Owner.Email != null ? eachPM.Opportunity__r.Owner.Email : 'null'));
                            }
                        }
                        
                        System.debug('Advisor emailList size: ' + emailList.size());
                        if(emailList.size() > 0){
                            try {
                                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
                                for(Messaging.SendEmailResult result : results) {
                                    if (result.isSuccess()) {
                                        System.debug('Email sent successfully');
                                        TriggerAPIService.logTriggerEvent('MSG_EMAIL_AGNT1', 'SF26', UserInfo.getUserName(), null);
                                    } else {
                                        for(Messaging.SendEmailError error : result.getErrors()) {
                                            System.debug('Email error: ' + error.getMessage() + ', Code: ' + error.getStatusCode());
                                        }
                                    }
                                }
                            } catch(Exception e) {
                                System.debug('Exception sending email: ' + e.getMessage() + ', Line: ' + e.getLineNumber());
                            }
                        }
                    }
                }
            }
            
            // Process Advisor messages to Members
            if(pmAdvisorMessageIds.size() > 0){
                System.debug('Processing Advisor messages to Members - pmAdvisorMessageIds size: ' + pmAdvisorMessageIds.size());
                List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                // You can change this template name later as needed
                List<EmailTemplate> template = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Advisor_Message_Notification_for_Member' LIMIT 1];
                System.debug('Member notification template found: ' + (template.size() > 0 ? 'Yes, ID: ' + template[0].Id : 'No'));
                List<tdc_tsw__Message_Template__c> smsTemplateList = [SELECT Id, tdc_tsw__SMSBodyNew__c FROM tdc_tsw__Message_Template__c WHERE Name = 'Advisor_Message_Notification_for_Member' Limit 1];
                tdc_tsw__Message_Template__c smsTemp = smsTemplateList.size() > 0? smsTemplateList[0] : null; 
                
                List<Portal_Message__c> pmList = [SELECT Id, Name, Opportunity__r.Name, Message__c, Opportunity__c, Opportunity__r.Auto_Shopper__c, Opportunity__r.Auto_Shopper__r.Name, Opportunity__r.Auto_Shopper__r.Email, Opportunity__r.FastPass_Team_Email_Support__c, Opportunity__r.FastPass_Team_SMS_Support__c, Opportunity__r.Mobile__c, Opportunity__r.Phone__c
                                                  FROM Portal_Message__c
                                                  WHERE Id IN:pmAdvisorMessageIds]; 
                System.debug('Member notification pmList size: ' + pmList.size());
                
                EmailTemplate emailTemp = template.size() > 0? template[0] : null; 
                if(pmList.size() > 0 && (emailTemp != null || smsTemp != null)){
                    Boolean isSMSSent;
                    for(Portal_Message__c eachPM : pmList){
                        System.debug('Processing member notification for: ' + eachPM.Id + ', Member Email: ' + (eachPM.Opportunity__r.Auto_Shopper__r.Email != null ? eachPM.Opportunity__r.Auto_Shopper__r.Email : 'null'));
                        if( emailTemp != null && eachPM.Opportunity__r.Auto_Shopper__r.Email != null && eachPM.Opportunity__r.FastPass_Team_Email_Support__c == false){ 
                            Messaging.SingleEmailMessage emailTempRender = Messaging.renderStoredEmailTemplate(emailTemp.Id, null, eachPM.Opportunity__c);
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            String subject = emailTempRender.getSubject(); 
                            String htmlBody = emailTempRender.getHtmlBody();
                            emailList.add(createEmail(subject, htmlBody, new List<String>{eachPM.Opportunity__r.Auto_Shopper__r.Email}, null, eachPM.Opportunity__c ));
                            System.debug('Added member email to list for: ' + eachPM.Opportunity__r.Auto_Shopper__r.Email);
                        } else {
                            System.debug('Skipping member email - Member Email is null');
                        }
                        if(smsTemp != null && (eachPM.Opportunity__r.Mobile__c != null || eachPM.Opportunity__r.Phone__c != null ) && eachPM.Opportunity__r.FastPass_Team_SMS_Support__c == false  ){
                            String phoneField = eachPM.Opportunity__r.Mobile__c != null ? eachPM.Opportunity__r.Mobile__c : eachPM.Opportunity__r.Phone__c;
                            tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId(phoneField,smsTemp.Id,eachPM.Opportunity__c);
                            isSMSSent = true;
                        }
                    }

                    if(isSMSSent == true){
                        TriggerAPIService.logTriggerEvent('MSG_TXT_MBR3', 'SF11', UserInfo.getUserName(), null);
                    }
                    System.debug('Member emailList size: ' + emailList.size());
                    if(emailList.size() > 0){
                        try {
                            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
                            for(Messaging.SendEmailResult result : results) {
                                if (result.isSuccess()) {
                                    System.debug('Member email sent successfully');
                                    TriggerAPIService.logTriggerEvent('MSG_EMAIL_MBR6', 'SF11', UserInfo.getUserName(), null);
                                } else {
                                    for(Messaging.SendEmailError error : result.getErrors()) {
                                        System.debug('Member email error: ' + error.getMessage() + ', Code: ' + error.getStatusCode());
                                    }
                                }
                            }
                        } catch(Exception e) {
                            System.debug('Exception sending member email: ' + e.getMessage() + ', Line: ' + e.getLineNumber());
                        }
                    }
                }
            }
        } catch (Exception e) {
            system.debug('Error: ' + e.getMessage());
            system.debug('Line number: ' + e.getLineNumber());
        }
    }
    
    public static Messaging.SingleEmailMessage createMembernotificationFromMSR(Portal_Message__c portaMessage, EmailTemplate template){
        String subject = template.Subject; 
        String htmlBody = template.HtmlValue;
       // htmlBody = portaMessage.Opportunity__r.Branch__c !=null?  htmlBody.replace('{{{CreditUnionName}}}', portaMessage.Opportunity__r.Branch__r.Name): htmlBody.replace('{{{CreditUnionName}}}','' );
        htmlBody = portaMessage.Opportunity__r.Auto_Shopper__r.FirstName != null? htmlBody.replace('{{{Member_FirstName}}}', portaMessage.Opportunity__r.Auto_Shopper__r.FirstName) : htmlBody.replace('{{{Member_FirstName}}}', portaMessage.Opportunity__r.Auto_Shopper__r.Name);
        htmlBody = portaMessage.Opportunity__c != null? htmlBody.replace('{{{Opportunity.Id}}}', portaMessage.Opportunity__c) : htmlBody.replace('{{{Opportunity.Id}}}', '');
        return createEmail(subject,  htmlBody, new List<String>{portaMessage.Opportunity__r.Auto_Shopper__r.Email},null, portaMessage.Opportunity__c );
    }
    
    public static Messaging.SingleEmailMessage createEmail(String subject, String htmlBody,List<String> toaddress, List<String> ccaddress, String relatedRecordId ){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody( htmlBody);
        email.setToAddresses(toaddress);
        email.setSaveAsActivity(true);
        email.setWhatId(relatedRecordId);
        email.setUseSignature(false);
        if(orgWideEmailId != null){
            email.setOrgWideEmailAddressId(orgWideEmailId);
        }
        if(ccaddress != null && ccaddress.size()>0){
            email.setCcAddresses(ccaddress);
        }
        
        return email;
    }
}