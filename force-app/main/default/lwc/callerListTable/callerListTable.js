import { LightningElement, wire, track, api } from 'lwc';
import getContact from '@salesforce/apex/CallerListTableController.getContacts';
import getVoiceCall from '@salesforce/apex/CallerListTableController.getVoiceCall';
import relateOpp from '@salesforce/apex/CallerListTableController.relateOppWithVoiceCall';
import getCallLog from '@salesforce/apex/CallerListTableController.getRelatedCallLogs';
import getPresenceStatus from '@salesforce/apex/CallerListTableController.getOmniStatus';
import navigateSMSPage from '@salesforce/apex/CallerListTableController.navigateSMSPage';

import NAME from "@salesforce/schema/Opportunity.Name";
import MEMBER from "@salesforce/schema/Opportunity.Auto_Shopper__c";
import DATE from "@salesforce/schema/Opportunity.CloseDate";
import CARD from "@salesforce/schema/Opportunity.Card_Number__c";

import { NavigationMixin } from 'lightning/navigation';  
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';  
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const FIELDS = [
    'Opportunity.Name',
    'Opportunity.Auto_Shopper__c',
    'Opportunity.CloseDate',
    'Opportunity.Card_Number__c',
    // ... other fields you need
];

export default class CallerListTable extends NavigationMixin(LightningElement) {
    @api recordId;
    filterValue = 'Auto Shopper';
    options = [

        { label: "All Contacts", value: "All contacts" },
        { label: "Service Rep", value: "Bank Service Rep" },
        { label: "All Dealer Pro", value: "Auto Dealer Pro" },
        { label: "Member", value: "Auto Shopper" },
        { label: "Recently Called", value: "Recently Called" }
    
    ];
    Contacts;
    Error;
    searchKey;
    phNumber;
    @track contactsToDisplay = [];
    @track voiceCalltoDisplay = [];
    filterContactsList = [];
    showHistoryPage = false;
    isAllContacts = true;
    selectedContactName;
    callLogList=[];
    branchOrDealer;
    opportunity;
    

    @wire(getRecord, { recordId: '$recordId',fields: ['Opportunity.Name', 'Opportunity.Auto_Shopper__c', 'Opportunity.CloseDate', 'Opportunity.Card_Number__c'] })
    wiredOpp(result){
        console.log("result for opp", result);
        if(result.data){
            console.log("data for opp", result.data);
            this.opportunity = result.data;
            if(this.opportunity && this.Contacts){
                this.filterRecords();
            }
        }
        console.log("Completed opp");
    }
   

    @wire(getContact) 
    wiredContacts(result){
        
        console.log("result", result);
            console.log("Contacts", this.Contacts);
            if(result.data){
                console.log('Inside Data');
                this.Contacts = result.data.map(
                    record => 
                       // const accName = record.Account? record.Account.Name: "";
                        
                        Object.assign(
                      { "RecordTypeName": record.RecordType.Name, "AccountName":record.Account? record.Account.Name: "", "AccountPhone":record.Account? record.Account.Phone: "","PhoneNumber":record.Phone? record.Phone:record.MobilePhone, "class": record.Phone? "button-37":record.MobilePhone? "button-37":"button-37 disable-click"  },
                      record
                      )
                    );
                console.log('Accounts==>'+JSON.stringify(this.Contacts));
                console.log('Contacts==>'+this.Contacts);
                console.log('Contacts2==>'+ JSON.parse(JSON.stringify(this.Contacts)) );
                if(this.opportunity && this.Contacts){
                    this.filterRecords();
                }
                
                


                /*
                 this.Contacts = JSON.parse(JSON.stringify(data.data));
               //this.Contacts = data.data;
               var testVar = [ ...this.Contacts]
               console.log("Contacts", this.Contacts);
                console.log("this.Contacts", JSON.parse(JSON.stringify(this.Contacts) ));
                testVar.map(element => {
                console.log("element", element);
                element.Test = element.RecordType.Name;
            });
            console.log("Contacts2", this.Contacts);
            console.log("Contacts2", JSON.stringify(this.Contacts));
            var last = JSON.stringify(this.Contacts);
            console.log("Contacts2", JSON.parse(last ));
            console.log("Contacts2", JSON.parse(JSON.stringify(this.Contacts) ));
*/
        }
        else{
            console.log("Inside No contacts");
            this.showNoRecords = true;
        }
    }

    @wire(getCallLog, { opportunityId: '$recordId'}) 
    wiredCallLogs(result){
        console.log('Call Logs :: ',result);
        if(result.data){
            result.data.map(element => {
                if(!this.callLogList.includes(element.WhoId)){
                    this.callLogList.push(element.WhoId);
                }
            });
        }
        console.log('this.callLogList :: ',JSON.stringify(this.callLogList));
    }

    handleChangeFilter(event){
        console.log("filterValue", (event.target.value));
       // this.filterRecords(event.target.value); 
        this.filterValue = event.target.value;
        if(this.Contacts){
        this.filterRecords(); 
        }
    }

    handleChangeSearch(event){
         this.searchKey = event.target.value;
        console.log("searchKey", this.searchKey);
        console.log("isNaN(searchKey)", isNaN(this.searchKey));
        
        if(isNaN(this.searchKey)){
            console.log("Inside Text");
            this.contactsToDisplay = this.filterContactsList.filter(elem => elem.Name.toLowerCase().includes(this.searchKey.toLowerCase()) || elem.AccountName.toLowerCase().includes(this.searchKey.toLowerCase()) );
        }
       
        else if(isNaN(this.searchKey) === false && this.searchKey != '') {
            console.log("Inside Number");
            console.log("searchKey :: ",this.searchKey);
            this.contactsToDisplay = this.filterContactsList.filter(elem=>{
                console.log(" Phone Phone", elem.Phone);
                console.log(" Account Phone", elem.AccountPhone);
                console.log(" Account", JSON.stringify(elem));

                if(elem.Phone){
                    console.log("Inside Phone");
                    return elem.PhoneNumber.includes(this.searchKey) ;
                }
                
                if(elem.AccountPhone){
                    console.log("Inside Account Phone");
                    return elem.AccountPhone.includes(this.searchKey) ;
                }
            });
            console.log(" elem.Phone.includes(searchKey) ::", JSON.stringify(this.contactsToDisplay)); 
    }
    else{
        this.contactsToDisplay = this.filterContactsList
    }
        console.log("filterValue", this.contactsToDisplay);
    }

    filterRecords(){
        console.log("Inside filterRecords");
        console.log("filterValue", this.filterValue);
        if(this.filterValue == "All contacts"){
            this.isAllContacts = true;
            this.contactsToDisplay = this.Contacts;
            this.filterContactsList =  this.contactsToDisplay;
            this.branchOrDealer = "Dealer/Branch";
            console.log("  this.contactsToDisplay",   this.contactsToDisplay);
        }
        else{
            console.log("Inside else");
            this.isAllContacts = false;
            console.log("Inside else opp",this.opportunity);
            console.log("Inside else Auto Shopper", this.opportunity.fields.Auto_Shopper__c);
            if( this.filterValue == "Auto Shopper"){
                this.contactsToDisplay = this.Contacts.filter(elem => elem.Id == this.opportunity.fields.Auto_Shopper__c.value);
                this.filterContactsList =  this.contactsToDisplay;
                this.branchOrDealer = "Dealer/Branch";
                console.log("Inside Auto Shopper");
            }
            else if( this.filterValue == "Recently Called"){
                this.contactsToDisplay = this.Contacts.filter(elem => this.callLogList.includes(elem.Id));
                console.log(this.callLogList);
                this.contactsToDisplay.sort((a, b) => this.callLogList.indexOf(a.Id) - this.callLogList.indexOf(b.Id));
                this.filterContactsList =  this.contactsToDisplay;
                this.branchOrDealer = "Dealer/Branch";
            }
            else{
                this.contactsToDisplay = this.Contacts.filter(elem => elem.RecordTypeName == this.filterValue);
                this.filterContactsList =  this.contactsToDisplay;
                if(this.filterValue == "Auto Dealer Pro"){
                    this.branchOrDealer = "Dealer";
                }
                else if(this.filterValue == "Bank Service Rep"){
                    this.branchOrDealer = "Branch";
                }
                else{
                    this.branchOrDealer = "Dealer/Branch";
                }
            }

            // this.contactsToDisplay = this.Contacts.map(elem =>{
            //     if(!elem.PhoneNumber){
            //         const button = this.template.querySelector(`button[data-rowid="${elem.Id}"][name="Call"]`);
            //        // button.classList.add('disable-click');
            //     }
            // });
            

            if(this.contactsToDisplay){
                console.log("Inside contacts");
                this.showNoRecords = false;
               // this.filterRecords();
            }
            else{
                console.log("Inside no contacts");
                this.showNoRecords = true;
            }
            
            console.log("Opportunity Details :: ",this.opportunity);
           // console.log("Opportunity Details AutoShoper :: ",this.opportunity.data.fields.Auto_Shopper__c.value);
        }
        if(this.searchKey){
            var eve = {"target": {
                "value": this.searchKey
            }
        }
            this.handleChangeSearch(eve);
        }

    }


    handleViewHistory(event){
        this.showHistoryPage = true;
        console.log("Value:: ",event.target.value);
        this.selectedContactName = this.filterContactsList.find(obj=> obj.Id == event.target.value).Name;
        getVoiceCall({opportunityId:this.recordId, contactId:event.target.value})

    .then((result)=>{
        console.log("result:: ",result);
        this.voiceCalltoDisplay =  result.map(
            record =>{
                const dateObject = new Date(record.CallAcceptDateTime);
                const options = { 
                    day: '2-digit', 
                    month: '2-digit', 
                    year: 'numeric', 
                    hour: '2-digit', 
                    minute: '2-digit', 
                    hour12: false 
                  };
                  
                 // const url = "/"+ record.Id; 
                  const formattedDate = new Intl.DateTimeFormat('en-GB', options).format(dateObject);
                  if(record.CallDurationInSeconds ){
                   
                    const minutesCal = Math.floor(record.CallDurationInSeconds / 60);
                    const secondsCal = record.CallDurationInSeconds % 60;
                    var minutes = `${minutesCal}:${secondsCal < 10 ? '0' : ''}${secondsCal}`;
                  }
                  
                console.log("dateObject:: ",dateObject);
                return Object.assign(
              { "Date": formattedDate, "Minutes": minutes},
              record
              )
             
            });
            
            if(this.voiceCalltoDisplay.length == 0 || this.voiceCalltoDisplay == [] ){
                console.log("Inside 0 length:: ");
                this.showNoRecords = true;
            }
    })
    .catch((error)=>{
        console.log("error:: ",error);
    })

    }
    
    
    handleHomeClick(event){
        this.showHistoryPage = false;
        this.showNoRecords = false;
    }

    handleOpenRecord(event){
        console.log("event.target.value :: ",event.target.value);
        console.log("event.target.value :: ", event.currentTarget.dataset.id);
        this.navigateVoiceCallRecordPage(event.currentTarget.dataset.id);
    }
    // handleMakeCall(event){
    //     console.log('Clicked');
    //     console.log('event:', event);

    //     console.log('event.currentTarget.dataset.id  :::', event.currentTarget.dataset.id);
    //     this.phNumber = event.currentTarget.dataset.id;
    //     console.log("phNumber action",this.phNumber);
    //     console.log("Immediate action",Date.now());

    //     setTimeout(() => {
    //         relateOpp({ recId: this.recordId, phNumber: this.phNumber })
    //         .then((result) => { console.log('Success') })
    //         .catch((error) => { this.error = error })
    //         console.log("delay action",Date.now());
    //       }, 10000);
    //     }
        handleMakeCall(value){
            console.log('Clicked');
            console.log('event:', value);
    
            console.log('event.currentTarget.dataset.id  :::');
            this.phNumber = value;
            console.log("phNumber action",this.phNumber);
            console.log("Immediate action",Date.now());
    
            setTimeout(() => {
                relateOpp({ recId: this.recordId, phNumber: this.phNumber })
                .then((result) => { console.log('Success') })
                .catch((error) => { this.error = error })
                console.log("delay action",Date.now());
              }, 10000);
            }
    

        navigateVoiceCallRecordPage(voiceId){
            console.log("voiceId :: ",voiceId);
            this[NavigationMixin.Navigate]({
               type:'standard__recordPage',
               attributes:{
                  recordId:voiceId,
                 // objectApiName: "VoiceCall",
                  actionName:'view'
               }
            })
           }

           handleCallButtonClick(event) {
            console.log("button html :: ",this.template.querySelector(`button[data-rowid="${event.currentTarget.dataset.rowid}"][name="Call"]`));
            const button = this.template.querySelector(`button[data-rowid="${event.currentTarget.dataset.rowid}"][name="Call"]`);
            button.classList.add('disable-click');

            setTimeout(() => {
                // Show the button after 5 seconds
                button.classList.remove('disable-click');
            }, 3000);

            console.log("event",event);
            console.log("event.target.value",event.target.value);
            console.log("event.currentTarget.dataset.id",event.currentTarget.dataset.id);
            var value = event.currentTarget.dataset.id;
            const clickToDial = this.template.querySelector(`lightning-click-to-dial[data-id="${event.currentTarget.dataset.id}"]`);
            console.log("clickToDial",clickToDial);
            getPresenceStatus()

    .then((result)=>{
        console.log("result:: ",result);   
        if (clickToDial && result == "true") {
            try {
                console.log("event.currentTarget.dataset.id");
            console.log("event.currentTarget.dataset.id",value);
            
            clickToDial.click();
            this.handleMakeCall(value);
           
            console.log("event.currentTarget.dataset.id");
            } catch (error) {
                console.log("error from catch :: ",JSON.stringify(error));
                console.log("error from catch :: ",(error));
                console.log("error from catch :: ",JSON.parse(JSON.stringify(error)));
            }
            
        }
        else{
            if(value == undefined || value == ""){
                const event = new ShowToastEvent({
                    title: 'Check Presence Status',
                    message: 'Phone Number Not Present in the Contact',
                    variant:'info',
                   
                });
                this.dispatchEvent(event);
            }
            else{
            const event = new ShowToastEvent({
                title: 'Check Presence Status',
                message: 'Make Status as Online for call',
                variant:'info',
               
            });
            this.dispatchEvent(event);
        }
        }  
    })
    .catch((error)=>{
        console.log("error from catch :: ",JSON.stringify(error));
        console.log("error from catch :: ",(error));
        console.log("error from catch :: ",JSON.parse(JSON.stringify(error)));
    })

            
            // Trigger the click event programmatically
            
        }
        handleMailButtonClick(event) {
            console.log('email button is Clicked');
            console.log('event.currentTarget.dataset.id',event.currentTarget.dataset.id);
    var pageRef = {
      type: "standard__quickAction",
      attributes: {
        apiName: "Global.SendEmail",
      },
      state: {
        recordId: this.recordId,
        defaultFieldValues: encodeDefaultFieldValues({
        //   HtmlBody: "Pre-populated text for the email body.",
           Subject: this.opportunity.fields.Card_Number__c.value?  `<subject line> - #${this.opportunity.fields.Card_Number__c.value}`:'',
          ToIds: event.currentTarget.dataset.id,
          
        }),
      },
    };

    this[NavigationMixin.Navigate](pageRef);
    console.log('email function completed');
        }
        handleSMSButtonClick(event){
            console.log("button html :: ",this.template.querySelector(`button[data-rowid="${event.currentTarget.dataset.rowid}"][name="SMS"]`));
            const button = this.template.querySelector(`button[data-rowid="${event.currentTarget.dataset.rowid}"][name="SMS"]`);
            button.classList.add('disable-click');

            setTimeout(() => {
                // Show the button after 5 seconds
                button.classList.remove('disable-click');
            }, 3000);

            navigateSMSPage({contactId: event.currentTarget.dataset.id,oppId:this.recordId })
            .then((result)=>{
                console.log("result:: ",result); 
                if(result == 'false'){
                    this.createTost('Check Presence Status', 'Make Status as Online for SMS', 'info');
                }
                else if(result == 'Error'){
                    this.createTost('Error', 'Somting Went Wrong', 'Error');
                }
                else{
                    this[NavigationMixin.Navigate]({
                        type:'standard__recordPage',
                        attributes:{
                           recordId:result,
                           actionName:'view'
                        }
                     })
                }  
                
                
                
            })
            .catch((error)=>{
                console.log("error from catch :: ",JSON.stringify(error));
                console.log("error from catch :: ",(error));
                console.log("error from catch :: ",JSON.parse(JSON.stringify(error)));
            })
        }

        createTost(title, message, variant){
            const event = new ShowToastEvent({
                title: title,
                message: message,
                variant:variant,
               
            });
            this.dispatchEvent(event);
        }
        
}