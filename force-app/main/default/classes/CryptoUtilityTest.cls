@isTest
public class CryptoUtilityTest {
 @isTest
    static void dotest(){
        System.Debug(CryptoUtility.encrypt('Test String'));
         System.Debug(CryptoUtility.decrypt(EncodingUtil.urlDecode(CryptoUtility.encrypt('Test String'), 'UTF-8'))); //.replaceAll('%', 'x')
    }
}