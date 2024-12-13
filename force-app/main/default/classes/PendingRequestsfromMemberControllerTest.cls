@isTest
public class PendingRequestsfromMemberControllerTest {
 @isTest
    static void testGetFormattedMessages() {
        // Create sample JSON string to mimic the input
        String sampleJson = '{'+
		'            "testDrive": ['+
		'                {'+
		'                    "vehicleVIN": "1HGCM82633A123456",'+
		'                    "sender": "John Doe",'+
		'                    "marketCheckId": "MC123",'+
		'                    "loanId": "L123",'+
		'                    "emailMessage": "Test drive scheduled.",'+
		'                    "createdDate": "2023-12-13T10:15:30.000Z"'+
		'                },'+
		'                {'+
		'                    "vehicleVIN": "2HGCM82633A654321",'+
		'                    "sender": "Jane Smith",'+
		'                    "marketCheckId": "MC456",'+
		'                    "loanId": "L456",'+
		'                    "emailMessage": "Follow-up on test drive.",'+
		'                    "createdDate": "2023-12-13T12:45:30.000Z"'+
		'                }'+
		'            ]'+
		'        }';

        // Prepare input list for the invocable method
        List<String> inputJsonList = new List<String>{sampleJson};

        // Call the method under test
        List<String> result = PendingRequestsfromMemberFlowController.getFormattedMessages(inputJsonList);

        // Validate results
        System.assertEquals(1, result.size(), 'The result should contain one formatted string.');

        // Verify the formatted string contains expected values
        String expectedMessage1 = '<b>13/12/23 10:15</b> Test drive scheduled.';
        String expectedMessage2 = '<b>13/12/23 12:45</b> Follow-up on test drive.';

        System.assert(result[0].contains(expectedMessage1), 'The result should contain the first formatted message.');
        System.assert(result[0].contains(expectedMessage2), 'The result should contain the second formatted message.');

        // Validate the formatting and newline separation
        System.assert(result[0].contains('<br/>'), 'The formatted messages should be separated by <br/> tags.');
    }
}