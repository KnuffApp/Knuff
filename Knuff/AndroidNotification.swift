//
//  AndroidNotification.swift
//  Knuff
//
//  Created by Detar Zyberi on 08.08.16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

import Cocoa
import Fragaria

struct FCMMessage {
    var registration_ids : [String]?
}

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
        
    
        // Get the Authorisation Key and turn it into a String
        let key = authorisationTextField.stringValue
        
        // If the key is empty show an Alert Message and stop the Function
        if key == "" {
            print("leerer key")
            attentionAlert("Please insert an authorisation key", title: "Attention")
            return
        }
        
        // Get the Payload from the View, make it a String and put it into a Constant
        let jsonString = payloadFragaria.string
        
        // If the Json String empty, show an alert message
        if jsonString == "" {
            attentionAlert("Your Payload is empty", title: "Attention")
            return
        }
        print(jsonString)
        
        // Turn the Json String into NSData
        guard let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {return}
        
        // Check if is the Json Payload valid
        guard var jsonObject: [String: AnyObject]  = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String : AnyObject] else {
            //TODO: Inform user that json format is invalid.
            attentionAlert("Your json is invalid", title: "Attention")
            return
        }
        
        // If the Token TextField is empty, show an Alert Message
        if tokenTextField.stringValue == "" {
            attentionAlert("Please enter a token", title: "Attention")
            return
        }
        
        let message = FCMMessage(registration_ids: tokenTextField.stringValue.componentsSeparatedByString(","))
        print("message: \(message)")
        
        // Add the token to the JsonObject
        jsonObject["registration_ids"] = message.registration_ids
        
        print("jsonObject: \(jsonObject)")
        
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
        
        // Put the URL for the Notification into a Constant
        guard let url = NSURL(string: "https://fcm.googleapis.com/fcm/send") else {return}
        
        // Start the function to send the Data
        Networking.sendPushNotification(url, key: key, body: jsonData)
        
    }
    
    
    // Alert function
    func attentionAlert(message: String, title: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.window.title = title
        alert.addButtonWithTitle("OK")
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        alert.runModal()
    }
}






