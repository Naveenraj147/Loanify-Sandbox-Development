public class ChatPortalController {
    public String newMessage { get; set; }
    public String selectedSender { get; set; }
    public List<SelectOption> senderOptions { get; set; }
    public Boolean showComponent { get; set; }
	public String recordId{ get; set; }
    public String opportunityId;
    public String portalType{ get; set; }
    Opportunity opportunity = new Opportunity();
    public List<MessageWrapper> messageList { get; set; }
    public String memberEmail;
    public String memberName;
    public Map<String,String> nameEmailMap = new Map<String,String>();
    public Map<String,String> emailNameMap = new Map<String,String>();
    public String dealerId;
    public String vehicleName{ get; set; }
    public String garageId;
    public Integer fastpassDealerId;
    public String vehicleVin{ get; set; }
    public String stockNumber{ get; set; }
    public Boolean showButtons { get; set; }
    public String sObjName;
    public Integer dealerMsgCount = 0;
    public Integer memberMsgCount = 0;

    public ChatPortalController() {
        newMessage='';
        opportunityId='';
        portalType='';

        // Decrypt and assign the parameters from the URL
        Map<String, String> params = ApexPages.currentPage().getParameters();
        recordId = params.get('id'); 
        System.debug('RecordId:'+recordId);
        String encryptedParams = params.get('q');
        Date linkGeneratedDate;
       
        if(encryptedParams != null){
            String decryptedParams = CryptoUtility.decrypt(encryptedParams);
            Map<string,Object> paramMapping=(Map<string,Object> )JSON.deserializeUntyped(decryptedParams);
            opportunityId = (String)paramMapping.get('opportunityId');
            String dateString = (String)paramMapping.get('linkSharedDate');
            linkGeneratedDate = Date.valueOf(dateString);
            portalType = (String)paramMapping.get('portalType');
            if(portalType == 'Dealer' || portalType == 'Carbots'){
                dealerId = (String)paramMapping.get('dealerId');
                vehicleVin = (String)paramMapping.get('vehicleVin');
                vehicleName = (String)paramMapping.get('vehicleName');
                fastpassDealerId = Integer.valueOf(paramMapping.get('fastpassVehicleId'));
                garageId = (String)paramMapping.get('garageId');
                stockNumber = (String)paramMapping.get('stockNumber');
            }           
            System.debug('convertedDate--> '+ linkGeneratedDate.daysBetween(System.Today()));
            showComponent = true;
            
        }
        if(recordId != null){
            sObjName = ((Id)recordId).getSObjectType().getDescribe().getName();
            showComponent = true;
            if(sObjName == 'Opportunity'){
                opportunityId = recordId;
                portalType = 'MSR';
            }
            if(sObjName == 'Garage__c'){
                garageId = recordId;
                portalType = 'Dealer';
                List<Garage__c> Garage = [SELECT Id, Opportunity__c FROM Garage__c WHERE Id =:garageId LIMIT 1 ]; 
                opportunityId = Garage.size() > 0? Garage[0].Opportunity__c : null;

            }
        }
        if(linkGeneratedDate != null && recordId == null && linkGeneratedDate.daysBetween(System.Today())> 7 ){
            showComponent = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Link Expired'));
        }
        
        opportunity = [SELECT Id, Name, Auto_Shopper__r.Name, Auto_Shopper__r.Email, Branch__c, Bank_Service_Rep_Name_MSR__c FROM Opportunity where Id=:opportunityId];
        memberName =  opportunity != null? opportunity.Auto_Shopper__r.Name:'Member';
        memberEmail = opportunity != null? opportunity.Auto_Shopper__r.Email:null;
        loadsenderOptions();
        loadConversations();
    }

    private void loadConversations() {
        messageList = new List<MessageWrapper>();
        Integer count = 0;
        if (portalType == 'MSR') {
            for(Portal_Message__c each : [SELECT Message__c,  Sender_Email__c, CreatedDate, Is_Member_Message__c FROM Portal_Message__c WHERE Opportunity__c = :opportunity.Id  AND Garage__c = null AND Portal_Type__c = 'MSR' AND Is_Pending__c = false  order by CreatedDate]){ //
                MessageWrapper wrapper = new MessageWrapper();
                wrapper.message = each.Message__c;
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.Is_Member_Message__c? memberEmail: each.Sender_Email__c;
                wrapper.styleClass = each.Is_Member_Message__c? 'member-message': 'non-member-message';
                wrapper.name = each.Is_Member_Message__c? memberName : emailNameMap.get(wrapper.fromAddress);
                messageList.add(wrapper);
            }
        } 
        if (portalType == 'Dealer' || portalType == 'Carbots' ) {
            for(Portal_Message__c each : [SELECT Message__c,  Sender_Email__c, CreatedDate, Is_Member_Message__c FROM Portal_Message__c WHERE Opportunity__c = :opportunity.Id  AND Garage__c = :garageId AND Is_Pending__c = false AND (Portal_Type__c = 'Dealer'OR Portal_Type__c = 'Carbots')  order by CreatedDate]){
                MessageWrapper wrapper = new MessageWrapper();
                wrapper.message = each.Message__c;
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.Is_Member_Message__c? memberEmail: each.Sender_Email__c;
                wrapper.styleClass = each.Is_Member_Message__c? 'member-message': 'non-member-message';
                wrapper.name = each.Is_Member_Message__c? memberName : emailNameMap.get(wrapper.fromAddress); 
                messageList.add(wrapper);
                count++;
                if(!each.Is_Member_Message__c){
                    dealerMsgCount++;
                }
                else{
                    memberMsgCount++;
                }
            }
            if(count == 1){
                showButtons = true;
            }
            else{
                showButtons = false;
            }
        }
    }
    private void loadsenderOptions() {
       
        senderOptions = new List<SelectOption>();
        if(recordId != null){
            senderOptions.add(new SelectOption( 'Agent', UserInfo.getFirstName() ));
            nameEmailMap.put(UserInfo.getUserEmail(), UserInfo.getFirstName() );
            emailNameMap.put(UserInfo.getUserEmail(), UserInfo.getFirstName() );
            if(sObjName == 'Opportunity'){
                List<Contact> msrContacts = [SELECT Id, Name, Email FROM Contact WHERE AccountId =: opportunity.Branch__c];

                for(Contact each : msrContacts) {
                    nameEmailMap.put(each.Id, each.Email);
                    nameEmailMap.put(each.Email, each.Name);
                    emailNameMap.put(each.Email, each.Name);
                }
            }
            
        }
        else if (portalType == 'MSR' ) {
            List<Contact> msrContacts = [SELECT Id, Name, Email FROM Contact WHERE AccountId =: opportunity.Branch__c];

            for(Contact each : msrContacts) {
                senderOptions.add(new SelectOption(each.Id, each.Name));
                nameEmailMap.put(each.Id, each.Email);
                nameEmailMap.put(each.Email, each.Name);
                emailNameMap.put(each.Email, each.Name);
            }
        }
        else if (portalType == 'Dealer' || portalType == 'Carbots' ) {
            System.debug('Inside Dealer Manager');
            Account dealerAccount;
            Lead dealerLead;
            List<Account> dealerList = [SELECT Id, Name,Manager_Email__c, Manager_Name__c FROM Account WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
            if(dealerList.size() > 0 ){
                System.debug('Inside dealerList');
                dealerAccount = dealerList[0];
                if (dealerAccount.Manager_Name__c !=null && dealerAccount.Manager_Email__c != null) {
                    senderOptions.add(new SelectOption(dealerAccount.Manager_Email__c, dealerAccount.Manager_Name__c));
                    nameEmailMap.put(dealerAccount.Id,dealerAccount.Manager_Email__c);
                    nameEmailMap.put(dealerAccount.Manager_Email__c,dealerAccount.Manager_Name__c);
                    emailNameMap.put(dealerAccount.Manager_Email__c,dealerAccount.Manager_Name__c);
                }
                List<Contact> dealerProList = [SELECT Id, Name, Email FROM Contact WHERE AccountId =: dealerAccount.Id];
                System.debug('Inside dealerList');
                if(dealerProList.size() > 0){
                    for(Contact each : dealerProList){
                        if(each.Name != null && each.Email != null){
                            senderOptions.add(new SelectOption( each.Email, each.Name));
                            nameEmailMap.put(each.Id, each.Name);
                            nameEmailMap.put(each.Name, each.Email);
                            emailNameMap.put(each.Email, each.Name);
                        }
                    }
                } 
            }
            else{
                dealerLead = [SELECT Id, Company, Manager_Email__c, Manager_Name__c, Dealer_Pro_1_Email__c, Dealer_Pro_2_Email__c, Dealer_Pro_3_Email__c, Dealer_Pro_1_Name__c, Dealer_Pro_2_Name__c, Dealer_Pro_3_Name__c FROM Lead WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
                if( dealerLead != null){
                    System.debug('Inside Dealer Lead Manager');
                    if(dealerLead.Manager_Email__c != null && dealerLead.Manager_Name__c != null ){
                        nameEmailMap.put(dealerLead.Manager_Name__c, dealerLead.Manager_Email__c);
                        senderOptions.add(new SelectOption(dealerLead.Manager_Email__c, dealerLead.Manager_Name__c));
                    } 
                    if(dealerLead.Dealer_Pro_1_Email__c != null && dealerLead.Dealer_Pro_1_Name__c != null ){
                        nameEmailMap.put(dealerLead.Dealer_Pro_1_Name__c, dealerLead.Dealer_Pro_1_Email__c);
                        senderOptions.add(new SelectOption(dealerLead.Dealer_Pro_1_Email__c, dealerLead.Dealer_Pro_1_Name__c));
                    } 
                    if(dealerLead.Dealer_Pro_2_Email__c != null && dealerLead.Dealer_Pro_2_Name__c != null ){
                        nameEmailMap.put(dealerLead.Dealer_Pro_2_Name__c, dealerLead.Dealer_Pro_2_Email__c);
                        senderOptions.add(new SelectOption(dealerLead.Dealer_Pro_2_Email__c, dealerLead.Dealer_Pro_2_Name__c));
                    } 
                    if(dealerLead.Dealer_Pro_3_Email__c != null && dealerLead.Dealer_Pro_3_Name__c != null ){
                        nameEmailMap.put(dealerLead.Dealer_Pro_3_Name__c, dealerLead.Dealer_Pro_3_Email__c);
                        senderOptions.add(new SelectOption(dealerLead.Dealer_Pro_3_Email__c, dealerLead.Dealer_Pro_3_Name__c));
                    }
                    System.debug('Inside Dealer Lead Manager'); 
                }
            }
        }
        List<User> userList = [SELECT Name, Email FROM User];
        if(userList.size() > 0){
            for(User each : userList){
                emailNameMap.put(each.email, each.Name);
            }
        }
    }
    public void sendMessage() {
        System.debug('selectedSender :: '+ selectedSender);
        if (String.isNotBlank(newMessage)) {
            Portal_Message__c newPM = new Portal_Message__c();
            newPM.Message__c = newMessage;
            newPM.Opportunity__c = opportunity.Id;
            if(selectedSender == 'Agent'){
                newPM.Sender_Email__c = UserInfo.getUserEmail();
            }
            else{
                newPM.Sender_Email__c = selectedSender;
            }

            if(portalType == 'MSR'){
                newPM.Portal_Type__c = 'MSR';
            }
            else if(portalType == 'Dealer' || portalType == 'Carbots'){
                String recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Shopper_Carbots').getRecordTypeId();
                newPM.Portal_Type__c = opportunity.Auto_Shopper__r.RecordTypeId == recordTypeId? 'Carbots' : 'Dealer';
                newPM.Garage__c = garageId;
                //newPM.Sender_Email__c = nameEmailMap.get(selectedSender);
                String chatLink;
                if(garageId != null){
                List<Garage__c> Garage = [SELECT Id, Name, VIN__c, Chat_Id__c, Opportunity__c,Dealer__c, Dealer__r.FastPass_Dealer_Id__c, FastPass_Vehicle_Id__c, Lead_Dealer__c, Lead_Dealer__r.FastPass_Dealer_Id__c FROM Garage__c WHERE Id =:garageId ]; 
                    if(Garage.size() > 0){
                        chatLink = Garage[0].Chat_Id__c;
                    }
                    Garage__c garageUpdate = new Garage__c();
                    garageUpdate.Id = garageId;
                    if(memberMsgCount == 1 &&  dealerMsgCount >= 1){
                        garageUpdate.Send_Generic_Notification__c = true;
                    }
                    garageUpdate.Last_Dealer_Response_Test_Drive__c = System.now();
                    Update garageUpdate;
                    if(chatLink != null){
                        callFastPassWebhook(chatLink);
                    }
                    if((memberMsgCount == 1 && (dealerMsgCount == null || dealerMsgCount == 0) ) || memberMsgCount > 1){
                        System.debug('Before Send SMS ');
                        SendSMS(garageUpdate.Id);
                        
                    }
                }
            }
            insert newPM;
        }
    }

    @future(callout=true)
    public static void callFastPassWebhook(String chatLink){
        FastPass_App_Webhook__mdt baseUrl = FastPass_App_Webhook__mdt.getInstance('Base_URL');
        FastPass_App_Webhook__mdt token = FastPass_App_Webhook__mdt.getInstance('Webhook_Token');
        String chatId = chatLink != null? chatLink.substring(chatLink.lastIndexOf('/')+1) : null;
        System.debug('chatId :: ' + chatId);
        if(baseUrl != null && token != null && chatId != null){
                
            String endpointUrl = baseUrl.value__c+'/webhook/conversation-webhook';
            // Prepare the JSON payload 
            String jsonPayload = '{"chat_id": "'+ chatId +'"}';

            // Initialize an HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json'); // Set content type
            request.setHeader('x-webhook-token',token.value__c);
            request.setBody(jsonPayload);

            // Initialize an HTTP instance and send the request
            Http http = new Http();
            try {
                HttpResponse response = http.send(request);
                if (response.getStatusCode() == 200) {
                    System.debug('FastPass Webhook called successfully. Response: ' + response.getBody());
                } else {
                    System.debug('Failed to call FastPass webhook. Status: ' + response.getStatusCode() + ' Response: ' + response.getBody());
                }
            } catch (Exception e) {
                System.debug('Error occurred while calling FastPass webhook: ' + e.getMessage());
            }
            
        }
    }

    @future(callout=true)
    public static void sendSMS(String recordId){
        System.debug('Inside Send SMS');
        If(recordId != null){
        try {
            // Prepare the HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            Salesforce_API__mdt metaSFAPI = Salesforce_API__mdt.getInstance('Salesforce_API');
            String baseUrl = metaSFAPI != null? metaSFAPI.Base_Url__c: null;
            String accessToken = metaSFAPI != null? metaSFAPI.Access_Token__c: null;
            if(metaSFAPI != null && baseUrl != null && accessToken != null){
              //  String flowUrl = baseUrl+ '/services/data/v53.0/actions/custom/flow/Send_SMS_From_Flow';
              String flowUrl = baseUrl+ '/services/data/v57.0/sobjects/Garage__c/'+recordId;
            request.setEndpoint(flowUrl);
            request.setMethod('PATCH');
            
            // Set headers if necessary
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + accessToken);  // If authentication is required
            
            
            
            List<tdc_tsw__Message_Template__c> messageTemplate = [SELECT Id FROM tdc_tsw__Message_Template__c Where Name = 'Notification to the Member' Limit 1];
            // Convert to JSON string
            If(messageTemplate.size() > 0){
                String jsonBody = '{ '+
                '"inputs" : [ {'+
                '   "paramInput" : "'+ recordId +',Member_Mobile__c,'+messageTemplate[0].Id+'"'+
                '   } ] '+
                '}';

                String data = '{"Send_SMS_Notification__c": true}';
                    

                request.setBody(data);
                
                // Send the HTTP request
                HttpResponse response = http.send(request);
                
                // Process the response
                if (response.getStatusCode() == 200 || response.getStatusCode() == 204) {
                    System.debug('Callout successful. Response: ' + response.getBody());
                } 
                else {
                    System.debug('Callout failed with status: ' + response.getStatus());
                    AzureIntegrationService.sendErrorEmail('Send SMS From Public Site. Status Code: '+response.getStatusCode(), response.getBody());
                }
            }
            else{
                System.debug('Send SMS From Public Site. SMS Template Not Found');
                AzureIntegrationService.sendErrorEmail('Send SMS From Public Site.', 'SMS Template Not Found');

            }
            
            }
            else{
                AzureIntegrationService.sendErrorEmail('Send SMS From Public Site.', 'Metadata values are empty');
            }
           // String externalServiceUrl = 'https://app-computing-7882--dev.sandbox.my.salesforce.com' + '/services/data/v57.0/sobjects/Garage__c/a1kVA000008tbXAYAY'; 
            
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
            AzureIntegrationService.sendErrorEmail('Send SMS From Public Site.', e.getMessage());
        }
    }
    }



    public class MessageWrapper {
        public string message {get;set;}
        public DateTime createdDate {get;set;}
        public string fromAddress {get;set;}
        public string name {get;set;}
        public string styleClass {get;set;}
        
    
    }

}