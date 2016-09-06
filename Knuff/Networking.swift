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
        
        // Start the session
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        // Start the request
        let request = NSMutableURLRequest(URL: url)
        
        // Set the HTTP Header Content Type and Authorisation
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(key)", forHTTPHeaderField: "Authorization")
        
        // Add the Body Data and set the Method to POST
        request.HTTPBody = body
        request.HTTPMethod = "POST"
        
        // Transfer the Session into the DataTask and check if all the data is correct
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            print(data)
            print(response)
            print(error)
            
            // Get the respone for the StatusCode
            if let httpResponse = response as? NSHTTPURLResponse {
                
                print("statusCode: \(httpResponse.statusCode)")
                
                dispatch_async(dispatch_get_main_queue(), { 
                    // Create an Alert Message to show the Status Code, so the user can see if it works
                    let alert = NSAlert()
                    alert.messageText = "Status Code: \(httpResponse.statusCode)"
                    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                    
                    // run the message
                    alert.runModal()
                })
                
            }

        }
        
        // Send the Data
        dataTask.resume()
        
    }

}
