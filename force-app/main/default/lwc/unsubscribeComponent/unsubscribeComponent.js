import { LightningElement, track, wire } from 'lwc';
import companyLogoFastPass from '@salesforce/resourceUrl/CompanyLogoFastPass';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updatePreferences from '@salesforce/apex/UnsubscribeComponentController.updatePreferences';
import getContactDetails from '@salesforce/apex/UnsubscribeComponentController.getContactDetails';
import getUnsubscribeDetails from '@salesforce/apex/UnsubscribeComponentController.getUnsubscribeDetails';

export default class UnsubscribeComponent extends LightningElement {
    imageUrl = companyLogoFastPass;
    //iconUrl = utilityIcon;

   @track checkboxValue = {SMS:{ all:false, dn:false, cun:false, fpn:false, mn:false},
                    Email:{ all:false, dn:false, cun:false, fpn:false, mn:false}}
    intialValue = {};
    queryParamValue;
    getObjectName;
    isLoading = false;
    showSucessMessage = false;
    isError = false;
    isModalOpen = true;

    get isContact() {
        return this.getObjectName === 'Contact';
    }

    connectedCallback() {
        console.log('inside connected callback ==> ');
        const url = window.location.href;
        const urlObj = new URL(url);
        const params = new URLSearchParams(urlObj.search);
        console.log('params ==> '+params);
        const id = params.get('recId');  
        console.log('Id ==> '+ id);
        console.log('queryParamValue ==> '+ this.queryParamValue);
        this.queryParamValue = id != null? id : this.queryParamValue;
        console.log('queryParamValue ==> '+ this.queryParamValue);
        this.getObjectName = this.getObjectNameFromId(this.queryParamValue);
        if(this.getObjectName == "Account"){
            this.getObjectName = "Contact";
            getContactDetails({ accountId: this.queryParamValue})
                    .then(result => {
                        console.log('Result calling Apex:', result); 
                    })
                    .catch(error => {
                        console.error('Error calling Apex:', error);
                        console.error(JSON.stringify(error));
                    });    
        }
        else{
            var data = {};
            data["recordId"] = this.queryParamValue;
            data["objectName"] = this.getObjectName;
            getUnsubscribeDetails({ data: (JSON.stringify(data))})
                    .then(result => {
                        console.log('Result calling Apex:', result); 
                        this.checkboxValue = JSON.parse(result);
                        this.intialValue = JSON.parse(result);
                        //this.checkboxValue.Email.all = true;
                        console.log(" this.checkboxValue ==> ",  this.checkboxValue);
                        console.log("Test");
                    })
                    .catch(error => {
                        console.error('Error calling Apex:', error);
                        console.error(JSON.stringify(error));
                    });    
        }
    }
 
    handleOnChange(event){
    if((event.target.name).includes("Email")){
        if((event.target.name).includes("All")){
            if(this.getObjectName == "Opportunity"){
                this.checkboxValue.Email.dn = event.target.checked;
                this.checkboxValue.Email.cun = event.target.checked;
                this.checkboxValue.Email.fpn = event.target.checked;
            }
            else{
                this.checkboxValue.Email.mn = event.target.checked;
                this.checkboxValue.Email.fpn = event.target.checked;
            }
            
        }
        else{
            const checkboxName = event.target.name.split('-')[1];
            this.checkboxValue.Email[checkboxName] = event.target.checked;
        }
        if((this.checkboxValue.Email.dn == true &&
            this.checkboxValue.Email.cun == true &&
            this.checkboxValue.Email.fpn == true) || (this.checkboxValue.Email.mn == true &&
            this.checkboxValue.Email.fpn == true)){
                this.checkboxValue.Email.all = true;
        }
        else{
            this.checkboxValue.Email.all = false;
        }
    }
    else if((event.target.name).includes("SMS")){
        if((event.target.name).includes("All")){
            if(this.getObjectName == "Opportunity"){
            this.checkboxValue.SMS.dn = event.target.checked;
            this.checkboxValue.SMS.cun = event.target.checked;
            this.checkboxValue.SMS.fpn = event.target.checked;
            }
            else{
            this.checkboxValue.SMS.mn = event.target.checked;
            this.checkboxValue.SMS.fpn = event.target.checked;
                
            }
        }
        else{
            const checkboxName = event.target.name.split('-')[1];
            this.checkboxValue.SMS[checkboxName] = event.target.checked;
        }
        if((this.checkboxValue.SMS.dn == true &&
            this.checkboxValue.SMS.cun == true &&
            this.checkboxValue.SMS.fpn == true) || (this.checkboxValue.SMS.mn == true &&
            this.checkboxValue.SMS.fpn == true)){
                this.checkboxValue.SMS.all = true;
        }
        else{
            this.checkboxValue.SMS.all = false;
        }
    }
    console.log("checkboxValue ==> ",JSON.parse(JSON.stringify(this.checkboxValue)));
    console.log("checkboxValue ==> ",(JSON.stringify(this.checkboxValue)));
}
OBJECT_PREFIX_MAP = {
    '003': 'Contact',
    '006': 'Opportunity',
    '001': 'Account'
};
getObjectNameFromId(recordId) {
    if (!recordId || recordId.length < 3) {
        return null;
    }
    const prefix = recordId.substring(0, 3);
    return this.OBJECT_PREFIX_MAP[prefix] || 'Unknown Object';
}

handleClick() {
        console.log('Inside Button Click');
        let isChecked = this.checkAnyTrue(this.checkboxValue); 
        if(isChecked){
            this.isLoading = true;   
            this.checkboxValue["recordId"] = this.queryParamValue;
            this.checkboxValue["objectName"] = this.getObjectName;
        
            updatePreferences({ data: JSON.stringify(this.checkboxValue)})
                .then(result => {
                    console.log('Result calling Apex:', result); 
                    if(result == 'Success'){
                        this.isLoading = false;
                        this.showSucessMessage = true;
                    }   
                })
                .catch(error => {
                    console.error('Error calling Apex:', error);
                    console.error('Error calling Apex:', error);
                    console.error(JSON.stringify(error));
                });     
        }
        else{
            this.isError = true;
        setTimeout(() => {
       this.isError = false;
   }, 2000);
        }
        
    }
checkAnyTrue(obj) {

    let SMS_1 = JSON.stringify(obj.SMS);
    let SMS_2 = JSON.stringify(this.intialValue.SMS);
    let Email_1 = JSON.stringify(obj.Email);
    let Email_2 = JSON.stringify(this.intialValue.Email);
    
    return Email_1 !== Email_2 || SMS_1 !== SMS_2;
}

}