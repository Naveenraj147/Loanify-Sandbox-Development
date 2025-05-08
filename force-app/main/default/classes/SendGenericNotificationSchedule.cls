public class SendGenericNotificationSchedule implements Schedulable {

    public void execute(SchedulableContext ctx) {
        sendGenericEmailsAndSMS();
    }
    public static void sendGenericEmailsAndSMS(){
        List<Garage__c> garages = [SELECT Id, Opportunity__r.Auto_Shopper__c, Opportunity__r.Auto_Shopper__r.Email, Send_Generic_Notification__c, Opportunity__r.Dealer_Email_Notifications__c, Opportunity__r.Dealer_SMS_Notifications__c  FROM Garage__c WHERE Active__c != false AND Send_Generic_Notification__c =  true];
        if(garages.size() > 0){
            List<EmailTemplate> templates = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = 'Generic_notification_for_dealer_response_to_member' Limit 1];
            List<tdc_tsw__Message_Template__c> messageTemplate = [SELECT Id FROM tdc_tsw__Message_Template__c Where Name = 'Generic notification for dealer response to member' Limit 1];

            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Set<String> contactIds = new Set<String>();
            if(templates.size() > 0){
                Id templateId = templates[0].Id;
                for(Garage__c each: garages){
                    if(!contactIds.contains(each.Opportunity__r.Auto_Shopper__c) && each.Opportunity__r.Auto_Shopper__r.Email != null && each.Opportunity__r.Dealer_Email_Notifications__c){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setTargetObjectId(each.Opportunity__r.Auto_Shopper__c);
                        email.setTemplateId(templateId);
                        email.setSaveAsActivity(true); 
                        emailList.add(email);
                        
                    }
                    if(each.Opportunity__r.Dealer_SMS_Notifications__c == false){
                        contactIds.add(each.Opportunity__r.Auto_Shopper__c);
                    }
                    each.Send_Generic_Notification__c = false;
                }
            
                if(emailList.size() > 0){
                    Messaging.sendEmail(emailList);
                }
                if(contactIds.size() > 0 && messageTemplate.size() > 0){
                    String smsTemplateId = messageTemplate[0].Id;
                    for(String eachConId : contactIds){
                        tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId('Member_Mobile__c', smsTemplateId ,eachConId);
                    }
                }
                update garages;
            }
        }
    }
}