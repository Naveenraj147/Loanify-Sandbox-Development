global class AzureIntegrationServiceScheduler implements Schedulable {

    global void execute(SchedulableContext ctx) {
         
        AzureIntegrationService.getAzureAccessToken();
        
        //String jobName = 'Azure Access Token Update';
        //String jobDetail = 'This job updates Azure access token every 12 hours';
        //String cronExpression = '0 0 */12 * * ?'; 
        //System.schedule(jobName, cronExpression, new AzureIntegrationServiceScheduler());
        
    }      
}