import UIKit
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// 1) كلاس AppDelegate لتطبيق UNUserNotificationCenterDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            // تعامل مع granted أو error إذا رغبت
        }
        return true
    }

    // 2) استدعاء عند وصول الإشعار والـ app في الـ foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@main
struct MyApp: App {
    // 3) ربط الـ AppDelegate مع SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // 4) تخزين اللغة والـ dark mode
    @AppStorage("selectedLanguage")
    private var selectedLanguage = Locale
        .current
        .language
        .languageCode?
        .identifier
        ?? "ar"

    @AppStorage("darkModeEnabled") private var darkModeEnabled = true

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            // 5) تفعيل الـ localization بناءً على الاختيار
            .environment(\.locale, .init(identifier: selectedLanguage))
            // 6) إجبار اتجاه الواجهة LTR (مع الحفاظ على نص عربي)
            .environment(\.layoutDirection, .leftToRight)
            // 7) تطبيق الوضع الليلي أو النهاري
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            .onAppear {
                // تأكد من صلاحيات الإشعارات لو لم تُمنح
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }
}
