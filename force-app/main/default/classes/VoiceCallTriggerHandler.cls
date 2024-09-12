public class VoiceCallTriggerHandler {
    VoiceCallTriggerHelper helper = new VoiceCallTriggerHelper();

    public void onBeforeUpdate(map<Id, VoiceCall> oldMap, map<Id, VoiceCall> newMap){
         helper.deleteRelatedTask(oldMap, newMap );
    }
    
  
}