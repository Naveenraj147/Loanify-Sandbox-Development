public class LeadTriggerHelper {
    
    
    public static void processEmailUpdatedLeads (List<Lead> newList, Map<Id, Lead> oldMap){
        try{
            Set<Id> conIds = new Set<Id> ();
            Id recordTypeId = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            Id recordTypeIdDealerContact = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();
            Id recordTypeIdCUContact = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Bank_Service_Rep').getRecordTypeId();
            set<Id> leadIds = new set<Id> ();
            set<Id> convertedLeadIds = new set<Id> ();
            Map<Id, List<String>>  dealerIdToDealerProsEmailMap = new Map<Id, List<String>> ();
            Map<Id, List<String>>  dealerIdToDealerProsPhoneMap = new Map<Id, List<String>> ();
            List<Contact> newContactsList = new List<Contact>();
            Set<Id> contactIdsToDeleteSet = new Set<Id>();
            for(Lead each: newList){
                Lead oldLead = oldMap.get(each.Id);
                   
                    if((each.Manager_Email__c != oldLead.Manager_Email__c && oldLead.Manager_Email__c == null) || (each.Dealer_pro_1_Email__c != oldLead.Dealer_pro_1_Email__c && oldLead.Dealer_pro_1_Email__c == null)
                    || (each.Dealer_pro_2_Email__c != oldLead.Dealer_pro_2_Email__c && oldLead.Dealer_pro_2_Email__c == null) || (each.Dealer_pro_3_Email__c != oldLead.Dealer_pro_3_Email__c && oldLead.Dealer_pro_3_Email__c == null)  ){
                        leadIds.add(each.Id);
                        List<String> emailList = new List<String>();
                        List<String> phoneList = new List<String>();
                        if(each.Manager_Email__c != null){
                            emailList.add(each.Manager_Email__c);
                            if(each.Manager_Cell_Phone__c != null){
                                phoneList.add(each.Manager_Cell_Phone__c);
                            }
                        }
                        if(each.Dealer_pro_1_Email__c != null){
                            emailList.add(each.Dealer_pro_1_Email__c);
                            if(each.Dealer_pro_1_Phone__c != null){
                                phoneList.add(each.Dealer_pro_1_Phone__c);
                            }
                        }
                        if(each.Dealer_pro_2_Email__c != null){
                            emailList.add(each.Dealer_pro_2_Email__c);
                            if(each.Dealer_pro_1_Phone__c != null){
                                phoneList.add(each.Dealer_pro_1_Phone__c);
                            }
                        }
                        if(each.Dealer_pro_3_Email__c != null){
                            emailList.add(each.Dealer_pro_3_Email__c);
                            if(each.Dealer_pro_1_Phone__c != null){
                                phoneList.add(each.Dealer_pro_1_Phone__c);
                            }
                        }
                        dealerIdToDealerProsEmailMap.put(each.Id, emailList);
                        dealerIdToDealerProsPhoneMap.put(each.Id, phoneList);

                    }
                    System.Debug('Condition ::: '+(each.IsConverted == true )+ (each.IsConverted != oldLead.IsConverted));
                    System.Debug('old Converted ::: '+ oldLead.IsConverted);
                    System.Debug('New Converted ::: '+ each.IsConverted);
                    if(each.IsConverted == true && each.IsConverted != oldLead.IsConverted){
                        convertedLeadIds.add(each.Id);
                        
                        if(each.RecordTypeId  == recordTypeId){
                            if(each.Dealer_Pro_1_Email__c != null && each.Dealer_Pro_1_Name__c != null){
                                newContactsList.add(createContact(each.Dealer_Pro_1_Name__c, each.Dealer_Pro_1_Email__c, each.Dealer_Pro_1_Role__c, each.ConvertedAccountId, each.Dealer_Pro_1_Phone__c, recordTypeIdDealerContact, each.Dealer_Pro_1_Years_at_Dealership__c));
                            }
                            if(each.Dealer_Pro_2_Email__c != null && each.Dealer_Pro_2_Name__c != null){
                                newContactsList.add(createContact(each.Dealer_Pro_2_Name__c, each.Dealer_Pro_2_Email__c, each.Dealer_Pro_3_Role__c, each.ConvertedAccountId, each.Dealer_Pro_2_Phone__c, recordTypeIdDealerContact, each.Dealer_Pro_2_Years_at_Dealership__c));

                            }
                            if(each.Dealer_Pro_3_Email__c != null && each.Dealer_Pro_3_Name__c != null){
                                newContactsList.add(createContact(each.Dealer_Pro_3_Name__c, each.Dealer_Pro_3_Email__c, each.Dealer_Pro_3_Role__c, each.ConvertedAccountId, each.Dealer_Pro_3_Phone__c, recordTypeIdDealerContact, each.Dealer_Pro_3_Years_at_Dealership__c));
                            }
                            if(each.GM_Email__c != null && each.GM_Name__c != null){
                                newContactsList.add(createContact(each.GM_Name__c, each.GM_Email__c, 'GM', each.ConvertedAccountId, each.GM_Phone__c, recordTypeIdDealerContact, null));
                            }
                            if(each.Finance_Director_Email__c != null && each.Finance_Director_Name__c != null){
                                newContactsList.add(createContact(each.Finance_Director_Name__c, each.Finance_Director_Email__c, 'Finance Director', each.ConvertedAccountId, each.Finance_Director_Phone__c, recordTypeIdDealerContact, each.Finance_Director_Years_at_Dealership__c));
                            }
                            if(each.Manager_Email__c != null && each.Manager_Name__c != null){
                                newContactsList.add(createContact(each.Manager_Name__c, each.Manager_Email__c, 'Manager', each.ConvertedAccountId, each.Manager_Cell_Phone__c, recordTypeIdDealerContact, null));
                            }
                            if(each.GSM_Email__c != null && each.GSM_Name__c != null){
                                newContactsList.add(createContact(each.GSM_Name__c, each.GSM_Email__c, 'GSM', each.ConvertedAccountId, each.GSM_Phone__c, recordTypeIdDealerContact, each.GSM_Years_at_Dealership__c));
                            }
                            if(each.Business_Manager_Email__c != null && each.Business_Manager_Name__c != null){
                                newContactsList.add(createContact(each.Business_Manager_Name__c, each.Business_Manager_Email__c, 'Business Manager', each.ConvertedAccountId, each.Business_Manager_Phone__c, recordTypeIdDealerContact, each.Business_Manager_Years_at_Dealership__c));
                            }
                            if(each.F_I_Email__c != null && each.F_I_Manager_Name__c != null){
                                newContactsList.add(createContact(each.F_I_Manager_Name__c, each.F_I_Email__c, 'F&I Manager', each.ConvertedAccountId, each.F_I_Manager_Cell_Phone__c, recordTypeIdDealerContact, null));
                            }
                            
                        }
                        else{
                            if(each.Contact_1_Name__c != null && each.Contact_1_Email__c != null){
                                newContactsList.add(createContact(each.Contact_1_Name__c, each.Contact_1_Email__c, each.Contact_1_Job_Title__c, each.ConvertedAccountId, each.Contact_1_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.Contact_2_Name__c != null && each.Contact_2_Email__c != null){
                                newContactsList.add(createContact(each.Contact_2_Name__c, each.Contact_2_Email__c, each.Contact_2_Job_Title__c, each.ConvertedAccountId, each.Contact_2_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.Contact_3_Name__c != null && each.Contact_3_Email__c != null){
                                newContactsList.add(createContact(each.Contact_3_Name__c, each.Contact_3_Email__c, each.Contact_3_Job_Title__c, each.ConvertedAccountId, each.Contact_3_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.Contact_4_Name__c != null && each.Contact_4_Email__c != null){
                                newContactsList.add(createContact(each.Contact_4_Name__c, each.Contact_4_Email__c, each.Contact_4_Job_Title__c, each.ConvertedAccountId, each.Contact_4_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CEO_Name__c != null && each.CEO_Email__c != null){
                                newContactsList.add(createContact(each.CEO_Name__c, each.CEO_Email__c, 'CEO', each.ConvertedAccountId, each.CEO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CFO_Name__c != null && each.CFO_Email__c != null){
                                newContactsList.add(createContact(each.CFO_Name__c, each.CFO_Email__c, 'CFO', each.ConvertedAccountId, each.CFO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CLO_Name__c != null && each.CLO_Email__c != null){
                                newContactsList.add(createContact(each.CLO_Name__c, each.CLO_Email__c, 'CLO', each.ConvertedAccountId, each.CLO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CExO_Name__c != null && each.CExO_Email__c != null){
                                newContactsList.add(createContact(each.CExO_Name__c, each.CExO_Email__c, 'CExO', each.ConvertedAccountId, each.CExO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CTO_Name__c != null && each.CTO_Email__c != null){
                                newContactsList.add(createContact(each.CTO_Name__c, each.CLO_Email__c, 'CTO', each.ConvertedAccountId, each.CTO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.COO_Name__c != null && each.COO_Email__c != null){
                                newContactsList.add(createContact(each.COO_Name__c, each.COO_Email__c, 'COO', each.ConvertedAccountId, each.COO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CMO_Name__c != null && each.CMO_Email__c != null){
                                newContactsList.add(createContact(each.CMO_Name__c, each.CMO_Email__c, 'CMO', each.ConvertedAccountId, each.CMO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CIO_Name__c != null && each.CIO_Email__c != null){
                                newContactsList.add(createContact(each.CIO_Name__c, each.CIO_Email__c, 'CIO', each.ConvertedAccountId, each.CIO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.CRO_Name__c != null && each.CRO_Email__c != null){
                                newContactsList.add(createContact(each.CRO_Name__c, each.CRO_Email__c, 'CRO', each.ConvertedAccountId, each.CRO_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.Project_Manager_Name__c != null && each.Project_Manager_Email__c != null){
                                newContactsList.add(createContact(each.Project_Manager_Name__c, each.Project_Manager_Email__c, 'project Manager', each.ConvertedAccountId, each.Project_Manager_Cell_Phone__c, recordTypeIdCUContact, null));
                            }
                            if(each.Lead_MSR_Email__c != null && each.Lead_MSR_Name__c != null){
                                newContactsList.add(createContact(each.Lead_MSR_Name__c, each.Lead_MSR_Email__c, 'Lead MSR', each.ConvertedAccountId, each.Lead_MSR_Cell_Phone__c, recordTypeIdCUContact, null));
                            }
                        }
                        if(each.ConvertedContactId != null){
                            contactIdsToDeleteSet.add(each.ConvertedContactId);
                        }
                    }
                    
            }
            if(newContactsList.size() > 0){
                insert newContactsList;
            }
            if(contactIdsToDeleteSet.size() > 0){
                List<Contact> contactsToDeleteList = [SELECT Id, AccountId FROM Contact WHERE Id =: contactIdsToDeleteSet];
                Map<String, String> ContactAccountIdMap = new Map<String, String>();
                for(Contact each:contactsToDeleteList){
                    ContactAccountIdMap.put(each.Id, each.AccountId);
                }

                List<Task> taskList = [SELECT Id, WhatId, WhoId FROM Task WHERE WhoId IN: contactIdsToDeleteSet];
                if(taskList.size()> 0){
                    List<Task> taskToUpdateList = new List<Task>();
                for(Task each:taskList){
                    if(ContactAccountIdMap.containsKey(each.WhoId)){
                        each.WhatId = ContactAccountIdMap.get(each.WhoId);
                        each.WhoId = null;
                        taskToUpdateList.add(each);
                    }
                }
                if(taskToUpdateList.size()>0){
                    System.debug('Task Updated');
                    update taskToUpdateList;
                }

            }
                
                if(contactsToDeleteList.size() > 0){
                    delete(contactsToDeleteList);
                }
            }
            if(convertedLeadIds.size()>0){
                System.Debug('Inside Update Dealer');
                List<Garage__c> garageList = [SELECT Id, Name, VIN__C, Active__c, Lead_Dealer__r.ConvertedAccountId,  Dealer__c FROM Garage__C WHERE Lead_Dealer__c IN:convertedLeadIds];
                if(garageList.size()> 0){
                    for(Garage__c each:garageList){
                        each.Dealer__c = each.Lead_Dealer__r.ConvertedAccountId;
                    }
                    System.Debug('Update Dealer');
                    update garageList;
                }
                
              /*  List<String> ConvertedLeadJsonList = new List<String>();
                for(Id each:convertedLeadIds ){
                    Map<String, Object> objMap = new Map<String, Object>();
                    objMap.put('Id', each);
                    objMap.put('IsConverted', true);
                    ConvertedLeadJsonList.add(JSON.serialize(objMap));
                }
                if(ConvertedLeadJsonList.size() > 0){
                    AzureIntegrationService.updateDataInAzure(ConvertedLeadJsonList);
                }*/

            }
            
            // Adding Account Manager Emails 
            
            if(!leadIds.isEmpty()){
                sendPendingRequestsToDealer(leadIds, dealerIdToDealerProsEmailMap, dealerIdToDealerProsPhoneMap);
                System.debug('Pending req method called');
            }
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
        
    }

    public static Contact createContact(String lastName, String email, String title, Id accountId, String phone, Id recordTypeId, Decimal yearsAtDealership){
        Contact contact = new Contact();
        contact.LastName = lastName;
        contact.Email = email;
        contact.Title = title;
        contact.AccountId = accountId;
        contact.phone = phone;
        contact.MobilePhone = phone;
        contact.recordTypeId = recordTypeId;
        contact.Years_at_Dealership__c = yearsAtDealership;
        return contact;
        
    }
    
    
    public static void sendPendingRequestsToDealer (Set<Id> leadIds, Map<Id, List<String>>  idToEmailMap, Map<Id, List<String>>  idToPhoneMap){
        try{
            List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Support' LIMIT 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            
            if (orgWideEmail == null) {
                System.debug('No Org-Wide Email Address found');
                return;
            }
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            List<Garage__c> garagesToUpdate = new List<Garage__c>();
            
            List<Garage__c> garageList = [SELECT Id, Name, VIN__C, Active__c, Dealer_Email_Available__c, FastPass_Dealer_Id__c, Pending_Requests__c, Dealer__c FROM Garage__C WHERE Lead_Dealer__c IN:leadIds];
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
                    List<Garage__c> garageswithPendingRequests = [SELECT Id, Name, VIN__c, FastPass_Dealer_Id__c, Opportunity__C, Pending_Requests__c, Dealer__c, Dealer__r.Manager_Email__c,Lead_Dealer__c,FastPass_Vehicle_Id__c FROM Garage__c WHERE Id IN:garageSet];
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
                                    List<String> toAddress = idToEmailMap.get(garage.Lead_Dealer__c);
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
                                        if(body.contains('Note: Click on the link to REPLY')){
                                           body = body.replaceAll('<[^>]*>', '');
                                           body = body.replaceAll('\n', '');
                                           body = body.replaceAll('\t', '');
                                           body = body.substringBefore('Thanks,FastPass');
                                           
                                           // String response = body.substringBetween('<a href="', '">Click here to reply');
                                           // System.debug('response:: '+response);
                                            String messageText = smsTemplate.size()>0 ? smsTemplate[0].tdc_tsw__SMSBodyNew__c : null;
                                            
                                            if(idToPhoneMap.containsKey(garage.Lead_Dealer__c) && messageText != null){
                                                messageText = messageText.replace('{firstMessage}', body);
                                                String conLink = dealerportalURL+'?q='+encryptedParams;
                                                messageText = messageText.replace('{Link}', conLink);
                                                for(String sms : idToPhoneMap.get(garage.Lead_Dealer__c) ){
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

    public static void mapLeadsToGarage(List<Lead> newList){
        Map<String, String> fpDealerIdLeadIdMap = new Map<String, String>();

        for(Lead lead : newList){
            if(lead.Fastpass_Dealer_Id__c != null ){
                fpDealerIdLeadIdMap.put(lead.Fastpass_Dealer_Id__c, lead.Id);
            }
        }
        List<Garage__c> garageList = [SELECT Id, Fastpass_Dealer_Id__c FROM Garage__c WHERE Fastpass_Dealer_Id__c IN:fpDealerIdLeadIdMap.keySet() AND Dealer__c = null AND Lead_Dealer__c = null];

        List<Garage__c> garageListToUpdate = new List<Garage__c>();
        if(garageList.size() > 0){
            for(Garage__c garage : garageList){
                if(fpDealerIdLeadIdMap.containsKey(garage.Fastpass_Dealer_Id__c)){
                    Garage__c garageRecord = new Garage__c();
                    garageRecord.Id = garage.Id;
                    garageRecord.Lead_Dealer__c = fpDealerIdLeadIdMap.get(garage.Fastpass_Dealer_Id__c);
                    garageListToUpdate.add(garageRecord);
                }
            }
        }
        if(garageListToUpdate.size() > 0){
            update garageListToUpdate;
        }
    }

}