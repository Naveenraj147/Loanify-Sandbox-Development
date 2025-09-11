public class LeadTriggerHelper {
    
    public static void processEmailUpdatedLeads (List<Lead> newList, Map<Id, Lead> oldMap){
        try{
            Set<Id> conIds = new Set<Id> ();
            Id recordTypeId = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Dealer').getRecordTypeId();
            Id recordTypeIdDealerContact = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();
            Id recordTypeIdCUContact = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Bank_Service_Rep').getRecordTypeId();
            set<Id> leadIds = new set<Id> ();
            set<Id> convertedLeadIds = new set<Id> ();
            //Collect converted AccountId with LeadId
            Map<Id, Lead> convertedLeadIdWithId = new Map<Id, Lead> ();
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
                    if(each.IsConverted == true && each.IsConverted != oldLead.IsConverted){
                        convertedLeadIds.add(each.Id);
                        convertedLeadIdWithId.put(each.Id, each);
                        
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
                            TriggerAPIService.logTriggerEvent('SF_DML_INSERT16', 'SF34', UserInfo.getUserName(), null);
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
                            TriggerAPIService.logTriggerEvent('SF_DML_INSERT17', 'SF35', UserInfo.getUserName(), null);
                        }
                        if(each.ConvertedContactId != null){
                            contactIdsToDeleteSet.add(each.ConvertedContactId);
                        }
                    }
                    
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
                    TriggerAPIService.logTriggerEvent('SF_DML_UPDATE11', 'SF34', UserInfo.getUserName(), null);
                }
                
              List<String> ConvertedLeadJsonList = new List<String>();
                for(Id each:convertedLeadIds ){
                    //Check Converterd Lead is Dealer RecordType
                    if(convertedLeadIdWithId.containsKey(each) && convertedLeadIdWithId.get(each).RecordTypeId == recordTypeId){
                        ConvertedLeadJsonList.add(AzureIntegrationService.serializeWithNulls(convertedLeadIdWithId.get(each)));
                    }
                }
                if(ConvertedLeadJsonList.size() > 0){
                    AzureIntegrationService.updateDataInAzure(ConvertedLeadJsonList);
                }
                
            }
            
            if(!leadIds.isEmpty() ){
                 processPMforLeadUpdate(leadIds);
            }
            if(newContactsList.size() > 0){
                insert newContactsList;
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


    public static void processPMforLeadUpdate(Set<Id> leadIds){
	System.debug('Inside process portal messages');
        List<Garage__c> garList = [SELECT Id, Dealer_Email_Available__c, Lead_Dealer__c FROM Garage__c WHERE Lead_Dealer__c =: leadIds AND Dealer_Email_Available__c = false];
        if(garList.size() > 0){
            List<Garage__c> garListToUpdate = new List<Garage__c>();
            for(garage__c eachGarage : garList ){
                Garage__c garage = new Garage__c();
                garage.Id = eachGarage.Id;
                garage.Dealer_Email_Available__c = true;    
                garListToUpdate.add(garage);
            }
            if(garListToUpdate.size() > 0){
				System.debug('Inside garage Update');
                update garListToUpdate;
                TriggerAPIService.logTriggerEvent('SF_DML_UPDATE19', 'SF33', UserInfo.getUserName(), null);
            }
            List<Portal_Message__c> portalMessageList = [SELECT Is_Pending__c FROM Portal_Message__c WHERE Is_Pending__c = true AND Garage__c IN : garListToUpdate ];
            System.debug('portalMessageList ===> '+ portalMessageList);
			if(portalMessageList.size() > 0){
                System.debug('Inside Portal Message Update');
                for(Portal_Message__c eachPM : portalMessageList){
                    eachPM.Is_Pending__c = false;
                }
                update portalMessageList;
                TriggerAPIService.logTriggerEvent('SF_DML_UPDATE20', 'SF33', UserInfo.getUserName(), null);
            }
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

    public static void updateControlNumbers(List<Lead> newLeads, Map<Id, Lead> oldLeads) {

        try {
            List<Lead> leadsToProcess = new List<Lead>();
            Id creditUnionRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Credit_Union').getRecordTypeId();

            for (Lead each : newLeads) {
                if (each.RecordTypeId == creditUnionRecordTypeId ) {
                    if (each.Status == 'Proposal' && each.Status != oldLeads.get(each.Id).Status  && each.Proposal_Control_Number__c == null) {
                        leadsToProcess.add(each);
                    }
                    if (each.Status == 'Due Diligence - Contract' && each.Status != oldLeads.get(each.Id).Status && each.Contract_Control_Number__c == null) {
                        leadsToProcess.add(each);
                    }
                }
            }

            if (!leadsToProcess.isEmpty()) {

                Map<String, String> maxProposalNumbers ;
                Map<String, String> maxContractNumbers ;

                List<Lead> existingLeads = [
                    SELECT Credit_Union_Id__c, Proposal_Control_Number__c, Contract_Control_Number__c 
                    FROM Lead 
                    WHERE (Proposal_Control_Number__c != NULL OR Contract_Control_Number__c != NULL)
                    AND RecordTypeId =: creditUnionRecordTypeId ALL ROWS
                ];

                List<Lead> maxProposalLeadRecord= [
                    SELECT Proposal_Control_Number_Formula__c 
                    FROM Lead 
                    WHERE Proposal_Control_Number_Formula__c  != NULL AND RecordTypeId =: creditUnionRecordTypeId
                    ORDER BY Proposal_Control_Number_Formula__c desc Limit 1 ALL ROWS];

                List<Lead> contractLeadRecord= [
                    SELECT Contract_Control_Number_Formula__c 
                    FROM Lead 
                    WHERE Contract_Control_Number_Formula__c  != NULL AND RecordTypeId =: creditUnionRecordTypeId
                    ORDER BY Contract_Control_Number_Formula__c desc Limit 1 ALL ROWS];

                Integer maxProposalNumber = !maxProposalLeadRecord.isEmpty() ? Integer.valueOf(maxProposalLeadRecord[0].Proposal_Control_Number_Formula__c) : 0 ;
                Integer maxContractNumber = !contractLeadRecord.isEmpty() ? Integer.valueOf(contractLeadRecord[0].Contract_Control_Number_Formula__c) : 0 ;
                
                // Assign numbers
                for (Lead each : leadsToProcess) {
                        
                    String creditUnionId = (each.Credit_Union_Id__c != null) ? String.valueOf(Math.floor(each.Credit_Union_Id__c)) : '';

                    if (each.Status == 'Proposal' && String.isEmpty(each.Proposal_Control_Number__c)) {
                        maxProposalNumber=maxProposalNumber >= 10 ? maxProposalNumber + 1 : 10;
                        each.Proposal_Control_Number__c = 'P-' + (String.isEmpty(creditUnionId) ? '' : creditUnionId + '-') + String.valueOf(maxProposalNumber).leftPad(3, '0');               
                    }

                    if (each.Status == 'Due Diligence - Contract' && String.isEmpty(each.Contract_Control_Number__c)) {
                        maxContractNumber=maxContractNumber >= 500 ? maxContractNumber + 1 : 500;
                        String maxContractValuePrefix='C-' + String.valueOf(maxContractNumber).leftPad(4, '0'); 
                        each.Contract_Control_Number__c = maxContractValuePrefix;
                        each.Contract_Control_Number__c += each.Proposal_Control_Number__c != null ? '-'+each.Proposal_Control_Number__c: '' ;
                    }
                } 
            }
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
        
    }
    
    public static void updateDefaultValues(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        try {
            Id creditUnionRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Credit_Union').getRecordTypeId();

            for (Lead each : newLeads) {

                if (each.RecordTypeId == creditUnionRecordTypeId ) {
                    if(Trigger.isInsert){
                        each.LinkedIn_Profile__c = (each.LinkedIn_Profile__c==null && each.LinkedIn_Email__c!=null) ? 
                            each.LinkedIn_Email__c : each.LinkedIn_Profile__c;
                        each.Interested_Name__c = (each.Interested_Name__c==null && each.Initial_Contact_Name__c!=null) ? 
                            each.Initial_Contact_Name__c : each.Interested_Name__c;
                        each.Interested_Email__c = (each.Interested_Email__c==null && each.Direct_Email__c!=null) ? 
                            each.Direct_Email__c : each.Interested_Email__c;
                        each.Planned_Demo_Date__c = (each.Planned_Demo_Date__c==null && each.Demo_Date_Planned__c!=null) ? 
                            each.Demo_Date_Planned__c : each.Planned_Demo_Date__c;
                        each.Actual_Executed_Demo_Date__c = (each.Actual_Executed_Demo_Date__c==null && each.Planned_Demo_Date__c!=null) ? 
                            each.Planned_Demo_Date__c : each.Actual_Executed_Demo_Date__c;
                    }else if(Trigger.isUpdate){
                        each.LinkedIn_Profile__c = (each.LinkedIn_Profile__c==null && each.LinkedIn_Email__c!=null && each.LinkedIn_Email__c != oldLeadMap.get(each.Id).LinkedIn_Email__c) ? 
                            each.LinkedIn_Email__c : each.LinkedIn_Profile__c;
                        each.Interested_Name__c = (each.Interested_Name__c==null && each.Initial_Contact_Name__c!=null && each.Initial_Contact_Name__c != oldLeadMap.get(each.Id).Initial_Contact_Name__c) ? 
                            each.Initial_Contact_Name__c : each.Interested_Name__c;
                        each.Interested_Email__c = (each.Interested_Email__c==null && each.Direct_Email__c!=null && each.Direct_Email__c != oldLeadMap.get(each.Id).Direct_Email__c) ? 
                            each.Direct_Email__c : each.Interested_Email__c;
                        each.Planned_Demo_Date__c = (each.Planned_Demo_Date__c==null && each.Demo_Date_Planned__c!=null && each.Demo_Date_Planned__c != oldLeadMap.get(each.Id).Demo_Date_Planned__c) ? 
                            each.Demo_Date_Planned__c : each.Planned_Demo_Date__c;
                        each.Actual_Executed_Demo_Date__c = (each.Actual_Executed_Demo_Date__c==null && each.Planned_Demo_Date__c!=null && each.Planned_Demo_Date__c != oldLeadMap.get(each.Id).Planned_Demo_Date__c) ? 
                            each.Planned_Demo_Date__c : each.Actual_Executed_Demo_Date__c;
                    }
                }
            }    
        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
    }
}