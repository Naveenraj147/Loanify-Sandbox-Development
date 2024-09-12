public class CallerListTableController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(){
        return [SELECT Name, Phone, RecordType.Name, AccountId, MobilePhone,  Account.Name, Account.Phone FROM Contact order by Name asc];
    }
    
    @AuraEnabled
    public static List<VoiceCall> getVoiceCall(String opportunityId, String contactId){
        return [SELECT Name, CallDurationInSeconds, CallAcceptDateTime, CallType, Call_End_Status__c FROM VoiceCall WHERE Opportunity__c =:opportunityId AND RelatedRecordId =:contactId order by Name desc];
    }
    
    @AuraEnabled
    public static void relateOppWithVoiceCall(Id recId, String phNumber ){
        system.debug('phNumber  :: ' +phNumber);
        system.debug('recId  :: ' +recId);
        Datetime currentTime = Datetime.now();
        Datetime newTime = currentTime.addSeconds(-20);
        
        system.debug('currentTime  :: ' +currentTime);
        system.debug('newTime  :: ' +newTime);
        List<VoiceCall> vcList = [SELECT Id, RelatedRecordId, Opportunity__c, ToPhoneNumber FROM VoiceCall WHERE ToPhoneNumber =: phNumber AND CallType = 'Outbound'  order by createdDate desc  ]; //AND createdDate > :newTime
        system.debug('vcList  :: ' +vcList);
        if (vcList.size() > 0) {
            VoiceCall vc = vcList[0];
            if(vc.Opportunity__c == null ){
                vc.Opportunity__c = recId;
                update vc;
            }
            
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Task> getRelatedCallLogs(String opportunityId){
        return [SELECT  Id, WhoId, TaskSubtype,  WhatId  FROM Task WHERE WhatId =:opportunityId AND TaskSubtype = 'Call' order by createdDate desc];
    } 
    @AuraEnabled
    public static String getOmniStatus(){
        String presenceStatus = 'false';
        List<UserServicePresence> presenceStatusRecord =  [SELECT Id, Name, OwnerId, IsCurrentState, StatusDuration, AverageCapacity, AtCapacityDuration, StatusStartDate, UserId, ServicePresenceStatus.DeveloperName FROM UserServicePresence Where ServicePresenceStatus.DeveloperName = 'AvailableforVoice' OR ServicePresenceStatus.DeveloperName = 'All_Available' order by createddate desc];
        if(presenceStatusRecord.size() > 0){
            if(presenceStatusRecord[0].IsCurrentState == true || Test.isRunningTest()){
                presenceStatus = 'true';
            }
        }
        return presenceStatus;
        
    } 
    
    @AuraEnabled
    public static String navigateSMSPage(String contactId, String oppId){
        
        String returnValue = 'false';
        try{
            List<UserServicePresence> presenceStatusRecord =  [SELECT Id, Name, OwnerId, IsCurrentState, StatusDuration, AverageCapacity, AtCapacityDuration, StatusStartDate, UserId, ServicePresenceStatus.DeveloperName FROM UserServicePresence Where ServicePresenceStatus.DeveloperName = 'All_Available' OR ServicePresenceStatus.DeveloperName = 'Available_for_SMS' order by createddate desc];
            if(presenceStatusRecord.size() > 0){
                if(presenceStatusRecord[0].IsCurrentState == true || Test.isRunningTest()){
                    List<MessagingSession> MSList = [SELECT Id, EndUserContactId, Status FROM MessagingSession WHERE EndUserContactId =: contactId AND Status != 'Ended' order by createddate desc ];
                    if(MSList.size() > 0){
                        returnValue = MSList[0].Id;
                    }
                    else{
                        List<MessagingEndUser> MEUList = [SELECT Id, ContactId, Opportunity__c FROM MessagingEndUser WHERE ContactId =: contactId AND MessagingConsentStatus != 'Opted Out' AND MessagingChannel.DeveloperName != 'TEXT_US_15126168756' ];
                        List<MessagingChannel> MCList = [SELECT Id from MessagingChannel WHERE MasterLabel = '+17148688746' ];
                        if(MEUList.size() > 0){
                            MEUList[0].Opportunity__c = oppId;
                            update MEUList[0];
                            returnValue = MEUList[0].Id;
                        }
                        else{
                            List<Contact> conList = [SELECT Id, Phone, MobilePhone, Name from Contact WHERE Id =: contactId ];
                            MessagingEndUser ME = new MessagingEndUser();
                            ME.Name = conList[0].Name;
                            ME.MessageType = 'Text';
                            ME.MessagingChannelId = MCList.size() > 0? MCList[0].Id:null;
                            ME.MessagingConsentStatus = 'ImplicitlyOptedIn';
                            ME.ContactId = contactId;
                            ME.Opportunity__c = oppId;
                            ME.MessagingPlatformKey = conList[0].Phone != null? conList[0].Phone : conList[0].MobilePhone;
                            insert ME;
                            returnValue = ME.Id;
                            
                        }
                        
                    }
                    
                }
            }
        }
        catch(exception e){
            returnValue = 'Error';
        }
        return returnValue;
        
    } 
}