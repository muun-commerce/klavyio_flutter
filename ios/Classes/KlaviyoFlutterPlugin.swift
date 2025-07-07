import UIKit
import Flutter
import KlaviyoSwift

/// A class that receives and handles calls from Flutter to complete the payment.
public class KlaviyoFlutterPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate, FlutterStreamHandler {
  private static let methodChannelName = "com.rightbite.denisr/klaviyo"
  private static let eventChannelName = "com.rightbite.denisr/klaviyo_push_stream"
    
  private let METHOD_UPDATE_PROFILE = "updateProfile"
  private let METHOD_INITIALIZE = "initialize"
  private let METHOD_SEND_TOKEN = "sendTokenToKlaviyo"
  private let METHOD_LOG_EVENT = "logEvent"
  private let METHOD_HANDLE_PUSH = "handlePush"
  private let METHOD_GET_EXTERNAL_ID = "getExternalId"
  private let METHOD_RESET_PROFILE = "resetProfile"

  private let METHOD_SET_EMAIL = "setEmail"
  private let METHOD_GET_EMAIL = "getEmail"
  private let METHOD_SET_PHONE_NUMBER = "setPhoneNumber"
  private let METHOD_GET_PHONE_NUMBER = "getPhoneNumber"
  private let METHOD_CLEAR_BADGE = "clearBadge"

  private let klaviyo = KlaviyoSDK()
  private var eventSink: FlutterEventSink?
  // Add a queue to store notifications received before Flutter is ready
  private var pendingNotifications: [[String: Any]] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    let instance = KlaviyoFlutterPlugin()

    // Setup event channel for push notification stream
    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
    eventChannel.setStreamHandler(instance)

    if #available(OSX 10.14, *) {
        let center = UNUserNotificationCenter.current()
        center.delegate = instance
    }

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // Helper function to parse and send notification data to Flutter
  private func sendNotificationToFlutter(userInfo: [AnyHashable: Any]) {
    if let eventSink = self.eventSink {
      // Convert userInfo to a JSON string
      if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
         let jsonString = String(data: jsonData, encoding: .utf8) {
        eventSink(jsonString)
      }
    } else {
      // If eventSink is not ready, store the notification for later
      pendingNotifications.append(userInfo as? [String: Any] ?? [:])
    }
  }

  // below method will be called when the user interacts with the push notification
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    // decrement the badge count on the app icon
    if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(UIApplication.shared.applicationIconBadgeNumber - 1)
    } else {
        UIApplication.shared.applicationIconBadgeNumber -= 1
    }

    // Extract notification data
    var userInfo = response.notification.request.content.userInfo
    userInfo["source"] = "interaction"
    
    // Use the helper function to send or queue the notification
    sendNotificationToFlutter(userInfo: userInfo)
    
    completionHandler()
  }

  // below method is called when the app receives push notifications when the app is the foreground
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
     // Extract notification data
     var userInfo = notification.request.content.userInfo
     userInfo["source"] = "foreground"
     
     // Use the helper function to send or queue the notification
     sendNotificationToFlutter(userInfo: userInfo)
     
     var options: UNNotificationPresentationOptions =  [.alert]
     if #available(iOS 14.0, *) {
       options = [.list, .banner]
     }
     // Disable banners
     completionHandler([])
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
        case METHOD_INITIALIZE:
          let arguments = call.arguments as! [String: Any]
          klaviyo.initialize(with: arguments["apiKey"] as! String)
          result("Klaviyo initialized")

        case METHOD_SEND_TOKEN:
          let arguments = call.arguments as! [String: Any]
          let tokenData = arguments["token"] as! String
          klaviyo.set(pushToken: Data(hexString: tokenData))
          result("Token sent to Klaviyo")

        case METHOD_UPDATE_PROFILE:
          let arguments = call.arguments as! [String: Any]
          // parsing location
          let address1 = arguments["address1"] as? String
          let address2 = arguments["address2"] as? String
          let latitude = (arguments["latitude"] as? String)?.toDouble
          let longitude = (arguments["longitude"] as? String)?.toDouble
          let region = arguments["region"] as? String
        
          var location: Profile.Location?
        
          if(address1 != nil && address2 != nil && latitude != nil && longitude != nil && region != nil) {
            location = Profile.Location(
                address1: address1,
                address2: address2,
                latitude: latitude,
                longitude: longitude,
                region: region)
          }
        
        
          let profile = Profile(
            email: arguments["email"] as? String,
            phoneNumber: arguments["phone_number"] as? String,
            externalId: arguments["external_id"] as? String,
            firstName: arguments["first_name"] as? String,
            lastName: arguments["last_name"] as? String,
            organization: arguments["organization"] as? String,
            title: arguments["title"] as? String,
            image: arguments["image"] as? String,
            location: location,
            properties: arguments["properties"] as? [String:Any]
            )
          klaviyo.set(profile: profile)
          result("Profile updated")

        case METHOD_LOG_EVENT:
          let arguments = call.arguments as! [String: Any]
          let event = Event(
            name: .customEvent(arguments["name"] as! String),
            properties: arguments["metaData"] as? [String: Any])

          klaviyo.create(event: event)
          result("Event: [\(event)] created")
        
        case METHOD_HANDLE_PUSH:
          let arguments = call.arguments as! [String: Any]

          if let properties = arguments["message"] as? [String: Any],
            let _ = properties["_k"] {
              klaviyo.create(event: Event(name: .customEvent("$opened_push"), properties: properties))
              
              // Clear badge number completely when push notification is opened
              if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(0)
              } else {
                UIApplication.shared.applicationIconBadgeNumber = 0
              }

              return result(true)
          }
          result(false)

        case METHOD_GET_EXTERNAL_ID:
          result(klaviyo.externalId)

        case METHOD_RESET_PROFILE:
          klaviyo.resetProfile()
          result(true)

        case METHOD_GET_EMAIL:
          result(klaviyo.email)

        case METHOD_GET_PHONE_NUMBER:
          result(klaviyo.phoneNumber)

        case METHOD_SET_EMAIL:
          let arguments = call.arguments as! [String: Any]
          klaviyo.set(email: arguments["email"] as! String)
          result("Email updated")

        case METHOD_SET_PHONE_NUMBER:
          let arguments = call.arguments as! [String: Any]
          klaviyo.set(phoneNumber: arguments["phoneNumber"] as! String)
          result("Phone updated")

        case METHOD_CLEAR_BADGE:
          if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
          } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
          }
          result("Badge cleared")

        default:
          result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterStreamHandler
  
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    
    // Process any pending notifications now that Flutter is ready
    if !pendingNotifications.isEmpty {
      for userInfo in pendingNotifications {
        if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
           let jsonString = String(data: jsonData, encoding: .utf8) {
          events(jsonString)
        }
      }
      // Clear the queue after processing
      pendingNotifications.removeAll()
    }
    
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}

extension String {
    var toDouble: Double {
        return Double(self) ?? 0.0
    }
}

extension Data {
    init(hexString: String) {
        self = hexString
            .dropFirst(hexString.hasPrefix("0x") ? 2 : 0)
            .compactMap { $0.hexDigitValue.map { UInt8($0) } }
            .reduce(into: (data: Data(capacity: hexString.count / 2), byte: nil as UInt8?)) { partialResult, nibble in
                if let p = partialResult.byte {
                    partialResult.data.append(p + nibble)
                    partialResult.byte = nil
                } else {
                    partialResult.byte = nibble << 4
                }
            }.data
    }
}
