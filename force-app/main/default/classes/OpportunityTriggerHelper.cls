public class OpportunityTriggerHelper {
    public static void sendSMSAndEmail(List<Opportunity> newOppList, Map<Id, Opportunity> oldMap){
        try{
            List<tdc_tsw__Message_Template__c> smsTempList = [SELECT Id, Name FROM tdc_tsw__Message_Template__c WHERE Name = 'CU Member Pre-Time/Date Notification' LIMIT 1];
            tdc_tsw__Message_Template__c smsTemplate = smsTempList.size() > 0 ? smsTempList[0] : null ;
            List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName = 'Support' Limit 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            String orgWideEmailId = orgWideEmail != null? orgWideEmail.Id : null;
            List<EmailTemplate> emailTempList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'MSR_Notification_for_Member_Connected_to_FastPass' LIMIT 1];
            EmailTemplate emailTemplate = emailTempList.size() > 0 ? emailTempList[0] : null ;
            List<Messaging.SingleEmailMessage> emailList = new  List<Messaging.SingleEmailMessage>();

            set<Id> msrUpdatedOppIds = new Set<Id>();
            set<Id> msrUpdatedBranchIds = new Set<Id>();
            
            for(Opportunity eachOpp : newOppList){
                if(System.Label.MSR_Notifications == 'TRUE'){
                    if((eachOpp.Mobile__c != null || eachOpp.Phone__c != null) && smsTemplate != null ){
                        String smsField = eachOpp.Mobile__c != null? 'Mobile__c' : 'Phone__c';
                        if(oldMap == null){
                            tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId(smsField, smsTemplate.Id, eachOpp.Id);
                        }
                        else if((eachOpp.Phone__c == null && eachOpp.Mobile__c != null && oldMap.get(eachOpp.Id).Mobile__c == null) || (eachOpp.Mobile__c == null && eachOpp.Phone__c != null && oldMap.get(eachOpp.Id).Phone__c == null) ){
                            tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId(smsField, smsTemplate.Id, eachOpp.Id);
                        }
                    }
                    if(eachOpp.Bank_Service_Rep_Name_MSR__c != null && eachOpp.Download_Stamp__c != null && (oldMap == null || oldMap.get(eachOpp.Id).Bank_Service_Rep_Name_MSR__c == null)  ){
                        msrUpdatedOppIds.add(eachOpp.Id);
                    } 
                }
            }
            
            if(msrUpdatedOppIds.size() > 0 && emailTemplate != null){
                String dealerportalURL = system.label.Dealer_Portal_Page_URL;
                for(Opportunity eachOpp : [SELECT Id, Bank_Service_Rep_Name_MSR__r.Email FROM Opportunity WHERE Id =:msrUpdatedOppIds AND Bank_Service_Rep_Name_MSR__r.Email != null] ){
                    Messaging.SingleEmailMessage emailTempRender = Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, eachOpp.Id);
                    Map<String, Object> params = new Map<String, Object>();
                    params.put('opportunityId', eachOpp.Id);
                    params.put('portalType', 'MSR');
                    params.put('linkSharedDate', Date.today());
                    // Convert to JSON string
                    String jsonParams = JSON.serialize(params);
                    String conLink = dealerportalURL+'?q='+CryptoUtility.encrypt(jsonParams);
                    String htmlBody = emailTempRender.getHtmlBody();
                    htmlBody = htmlBody.replace ('click here', '<a href="' +conLink+ '">click here</a>');
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        // Set the recipient (to address)
                        List<String> toAddresses = new List<String> {eachOpp.Bank_Service_Rep_Name_MSR__r.Email};
                        email.setToAddresses(toAddresses);
                        email.setSubject(emailTempRender.getSubject());
                        email.setHtmlBody(htmlBody);
                        email.setOrgWideEmailAddressId(orgWideEmailId);
                        email.setWhatId(eachOpp.Id);
                        emailList.add(email);
                }
                if(emailList.size() > 0){
                    Messaging.sendEmail(emailList);
                }
            }
        }
        catch(exception e){
            System.debug('Error ==> '+e.getMessage());
        }
    
        
    }
    public static void processPortalMessages(List<Opportunity> newOppList, Map<Id, Opportunity> oldMap){
        Set<Id> updatedOppIds = new Set<Id>();
        for (Opportunity opp : newOppList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.Branch__c != null && opp.Bank_Service_Rep_Name_MSR__c != oldOpp.Bank_Service_Rep_Name_MSR__c) {
                updatedOppIds.add(opp.id);
            }
        }
        if(updatedOppIds.size() > 0){
            List<Portal_Message__c> pmList = [SELECT id, Opportunity__c, Is_Pending__c, Opportunity__r.Branch__c   FROM Portal_Message__c 
                                                WHERE Opportunity__c in :updatedOppIds AND Portal_Type__c = 'MSR' AND Is_Pending__c = true];
            if(pmList.size() > 0){
                for(Portal_Message__c each : pmList){
                    each.Is_Pending__c = false;
                }
                update pmList;

            }
        }
    }

}