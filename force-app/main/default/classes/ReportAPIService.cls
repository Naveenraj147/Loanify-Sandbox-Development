@RestResource(urlMapping='/ReportAPIService/*')
global class ReportAPIService {
    @HttpPost
    global static void doPost(){
        String requestType = '';
        String jsonResponse;
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        try{
            RestRequest req = RestContext.request;
            Map<String,Object> requestMap = (Map<String,Object>)JSON.deserializeUntyped(req.requestBody.tostring());
            if(requestMap.containsKey('requestType')){
                requestType = (String)requestMap.get('requestType');
                if(requestType=='getLoanCount' || requestType=='getCallCount' || requestType=='getCallDuration' || requestType=='getSMSDetails' || requestType =='getEmailDetails' || requestType == 'getSMSOptCount'){
                    if(requestType =='getLoanCount'){
                        jsonResponse = getOppCount(requestMap);
                    }
                    else if(requestType == 'getSMSOptCount'){
                        jsonResponse = getSMSOptCount(requestMap);
                    }
                    else{
                        jsonResponse = checkCommonParms(requestMap);
                        if(jsonResponse == null){
                            if(requestType =='getCallCount'){
                                jsonResponse = getCallCount(requestMap);
                            }
                            if(requestType =='getCallDuration'){
                                jsonResponse = GetCallDuration(requestMap);
                            }
                            if(requestType =='getSMSDetails'){
                                jsonResponse = GetSMSDetails(requestMap);
                            }
                            if(requestType =='getEmailDetails'){
                                jsonResponse = GetEmailDetails(requestMap);
                            }
                        }
                        
                    }

                    
                }
                else{
                    wrapper.success = new Map<String,Object>();
                    wrapper.error = new Map<String,String>{'NOT_FOUND'=>'Could not find the valid requestType'};
                    jsonResponse = JSON.serialize(wrapper);
                }

            }
            else{
                wrapper.success = new Map<String,Object>();
                wrapper.error = new Map<String,String>{'NOT_FOUND'=>'Could not find the parameter requestType'};
                jsonResponse = JSON.serialize(wrapper);
            }
            
            RestContext.response.statusCode = 200;
           
        }
        catch (Exception e) {
            // Handling exceptions and returning an error message
            RestContext.response.statusCode = 500; // Optional, default is 200
            String errorMessage = e.getTypeName()+': '+e.getMessage()+' Line: '+e.getLineNumber();
            System.debug('errorMessage :: ' +  errorMessage);
            wrapper.success = new Map<String,Object>();
            wrapper.error = new Map<String,String>{'ERROR'=>'An internal error has occurred.'};
            jsonResponse = JSON.serialize(wrapper);
            
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(jsonResponse);
    }


    public static String getOppCount(Map<String,Object> requestMap){
        String jsonString; 
        String requiredParameter = null; 
        String requiredValues = null;
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        if(!requestMap.containsKey('reportStartDate') ){
            requiredParameter = 'reportStartDate';
        }
        if(!requestMap.containsKey('reportEndDate') ){
            requiredParameter = requiredParameter == null? 'reportEndDate' : requiredParameter+', '+'reportEndDate'; 
        }
        if(!requestMap.containsKey('creditUnionId') ){
            requiredParameter = requiredParameter == null? 'creditUnionId' : requiredParameter+', '+'creditUnionId'; 
        }

        if(requiredParameter != null){
            wrapper.error = new Map<String,String>{'MISSING'=>'Required Parameters Missing: '+requiredParameter+'.'};
            wrapper.success = new Map<String, Object>();
        }
        else{
          List<OpportunityStage> activeOppStagesList = [SELECT MasterLabel
                                                        FROM OpportunityStage
                                                        WHERE IsActive = true
                                                        ORDER BY SortOrder ASC];

           
            String creditUnionId = (String)requestMap.get('creditUnionId');
            String reportStartDate = (String)requestMap.get('reportStartDate');
            String reportEndDate = (String)requestMap.get('reportEndDate');
            if(reportStartDate == null || reportStartDate =='' ){
                requiredValues = 'reportStartDate';
            }
            if(reportEndDate == null || reportEndDate == '' ){
                requiredValues = requiredValues == null? 'reportEndDate' : requiredValues+', '+'reportEndDate'; 
            }
            if(creditUnionId == null || creditUnionId == ''){
                requiredValues = requiredValues == null? 'creditUnionId' : requiredValues+', '+'creditUnionId'; 
            }
            if(requiredValues != null){
                wrapper.error = new Map<String,String>{'MISSING'=>'Required parameters couldn\'t empty: '+requiredValues+'.'};
                wrapper.success = new Map<String,String>();
                jsonString = JSON.serialize(wrapper);
            }
            else{
                Date reportStartDate1 = Date.valueOf((String)requestMap.get('reportStartDate'));
                Date reportEndDate1 = Date.valueOf((String)requestMap.get('reportEndDate'));
                List<AggregateResult> oppCountByStage = [SELECT StageName, COUNT(Id) countTotal
                                                            FROM Opportunity
                                                            WHERE CreatedDate >= :reportStartDate1
                                                            AND CreatedDate <= :reportEndDate1
                                                            AND Lender_Id__c =: creditUnionId
                                                            GROUP BY StageName
                                                            ORDER BY StageName];
                                                            
                    Map<String, Integer> stageCountMap = new Map<String, Integer>();
                    List<String> stagesList = new List<String>();
                    for (AggregateResult ar : oppCountByStage) {
                        stageCountMap.put((String)(ar.get('StageName')),(Integer)( ar.get('countTotal')));
                    }
                    for(OpportunityStage each: activeOppStagesList){
                        stagesList.add(each.MasterLabel);
                    }

                    wrapper.success = new Map<String, Object>();
                    wrapper.success.put('stages', stagesList);
                    wrapper.success.put('count', stageCountMap); 
                    wrapper.error = new Map<String,String>();
        }
            
        }
        jsonString = JSON.serialize(wrapper);
        return jsonString;
    }
    public static String getSMSOptCount(Map<String,Object> requestMap){
        String jsonString; 
        String requiredParameter = null; 
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        
            Date ReportStartDate = Date.valueOf((String)requestMap.get('reportStartDate'));
            Date ReportEndDate = Date.valueOf((String)requestMap.get('reportEndDate'));
            String creditUnionId = (String)requestMap.get('creditUnionId');
           List<AggregateResult> oppCountByStage = [SELECT tdc_tsw__SMS_Opt_out__c, COUNT(Id) countTotal
                                                    FROM Opportunity
                                                    WHERE CreatedDate >= :ReportStartDate
                                                    AND CreatedDate <= :ReportEndDate
                                                    AND Lender_Id__c =: creditUnionId
                                                    GROUP BY tdc_tsw__SMS_Opt_out__c];
                                                    
            Map<String, Integer> optCountMap = new Map<String, Integer>();
            for (AggregateResult ar : oppCountByStage) {
                if((Boolean)ar.get('tdc_tsw__SMS_Opt_out__c')){
                    optCountMap.put('opt-out',(Integer)( ar.get('countTotal')));
                }
                
                else{
                    optCountMap.put('opt-in',(Integer)( ar.get('countTotal')));
                }
            }
            wrapper.success = new Map<String, Object>();
            wrapper.success.put('count', optCountMap); 
            wrapper.error = new Map<String,String>();
            
            
        
        jsonString = JSON.serialize(wrapper);
        return jsonString;
    }
  
  
    public static String getCallCount(Map<String,Object> requestMap){
        String  jsonString;
        String requiredParameter = null; 
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
            Date reportStartDate = Date.valueOf((String)requestMap.get('reportStartDate'));
            Date reportEndDate = Date.valueOf((String)requestMap.get('reportEndDate'));
            String creditUnionId = (String)requestMap.get('creditUnionId');

            List<Id> whatIds = getRelatedRecords(creditUnionId);
           List<AggregateResult> callCountByAgent = [SELECT Owner.Username, tdc_cti__Call_Type__c, COUNT(Id) countTotal
                                                    FROM Task
                                                    WHERE tdc_cti__Call_Type__c != null 
                                                    AND tdc_cti__Source__c != null
                                                    AND CreatedDate >= :reportStartDate
                                                    AND CreatedDate <= :reportEndDate
                                                    AND (WhatId IN :whatIds OR WhoId IN  :whatIds )
                                                    GROUP BY Owner.Username, tdc_cti__Call_Type__c
                                                    ORDER BY Owner.Username, tdc_cti__Call_Type__c
                                                    ];
            
                                                    Map<String, Map<String, Integer>> callCountMap = new Map<String, Map<String, Integer>>();

            for (AggregateResult ar : callCountByAgent) {
                String name = (String)ar.get('Username');
                String callType = (String)ar.get('tdc_cti__Call_Type__c');
                Integer countTotal = (Integer)ar.get('countTotal');
                if(callCountMap.containsKey(name)){
                    callCountMap.get(name).put(callType,countTotal);
                }
                else {
                    callCountMap.put(name, new Map<String, Integer>());
                    callCountMap.get(name).put(callType,countTotal);
                }
            }
            
            wrapper.success = new Map<String, Object>();
            wrapper.success.put('userName', getUserList());
            wrapper.success.put('count', callCountMap);   
            wrapper.error = new Map<String,String>();
                
        
        jsonString = JSON.serialize(wrapper);
        return jsonString;
    }
    
    public static String GetCallDuration(Map<String,Object> requestMap){
        String  jsonString;
        String requiredParameter = null; 
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
            Date reportStartDate = Date.valueOf((String)requestMap.get('reportStartDate'));
            Date reportEndDate = Date.valueOf((String)requestMap.get('reportEndDate'));
            String creditUnionId = (String)requestMap.get('creditUnionId');
           List<Id> whatIds = getRelatedRecords(creditUnionId);
           List<AggregateResult> oppCountByStage = [SELECT Owner.Username, tdc_cti__Call_Type__c, SUM(CallDurationInSeconds) TotalCallDuration
                                                    FROM Task
                                                    WHERE tdc_cti__Call_Type__c != null 
                                                    AND tdc_cti__Source__c != null
                                                    AND CreatedDate >= :reportStartDate
                                                    AND CreatedDate <= :reportEndDate
                                                    AND tdc_cti__Call_Type__c != 'Missed Call'
                                                    AND (WhatId IN :whatIds OR WhoId IN  :whatIds )
                                                    GROUP BY Owner.Username, tdc_cti__Call_Type__c
                                                    ORDER BY Owner.Username, tdc_cti__Call_Type__c];
            Map<String, Map<String, Integer>> callDurationMap = new Map<String, Map<String, Integer>>();
            for (AggregateResult ar : oppCountByStage) {
                String name = (String)ar.get('Username');
                String callType = (String)ar.get('tdc_cti__Call_Type__c');
                Integer countTotal = Integer.valueOf(ar.get('TotalCallDuration'));
                if(callDurationMap.containsKey(name)){
                    callDurationMap.get(name).put(callType,countTotal);
                }
                else {
                    callDurationMap.put(name, new Map<String, Integer>());
                    callDurationMap.get(name).put(callType,countTotal);
                }
            }
           
           
                wrapper.success = new Map<String, Object>();
                wrapper.success.put('userName', getUserList());
                wrapper.success.put('count', callDurationMap); 
                System.debug('wrapper: '+ wrapper);  
                wrapper.error = new Map<String,String>();
                
        
        jsonString = JSON.serialize(wrapper);
        return jsonString;
    }

    public static String GetEmailDetails(Map<String,Object> requestMap){
        String jsonString;
        String requiredParameter = null; 
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
            Date reportStartDate = Date.valueOf((String)requestMap.get('reportStartDate'));
            Date reportEndDate = Date.valueOf((String)requestMap.get('reportEndDate'));
            String creditUnionId = (String)requestMap.get('creditUnionId');
            List<Id> whatIds = getRelatedRecords(creditUnionId);
           List<AggregateResult> oppCountByStage = [SELECT CreatedBy.Username, COUNT(Id) RecordCount
                                                    FROM EmailMessage 
                                                    WHERE CreatedDate >= :reportStartDate
                                                    AND CreatedDate <= :reportEndDate
                                                    AND RelatedToId IN :whatIds
                                                    GROUP BY CreatedBy.Username
                                                    ORDER BY CreatedBy.Username desc];
            Map<String, Integer> emailCountMap = new Map<String, Integer>();
            for (AggregateResult ar : oppCountByStage) {
                emailCountMap.put((String)(ar.get('Username')),Integer.valueOf(ar.get('RecordCount')));
            }
           
            wrapper.success = new Map<String,String>();
            
           
            wrapper.success = new Map<String, Object>();
            wrapper.success.put('userName', getUserList());
            wrapper.success.put('count', emailCountMap); 
                wrapper.error = new Map<String,String>();
        
        jsonString = JSON.serialize(wrapper);
        return jsonString;
    }

    public static String GetSMSDetails(Map<String,Object> requestMap){
        String jsonString;
        String requiredParameter = null; 
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
            Date reportStartDate = Date.valueOf((String)requestMap.get('reportStartDate'));
            Date reportEndDate = Date.valueOf((String)requestMap.get('reportEndDate'));
            String creditUnionId = (String)requestMap.get('creditUnionId');

            List<Id> whatIds = getRelatedRecords(creditUnionId);
           List<AggregateResult> smsCountByUser = [SELECT Owner.Username, Name, COUNT(Id) recordCount
                                                    FROM tdc_tsw__Message__c
                                                    WHERE CreatedDate >= :reportStartDate
                                                    AND CreatedDate <= :reportEndDate
                                                    AND tdc_tsw__Related_Object_Id__c IN :whatIds
                                                    GROUP BY Owner.Username, Name
                                                    ORDER BY Owner.Username, Name desc];
                                                    Map<String, Map<String, Integer>> smsCountMap = new Map<String, Map<String, Integer>>();
            for (AggregateResult ar : smsCountByUser) {
                String name = (String)ar.get('Username');
                String smsType = (String)ar.get('Name');
                Integer countTotal = Integer.valueOf(ar.get('recordCount'));
                if(smsCountMap.containsKey(name)){
                    smsCountMap.get(name).put(smsType,countTotal);
                }
                else {
                    smsCountMap.put(name, new Map<String, Integer>());
                    smsCountMap.get(name).put(smsType,countTotal);
                }
            }
           
            wrapper.success = new Map<String, Object>();
            wrapper.success.put('userName', getUserList()); 
                wrapper.success.put('count', smsCountMap); 
               
                wrapper.error = new Map<String,String>();
        
        jsonString = JSON.serialize(wrapper);
        return jsonString;
    }

    public static String checkCommonParms(Map<String,Object> requestMap){
        CreateResponseWrapper wrapper = new CreateResponseWrapper();
        String jsonString = null;
        String requiredParameter;
        if(!requestMap.containsKey('reportStartDate') ){
            requiredParameter = 'reportStartDate';
        }
        if(!requestMap.containsKey('reportEndDate') ){
            requiredParameter = requiredParameter == null? 'reportEndDate' : requiredParameter+', '+'reportEndDate'; 
        }
        if(!requestMap.containsKey('creditUnionId') ){
            requiredParameter = requiredParameter == null? 'creditUnionId' : requiredParameter+', '+'creditUnionId'; 
        }
        
        if(requiredParameter != null){
            wrapper.error = new Map<String,String>{'MISSING'=>'Required Parameters Missing: '+requiredParameter+'.'};
            wrapper.success = new Map<String,String>();
            jsonString = JSON.serialize(wrapper);
        }
        else{
            String requiredValues;
            String reportStartDate = (String)requestMap.get('reportStartDate');
            String reportEndDate = (String)requestMap.get('reportEndDate');
            String creditUnionId = (String)requestMap.get('creditUnionId');
            if(reportStartDate == null || reportStartDate =='' ){
                requiredValues = 'reportStartDate';
            }
            if(reportEndDate == null || reportEndDate == '' ){
                requiredValues = requiredValues == null? 'reportEndDate' : requiredValues+', '+'reportEndDate'; 
            }
            if(creditUnionId == null || creditUnionId == ''){
                requiredValues = requiredValues == null? 'creditUnionId' : requiredValues+', '+'creditUnionId'; 
            }
            if(requiredValues != null){
                wrapper.error = new Map<String,String>{'MISSING'=>'Required parameters couldn\'t empty: '+requiredValues+'.'};
                wrapper.success = new Map<String,String>();
                jsonString = JSON.serialize(wrapper);
            }
        }
        
        return jsonString;
    }

    public static Map<String, String> getUserList(){
        List<User> activeUsers = [SELECT Id, Username, Name FROM User WHERE IsActive = true ORDER BY Username desc];
        Map<String, String> userMap = new Map<String, String>();
        for (User each : activeUsers) {
            userMap.put(each.Username, each.Name);
        }
        
        return userMap;
    }

    public static List<Id> getRelatedRecords(String creditUnionId){
        Map<Id, Opportunity> oppMap =  new Map<Id, Opportunity>([SELECT Id FROM Opportunity  WHERE Lender_Id__c =: creditUnionId]);
            Map<Id, Garage__c> garageMap =  new Map<Id, Garage__c>([SELECT Id FROM Garage__c WHERE Opportunity__r.Lender_Id__c =: creditUnionId]);
            Map<Id, Contact> contactMap =  new Map<Id, Contact>([SELECT Id FROM Contact WHERE Id IN (SELECT Auto_Shopper__c FROM Opportunity WHERE Lender_Id__c =: creditUnionId)]);
            
            List<Id> whatIds = new List<Id>();
           whatIds.addAll(oppMap.keySet());
           whatIds.addAll(garageMap.keySet());
           whatIds.addAll(contactMap.keySet());
        
        return whatIds;
    }



    global class CreateResponseWrapper {
        public Map<String,Object> success;
        public Map<String,String> error;
    }
}