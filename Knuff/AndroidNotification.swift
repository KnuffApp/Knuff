//
//  AndroidNotification.swift
//  Knuff
//
//  Created by Detar Zyberi on 08.08.16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

import Cocoa
import Fragaria

class AndroidNotification: NSViewController, MGSFragariaTextViewDelegate, MGSDragOperationDelegate {
    
    @IBOutlet weak var payloadFragaria: MGSFragariaView!
    @IBOutlet weak var authorisationTextField: NSTextField!
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var payloadTextField: NSTextField!
    @IBAction func sendButton(sender: AnyObject) {
        getDataFromView()
    }
    
    override func viewDidLoad() {
        
        let payload = "{\n\t\"notification\":{\n\t\t\"title\":\"Test\",\n\t\t\"text\":\"default\"\n\t}\n}"
        
        payloadFragaria.syntaxColoured = true
        payloadFragaria.showsLineNumbers = true
        payloadFragaria.syntaxDefinitionName = "JavaScript"
        payloadFragaria.textViewDelegate = self
        
        payloadFragaria.string = payload
        
    }
    
    
    
    
    func getDataFromView() {
        print("push send Button!!")
        
    
        // constat for the Authorisation Key and make it to a string
        let key = authorisationTextField.stringValue
        
        // if the key empty show a alert message and stop the function
        if key == "" {
            print("leerer key")
            attentionAlert("Pls leave a Authorisation key", title: "Attention")
            return
        }
        
        // get the payload from the view, make it a string and put it a Constant
        let jsonString = payloadFragaria.string
        
        // if the jsonString empty show a alert message
        if jsonString == "" {
            attentionAlert("Your Payload is empty", title: "Attention")
            return
        }
        print(jsonString)
        
        // make the jsonString to type NSData
        guard let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {return}
        
        // chech it if is the json payload valid
        guard var jsonObject: [String: AnyObject]  = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String : AnyObject] else {
            //TODO: Inform user that json format is invalid.
            attentionAlert("Your json is invalid", title: "Attention")
            return
        }
        
        // if the Token text field empty show a alert message
        if tokenTextField.stringValue == "" {
            attentionAlert("Pls leave a Token", title: "Attention")
            return
        }
        
        let message = FCMMessage(registration_ids: tokenTextField.stringValue.componentsSeparatedByString(","))
        print("message: \(message)")
        
        // add the token in the jsonObject
        jsonObject["registration_ids"] = message.registration_ids
        
        print("jsonObject: \(jsonObject)")
        
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
        
        // put the URL for the Notification in a Constant
        guard let url = NSURL(string: "https://fcm.googleapis.com/fcm/send") else {return}
        
        // start function to send the Data
        Networking.sendPushNotification(url, key: key, body: jsonData)
        
    }
    
    
    // alert function
    func attentionAlert(message: String, title: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.window.title = title
        alert.addButtonWithTitle("go back")
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        alert.runModal()
    }
}

struct FCMMessage {
    var registration_ids : [String]?
}

// um designen !!!



