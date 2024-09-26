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
	public String RecordId{ get; set; }
    public String opportunityId;
    public String dealerId;
    public String vehicleVin{ get; set; }
    public String vehicleName{ get; set; }
    public String requestHeader{ get; set; }
    public String type{ get; set; }
    public String garageId;
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
        }
        if(RecordId != null){
            garageId = RecordId;
            List<Garage__c> Garage = [SELECT Id, Name, VIN__c, Opportunity__c, Dealer__r.FastPass_Dealer_Id__c, FastPass_Vehicle_Id__c FROM Garage__c WHERE Id =:RecordId ]; 
            if(Garage.size() > 0){
                opportunityId = Garage[0].Opportunity__c;
                dealerId = Garage[0].Dealer__r.FastPass_Dealer_Id__c;
                vehicleVin = Garage[0].VIN__c;
                vehicleName = Garage[0].Name;
                fastpassDealerId = Integer.valueOf((Garage[0].FastPass_Vehicle_Id__c));
                type = 'testDrive';
            }
            
        }
        
        showComponent = true;
        
        if(convertedDate != null && RecordId == null && convertedDate.daysBetween(System.Today())> 7 ){
            showComponent = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Link Expired'));
        }

        System.debug('opportunityId'+opportunityId);
        System.debug('dealerId'+dealerId);
        System.debug('vehicleVin'+vehicleVin);
        System.debug('type'+type);
        //System.debug('linkSharedDate'+linkSharedDate);
		List<Contact> dealerPro=new List<Contact>();
        opportunity = [SELECT Id, Name,Auto_Shopper__r.Name,Card_Number__c FROM Opportunity where Id=:opportunityId];
        Account dealerManager = [SELECT Id, Name,Manager_Email__c FROM Account WHERE FastPass_Dealer_Id__c = :dealerId Limit 1]; 
        if (dealerManager !=null) {
            dealerPro=[SELECT Id, AccountId, Name, Email, RecordType.DeveloperName from Contact Where AccountId =:dealerManager.Id AND RecordType.DeveloperName = 'Auto_Dealer_Pro' AND Active__c = true];
        }
        String memberName =  opportunity != null? opportunity.Auto_Shopper__r.Name:'Member';
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
        System.debug('dealers'+dealerManager);
        if (dealerManager!=null && dealerManager.Manager_Email__c != null) {
            	emailWithNameMap.put(dealerManager.Manager_Email__c,dealerManager.Name);
        }
        System.debug('emailWithNameMap'+emailWithNameMap);
        loadConversations();
        // Fetch conversations based on type
       /* wrapperList = new List<EmailWrapper>();
        List<String>  duplicateString = new List<String>();
        String subject = (type == 'testDrive') ? 'Test Drive Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin : 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin;

        if (type == 'testDrive') {
            System.debug('Inside Test Drive');
            requestHeader = 'Test Drive Request';
            for(EmailMessage each : [SELECT Subject, TextBody,ToAddress, FromAddress, CreatedDate FROM EmailMessage WHERE Subject LIKE :subject AND RelatedToId = :garageId order by CreatedDate]){
                EmailWrapper wrapper = new EmailWrapper();
               
                wrapper.textBody = each.TextBody;
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.FromAddress;
                wrapper.name = emailWithNameMap.get(each.FromAddress);
                
                if(!duplicateString.contains(each.TextBody+each.FromAddress+each.CreatedDate.date())){
                    duplicateString.add(each.TextBody+each.FromAddress+each.CreatedDate.date());
                    wrapperList.add(wrapper);
                }
                
            }        
        } else if (type == 'askDealer') {
            requestHeader = 'Ask Dealer Request';
            for(EmailMessage each : [SELECT Subject, TextBody,ToAddress, FromAddress, CreatedDate FROM EmailMessage WHERE Subject LIKE :subject AND RelatedToId = :garageId order by CreatedDate]){
                EmailWrapper wrapper = new EmailWrapper();
                wrapper.textBody = each.TextBody;
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.FromAddress;
                wrapper.name = emailWithNameMap.get(each.FromAddress);
                if(!duplicateString.contains(each.TextBody+each.FromAddress+each.CreatedDate.date())){
                    duplicateString.add(each.TextBody+each.FromAddress+each.CreatedDate.date());
                    wrapperList.add(wrapper);
                }
               
            }
        }*/
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
            loadDealerOptions(dealerId);
        }
        

        System.debug('conversations--> '+conversations);
        System.debug('wrapperList--> '+wrapperList);
    }
    
    private void loadConversations() {
        wrapperList = new List<EmailWrapper>();
        List<String>  duplicateString = new List<String>();
        String subject = (type == 'testDrive') ? 'Test Drive Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+ vehicleVin + ' #' +fastpassDealerId : 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin; //
        String subject2 = (type == 'testDrive') ? 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+ vehicleVin + ' #' +fastpassDealerId : 'Query Requested by '+opportunity.Auto_Shopper__r.Name+' for #'+opportunity.Card_Number__c+' in #'+vehicleVin; //
        System.debug('subject :: '+ subject);
        System.debug('fastpassDealerId :: '+ fastpassDealerId);
        if (type == 'testDrive') {
            System.debug('Inside Test Drive');
            requestHeader = 'Test Drive Request';
            for(EmailMessage each : [SELECT Subject, TextBody, HtmlBody, ToAddress, FromAddress, CreatedDate FROM EmailMessage WHERE (Subject LIKE :subject OR Subject LIKE :subject2) AND RelatedToId = :garageId order by CreatedDate]){
                EmailWrapper wrapper = new EmailWrapper();
               
                System.debug('Message :: + '+each.TextBody);
                System.debug('Message HtmlBody :: + '+each.HtmlBody);

                wrapper.textBody = each.HtmlBody.replaceAll('<br/>', '\n').replaceAll('<br />','\n');
                wrapper.textBody = wrapper.textBody.replaceAll('<[^>]*>', '');
                wrapper.textBody = wrapper.textBody.replaceAll('&nbsp;', '');
                wrapper.createdDate = each.CreatedDate;
                wrapper.fromAddress = each.FromAddress;
                wrapper.name = emailWithNameMap.get(each.FromAddress);
                
                if(!duplicateString.contains(each.TextBody+each.FromAddress+each.CreatedDate.date())){
                    duplicateString.add(each.TextBody+each.FromAddress+each.CreatedDate.date());
                    wrapperList.add(wrapper);
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
                }
               
            }
        }
    }
    
    
    //new 
    public void loadDealerOptions(String dealerId) {
        dealerOptions = new List<SelectOption>();
        System.debug('dealerId'+dealerId);
        List<Contact> dealerPro=new List<Contact>();
        Account dealerManager = [SELECT Id, Name,Manager_Email__c FROM Account WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
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

    public void sendMessage() {
		System.debug('Send Message is Clicked');
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
            newMessage = '';
			System.debug('Send Message is Clicked :: '+ newEmail.TextBody );
            System.debug('Send Message is Clicked :: '+ newEmail.TextBody );

            System.debug('Send Message is Clicked :: '+ newEmail.HtmlBody );
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
                for(EmailWrapper each: wrapperList){
                    System.debug('new wrapper :: '+each);
                }
                
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
                Update garage;
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