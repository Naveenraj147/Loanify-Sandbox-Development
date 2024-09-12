@isTest
public class VoiceCallTriggerHelperTest {
	@isTest    
    static void doTest(){
        
        String recTypeIdContact = [SELECT Id,Name FROM RecordType WHERE Name = 'Auto Shopper' AND SObjectType = 'Contact' ORDER BY Name asc LIMIT 1].Id;
        
        contact con = new contact();
        con.LastName = 'test opp';
        con.Email = 'Test99@xyz.com';
        con.RecordTypeId = recTypeIdContact;
        insert con;
        
        Opportunity opp = new Opportunity();
        opp.Auto_Shopper__c = con.Id;
        opp.Name = 'test opp';
        opp.StageName = 'Prospecting';
        opp.CloseDate = system.today();
        
        insert opp;
        
        VoiceCall VC1 = new VoiceCall();
        VC1.CallCenterId = [SELECT Id, Name FROM CallCenter Limit 1].Id;
        VC1.VendorType = 'ContactCenter'; 
        VC1.CallType = 'Inbound';
        VC1.FromPhoneNumber = '+19999999999';
        VC1.ToPhoneNumber = '+19999999999';
        VC1.CallStartDateTime = System.now().addMinutes( - 3 );
        VC1.CallEndDateTime = System.now();
        VC1.CallDisposition = 'completed';
        //VC1.RelatedRecordId = con.Id;
        VC1.Opportunity__c = opp.Id;
        insert VC1;
        
        Task newTask = new Task();
        newTask.WhatId = opp.Id;
        newTask.TaskSubtype = 'Call';
        newTask.Voice_Call__c = VC1.Id;
        insert newTask;
        
        VC1.Opportunity__c = null;
        update VC1;
    }
}