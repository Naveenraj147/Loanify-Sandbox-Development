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
        helper.handlePendingRequestsInGarage(newMap); 
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
        
        helper.handlePendingRequestsInGarage1(oldMap, newMap);
        
        System.debug('Insert Contact On After Method');
        List<Contact> conList = [select Id,Name,MobilePhone,Phone,RecordTypeId,RecordType.DeveloperName from Contact where Id in: newList];
        System.debug('ConList Size::'+ conList.Size());
        List<String> serializedDataList = new List<String> ();
        
        for(Contact each : conList){
            if ( each.RecordType.DeveloperName == 'Bank_Service_Rep' || each.RecordType.DeveloperName == 'Auto_Dealer_Pro'){
                String serializedData =AzureIntegrationService.serializeWithNulls(newMap.get(each.Id)); 
                serializedDataList.add(serializedData);
            }else if (each.RecordType.DeveloperName == 'Auto_Shopper' && oldMap.get(each.Id).MobilePhone != each.MobilePhone || oldMap.get(each.Id).Phone != each.Phone){
                String serializedData = serializePhoneField(each.MobilePhone, each.Phone, each.Id); 
                serializedDataList.add(serializedData);
            }
            
        }
        if(!serializedDataList.isEmpty()){
            System.debug('serializedDataList Size::'+ serializedDataList.Size());
            AzureIntegrationService.updateDataInAzure(serializedDataList);
        }
    }
    
    private String serializePhoneField(String MobilePhone, string Phone, String Id) {
        Map<String, Object> phoneMap = new Map<String, Object>();
        phoneMap.put('Id', Id);
        phoneMap.put('MobilePhone', MobilePhone);
        phonemap.put('Phone', Phone);
        
        return JSON.serialize(phoneMap);
    }
    
    
    public void onBeforeDelete(){
        
    }
    
    public void onAfterDelete(){
        
    }
    
}