public class LeadTriggerHandler {
    
    // Before Insert Handler
    public static void beforeInsert(List<Lead> newLeads) {
      
    }
    
    // Before Update Handler
    public static void beforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        System.Debug('Inside beforeUpdate ');
        System.Debug('Lead ' + newLeads);
        for(Lead each : newLeads){
            Lead oldLead = oldLeadMap.get(each.Id);
            System.Debug('Inside For Loop ');
            System.Debug('Condition ::: '+(each.IsConverted == true )+ (each.IsConverted != oldLead.IsConverted));
            System.Debug('old Converted ::: '+ oldLead.IsConverted);
            System.Debug('New Converted ::: '+ each.IsConverted);

            if(each.IsConverted == true && each.IsConverted != oldLead.IsConverted){
                if(each.Email == null){
                    System.Debug('Inside Email Assignment');
                    each.Email = 'invalid@mail.com';
                }
            }
        }
    }

    // After Insert Handler
    public static void afterInsert(List<Lead> newLeads) {
        LeadTriggerHelper.mapLeadsToGarage(newLeads);
    }

    // After Update Handler
    public static void afterUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        System.Debug('Inside afterUpdate');
         LeadTriggerHelper.processEmailUpdatedLeads(newLeads, oldLeadMap);
    }
}