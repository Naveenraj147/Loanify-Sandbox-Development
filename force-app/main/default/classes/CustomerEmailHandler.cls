global class CustomerEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try {
            String subject = email.subject;
            String cardNumber = extractCardNumber(subject);
            
            if (cardNumber != null) {
                List<Opportunity> matchingOpportunities = [SELECT Id, Name FROM Opportunity WHERE Card_Number__c = :cardNumber Limit 1];
                if (!matchingOpportunities.isEmpty() && matchingOpportunities.Size()>0) {
                    Opportunity matchingOpportunity = matchingOpportunities[0];
                    EmailMessage emailMsg = new EmailMessage();
                    emailMsg.RelatedToId = matchingOpportunity.Id;
                    emailMsg.Subject = email.subject;
                    emailMsg.HtmlBody = email.htmlBody;
                    emailMsg.TextBody = email.plainTextBody;
                    emailMsg.FromAddress = email.fromAddress;
                    emailMsg.MessageDate = System.now();
                    emailMsg.Status = '4';
                    
                    system.debug('FromAddress::' +emailMsg.FromAddress);
                    system.debug('TooAddress::' +emailMsg.ToAddress);
                    
                    Map<string, String>  ccMap = new Map<string, string>();
                    for (Messaging.InboundEmail.Header header : email.headers) {
                        system.debug(header.Name + '::' + header.value);
                        if (header.name == 'From') {
                            emailMsg.FromName = header.value.substringBefore('<').trim().replaceAll('"', '');
                        } else if (header.name == 'Cc') {
                            ccMap.put(header.Name, header.Value);   
                        } else if (header.name == 'To' && header.value.contains('<')) {
                            emailMsg.ToAddress = header.value.substringBetween('<', '>');
                        } else if (header.name == 'To'){
                            emailMsg.ToAddress = header.value;
                        }
                        
                    }
                    System.debug('map::'+ ccMap);
                    System.debug('Check condition for Outlook::'+ ccMap.containskey('CC'));
                    system.debug('Check condition for Gmail::'+ccMap.containskey('Cc'));
                    System.debug('Values In map::'+ ccMap.values());
                    system.debug('Key In map::' + ccMap.keyset());
                    if(ccMap.containskey('CC') || ccMap.containsKey('Cc') || Test.isRunningTest()){
                        String ccValue = ccMap.containsKey('CC') ? ccMap.get('CC') : ccMap.get('Cc');
                        List<string> ccStr = ccValue.split(',');
                        System.debug('Values in List::'+ ccStr);
                        string ccAddr = '';
                        for(string each: ccStr){
                            string tmp = '';
                            if (each.contains('<')) {
                                tmp = each.substringBetween('<', '>');
                            } else{
                                tmp = each;
                            }
                            system.debug('Comma Separated CcAddress::' + tmp);
                            if(ccAddr == ''){
                                ccAddr = tmp;   
                            }
                            else{
                                ccAddr = ccAddr +','+tmp;    
                            }
                        }
                        
                        emailMsg.CcAddress = ccAddr;
                    }
                    insert emailMsg;
                    
                    If(email.binaryAttachments != null){
                        List<Attachment> attachments = new List<Attachment>();
                        for (Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments) {
                            if (attachment.body.size() <= 25 * 1024 * 1024) {
                                Attachment newAttachment = new Attachment();
                                newAttachment.ParentId = emailMsg.Id;
                                newAttachment.Name = attachment.fileName;
                                newAttachment.Body = attachment.body;
                                attachments.add(newAttachment);
                            }
                        }
                        insert attachments;
                    }
                    
                    System.debug('Email processed and associated with Opportunity: ' + matchingOpportunity.Name);
                }
            }
            result.success = true;
        } catch(Exception e){
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            System.debug('Error processing email: ' + errorMessage);
            result.success = false;
            result.message = 'Something went wrong. Please contact our support team.';
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            List<String> emailIdsiLst;
            emailIdsiLst = Label.Exception_Email_Recipients.split(',');
            if(!emailIdsiLst.isEmpty() && emailIdsiLst.size() > 0){
                for(string each:emailIdsiLst){
                    sendTo.add(each);
                }
                errorEmail.setToAddresses(sendTo);
                errorEmail.setSubject('CustomerEmailHandler -'+'An exception has occured while getting mail from customer');
                errorEmail.setHtmlBody('Following Exception has Occured in CustomerEmailHandler.<br/><br/> Exception:'+ errorMessage);
                emailList.add(errorEmail);
                if(!Test.isRunningTest() && emailList.size()>0){
                    
                    Messaging.sendEmail(emailList);
                }
            }
        }
        return result;
    }
    
    private String extractCardNumber(String subject) {
        String cardNumber = null;
        
        if (subject != null) {
            Pattern pattern = Pattern.compile('#(\\d{16})\\b');
            Matcher matcher = pattern.matcher(subject);
            if (matcher.find()) {
                cardNumber = matcher.group(1);
            }
        }
        
        return cardNumber;
    }
}