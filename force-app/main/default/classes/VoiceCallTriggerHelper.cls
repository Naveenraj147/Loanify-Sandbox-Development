public class VoiceCallTriggerHelper {
    
    public void deleteRelatedTask(map<Id, VoiceCall> oldMap, map<Id, VoiceCall> newMap){
        Set<Id> oppIds = new Set<Id>();
        Set<Id> voiceCallIds = new Set<Id>();
        List<String> oppVCLink = new List<String>();
        List<Task> tasksToDelete = new List<Task>();
        for(VoiceCall each : newMap.values()){
            if(each.Opportunity__c != oldMap.get(each.Id).Opportunity__c && oldMap.get(each.Id).Opportunity__c != null ){
                oppIds.add(oldMap.get(each.Id).Opportunity__c);
                voiceCallIds.add(each.Id);
                oppVCLink.add(oldMap.get(each.Id).Opportunity__c+ ':' + each.Id);
            }
        }
        
        if(oppIds.size() > 0){
            List<Task> taskList = [ SELECT  Id, WhoId, TaskSubtype, Voice_Call__c, WhatId  from Task where WhatId =: oppIds AND Voice_Call__c =: voiceCallIds AND TaskSubtype = 'Call'];
            for(Task each : taskList){
                if(oppVCLink.contains(each.WhatId + ':' + each.Voice_Call__c) ){
                     tasksToDelete.add(each);
                }
               
            }
            if(tasksToDelete.size() > 0){
                delete tasksToDelete;
            }
        }
        
        
    }
}