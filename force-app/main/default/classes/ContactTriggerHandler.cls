public class ContactTriggerHandler {
    
    private boolean m_isExecuting = false;
    private integer batchSize = 0; 
    private List<Contact> newList;
    private List<Contact> oldList;
    private Map<Id, Contact> newMap;
    private Map<Id, Contact> oldMap;
    
    public ContactTriggerHandler (Boolean isExecuting, Integer size,  List<Contact> oldList, Map<Id, Contact> newMap, List<Contact> newList, Map<Id,Contact> oldMap){
        
        this.m_isExecuting = isExecuting;
        this.batchSize = size;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.oldList = oldList;
    }
    
    ContactTriggerHelper helper = new ContactTriggerHelper();
    public void onBeforeInsert(){
       
        for (Contact con : newList) {
            
            if (con.Phone != null ) {
                con.Phone = ContactTriggerHelper.formatPhoneNumber(con.Phone, '+1');
            }
            if (con.MobilePhone != null) {
                con.MobilePhone = ContactTriggerHelper.formatPhoneNumber(con.MobilePhone, '+1');
            }
        }      
    }
    
    public void onAfterInsert(){
        helper.processPortalMessages(newList);
        helper.syncDataInAzure(newMap, null);
    }
    
    public void onBeforeUpdate(){
        for (Contact con : newList) {
            Contact oldCon = oldMap.get(con.Id);
            if (con.Phone != null && con.Phone != oldCon.Phone) {
                con.Phone = ContactTriggerHelper.formatPhoneNumber(con.Phone, '+1');
            }
            if (con.MobilePhone != null && con.MobilePhone != oldCon.MobilePhone) {
                con.MobilePhone = ContactTriggerHelper.formatPhoneNumber(con.MobilePhone, '+1');
            }
        }
        
    }
    
    public void onAfterUpdate(){
        helper.processPMforContactUpdate(newList, oldMap);
        helper.syncDataInAzure(newMap, oldMap);
    }
    
    
    
    
    public void onBeforeDelete(){
        
    }
    
    public void onAfterDelete(){
        
    }
    
}