import SwiftUI
import MapKit
import CoreLocation
import UIKit

// MARK: – Location Manager

class SimpleLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last, loc.horizontalAccuracy <= 50 else { return }
        DispatchQueue.main.async { self.lastLocation = loc }
    }
}

// MARK: – Annotation Model

struct MosqueAnnotation: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem

    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }

    var title: String {
        let name = mapItem.name ?? ""
        let hasEnglish = name.range(of: "[A-Za-z]", options: .regularExpression) != nil
        if hasEnglish { return name }
        if name.contains("مسجد") || name.contains("جامع") { return name }
        return "مسجد \(name)"
    }

    var originalTitle: String { mapItem.name ?? "" }

    func distance(from location: CLLocation?) -> String {
        guard
            let userLoc = location,
            let meters = mapItem.placemark.location?.distance(from: userLoc)
        else { return "?" }
        return meters >= 1_000
            ? String(format: "%.1f كم", meters/1_000)
            : String(format: "%.0f م", meters)
    }
}

// MARK: – List & Map View

struct MosqueListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var locManager = SimpleLocationManager()
    @State private var annotations: [MosqueAnnotation] = []
    @State private var isSearching = false

    // الآن نستخدم span لتغيير الزوم بسهولة
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    @State private var hasCentered = false
    @State private var lastSearchDate = Date.distantPast
    @State private var lastSearchLocation: CLLocation?
    @State private var showOptions = false
    @State private var selectedMosque: MosqueAnnotation?

    private let movingSpeedThreshold: CLLocationSpeed = 5
    private let stationaryDistanceThreshold: CLLocationDistance = 50

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // ───── Map ─────
                Map(
                    coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: annotations
                ) { mosque in
                    MapAnnotation(coordinate: mosque.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2).foregroundColor(.green)
                            Text(mosque.title)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(5)
                        }
                        .onTapGesture {
                            selectedMosque = mosque
                            showOptions = true
                        }
                    }
                }
                .frame(height: 400)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.top, 10)

                // ───── Zoom Controls ─────
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Button {
                                // zoom in
                                region.span.latitudeDelta /= 2
                                region.span.longitudeDelta /= 2
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            Button {
                                // zoom out
                                region.span.latitudeDelta *= 2
                                region.span.longitudeDelta *= 2
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
            }

            if isSearching {
                ProgressView("جاري البحث عن المساجد والجوامع...")
                    .padding(.bottom, 10)
            }

            // ───── List ─────
            List(annotations) { mosque in
                Button {
                    selectedMosque = mosque
                    showOptions = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mosque.originalTitle.contains("جامع") || mosque.originalTitle.contains("مسجد")
                                 ? mosque.originalTitle
                                 : mosque.title)
                                .font(.headline)
                            Text("يبعد \(mosque.distance(from: locManager.lastLocation))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.left")
                            .rotationEffect(.degrees(180))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.plain)
        }
        .navigationBarTitle("مساجد قريبة", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Back button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                        Text("رجوع")
                    }
                }
                .foregroundColor(.blue)
            }
            // Refresh button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard let loc = locManager.lastLocation else { return }
                    centerMap(on: loc)
                    performSmartSearch(ifNeededFor: loc)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        // Swipe from edges to go back
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { v in
                    let w = UIScreen.main.bounds.width
                    if v.startLocation.x < 20 && v.translation.width > 100 ||
                       v.startLocation.x > w - 20 && v.translation.width < -100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
        .confirmationDialog("فتح الموقع", isPresented: $showOptions, titleVisibility: .visible) {
            Button("فتح في خرائط جوجل") { openInGoogleMaps(selectedMosque) }
            Button("فتح في الخرائط") {
                selectedMosque?.mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                ])
            }
            Button("إلغاء", role: .cancel) { }
        }
        .onAppear {
            if let loc = locManager.lastLocation, !hasCentered {
                centerMap(on: loc)
                performSmartSearch(ifNeededFor: loc)
                hasCentered = true
            }
        }
        .onChange(of: locManager.lastLocation) { newLoc in
            guard let loc = newLoc else { return }
            if !hasCentered {
                centerMap(on: loc)
                hasCentered = true
            }
            performSmartSearch(ifNeededFor: loc)
        }
    }  // end body

    // MARK: – Map helpers

    private func centerMap(on location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: region.span // نحافظ على نفس span
        )
    }

    private func performSmartSearch(ifNeededFor location: CLLocation) {
        let now = Date()
        let speed = max(0, location.speed)

        if speed >= movingSpeedThreshold {
            if now.timeIntervalSince(lastSearchDate) >= 30 {
                findMosques(around: location)
                lastSearchDate = now
            }
        } else {
            if let lastLoc = lastSearchLocation {
                if location.distance(from: lastLoc) >= stationaryDistanceThreshold {
                    findMosques(around: location)
                    lastSearchLocation = location
                }
            } else {
                findMosques(around: location)
                lastSearchLocation = location
            }
        }
    }

    private func findMosques(around location: CLLocation) {
        isSearching = true
        let queries = ["جامع", "مسجد", "mosque", "masjid"]
        var allItems: [MKMapItem] = []
        let searchRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: region.span
        )

        let group = DispatchGroup()
        for q in queries {
            group.enter()
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = q
            req.region = searchRegion
            MKLocalSearch(request: req).start { resp, _ in
                if let items = resp?.mapItems {
                    allItems.append(contentsOf: items)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let unique = Dictionary(grouping: allItems, by: {
                NSValue(mkCoordinate: $0.placemark.coordinate)
            }).compactMap { $0.value.first }

            annotations = unique
                .sorted {
                    ($0.placemark.location?.distance(from: location) ?? .infinity) <
                    ($1.placemark.location?.distance(from: location) ?? .infinity)
                }
                .map { MosqueAnnotation(mapItem: $0) }
            isSearching = false
        }
    }

    private func openInGoogleMaps(_ mosque: MosqueAnnotation?) {
        guard
            let m = mosque,
            let loc = m.mapItem.placemark.location
        else { return }

        let lat = loc.coordinate.latitude
        let lon = loc.coordinate.longitude
        let schemeURL = URL(string: "comgooglemaps://?q=\(lat),\(lon)&zoom=14")!
        let webURL    = URL(string: "https://maps.google.com/?q=\(lat),\(lon)")!

        if UIApplication.shared.canOpenURL(schemeURL) {
            UIApplication.shared.open(schemeURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: – Preview

struct MosqueListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MosqueListView()
        }
    }
}
