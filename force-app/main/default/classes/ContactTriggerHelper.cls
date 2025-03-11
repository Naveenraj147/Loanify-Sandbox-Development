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


public void processPortalMessages(List<Contact> newContactList){
    System.Debug('Inside processPortalMessages');
    Set<Id> accIds = new Set<Id>();
    Set<Id> dealerAccIds = new Set<Id>();
    String msrRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Bank Service Rep').getRecordTypeId();
    String dealerProRecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Dealer_Pro').getRecordTypeId();
    for (Contact con : newContactList) {
        if(con.RecordTypeId == msrRecordTypeId && con.AccountId != null){
            accIds.add(con.AccountId);
        }
        if(con.RecordTypeId == dealerProRecordTypeId && con.Active__c == true && con.Member_Response_Notification__c == true ){
            dealerAccIds.add(con.AccountId);
        }
    }
    if(accIds.size() > 0){
        List<Portal_Message__c> pmList = [SELECT id, Opportunity__r.Branch__c , Is_Pending__c  FROM Portal_Message__c 
                                            WHERE Opportunity__r.Branch__c in :accIds AND Portal_Type__c = 'MSR' AND Is_Pending__c = true];
        if(pmList.size() > 0){
            for(Portal_Message__c each : pmList){
                each.Is_Pending__c = false;
            }
            update pmList;

        }
    }
    if(dealerAccIds.size() > 0){
        List<Garage__c> garageList = [SELECT id, Dealer_Email_Available__c  FROM Garage__c 
                                            WHERE Dealer__c in :dealerAccIds  AND Dealer_Email_Available__c = false];
        if(garageList.size() > 0){
            for(Garage__c each : garageList){
                each.Dealer_Email_Available__c = true;
            }
            update garageList; 
        }

        List<Portal_Message__c> pmList = [SELECT id, Is_Pending__c  FROM Portal_Message__c 
                                            WHERE Garage__r.Dealer__c in :dealerAccIds AND Portal_Type__c = 'Dealer' AND Is_Pending__c = true];
        if(pmList.size() > 0){
            for(Portal_Message__c each : pmList){
                each.Is_Pending__c = false;
            }
            update pmList;

        }
    }
   
}
public void processPMforContactUpdate(List<Contact> newContactList, Map<Id,Contact> oldContactMap){
    System.Debug('Inside processPMforContactUpdate');
    List<Contact> updatedContactWithCriteria = new List<Contact>();
    Set<Id> accIds = new Set<Id>();
    Set<Id> appDownloadedMembers = new Set<Id>();
    for(Contact con : newContactList){
        if(con.Active__c == true  && con.Member_Response_Notification__c == true && (oldContactMap.get(con.Id).Active__c != con.Active__c || oldContactMap.get(con.Id).Member_Response_Notification__c != con.Member_Response_Notification__c )){
            updatedContactWithCriteria.add(con);
        }
        else if((con.Active__c == false && oldContactMap.get(con.Id).Active__c != con.Active__c) || (con.Member_Response_Notification__c == false && oldContactMap.get(con.Id).Member_Response_Notification__c != con.Member_Response_Notification__c)){
            accIds.add(con.AccountId);
        }
        if(con.App_Downloaded__c != null && con.App_Downloaded__c != oldContactMap.get(con.Id).App_Downloaded__c ){
            appDownloadedMembers.add(con.Id);
        }
    }
    System.Debug('updatedContactWithCriteria.size() ===> '+updatedContactWithCriteria.size());
    if(updatedContactWithCriteria.size() > 0){
        processPortalMessages(updatedContactWithCriteria);
    }
    if(appDownloadedMembers.size() > 0 && System.Label.MSR_Notifications == 'TRUE' ){
        sendSMSandEmail(appDownloadedMembers);
    }
    System.Debug('accIds.size() ===> '+accIds.size());
    if(accIds.size() > 0){
        Map<Id, Account> accMap = new Map<Id, Account> ([SELECT Id, Manager_Email__c, (SELECT Id FROM Contacts WHERE Active__c = true AND Member_Response_Notification__c = true) FROM Account WHERE Id =: accIds]);
        List<Garage__c> garList = [SELECT Id, Dealer_Email_Available__c, Dealer__c FROM Garage__c WHERE Dealer__c =: accIds AND Dealer_Email_Available__c = true];
        List<Garage__c> garListToUpdate = new List<Garage__c>();
        System.Debug('accMap ===> '+accMap.size());
        System.Debug('garList ===> '+garList.size());
        if(garList.size() > 0){
            for(Garage__c gar : garList){
                if(accMap.containsKey(gar.Dealer__c)  && accMap.get(gar.Dealer__c).contacts.size() == 0){ 
                    Garage__c newGarage = new Garage__c();
                    newGarage.Id = gar.Id;
                    newGarage.Dealer_Email_Available__c = false;
                    garListToUpdate.add(newGarage);

                }
            }
        }
        if(garListToUpdate.size() > 0){
            update garListToUpdate;
        }
    }

}


public void sendSMSandEmail(Set<Id> contactList){
    system.debug('Inside SMS Test ');
    List<EmailTemplate> emailTempList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'MSR_Notification_for_Member_Connected_to_FastPass' LIMIT 1];
    EmailTemplate emailTemplate = emailTempList.size() > 0 ? emailTempList[0] : null ;

    List<tdc_tsw__Message_Template__c> smsTempList = [SELECT Id, Name FROM tdc_tsw__Message_Template__c WHERE Name = 'CU Member Post-Time/Date Notification' LIMIT 1];
    tdc_tsw__Message_Template__c smsTemplate = smsTempList.size() > 0 ? smsTempList[0] : null ;
    String autoShopperRecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Shopper').getRecordTypeId();
    List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName = 'Support' Limit 1];
    OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
    String orgWideEmailId = orgWideEmail != null? orgWideEmail.Id : null;
        
    Set<Id> memberIds = new Set<Id>();
    List<Messaging.SingleEmailMessage> emailList = new  List<Messaging.SingleEmailMessage>();
    String dealerportalURL = system.label.Dealer_Portal_Page_URL;
    List<Opportunity> oppList = [SELECT Id, Bank_Service_Rep_Name_MSR__c, Bank_Service_Rep_Name_MSR__r.Email, Mobile__c, Auto_Shopper__r.RecordTypeId, Auto_Shopper__c FROM Opportunity WHERE Auto_Shopper__c =: contactList AND IsClosed = false Order By CreatedDate desc ];
    for(Opportunity eachOpp : oppList){ 
        if(!memberIds.contains(eachOpp.Auto_Shopper__c)){
            if(eachOpp.Bank_Service_Rep_Name_MSR__c != null && eachOpp.Bank_Service_Rep_Name_MSR__r.Email != null && emailTemplate != null){
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
            if(smsTempList.size() > 0){
                if(eachOpp.Auto_Shopper__r.RecordTypeId == autoShopperRecordTypeId  && (eachOpp.Mobile__c != null || eachOpp.Phone__c != null)) {
                    system.debug('Inside SMS Sending ');
                    String phoneField = eachOpp.Mobile__c != null ? eachOpp.Mobile__c : eachOpp.Phone__c;
                    tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId(phoneField,smsTempList[0].Id,eachOpp.Id);
                }
            }
            memberIds.add(eachOpp.Auto_Shopper__c);
        }
       
    }
    if(emailList.size() > 0){
        Messaging.sendEmail(emailList);
    }

}


}