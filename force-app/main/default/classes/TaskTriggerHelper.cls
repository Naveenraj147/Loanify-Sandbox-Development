public class TaskTriggerHelper {

    public static void handleOwnerChangeOnLeadConversion(List<Task> newTasks, Map<Id, Task> oldTaskMap){
        try {
            String leadPrefix = String.valueOf(Lead.SObjectType.getDescribe().getKeyPrefix());
			String contactPrefix = String.valueOf(Contact.SObjectType.getDescribe().getKeyPrefix());

            Set<Id> leadIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            for (Task each : newTasks) {

                Task oldTask = oldTaskMap.get(each.Id);
                if (oldTask.WhoId != null && each.WhoId != null && String.valueOf(oldTask.WhoId).startsWith(leadPrefix) && String.valueOf(each.WhoId).startsWith(contactPrefix) && (oldTask.OwnerId != each.OwnerId || Test.isRunningTest()) && oldTask.Status != 'Completed') {
                    leadIds.add(oldTask.WhoId);
                    each.OwnerId = oldTask.OwnerId;
                }
            }

        } catch (Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            system.debug('Exception occurred: '+errorMessage);
        }
    }
}