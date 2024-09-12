public class AccountTriggerHandler {
    
    private boolean m_isExecuting = false;
    private integer batchSize = 0; 
    private List<Account> newList;
    private List<Account> oldList;
    private Map<Id, Account> newMap;
    private Map<Id, Account> oldMap;
    
    public AccountTriggerHandler(Boolean isExecuting, Integer size,  List<Account> oldList, Map<Id, Account> newMap, List<Account> newList, Map<Id,Account> oldMap){
        this.m_isExecuting = isExecuting;
        this.batchSize = size;
        this.newList = newList;
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.oldList = oldList;
    } 
    
    AccountTriggerHelper  helper = new AccountTriggerHelper ();
    public void onBeforeInsert(){
        
        for (Account acc : newList) {
            if (acc.Phone != null) {
                acc.Phone = ContactTriggerHelper.formatPhoneNumber(acc.Phone, '+1');
            }
            if (acc.Manager_Cell_Phone__c != null) {
                acc.Manager_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.Manager_Cell_Phone__c, '+1');
            }
            if (acc.Lead_MSR_Cell_Phone__c != null) {
                acc.Lead_MSR_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.Lead_MSR_Cell_Phone__c, '+1');
            }
            if (acc.Project_Manager_Cell_Phone__c != null) {
                acc.Project_Manager_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.Project_Manager_Cell_Phone__c, '+1');
            }
            if (acc.F_I_Manager_Cell_Phone__c != null) {
                acc.F_I_Manager_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.F_I_Manager_Cell_Phone__c, '+1');
            }
        }
    }
    
    
    public void onAfterInsert(){
        
    }
    
    public void onBeforeUpdate(){
        
        for (Account acc : newList) {
            Account oldAcc = oldMap.get(acc.Id);
            if (acc.Phone != null && acc.Phone != oldAcc.Phone) {
                acc.Phone = ContactTriggerHelper.formatPhoneNumber(acc.Phone, '+1');
            }
            if (acc.Manager_Cell_Phone__c != null && acc.Manager_Cell_Phone__c != oldAcc.Manager_Cell_Phone__c) {
                acc.Manager_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.Manager_Cell_Phone__c, '+1');
            }
            if (acc.Lead_MSR_Cell_Phone__c != null && acc.Lead_MSR_Cell_Phone__c != oldAcc.Lead_MSR_Cell_Phone__c) {
                acc.Lead_MSR_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.Lead_MSR_Cell_Phone__c, '+1');
            }
            if (acc.Project_Manager_Cell_Phone__c != null && acc.Project_Manager_Cell_Phone__c != oldAcc.Project_Manager_Cell_Phone__c) {
                acc.Project_Manager_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.Project_Manager_Cell_Phone__c, '+1');
            }
            if (acc.F_I_Manager_Cell_Phone__c != null && acc.F_I_Manager_Cell_Phone__c != oldAcc.F_I_Manager_Cell_Phone__c) {
                acc.F_I_Manager_Cell_Phone__c = ContactTriggerHelper.formatPhoneNumber(acc.F_I_Manager_Cell_Phone__c, '+1');
            }
        }
        
    }
    
    public void onAfterUpdate() {
        
        List<Account> accList = [select Id,Name,RecordTypeId,RecordType.DeveloperName,Market__c from Account where Id in: newList];
        List<String> serializedDataList = new List<String> ();
        for (Account each : accList) {
            if ( each.RecordType.DeveloperName == 'Auto_Dealer'|| each.RecordType.DeveloperName == 'Bank' ){
                String serializedData = AzureIntegrationService.serializeWithNulls(newMap.get(each.Id)); 
                serializedDataList.add(serializedData);
            }
        }
        if(!serializedDataList.isEmpty()){
            AzureIntegrationService.updateDataInAzure(serializedDataList);
        }
        
        helper.handlePendingRequestsInGarage(oldMap, newMap);
    }  
    
    public void onBeforeDelete(){
        
    }
    
    public void onAfterDelete(){
        
    }
    
}