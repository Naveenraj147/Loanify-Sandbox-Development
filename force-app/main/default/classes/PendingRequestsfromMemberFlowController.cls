/**
 * @This class acts the controller for the Pending Requests from Member Flow
 */
public class PendingRequestsfromMemberFlowController {
    public class TestDriveWrapper {
        public String vehicleVIN;
        public String sender;
        public String marketCheckId;
        public String loanId;
        public String emailMessage;
        public DateTime createdDate;
    }
    
    public class RootWrapper {
        public List<TestDriveWrapper> testDrive;
    }
    
    @InvocableMethod(label='Get Formatted String From JSON')
    public static List<String> getFormattedMessages(List<String> recordId) {
        // Deserialize JSON string into wrapper class
       // RootWrapper root = (RootWrapper) JSON.deserialize(recordId[0], RootWrapper.class);
        
        List<String> formattedMessages = new List<String>();
        // for (TestDriveWrapper message : root.testDrive) {
        //     // Parse and format the CreatedDate
        //     DateTime dt = DateTime.valueOf(message.createdDate);
        //     String formattedDate = dt.format('dd/MM/yy HH:mm');
            
        //     // Append formatted message
        //     formattedMessages.add('<b>'+formattedDate + '</b> ' + message.emailMessage);
        // }
        
        // Join all messages with newline


        String sObjName = ((Id)recordId[0]).getSObjectType().getDescribe().getName();
        List<Portal_Message__c> pmList;
        
        if(sObjName == 'Opportunity'){
            pmList = [SELECT Message__c, CreatedDate FROM Portal_Message__c WHERE Opportunity__c =: recordId[0] AND Garage__c = null AND Is_Pending__c = true]; 
        }
        if(sObjName == 'Garage__c'){
            pmList = [SELECT Message__c, CreatedDate FROM Portal_Message__c WHERE Garage__c =: recordId[0] AND Is_Pending__c = true]; 
        }
        for (Portal_Message__c message : pmList) {
            // Parse and format the CreatedDate
            DateTime dt = DateTime.valueOf(message.createdDate);
            String formattedDate = dt.format('dd/MM/yy HH:mm');
            
            // Append formatted message
            formattedMessages.add('<b>'+formattedDate + '</b> ' + message.Message__c);
        }
        
        

       // }
       if(formattedMessages.size() > 0){
            return new List<String>{String.join(formattedMessages, '<br/>')};
       }
       else{
        return null;
       }
        




       
    }
    

}