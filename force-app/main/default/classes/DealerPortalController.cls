public class DealerPortalController {
    public String newMessage { get; set; }
    public static List<EmailMessage> conversations { get; set; }
    public List<String> tempConversations { get; set; }
    public List<EmailWrapper> wrapperList { get; set; }


    public String selectedDealer { get; set; }
    public List<SelectOption> dealerOptions { get; set; }
    public List<SelectOption> requestOptions { get; set; }
    public String selectedType { get; set; }
    public Boolean showComponent { get; set; }
    public Boolean showButtons { get; set; }
	public String RecordId{ get; set; }
    public String opportunityId;
    public String dealerId;
    public String vehicleVin{ get; set; }
    public String stockNumber{ get; set; }
    public String vehicleName{ get; set; }
    public String requestHeader{ get; set; }
    public String type{ get; set; }
    public String garageId;
    public String memberEmail;
    public String memberName;
    public Integer fastpassDealerId;
    private Date linkSharedDate;
    private Map<String,String> dealerNameEmailMap=new Map<String,String>();
    private Map<String,String> emailWithNameMap=new Map<String,String>();
    Opportunity opportunity=new Opportunity();
	
    public void handlePicklistChange(){
        loadConversations();
         System.debug('DealerPortalController Called Again:');
    }
    public DealerPortalController() {
        // ApexPages.currentPage().getParameters().get('id');
        
        newMessage='';
        conversations= new List<EmailMessage>();
        tempConversations = new List<String>();
        opportunityId='';
        dealerId='';
        vehicleVin='';
        stockNumber='';
        vehicleName='';
        garageId='';
        type='';
        fastpassDealerId = null;
        tempConversations.add('Hi this is from controller !!');
        System.debug('Hi');
        // Decrypt and assign the parameters from the URL
        Map<String, String> params = ApexPages.currentPage().getParameters();
        RecordId = params.get('id');
        System.debug('RecordId:'+RecordId);
        String encryptedParams = params.get('q');
        System.debug('q--> '+encryptedParams);
        Date convertedDate;
        if(encryptedParams != null){
            String decryptedParams = CryptoUtility.decrypt(encryptedParams);
            
            System.debug('decryptedParams:'+decryptedParams);
            Map<string,Object> paramMapping=(Map<string,Object> )JSON.deserializeUntyped(decryptedParams);
            System.debug('paramMapping:'+paramMapping);
            opportunityId = (String)paramMapping.get('opportunityId');
            dealerId = (String)paramMapping.get('dealerId');
            vehicleVin = (String)paramMapping.get('vehicleVin');
            vehicleName = (String)paramMapping.get('vehicleName');
            fastpassDealerId = Integer.valueOf(paramMapping.get('fastpassVehicleId'));
            type = (String)paramMapping.get('type');
            String dateString = (String)paramMapping.get('linkSharedDate');
            garageId = (String)paramMapping.get('garageId');
            System.debug('dataString--> '+dateString);
            convertedDate = Date.valueOf(dateString);
            System.debug('convertedDate--> '+ convertedDate.daysBetween(System.Today()));
            if(garageId != null){
                List<Garage__c> Garage = [SELECT Id, Name, VIN__c, Opportunity__c,Dealer__c, Dealer__r.FastPass_Dealer_Id__c, FastPass_Vehicle_Id__c, Lead_Dealer__c, Lead_Dealer__r.FastPass_Dealer_Id__c,Stock_Number__c FROM Garage__c WHERE Id =:garageId ]; 
                if(Garage.size() > 0){
                    stockNumber = Garage[0].Stock_Number__c;
                }
            }
        }
        if(RecordId != null){
            garageId = RecordId;
            List<Garage__c> Garage = [SELECT Id, Name, VIN__c, Opportunity__c,Dealer__c, Dealer__r.FastPass_Dealer_Id__c, FastPass_Vehicle_Id__c, Lead_Dealer__c, Lead_Dealer__r.FastPass_Dealer_Id__c,Stock_Number__c FROM Garage__c WHERE Id =:RecordId ]; 
            if(Garage.size() > 0){
                opportunityId = Garage[0].Opportunity__c;
                dealerId = Garage[0].Dealer__c != null? Garage[0].Dealer__r.FastPass_Dealer_Id__c: Garage[0].Lead_Dealer__c != null? Garage[0].Lead_Dealer__r.FastPass_Dealer_Id__c:null;
                vehicleVin = Garage[0].VIN__c;
                vehicleName = Garage[0].Name;
                stockNumber = Garage[0].Stock_Number__c;
                fastpassDealerId = Integer.valueOf((Garage[0].FastPass_Vehicle_Id__c));
                type = 'testDrive';
            }
            
        }
        
        showComponent = true;
        
        if(convertedDate != null && RecordId == null && convertedDate.daysBetween(System.Today())> 7 ){
            showComponent = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Link Expired'));
        }
        System.debug('fastpassDealerId'+fastpassDealerId);
        System.debug('opportunityId'+opportunityId);
        System.debug('dealerId'+dealerId);
        System.debug('vehicleVin'+vehicleVin);
        System.debug('type'+type);
        //System.debug('linkSharedDate'+linkSharedDate);
		List<Contact> dealerPro=new List<Contact>();
        Lead dealerLeadManager;
        Account dealerManager;
        opportunity = [SELECT Id, Name,Auto_Shopper__r.Name,Card_Number__c, Auto_Shopper__r.Email FROM Opportunity where Id=:opportunityId];
        List<Account> dealerManagerList = [SELECT Id, Name,Manager_Email__c FROM Account WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
         if(dealerManagerList.size() > 0){
            dealerManager = dealerManagerList[0];
         }
         else{
            dealerLeadManager = [SELECT Id, Company, Manager_Email__c, Manager_Name__c, Dealer_Pro_1_Email__c, Dealer_Pro_2_Email__c, Dealer_Pro_3_Email__c, Dealer_Pro_1_Name__c, Dealer_Pro_2_Name__c, Dealer_Pro_3_Name__c FROM Lead WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
        }
        if (dealerManager !=null) {
            dealerPro=[SELECT Id, AccountId, Name, Email, RecordType.DeveloperName from Contact Where AccountId =:dealerManager.Id AND RecordType.DeveloperName = 'Auto_Dealer_Pro' AND Active__c = true];
        }
        
        memberName =  opportunity != null? opportunity.Auto_Shopper__r.Name:'Member';
        memberEmail = opportunity != null? opportunity.Auto_Shopper__r.Email:null;
        List<User> userList = [SELECT Name, Email FROM User];
        if(userList.size() > 0){
            for(User each : userList){
                emailWithNameMap.put(each.email, each.Name);
            }
        }
       
        emailWithNameMap.put('support@cufastpass.com', memberName);
       // emailWithNameMap.put(UserInfo.getUserEmail(),UserInfo.getFirstName());
        if (!dealerPro.isEmpty()) {
            for(Contact each : dealerPro) {
                emailWithNameMap.put(each.Email, each.Name);
            }
        }
        else if(dealerManager == null && dealerLeadManager != null){
            if(dealerLeadManager.Manager_Email__c != null && dealerLeadManager.Manager_Name__c != null ){
                emailWithNameMap.put(dealerLeadManager.Manager_Email__c, dealerLeadManager.Manager_Name__c);
            } 
            if(dealerLeadManager.Dealer_Pro_1_Email__c != null && dealerLeadManager.Dealer_Pro_1_Name__c != null ){
                emailWithNameMap.put(dealerLeadManager.Dealer_Pro_1_Email__c, dealerLeadManager.Dealer_Pro_1_Name__c);
            } 
            if(dealerLeadManager.Dealer_Pro_2_Email__c != null && dealerLeadManager.Dealer_Pro_2_Name__c != null ){
                emailWithNameMap.put(dealerLeadManager.Dealer_Pro_2_Email__c, dealerLeadManager.Dealer_Pro_2_Name__c);
            } 
            if(dealerLeadManager.Dealer_Pro_3_Email__c != null && dealerLeadManager.Dealer_Pro_3_Name__c != null ){
                emailWithNameMap.put(dealerLeadManager.Dealer_Pro_3_Email__c, dealerLeadManager.Dealer_Pro_3_Name__c);
            } 
        }

        System.debug('dealers'+dealerManager);
        if (dealerManager!=null && dealerManager.Manager_Email__c != null) {
            	emailWithNameMap.put(dealerManager.Manager_Email__c,dealerManager.Name);
        }
        else if(dealerLeadManager != null && dealerLeadManager.Manager_Email__c != null){
            emailWithNameMap.put(dealerLeadManager.Manager_Email__c,dealerLeadManager.Manager_Name__c);
        }
        System.debug('emailWithNameMap'+emailWithNameMap);
        loadConversations();
       
        //load dealer
        if(RecordId != null){
            dealerOptions = new List<SelectOption>();
            dealerOptions.add(new SelectOption( 'Agent', UserInfo.getFirstName() ));
            dealerNameEmailMap.put('Agent',UserInfo.getUserEmail());
            requestOptions = new List<SelectOption>();
            requestOptions.add(new SelectOption( 'testDrive', 'Test Drive' ));
            requestOptions.add(new SelectOption( 'askDealer', 'Ask Dealer' ));
        }
        else{
            System.debug('Load dealer Options');
            loadDealerOptions(dealerId);
        }
    }
    
    private void loadConversations() {
        wrapperList = new List<EmailWrapper>();
        List<String>  duplicateString = new List<String>();
        String subject = (type == 'testDrive') ? 'Test Drive Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+ vehicleVin + ' #' +fastpassDealerId : 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin; //
        String subject2 = (type == 'testDrive') ? 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+ vehicleVin + ' #' +fastpassDealerId : 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin; //
        String subject3 =  'Availability Inquiry: Pre-Approved Member Interested in a Vehicle';
        System.debug('subject :: '+ subject);
        System.debug('fastpassDealerId :: '+ fastpassDealerId);
        Integer count = 0;
        if (type == 'testDrive') {
            System.debug('Inside Test Drive');
            requestHeader = 'Test Drive Request';
            for(EmailMessage each : [SELECT Subject, TextBody, HtmlBody, ToAddress, FromAddress, CreatedDate FROM EmailMessage WHERE (Subject LIKE :subject OR Subject LIKE :subject2 OR Subject LIKE :subject3) AND RelatedToId = :garageId order by CreatedDate]){
                EmailWrapper wrapper = new EmailWrapper();

                wrapper.textBody = each.HtmlBody.replaceAll('<br/>', '\n').replaceAll('<br />','\n');
                wrapper.textBody = wrapper.textBody.replaceAll('<[^>]*>', '');
                wrapper.textBody = wrapper.textBody.replaceAll('&nbsp;', '');
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.FromAddress;
                wrapper.name = emailWithNameMap.get(each.FromAddress);
                System.debug('each.FromAddress :: '+ each.FromAddress);
                System.debug('wrapper.name :: '+ wrapper.name);
                if(!duplicateString.contains(each.TextBody+each.FromAddress+each.CreatedDate.date())){
                    duplicateString.add(each.TextBody+each.FromAddress+each.CreatedDate.date());
                    wrapperList.add(wrapper);
                    count++;
                }
                
            }        
        } else if (type == 'askDealer') {
            requestHeader = 'Ask Dealer Request';
            for(EmailMessage each : [SELECT Subject, TextBody, HtmlBody, ToAddress, FromAddress, CreatedDate FROM EmailMessage WHERE Subject LIKE :subject AND RelatedToId = :garageId order by CreatedDate]){
                EmailWrapper wrapper = new EmailWrapper();
                wrapper.textBody = each.TextBody;
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.FromAddress;
                wrapper.name = emailWithNameMap.get(each.FromAddress);
                if(!duplicateString.contains(each.TextBody+each.FromAddress+each.CreatedDate.date())){
                    duplicateString.add(each.TextBody+each.FromAddress+each.CreatedDate.date());
                    wrapperList.add(wrapper);
                    count++;
                }
               
            }
        }
        if(count == 1){
            showButtons = true;
        }
        else{
            showButtons = false;
        }
    }
    
    
    //new 
    public void loadDealerOptions(String dealerId) {
        dealerOptions = new List<SelectOption>();
        System.debug('dealerId'+dealerId);
        List<Contact> dealerPro=new List<Contact>();
        Account dealerManager;
        Lead dealerLeadManager;
        List<Account> dealerManagerList = [SELECT Id, Name,Manager_Email__c FROM Account WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
         if(dealerManagerList.size() > 0){
            dealerManager = dealerManagerList[0];
         }
         else{
            dealerLeadManager = [SELECT Id, Company, Manager_Email__c, Manager_Name__c, Dealer_Pro_1_Email__c, Dealer_Pro_2_Email__c, Dealer_Pro_3_Email__c, Dealer_Pro_1_Name__c, Dealer_Pro_2_Name__c, Dealer_Pro_3_Name__c FROM Lead WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
             if(dealerManager == null && dealerLeadManager != null){
                System.debug('Inside Dealer Lead Manager');
                if(dealerLeadManager.Manager_Email__c != null && dealerLeadManager.Manager_Name__c != null ){
                    dealerNameEmailMap.put(dealerLeadManager.Manager_Name__c, dealerLeadManager.Manager_Email__c);
                    dealerOptions.add(new SelectOption(dealerLeadManager.Manager_Name__c, dealerLeadManager.Manager_Name__c));
                } 
                if(dealerLeadManager.Dealer_Pro_1_Email__c != null && dealerLeadManager.Dealer_Pro_1_Name__c != null ){
                    dealerNameEmailMap.put(dealerLeadManager.Dealer_Pro_1_Name__c, dealerLeadManager.Dealer_Pro_1_Email__c);
                    dealerOptions.add(new SelectOption(dealerLeadManager.Dealer_Pro_1_Name__c, dealerLeadManager.Dealer_Pro_1_Name__c));
                } 
                if(dealerLeadManager.Dealer_Pro_2_Email__c != null && dealerLeadManager.Dealer_Pro_2_Name__c != null ){
                    dealerNameEmailMap.put(dealerLeadManager.Dealer_Pro_2_Name__c, dealerLeadManager.Dealer_Pro_2_Email__c);
                    dealerOptions.add(new SelectOption(dealerLeadManager.Dealer_Pro_2_Name__c, dealerLeadManager.Dealer_Pro_2_Name__c));
                } 
                if(dealerLeadManager.Dealer_Pro_3_Email__c != null && dealerLeadManager.Dealer_Pro_3_Name__c != null ){
                    dealerNameEmailMap.put(dealerLeadManager.Dealer_Pro_3_Name__c, dealerLeadManager.Dealer_Pro_3_Email__c);
                    dealerOptions.add(new SelectOption(dealerLeadManager.Dealer_Pro_3_Name__c, dealerLeadManager.Dealer_Pro_3_Name__c));
                }
                System.debug('Inside Dealer Lead Manager'); 
            }
        
        }
        if (dealerManager !=null) {
            dealerPro=[SELECT Id, AccountId, Name, Email, RecordType.DeveloperName from Contact Where AccountId =:dealerManager.Id AND RecordType.DeveloperName = 'Auto_Dealer_Pro' AND Active__c = True];
        }    
        if (!dealerPro.isEmpty()) {
            for(Contact each : dealerPro) {
                dealerOptions.add(new SelectOption(each.Id, each.Name));
                dealerNameEmailMap.put(each.Id, each.Email);
                //emailWithNameMap.put(each.Email, each.Name);
            }
        }   
        System.debug('dealers'+dealerManager);
        if (dealerManager!=null && dealerManager.Manager_Email__c != null) {
                dealerOptions.add(new SelectOption(dealerManager.Id, dealerManager.Name));
                dealerNameEmailMap.put(dealerManager.Id,dealerManager.Manager_Email__c);
            	//emailWithNameMap.put(dealerManager.Manager_Email__c,dealerManager.Name);
        }
        System.debug('emailWithNameMap'+emailWithNameMap);
    }

    public void disableTrue(){
        System.debug('Inside disableTrue');
        showButtons = false;
        System.debug('showButtons :: '+ showButtons);
    }

    public void sendMessage() {
        
		System.debug('Send Message is Clicked');
        System.debug('Message :: '+ newMessage );
        if (String.isNotBlank(newMessage)) {
            System.debug('Send Message is Clicked :: '+ newMessage );
            // send email Logic 
            EmailMessage newEmail = new EmailMessage();
            System.debug(selectedDealer);
            System.debug(dealerNameEmailMap.get(selectedDealer));
            newEmail.FromAddress=dealerNameEmailMap.get(selectedDealer);
            newEmail.ToAddress = 'invalid@invalid.com';
            newEmail.Subject = (type == 'testDrive') ? 'Test Drive Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin + ' #'+fastpassDealerId : 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+fastpassDealerId;
            newEmail.TextBody = 'Dealer Response: '+newMessage;
            newEmail.HtmlBody = 'Dealer Response: '+newMessage;
            newEmail.RelatedToId = garageId;
            newEmail.Status = '3'; 
            insert newEmail;
            String chatLink;
            if(garageId != null){
                List<Garage__c> Garage = [SELECT Id, Name, VIN__c, Chat_Id__c, Opportunity__c,Dealer__c, Dealer__r.FastPass_Dealer_Id__c, FastPass_Vehicle_Id__c, Lead_Dealer__c, Lead_Dealer__r.FastPass_Dealer_Id__c FROM Garage__c WHERE Id =:garageId ]; 
                if(Garage.size() > 0){
                    chatLink = Garage[0].Chat_Id__c;
                }
            }

            List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName = 'Support' Limit 1];
            OrgWideEmailAddress orgWideEmail = orgWideEmails.size() > 0 ? orgWideEmails[0] : null;
            
            if(memberEmail != null && orgWideEmail != null){

                List<EmailTemplate> template = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Email_Notification_to_Member' LIMIT 1];
                //Messaging.SingleEmailMessage emailTemp = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage emailTemp = Messaging.renderStoredEmailTemplate(template[0].Id, null, garageId);
                if (template.size() > 0) {
            // Set up the email message
            

           // emailTemp.setTemplateId(template[0].Id);
            //emailTemp.setWhatId(garageId); 
        } else {
            System.debug('Email template not found with DeveloperName: Email_Notification_to_Member');
        }
        System.debug('Email Subject :: '+ emailTemp.getSubject() );
        System.debug('Email Body :: '+ emailTemp.getHtmlBody() );
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                // Set the recipient (to address)
                List<String> toAddresses = new List<String> {memberEmail};
                email.setToAddresses(toAddresses);
                email.setSubject(emailTemp.getSubject());
                email.setHtmlBody(emailTemp.getHtmlBody());
                email.setOrgWideEmailAddressId(orgWideEmail.Id);
                // Send the email
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
            }

            newMessage = '';
			
			Garage__c garage = new Garage__c();
            garage.Id = garageId;

            // Refresh conversations
            if (type == 'testDrive') {
                garage.Last_Dealer_Response_Test_Drive__c = System.now();
                for (EmailMessage each : [SELECT Subject, TextBody,ToAddress, FromAddress, HtmlBody, CreatedDate FROM EmailMessage WHERE Subject LIKE '%Test Drive Requested%' AND Id = :newEmail.Id ]) {
                    EmailWrapper wrapper = new EmailWrapper();
                    wrapper.textBody = each.TextBody;
                    wrapper.createdDate = each.CreatedDate;
                    wrapper.fromAddress = each.FromAddress;
                    wrapper.name = emailWithNameMap.get(each.FromAddress);
                    wrapperList.add(wrapper);
                    System.debug('new wrapper :: '+wrapper);
                    
                }
                /*for(EmailWrapper each: wrapperList){
                    System.debug('new wrapper :: '+each);
                }*/
                
            } else if (type == 'askDealer') {
                garage.Last_Dealer_Response_Ask_Dealer__c = System.now();
                for (EmailMessage each : [SELECT Subject, TextBody,ToAddress, FromAddress, CreatedDate FROM EmailMessage WHERE Subject LIKE '%Query Requested%' AND Id = :newEmail.Id ]) {
                    EmailWrapper wrapper = new EmailWrapper();
                    wrapper.textBody = each.TextBody;
                    wrapper.createdDate = each.CreatedDate;
                    wrapper.fromAddress = each.FromAddress;
                    wrapper.name = emailWithNameMap.get(each.FromAddress);
                    wrapperList.add(wrapper);
                    System.debug('wrapper'+wrapper);
                }
            }
            if(garage.Id != null){
                System.debug('Inside SMS');
                Update garage;
                callFastPassWebhook(chatLink);
               // SendSMS(garage.Id);

                
                tdc_tsw.GlobalSMSSender.sendSmsWithPhoneAPiAndTemplateId('Member_Mobile__c','a0uVA000000aSDtYAM',garage.Id);
               
            }
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
              String flowUrl = baseUrl+ '/services/data/v57.0/sobjects/Garage__c/a1kVA000009I1ZxYAK';
            request.setEndpoint(flowUrl);
            request.setMethod('PATCH');
            
            // Set headers if necessary
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + accessToken);  // If authentication is required
            
            // Prepare the request body (example JSON payload)
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('Name', 'Garage Test 222');  // Update to the desired stage name
            
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
                if (response.getStatusCode() == 200) {
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
    
    public class EmailWrapper {
        public String textBody {get; set;}
        public DateTime createdDate {get; set;}
        public String fromAddress {get; set;}
        public String name {get; set;}
    }
}