public without sharing class UnsubscribeComponentController {

    @AuraEnabled
    public static string updatePreferences(String data){
        try {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(data);
            if(dataMap.containsKey('objectName') && dataMap.containsKey('recordId') && dataMap.containsKey('objectName') && dataMap.containsKey('SMS') && dataMap.containsKey('Email') ){
                string recordId = (string) dataMap.get('recordId');
                string objectName = (string) dataMap.get('objectName');
                if(objectName == 'Opportunity'){
                   List<Opportunity> oppList = [SELECT Id, Dealer_SMS_Notifications__c, Dealer_Email_Notifications__c, Credit_Union_Email_Notifications__c, Credit_Union_SMS_Notifications__c, FastPass_Team_Email_Support__c, FastPass_Team_SMS_Support__c FROM Opportunity WHERE Id =:recordId Limit 1 ];
                    if(oppList.size() > 0){
                        Map<String, Object> smsMap = (Map<String, Object>) dataMap.get('SMS');
                        Map<String, Object> emailMap = (Map<String, Object>) dataMap.get('Email');
                        Opportunity opp = oppList[0];
                        opp.Dealer_SMS_Notifications__c = (Boolean)(smsMap.containsKey('dn')? smsMap.get('dn'):null);
                        opp.Dealer_Email_Notifications__c = (Boolean)(emailMap.containsKey('dn')? emailMap.get('dn'):null);
                        opp.Credit_Union_Email_Notifications__c = (Boolean)(emailMap.containsKey('cun')? emailMap.get('cun'):null);
                        opp.Credit_Union_SMS_Notifications__c = (Boolean)(smsMap.containsKey('cun')? smsMap.get('cun'):null);
                        opp.FastPass_Team_Email_Support__c = (Boolean)(emailMap.containsKey('fpn')? emailMap.get('fpn'):null);
                        opp.FastPass_Team_SMS_Support__c = (Boolean)(smsMap.containsKey('fpn')? smsMap.get('fpn'):null);
                        update opp;
                    }
                }
                else if(objectName == 'Contact'){
                    List<Contact> conList = [SELECT Id, Member_SMS_Notifications__c, Member_Email_Notifications__c, FastPass_Team_Email_Support__c, FastPass_Team_SMS_Support__c FROM Contact WHERE Id =:recordId Limit 1 ];
                    if(conList.size() > 0){
                        Map<String, Object> smsMap = (Map<String, Object>) dataMap.get('SMS');
                        Map<String, Object> emailMap = (Map<String, Object>) dataMap.get('Email');
                        Contact con = conList[0];
                        con.Member_SMS_Notifications__c = (Boolean)(smsMap.containsKey('mn')? smsMap.get('mn'):null);
                        con.Member_Email_Notifications__c = (Boolean)(emailMap.containsKey('mn')? emailMap.get('mn'):null);
                        con.FastPass_Team_Email_Support__c = (Boolean)(emailMap.containsKey('fpn')? emailMap.get('fpn'):null);
                        con.FastPass_Team_SMS_Support__c = (Boolean)(smsMap.containsKey('fpn')? smsMap.get('fpn'):null);
                        update con;
                    }
                }
            }
            return 'Success';
        
        } catch (Exception e) {
           /// throw new AuraHandledException(e.getMessage());
            return 'Error';
        }
       
    }
    @AuraEnabled
    public static string getUnsubscribeDetails(String data){
        Map<String,values> dataValuesMap = new Map<String,values>();
        try {
            system.debug(Data);
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(data);
            string recordId = (string) dataMap.get('recordId');
            string objectName = (string) dataMap.get('objectName');
            if(objectName == 'Opportunity'){
                List<Opportunity> OpportunityList = [SELECT Id, Name, Dealer_SMS_Notifications__c, Dealer_Email_Notifications__c, Credit_Union_Email_Notifications__c, Credit_Union_SMS_Notifications__c, FastPass_Team_Email_Support__c, FastPass_Team_SMS_Support__c FROM Opportunity WHERE Id =: recordId];
                if(OpportunityList.size() > 0){
                    Opportunity opp = OpportunityList[0];
                    values sms = new values();
                    sms.cun = opp.Credit_Union_SMS_Notifications__c;
                    sms.dn = opp.Dealer_SMS_Notifications__c;
                    sms.fpn = opp.FastPass_Team_SMS_Support__c;
                    sms.all = sms.cun == true && sms.dn == true && sms.fpn == true? true:false;
                    sms.mn = false;
                    dataValuesMap.put('SMS', sms);
                    values email = new values();
                    email.cun = opp.Credit_Union_Email_Notifications__c;
                    email.dn = opp.Dealer_Email_Notifications__c;
                    email.fpn = opp.FastPass_Team_Email_Support__c;
                    email.all = email.cun == true && email.dn == true && email.fpn == true? true:false;
                    email.mn = false;
                    dataValuesMap.put('Email', email);
                }
            }
            else{
                List<Contact> contactList = [SELECT Id, Name, Member_SMS_Notifications__c, Member_Email_Notifications__c, FastPass_Team_Email_Support__c, FastPass_Team_SMS_Support__c FROM Contact WHERE Id =: recordId];
                if(contactList.size() > 0){
                    Contact con = contactList[0];
                    values sms = new values();
                    sms.cun = false;
                    sms.dn = false;
                    sms.fpn = con.FastPass_Team_SMS_Support__c;
                    sms.mn = con.Member_SMS_Notifications__c;
                    sms.all = sms.fpn == true && sms.mn == true? true:false;
                    dataValuesMap.put('SMS', sms);
                    values email = new values();
                    email.cun = false;
                    email.dn = false;
                    email.fpn = con.FastPass_Team_Email_Support__c;
                    email.mn = con.Member_Email_Notifications__c;
                    email.all = email.fpn == true && email.mn == true? true:false;
                    dataValuesMap.put('Email', email);
                }
            }

        } catch (exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(dataValuesMap);
    }
    @AuraEnabled
    public static List<Contact> getContactDetails(String accountId){
        List<Contact> contactList;
        try {
            contactList = [SELECT Id, Name, Email FROM Contact WHERE AccountId =: accountId];

        } catch (exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return contactList;
    }

    public class values{
        public Boolean all { get; set; }
        public Boolean dn { get; set; }
        public Boolean cun { get; set; }
        public Boolean fpn { get; set; }
        public Boolean mn { get; set; }
    }

}