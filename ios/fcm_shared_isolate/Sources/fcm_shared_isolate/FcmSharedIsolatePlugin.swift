import Flutter
import FirebaseCore
import FirebaseMessaging

@objc public class FcmSharedIsolatePlugin: NSObject, FlutterPlugin, MessagingDelegate {
    internal init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fcm_shared_isolate", binaryMessenger: registrar.messenger())
        let instance = FcmSharedIsolatePlugin(channel: channel)
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
        UNUserNotificationCenter.current().delegate = instance
    }

    let channel: FlutterMethodChannel
    private var pendingTokenResults: [FlutterResult] = []

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getToken":
            Messaging.messaging().delegate = self
            // FCM fails with error 505 until APNs has delivered the device token.
            if Messaging.messaging().apnsToken == nil {
                pendingTokenResults.append(result)
                UIApplication.shared.registerForRemoteNotifications()
                return
            }
            fetchToken(result)
        case "requestPermission":
            let arguments = call.arguments as! NSDictionary;
            if #available(iOS 10.0, *) {
                var authOptions: UNAuthorizationOptions = []
                if arguments["sound"] as! Bool {
                    authOptions.insert(.sound)
                }
                if arguments["alert"] as! Bool {
                    authOptions.insert(.alert)
                }
                if arguments["badge"] as! Bool {
                    authOptions.insert(.badge)
                }
                if arguments["provisional"] as! Bool {
                    if #available(iOS 12.0, *) {
                        authOptions.insert(.provisional)
                    }
                }

                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { [] granted, error in
                        if let error = error {
                            result(FlutterError(code: "perm", message: nil, details: error.localizedDescription))
                            return
                        }

                        result(granted)
                    }
                )

                UIApplication.shared.registerForRemoteNotifications()
                Messaging.messaging().delegate = self
            } else {
                var notificationTypes: UIUserNotificationType = []
                if arguments["sound"] as! Bool {
                    notificationTypes.insert(.sound)
                }
                if arguments["alert"] as! Bool {
                    notificationTypes.insert(.alert)
                }
                if arguments["badge"] as! Bool {
                    notificationTypes.insert(.badge)
                }

                let settings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)

                UIApplication.shared.registerForRemoteNotifications()

                result(true)
            }
        default:
            assertionFailure(call.method)
            result(FlutterMethodNotImplemented)
        }
    }

    private func fetchToken(_ result: @escaping FlutterResult) {
        Messaging.messaging().token { token, error in
            if let error = error {
                result(FcmSharedIsolatePlugin.flutterError(error))
            } else {
                result(token.map { String($0) })
            }
        }
    }

    private static func flutterError(_ error: Error) -> FlutterError {
        let nsError = error as NSError
        return FlutterError(code: "unknown/\(nsError.domain)/\(nsError.code)", message: error.localizedDescription, details: nsError.userInfo.description)
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let results = pendingTokenResults
        pendingTokenResults.removeAll()
        if results.isEmpty { return }
        fetchToken { value in results.forEach { $0(value) } }
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let results = pendingTokenResults
        pendingTokenResults.removeAll()
        results.forEach { $0(FcmSharedIsolatePlugin.flutterError(error)) }
    }

    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken token: String?) {
        channel.invokeMethod("token", arguments: token)
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if userInfo["google.c.sender.id"] != nil {
            channel.invokeMethod("message", arguments: userInfo)
        }
    }
}
