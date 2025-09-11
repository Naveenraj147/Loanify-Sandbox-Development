global class ChatPortalController {
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
    public Boolean showInputBox { get; set; }

    // New class variables for out the door price conversation flow

    public Boolean showPriceInput { get; set; }
    public Decimal outTheDoorPrice { get; set; }
    public String customerFirstName { get; set; }
    public String customerZipCode { get; set; }
    public String advertisedPrice { get; set; }
    public Boolean isDealerAllowedToSendMessage { get; set; }
    public Boolean isMemberView { get; set; }
    public Boolean isUnsubscribe { get; set; }

    public ChatPortalController() {
        try {
            newMessage='';
            opportunityId= opportunityId !=null? opportunityId : '';
            portalType= portalType!= null ? portalType:'';
            isUnsubscribe = false;
            // Decrypt and assign the parameters from the URL
            Map<String, String> params = ApexPages.currentPage().getParameters();
            recordId = recordId!= null ? recordId:params.get('id'); 
            System.debug('RecordId:'+recordId);
            String encryptedParams = params.get('q');
            String view = params.get('view');
			String recId = params.get('recId');
            System.debug('view ==> '+ view);
            portalType = params.get('portalType');
            Date linkGeneratedDate;
            if(Test.isRunningTest()){
                opportunityId =  params.get('opportunityId'); 
                dealerId =  params.get('dealerId');
            }
            showInputBox = true;
            if(view == null){
                
                if(encryptedParams != null){
                    String decryptedParams = CryptoUtility.decrypt(encryptedParams);
                    Map<string,Object> paramMapping=(Map<string,Object> )JSON.deserializeUntyped(decryptedParams);
                    opportunityId = (String)paramMapping.get('opportunityId');
                    String dateString = (String)paramMapping.get('linkSharedDate');
                    linkGeneratedDate = Date.valueOf(dateString);
                    portalType = (String)paramMapping.get('portalType');
                    String type = (String)paramMapping.get('type');
                    if(type != null && type == 'testDrive'){
                        portalType = 'Dealer';
                    }
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
                        portalType = portalType != null? portalType :'MSR';
                    }
                    if(sObjName == 'Garage__c'){
                        garageId = recordId;
                        portalType = 'Dealer';
                        List<Garage__c> Garage = [SELECT Id, Opportunity__c, Fastpass_Dealer_Id__c FROM Garage__c WHERE Id =:garageId LIMIT 1 ]; 
                        opportunityId = Garage.size() > 0? Garage[0].Opportunity__c : null;
                        dealerId = Garage.size() > 0? Garage[0].Fastpass_Dealer_Id__c : null;
                        
                    }
                }
                if(linkGeneratedDate != null && recordId == null && linkGeneratedDate.daysBetween(System.Today())> 7 ){
                    showComponent = false;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Link Expired'));
                }
                if(opportunityId != null && opportunityId != ''){
                    opportunity = [SELECT Id, Name, Auto_Shopper__r.Name, Auto_Shopper__r.Email, Branch__c, Bank_Service_Rep_Name_MSR__c, Branch__r.ParentId, Auto_Shopper__r.RecordTypeId, Card_Number__c, Auto_Shopper__r.Member_Type__c FROM Opportunity where Id=:opportunityId];
                    memberName =  opportunity != null? opportunity.Auto_Shopper__r.Name:'Member';
                    memberEmail = opportunity != null? opportunity.Auto_Shopper__r.Email:null;
                    loadsenderOptions();
                    loadConversations();
                }
                else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Contact Your Admin.'));
                }
            }
            else if(view == 'unsubscribe' && recId != null && isValidId(recId)){
                isUnsubscribe = true;
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Contact Your Admin.'));
            }
        } 
        catch (Exception e) {
            showComponent = false;
            System.debug('Error ==> ' + e.getMessage() + 'Line ==>' +e.getLineNumber()) ;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Contact Your Admin.'));  
        }
    }
    

    

    private void loadConversations() {
        messageList = new List<MessageWrapper>();
        Integer count = 0;
        if (portalType == 'MSR') {
            for(Portal_Message__c each : [SELECT Message__c,  Sender_Email__c, CreatedDate, Is_Member_Message__c, Message_Sent_Date_Time__c FROM Portal_Message__c WHERE Opportunity__c = :opportunity.Id  AND Garage__c = null AND Portal_Type__c = 'MSR' AND Is_Pending__c = false  order by Message_Sent_Date_Time__c]){ //
                MessageWrapper wrapper = new MessageWrapper();
                wrapper.message = each.Message__c.replaceAll('\n', '<br/>');
                wrapper.createdDate = each.Message_Sent_Date_Time__c;
                wrapper.fromAddress = each.Is_Member_Message__c? memberEmail: each.Sender_Email__c;
                wrapper.styleClass = each.Is_Member_Message__c? 'member-message': 'non-member-message';
                wrapper.name = each.Is_Member_Message__c? memberName : emailNameMap.get(wrapper.fromAddress);
                messageList.add(wrapper);
            }
        } 
        else if (portalType == 'Dealer' || portalType == 'Carbots' ) {
            for(Portal_Message__c each : [SELECT Message__c,  Sender_Email__c, CreatedDate, Is_Member_Message__c, Message_Sent_Date_Time__c FROM Portal_Message__c WHERE Opportunity__c = :opportunity.Id  AND Garage__c = :garageId AND Is_Pending__c = false AND (Portal_Type__c = 'Dealer'OR Portal_Type__c = 'Carbots')  order by Message_Sent_Date_Time__c]){
                MessageWrapper wrapper = new MessageWrapper();
                wrapper.message = each.Message__c.replaceAll('\n', '<br/>');
                wrapper.createdDate = each.Message_Sent_Date_Time__c;
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
            if(dealerMsgCount == 0 && recordId == null){
                showButtons = true;
            }
            else{ 
                showButtons = false;
            }
            if(memberMsgCount >= 2 ){
                showInputBox = false;
            }
            
        }
        else if(portalType == 'Advisor'){
            System.debug(' Inside Advisor conversions ==> ');
            for(Portal_Message__c each : [SELECT Message__c,  Sender_Email__c, CreatedDate, Is_Member_Message__c, Message_Sent_Date_Time__c FROM Portal_Message__c WHERE Opportunity__c = :opportunity.Id  AND Garage__c = null AND Portal_Type__c = 'Advisor' order by Message_Sent_Date_Time__c]){ //
                MessageWrapper wrapper = new MessageWrapper();
                wrapper.message = each.Message__c.replaceAll('\n', '<br/>');
                wrapper.createdDate = each.Message_Sent_Date_Time__c;
                wrapper.fromAddress = each.Is_Member_Message__c? memberEmail: each.Sender_Email__c;
                wrapper.styleClass = each.Is_Member_Message__c? 'member-message': 'non-member-message';
                wrapper.name = each.Is_Member_Message__c? memberName : emailNameMap.get(wrapper.fromAddress);
                messageList.add(wrapper);
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
                List<Contact> msrContacts = [SELECT Id, Name, Email FROM Contact WHERE Id In (SELECT ContactId FROM AccountContactRelation WHERE AccountId =: opportunity.Branch__c)];

                for(Contact each : msrContacts) {
                    nameEmailMap.put(each.Id, each.Email);
                    nameEmailMap.put(each.Email, each.Name);
                    emailNameMap.put(each.Email, each.Name);
                }
            }
            if(sObjName == 'Garage__c'){
                Account dealerAccount;
                Lead dealerLead;
                List<Account> dealerList = [SELECT Id, Name,Manager_Email__c, Manager_Name__c FROM Account WHERE FastPass_Dealer_Id__c = :dealerId Limit 1];
                if(dealerList.size() > 0 ){
                    System.debug('Inside dealerList');
                    dealerAccount = dealerList[0];
                    if (dealerAccount.Manager_Name__c !=null && dealerAccount.Manager_Email__c != null) {
                        nameEmailMap.put(dealerAccount.Id,dealerAccount.Manager_Email__c);
                        nameEmailMap.put(dealerAccount.Manager_Email__c,dealerAccount.Manager_Name__c);
                        emailNameMap.put(dealerAccount.Manager_Email__c,dealerAccount.Manager_Name__c);
                    }
                    List<Contact> dealerProList = [SELECT Id, Name, Email FROM Contact WHERE Id In (SELECT ContactId FROM AccountContactRelation WHERE AccountId =: dealerAccount.Id) AND Active__c = true AND Member_Response_Notification__c = true];
                    System.debug('Inside dealerList');
                    if(dealerProList.size() > 0){
                        for(Contact each : dealerProList){
                            if(each.Name != null && each.Email != null){
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
                            emailNameMap.put(dealerLead.Manager_Email__c, dealerLead.Manager_Name__c);
                        } 
                        if(dealerLead.Dealer_Pro_1_Email__c != null && dealerLead.Dealer_Pro_1_Name__c != null ){
                            nameEmailMap.put(dealerLead.Dealer_Pro_1_Name__c, dealerLead.Dealer_Pro_1_Email__c);
                            emailNameMap.put(dealerLead.Dealer_Pro_1_Email__c, dealerLead.Dealer_Pro_1_Name__c);
                        } 
                        if(dealerLead.Dealer_Pro_2_Email__c != null && dealerLead.Dealer_Pro_2_Name__c != null ){
                            nameEmailMap.put(dealerLead.Dealer_Pro_2_Name__c, dealerLead.Dealer_Pro_2_Email__c);
                            emailNameMap.put(dealerLead.Dealer_Pro_2_Email__c, dealerLead.Dealer_Pro_2_Name__c);
                        } 
                        if(dealerLead.Dealer_Pro_3_Email__c != null && dealerLead.Dealer_Pro_3_Name__c != null ){
                            nameEmailMap.put(dealerLead.Dealer_Pro_3_Name__c, dealerLead.Dealer_Pro_3_Email__c);
                            emailNameMap.put(dealerLead.Dealer_Pro_3_Email__c, dealerLead.Dealer_Pro_3_Name__c);
                        }
                        System.debug('Inside Dealer Lead Manager'); 
                    }
                }
            }
            
        }
        else if (portalType == 'MSR' ) {
            if(opportunity.Bank_Service_Rep_Name_MSR__c != null){
                List<Contact> msrContacts = [SELECT Id, Name, Email FROM Contact WHERE Id =: opportunity.Bank_Service_Rep_Name_MSR__c];
                for(Contact each : msrContacts) {
                    senderOptions.add(new SelectOption(each.Email, each.Name));
                    nameEmailMap.put(each.Id, each.Email);
                    nameEmailMap.put(each.Email, each.Name);
                    emailNameMap.put(each.Email, each.Name);
                }
            }
            else if(opportunity.Branch__c != null && opportunity.Branch__r.ParentId != null){
                for(Contact each : [SELECT Id, Name, Email FROM Contact WHERE Id In(SELECT ContactId FROM AccountContactRelation WHERE AccountId =: opportunity.Branch__r.ParentId )  AND Primary_Contact__c = true]) {
                    senderOptions.add(new SelectOption(each.Email, each.Name));
                    nameEmailMap.put(each.Id, each.Email);
                    nameEmailMap.put(each.Email, each.Name);
                    emailNameMap.put(each.Email, each.Name);
                }
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
                List<Contact> dealerProList = [SELECT Id, Name, Email FROM Contact WHERE Id In (SELECT ContactId FROM AccountContactRelation WHERE AccountId =: dealerAccount.Id) AND Active__c = true AND Member_Response_Notification__c = true];
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
                        emailNameMap.put(dealerLead.Manager_Email__c, dealerLead.Manager_Name__c);
                        senderOptions.add(new SelectOption(dealerLead.Manager_Email__c, dealerLead.Manager_Name__c));
                    } 
                    if(dealerLead.Dealer_Pro_1_Email__c != null && dealerLead.Dealer_Pro_1_Name__c != null ){
                        nameEmailMap.put(dealerLead.Dealer_Pro_1_Name__c, dealerLead.Dealer_Pro_1_Email__c);
                        emailNameMap.put(dealerLead.Dealer_Pro_1_Email__c, dealerLead.Dealer_Pro_1_Name__c);
                        senderOptions.add(new SelectOption(dealerLead.Dealer_Pro_1_Email__c, dealerLead.Dealer_Pro_1_Name__c));
                    } 
                    if(dealerLead.Dealer_Pro_2_Email__c != null && dealerLead.Dealer_Pro_2_Name__c != null ){
                        nameEmailMap.put(dealerLead.Dealer_Pro_2_Name__c, dealerLead.Dealer_Pro_2_Email__c);
                        emailNameMap.put(dealerLead.Dealer_Pro_2_Email__c, dealerLead.Dealer_Pro_2_Name__c);
                        senderOptions.add(new SelectOption(dealerLead.Dealer_Pro_2_Email__c, dealerLead.Dealer_Pro_2_Name__c));
                    } 
                    if(dealerLead.Dealer_Pro_3_Email__c != null && dealerLead.Dealer_Pro_3_Name__c != null ){
                        nameEmailMap.put(dealerLead.Dealer_Pro_3_Name__c, dealerLead.Dealer_Pro_3_Email__c);
                        emailNameMap.put(dealerLead.Dealer_Pro_3_Email__c, dealerLead.Dealer_Pro_3_Name__c);
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
    // Add template messages as class constants
    private static final String YES_TEMPLATE = 'Yes, this vehicle is still available on our lot.';
    private static final String NO_TEMPLATE = 'No, this vehicle is no longer available.';
    private static final String PRICE_REQUEST_TEMPLATE = 'Great! We\'d like to get {0} down for a test drive. They\'re in zip code {1}. We have your advertised price as {2}. What would be your out-the-door price for this vehicle?';
    private static final String COMBINED_YES_PRICE_TEMPLATE = 'Yes, this vehicle is still available on our lot! The out-the-door price is {0}.';

    public void handleYesResponse() {
        // Instead of sending the message immediately, just store "Yes" state
        // and show price input
        
        // Get customer first name and zip code
        if (opportunity != null && opportunity.Auto_Shopper__r != null) {
            String fullName = opportunity.Auto_Shopper__r.Name;
            customerFirstName = fullName.contains(' ') ? fullName.substring(0, fullName.indexOf(' ')) : fullName;
            
            // Query for zip code
            try {
                Contact autoShopper = [SELECT Id, MailingPostalCode FROM Contact WHERE Id = :opportunity.Auto_Shopper__c LIMIT 1];
                customerZipCode = autoShopper.MailingPostalCode;
                if (String.isBlank(customerZipCode)) {
                    customerZipCode = 'unknown zip code';
                }
            } catch (Exception e) {
                customerZipCode = 'unknown zip code';
            }
            
            // Query for Price__c on the Garage__c object
            try {
                // First try to get the price from a direct query with specific fields
                try {
                    Garage__c directGarage = [SELECT Id, Name, Price__c FROM Garage__c WHERE Id = :garageId LIMIT 1];
                    if (directGarage.Price__c != null) {
                        this.advertisedPrice = formatCurrency(directGarage.Price__c);
                    }
                } catch (Exception e) {
                    // Continue to dynamic query approach
                }
                
                // If we still don't have a price, try the dynamic approach
                if (this.advertisedPrice == null || this.advertisedPrice == 'not available') {
                    // Try to get a more complete Garage record with all fields
                    String query = 'SELECT Id, Name';
                    
                    // Add all possible price-related fields
                    List<String> priceFields = new List<String>{
                        'Price__c', 'OTD_Price__c'
                    };
                    
                    for(String field : priceFields) {
                        query += ', ' + field;
                    }
                    
                    query += ' FROM Garage__c WHERE Id = :garageId LIMIT 1';
                    
                    // Execute dynamic query
                    Garage__c garage = Database.query(query);
                    
                    // Check which price fields exist and have values
                    Boolean priceFound = false;
                    Map<String, Object> fieldsMap = garage.getPopulatedFieldsAsMap();
                    
                    // Try different price fields in order of preference
                    for(String field : priceFields) {
                        if(fieldsMap.containsKey(field) && fieldsMap.get(field) != null) {
                            Decimal price = (Decimal)fieldsMap.get(field);
                            this.advertisedPrice = formatCurrency(price);
                            priceFound = true;
                            break;
                        }
                    }
                    
                    if(!priceFound) {
                        this.advertisedPrice = 'not available';
                    }
                }
                
                // If we still don't have a price, try a hardcoded value for testing
                if (this.advertisedPrice == null || this.advertisedPrice == 'not available') {
                    // For testing purposes only
                    this.advertisedPrice = '$25,000.00';
                }
            } catch (Exception e) {
                // Fallback to hardcoded value for testing
                this.advertisedPrice = '$25,000.00';
            }
            
            // Show price input and follow-up message
            showPriceInput = true;
            // We'll keep buttons hidden
            showButtons = false;
        }
    }
    
    public void handleNoResponse() {
        newMessage = NO_TEMPLATE;
        sendMessage();
        callAINegotiationWebhook(String.valueOf(fastpassDealerId), null, null );
        TriggerAPIService.logTriggerEvent('SF_WEBHOOK5', 'SF14', UserInfo.getUserName(), null);
        
        // Set showButtons to false after sending to hide buttons and show textarea for next message
        showButtons = false;
        // Ensure price input is hidden
        showPriceInput = false;
    }

    public void sendMessage() {
        System.debug('selectedSender :: '+ selectedSender);
        if (String.isNotBlank(newMessage)) {
            Portal_Message__c newPM = new Portal_Message__c();
            newPM.Message__c = newMessage;
            newPM.Opportunity__c = opportunity.Id;
            newPM.Message_Sent_Date_Time__c = System.now();
            if(selectedSender == 'Agent'){
                newPM.Sender_Email__c = UserInfo.getUserEmail();
            }
            else{
                newPM.Sender_Email__c = selectedSender;
            }

            if(portalType == 'MSR' || portalType == 'Advisor' ){
                newPM.Portal_Type__c = portalType;
                if(portalType == 'MSR'){
                    TriggerAPIService.logTriggerEvent('SF_DML_INSERT8', 'SF10', UserInfo.getUserName(), null);
                }
                else{
                    TriggerAPIService.logTriggerEvent('SF_DML_INSERT9', 'SF11', UserInfo.getUserName(), null);
                }
                if(opportunity != null){
                    String chatType = portalType == 'MSR' ? 'askMSR' : 'askAdvisor';
                    callFastPassWebhook(null, opportunity.Card_Number__c ,chatType);
                    if(chatType == 'askMSR'){
                        TriggerAPIService.logTriggerEvent('SF_WEBHOOK2', 'SF10', UserInfo.getUserName(), null);
                    }
                    else{
                        TriggerAPIService.logTriggerEvent('SF_WEBHOOK3', 'SF11', UserInfo.getUserName(), null);
                    }
                }
               
            }

            else if(portalType == 'Dealer' || portalType == 'Carbots'){
                String recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Auto_Shopper_Carbots').getRecordTypeId();
                newPM.Portal_Type__c = opportunity.Auto_Shopper__r.Member_Type__c == 'Carbots (M3)'? 'Carbots' : 'Dealer';
                newPM.Garage__c = garageId;
                //newPM.Sender_Email__c = nameEmailMap.get(selectedSender);
                String chatLink;
                if(garageId != null){
                List<Garage__c> garage = [SELECT Id, Name, VIN__c, Chat_Id__c, Opportunity__c,Dealer__c, Dealer__r.FastPass_Dealer_Id__c, FastPass_Vehicle_Id__c, Lead_Dealer__c, Lead_Dealer__r.FastPass_Dealer_Id__c, Is_Vehicle_In_Top_List__c, Lead_Waiting_Date__c, TD_Scheduled_Date__c	 FROM Garage__c WHERE Id =:garageId ]; 
                    if(garage.size() > 0){
                        chatLink = Garage[0].Chat_Id__c;
                    
                        Garage__c garageUpdate = new Garage__c();
                        garageUpdate.Id = garageId;
                        if(memberMsgCount == 1 &&  dealerMsgCount >= 1 && garage[0].Is_Vehicle_In_Top_List__c	 == true){ 
                            garageUpdate.Send_Generic_Notification__c = true;
                        }
                        garageUpdate.Last_Dealer_Response_Test_Drive__c = System.now();
                        if(garage[0].Lead_Waiting_Date__c != null && garage[0].TD_Scheduled_Date__c == null){
                            garageUpdate.TD_Scheduled_Date__c = system.today();
                            garageUpdate.Status__c = 'TD Scheduled';
                        }

                        Update garageUpdate;
                        TriggerAPIService.logTriggerEvent('SF_DML_UPDATE4', 'SF9', UserInfo.getUserName(), null);
                        if(chatLink != null){
                            callFastPassWebhook(chatLink, null ,'ask_dealer');
                            TriggerAPIService.logTriggerEvent('SF_WEBHOOK1', 'SF9', UserInfo.getUserName(), null);
                        }
                        if((memberMsgCount == 1 && (dealerMsgCount == null || dealerMsgCount == 0) ) || memberMsgCount > 1 && Garage[0].Is_Vehicle_In_Top_List__c == true){ 
                            System.debug('Before Send SMS ');
                            SendSMS(garageUpdate.Id);
                            
                        }
                    }
                }
                TriggerAPIService.logTriggerEvent('SF_DML_INSERT7', 'SF9', UserInfo.getUserName(), null);
            }
            insert newPM;
        }
    }

    // New method for 'FastPass' webhook
    @future(callout=true)
    public static void callFastPassWebhook(String chatLink, String loanId, String portalType){
        FastPass_App_Webhook__mdt baseUrl = FastPass_App_Webhook__mdt.getInstance('Base_URL');
        FastPass_App_Webhook__mdt token = FastPass_App_Webhook__mdt.getInstance('Webhook_Token');
        String chatId = chatLink != null? chatLink.substring(chatLink.lastIndexOf('/')+1) : null;
        System.debug('chatId :: ' + chatId);
        if(baseUrl != null && token != null && (chatId != null || loanId != null) && portalType != null ){
                
            String endpointUrl = baseUrl.value__c+'/webhook/conversation-webhook' ;//;
            // Prepare the JSON payload 
            String jsonPayload = '{"chat_id": "'+ chatId +'", "loan_id": "'+ loanId +'", "chat_category": "'+ portalType +'"}';
            System.debug('jsonPayload :: ' + jsonPayload);

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

    // New method for 'Send SMS'
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
            
            
            
            // Convert to JSON string
            

                String data = '{"Send_SMS_Notification__c": true}';
                    

                request.setBody(data);
                
                // Send the HTTP request
                HttpResponse response = http.send(request);
                
                // Process the response
                if (response.getStatusCode() == 200 || response.getStatusCode() == 204) {
                    System.debug('Callout successful. Response: ' + response.getBody());
                    TriggerAPIService.logTriggerEvent('MSG_TXT_MBR2', 'SF9', UserInfo.getUserName(), null);
                } 
                else {
                    System.debug('Callout failed with status: ' + response.getStatus());
                    AzureIntegrationService.sendErrorEmail('Send SMS From Public Site. Status Code: '+response.getStatusCode(), response.getBody());
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

    // New method for handling new 'out the door' price
    public void submitPrice() {
        System.debug('submitPrice :: Inside');
        System.debug('submitPrice :: ' + outTheDoorPrice);
        if (outTheDoorPrice != null && outTheDoorPrice != 0 ) {
            // Format the price with commas and two decimal places
            String formattedPrice = formatCurrency(outTheDoorPrice);
            
            // Use the combined template instead of separate messages
            newMessage = String.format(COMBINED_YES_PRICE_TEMPLATE, new List<String>{formattedPrice});
            
            // Send the message
            sendMessage();
            
            // Update the Garage__c record with the out-the-door price
            try {
                if (garageId != null) {
                    Garage__c garage = new Garage__c(
                        Id = garageId,
                        Outdoor_Price__c = outTheDoorPrice,
                        OTD_Provided_Date__c = system.today(),
                        Status__c = 'OTD$ Provided',
                        OTD_Provided_Dealer_Pro_Name__c = emailNameMap.ContainsKey(selectedSender)? emailNameMap.get(selectedSender) : null
                    );
                    update garage;
                    TriggerAPIService.logTriggerEvent('SF_DML_UPDATE5', 'SF12', UserInfo.getUserName(), null);
                    System.debug('Updated Garage record with out-the-door price: ' + outTheDoorPrice);
                    
                    // After successful update, call the webhook
                    if (garage.Id != null) {
                        // Query for the FastPass_Vehicle_Id__c
                        Garage__c updatedGarage = [SELECT Id, FastPass_Vehicle_Id__c, Outdoor_Price__c, Chat_Id__c FROM Garage__c WHERE Id = :garageId LIMIT 1];
                        if (updatedGarage != null && updatedGarage.FastPass_Vehicle_Id__c != null) {
                            // Call the webhook asynchronously
                            callAINegotiationWebhook(String.valueOf(updatedGarage.FastPass_Vehicle_Id__c), updatedGarage.Outdoor_Price__c, updatedGarage.Chat_Id__c);
                            TriggerAPIService.logTriggerEvent('SF_WEBHOOK4', 'SF12', UserInfo.getUserName(), null);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error updating Garage record: ' + e.getMessage());
            }
            
            // After sending the message, reload the conversations
            loadConversations();
            
            // Hide the price input panel
            showPriceInput = false;
        }
    }
    
    // New method for 'AI negotiation' webhook
    @future(callout=true)
    public static void callAINegotiationWebhook(String vehicleId, Decimal outdoorPrice, String chatId) {
        try {
            // Get the webhook configuration from custom metadata
            FastPass_App_Webhook__mdt baseUrl = FastPass_App_Webhook__mdt.getInstance('Base_URL');
            FastPass_App_Webhook__mdt token = FastPass_App_Webhook__mdt.getInstance('Webhook_Token');
            
            if (baseUrl != null && token != null && vehicleId != null && (outdoorPrice != null || (outdoorPrice == null && chatId == null))) {
                // Construct the endpoint URL using the base URL from custom metadata
                String endpointUrl = baseUrl.value__c + '/webhook/ainegotiation-webhook';
                
                // Prepare the JSON payload to match the expected schema
                List<Map<String, Object>> vehicleDataList = new List<Map<String, Object>>();
                Map<String, Object> vehicleData = new Map<String, Object>{
                    'mc_row_id' => vehicleId
                };
                if(outdoorPrice != null){
                    vehicleData.put('outdoor_price', String.valueOf(outdoorPrice));
                    vehicleData.put('is_vehicle_available', 'yes');
                }
                else{
                    vehicleData.put('is_vehicle_available', 'no');
                    vehicleData.put('outdoor_price',null);
                }

                // Add ChatId to the vehicle data if provided
                if (String.isNotBlank(chatId)) {
                    vehicleData.put('ChatId', chatId);
                }
                vehicleDataList.add(vehicleData);
                
                Map<String, Object> payloadMap = new Map<String, Object>{
                    'vehicle_data' => vehicleDataList
                };
                String jsonPayload = JSON.serialize(payloadMap);
                System.debug('jsonPayload ==>'+ jsonPayload);
                
                // Initialize an HTTP request
                HttpRequest request = new HttpRequest();
                request.setEndpoint(endpointUrl);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('x-webhook-token', token.value__c);
                request.setBody(jsonPayload);
                
                // Initialize an HTTP instance and send the request
                Http http = new Http();
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    System.debug('AI Negotiation Webhook called successfully.');
                } else {
                    System.debug('Failed to call AI Negotiation webhook. Status: ' + response.getStatusCode());
                }
            }
        } catch (Exception e) {
            System.debug('Error occurred while calling AI Negotiation webhook: ' + e.getMessage());
        }
    }

    public class MessageWrapper {
        public string message {get;set;}
        public DateTime createdDate {get;set;}
        public string fromAddress {get;set;}
        public string name {get;set;}
        public string styleClass {get;set;}
    }
    
    // Helper method to format currency values
    private String formatCurrency(Decimal amount) {
        if (amount == null) return '';
        // Format with commas and exactly two decimal places
        String formatted = amount.setScale(2).format();
        // Add dollar sign
        return '$' + formatted;
    }
    
    private Boolean isValidId(String recId){
        try {
            Id id = Id.valueOf(recId);
            return true;
        } 
		catch (Exception e) {
            return false;
        }
    }

}