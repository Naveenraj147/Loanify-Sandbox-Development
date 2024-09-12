public class CryptoUtility {

    // private static final String key = 'F4C789A1B2D3E4F5E6F788A9B0C1D2E3';
    private static final Blob keyBlob = EncodingUtil.base64Decode(Label.ENCRYPTION_KEY);// change it to get the key from custom Label later
    public static String encrypt(String data) {
        if (data!=null) {
            Blob dataBlob = Blob.valueOf(data);
            Blob encryptedBlob = Crypto.encryptWithManagedIV('AES128', keyBlob, dataBlob);
            return EncodingUtil.urlEncode(EncodingUtil.base64Encode(encryptedBlob), 'UTF-8');
            
        }
        return null;
    }

    public static String decrypt(String encryptedData) {
        if(encryptedData!=null){
            system.debug('Url Decode--> '+EncodingUtil.urlDecode(encryptedData, 'UTF-8'));
            // Blob dataBlob = EncodingUtil.base64Decode(EncodingUtil.urlDecode(encryptedData, 'UTF-8'));
            Blob dataBlob =  EncodingUtil.base64Decode(encryptedData);
            Blob decryptedBlob = Crypto.decryptWithManagedIV('AES128', keyBlob, dataBlob);
            return decryptedBlob.toString();
        }
        return null;
    }
}