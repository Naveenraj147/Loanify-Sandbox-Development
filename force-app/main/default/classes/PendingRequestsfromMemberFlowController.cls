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
    public static List<String> getFormattedMessages(List<String> jsonString) {
        // Deserialize JSON string into wrapper class
        RootWrapper root = (RootWrapper) JSON.deserialize(jsonString[0], RootWrapper.class);
        
        List<String> formattedMessages = new List<String>();
        for (TestDriveWrapper message : root.testDrive) {
            // Parse and format the CreatedDate
            DateTime dt = DateTime.valueOf(message.createdDate);
            String formattedDate = dt.format('dd/MM/yy HH:mm');
            
            // Append formatted message
            formattedMessages.add('<b>'+formattedDate + '</b> ' + message.emailMessage);
        }
        
        // Join all messages with newline
        return new List<String>{String.join(formattedMessages, '<br/>')};
    }

}