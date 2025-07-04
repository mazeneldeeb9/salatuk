

import SwiftUI
import UIKit
import AVFoundation
import Foundation
import CoreLocation
import UserNotifications
import AudioToolbox
import MapKit

//import Adhan

// أعلى ContentView.swift، قبل:
// struct ContentView: View { … }



// MARK: - LocationManager (with Heading)
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var placemark: CLPlacemark?
    @Published var heading: CLHeading?

    private let manager = CLLocationManager()

    // ← هنا نضيف authStatus
    var authStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return manager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = kCLHeadingFilterNone
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if location == nil, let loc = locations.last {
            DispatchQueue.main.async { self.location = loc }
            CLGeocoder().reverseGeocodeLocation(loc) { places, _ in
                if let place = places?.first {
                    DispatchQueue.main.async { self.placemark = place }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async { self.heading = newHeading }
    }
}
// MARK: - Bearing Calculation
private let kaabaLatitude  = 21.4225
private let kaabaLongitude = 39.8262

extension Double {
    func toRadians() -> Double { self * .pi / 180 }
    func toDegrees() -> Double { self * 180 / .pi }
}

extension Color {
    static let slateGray = Color(
        red:   113/255,
        green: 125/255,
        blue:  125/255
    )
}

func qiblaBearing(from loc: CLLocation) -> CLLocationDirection {
    let φ1 = loc.coordinate.latitude.toRadians()
    let λ1 = loc.coordinate.longitude.toRadians()
    let φ2 = kaabaLatitude.toRadians()
    let λ2 = kaabaLongitude.toRadians()
    let Δλ = λ2 - λ1
    let y = sin(Δλ) * cos(φ2)
    let x = cos(φ1)*sin(φ2) - sin(φ1)*cos(φ2)*cos(Δλ)
    let θ = atan2(y, x).toDegrees()
    return fmod(θ + 360, 360)
}

// MARK: - CompassView
struct CompassView: View {
    let heading: CLLocationDirection?
    let bearing: CLLocationDirection?
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 80, height: 80)
            ForEach(0..<12) { i in
                Capsule()
                    .fill(Color.black)
                    .frame(width: 2.0, height: i % 3 == 0 ? 10 : 5)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            Image(systemName: "arrowtriangle.up.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 20)
                .foregroundColor(.red)
                .offset(y: -9)
                .rotationEffect(.degrees(rotationAngle))
            Circle()
                .fill(isAligned ? Color.green : Color.white)
                .frame(width: 4, height: 4)
                .scaleEffect(pulse ? 1.5 : 1)
                .opacity(pulse ? 0.5 : 1)
                .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
        }
        .frame(width: 80, height: 60)
        .onAppear { pulse = true }
        .onChange(of: isAligned) { aligned in
            if aligned {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var rotationAngle: Double {
        guard let h = heading, let b = bearing else { return 0 }
        return b - h
    }

    private var isAligned: Bool {
        guard let h = heading, let b = bearing else { return false }
        let diff = abs((b - h + 360).truncatingRemainder(dividingBy: 360))
        return diff <= 5 || diff >= 355
    }
}

// MARK: - EnhancedCompassView


struct EnhancedCompassView: View {
    let heading: CLLocationDirection?
    let bearing: CLLocationDirection?
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0

    let gradientColors = Gradient(colors: [
        Color(red: 0.1, green: 0.4, blue: 0.6),
        Color(red: 0.2, green: 0.4, blue: 0.4),
        Color.blue,
        Color(red: 0.4, green: 0.4, blue: 0.4),
        Color(red: 0.1, green: 0.4, blue: 0.6)
    ])








var body: some View {
    ZStack {
        // الخلفية
        Circle()
            .fill(
                AngularGradient(
                    gradient: gradientColors,
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                )
            )
            .frame(width: 70, height: 70)
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            .shadow(color: Color.blue.opacity(0.4), radius: glowIntensity * 5)

        // الاتجاهات
        ForEach(0..<36) { i in
            if i % 9 == 0 {
                CompassDirectionMark(index: i)
            } else {
                Capsule()
                    .fill(i % 3 == 0 ? Color.white : Color.white.opacity(0.7))
                    .frame(width: i % 3 == 0 ? 1.2 : 0.8, height: i % 3 == 0 ? 5 : 3)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(i) * 10))
            }
        }

        // السهم الأحمر
        Image(systemName: "location.north.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 17, height: 17)
            .foregroundColor(.red)
            .rotationEffect(.degrees(rotationAngle))
            .shadow(color: .red, radius: glowIntensity * 3)

        // الكعبة بالأعلى
        VStack {
            Text("🕋")
                .font(.system(size: 16))
                .padding(.bottom, 32)
            Spacer()
        }

        // المركز النابض
        Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .fill(isAligned ? Color.green : Color.white)
                    .frame(width: 6, height: 6)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            )
    }
    .frame(width: 80, height: 80)
    .offset(x: 10)
    .onAppear {
        pulseScale = 1.2
        animateGlow()
    }
.onChange(of: isAligned) { aligned in
    if aligned {
        // UINotificationFeedbackGenerator() تم حذفه عشان ما يصير هزاز
        animateGlow()
    }
}
}

    private var rotationAngle: Double {
        guard let h = heading, let b = bearing else { return 0 }
        return b - h
    }

    private var isAligned: Bool {
        guard let h = heading, let b = bearing else { return false }
        let diff = abs((b - h + 360).truncatingRemainder(dividingBy: 360))
        return diff <= 3 || diff >= 357
    }

    private func animateGlow() {
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever()) {
            glowIntensity = isAligned ? 1 : 0.3
        }
    }

    @ViewBuilder
    private func CompassDirectionMark(index: Int) -> some View {
        VStack {
            Text(directionLetter(for: index))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2.5)

            Capsule()
                .fill(Color.white)
                .frame(width: 2.5, height: 10)
                .offset(y: -3)
        }
        .offset(y: -42)
        .rotationEffect(.degrees(Double(index) * 10))
    }

    private func directionLetter(for index: Int) -> String {
        switch index {
        case 0: return "N"
        case 9: return "E"
        case 18: return "S"
        case 27: return "W"
        default: return ""
        }
    }
}
// MARK: - Prayer Times Models & Service
struct Timings: Codable {
    let fajr: String
    let sunrise: String      // ← أضف هذا السطر
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    private enum CodingKeys: String, CodingKey {
        case fajr     = "Fajr"
        case sunrise  = "Sunrise"   // ← أضف هذا السطر
        case dhuhr    = "Dhuhr"
        case asr      = "Asr"
        case maghrib  = "Maghrib"
        case isha     = "Isha"
    }
}
struct CoordinatesPrayerResponse: Codable { let data: CoordinateData }
struct CoordinateData: Codable { let timings: Timings; let date: DateInfo? }
struct DateInfo: Codable { let gregorian: Gregorian }
struct Gregorian: Codable { let day: String, month: Month, year: String }
struct Month: Codable { let number: Int }

class PrayerTimesService {
    static let shared = PrayerTimesService()
    private let baseCoordURL = "https://api.aladhan.com/v1/timings"

    func getPrayerTimesByCoordinates(latitude: Double,
                                     longitude: Double,
                                     completion: @escaping (Result<Timings, Error>) -> Void) {
        var comps = URLComponents(string: baseCoordURL)!
        comps.queryItems = [
            URLQueryItem(name: "latitude",  value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "method",    value: "2")
        ]
        URLSession.shared.dataTask(with: comps.url!) { data, _, err in
            if let e = err { return completion(.failure(e)) }
            guard let d = data else {
                let noData = NSError(domain: "", code: -1,
                                     userInfo: [NSLocalizedDescriptionKey:"No data"])
                return completion(.failure(noData))
            }
            do {
                let resp = try JSONDecoder().decode(CoordinatesPrayerResponse.self, from: d)
                completion(.success(resp.data.timings))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - SoundPlayer & ButtonStyle
class SoundPlayer {
    static let shared = SoundPlayer()
    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        let session = AVAudioSession.sharedInstance()
        // نجعل الصوت يتبع وضع الصامت
        try? session.setCategory(.soloAmbient, mode: .default, options: [])
        try? session.setActive(true)

        ["click","counter","complete"].forEach {
            if let url = Bundle.main.url(forResource: $0, withExtension: "mp3"),
               let p   = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                players[$0] = p
            }
        }
    }

    func play(_ sound: String) {
        guard let p = players[sound] else { return }
        p.currentTime = 0
        p.play()
    }
}

struct SoundButtonStyle: ButtonStyle {
    @AppStorage("soundEnabled")  private var soundEnabled  = false
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { pressed in
                guard pressed else { return }
                if soundEnabled  { SoundPlayer.shared.play("click") }
                if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
    }
}
// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Dhikr Model & ActivityView

struct Dhikr: Identifiable, Codable {
    var id = UUID()
    var text: String
    var repetition: Int
    var note: String?
}
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
// MARK: - ClockView (static, 12-hour)
struct ClockView: View {
    private let now = Date()
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        f.amSymbol = "ص"
        f.pmSymbol = "م"
        return f
    }()

    var body: some View {
        Text(formatter.string(from: now))
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(.blue)
    }
}



// MARK: - ContentView


// MARK: - Offline Prayer Times Service
//هنا سنه




/// نموذج لتمثيل أوقات الصلاة كنصوص بصيغة "HH:mm"





class PrayerTimesServiceOffline: NSObject, CLLocationManagerDelegate {
    static let shared = PrayerTimesServiceOffline()
    private let locationManager = CLLocationManager()
    private var completion: ((Timings) -> Void)?
    private var calculationDate: Date = Date()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }

    func getPrayerTimes(date: Date = Date(),
                        completion: @escaping (Timings) -> Void) {
        self.completion = completion
        self.calculationDate = date
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let loc = locations.last else { return }

        let timings = calculateTimings(
            latitude:  loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            date:      calculationDate
        )
        completion?(timings)
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        let defaultLat = 35.78056
        let defaultLon = -78.6389

        let timings = calculateTimings(
            latitude:  defaultLat,
            longitude: defaultLon,
            date:      calculationDate
        )
        completion?(timings)
        completion = nil
    }

    private func calculateTimings(latitude: Double,
                                  longitude: Double,
                                  date: Date) -> Timings {
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.year, .month, .day], from: date)

        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        var params = CalculationMethod.muslimWorldLeague.params
        params.madhab = .shafi

        guard let prayerTimes = PrayerTimes(coordinates: coordinates,
                                            date: comps,
                                            calculationParameters: params) else {
            return Timings(fajr: "00:00", sunrise: "00:00",
                           dhuhr: "00:00", asr: "00:00",
                           maghrib: "00:00", isha: "00:00")
        }

        // حساب SunnahTimes
        if let sunnahTimes = SunnahTimes(from: prayerTimes) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm"

            print("Last Third of the Night: \(formatter.string(from: sunnahTimes.lastThirdOfTheNight))")
            print("Middle of the Night: \(formatter.string(from: sunnahTimes.middleOfTheNight))")
        }

        // تحديد الصلاة الحالية والقادمة والوقت المتبقي
        let currentPrayer = prayerTimes.currentPrayer()
        let nextPrayer = prayerTimes.nextPrayer()
let countdown = nextPrayer.flatMap { prayerTimes.time(for: $0).timeIntervalSinceNow } ?? 0

        print("Current Prayer: \(String(describing: currentPrayer))")
        print("Next Prayer: \(String(describing: nextPrayer))")
        print("Time until next prayer: \(countdown)")

        func fmt(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale     = Locale(identifier: "en_US_POSIX")
            formatter.timeZone   = TimeZone.current
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        return Timings(
            fajr:    fmt(prayerTimes.fajr),
            sunrise: fmt(prayerTimes.sunrise),
            dhuhr:   fmt(prayerTimes.dhuhr),
            asr:     fmt(prayerTimes.asr),
            maghrib: fmt(prayerTimes.maghrib),
            isha:    fmt(prayerTimes.isha)
        )
    }
}


// أعلى ContentView.swift
private struct DefaultIqamaOffsets {
    let fajr: Int    = 20
    let dhuhr: Int   = 20
    let asr: Int     = 20
    let maghrib: Int = 10
    let isha: Int    = 20
}
private let defaultIqamaOffsets = DefaultIqamaOffsets()


//هنا3

struct ContentView: View {

@State private var lastFetchedDay = Calendar.current.startOfDay(for: Date())


    // MARK: – App Settings
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true
    @AppStorage("soundEnabled")    private var soundEnabled    = false
    @AppStorage("hapticEnabled")   private var hapticEnabled   = true
    
    // كتم الأذان
    @AppStorage("muteAzanFajr")    private var muteAzanFajr    = false
    @AppStorage("muteAzanDhuhr")   private var muteAzanDhuhr   = false
    @AppStorage("muteAzanAsr")     private var muteAzanAsr     = false
    @AppStorage("muteAzanMaghrib") private var muteAzanMaghrib = false
    @AppStorage("muteAzanIsha")    private var muteAzanIsha    = false
    
    @AppStorage("muteAzanSunrise") private var muteAzanSunrise   = false
    
    
    
    // كتم الإشعارات
    @AppStorage("muteNotifSunrise") private var muteNotifSunrise = false
    
    @AppStorage("muteNotifFajr")    private var muteNotifFajr    = false
    @AppStorage("muteNotifDhuhr")   private var muteNotifDhuhr   = false
    @AppStorage("muteNotifAsr")     private var muteNotifAsr     = false
    @AppStorage("muteNotifMaghrib") private var muteNotifMaghrib = false
    @AppStorage("muteNotifIsha")    private var muteNotifIsha    = false
    
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    // دقائق الإقامة
    @AppStorage("iqamaFajrOffset")    private var iqamaFajrOffset    = 20
    @AppStorage("iqamaDhuhrOffset")   private var iqamaDhuhrOffset   = 20
    @AppStorage("iqamaAsrOffset")     private var iqamaAsrOffset     = 20
    @AppStorage("iqamaMaghribOffset") private var iqamaMaghribOffset = 10
    @AppStorage("iqamaIshaOffset")    private var iqamaIshaOffset    = 20


    // MARK: – تأخير/تقديم موعد الأذان (بالدقائق)
    @AppStorage("azanFajrOffset")    private var azanFajrOffset    = 0
    @AppStorage("azanDhuhrOffset")   private var azanDhuhrOffset   = 0
    @AppStorage("azanAsrOffset")     private var azanAsrOffset     = 0
    @AppStorage("azanMaghribOffset") private var azanMaghribOffset = 0
    @AppStorage("azanIshaOffset")    private var azanIshaOffset    = 0
    @AppStorage("azanSunriseOffset") private var azanSunriseOffset = 0

@AppStorage("selectedLanguage")
private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"



@Environment(\.layoutDirection) var layoutDirection

@Environment(\.locale) private var locale

@State private var tempIqamaFajrOffset    = 0
@State private var tempIqamaDhuhrOffset   = 0
@State private var tempIqamaAsrOffset     = 0
@State private var tempIqamaMaghribOffset = 0
@State private var tempIqamaIshaOffset    = 0

@State private var tempAzanFajrOffset    = 0
@State private var tempAzanSunriseOffset = 0
@State private var tempAzanDhuhrOffset   = 0
@State private var tempAzanAsrOffset     = 0
@State private var tempAzanMaghribOffset = 0
@State private var tempAzanIshaOffset    = 0






// أضف هذه المتغيّرات لحفظ الساعة الأصلية بصيغة 12-ساعة
@State private var origFajr    = ""
@State private var origSunrise = ""
@State private var origDhuhr   = ""
@State private var origAsr     = ""
@State private var origMaghrib = ""
@State private var origIsha    = ""
    
    
    private let badgeColors: [Color] = [
        .green, .orange, .blue, .red, .purple, .pink, .yellow
    ]
    
    //@State private var customSections: [String] = UserDefaults.standard.stringArray(forKey: "customSections") ?? []
    //@State private var showAddSection = false
    //@State private var newSectionName = ""
    
    // حالــة الـ UI
    @State private var showSettings  = false
    @State private var showEditIqama = false
@State private var settingsTimings: Timings?   // لإعادة الحساب في شاشة التعديل
    
    @State private var deleteIndex: Int? = nil
    //@State private var showDeleteAlert = false
    
    
    
    
    //@State private var deleteSectionIndex: Int? = nil
    
    
    
    
    // الموقع ومواقيت الصلاة
    @StateObject private var locationManager = LocationManager()
    @State private var prayerTimes: Timings?
    @State private var isLoading = true
    @State private var now       = Date()
    
    
    
    
    
    
    
    // …
    
    
    
    
    
    // ... محتوى الواجهة ...
    
    
    // داخل ContentView، بعد ما تجيب prayerTimes و now:
    private var nextPrayerIndex: Int {
        guard let t = prayerTimes else { return 0 }
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let offset: TimeInterval = 30 * 60
        
        // الآن تشمل Sunrise أيضاً
        let rawTimes = [t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha]
        let prayerDates: [Date] = rawTimes.compactMap { timeStr in
            let clean = timeStr
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces).first ?? timeStr
            guard let d = parser.date(from: clean) else { return nil }
            return cal.date(
                bySettingHour: cal.component(.hour,   from: d),
                minute:        cal.component(.minute, from: d),
                second:        0,
                of:            startOfDay
            )
        }
        
        for (i, pd) in prayerDates.enumerated() {
            if now < pd || now < pd + offset {
                return i
            }
        }
        
        return 0
    }


// داخل ContentView، فوق var body
private func adjustedAzanTime(_ timeString: String, for prayer: String) -> String {
    guard let originalDate = parser.date(from: timeString) else { return timeString }

    // الإزاحة
    let offset: Int
    switch prayer {
    case "الفجر", "Fajr":       offset = azanFajrOffset
    case "الشروق", "Sunrise":   offset = azanSunriseOffset
    case "الظهر", "Dhuhr":      offset = azanDhuhrOffset
    case "العصر", "Asr":        offset = azanAsrOffset
    case "المغرب", "Maghrib":   offset = azanMaghribOffset
    case "العشاء", "Isha":      offset = azanIshaOffset
    default:                    offset = 0
    }

    let adjustedDate = Calendar.current.date(byAdding: .minute, value: offset, to: originalDate) ?? originalDate

    // مهيئ التاريخ حسب اللغة
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    
    if selectedLanguage == "ar" {
        formatter.amSymbol = "ص"
        formatter.pmSymbol = "م"
    } else {
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
    }

    return formatter.string(from: adjustedDate)
}
    // اضبط الساعة القديمة مع الدقيقة الجديدة

    
    
    // 1) فوق الـ body (ضمن ContentView) أضف الدوال هذي:
    private func isAzanMuted(for prayer: String) -> Bool {
        switch prayer {
        case "الفجر":  return muteAzanFajr
        case "الشروق": return muteAzanSunrise
        case "الظهر":  return muteAzanDhuhr
        case "العصر":  return muteAzanAsr
        case "المغرب": return muteAzanMaghrib
        case "العشاء": return muteAzanIsha
        default:       return false
        }
    }
    
    private func toggleAzanMute(for prayer: String) {
        switch prayer {
        case "الفجر":  muteAzanFajr.toggle()
        case "الشروق": muteAzanSunrise.toggle()
        case "الظهر":  muteAzanDhuhr.toggle()
        case "العصر":  muteAzanAsr.toggle()
        case "المغرب": muteAzanMaghrib.toggle()
        case "العشاء": muteAzanIsha.toggle()
        default: break
        }
        if let t = prayerTimes { schedulePrayerNotifications(t) }
    }
    
    private func isNotifMuted(for prayer: String) -> Bool {
        switch prayer {
        case "الفجر":  return muteNotifFajr
        case "الشروق": return muteNotifSunrise
        case "الظهر":  return muteNotifDhuhr
        case "العصر":  return muteNotifAsr
        case "المغرب": return muteNotifMaghrib
        case "العشاء": return muteNotifIsha
        default:       return false
        }
    }
    
    private func toggleNotifMute(for prayer: String) {
        switch prayer {
        case "الفجر":  muteNotifFajr.toggle()
        case "الشروق": muteNotifSunrise.toggle()
        case "الظهر":  muteNotifDhuhr.toggle()
        case "العصر":  muteNotifAsr.toggle()
        case "المغرب": muteNotifMaghrib.toggle()
        case "العشاء": muteNotifIsha.toggle()
        default: break
        }
        if let t = prayerTimes { schedulePrayerNotifications(t) }
    }
    
    // 2) داخل ForEach، غيّر HStack كذا:
    
// MARK: – Localized Date/Time/Location

private var isArabic: Bool {
    locale.language.languageCode?.identifier == "ar"
}

private var localizedTime: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "h:mm a"
    if isArabic {
        f.amSymbol = "ص"; f.pmSymbol = "م"
    }
    return f.string(from: now)
}

private var localizedWeekday: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: isArabic ? "ar" : "en_US_POSIX")
    f.dateFormat = "EEEE"
    return f.string(from: now)
}

private var localizedDate: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: isArabic ? "ar" : "en_US_POSIX")
    // يمكنك تغيير الصيغة حسب رغبتك
    f.dateFormat = isArabic ? "d/MMMM/yyyy" : "MMMM d, yyyy"
    return f.string(from: now)
}

private var localizedHijri: String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .islamicUmmAlQura)
    f.locale   = Locale(identifier: isArabic ? "ar" : "en_US_POSIX")
    f.dateFormat = "d MMMM yyyy"
    return f.string(from: now)
}

private var localizedLocation: String {
    guard let place = locationManager.placemark else { return "…" }
    let city = place.locality ?? "…"
    let country: String
    if let code = place.isoCountryCode {
        // دائمًا احصل على اسم البلد بالإنجليزية
        country = Locale(identifier: "en_US_POSIX")
            .localizedString(forRegionCode: code) ?? place.country ?? "…"
    } else {
        country = place.country ?? "…"
    }
    return isArabic
        ? "\(city)، \(country)"
        : "\(city), \(country)"
}



    

    // MARK: – Timer
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: – Date Formatters
    private let parser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()
    
    // داخل ContentView (فوق الـ body)
    

    private let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar")
        f.dateFormat = "EEEE"
        return f
    }()
    // تاريخ مفصول بشرطات مع سنة
    private let slashDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar")
        f.dateFormat = "d/MMMM/yyyy"
        return f
    }()
    private let formatter12: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        f.amSymbol = "ص"; f.pmSymbol = "م"
        return f
    }()
    
    // داخل ContentView (فوق الـ body)
    private let hijriDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar")
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    
    // MARK: – Helper Functions
    private func formatTime(_ time: String) -> String {
        let clean = time
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces).first ?? time
        guard let date = parser.date(from: clean) else { return clean }
        return formatter12.string(from: date)
    }
    
    
    // MARK: – عدّاد الدقائق حتى الصلاة
    private func countdownSeconds(for timeString: String, prayer: String) -> Int? {
        // نعيد استخدام parsed و rawAdhan و azanOffset من iqamaInfo
        let cal = Calendar.current, now = Date()
        guard let parsed = parser.date(from: timeString) else { return nil }
        var comps = cal.dateComponents([.hour, .minute], from: parsed)
        comps.year  = cal.component(.year,  from: now)
        comps.month = cal.component(.month, from: now)
        comps.day   = cal.component(.day,   from: now)
        guard let rawAdhan = cal.date(from: comps) else { return nil }

        let azanOffset: Int
        switch prayer {
        case "الفجر":   azanOffset = azanFajrOffset
        case "الظهر":   azanOffset = azanDhuhrOffset
        case "العصر":   azanOffset = azanAsrOffset
        case "المغرب":  azanOffset = azanMaghribOffset
        case "العشاء":  azanOffset = azanIshaOffset
        default:        azanOffset = 0
        }
        let adhanDate = cal.date(byAdding: .minute, value: azanOffset, to: rawAdhan)!

        return Int(adhanDate.timeIntervalSince(now))
    }

    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    

    
    // داخل ContentView:
// داخل ContentView لديك already:

// قم بتعديل الدالة لتستخدم selectedLanguage:
private func iqamaInfo(for timeString: String, prayer: String) -> (label: String, color: Color)? {
    let cal = Calendar.current
    let now = Date()

    // 1. حوّل النص الأصلي لـ Date
    guard let parsed = parser.date(from: timeString) else { return nil }
    var comps = cal.dateComponents([.hour, .minute], from: parsed)
    comps.year  = cal.component(.year,  from: now)
    comps.month = cal.component(.month, from: now)
    comps.day   = cal.component(.day,   from: now)
    guard let adhanBase = cal.date(from: comps) else { return nil }

    // 2. حساب وقت الأذان مع offset
    let azanOffset: Int
    switch prayer {
    case "الفجر":   azanOffset = azanFajrOffset
    case "الظهر":   azanOffset = azanDhuhrOffset
    case "العصر":   azanOffset = azanAsrOffset
    case "المغرب":  azanOffset = azanMaghribOffset
    case "العشاء":  azanOffset = azanIshaOffset
    default:        azanOffset = 0
    }
    let adhanDate = cal.date(byAdding: .minute, value: azanOffset, to: adhanBase)!

    // 3. حساب وقت الإقامة مع offset
    let iqamaOffset: Int
    switch prayer {
    case "الفجر":   iqamaOffset = iqamaFajrOffset
    case "الظهر":   iqamaOffset = iqamaDhuhrOffset
    case "العصر":   iqamaOffset = iqamaAsrOffset
    case "المغرب":  iqamaOffset = iqamaMaghribOffset
    case "العشاء":  iqamaOffset = iqamaIshaOffset
    default:        iqamaOffset = 20
    }
    let iqamaDate = cal.date(byAdding: .minute, value: iqamaOffset, to: adhanDate)!

    // 4. عرض ما قبل الإقامة أو بعدها حتى 30 دقيقة
    guard now >= adhanDate else { return nil }                        
    let windowEnd = iqamaDate.addingTimeInterval(30 * 60)
    guard now <= windowEnd else { return nil }

    let diff = iqamaDate.timeIntervalSince(now)                       
    let absSec = Int(abs(diff))
    let m = absSec / 60, s = absSec % 60
    let tp = String(format: "%02d:%02d", m, s)

    // استخدم selectedLanguage للاختيار بين العربي والإنجليزي
    if diff >= 0 {
        let label = (selectedLanguage == "ar")
            ? "الإقامة بعد \(tp)"
            : "Iqama in \(tp)"
        return (label, .green)
    } else {
        let label = (selectedLanguage == "ar")
            ? "متأخر عن الإقامة \(tp)"
            : "Late for Iqama by \(tp)"
        return (label, .red)
    }
}



//هنا اقامه
    
    // داخل ContentView:
    private func schedulePrayerNotifications(_ timings: Timings) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // إضافة الشروق إلى قائمة الصلوات
        let prayers = [
            ("الفجر",   timings.fajr),
            ("الشروق",  timings.sunrise),
            ("الظهر",   timings.dhuhr),
            ("العصر",   timings.asr),
            ("المغرب",  timings.maghrib),
            ("العشاء",  timings.isha)
        ]
        
        for (name, timeString) in prayers {
            // ← هذا السطر يخطي جدولة إشعار الشروق إذا كان مكتوماً
            if name == "الشروق" && muteNotifSunrise {
                continue
            }
            
            // تنظيف السلسلة وتحويلها إلى Date
            let clean = timeString
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces).first ?? timeString
            guard let date = parser.date(from: clean) else { continue }
            
            // ───── الكود الجديد للتعويض بـ azanOffset ─────
            // 1. نبني تاريخ اليوم عند وقت الصلاة
            let baseDate = Calendar.current.date(
                bySettingHour:   Calendar.current.component(.hour,   from: date),
                minute:          Calendar.current.component(.minute, from: date),
                second:          0,
                of:               Date()
            )!
            // 2. نختار الـ offset المناسب لكل صلاة
            let offsetMinutes: Int
            switch name {
            case "الفجر":   offsetMinutes = azanFajrOffset
            case "الشروق":  offsetMinutes = azanSunriseOffset
            case "الظهر":   offsetMinutes = azanDhuhrOffset
            case "العصر":   offsetMinutes = azanAsrOffset
            case "المغرب":  offsetMinutes = azanMaghribOffset
            case "العشاء":  offsetMinutes = azanIshaOffset
            default:        offsetMinutes = 0
            }
            // 3. نضيف/نطرح الـ offset
            let fireDate = Calendar.current.date(
                byAdding: .minute,
                value: offsetMinutes,
                to: baseDate
            )!
            // 4. نحول التاريخ المعوَّض إلى مكونات ساعة ودقيقة
            let comps = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
            // ────────────────────────────────────────────────
            
            // إعداد الإشعار
            let content = UNMutableNotificationContent()
            if name == "الشروق" {
                content.title = "شروق الشمس"
                content.body  = "حان وقت شروق الشمس"
                content.sound = nil  // بدون صوت
            } else {
                // ضبط كتم الإشعارات والأذان للصلاة
                let isMuteNotif: Bool
                let isMuteAzan:  Bool
                switch name {
                case "الفجر":
                    isMuteNotif = muteNotifFajr;    isMuteAzan = muteAzanFajr
                case "الظهر":
                    isMuteNotif = muteNotifDhuhr;   isMuteAzan = muteAzanDhuhr
                case "العصر":
                    isMuteNotif = muteNotifAsr;     isMuteAzan = muteAzanAsr
                case "المغرب":
                    isMuteNotif = muteNotifMaghrib; isMuteAzan = muteAzanMaghrib
                case "العشاء":
                    isMuteNotif = muteNotifIsha;    isMuteAzan = muteAzanIsha
                default:
                    isMuteNotif = false; isMuteAzan = false
                }
                guard !isMuteNotif else { continue }
                
                content.title = "أذان \(name)"
                content.body  = "حان وقت أذان \(name)"
                content.sound = isMuteAzan
                    ? nil
                    : UNNotificationSound(named: .init("azan.m4a"))
            }
            
            // جدولة التكرار اليومي باستخدام المكونات بعد offset
            var triggerComps = DateComponents()
            triggerComps.hour   = comps.hour
            triggerComps.minute = comps.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)
            
            // identifier مختلف للشروق
            let identifier = (name == "الشروق") ? "sunrise" : "azan_\(name)"
            let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(req) { error in
                if let e = error {
                    print("Failed to add \(name):", e)
                }
            }
        }
    }

    private func scheduleDhikrNotifications(_ timings: Timings) {
        let center = UNUserNotificationCenter.current()
        let prayers = [
            ("الفجر",   timings.fajr),
            ("الظهر",   timings.dhuhr),
            ("العصر",   timings.asr),
            ("المغرب",  timings.maghrib),
            ("العشاء",  timings.isha)
        ]

        // إزالة أي جداول سابقة
        let ids = prayers.map { "dhikr_\($0.0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        let day = Calendar.current.component(.day, from: Date())
        let cal = Calendar.current

        for (name, timeStr) in prayers {
            // 1. حوّل نص الوقت إلى Date في اليوم الحالي
            let clean = timeStr.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).first ?? timeStr
            guard let parsed = parser.date(from: clean) else { continue }
            var comps = cal.dateComponents([.hour, .minute], from: parsed)
            comps.year  = cal.component(.year,  from: Date())
            comps.month = cal.component(.month, from: Date())
            comps.day   = cal.component(.day,   from: Date())
            guard let rawAdhan = cal.date(from: comps) else { continue }

            // 2. جيب azanOffset من الإعدادات
            let azanOffset: Int
            switch name {
            case "الفجر":   azanOffset = azanFajrOffset
            case "الظهر":   azanOffset = azanDhuhrOffset
            case "العصر":   azanOffset = azanAsrOffset
            case "المغرب":  azanOffset = azanMaghribOffset
            case "العشاء":  azanOffset = azanIshaOffset
            default:        azanOffset = 0
            }
            let adhanDate = cal.date(byAdding: .minute, value: azanOffset, to: rawAdhan)!

            // 3. حدّد offset الأذكار بناءً على الصلاة
            let dhikrOffset: Int
            switch name {
            case "الفجر":
                dhikrOffset = 30    // بعد الآذان بــ30 دقيقة
            case "المغرب":
                dhikrOffset = -30   // قبل الآذان بــ30 دقيقة
            default:
                dhikrOffset = -20   // قبل بقية الصلوات بــ20 دقيقة
            }

            // 4. احسب موعد الإشعار
            guard let fireDate = cal.date(byAdding: .minute, value: dhikrOffset, to: adhanDate) else { continue }
            let compsFire = cal.dateComponents([.hour, .minute], from: fireDate)

            // 5. جهّز محتوى الإشعار
            let content = UNMutableNotificationContent()
            content.title = "أذكار"
            content.sound = .default

            // اختيار نص الذكر
            let dhikrOptions: [String: [String]] = [
                "الفجر":  ["حان وقت قراءتك لأذكار الصباح"],
                "الظهر":  ["سبحان الله", "وقل رب اغفر وارحم وأنت خير الراحمين", "الحمدلله"],
                "العصر":  ["لا إله إلا الله", "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ", "سبحان الله وبحمده"],
                "المغرب": ["حان وقت قراءتك لأذكار المساء"],
                "العشاء": ["أعوذ بكلمات الله التامات من شر ما خلق", "سبحان الله وبحمده", "لا حول ولا قوة إلا بالله"]
            ]
            if let arr = dhikrOptions[name] {
                if name == "الفجر" || name == "المغرب" {
                    content.body = arr.first!
                } else {
                    // دوّر ذكر بناءً على اليوم وترتيب الصلاة
                    let offsets = ["الفجر":0,"الظهر":1,"العصر":2,"المغرب":3,"العشاء":4]
                    let idx = ((day - 1) + (offsets[name] ?? 0)) % arr.count
                    content.body = arr[idx]
                }
            }



            // 6. اجدول الإشعار
            var triggerComps = DateComponents()
            triggerComps.hour   = compsFire.hour
            triggerComps.minute = compsFire.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)
            let req = UNNotificationRequest(identifier: "dhikr_\(name)", content: content, trigger: trigger)
            center.add(req) { if let e = $0 { print("خطأ جدولة ذكر \(name):", e) } }
        }
    }

    
    // MARK: – View Body
    var body: some View {
        NavigationStack {
            
            ZStack {
                                LinearGradient(gradient: Gradient(colors: [
        Color(red: 0.12, green: 0.25, blue: 0.33),    // أزرق غامق ليلي
        Color(red: 0.20, green: 0.25, blue: 0.33),       // بنفسجي غامق ليلي
        Color(red: 0.1, green: 0.15, blue: 0.3),      // أزرق غامق ليلي آخر
        Color(red: 0.15, green: 0.05, blue: 0.25),     // أخضر غامق ليلي
        Color(red: 0.12, green: 0.25, blue: 0.33),    // أزرق غامق ليلي
    
                ]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                VStack(spacing:20) {
                    // Top Bar
                    HStack {
                        Button { showSettings.toggle() } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size:20))
                                .foregroundColor(.white)
                                .padding(.leading,28)
                        }
                        Spacer()
                    }
                    .padding(.top,30)
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    // Compass & Location & Date
                    if let loc = locationManager.location {






                        VStack(spacing: 8) {

// …




    // النصوص تتغير ترتيبها وفق اللغة
HStack(alignment: .center, spacing: 14) {
    // ——— البوصلة على اليسار ———
    EnhancedCompassView(
        heading: locationManager.heading?.trueHeading,
        bearing: qiblaBearing(from: loc)
    )
    .frame(width: 60, height: 60)
    .offset(x: 20)

    Spacer()

    // ——— النصوص على اليمين ———
  VStack(alignment: .leading, spacing: 4) {
    // الوقت
    HStack {
        if isArabic {
            Text(localizedTime)
                .foregroundColor(.green)
            Spacer()
            Text("الوقت:")
                .foregroundColor(.white)
        } else {
            Text("Time:")
                .foregroundColor(.white)
            Spacer()
            Text(localizedTime)
                .foregroundColor(.green)
        }
    }
    Divider().background(Color.white.opacity(0.3))

    // اليوم
    HStack {
        if isArabic {
            Text(localizedWeekday)
                .foregroundColor(.green)
            Spacer()
            Text("اليوم:")
                .foregroundColor(.white)
        } else {
            Text("Day:")
                .foregroundColor(.white)
            Spacer()
            Text(localizedWeekday)
                .foregroundColor(.green)
        }
    }
    Divider().background(Color.white.opacity(0.3))

    // التاريخ الميلادي
    HStack {
        if isArabic {
            Text(localizedDate)
                .foregroundColor(.green)
            Spacer()
            Text("التاريخ:")
                .foregroundColor(.white)
        } else {
            Text("Date:")
                .foregroundColor(.white)
            Spacer()
            Text(localizedDate)
                .foregroundColor(.green)
        }
    }
    Divider().background(Color.white.opacity(0.3))

    // التاريخ الهجري
    HStack {
        if isArabic {
            Text(localizedHijri)
                .foregroundColor(.green)
            Spacer()
            Text("التاريخ الهجري:")
                .foregroundColor(.white)
        } else {
            Text("Hijri Date:")
                .foregroundColor(.white)
            Spacer()
            Text(localizedHijri)
                .foregroundColor(.green)
        }
    }
    Divider().background(Color.white.opacity(0.3))

    // المدينة والبلد
    HStack {
        if isArabic {
            Text(localizedLocation)
                .foregroundColor(.green)
            Spacer()
            Text("الدولة:")
                .foregroundColor(.white)
        } else {
            Text("Location:")
                .foregroundColor(.white)
            Spacer()
            Text(localizedLocation)
                .foregroundColor(.green)
        }
    }
}
.font(.system(size: 14, weight: .medium, design: .rounded))
.frame(width: 210, alignment: .leading)

}
.padding(13)
.background(Color.black.opacity(0.3))
.cornerRadius(8)
.padding(.horizontal, 25)


                            
                        }
                        
                    }
                    
                    
                    
                  
   // --- في ContentView.swift داخل الـ body استبدل القسم القديم بهذا القسم: ---
                    if locationManager.location == nil {
                        switch locationManager.authStatus {
                        case .denied, .restricted:
                            VStack(spacing: 16) {
                                Text("يجب تفعيل الموقع لتتمكن من حساب مواقيت الصلاة:\nالإعدادات ← الخصوصية ← خدمات الموقع ← تطبيق ← سماح الوصول دائماً")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                Button("فتح إعدادات التطبيق") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding()
                        default:
                            ProgressView("جاري حساب مواقيت الصلاة…")
                                .foregroundColor(.white)
                        }
                    }
                    else if isLoading {
                        ProgressView("جاري حساب مواقيت الصلاة…")
                            .foregroundColor(.white)
                    }
                    else if let t = prayerTimes {
                        VStack(spacing: 8) {
                            HStack {
                                Button { showEditIqama.toggle() } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "switch.2")
                                        Text("تحرير")
                                    }
                                    .foregroundColor(.green)
                                }
                                Spacer()
                            }
                            .padding(.leading, 27)
                            // … بقية عرض أوقات الصلاة …
                            
                        
                            
                            
                            
                            
                            // … بقية محتوى VStack الخاص بعرض أوقات الصلاة …
                            
                            
                            // بقية الـ VStack …
                            
                            //هنا جدول
                            


VStack(spacing: 8) {
    ForEach(Array([
        (isArabic ? "الفجر" : "Fajr",       t.fajr),
        (isArabic ? "الشروق" : "Sunrise",    t.sunrise),
        (isArabic ? "الظهر" : "Dhuhr",      t.dhuhr),
        (isArabic ? "العصر" : "Asr",        t.asr),
        (isArabic ? "المغرب" : "Maghrib",   t.maghrib),
        (isArabic ? "العشاء" : "Isha",      t.isha)
    ].enumerated()), id: \.0) { idx, item in
        HStack(alignment: .top, spacing: 12) {
            if isArabic {
                // أزرار الصوت والإشعار والوقت بالعربي
                Button {
                    toggleAzanMute(for: item.0)
                    if soundEnabled  { SoundPlayer.shared.play("click") }
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                } label: {
                    Image(systemName: isAzanMuted(for: item.0)
                          ? "speaker.slash.fill"
                          : "speaker.wave.2.fill")
                    .foregroundColor(isAzanMuted(for: item.0) ? .red : .white)
                }

                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.white.opacity(0.3))

                Button {
                    toggleNotifMute(for: item.0)
                    if soundEnabled  { SoundPlayer.shared.play("click") }
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                } label: {
                    Image(systemName: isNotifMuted(for: item.0)
                          ? "bell.slash.fill"
                          : "bell.fill")
                    .foregroundColor(isNotifMuted(for: item.0) ? .red : .white)
                }

                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    Text(adjustedAzanTime(item.1, for: item.0))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)

                    if item.0 != "الشروق" {
                        if let secs = countdownSeconds(for: item.1, prayer: item.0) {
                            if secs > 0 && secs <= 80 * 60 {
                                let hours = secs / 3600
                                let minutes = (secs % 3600) / 60
                                let seconds = secs % 60
                                let countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)

                                Text("أذان \(item.0) بعد \(countdown)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.yellow)
                            }
                        }
                        if let info = iqamaInfo(for: item.1, prayer: item.0) {
                            Text(info.label)
                                .font(.caption.monospacedDigit())
                                .foregroundColor(info.color)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(item.0)
                        .foregroundColor(.white)
                    if nextPrayerIndex == idx && item.0 != "الشروق" {
                        Image(systemName: "arrowtriangle.left.fill")
                            .foregroundColor(.white)
                            .opacity(0.3)
                            .padding(.trailing, -21)
                    }
                }
                .frame(width: 80, alignment: .trailing)
            } else {
                HStack(spacing: 4) {
                    if nextPrayerIndex == idx && item.0 != "Sunrise" {
                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(.white)
                            .opacity(0.3)
                            .padding(.leading, -21)
                    }
                    Text(item.0)
                        .foregroundColor(.white)
                }
                .frame(width: 80, alignment: .leading)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(adjustedAzanTime(item.1, for: item.0))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)

                    if item.0 != "Sunrise" {
                        if let secs = countdownSeconds(for: item.1, prayer: item.0) {
                            if secs > 0 && secs <= 80 * 60 {
                                let hours = secs / 3600
                                let minutes = (secs % 3600) / 60
                                let seconds = secs % 60
                                let countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)

                                Text("\(item.0) Azan in \(countdown)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.yellow)
                            }
                        }
                        if let info = iqamaInfo(for: item.1, prayer: item.0) {
                            Text(info.label)
                                .font(.caption.monospacedDigit())
                                .foregroundColor(info.color)
                        }
                    }
                }

                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.white.opacity(0.3))

                Button {
                    toggleNotifMute(for: item.0 == "Fajr" ? "الفجر" : 
                                  item.0 == "Sunrise" ? "الشروق" :
                                  item.0 == "Dhuhr" ? "الظهر" :
                                  item.0 == "Asr" ? "العصر" :
                                  item.0 == "Maghrib" ? "المغرب" : "العشاء")
                    if soundEnabled  { SoundPlayer.shared.play("click") }
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                } label: {
                    Image(systemName: isNotifMuted(for: item.0 == "Fajr" ? "الفجر" : 
                                                 item.0 == "Sunrise" ? "الشروق" :
                                                 item.0 == "Dhuhr" ? "الظهر" :
                                                 item.0 == "Asr" ? "العصر" :
                                                 item.0 == "Maghrib" ? "المغرب" : "العشاء") ? "bell.slash.fill" : "bell.fill")
                        .foregroundColor(isNotifMuted(for: item.0 == "Fajr" ? "الفجر" : 
                                                    item.0 == "Sunrise" ? "الشروق" :
                                                    item.0 == "Dhuhr" ? "الظهر" :
                                                    item.0 == "Asr" ? "العصر" :
                                                    item.0 == "Maghrib" ? "المغرب" : "العشاء") ? .red : .white)
                }

                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.white.opacity(0.3))

                Button {
                    toggleAzanMute(for: item.0 == "Fajr" ? "الفجر" : 
                                 item.0 == "Sunrise" ? "الشروق" :
                                 item.0 == "Dhuhr" ? "الظهر" :
                                 item.0 == "Asr" ? "العصر" :
                                 item.0 == "Maghrib" ? "المغرب" : "العشاء")
                    if soundEnabled  { SoundPlayer.shared.play("click") }
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                } label: {
                    Image(systemName: isAzanMuted(for: item.0 == "Fajr" ? "الفجر" : 
                                                item.0 == "Sunrise" ? "الشروق" :
                                                item.0 == "Dhuhr" ? "الظهر" :
                                                item.0 == "Asr" ? "العصر" :
                                                item.0 == "Maghrib" ? "المغرب" : "العشاء") ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(isAzanMuted(for: item.0 == "Fajr" ? "الفجر" : 
                                                   item.0 == "Sunrise" ? "الشروق" :
                                                   item.0 == "Dhuhr" ? "الظهر" :
                                                   item.0 == "Asr" ? "العصر" :
                                                   item.0 == "Maghrib" ? "المغرب" : "العشاء") ? .red : .white)
                }
            }
        }

        if item.0 != (isArabic ? "العشاء" : "Isha") {
            Divider().background(Color.white.opacity(0.3))
        }
    }
}
.padding()
.background(Color.black.opacity(0.3))
.cornerRadius(15)
.padding(.horizontal, 25)

                        }
                    }
                    
                    
                    
                    // ↓ بدل ScrollView+LazyVGrid القديم:
                    // داخل ContentView’s body، استبدل الـ ScrollView القديم بهذا الكود الكامل:
                    

ScrollView {
    // ——— الأذكار الرئيسية ———
    HStack(spacing: 14) {
        // أذكار المساء
        NavigationLink(destination: DhikrDetailView(dhikrType: .evening)) {
            HStack(spacing: 12) {
                // الإيقونة على اليسار
Image("eveningIcon")
    .resizable()
    .scaledToFit()
    .frame(width: 50, height: 50)
    .background(Color.white.opacity(0.2))
    .clipShape(Circle())
    .overlay(
        Circle()
            .stroke(Color.gray, lineWidth: 2)
    )
    .padding(.leading, 8)

Text("أذكار المساء")
    .font(.system(size: 15))
    .foregroundColor(.white)
    .padding(.leading, 8)

Spacer()
            }
            .padding(0)
            .frame(width: 180, height: 60)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.slateGray, lineWidth: 2)
            )
        }
        
        // أذكار الصباح
        NavigationLink(destination: DhikrDetailView(dhikrType: .morning)) {
            HStack(spacing: 12) {
                Image("morningIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
    .clipShape(Circle())
    .overlay(
        Circle()
            .stroke(Color.gray, lineWidth: 2)
    )
    .padding(.leading, 8)

                Text("أذكار الصباح")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
.padding(.leading, 8)
                
                Spacer()
            }
            .padding(0)
            .frame(width: 180, height: 60)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.slateGray, lineWidth: 2)
            )
        }
    }
    
    HStack(spacing: 14) {
        // أذكار الاستيقاظ
        NavigationLink(destination: DhikrDetailView(dhikrType: .awakening)) {
            HStack(spacing: 12) {
                Image("awakeningIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
    .clipShape(Circle())
    .overlay(
        Circle()
            .stroke(Color.gray, lineWidth: 2)
    )
    .padding(.leading, 8)

                Text("أذكار الاستيقاظ")
                    .font(.system(size: 14.5))
                    .foregroundColor(.white)
.padding(.leading, 8)
                
                Spacer()
            }
            .padding(0)
            .frame(width: 180, height: 60)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.slateGray, lineWidth: 2)
            )
        }
        
        // أذكار النوم
        NavigationLink(destination: DhikrDetailView(dhikrType: .sleep)) {
            HStack(spacing: 12) {
                Image("sleepIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
    .clipShape(Circle())
    .overlay(
        Circle()
            .stroke(Color.gray, lineWidth: 2)
    )
    .padding(.leading, 8)

                Text("أذكار النوم")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
.padding(.leading, 8)
                
                Spacer()
            }
            .padding(0)
            .frame(width: 180, height: 60)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.slateGray, lineWidth: 2)
            )
        }
    }
    HStack(spacing: 14) {
        
        NavigationLink(destination: AlzakeerMenuView()) {
            HStack(spacing: 12) {
                Image("alzakeerIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
    .clipShape(Circle())
    .overlay(
        Circle()
            .stroke(Color.gray, lineWidth: 2)
    )
    .padding(.leading, 8)
                
                Text("جميع الأقسام")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(0)
            .frame(width: 180, height: 60)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.slateGray, lineWidth: 2)
            )
        }
        

    }

}
.padding(.horizontal, 25)
.frame(maxHeight: .infinity)
.ignoresSafeArea(.keyboard, edges: .bottom)
    }


                .environment(\.layoutDirection, .leftToRight) // ← يجعل الاتجاه إنجليزي لكن يحافظ على النص العربي
                
                
                
                .navigationBarHidden(true)
            }
            // أولاً sheet للإعدادات

            // ثم sheet لتحرير الإقامة
// 2) استبدل الـ sheet الحالي بهذا:


                                
                        
                        
                        
    // … داخل الـ Form …


// قبل كل شيء حدِّث دالة adjustedAzanTime لتضيف_OFFSET_ إلى الوقت الأصلي:


// داخل الـ Sheet الخاص بتحرير الأذان، استبدل القسم بـ:

                                
              
            // في نهاية تعريف الـ View داخل ContentView، بعد .preferredColorScheme(...)
// داخل الـ View أو الـ ViewModifier حيث لديك الـ onAppear و onReceive
            .onAppear {
              requestNotificationPermission()
               
                               
                           
                        }
            .onReceive(locationManager.$location) { _ in
              isLoading = true
  PrayerTimesServiceOffline.shared.getPrayerTimes(date: Date()) { timings in
    DispatchQueue.main.async {
      prayerTimes = timings
      settingsTimings = timings
      schedulePrayerNotifications(timings)
      if notificationsEnabled {
        scheduleDhikrNotifications(timings)
      }
      isLoading = false
    }
  }
}
.onReceive(timer) { time in
  now = time
  let today = Calendar.current.startOfDay(for: time)
  if today != lastFetchedDay {
    lastFetchedDay = today
    isLoading = true
    PrayerTimesServiceOffline.shared.getPrayerTimes(date: time) { timings in
      DispatchQueue.main.async {
        prayerTimes = timings
        schedulePrayerNotifications(timings)
        if notificationsEnabled {
          scheduleDhikrNotifications(timings)
        }
        isLoading = false
      }
    }
  }
}
.onChange(of: notificationsEnabled) { enabled in
  guard let t = prayerTimes else { return }
  schedulePrayerNotifications(t)
  let center = UNUserNotificationCenter.current()
  if enabled {
    scheduleDhikrNotifications(t)
  } else {
    let ids = ["dhikr_الفجر","dhikr_الظهر","dhikr_العصر","dhikr_المغرب","dhikr_العشاء"]
    center.removePendingNotificationRequests(withIdentifiers: ids)
  }
}
.sheet(isPresented: $showSettings) {
  SettingsView()
}



.sheet(isPresented: $showEditIqama) {
  NavigationView {
    Form {
Section(
    header: Text(isArabic ? "تعديل أوقات الإقامة" : "Edit Iqama Times")
        .font(.headline),
    footer: Text(isArabic
        ? "يمكنك معرفة تواقيت الإقامة من الويب أو الساعات الموجودة في المساجد"
        : "You can find the iqama times online or from the mosque clocks.")
        .font(.footnote)
        .foregroundColor(.gray)
) {
    // فجر / Fajr
    HStack {
        Stepper(
            isArabic
                ? "الفجر: \(tempIqamaFajrOffset) دقيقة"
                : "Fajr: \(tempIqamaFajrOffset) min",
            value: $tempIqamaFajrOffset,
            in: 0...60
        )
        .onChange(of: tempIqamaFajrOffset) { _ in
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        Button(isArabic ? "افتراضي" : "Default") {
            tempIqamaFajrOffset = defaultIqamaOffsets.fajr
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .font(.caption)
        .foregroundColor(.red)
        .buttonStyle(BorderlessButtonStyle())
    }

    // الظهر / Dhuhr
    HStack {
        Stepper(
            isArabic
                ? "الظهر: \(tempIqamaDhuhrOffset) دقيقة"
                : "Dhuhr: \(tempIqamaDhuhrOffset) min",
            value: $tempIqamaDhuhrOffset,
            in: 0...60
        )
        .onChange(of: tempIqamaDhuhrOffset) { _ in
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        Button(isArabic ? "افتراضي" : "Default") {
            tempIqamaDhuhrOffset = defaultIqamaOffsets.dhuhr
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .font(.caption)
        .foregroundColor(.red)
        .buttonStyle(BorderlessButtonStyle())
    }

    // العصر / Asr
    HStack {
        Stepper(
            isArabic
                ? "العصر: \(tempIqamaAsrOffset) دقيقة"
                : "Asr: \(tempIqamaAsrOffset) min",
            value: $tempIqamaAsrOffset,
            in: 0...60
        )
        .onChange(of: tempIqamaAsrOffset) { _ in
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        Button(isArabic ? "افتراضي" : "Default") {
            tempIqamaAsrOffset = defaultIqamaOffsets.asr
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .font(.caption)
        .foregroundColor(.red)
        .buttonStyle(BorderlessButtonStyle())
    }

    // المغرب / Maghrib
    HStack {
        Stepper(
            isArabic
                ? "المغرب: \(tempIqamaMaghribOffset) دقيقة"
                : "Maghrib: \(tempIqamaMaghribOffset) min",
            value: $tempIqamaMaghribOffset,
            in: 0...60
        )
        .onChange(of: tempIqamaMaghribOffset) { _ in
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        Button(isArabic ? "افتراضي" : "Default") {
            tempIqamaMaghribOffset = defaultIqamaOffsets.maghrib
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .font(.caption)
        .foregroundColor(.red)
        .buttonStyle(BorderlessButtonStyle())
    }

    // العشاء / Isha
    HStack {
        Stepper(
            isArabic
                ? "العشاء: \(tempIqamaIshaOffset) دقيقة"
                : "Isha: \(tempIqamaIshaOffset) min",
            value: $tempIqamaIshaOffset,
            in: 0...60
        )
        .onChange(of: tempIqamaIshaOffset) { _ in
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        Button(isArabic ? "افتراضي" : "Default") {
            tempIqamaIshaOffset = defaultIqamaOffsets.isha
            if soundEnabled  { SoundPlayer.shared.play("click") }
            if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .font(.caption)
        .foregroundColor(.red)
        .buttonStyle(BorderlessButtonStyle())
    }
}
.environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)

            // MARK: – تعديل أوقات الأذان
Section(
    header: Text(isArabic ? "تعديل أوقات الأذان" : "Edit Azan Times")
        .font(.headline),
    footer: Text(isArabic
        ? "بعد التعديل الوقت اذان يتم تلقائي حسب التوقيت بشكل دقيق بعد ذالك لا تحتاج الى التعديل"
        : "After editing, azan times will update automatically according to accurate timings, so no further adjustments are needed.")
        .font(.footnote)
        .foregroundColor(.gray)
) {
    if let t = settingsTimings {
        // تحويل الأوقات الأصلية إلى صيغة 12-ساعة
        let origFajr    = parser.date(from: t.fajr).map { formatter12.string(from: $0) } ?? t.fajr
        let origSunrise = parser.date(from: t.sunrise).map { formatter12.string(from: $0) } ?? t.sunrise
        let origDhuhr   = parser.date(from: t.dhuhr).map { formatter12.string(from: $0) } ?? t.dhuhr
        let origAsr     = parser.date(from: t.asr).map { formatter12.string(from: $0) } ?? t.asr
        let origMaghrib = parser.date(from: t.maghrib).map { formatter12.string(from: $0) } ?? t.maghrib
        let origIsha    = parser.date(from: t.isha).map { formatter12.string(from: $0) } ?? t.isha

        PrayerAzanRow(name: isArabic ? "الفجر" : "Fajr",
                      original: origFajr,
                      offset: $tempAzanFajrOffset)
        PrayerAzanRow(name: isArabic ? "الشروق" : "Sunrise",
                      original: origSunrise,
                      offset: $tempAzanSunriseOffset)
        PrayerAzanRow(name: isArabic ? "الظهر" : "Dhuhr",
                      original: origDhuhr,
                      offset: $tempAzanDhuhrOffset)
        PrayerAzanRow(name: isArabic ? "العصر" : "Asr",
                      original: origAsr,
                      offset: $tempAzanAsrOffset)
        PrayerAzanRow(name: isArabic ? "المغرب" : "Maghrib",
                      original: origMaghrib,
                      offset: $tempAzanMaghribOffset)
        PrayerAzanRow(name: isArabic ? "العشاء" : "Isha",
                      original: origIsha,
                      offset: $tempAzanIshaOffset)
    } else {
        Text(isArabic ? "جاري تحميل الأوقات…" : "Loading times…")
            .foregroundColor(.gray)
    }
}
.environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
.navigationTitle(isArabic ? "تحرير الإعدادات" : "Edit Settings")
.navigationBarItems(
    leading: Button(isArabic ? "إلغاء" : "Cancel") {
        showEditIqama = false
    },
    trailing: Button(isArabic ? "حفظ" : "Save") {
        // حفظ القيم الجديدة
        iqamaFajrOffset    = tempIqamaFajrOffset
        iqamaDhuhrOffset   = tempIqamaDhuhrOffset
        iqamaAsrOffset     = tempIqamaAsrOffset
        iqamaMaghribOffset = tempIqamaMaghribOffset
        iqamaIshaOffset    = tempIqamaIshaOffset

        azanFajrOffset     = tempAzanFajrOffset
        azanSunriseOffset  = tempAzanSunriseOffset
        azanDhuhrOffset    = tempAzanDhuhrOffset
        azanAsrOffset      = tempAzanAsrOffset
        azanMaghribOffset  = tempAzanMaghribOffset
        azanIshaOffset     = tempAzanIshaOffset

        // إعادة جدولة الإشعارات بناءً على offsets الجديدة
        if let t = prayerTimes {
            schedulePrayerNotifications(t)
            if notificationsEnabled {
                scheduleDhikrNotifications(t)
            }
        }

        // إغلاق الشيت
        showEditIqama = false
    }
)
.onAppear {
    // تهيئة القيم المؤقتة عند فتح الشيت
    tempIqamaFajrOffset    = iqamaFajrOffset
    tempIqamaDhuhrOffset   = iqamaDhuhrOffset
    tempIqamaAsrOffset     = iqamaAsrOffset
    tempIqamaMaghribOffset = iqamaMaghribOffset
    tempIqamaIshaOffset    = iqamaIshaOffset

    tempAzanFajrOffset     = azanFajrOffset
    tempAzanSunriseOffset  = azanSunriseOffset
    tempAzanDhuhrOffset    = azanDhuhrOffset
    tempAzanAsrOffset      = azanAsrOffset
    tempAzanMaghribOffset  = azanMaghribOffset
    tempAzanIshaOffset     = azanIshaOffset

    if let _ = locationManager.location {
        PrayerTimesServiceOffline.shared.getPrayerTimes(date: Date()) { newTimings in
            DispatchQueue.main.async {
                settingsTimings = newTimings
                // تحديث الأوقات الأصلية في الصيغة 12-ساعة
                if let d = parser.date(from: newTimings.fajr)    { origFajr    = formatter12.string(from: d) }
                if let d = parser.date(from: newTimings.sunrise) { origSunrise = formatter12.string(from: d) }
                if let d = parser.date(from: newTimings.dhuhr)   { origDhuhr   = formatter12.string(from: d) }
                if let d = parser.date(from: newTimings.asr)     { origAsr     = formatter12.string(from: d) }
                if let d = parser.date(from: newTimings.maghrib) { origMaghrib = formatter12.string(from: d) }
                if let d = parser.date(from: newTimings.isha)    { origIsha    = formatter12.string(from: d) }
            }
        }
    }
}



}
.accentColor(.primary)
.buttonStyle(SoundButtonStyle())
.preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}
}
}


}



// 1) ضع هذا التعريف فوق ContentView أو في نهاية الملف:
private struct PrayerAzanRow: View {
    let name: String
    let original: String    // نص الوقت بصيغة 12-ساعة
    @Binding var offset: Int

    @AppStorage("soundEnabled")  private var soundEnabled  = false
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("selectedLanguage") private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    private var isArabic: Bool {
        selectedLanguage == "ar"
    }

    private let parser: DateFormatter = {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        f.amSymbol = "ص"; f.pmSymbol = "م"
        return f
    }()
    private let formatter12: DateFormatter = {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        f.amSymbol = "ص"; f.pmSymbol = "م"
        return f
    }()

    private var original12: String {
        guard let d = parser.date(from: original) else { return original }
        return formatter12.string(from: d)
    }
    private var adjusted12: String {
        guard let d = parser.date(from: original) else { return original12 }
        let adjDate = Calendar.current.date(byAdding: .minute, value: offset, to: d) ?? d
        return formatter12.string(from: adjDate)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body).bold()

                Text(isArabic
                    ? "الأساسي: \(original12)"
                    : "Original: \(original12)"
                )
                .font(.caption)
                .foregroundColor(.gray)

                Text(isArabic
                    ? "بعد التعديل: \(adjusted12)"
                    : "Adjusted: \(adjusted12)"
                )
                .font(.caption.monospacedDigit())
                .foregroundColor(.green)
            }
            Spacer()
            HStack(spacing: 12) {
                Stepper("", value: $offset, in: -60...60)
                    .labelsHidden()
                    .frame(minWidth: 80)
                    .onChange(of: offset) { _ in
                        if soundEnabled  { SoundPlayer.shared.play("click") }
                        if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                    }

                Button(isArabic ? "افتراضي" : "Default") {
                    offset = 0
                    if soundEnabled  { SoundPlayer.shared.play("click") }
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                }
                .font(.caption)
                .foregroundColor(.red)
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
    }
}
    
    














                        struct DhikrCard: View {
                            let type: DhikrType
                            let fontSize: CGFloat

                            var body: some View {
                                HStack {
                                    Image(systemName: type.icon)
                                        .font(.system(size: fontSize))
                                        .foregroundColor(.white)
                                        .frame(width: fontSize*2, height: fontSize*2)
                                        .background(type.color)
                                        .clipShape(Circle())
                                    Text(type.rawValue)
                                        .font(.system(size: fontSize, weight:.semibold))
                                        .foregroundColor(.white)
                                        .padding(.leading,10)
                                    Spacer()
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: fontSize*0.8))
                                        .foregroundColor(.gray)
                                }
                                .padding(18)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(20)
                            }
                        }

                        //هنا 55

                        // MARK: - DhikrDetailView


                        // MARK: - AddDhikrView



                        // 1) ضع هذا خارج أي struct آخر:
                        struct CustomTextView: UIViewRepresentable {
                            @Binding var text: String
                            var placeholder: String
                            var textColor: UIColor = .label  // الافتراضي أسود

                            func makeUIView(context: Context) -> UITextView {
                                let tv = UITextView()
                                tv.delegate = context.coordinator
                                tv.font = .systemFont(ofSize: 16)
                                tv.text = text.isEmpty ? placeholder : text
                                tv.textColor = text.isEmpty ? .gray : textColor
                                return tv
                            }

                            func updateUIView(_ uiView: UITextView, context: Context) {
                                uiView.text = text.isEmpty ? placeholder : text
                                uiView.textColor = text.isEmpty ? .gray : textColor
                            }

                            func makeCoordinator() -> Coordinator {
                                Coordinator(self)
                            }

                            class Coordinator: NSObject, UITextViewDelegate {
                                var parent: CustomTextView
                                init(_ parent: CustomTextView) { self.parent = parent }

                                func textViewDidBeginEditing(_ textView: UITextView) {
                                    if textView.text == parent.placeholder {
                                        textView.text = ""
                                        textView.textColor = parent.textColor
                                    }
                                }

                                func textViewDidChange(_ textView: UITextView) {
                                    parent.text = textView.text
                                }

                                func textViewDidEndEditing(_ textView: UITextView) {
                                    if textView.text.isEmpty {
                                        textView.text = parent.placeholder
                                        textView.textColor = .gray
                                    }
                                }
                            }
                        }









struct SettingsView: View {
    // MARK: – AppStorage
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled")    private var darkModeEnabled    = true
    @AppStorage("soundEnabled")       private var soundEnabled       = false
    @AppStorage("hapticEnabled")      private var hapticEnabled      = true
    @AppStorage("selectedLanguage")   private var selectedLanguage   = Locale
        .current
        .language
        .languageCode?
        .identifier
        ?? "ar"

    // MARK: – Environment
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme)    var colorScheme

    // MARK: – Share & Suggestion State
    @State private var isSharePresented   = false
    @State private var isSuggestPresented = false
    @State private var suggestionText     = ""

    private var shareText: String {
        selectedLanguage == "ar"
            ? "جرب تطبيق أذان وأذكار المسلم الرائع!"
            : "Try the amazing Muslim prayer & dhikr app!"
    }
    private let shareURL = URL(string:
        "https://tools4cydia.info/filetools/ipa/Salatuk%20Pro.ipa"
    )!

    // MARK: – Translations
    private var t_settings: String       { selectedLanguage == "ar" ? "الإعدادات"          : "Settings" }
    private var t_general: String        { selectedLanguage == "ar" ? "الإعدادات العامة"   : "General Settings" }
    private var t_dhikrNotif: String     { selectedLanguage == "ar" ? "إشعارات الأذكار"    : "Dhikr Notifications" }
    private var t_touchSounds: String    { selectedLanguage == "ar" ? "أصوات اللمس"         : "Touch Sounds" }
    private var t_haptic: String         { selectedLanguage == "ar" ? "الاهتزاز"            : "Haptic Feedback" }
    private var t_darkMode: String       { selectedLanguage == "ar" ? "الوضع الليلي"        : "Dark Mode" }
    private var t_language: String       { selectedLanguage == "ar" ? "اللغة"               : "Language" }
    private var t_about: String          { selectedLanguage == "ar" ? "حول التطبيق"         : "About" }
    private var t_version: String        { selectedLanguage == "ar" ? "الإصدار"             : "Version" }
    private var t_addSuggestion: String  { selectedLanguage == "ar" ? "أضف اقتراح"          : "Add Suggestion" }
    private var t_shareApp: String       { selectedLanguage == "ar" ? "مشاركة التطبيق"      : "Share App" }
    private var t_contactUs: String      { selectedLanguage == "ar" ? "تواصل معنا"          : "Contact Us" }
    private var t_twitter: String        { selectedLanguage == "ar" ? "تويتر"               : "Twitter" }
    private var t_done: String           { selectedLanguage == "ar" ? "تم"                  : "Done" }
    private var t_cancel: String         { selectedLanguage == "ar" ? "إلغاء"               : "Cancel" }
    private var t_send: String           { selectedLanguage == "ar" ? "إرسال"               : "Send" }
    private var t_suggestPrompt: String  { selectedLanguage == "ar"
        ? "شاركنا أفكارك لتحسين التطبيق"
        : "Share your ideas to improve the app"
    }
    private var t_newSuggestion: String  { selectedLanguage == "ar" ? "اقتراح جديد"         : "New Suggestion" }

    var body: some View {
        NavigationView {
            Form {
                // MARK: - General Settings
                Section(header: sectionHeader(title: t_general, icon: "gearshape.fill")) {
                    SettingRow(icon: "bell.fill", color: .red,    title: t_dhikrNotif,  toggle: $notificationsEnabled)
                    SettingRow(icon: "speaker.wave.2.fill", color: .blue, title: t_touchSounds, toggle: $soundEnabled)
                    SettingRow(icon: "iphone.radiowaves.left.and.right", color: .green, title: t_haptic,      toggle: $hapticEnabled)
                    SettingRow(icon: "moon.fill", color: .purple, title: t_darkMode,     toggle: $darkModeEnabled)

                    // MARK: - Language Selection Row
                    Menu {
                        Button("العربية") {
                            selectedLanguage = "ar"
                            if soundEnabled { SoundPlayer.shared.play("click") }
                        }
                        Button("English") {
                            selectedLanguage = "en"
                            if soundEnabled { SoundPlayer.shared.play("click") }
                        }
                    } label: {
HStack {
                        Text(t_language)
                        Spacer()
                        Text(selectedLanguage == "ar" ? "العربية" : "English")
                            .foregroundColor(.secondary)
                        Image(systemName: "globe.europe.africa")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
}

                // MARK: - About
                Section(header: sectionHeader(title: t_about, icon: "info.circle.fill")) {
                    InfoRow(title: t_version, value: "3.6.0")
                    ActionRow(icon: "lightbulb.fill", color: .orange, title: t_addSuggestion) {
                        isSuggestPresented = true
                    }
                }

                // MARK: - Share App
                Section {
                    ActionRow(icon: "square.and.arrow.up.fill", color: .green, title: t_shareApp) {
                        isSharePresented = true
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ActivityView(activityItems: [shareText, shareURL])
                    }
                }

                // MARK: - Contact Us
                Section(header: sectionHeader(title: t_contactUs, icon: "envelope.fill")) {
                    SocialMediaRow(
                        icon: "x.circle.fill",
                        color: .black,
                        title: t_twitter,
                        handle: "@Tools4cydia",
                        url: "https://twitter.com/Tools4cydia"
                    )
                    SocialMediaRow(
                        icon: "x.circle.fill",
                        color: .black,
                        title: t_twitter,
                        handle: "@Salatuk_Pro",
                        url: "https://twitter.com/Salatuk_Pro"
                    )
                }
            }
            .navigationBarTitle(t_settings, displayMode: .inline)
            .navigationBarItems(trailing: doneButton)
            .background(backgroundView)
            .sheet(isPresented: $isSuggestPresented) { suggestionSheet }
        }
        .accentColor(colorScheme == .dark ? .white : .blue)
        .environment(\.layoutDirection, .leftToRight)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }

    // MARK: - Done Button
    private var doneButton: some View {
        Button(t_done) {
            presentationMode.wrappedValue.dismiss()
        }
        .fontWeight(.medium)
        .buttonStyle(SoundButtonStyle())
    }

    // MARK: - Background
    private var backgroundView: some View {
        Color.clear
            .background(
                colorScheme == .dark
                    ? LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.9), Color.gray.opacity(0.2)]),
                        startPoint: .top, endPoint: .bottom
                      )
                    : LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.9), Color.gray.opacity(0.1)]),
                        startPoint: .top, endPoint: .bottom
                      )
            )
    }

    // MARK: - Suggestion Sheet
    private var suggestionSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(t_suggestPrompt)
                    .font(.headline)
                    .padding(.top, 20)
                TextEditor(text: $suggestionText)
                    .frame(minHeight: 150)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                Spacer()
            }
            .padding(.horizontal)
            .navigationBarTitle(t_newSuggestion, displayMode: .inline)
            .navigationBarItems(
                leading: Button(t_cancel) {
                    suggestionText = ""
                    isSuggestPresented = false
                },
                trailing: Button(t_send) {
                    sendSuggestion()
                }
                .disabled(suggestionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }

    // MARK: - Section Header Helper
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Suggestion Email Action
    private func sendSuggestion() {
        let email = "salatuk.t4c@gmail.com"
        let subject = selectedLanguage == "ar"
            ? "اقتراح من مستخدم"
            : "Suggestion from User"
        let body = suggestionText
        let escSub = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let escBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)?subject=\(escSub)&body=\(escBody)") {
            UIApplication.shared.open(url)
        }
        suggestionText = ""
        isSuggestPresented = false
    }
}


// ثم أعد تشغيل التطبيق، ويجب أن يتوقف الـ crash عند فتح الإعدادات.


// MARK: - Custom Rows

struct SettingRow: View {
    let icon: String
    let color: Color
    let title: String
    @Binding var toggle: Bool

    var body: some View {
        HStack {
            Toggle("", isOn: $toggle)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .labelsHidden()
                .padding(.trailing, 8)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
        }
        .padding(.vertical, 8)
    }
}

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(value)
                .foregroundColor(.secondary)
            Spacer()
            Text(title)
                .frame(alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

struct ActionRow: View {
    let icon: String
    let color: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
                Text(title)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(SoundButtonStyle())
    }
}

struct SocialMediaRow: View {
    let icon: String
    let color: Color
    let title: String
    let handle: String
    let url: String

    var body: some View {
        Button(action: {
            if let u = URL(string: url) { UIApplication.shared.open(u) }
        }) {
            HStack {
                Image(systemName: "arrow.up.left")
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(handle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(SoundButtonStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.light)
        SettingsView()
            .preferredColorScheme(.dark)
    }
}




    // MARK: - Previews

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
