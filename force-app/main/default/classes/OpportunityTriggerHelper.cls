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
                        else if((eachOpp.Phone__c == null && eachOpp.Mobile__c != null && oldMap.get(eachOpp.Id).Mobile__c == null) || (eachOpp.Mobile__c == null && eachOpp.Phone__c != null && oldMap.get(eachOpp.Id).Phone__c == null ) && eachOpp.FastPass_Team_SMS_Support__c == false ){
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
                for(Opportunity eachOpp : [SELECT Id, Bank_Service_Rep_Name_MSR__r.Email, Bank_Service_Rep_Name_MSR__r.FastPass_Team_Email_Support__c  FROM Opportunity WHERE Id =:msrUpdatedOppIds AND Bank_Service_Rep_Name_MSR__r.Email != null] ){
                    if(eachOpp.Bank_Service_Rep_Name_MSR__r.FastPass_Team_Email_Support__c == false &&  eachOpp.Bank_Service_Rep_Name_MSR__r.Email != null ){
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
                        htmlBody = htmlBody.replace ('{Bank_Service_Rep_Name_MSR_Id}', eachOpp.Bank_Service_Rep_Name_MSR__c);
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
    public static void restrictNonRelatedMSR(List<Opportunity> newOppList, Map<Id, Opportunity> oldMap) {
        // Set to store unique Branch IDs from the Opportunity records
        Set<String> branchIds = new Set<String>();
    
        // Map to store the relationship between Branches (AccountId) and their associated MSRs (ContactId)
        Map<String, List<String>> accConRelationMap = new Map<String, List<String>>();
    
        // Extract Branch IDs from new Opportunities
        for (Opportunity opp : newOppList) {
            if (opp.Branch__c != null) {
                branchIds.add(opp.Branch__c);
            }
        }
    
        // Fetch the Account-Contact relationships where the AccountId (Branch) is in the collected Branch IDs
        List<AccountContactRelation> accConRelationList = [
            SELECT Id, AccountId, ContactId 
            FROM AccountContactRelation 
            WHERE AccountId IN :branchIds
        ];
    
        // Populate the accConRelationMap with Branch (AccountId) as the key and a list of related MSRs (ContactId) as the value
        for (AccountContactRelation each : accConRelationList) {
            if (accConRelationMap.containsKey(each.AccountId)) {
                accConRelationMap.get(each.AccountId).add(each.ContactId);
            } else {
                accConRelationMap.put(each.AccountId, new List<String>{each.ContactId});
            }
        }
    
        // Iterate through new Opportunities to apply validation rules
        for (Opportunity opp : newOppList) {
            // Retrieve old Opportunity record before update (if applicable)
            Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
    
            // Validation 1: If MSR is selected but no Branch is chosen, show an error
            if (opp.Branch__c == null && opp.Bank_Service_Rep_Name_MSR__c != null) {
                opp.addError('Please select Branch.');
            }
            // Validation 2: If MSR is changed or newly selected, check if it is related to the Branch
            else if (opp.Branch__c != null && opp.Bank_Service_Rep_Name_MSR__c != null &&  
                     (oldOpp == null || opp.Bank_Service_Rep_Name_MSR__c != oldOpp.Bank_Service_Rep_Name_MSR__c)) {
                
                // Check if the Branch exists in the relationship map and whether the MSR is associated with it
                if (!accConRelationMap.containsKey(opp.Branch__c) || 
                    (accConRelationMap.containsKey(opp.Branch__c) && 
                     !(accConRelationMap.get(opp.Branch__c)).contains(opp.Bank_Service_Rep_Name_MSR__c))) {
                    opp.addError('This MSR is not related to the Branch selected. Please select another MSR and try again.');
                }
            }
        }
    }    

}