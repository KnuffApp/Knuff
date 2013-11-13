# APNS Pusher
A simple debug application for apple push notification service (APNS).

[Download the latest version](https://github.com/blommegard/APNS-Pusher/releases "Download") 

## Features
* Send push notifications to APNS (Apple Push Notification Service) very easy (no configuration needed at all)
* Grabs the certificate right from your kechain
* Get the device token autimaticaly via bonjour, no need to log (or similar), usefull when not in sandbox mode
* Support for error response codes
* Development/Production environment
* Custom JSON payload
* Identity export to PEM format

## Usage of automatic token detection (iOS6+)
* Copy the files SBAPNSPusher.h/m to your project
* …or use [Cocoapods](http://cocoapods.org/):
 ```ruby
pod "SBAPNSPusher", "~> 2.2.1"
 ```

* Run the following code in ```application:didFinishLaunchingWithOptions:```

 ```objective-c
[SBAPNSPusher start];
 ```

* Start the app and make sure your on the same wifi

## Screenshots
![Screenshot](https://github.com/blommegard/APNS-Pusher/raw/master/Screenshots/main.png "Main")
![Screenshot](https://github.com/blommegard/APNS-Pusher/raw/master/Screenshots/certificates.png "Certificates")


## License
APNS Pusher is released under the MIT-license (see the LICENSE file)
