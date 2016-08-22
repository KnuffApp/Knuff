//
//  Networking.swift
//  Knuff
//
//  Created by Detar Zyberi on 17.08.16.
//  Copyright © 2016 Bowtie. All rights reserved.
//

import Cocoa

class Networking {
    
    internal static func sendPushNotification(url: NSURL, key: String, body: NSData) {
        
        // start session
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        // start request
        let request = NSMutableURLRequest(URL: url)
        
        // set Http Header Content typ and Authorisation
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(key)", forHTTPHeaderField: "Authorization")
        
        // set the body with all the data and set Method to POST
        request.HTTPBody = body
        request.HTTPMethod = "POST"
        
        // transfer the session in the dataTask and check if all the data is correct
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            print(data)
            print(response)
            print(error)
            
            // get the respone for the statusCode
            if let httpResponse = response as? NSHTTPURLResponse {
                
                print("statusCode: \(httpResponse.statusCode)")
                
                dispatch_async(dispatch_get_main_queue(), { 
                    // message to show the status code, so the user can see if it works
                    let alert = NSAlert()
                    alert.messageText = "Status Code: \(httpResponse.statusCode)"
                    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                    
                    // run the message
                    alert.runModal()
                })
                
            }

        }
        
        // send the data
        dataTask.resume()
        
    }

}
