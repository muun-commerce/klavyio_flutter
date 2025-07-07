# Customized Klaviyo Flutter implementation

This repository contains a modified version of [klaviyo_flutter](https://github.com/drybnikov/klaviyo_flutter) that handles iOS push notifications, deep links, and more.

### Changes
- Added a Flutter stream gate for iOS push notifications to catch foreground and interaction messages.
- Blocked Klaviyo deep link handling due to incompatibilities with the go_router package.
- Added $opened_event dispatching on the Flutter side, which is handled by foreground and interaction handlers.
- There are no changes to the Android side.

**Note**: This is a work in progress, and more code is expected.

---

# Changelog

## 0.1.4

* Update project to support Android SDK 35 and tooling, thanks @sn1cka

## 0.1.3

* Added Namespace declaration for Android Gradle Plugin compatibility, thanks @Codel1417

## 0.1.2

* Updated Android SDK to 3.0.0, Updated iOS SDK to 4.0.0

## 0.1.1

* Use correct Klaviyo notification key for Android

## 0.1.0

* Updated Android SDK to 2.2.1, Updated iOS SDK to 3.0.4

## 0.0.4+1

* Improved sending events in Android and iOS

## 0.0.3+1

* Updated Android SDK to 1.3.4, Updated iOS SDK to 2.2.1

## 0.0.2+3

* Fix for option properties in Android, Updated Android SDK to 1.1.1

## 0.0.2+2

* Fix for sending properties to Klaviyo API via Android

## 0.0.2+1

* Fix for sending properties to Klaviyo API, empty string in phone number caused an issue
* Added missing properties: `organization`, `title`, `image` and `properties`

## 0.0.1+7

* Updated Android SDK to 1.1.0, null checks

## 0.0.1+6

* Implemented `setEmail`, `getEmail`, `setPhoneNumber`, `getPhoneNumber` on both Android and iOS

## 0.0.1+5

* Added iOS extension to tracking push notifications to fixed issue #1

## 0.0.1+4

* Implemented `getExternalId`, `resetProfile` on both Android and iOS

## 0.0.1+3

* Implemented `isInitialized`, `isKlaviyoPush`
* Updated Android SDK to 1.0.1

## 0.0.1+2

* Implemented `handlePush` on both Android and iOS
* Updated `updateProfile` on iOS

## 0.0.1+1

* Implemented `updateProfile`, `initialize`, `sendTokenToKlaviyo`, `logEvent` on both Android and iOS
