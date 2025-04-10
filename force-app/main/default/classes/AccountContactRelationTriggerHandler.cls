public class AccountContactRelationTriggerHandler {

    public static void onAfterInsert(List<AccountContactRelation> acrList){
        AccountContactRelationTriggerHelper.handleNewContactRelation(acrList);

    }
    public static void onAfterUpdate(List<AccountContactRelation> acrList, Map<Id, AccountContactRelation> oldACRMap){
        AccountContactRelationTriggerHelper.handleContactRelationUpdate(acrList, oldACRMap);

    }

}