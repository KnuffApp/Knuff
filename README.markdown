# APNS Pusher
A simple debug application for apple push notification service (APNS).

[Download APNS Pusher](https://github.com/blommegard/APNS-Pusher/blob/master/Download/APNS%20Pusher.app.zip "Download") 

## Features
* Send push notifications to APNS (Apple Push Notification Service) very easy (no configuration needed at all)
* Grabs the certificate right from your kechain
* Get the device token autimaticaly via bonjour, no need to log (or similar), usefull when not in sandbox mode
* Support for error response codes
* Development/Production environment
* Custom JSON payload
* Identity export to PEM format

## Usage of automatic token detection
* Copy the files SBAPNSPusher.h/m to your project
* Run the following code in application:didFinishLaunchingWithOptions:
```objc
[SBAPNSPusher start];
```
* Start the app and make sure your on the same wifi

## Screenshots
![Screenshot](https://github.com/blommegard/APNS-Pusher/raw/master/Screenshots/main.png "Main")
![Screenshot](https://github.com/blommegard/APNS-Pusher/raw/master/Screenshots/certificates.png "Certificates")

## Changelog
### 2.2
* The app can now export the identity to PEM format

### 2.1
* Added the ability to automatic get the token from an iOS device on the same network via bonjour

### 2.0
* Support for custom JSON payload

### 1.1
* Initial Release

## License
APNS Pusher is released under the MIT-license (see the LICENSE file)
