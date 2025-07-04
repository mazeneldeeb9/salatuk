import SwiftUI
import CoreLocation
import CoreHaptics
import AudioToolbox

struct GpsBoslaView: View {
    // قراءة اللغة المختارة من AppStorage (مررة من الجذر)
    @AppStorage("selectedLanguage") private var selectedLanguage = Locale.current.language.languageCode?.identifier ?? "ar"
    // لإغلاق هذا العرض عند الضغط على زر الرجوع
    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var compassHeading    = CompassHeading()
    @StateObject private var locationManager   = QiblaLocationManager()
    @State private var engine: CHHapticEngine?
    @State private var isPointingToQibla = false
    @State private var qiblaAngle: Double   = 0

    private let kaabaCoordinate   = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    private let accuracyThreshold : Double = 5.0

    init() {
        prepareHaptics()
    }

    var body: some View {
        ZStack {
            // الخلفية
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.2, blue: 0.3),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                center: .center,
                startRadius: 5,
                endRadius: 500
            )
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                // عنوان الشاشة
                Text("Qibla.Title")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Spacer()

                compassView
                    .padding(.bottom, 40)

                infoCard

                Spacer()

                // رسالة التوجيه
                Text(isPointingToQibla
                     ? "Qibla.Message.Pointing"
                     : "Qibla.Message.Search"
                )
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(isPointingToQibla ? .green : .white)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        // — ربط مع الـ NavigationView الخارجي —
        .navigationTitle("Qibla.Title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(
      placement: selectedLanguage == "ar"
        ? .navigationBarTrailing   // في عربي: على اليمين
        : .navigationBarLeading    // في إنجليزي: على اليسار
    ) {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(
              systemName: selectedLanguage == "ar"
                ? "chevron.right"      // سهم إلى اليمين
                : "chevron.left"       // سهم إلى اليسار
            )
            .imageScale(.large)
            .foregroundColor(.white)
        }
    }
}
        // تحديثات القبلة
        .onAppear { calculateQiblaDirection() }
        .onChange(of: locationManager.location)   { _ in calculateQiblaDirection() }
        .onChange(of: compassHeading.degrees)     { _ in checkQiblaDirection() }
    }

    // MARK: – البوصلة الدوّارة
    private var compassView: some View {
        ZStack {
            // الحلقة الخارجية
            Circle().stroke(Color.gray.opacity(0.3), lineWidth: 10)
                .frame(width: 300, height: 300)

            // علامات
            ForEach(0..<36) { i in
                Rectangle()
                    .fill(i % 9 == 0 ? Color.white : Color.gray.opacity(0.7))
                    .frame(width: i % 9 == 0 ? 3 : 1,
                           height: i % 9 == 0 ? 20 : 10)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(i) * 10))
            }

            // N E S W
            Group {
                Text("N").offset(y: -145)
                Text("E").offset(x: 145)
                Text("S").offset(y: 145)
                Text("W").offset(x: -145)
            }
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)

            // مؤشر القبلة
            Circle()
                .fill(isPointingToQibla ? Color.green : Color.white)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(qiblaAngle))
        }
        .rotationEffect(.degrees(compassHeading.degrees))
        .animation(.easeInOut, value: compassHeading.degrees)
        // السهم الثابت + الاهتزاز
        .overlay(
            Image(systemName: "arrow.up")
                .resizable().frame(width: 30, height: 30)
                .foregroundColor(isPointingToQibla ? .green : .red)
                .shadow(color: isPointingToQibla ? .green : .red,
                        radius: isPointingToQibla ? 10 : 5)
                .offset(y: -60)
                .modifier(ShakeEffect(shakeNumber: isPointingToQibla ? 3 : 0))
        )
        // الإطار الداخلي
        .overlay(
            Circle()
                .stroke(isPointingToQibla ? Color.green : Color.red, lineWidth: 3)
                .frame(width: 200, height: 200)
        )
    }

    // MARK: – بطاقة المعلومات
    private var infoCard: some View {
        VStack(spacing: 15) {
infoRow(title: "Compass.Heading.Title", value: "\(Int(compassHeading.degrees))°")
infoRow(title: "Qibla.Heading.Title",    value: "\(Int(qiblaAngle))°")
infoRow(
  title: "Qibla.Diff.Title",
  value: "\(Int(abs(angleDifference())))°",
  valueColor: isPointingToQibla ? .green : .white
)

        }
        .font(.headline)
        .foregroundColor(.gray)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.3).opacity(0.8))
        )
    }

private func infoRow(title: String, value: String, valueColor: Color = .white) -> some View {
    HStack {
        Text(LocalizedStringKey(title))  // يحول السلسلة إلى مفتاح ترجمة
        Spacer()
        Text(value)
            .foregroundColor(valueColor)
            .frame(width: 60, alignment: .trailing)
    }
}


    // MARK: – حساب الاتجاه وتنبيه الهابتكس
    private func angleDifference() -> Double {
        let diff = ((qiblaAngle - compassHeading.degrees) + 360)
            .truncatingRemainder(dividingBy: 360)
        return diff > 180 ? 360 - diff : diff
    }

    private func checkQiblaDirection() {
        let diff = angleDifference()
        let wasPointing = isPointingToQibla
        isPointingToQibla = diff <= accuracyThreshold
        if isPointingToQibla && !wasPointing {
            triggerHapticSuccess()
        }
    }

    private func calculateQiblaDirection() {
        guard let userLoc = locationManager.location?.coordinate else { return }
        let lat1 = userLoc.latitude.toRadians()
        let lon1 = userLoc.longitude.toRadians()
        let lat2 = kaabaCoordinate.latitude.toRadians()
        let lon2 = kaabaCoordinate.longitude.toRadians()

        let y = sin(lon2 - lon1) * cos(lat2)
        let x = cos(lat1)*sin(lat2)
            - sin(lat1)*cos(lat2)*cos(lon2 - lon1)
        let deg = atan2(y, x).toDegrees()
        qiblaAngle = fmod(deg + 360, 360)
    }

    private func prepareHaptics() {
        if #available(iOS 13.0, *) {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print("Haptics init error:", error.localizedDescription)
            }
        }
    }

    private func triggerHapticSuccess() {
        if #available(iOS 13.0, *) {
            if let engine = engine {
                var events = [CHHapticEvent]()
                for i in 0..<3 {
                    let p = Float(1.0 - Double(i) * 0.2)
                    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: p)
                    let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: p)
                    let event = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [intensity, sharpness],
                        relativeTime: Double(i) * 0.2
                    )
                    events.append(event)
                }
                do {
                    let pattern = try CHHapticPattern(events: events, parameters: [])
                    let player  = try engine.makePlayer(with: pattern)
                    try player.start(atTime: 0)
                } catch {
                    print("Haptics play error:", error.localizedDescription)
                }
            } else {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
}

// MARK: – مساعد الموقع والاتجاه

class QiblaLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    private let locManager = CLLocationManager()
    override init() {
        super.init()
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.requestWhenInUseAuthorization()
        locManager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        location = locs.last
    }
}

class CompassHeading: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var degrees: Double = 0
    private let locManager = CLLocationManager()
    override init() {
        super.init()
        locManager.delegate = self
        locManager.headingFilter = 1
        locManager.startUpdatingHeading()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.degrees = newHeading.trueHeading
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var shakeNumber: CGFloat
    var animatableData: CGFloat { get { shakeNumber } set { shakeNumber = newValue } }
    func effectValue(size: CGSize) -> ProjectionTransform {
        guard shakeNumber != 0 else { return ProjectionTransform(.identity) }
        let angle = sin(shakeNumber * .pi * 4) * 0.05
        return ProjectionTransform(CGAffineTransform(rotationAngle: angle))
    }
}

// MARK: – معاينة

struct GpsBoslaView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GpsBoslaView()
        }
        .environment(\.locale, .init(identifier: "en"))
        .environment(\.layoutDirection, .leftToRight)
    }
}
