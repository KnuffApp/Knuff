# Knuff
The debug application for Apple Push Notification Service (APNs).

[Download the latest version](https://github.com/KnuffApp/Knuff/releases "Download")

![knuff-preview](https://cloud.githubusercontent.com/assets/499192/12481271/36b610e0-c048-11e5-9be6-ee9e996036a2.png)

## Features
* Send push notifications to APNS (Apple Push Notification Service) very easily (no configuration needed at all)
* Load / Save documents including token and JSON payload
* Grabs the certificate right from your keychain
* Get the device token automatically; forget about manually retrieving the device token through logging or similar techniques. Even more useful when not in sandbox mode
* Support for error response codes
* Detects Development/Production environment automatically
* Supports universal certificates
* Custom JSON payloads
* Identity export to PEM format (⌘ + E)

## Knuff iOS App

We created an iOS companion app to make it even easier to get up and running with APNs, download it from the [App Store](https://itunes.apple.com/us/app/knuff-the-apns-debug-tool/id993435856).

## Usage of automatic token detection (iOS8+)

To use this feature with your own apps, have a look at [Knuff-Framework](https://github.com/KnuffApp/Knuff-Framework)

## System Requirements

Due to the usage of the HTTP/2 protocol, Knuff only supports OS X El Capitan 10.11+

## License

Knuff is licensed under [The MIT License (MIT)](LICENSE).

## More Info

Have a question? Please [open an issue](https://github.com/KnuffApp/Knuff/issues/new)!
