import { LightningElement, api } from 'lwc';

export default class ChatPortalComponent extends LightningElement {
    @api portalType = 'Advisor';
    vfRoot = "https://nvn-dev-ed--c.develop.vf.force.com/";
handleIframeLoad() {

    console.log("iframe loaded");
    var vfWindow = this.template.querySelector("iframe").contentWindow;
    vfWindow.postMessage(this.recordId, this.vfRoot);
    
    console.log("iframe load completed");
    
    
    
    }
        
   
}