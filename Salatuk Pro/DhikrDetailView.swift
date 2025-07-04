

import SwiftUI
import UIKit
import AVFoundation
import Foundation
import CoreLocation
import UserNotifications
import AudioToolbox
import MapKit

extension Int {
    /// يحول الرقم إلى نص بأرقام عربية (هندية)
    var arabicDigits: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}


extension Text {
    static func arabicNumber(_ number: Int) -> Text {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.numberStyle = .decimal
        let str = formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        return Text(str)
    }
}

struct SmoothButtonStyle: ButtonStyle {
    var hapticEnabled: Bool
    var action: () -> Void
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    if hapticEnabled {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    action()
                }
            }
    }
}
/// ButtonStyle لإعطاء هابتيك وتنفيذ إجراء عند الرفع
struct HapticButtonStyle: ButtonStyle {
    let hapticEnabled: Bool
    let action: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { isPressed in
                if !isPressed {
                    if hapticEnabled {
                        let generator = UIImpactFeedbackGenerator(style: .rigid)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                    action()
                }
            }
    }
}




class CustomDhikr: ObservableObject, Identifiable {
    let id = UUID()
    @Published var text: String
    @Published var note: String?
    @Published var repetition: Int?

    init(text: String, note: String? = nil, repetition: Int? = nil) {
        self.text = text
        self.note = note
        self.repetition = repetition
    }
}



class CustomDhikrsViewModel: ObservableObject {
    @Published var customDhikrs: [CustomDhikr] = []

    func addNewDhikr(text: String, note: String?, repetition: Int?) {
        let dhikr = CustomDhikr(text: text, note: note, repetition: repetition)
        customDhikrs.append(dhikr)
    }
}






// تدرّج الألوان المشترك
private let backgroundGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.05, green: 0.05, blue: 0.15),    // أزرق غامق ليلي
        Color(red: 0.2, green: 0.1, blue: 0.3),       // بنفسجي غامق ليلي
        Color(red: 0.1, green: 0.15, blue: 0.3),      // أزرق غامق ليلي آخر
        Color(red: 0.05, green: 0.15, blue: 0.1),     // أخضر غامق ليلي
        Color(red: 0.15, green: 0.05, blue: 0.25)     // بنفسجي غامق ليلي آخر
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct RepetitionCounter: View {
    let current: Int
    let total: Int
    let color: Color
    let fontSize: CGFloat

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(current) / CGFloat(total)
    }

    var body: some View {
        let lineWidth = fontSize * 0.15
        let diameter = fontSize * 2.3

        ZStack {
            // 1. الخلفية مع تأثير ضوئي خفيف
            


            // 2. الحلقة الخلفية مع تدرج لوني
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.1), color.opacity(0.3)]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: lineWidth
                )

            // 3. شريط التقدم مع تحسينات للسرعة والمظهر
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)


            // 4. المحتوى الداخلي مع تحسينات للقراءة
            VStack(spacing: fontSize * 0.05) {
                Text("\(current)")
                    .font(.system(size: fontSize * 0.8, weight: .black, design: .rounded))
                    .foregroundColor(color)
                    .environment(\.locale, Locale(identifier: "ar"))

                RoundedRectangle(cornerRadius: lineWidth/2)
                    .fill(color.opacity(0.7))
                    .frame(width: fontSize * 0.4, height: lineWidth * 0.9)
                    .overlay(
                        RoundedRectangle(cornerRadius: lineWidth/2)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )

                Text("\(total)")
                    .font(.system(size: fontSize * 0.6, weight: .bold, design: .rounded))
                    .foregroundColor(color.opacity(0.7))
                    .environment(\.locale, Locale(identifier: "ar"))
            }
        }
        .frame(width: diameter, height: diameter)
        .overlay(
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 0.5)
                .padding(lineWidth/2)
        )
    }
}// صفحة دعاء غفران
struct GhofranView: View {
    private let types: [DhikrType] = [
        .ghofranDonub, .ghofranQulub, .ghofranMaal,
        .ghofranMard, .ghofranSafar, .ghofranAila
    ]
    private let columns = [ GridItem(.flexible()), GridItem(.flexible()) ]
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(types, id: \.self) { type in
                        NavigationLink(destination: destinationView(for: type)) {
                            GhofranCard(type: type)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("دعاء غفران")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)    // إخفاء زر الرجوع الافتراضي
        .toolbar {
            // زرّ "رجوع" مخصّص
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                        Text("Common.Back")
                    }
                }
                .foregroundColor(.white)
            }
        }
        // شريحة السحب من الحافة للرجوع
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
      let screenWidth = UIScreen.main.bounds.width
      
      // إذا بدأ السحب من آخر 20 نقطة على اليمين، وانزاح لليسار بما يكفي
      if value.startLocation.x > screenWidth - 20 && value.translation.width < -100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }

    @ViewBuilder
    private func destinationView(for type: DhikrType) -> some View {
        switch type {
        case .ghofranDonub:
            GhofranDonubImagesView()
        case .ghofranQulub:
            GhofranQulubImagesView()
        default:
            DhikrDetailView(dhikrType: type)
        }
    }
}





// استخرجت هنا فقط عرض البطاقة الصغيرة لتختصر الكود
struct GhofranCard: View {
    let type: DhikrType
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(type.icon)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 120)
                .clipped()
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2))
            Rectangle().fill(Color.black.opacity(0.4)).frame(height: 30)
            Text(type.rawValue)
                .font(.subheadline).foregroundColor(.white)
                .padding(.leading, 6).padding(.bottom, 6)
        }
        .cornerRadius(10)
    }
}






struct GhofranDonubImagesView: View {
    // أضف هنا أسماء الصور كما هي في Assets.xcassets
    private let images = [
        "f1",
        "gpsbosla",
        "f1",
        "f1"
    ]
    @State private var pageIndex = 0

    var body: some View {
        VStack {
            Spacer()

            // صفحة الصور
            TabView(selection: $pageIndex) {
                ForEach(images.indices, id: \.self) { idx in
                    Image(images[idx])
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                        .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 320)

            Spacer()

            // شريط التحكم
            HStack {
                // زر السابق
                Button(action: {
                    if pageIndex > 0 {
                        pageIndex -= 1
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(pageIndex == 0)

                Spacer()

                // رقم الصفحة
                Text("\(pageIndex + 1) / \(images.count)")
                    .font(.headline)

                Spacer()

                // زر التالي
                Button(action: {
                    if pageIndex + 1 < images.count {
                        pageIndex += 1
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(pageIndex + 1 == images.count)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .navigationTitle("غفران الذنوب")
        .navigationBarTitleDisplayMode(.inline)
    }
}



// شاشة عرض صور ghofranQulub
struct GhofranQulubImagesView: View {
    // تأكد أنّك أضفت هذه الصور إلى Assets.xcassets بنفس الأسماء:
    private let images = [
        "f1",
        "gpsbosla",
        "f1",
        "gpsbosla"
    ]
    @State private var pageIndex = 0

    var body: some View {
        VStack {
            Spacer()

            TabView(selection: $pageIndex) {
                ForEach(images.indices, id: \.self) { idx in
                    Image(images[idx])
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                        .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 320)

            Spacer()

            HStack {
                Button(action: {
                    if pageIndex > 0 { pageIndex -= 1 }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(pageIndex == 0)

                Spacer()

                Text("\(pageIndex + 1) / \(images.count)")
                    .font(.headline)

                Spacer()

                Button(action: {
                    if pageIndex + 1 < images.count { pageIndex += 1 }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(pageIndex + 1 == images.count)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .navigationTitle("غفران القلوب")
        .navigationBarTitleDisplayMode(.inline)
    }
}



// صفحة دعاء توبة
struct TobaView: View {
    private let types: [DhikrType] = [
        .tobaPerson, .tobaChild, .tobaFamily,
        .tobaPatient, .tobaTravel, .tobaSuccess
    ]
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(types, id: \.self) { type in
                        NavigationLink(destination: DhikrDetailView(dhikrType: type)) {
                            ZStack(alignment: .bottomLeading) {
                                Image(type.icon)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 120)
                                    .clipped()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 2)
                                    )
                                Rectangle()
                                    .fill(Color.black.opacity(0.4))
                                    .frame(height: 30)
                                Text(type.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.leading, 6)
                                    .padding(.bottom, 6)
                            }
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("دعاء توبة")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                        Text("Common.Back")
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
      let screenWidth = UIScreen.main.bounds.width
      
      // إذا بدأ السحب من آخر 20 نقطة على اليمين، وانزاح لليسار بما يكفي
      if value.startLocation.x > screenWidth - 20 && value.translation.width < -100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}

struct GhofranView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GhofranView()
            TobaView()
        }
    }
}




// تدرّج الألوان المشترك


struct AdkarslView: View {

@AppStorage("selectedLanguage")
private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText = ""
    
    private let types: [DhikrType] = [
    .adkarsl1, .adkarsl2, .adkarsl3, .adkarsl4,
    .adkarsl5, .adkarsl6, .adkarsl7, .adkarsl8,
    .adkarsl9, .adkarsl10, .adkarsl11, .adkarsl12,
    .adkarsl13, .adkarsl14, .adkarsl15, .adkarsl16,
    .adkarsl17, .adkarsl18, .adkarsl19, .adkarsl20,
    .adkarsl21, .adkarsl22, .adkarsl23, .adkarsl24,
    .adkarsl25, .adkarsl26, .adkarsl27, .adkarsl28,
    .adkarsl29, .adkarsl30, .adkarsl31, .adkarsl32,
    .adkarsl33, .adkarsl34, .adkarsl35, .adkarsl36,
    .adkarsl37, .adkarsl38, .adkarsl39, .adkarsl40,
    .adkarsl41, .adkarsl42, .adkarsl43, .adkarsl44,
    .adkarsl45, .adkarsl46, .adkarsl47, .adkarsl48,
    .adkarsl49, .adkarsl50, .adkarsl51, .adkarsl52,
    .adkarsl53, .adkarsl54, .adkarsl55, .adkarsl56,
    .adkarsl57, .adkarsl58, .adkarsl59, .adkarsl60,
    .adkarsl61, .adkarsl62, .adkarsl63, .adkarsl64,
    .adkarsl65, .adkarsl66, .adkarsl67, .adkarsl68,
    .adkarsl69, .adkarsl70, .adkarsl711, .adkarsl71,
    .adkarsl72, .adkarsl73, .adkarsl74, .adkarsl75,
    .adkarsl76, .adkarsl77, .adkarsl78, .adkarsl79,
    .adkarsl80, .adkarsl81, .adkarsl82, .adkarsl83, .adkarsl84
]
    private let columns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]

    private var filteredTypes: [DhikrType] {
        searchText.isEmpty
            ? types
            : types.filter { $0.rawValue.contains(searchText) }
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredTypes, id: \.self) { type in
                        NavigationLink(destination: DhikrDetailView(dhikrType: type)) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 60)
                                Text(type.rawValue)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("جميع الأدعية")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(
        placement: selectedLanguage == "ar"
            ? .navigationBarTrailing
            : .navigationBarLeading
    ) {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(
                systemName: selectedLanguage == "ar"
                    ? "chevron.right"
                    : "chevron.left"
            )
            .imageScale(.large)
            .foregroundColor(.blue)
        }
    }
}

        
        // شريط البحث بمفتاح ترجمـي
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: LocalizedStringKey("adkarsl.search.prompt")
        )
        
        // سحب الحافة اليمنى للإنجليزي أو اليسرى للعربي
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let w = UIScreen.main.bounds.width
                    if selectedLanguage == "ar" {
                        // عربي: سحب من اليسار إلى اليمين
                        if value.startLocation.x < 20 && value.translation.width > 100 {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        // إنجليزي: سحب من اليمين إلى اليسار
                        if value.startLocation.x > w - 20 && value.translation.width < -100 {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        )
    }
}


struct AddDhikrView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true
    let color: Color
    @Binding var newDhikrText: String
    @Binding var newDhikrRepetition: String
    @Binding var newDhikrNote: String
    @Binding var showAddDhikr: Bool
    let saveAction: () -> Void

    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case text, note, repetition }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // عنوان النافذة
                Text("AddDhikr.Title")
                    .font(.title2.bold())
                    .padding(.top)

                // ——— نص الذكر ———
                VStack(alignment: .leading, spacing: 8) {
                    Text("AddDhikr.Label.Text")
                        .font(.subheadline).bold()
                    ZStack(alignment: .topLeading) {
                        if newDhikrText.isEmpty {
                            Text("AddDhikr.Placeholder.Text")
                                .foregroundColor(.gray)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                        }
                        TextEditor(text: $newDhikrText)
                            .foregroundColor(.green)
                            .padding(4)
                            .focused($focusedField, equals: .text)
                            .frame(minHeight: 100)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .text ? color : Color.gray, lineWidth: 2)
                    )
                }
                .padding(.horizontal)

                // ——— نص أسفل الذكر ———
                VStack(alignment: .leading, spacing: 8) {
                    Text("AddDhikr.Label.Note")
                        .font(.subheadline).bold()
                    ZStack(alignment: .topLeading) {
                        if newDhikrNote.isEmpty {
                            Text("AddDhikr.Placeholder.Note")
                                .foregroundColor(.gray)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                        }
                        TextEditor(text: $newDhikrNote)
                            .foregroundColor(.green)
                            .padding(4)
                            .focused($focusedField, equals: .note)
                            .frame(minHeight: 80)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .note ? color : Color.gray, lineWidth: 2)
                    )
                }
                .padding(.horizontal)

                // ——— عدد النقر ———
                VStack(alignment: .leading, spacing: 8) {
                    Text("AddDhikr.Label.Repetition")
                        .font(.subheadline).bold()
                    TextField("AddDhikr.Placeholder.Repetition", text: $newDhikrRepetition)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .repetition ? color : Color.gray, lineWidth: 2)
                        )
                        .focused($focusedField, equals: .repetition)
                }
                .padding(.horizontal)

                // ——— الأزرار ———
                HStack(spacing: 16) {
                    Button("Common.Cancel") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showAddDhikr = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Common.Save") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        saveAction()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(color)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.bottom)
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        .onAppear {
            // إظهار لوحة المفاتيح تلقائياً عند فتح النافذة
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .text
            }
        }
    }
}


                        // MARK: - RepetitionCounter

                        // MARK: - RepetitionCounter




                        // هنا نضيف CompletionView

                        struct CompletionView: View {
                            let color: Color
                            let action: () -> Void

                            var body: some View {
                                VStack(spacing: 30) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(color)

                                    Text("Completion.Title")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Completion.Message")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)

                                    Button(action: action) {
                                        Text("Completion.Button")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(width: 200)
                                            .background(color)
                                            .cornerRadius(15)
                                            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }









struct CustomSectionDetailView: View {
    let sectionName: String

@AppStorage("selectedLanguage")
private var selectedLanguage: String =
    Locale.current.language.languageCode?.identifier ?? "en"



    @State private var customList: [Dhikr] = []
    @State private var idx: Int = 0
    @State private var rep: Int = 0
    @State private var isFinished: Bool = false

@Environment(\.presentationMode) private var presentationMode


    // إضافة/تحرير/مشاركة/حذف
    @State private var showAdd: Bool = false
    @State private var showEdit: Bool = false
    @State private var isSharePresented: Bool = false
    @State private var showDeleteConfirm: Bool = false

    // بيانات الذِّكر الجديد أو المحرَّر
    @State private var newText: String = ""
    @State private var newRep: String  = ""
    @State private var newNote: String = ""

    // تحكم في حجم الخط
    @State private var detailFontSize: Double = 18.0

    // Haptic generators
    private let tapHaptic = UIImpactFeedbackGenerator(style: .light)
    private let nextHaptic = UIImpactFeedbackGenerator(style: .rigid)

    // لحفظ عرض البطاقة
    @State private var cardWidth: CGFloat = 0

    // مسار ملف JSON الخاص بالقسم
    private var fileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("customDhikrs_\(sectionName).json")
    }

    private func loadDhikrs() {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            customList = try JSONDecoder().decode([Dhikr].self, from: data)
        } catch {
            print("⚠️ فشل تحميل الأذكار:", error)
        }
    }

    private func saveDhikrs() {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(customList)
            try data.write(to: url, options: [.atomicWrite])
        } catch {
            print("❌ فشل حفظ الأذكار:", error)
        }
    }

// أضف هذه الدالة في ملف مساعد أو في نفس الملف
// במעלה הקובץ, אחרי ה-imports:
func arabicNumber(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "ar")
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

    private var allList: [Dhikr] { customList }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                if allList.isEmpty {
                    VStack {
                        Spacer()
                        Text("EmptyDhikr.Message")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                        Spacer()
                    }
                } else if isFinished {
                    CompletionView(color: .green) {
                        idx = 0; rep = 0; isFinished = false
                    }
                } else {
                    VStack {
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { cardWidth = geo.size.width }

                            TabView(selection: $idx) {
                                ForEach(allList.indices, id: \.self) { i in
                                    ZStack(alignment: .topLeading) {
                                        // البطاقة الخلفية
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: cardWidth - 28, height: 533)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 20)

                                        VStack(spacing: 15) {
                                            ScrollView(.vertical, showsIndicators: false) {
                                                VStack(spacing: 15) {
                                                    Spacer().frame(height: 40)
                                                    let raw = allList[i].text.trimmingCharacters(in: .whitespacesAndNewlines)
                                                    let cleaned = raw
                                                        .replacingOccurrences(of: "«", with: "")
                                                        .replacingOccurrences(of: "»", with: "")

                                                    (
                                                        Text("❮ ")
                                                            .font(.system(size: detailFontSize * 0.8))
                                                            .foregroundColor(.green)
                                                        + Text(cleaned)
                                                            .foregroundColor(.white.opacity(0.8))
                                                        + Text(" ❯")
                                                            .font(.system(size: detailFontSize * 0.8))
                                                            .foregroundColor(.red)
                                                    )
                                                    .font(.system(size: detailFontSize, weight: .medium))
                                                    .multilineTextAlignment(.center)
                                                    .lineSpacing(8)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 8)
                                                    .padding(.bottom, 10)

                                                    Color.clear.frame(height: 80)
                                                }
                                            }
                                            .frame(maxHeight: 500)

                                            // عدَّاد التكرار داخل دائرة
RepetitionCounter(
    current: rep + 1,
    total: allList[i].repetition,
    color: .green,
    fontSize: 23
)
.padding(.bottom, 4)



                                            // النص أسفل الدائرة أو مساحة احتياطية
                                            if let note = allList[i].note {
                                                Text(note)
                                                    .font(.system(size: detailFontSize * 0.8))
                                                    .foregroundColor(.green)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, 20)
                                                    .padding(.top, 8)
                                                    .padding(.bottom, 40)
                                            } else {
                                                Spacer().frame(height: 40)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            let target = allList[idx].repetition
                                            if rep + 1 < target {
                                                rep += 1; tapHaptic.impactOccurred()
                                            } else {
                                                rep = 0
                                                if idx < allList.count - 1 {
                                                    withAnimation { idx += 1 }
                                                    nextHaptic.impactOccurred()
                                                } else {
                                                    isFinished = true
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)

                                        // زر المشاركة
                                        Button {
                                            tapHaptic.impactOccurred()
                                            isSharePresented = true
                                        } label: {
                                            Image(systemName: "square.and.arrow.up")
                                                .imageScale(.large)
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(Color.black.opacity(0.4))
                                                .clipShape(Circle())
                                        }
                                        .padding(.leading, 24)
                                        .padding(.top, 22)

                                        // أزرار الزووم + تحرير/حذف
                                        HStack(spacing: 12) {
                                            Button {
                                                if detailFontSize > 12 {
                                                    detailFontSize -= 1; tapHaptic.impactOccurred()
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle")
                                                    .font(.system(size: 16))
                                                    .padding(6)
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.4))
                                                    .clipShape(Circle())
                                            }
                                            Button {
                                                if detailFontSize < 22 {
                                                    detailFontSize += 1; tapHaptic.impactOccurred()
                                                }
                                            } label: {
                                                Image(systemName: "plus.circle")
                                                    .font(.system(size: 16))
                                                    .padding(6)
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.4))
                                                    .clipShape(Circle())
                                            }
                                            Button {
                                                tapHaptic.impactOccurred()
                                                newText = allList[i].text
                                                newRep  = "\(allList[i].repetition)"
                                                newNote = allList[i].note ?? ""
                                                showEdit = true
                                            } label: {
                                                Image(systemName: "pencil")
                                                    .foregroundColor(.green)
                                                    .padding(6)
                                                    .background(Color.black.opacity(0.4))
                                                    .clipShape(Circle())
                                            }
                                            Button {
                                                tapHaptic.impactOccurred()
                                                showDeleteConfirm = true
                                            } label: {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.red)
                                                    .padding(6)
                                                    .background(Color.black.opacity(0.4))
                                                    .clipShape(Circle())
                                            }
                                        }
                                        .padding(.trailing, 30)
                                        .padding(.top, 24)
                                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    }
                                    .tag(i)
                                    .frame(height: 533)
                                    .scaleEffect(x: -1, y: 1)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .environment(\.layoutDirection, .leftToRight)
                            .scaleEffect(x: -1, y: 1)
                            .animation(.easeInOut, value: idx)
                            .sheet(isPresented: $isSharePresented) {
                                ActivityView(activityItems: [ allList[idx].text ])
                            }
                        }
                        .frame(height: 533)

                        // شريط اختيار الصفحات
ScrollViewReader { proxy in
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
            // Empty spacer to keep first page on right
            Spacer()
            
            ForEach(0..<allList.count, id: \.self) { i in
                Button {
                    idx = i
                    rep = 0
                    tapHaptic.impactOccurred()
                } label: {
                    Text(arabicNumber(i+1)) // استدعاء الدالة الجديدة
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(idx == i ? .white : .green)
                        .frame(width: 30, height: 35)
                        .background(idx == i ? Color.green : Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                }
                .id(i)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .environment(\.layoutDirection, .rightToLeft)
    }
    .onAppear {
        proxy.scrollTo(0, anchor: .trailing)
    }
    .onChange(of: idx) { newIdx in
        withAnimation {
            if newIdx == 0 {
                proxy.scrollTo(0, anchor: .trailing)
            } else {
                proxy.scrollTo(newIdx, anchor: .center)
            }
        }
    }
}
.frame(height: 55)

// دالة مساعدة لتحويل الأرقام إلى عربية




                        // زر "التالي"
                        Button {
                            next()
                        } label: {
                            Image(systemName: "hand.point.up.braille.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                                .padding(18)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .buttonStyle(HapticButtonStyle(hapticEnabled: true) {})
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(sectionName)
            .navigationBarTitleDisplayMode(.inline)
.navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(
        placement: selectedLanguage == "ar"
            ? .navigationBarTrailing
            : .navigationBarLeading
    ) {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(
                systemName: selectedLanguage == "ar"
                    ? "chevron.forward"    // في عربي: سهم متجه يمين
                    : "chevron.backward"   // في إنجليزي: سهم متجه يسار
            )
            .imageScale(.large)
            .foregroundColor(.blue)
        }
    }


ToolbarItem(
    placement: selectedLanguage == "ar"
        ? .navigationBarLeading   // إذا عربي: عاليسار
        : .navigationBarTrailing  // إذا إنجليزي: عاليمين
) {
    Button {
        newText = ""; newRep = ""; newNote = ""; showAdd = true
    } label: {
        Image(systemName: "plus")
            .foregroundColor(.green)
    }
}

            }
            .sheet(isPresented: $showAdd) {
                AddDhikrView(
                    color: .green,
                    newDhikrText: $newText,
                    newDhikrRepetition: $newRep,
                    newDhikrNote: $newNote,
                    showAddDhikr: $showAdd
                ) {
                    if let n = Int(newRep), !newText.isEmpty {
                        customList.append(
                            Dhikr(text: newText, repetition: min(n,500), note: newNote.isEmpty ? nil : newNote)
                        )
                        saveDhikrs()
                        clampIndex()
                        showAdd = false        // ← إخفاء الشاشة بعد الحفظ
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                AddDhikrView(
                    color: .green,
                    newDhikrText: $newText,
                    newDhikrRepetition: $newRep,
                    newDhikrNote: $newNote,
                    showAddDhikr: $showEdit
                ) {
                    if let n = Int(newRep), !newText.isEmpty {
                        customList[idx].text = newText
                        customList[idx].repetition = min(n,500)
                        customList[idx].note = newNote.isEmpty ? nil : newNote
                        saveDhikrs()
                        showEdit = false       // ← إخفاء الشاشة بعد التعديل
                    }
                }
            }
            .alert(
    // عنوان التنبيه كمفتاح ترجمة
    "DeleteConfirmation.Title",
    isPresented: $showDeleteConfirm
) {
    // زري الحذف والإلغاء كمفاتيح ترجمة
    Button("DeleteConfirmation.Button.Delete", role: .destructive) {
        customList.remove(at: idx)
        saveDhikrs()
        clampIndex()
    }
    Button("DeleteConfirmation.Button.Cancel", role: .cancel) { }
} message: {
    // نص الرسالة كمفتاح ترجمة
    Text("DeleteConfirmation.Message")
}
.onAppear { loadDhikrs(); clampIndex() }
.onChange(of: allList.count) { _ in clampIndex() }
.onChange(of: idx) { _ in rep = 0 }
        }
    }

//هنا ترجمه

    // MARK: – Helpers

    private func next() {
        if rep + 1 < allList[idx].repetition {
            rep += 1; nextHaptic.impactOccurred()
            return
        }
        rep = 0
        if idx < allList.count - 1 {
            withAnimation { idx += 1 }; nextHaptic.impactOccurred()
        } else {
            isFinished = true
        }
    }

    private func clampIndex() {
        if allList.isEmpty {
            idx = 0; rep = 0
        } else {
            idx = min(idx, allList.count - 1)
            rep = min(rep, allList[idx].repetition - 1)
        }
    }
}











// القائمة الرئيسية للأقسام
struct AlzakeerMenuView: View {
    @State private var categories: [DhikrType] = [
        .morning, .evening, .sleep, .awakening, .msb,
        .adkarsl, .gpsbosla, .hasbzkat
    ]
    @State private var customSections: [String] = []

    @State private var showAddSection = false
    @State private var newSectionName = ""
    @State private var deleteSectionIndex: Int? = nil
    @State private var showDeleteAlert = false

@AppStorage("selectedLanguage")
private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"


    @Environment(\.presentationMode) private var presentationMode



    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 16),
        count: 4
    )
    private let badgeColors: [Color] = [.blue, .green, .orange, .purple, .pink]

    private var sectionsFileURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("customSections.json")
    }

    private func loadCustomSections() {
        guard let url = sectionsFileURL else { return }
        guard FileManager.default.fileExists(atPath: url.path) else {
            customSections = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            customSections = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("❌ فشل تحميل الأقسام:", error)
            customSections = []
        }
    }

    private func saveCustomSections() {
        guard let url = sectionsFileURL else { return }
        do {
            let data = try JSONEncoder().encode(customSections)
            try data.write(to: url, options: [.atomicWrite])
        } catch {
            print("❌ فشل حفظ الأقسام:", error)
        }
    }

    @ViewBuilder
    private func destinationView(for type: DhikrType) -> some View {
        switch type {

        case .hasbzkat:
            ZakatCalculatorView()
        case .gpsbosla:
            GpsBoslaView()
        case .morning, .evening, .msb, .sleep, .awakening:
            DhikrDetailView(dhikrType: type)
        case .adkarsl:
            AdkarslView()
        default:
            Text("واجهة \(type.rawValue)").font(.largeTitle)
        }
    }

    private func allIcon(for type: DhikrType) -> String {
        switch type {


        case .hasbzkat: return "hasbzkat"
        case .gpsbosla: return "gpsbosla"
        case .morning:   return "morningIcon"
        case .evening:   return "eveningIcon"
        case .msb:       return "msbhaIcon"
        case .adkarsl:   return "ghofranIcon"
        case .sleep:     return "sleepIcon"
        case .awakening: return "awakeningIcon"
        default:         return type.icon
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    // الشبكة الرئيسية للأقسام الثابتة
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(categories, id: \.self) { type in
                            NavigationLink(destination: destinationView(for: type)) {
                                VStack(spacing: 4) {
                                    Image(allIcon(for: type))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                        )
                                    Text(type.rawValue)
                                        .font(.caption).fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .lineLimit(1).minimumScaleFactor(0.5)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding()

                    // الأقسام المخصصة
                    if !customSections.isEmpty {
                        VStack(spacing: 12) {
Text("Menu.Sections.Title")
    .font(.headline)
    .foregroundColor(.white)
    .frame(maxWidth: .infinity, alignment: .center)  // يحاذي النص للمنتصف

//ترجم
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(Array(customSections.enumerated()), id: \.offset) { idx, name in
                                    let bg = badgeColors[idx % badgeColors.count]
                                    NavigationLink(destination: CustomSectionDetailView(sectionName: name)) {
                                        VStack(spacing: 4) {

Circle()
    .fill(bg)
    .frame(width: 50, height: 50)
    .overlay(
        Text((idx + 1).arabicDigits)     // ← هنا الرقم بالعربي
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
    )
                                                
                                            Text(name)
                                                .font(.caption).fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .lineLimit(1).minimumScaleFactor(0.5)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
             .toolbar {
                    // زر "رجوع"
                    ToolbarItem(
                        placement: selectedLanguage == "ar"
                            ? .navigationBarTrailing    // في عربي: على اليمين
                            : .navigationBarLeading     // في إنجليزي: على اليسار
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

                    // العنوان في الوسط
                    ToolbarItem(placement: .principal) {
                        Text("جميع الأقسام")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    // زر "+"
                    ToolbarItem(
                        placement: selectedLanguage == "ar"
                            ? .navigationBarLeading     // في عربي: على اليسار
                            : .navigationBarTrailing    // في إنجليزي: على اليمين
                    ) {
                        Button {
                            newSectionName = ""
                            deleteSectionIndex = nil
                            showAddSection = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundColor(.white)
                        }
                    }
                }
            .sheet(isPresented: $showAddSection) {
                AddSectionSheet(
                    customSections: $customSections,
                    badgeColors: badgeColors,
                    saveAction: saveCustomSections
                )
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let screenWidth = UIScreen.main.bounds.width
                        if value.startLocation.x > screenWidth - 20 && value.translation.width < -100 {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
            )
            .onAppear {
                loadCustomSections()
            }
        }
    }
}

// افصل شاشة إضافة/تعديل الأقسام في View مستقل لتقليل التعقيد
struct AddSectionSheet: View {
    @AppStorage("selectedLanguage")
    private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    
    @Binding var customSections: [String]
    let badgeColors: [Color]
    let saveAction: () -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var newSectionName = ""
    @State private var deleteSectionIndex: Int? = nil
    @State private var showDeleteAlert = false

    private var isArabic: Bool { selectedLanguage == "ar" }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                Form {
                    // إضافة قسم جديد / Add New Section
                    Section(header: Text(isArabic ? "إضافة قسم جديد" : "Add New Section")
                                .font(.headline)
                                .foregroundColor(.white)) {
                        TextField(
                            isArabic ? "أدخل اسم القسم…" : "Enter section name…",
                            text: $newSectionName
                        )
                        .autocapitalization(.words)
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    // الأقسام الحالية / Current Sections
                    Section(header: Text(isArabic ? "الأقسام الحالية" : "Current Sections")
                                .font(.headline)
                                .foregroundColor(.white)) {
                        ForEach(Array(customSections.enumerated()), id: \.offset) { idx, section in
                            let bg = badgeColors[idx % badgeColors.count]
                            HStack(spacing: 12) {
                                Text((idx + 1).arabicDigits)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(bg)
                                    .clipShape(Circle())
                                Text(section)
                                    .foregroundColor(.white)
                                Spacer()
                                // تحرير / Edit
                                Button {
                                    newSectionName = section
                                    deleteSectionIndex = idx
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(PlainButtonStyle())
                                // حذف / Delete
                                Button {
                                    deleteSectionIndex = idx
                                    showDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(bg.opacity(0.2))
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(isArabic ? "تحرير وإضافة" : "Edit & Add")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                // إلغاء / Cancel
                leading: Button(isArabic ? "إلغاء" : "Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red),
                // إضافة / Add   or   حفظ / Save
                trailing: Button(deleteSectionIndex == nil
                                 ? (isArabic ? "إضافة" : "Add")
                                 : (isArabic ? "حفظ" : "Save")) {
                    guard !newSectionName.isEmpty else { return }
                    if let idx = deleteSectionIndex {
                        customSections[idx] = newSectionName
                    } else {
                        customSections.append(newSectionName)
                    }
                    saveAction()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(newSectionName.isEmpty)
            )
            .alert(
                isArabic ? "تأكيد الحذف" : "Delete Confirmation",
                isPresented: $showDeleteAlert,
                presenting: deleteSectionIndex
            ) { idx in
                Button(isArabic ? "حذف" : "Delete", role: .destructive) {
                    customSections.remove(at: idx)
                    saveAction()
                }
                Button(isArabic ? "إلغاء" : "Cancel", role: .cancel) {
                    deleteSectionIndex = nil
                }
            } message: { idx in
                Text(isArabic
                     ? "هل تريد حذف القسم \"\(customSections[idx])\"؟"
                     : "Are you sure you want to delete the section “\(customSections[idx])”?")
            }
        }
    }
}

struct AlzakeerMenuView_Previews: PreviewProvider {
    static var previews: some View {
        AlzakeerMenuView()
    }
}


// افصل شاشة إضافة/تعديل الأقسام في View مستقل لتقليل التعقيد





struct DhikrDetailView: View {
    let dhikrType: DhikrType

    // AppStorage
    @AppStorage("soundEnabled")    private var soundEnabled    = false
    @AppStorage("hapticEnabled")   private var hapticEnabled   = true
    @AppStorage("detailFontSize")  private var detailFontSize  = 19.0

@AppStorage("selectedLanguage")
private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"


@Environment(\.locale) private var locale
private var isArabic: Bool {
    locale.language.languageCode?.identifier == "ar"
}


    @Environment(\.presentationMode) private var presentationMode

    // 1. عرف متغيّر baseList كـ @State ليحمّل مرة واحدة
    @State private var baseList: [Dhikr]
    @State private var customList: [Dhikr] = []
    @State private var idx: Int = 0
    @State private var rep: Int = 0
    @State private var isFinished: Bool = false
    @State private var showAdd: Bool = false
    @State private var showEdit: Bool = false
    @State private var isSharePresented: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isDownloadPresented: Bool = false

    @State private var slideOffset: CGFloat = 0
    @State private var cardWidth: CGFloat   = 0

    @State private var zoomCount: Int = 0
    private let maxZoomCount: Int = 6

    @State private var newText: String = ""
    @State private var newRep: String  = ""
    @State private var newNote: String = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var flip: Double      = 0
    @State private var flipping: Bool    = false
    @State private var flipDirection: Double = 1
    @State private var prevIdx: Int      = 0
@State private var dragOffset: CGFloat = 0

    private let uiFont: CGFloat = 18


private let tapHaptic = UIImpactFeedbackGenerator(style: .light)
private let nextHaptic = UIImpactFeedbackGenerator(style: .rigid)

struct HapticButtonStyle: ButtonStyle {
    let hapticEnabled: Bool
    let action: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .onChange(of: configuration.isPressed) { isPressed in
                if !isPressed {
                    if hapticEnabled {
                        let generator = UIImpactFeedbackGenerator(style: .rigid)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                    action()
                }
            }
    }
}

    private func playNextSound() {
            // تأكد من أن الملف موجود في الـ Bundle
            if let url = Bundle.main.url(forResource: "click", withExtension: "mp3") {
                do {
                    // قم بتهيئة المشغل
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    audioPlayer?.play()
                } catch {
                    print("خطأ في تشغيل الصوت: \(error.localizedDescription)")
                }
            } else {
                print("لم أجد ملف الصوت counter.mp3 في الـ Bundle")
            }
        }

    // 2. هيّئه في init ليحمّل قائمة الذكر المناسبة مرة واحدة
    init(dhikrType: DhikrType) {
        self.dhikrType = dhikrType
        _baseList = State(initialValue: Self.loadBaseList(for: dhikrType))
    }

    // allList تجمع القائمتين



    // 3. دالة ثابتة لبناء القائمة الأساسية حسب النوع


    
    

    private static func loadBaseList(for type: DhikrType) -> [Dhikr] {
        switch type {

        case .morning:
            return [Dhikr(text: """
الْحَمْدُ لِلَّهِ وَحْدَهُ، وَالصَّلاَةُ وَالسَّلاَمُ عَلَى مَنْ لاَ نَبِيَّ بَعْدَهُ
""",
                          repetition: 1,
                          note: """
عن أنس يرفعه: «لأن أقعد مع قوم يذكرون اللَّه تعالى من صلاة الغداة حتى تطلع الشمس أحبُّ إليَّ من أن أُعتق أربعة من ولد إسماعيل، ولأن أقعد مع قوم يذكرون اللَّه من صلاة العصر إلى أن تغرب الشمس أحبّ إليَّ من أن أعتق أربعة». أبو داود، برقم ٣٦٦٧، وحسنه الألباني، في صحيح أبي داود، ٢/ ٦٩٨.
"""),
                    
                    Dhikr(text: """
﴿اللَّهُ لاَ إِلَٰهَ إِلاَّ هُـوَ الْـحَيُّ الْـقَيُّومُ لاَ تَأخذُهُ سنَةٌ ولا نومٌ لهُ ما في السَّمَاوَاتِ وما في الأَرضِ من ذا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بإِذنهِ يعْلَمُ ما بينَ أيدِيهِمْ وما خلفَهُمْ ولا يُحيطُونَ بِشيءٍ مِّن عِلْمِهِ إِلاَّ بِمَا شَاء وَسعَ كُرْسيُّهُ السَّمَاوَاتِ وَالأَرْضَ وَلاَ يَؤودُهُ حِفظُهُمَا وهوَ العَليُّ العَظيمُ﴾
""",
                          repetition: 1,
                          note: """
سورة البقرة، الآية: ٢٥٥. من قالها حين يصبح أُجير من الجن حتى يمسي، ومن قالها حين يمسي أُجير منهم حتى يصبح. أخرجه الحاكم، ١/ ٥٦٢، وصححه الألباني في صحيح الترغيب والترهيب، ١/ ٢٧٣، وعزاه إلى النسائي، والطبراني، وقال: «إسناد الطبراني جيد».
"""),

                    
                    
                    Dhikr(text: """
بِسْمِ اللهِ الرَّحمَنِ الرّحِيم {قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ • لَمْ يَلِدْ وَلَمْ يُولَدْ • وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ}

بِسْمِ اللهِ الرَّحمَنِ الرّحِيم {قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ • مِن شَرِّ مَا خَلَقَ • وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ • وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ • وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ}

بِسْمِ اللهِ الرَّحمَنِ الرّحِيم {قُلْ أَعُوذُ بِرَبِّ النَّاسِ • مَلِكِ النَّاسِ • إِلَهِ النَّاسِ • مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ • الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ • مِنَ الْجِنَّةِ وَ النَّاسِ}
""",
                          repetition: 3,
                          note: """
من قالها ثلاث مرات حين يصبح وحين يمسي كفته من كل شيء. أخرجه أبو داود، ٤/ ٣٢٢، برقم ٥٠٨٢، والترمذي، ٥/ ٥٦٧، برقم ٣٥٧٥، وانظر: صحيح الترمذي، ٣/ ١٨٢.
"""),
                    
                    Dhikr(text: """
«أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ»
""",
                          repetition: 1,
                          note: """
مسلم، ٤/ ٢٠٨٨، برقم ٢٧٢٣.
"""),
                    
                    
                    
                    Dhikr(text: """
«اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ»
""",
                          repetition: 1,
                          note: """
الترمذي، ٥/ ٤٦٦، برقم ٣٣٩١، وانظر: صحيح الترمذي ٣/ ١٤٢.
"""),
                    
                    Dhikr(text: """
«اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ»
""",
                          repetition: 1,
                          note: """
من قالها موقنًا بها حين يمسي، فمات من ليلته دخل الجنة، وكذلك إذا أصبح. أخرجه البخاري، ٧ ١٥٠، برقم ٦٣٠٦.
"""),
                    
                    
                    
                    
                    
                    Dhikr(text: """
«اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتِكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ»
""",
                          repetition: 4,
                          note: """
من قالها حين يصبح، أو يمسي أربع مرات، أعتقه اللَّه من النار. أخرجه أبو داود، ٤/ ٣١٧، برقم ٥٠٧١، والبخاري في الأدب المفرد، برقم ١٢٠١، والنسائي في عمل اليوم والليلة، برقم ٩، وابن السني، برقم ٧٠، وحسّن سماحة الشيخ ابن باز إسناد النسائي، وأبي داود، في تحفة الأخيار، ص٢٣.
"""),
                    
                    Dhikr(text: """
«اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ»
""",
                          repetition: 1,
                          note: """
من قالها حين يصبح فقد أدَّى شكر يومه، ومن قالها حين يمسي فقد أدَّى شكر ليلته. أخرجه أبو داود، ٤/ ٣١٨، برقم ٥٠٧٥، والنسائي في عمل اليوم والليلة، برقم ٧، وابن السني، برقم ٤١، وابن حبان، «موارد» برقم ٢٣٦١، وحسّن ابن باز إسناده في تحفة الأخيار، ص٢٤.
"""),
                    
                    
                    
                    
                    
                    Dhikr(text: """
«اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ القَبْرِ، لاَ إِلَهَ إِلاَّ أَنْتَ»
""",
                          repetition: 3,
                          note: """
أبو داود، ٤/ ٣٢٤، برقم ٥٠٩٢، وأحمد، ٥/ ٤٢، برقم ٢٠٤٣٠، والنسائي في عمل اليوم والليلة، برقم ٢٢، وابن السني، برقم ٦٩، والبخاري في الأدب المفرد، برقم ٧٠١، وحسّن العلامة ابن باز إسناده في تحفة الأخيار، ص٢٦.
"""),
                    
                    Dhikr(text: """
«حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيهِ تَوَكَّلتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ»
""",
                          repetition: 7,
                          note: """
من قالها حين يصبح وحين يمسي سبع مرات كفاه اللَّه ما أهمّه من أمر الدنيا والآخرة. أخرجه ابن السني، برقم ٧١ مرفوعًا، وأبو داود موقوفًا، ٤/ ٣٢١، برقم ٥٠٨١، وصحّح إسناده شعيب وعبدالقادر الأرناؤوط. انظر: زاد المعاد ٢/ ٣٧٦.
"""),
                    
                    
                    
                    
                    
                    Dhikr(text: """
«اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ: فِي دِينِي وَدُنْيَايَ وَأَهْلِي، وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَينِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي»
""",
                          repetition: 1,
                          note: """
أبو داود، برقم ٥٠٧٤، وابن ماجه، برقم ٣٨٧١، وانظر: صحيح ابن ماجه، ٢/ ٣٣٢.
"""),
                    
                    Dhikr(text: """
«اللَّهُمَّ عَالِمَ الغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لاَ إِلَهَ إِلاَّ أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطانِ وَشَرَكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ»
""",
                          repetition: 1,
                          note: """
الترمذي، برقم ٣٣٩٢، وأبو داود، برقم ٥٠٦٧،. وانظر: صحيح الترمذي، ٣/ ١٤٢.
"""),
                    
                    
                    Dhikr(text: """
«بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلاَ فِي السّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ»
""",
                          repetition: 3,
                          note: """
من قالها ثلاثًا إذا أصبح، وثلاثًا إذا أمسى لم يضره شيء. أخرجه أبو داود، ٤/ ٣٢٣، برقم، ٥٠٨٨، والترمذي، ٥/ ٤٦٥، برقم ٣٣٨٨، وابن ماجه، برقم ٣٨٦٩، وأحمد، برقم ٤٤٦. وانظر: صحيح ابن ماجه، ٢/ ٣٣٢، وحسّن إسناده العلامة ابن باز في تحفة الأخيار، ص٣٩.
"""),
                    
                    Dhikr(text: """
«رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلاَمِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللهُ عليهِ وسَلم نَبِيًّا»
""",
                          repetition: 3,
                          note: """
من قالها ثلاثًا حين يصبح وثلاثًا حين يمسي كان حقًا على اللَّه أن يرضيه يوم القيامة. أحمد، ٤/ ٣٣٧، برقم ١٨٩٦٧، والنسائي في عمل اليوم والليلة، برقم ٤، وابن السني، برقم ٦٨، وأبو داود، ٤/ ٣١٨، برقم ١٥٣١، والترمذي، ٥/ ٤٦٥، برقم، ٣٣٨٩، وحسّنه ابن باز في تحفة الأخيار ص٣٩.
"""),
                    
                    
                    
                    
                    Dhikr(text: """
«يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغيثُ أَصْلِحْ لِي شَأْنِيَ كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ»
""",
                          repetition: 1,
                          note: """
الحاكم وصححه، ووافقه الذهبي، ١/ ٥٤٥، وانظر: صحيح الترغيب والترهيب، ١/ ٢٧٣.
"""),
                    
                    Dhikr(text: """
«أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ»
""",
                          repetition: 1,
                          note: """
أبو داود، ٤/ ٣٢٢، برقم ٥٠٨٤، وحسن إسناده شعيب وعبد القادر الأرناؤوط في تحقيق زاد المعاد، ٢/ ٣٧٣.
"""),
                    
                    
                    Dhikr(text: """
«أَصْبَحْنا عَلَى فِطْرَةِ الْإِسْلاَمِ، وَعَلَى كَلِمَةِ الْإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللهُ عليهِ وسَلم، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشرِكِينَ»
""",
                          repetition: 1,
                          note: """
أحمد، ٣/ ٤٠٦، و٤٠٧، برقم ١٥٣٦٠، ورقم ١٥٥٦٣، وابن السني في عمل اليوم والليلة، برقم ٣٤، وانظر: صحيح الجامع، ٤/ ٢٠٩.
"""),
                    
                    Dhikr(text: """
«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ»
""",
                          repetition: 100,
                          note: """
من قالها مائة مرة حين يصبح وحين يمسي لم يأت أحد يوم القيامة بأفضل مما جاء به إلا أحد قال مثل ما قال أو زاد عليه. مسلم، ٤/ ٢٠٧١ برقم ٢٦٩٢.
"""),
                    
                    
                    Dhikr(text: """
«أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ»
""",
                          repetition: 100,
                          note: """
البخاري مع الفتح، ١١/ ١٠١، برقم ٦٣٠٧، ومسلم، / ٢٠٧٥، برقم ٢٧٠٢.
"""),
                    
                    
                    Dhikr(text: """
«لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ»
""",
                          repetition: 100,
                          note: """
من قالها مائة مرة في يوم كانت له عدل عشر رقاب، وكُتِبَ له مائة حسنة، ومُحيت عنه مائة سيئة، وكانت له حرزًا من الشيطان يومه ذلك حتى يمسي، ولم يأت أحد بأفضل مما جاء به إلا أحد عمل أكثر من ذلك. البخاري، ٤/ ٩٥، برقم ٣٢٩٣، ومسلم، ٤/ ٢٠٧١، برقم ٢٦٩١.
"""),
                    
                    Dhikr(text: """
«لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ»
""",
                          repetition: 10,
                          note: """
النسائي في عمل اليوم والليلة، برقم ٢٤، وانظر: صحيح الترغيب والترهيب، ١/ ٢٧٢، وتحفة الأخيار لابن باز، ص٤٤، وانظر فضلها في: ص١٤٦، حديث، رقم ٢٥٥. ٢- أبو داود، برقم ٥٠٧٧، وابن ماجه، برقم ٣٧٩٨، وأحمد، برقم ٨٧١٩، وانظر: صحيح الترغيب والترهيب، ١/ ٢٧٠، وصحيح أبي داود، ٣/ ٩٥٧، وصحيح ابن ماجه، ٢/ ٣٣١، وزاد المعاد، ٢/ ٣٧٧.
"""),
                    
                    
                    Dhikr(text: """
«سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ»
""",
                          repetition: 3,
                          note: """
مسلم، ٤/ ٢٠٩٠، برقم ٢٧٢٦.
"""),
                    
                    Dhikr(text: """
«اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا»
""",
                          repetition: 1,
                          note: """
أخرجه ابن السني في عمل اليوم والليلة، برقم ٥٤، وابن ماجه، برقم ٩٢٥، وحسّن إسناده عبد القادر وشعيب الأرناؤوط في تحقيق زاد المعاد، ٢/ ٣٧٥، وتقدم برقم ٧٣.
"""),
                    
                    
                    Dhikr(text: """
«اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبَيِّنَا مُحَمَّدٍ»
""",
                          repetition: 100,
                          note: """
«من صلّى عليَّ حين يصبح عشرًا، وحين يمسي عشرًا، أدركته شفاعتي يوم القيامة» أخرجه الطبراني بإسنادين: أحدهما جيد، انظر: مجمع الزوائد، ١٠/ ١٢٠، وصحيح الترغيب والترهيب، ١/ ٢٧٣.
""")
            ]



        case .evening:
            return [Dhikr(text: """
الْحَمْدُ لِلَّهِ وَحْدَهُ، وَالصَّلاَةُ وَالسَّلاَمُ عَلَى مَنْ لاَ نَبِيَّ بَعْدَهُ
""",
                          repetition: 1,
                          note: """
‎عن أنس يرفعه: «لأن أقعد مع قوم يذكرون اللَّه تعالى من صلاة الغداة حتى تطلع الشمس أحبُّ إليَّ من أن أُعتق أربعة من ولد إسماعيل، ولأن أقعد مع قوم يذكرون اللَّه من صلاة العصر إلى أن تغرب الشمس أحبّ إليَّ من أن أعتق أربعة». أبو داود، برقم ٣٦٦٧، وحسنه الألباني، في صحيح أبي داود، ٢/ ٦٩٨.
"""),
                    
                    
                    Dhikr(text: """
﴿اللَّهُ لاَ إِلَٰهَ إِلاَّ هُـوَ الْـحَيُّ الْـقَيُّومُ لاَ تَأخذُهُ سنَةٌ ولا نومٌ لهُ ما في السَّمَاوَاتِ وما في الأَرضِ من ذا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بإِذنهِ يعْلَمُ ما بينَ أيدِيهِمْ وما خلفَهُمْ ولا يُحيطُونَ بِشيءٍ مِّن عِلْمِهِ إِلاَّ بِمَا شَاء وَسعَ كُرْسيُّهُ السَّمَاوَاتِ وَالأَرْضَ وَلاَ يَؤودُهُ حِفظُهُمَا وهوَ العَليُّ العَظيمُ﴾
""",
                          repetition: 1,
                          note: """
‎سورة البقرة، الآية: ٢٥٥. من قالها حين يصبح أُجير من الجن حتى يمسي، ومن قالها حين يمسي أُجير منهم حتى يصبح. أخرجه الحاكم، ١/ ٥٦٢، وصححه الألباني في صحيح الترغيب والترهيب، ١/ ٢٧٣، وعزاه إلى النسائي، والطبراني، وقال: «إسناد الطبراني جيد».
"""),
                    
                    Dhikr(text: """
بِسْمِ اللهِ الرَّحمَنِ الرّحِيم {قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ • لَمْ يَلِدْ وَلَمْ يُولَدْ • وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ}

بِسْمِ اللهِ الرَّحمَنِ الرّحِيم {قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ • مِن شَرِّ مَا خَلَقَ • وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ • وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ • وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ}

بِسْمِ اللهِ الرَّحمَنِ الرّحِيم {قُلْ أَعُوذُ بِرَبِّ النَّاسِ • مَلِكِ النَّاسِ • إِلَهِ النَّاسِ • مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ • الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ • مِنَ الْجِنَّةِ وَ النَّاسِ}
""",
                          repetition: 3,
                          note: """
‎من قالها ثلاث مرات حين يصبح وحين يمسي كفته من كل شيء. أخرجه أبو داود، ٤/ ٣٢٢، برقم ٥٠٨٢، والترمذي، ٥/ ٥٦٧، برقم ٣٥٧٥، وانظر: صحيح الترمذي، ٣/ ١٨٢.
"""),
                    
                    

    Dhikr(text: """
أَمْسَينَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ
""",
          repetition: 1,
          note: """
مسلم، ٤/٢٠٨٨، برقم ٢٧٢٣.
"""),

    Dhikr(text: """
اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ المَصِير
""",
          repetition: 1,
          note: """
الترمذي، ٥/٤٦٦، برقم ٣٣٩١، وانظر: صحيح الترمذي ٣/١٤٢.
"""),

    Dhikr(text: """
اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنوبَ إِلاَّ أَنْتَ
""",
          repetition: 1,
          note: """
من قالها موقنًا بها حين يمسي، فمات من ليلته دخل الجنة، وكذلك إذا أصبح. أخرجه البخاري، ٧/١٥٠، برقم ٦٣٠٦.
"""),

    Dhikr(text: """
اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ
""",
          repetition: 4,
          note: """
من قالها حين يصبح، أو يمسي أربع مرات، أعتقه اللَّه من النار. أخرجه أبو داود، ٤/٣١٧، برقم ٥٠٧١، والبخاري في الأدب المفرد، برقم ١٢٠١، والنسائي في عمل اليوم والليلة، برقم ٩، وابن السني، برقم ٧٠، وحسّن سماحة الشيخ ابن باز إسناد النسائي، وأبي داود، في تحفة الأخيار، ص٢٣.
"""),

    Dhikr(text: """
اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ
""",
          repetition: 1,
          note: """
من قالها حين يصبح فقد أَدَّى شكر يومه، ومن قالها حين يمسي فقد أَدَّى شكر ليلته. أخرجه أبو داود، ٤/٣١٨، برقم ٥٠٧٥، والنسائي في عمل اليوم والليلة، برقم ٧، وابن السني، برقم ٤١، وابن حبان، موارد برقم ٢٣٦١، وحسّن ابن باز إسناده في تحفة الأخيار، ص٢٤.
"""),

    Dhikr(text: """
اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ
""",
          repetition: 3,
          note: """
أبو داود، ٤/٣٢٤، برقم ٥٠٩٢، وأحمد، ٥/٤٢، برقم ٢٠٤٣٠، والنسائي في عمل اليوم والليلة، برقم ٢٢، وابن السني، برقم ٦٩، والبخاري في الأدب المفرد، برقم ٧٠١، وحسّن العلامة ابن باز إسناده في تحفة الأخيار، ص٢٦.
"""),

    Dhikr(text: """
حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ
""",
          repetition: 7,
          note: """
من قالها حين يصبح وحين يمسي سبع مرات كفاه اللَّه ما أهمه من أمر الدنيا والآخرة. أخرجه ابن السني، برقم ٧١ مرفوعًا، وأبو داود موقوفًا، ٤/٣٢١، برقم ٥٠٨١، وصحّح إسناده شعيب وعبدالقادر الأرناؤوط. انظر: زاد المعاد ٢/٣٧٦.
"""),

    Dhikr(text: """
اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ: فِي دِينِي وَدُنْيَايَ وَأَهْلِي، وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي
""",
          repetition: 1,
          note: """
أبو داود، برقم ٥٠٧٤، وابن ماجه، برقم ٣٨٧١، وانظر: صحيح ابن ماجه، ٢/٣٣٢.
"""),

    Dhikr(text: """
اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشَرَكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ
""",
          repetition: 1,
          note: """
الترمذي، برقم ٣٣٩٢، وأبو داود، برقم ٥٠٦٧، وانظر: صحيح الترمذي، ٣/١٤٢.
"""),

    Dhikr(text: """
بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ
""",
          repetition: 3,
          note: """
من قالها ثلاثًا إذا أصبح، وثلاثًا إذا أمسى لم يضره شيء. أخرجه أبو داود، ٤/٣٢٣، برقم ٥٠٨٨، والترمذي، ٥/٤٦٥، برقم ٣٣٨٨، وابن ماجه، برقم ٣٨٦٩، وأحمد، برقم ٤٤٦. وانظر: صحيح ابن ماجه، ٢/٣٣٢، وحسّن إسناده العلامة ابن باز في تحفة الأخيار، ص٣٩.
"""),

    Dhikr(text: """
رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلاَمِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا
""",
          repetition: 3,
          note: """
من قالها ثلاثًا حين يصبح وثلاثًا حين يمسي كان حقًا على اللَّه أن يرضيه يوم القيامة. أحمد، ٤/٣٣٧، برقم ١٨٩٦٧، والنسائي في عمل اليوم والليلة، برقم ٤، وابن السني، برقم ٦٨، وأبو داود، ٤/٣١٨، برقم ١٥٣١، والترمذي، ٥/٤٦٥، برقم ٣٣٨٩، وحسّنه ابن باز في تحفة الأخيار، ص٣٩.
"""),

    Dhikr(text: """
يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ
""",
          repetition: 1,
          note: """
الحاكم وصححه، ووافقه الذهبي، ١/٥٤٥، وانظر: صحيح الترغيب والترهيب، ١/٢٧٣.
"""),

    Dhikr(text: """
أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ: فَتْحَهَا، وَنَصْرَهَا، وَنُورَهَا، وَبَرَكَتَهَا، وَهُدَاهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهَا وَشَرِّ مَا بَعْدَهَا
""",
          repetition: 1,
          note: """
أبو داود، ٤/٣٢٢، برقم ٥٠٨٤، وحسن إسناده شعيب وعبد القادر الأرناؤوط في تحقيق زاد المعاد، ٢/٣٧٣.
"""),

    Dhikr(text: """
أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلاَمِ، وَعَلَى كَلِمَةِ الْإِخْلاَصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ
""",
          repetition: 1,
          note: """
أحمد، ٣/٤٠٦، و٤٠٧، برقم ١٥٣٦٠، ورقم ١٥٥٦٣، وابن السني في عمل اليوم والليلة، برقم ٣٤، وانظر: صحيح الجامع، ٤/٢٠٩.
"""),

    Dhikr(text: """
سُبْحَانَ اللَّهِ وَبِحَمْدِهِ
""",
          repetition: 100,
          note: """
من قالها مائة مرة حين يصبح وحين يمسي لم يأت أحد يوم القيامة بأفضل مما جاء به إلا أحد قال مثل ما قال أو زاد عليه. مسلم، ٤/٢٠٧١ برقم ٢٦٩٢.
"""),

    Dhikr(text: """
أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ
""",
          repetition: 100,
          note: """
البخاري مع الفتح، ١١/١٠١، برقم ٦٣٠٧، ومسلم، ٤/٢٠٧٥، برقم ٢٧٠٢.
"""),

    Dhikr(text: """
لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ
""",
          repetition: 10,
          note: """
النسائي في عمل اليوم والليلة، برقم ٢٤، وانظر: صحيح الترغيب والترهيب، ١/٢٧٢، وتحفة الأخيار لابن باز، ص٤٤، وانظر فضلها في: ص١٤٦، حديث رقم ٢٥٥. أبو داود، برقم ٥٠٧٧، وابن ماجه، برقم ٣٧٩٨، وأحمد، برقم ٨٧١٩، وانظر: صحيح الترغيب والترهيب، ١/٢٧٠، وصحيح أبي داود، ٣/٩٥٧، وصحيح ابن ماجه، ٢/٣٣١، وزاد المعاد، ٢/٣٧٧.
"""),

    Dhikr(text: """
أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ
""",
          repetition: 3,
          note: """
من قالها حين يمسي ثلاث مرات لم تضرّه حُمَّة تلك الليلة، أخرجه أحمد، ٢/٢٩٠، برقم ٧٨٩٨، والنسائي في عمل اليوم والليلة، برقم ٥٩٠، وابن السني، برقم ٦٨، وانظر: صحيح الترمذي، ٣/١٨٧، وصحيح ابن ماجه، ٢/٢٦٦، وتحفة الأخيار لابن باز، ص٤٥.
"""),

    Dhikr(text: """
اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ
""",
          repetition: 10,
          note: """
من صلّى عليَّ حين يصبح عشرًا، وحين يمسي عشرًا، أدركته شفاعتي يوم القيامة. أخرجه الطبراني بإسنادين: أحدهما جيد، انظر: مجمع الزوائد، ١٠/١٢٠، وصحيح الترغيب والترهيب، ١/٢٧٣.
""")
]
            
            
            //نوم
            
case .sleep:
    return [
        Dhikr(text: """
يَجْمَعُ كَفَّيْهِ ثُمَّ يَنْفُثُ فِيهِمَا فَيَقْرَأُ فِيهِمَا: بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ {قُلْ هُوَ اللَّهُ أَحَدٌ • اللَّهُ الصَّمَدُ • لَمْ يَلِدْ وَلَمْ يُولَدْ • وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ}
بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ {قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ • مِن شَرِّ مَا خَلَقَ • وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ • وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ • وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ}
بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ {قُلْ أَعُوذُ بِرَبِّ النَّاسِ • مَلِكِ النَّاسِ • إِلَهِ النَّاسِ • مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ • الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ • مِنَ الْجِنَّةِ وَالنَّاسِ}
ثُمَّ يَمْسَحُ بِهِمَا مَا اسْتَطَاعَ مِنْ جَسَدِهِ يَبْدَأُ بِهِمَا عَلَى رَأْسِهِ وَوَجْهِهِ وَمَا أَقْبَلَ مِنْ جَسَدِهِ
""",
                          repetition: 3,
                          note: """
البخاري مع الفتح، ٩/٦٢، برقم ٥٠١٧، ومسلم، برقم ٢١٩٢.
"""),

        Dhikr(text: """
{اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ لاَ تَأْخُذُهُ سِنَةٌ وَلاَ نَوْمٌ لَّهُ مَا فِي السَّمَوَاتِ وَمَا فِي الأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلاَّ بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلاَ يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلاَّ بِمَا شَاء وَسِعَ كُرْسِيُّهُ السَّمَوَاتِ وَالأَرْضَ وَلاَ يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ}
""",
                          repetition: 1,
                          note: """
سورة البقرة، الآية: ٢٥٥، من قرأها إذا أوى إلى فراشه فإنه لن يزال عليه من الله حافظ ولا يقربه شيطان حتى يصبح، البخاري مع الفتح، ٤/٤٨٧، برقم ٢٣١١.
"""),

        Dhikr(text: """
{آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لاَ نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ وَقَالُواْ سَمِعْنَا وَأَطَعْنَا غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ • لاَ يُكَلِّفُ اللَّهُ نَفْسًا إِلاَّ وُسْعَهَا لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ رَبَّنَا لاَ تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا رَبَّنَا وَلاَ تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا رَبَّنَا وَلاَ تُحَمِّلْنَا مَا لاَ طَاقَةَ لَنَا بِهِ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَآ أَنتَ مَوْلاَنَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ}
""",
                          repetition: 1,
                          note: """
من قرأهما في ليلة كفتاه، البخاري مع الفتح، ٩/٩٤، برقم ٤٠٠٨، ومسلم، ١/٥٥٤، برقم ٨٠٧، والآيتان من سورة البقرة، ٢٨٥-٢٨٦.
"""),

        Dhikr(text: """
بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا، بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ
""",
                          repetition: 1,
                          note: """
«إذا قام أحدكم من فراشه ثم رجع إليه فلينفضه بصَنِفَةِ إزاره ثلاث مرات، وليُسمِّ اللَّه؛ فإنه لا يدري ما خلفه عليه بعده، وإذا اضطجع فليقل:..» الحديث، [ومعنى بصَنِفة إزاره: طَرَفه مِمَّا يَلِي طُرَّته]. النهاية في غريب الحديث والأثر (صنف).
البخاري مع الفتح، ١١/١٢٦، برقم ٦٣٢٠، ومسلم، ٤/٢٠٨٤، برقم ٢٧١٤.
"""),

        Dhikr(text: """
اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا، لَكَ مَمَاتُهَا وَمَحْياهَا، إِنْ أَحْيَيْتَهَا فَاحْفَظْهَا، وَإِنْ أَمَتَّهَا فَاغْفِرْ لَهَا. اللَّهُمَّ إِنِّي أَسْأَلُكَ العَافِيَةَ
""",
                          repetition: 1,
                          note: """
أخرجه مسلم، ٤/٢٠٨٣، برقم ٢٧١٢، وأحمد بلفظه، ٢/٧٩، برقم ٥٥٠٢.
"""),

        Dhikr(text: """
اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ
""",
                          repetition: 3,
                          note: """
«كان صَلَّى اللهُ عليهِ وسَلَّم إذا أراد أن يرقد وضع يده اليمنى تحت خدِّه، ثم يقول:...» الحديث.
أبو داود بلفظه، ٤/٣١١، برقم ٥٠٤٥، والترمذي، برقم ٣٣٩٨، وانظر: صحيح الترمذي، ٣/١٤٣، وصحيح أبي داود، ٣/٢٤٠.
"""),

        Dhikr(text: """
بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا
""",
                          repetition: 1,
                          note: """
البخاري مع الفتح، ١١/١١٣، برقم ٦٣٢٤، ومسلم، ٤/٢٠٨٣، برقم ٢٧١١.
"""),

        Dhikr(text: """
سُبْحَانَ اللَّهِ (ثلاثًا وثلاثون) وَالْحَمْدُ لِلَّهِ (ثلاثًا وثلاثون) وَاللَّهُ أَكْبَرُ (أربعًا وثلاثون)
""",
                          repetition: 33,
                          note: """
من قال ذلك عندما يأوي إلى فراشه كان خيرًا له من خادم. البخاري مع الفتح، ٧/٧١، برقم ٣٧٠٥، ومسلم، ٤/٢٠٩١، برقم ٢٧٢٦.
"""),

        Dhikr(text: """
اللَّهُمَّ رَبَّ السَّمَوَاتِ السَّبْعِ وَرَبَّ الأَرْضِ، وَرَبَّ الْعَرْشِ الْعَظِيمِ، رَبَّنَا وَرَبَّ كُلِّ شَيْءٍ، فَالِقَ الْحَبِّ وَالنَّوَى، وَمُنْزِلَ التَّوْرَاةِ وَالْإِنْجِيلِ، وَالْفُرْقَانِ، أَعُوذُ بِكَ مِنْ شَرِّ كُلِّ شَيْءٍ أَنْتَ آخِذٌ بِنَاصِيَتِهِ. اللَّهُمَّ أَنْتَ الأَوَّلُ فَلَيْسَ قَبْلَكَ شَيْءٌ، وَأَنْتَ الآخِرُ فَلَيْسَ بَعْدَكَ شَيْءٌ، وَأَنْتَ الظَّاهِرُ فَلَيْسَ فَوْقَكَ شَيْءٌ، وَأَنْتَ الْبَاطِنُ فَلَيْسَ دُونَكَ شَيْءٌ، اقْضِ عَنَّا الدَّيْنَ وَأَغْنِنَا مِنَ الْفَقْرِ
""",
                          repetition: 1,
                          note: """
مسلم، ٤/٢٠٨٤، برقم ٢٧١٣.
"""),

        Dhikr(text: """
الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا، وَكَفَانَا، وَآوَانَا، فَكَمْ مِمَّنْ لاَ كَافِيَ لَهُ وَلاَ مُؤْوِيَ
""",
                          repetition: 1,
                          note: """
مسلم، ٤/٢٠٨٥، برقم ٢٧١٥.
"""),

        Dhikr(text: """
اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا، أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ
""",
                          repetition: 1,
                          note: """
أبو داود، ٤/٣١٧، برقم ٥٠٦٧، والترمذي، برقم ٣٦٢٩، وانظر: صحيح الترمذي ٣/١٤٢.
"""),

        Dhikr(text: """
يَقْرَأُ {الم} تَنْزِيلَ السَّجْدَةِ، وَتَبَارَكَ الَّذي بِيَدِهِ الْمُلْكُ
""",
                          repetition: 1,
                          note: """
الترمذي، برقم ٣٤٠٤، والنسائي في عمل اليوم والليلة، برقم ٧٠٧، وانظر: صحيح الجامع ٤/٢٥٥.
"""),

        Dhikr(text: """
اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ
""",
                          repetition: 1,
                          note: """
«إذا أخذت مضجعك فتوضأ وضوءك للصلاة، ثم اضطجع على شقك الأيمن، ثم قل:...» الحديث.
قال صَلَّى اللهُ عليهِ وسَلَّم لمن قال ذلك: «فإن مُتَّ مُتَّ على الفطرة». البخاري مع الفتح، ١١/١١٣، برقم ٦٣١٣، ومسلم، ٤/٢٠٨١، برقم ٢٧١٠.
""")
    ]
            
            //استيقاظ
            
            
            
            
            
            
        case .awakening:
            return [Dhikr(text: """
«الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا، وَإِلَيْهِ النُّشُورُ»
""",
                          repetition: 1,
                          note: """
البخاري مع الفتح، ١١/١١٣، برقم ٦٣١٤، ومسلم، ٤/٢٠٨٣، برقم ٢٧١١.
"""),
                    
                    Dhikr(text: """
«لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَريكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ للَّهِ، وَلاَ إِلَهَ إِلاَّ اللَّهُ، وَاللَّهُ أَكبَرُ، وَلاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، رَبِّ اغْفرْ لِي»
""",
                          repetition: 1,
                          note: """
من قال ذلك غُفِرَ له، فإن دعا استجيب له، فإن قام فتوضأ ثم صلى قُبلت صلاته، البخاري مع الفتح، ٣/ ٣٩، برقم ١١٥٤، وغيره، واللفظ لابن ماجه، انظر: صحيح ابن ماجه، ٢/ ٣٣٥.
"""),
                    
                    
                    Dhikr(text: """
«الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لي بِذِكْرِهِ»
""",
                          repetition: 1,
                          note: """
الترمذي، ٥/ ٤٧٣، برقم ٣٤٠١، وانظر: صحيح الترمذي، ٣/ ١٤٤.
"""),
                    
                    
                    Dhikr(text: """
{إِنَّ فِي خَلْقِ السَّمَوَاتِ وَالأَرْضِ وَاخْتِلاَفِ اللَّيْلِ وَالنَّهَارِ لَآيَاتٍ لأُوْلِي الألْبَابِ • الَّذِينَ يَذْكُرُونَ اللَّهَ قِيَامًا وَقُعُودًا وَعَلَىَ جُنُوبِهِمْ وَيَتَفَكَّرُونَ فِي خَلْقِ السَّمَوَاتِ وَالأَرْضِ رَبَّنَا مَا خَلَقْتَ هَذا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ • رَبَّنَا إِنَّكَ مَن تُدْخِلِ النَّارَ فَقَدْ أَخْزَيْتَهُ وَمَا لِلظَّالِمِينَ مِنْ أَنصَارٍ • رَّبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلإِيمَانِ أَنْ آمِنُواْ بِرَبِّكُمْ فَآمَنَّا رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الأبْرَارِ • رَبَّنَا وَآتِنَا مَا وَعَدتَّنَا عَلَى رُسُلِكَ وَلاَ تُخْزِنَا يَوْمَ الْقِيَامَةِ إِنَّكَ لاَ تُخْلِفُ الْمِيعَادَ • فَاسْتَجَابَ لَهُمْ رَبُّهُمْ أَنِّي لاَ أُضِيعُ عَمَلَ عَامِلٍ مِّنكُم مِّن ذَكَرٍ أَوْ أُنثَى بَعْضُكُم مِّن بَعْضٍ فَالَّذِينَ هَاجَرُواْ وَأُخْرِجُواْ مِن دِيَارِهِمْ وَأُوذُواْ فِي سَبِيلِي وَقَاتَلُواْ وَقُتِلُواْ لأُكَفِّرَنَّ عَنْهُمْ سَيِّئَاتِهِمْ وَلأُدْخِلَنَّهُمْ جَنَّاتٍ تَجْرِي مِن تَحْتِهَا الأَنْهَارُ ثَوَابًا مِّن عِندِ اللَّهِ وَاللَّهُ عِندَهُ حُسْنُ الثَّوَابِ • لاَ يَغُرَّنَّكَ تَقَلُّبُ الَّذِينَ كَفَرُواْ فِي الْبِلاَدِ • مَتَاعٌ قَلِيلٌ ثُمَّ مَأْوَاهُمْ جَهَنَّمُ وَبِئْسَ الْمِهَادُ • لَكِنِ الَّذِينَ اتَّقَوْاْ رَبَّهُمْ لَهُمْ جَنَّاتٌ تَجْرِي مِنْ تَحْتِهَا الأَنْهَارُ خَالِدِينَ فِيهَا نُزُلًا مِّنْ عِندِ اللَّهِ وَمَا عِندَ اللَّهِ خَيْرٌ لِّلأَبْرَارِ • وَإِنَّ مِنْ أَهْلِ الْكِتَابِ لَمَن يُؤْمِنُ بِاللَّهِ وَمَا أُنزِلَ إِلَيْكُمْ وَمَآ أُنزِلَ إِلَيْهِمْ خَاشِعِينَ لِلَّهِ لاَ يَشْتَرُونَ بِآيَاتِ اللَّهِ ثَمَنًا قَلِيلًا أُوْلَئِكَ لَهُمْ أَجْرُهُمْ عِندَ رَبِّهِمْ إِنَّ اللَّهَ سَرِيعُ الْحِسَابِ • يَا أَيُّهَا الَّذِينَ آمَنُواْ اصْبِرُواْ وَصَابِرُواْ وَرَابِطُواْ وَاتَّقُواْ اللَّهَ لَعَلَّكُمْ تُفْلِحُونَ}
""",
                          repetition: 1,
                          note: """
الآيات من سورة آل عمران، ١٩٠-٢٠٠، البخاري مع الفتح، ٨/ ٣٣٧، برقم ٤٥٦٩، ومسلم، ١/ ٥٣٠، برقم ٢٥٦.
""")
            ]
            
            

case .msb:
    return [
        Dhikr(text: """
        «سُبْحَانَ اللَّهِ»
        """,
              repetition: 33,
              note: ""
        ),

        Dhikr(text: """
        ٱلْحَمْدُ لِلَّهِ
        """,
              repetition: 33,
              note: ""
        ),

        Dhikr(text: """
        ٱللَّهُ أَكْبَرُ
        """,
              repetition: 33,
              note: ""
        ),

        Dhikr(text: """
        سُبْحَانَ اللَّهِ وَبِحَمْدِهِ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        أَسْتَغْفِرُ اللَّهَ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى سَيِّدِنَا مُحَمَّدٍ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ، الْحَيُّ الْقَيُّومُ، وَأَتُوبُ إِلَيْهِ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        اللَّهُ أَكْبَرُ كَبِيرًا، وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللَّهِ بُكْرَةً وَأَصِيلًا
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ
        """,
              repetition: 100,
              note: ""
        ),

        Dhikr(text: """
        اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَّجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَّجِيدٌ
        """,
              repetition: 100,
              note: ""
        )
    ]




            
        case .alzakeer:
            return [Dhikr(text: """

""",
                          repetition: 1,
                          note: """

""")
            ]
            
            

            

            
        case .ghofranQulub:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .ghofranMaal:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .ghofranMard:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .ghofranSafar:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
            
            
            
            
        case .ghofranAila:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
            
        case .tobaPerson:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .tobaChild:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .tobaFamily:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .tobaPatient:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .tobaTravel:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
        case .tobaSuccess:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]
            
            
            
        
            
            













        case .hasbzkat:
            return [Dhikr(text: """
        al hmd alah
        """,
                          repetition: 5,
                          note: """
        33 morha
        """)
            ]



        case .gpsbosla:
            return [Dhikr(text: """
        al hmd alah
        """,
                          repetition: 5,
                          note: """
        33 morha
        """)
            ]

    case .adkarsl:
        return [
            Dhikr(text: """
            al  alah
            """,
            repetition: 5,
            note: "33 morha")
        ]


        case .ghofranDonub:
            return [Dhikr(text: """
        
        """,
                          repetition: 5,
                          note: """
        
        """)
            ]

            

// داخل DhikrDetailView أو كملاحظة extension على DhikrType


    // … بقية الحالات الرئيسية









case .adkarsl1:
    return adkarsl1List
case .adkarsl2:
    return adkarsl2List
case .adkarsl3:
    return adkarsl3List
case .adkarsl4:
    return adkarsl4List
case .adkarsl5:
    return adkarsl5List
case .adkarsl6:
    return adkarsl6List
case .adkarsl7:
    return adkarsl7List
case .adkarsl8:
    return adkarsl8List
case .adkarsl9:
    return adkarsl9List
case .adkarsl10:
    return adkarsl10List
case .adkarsl11:
    return adkarsl11List
case .adkarsl12:
    return adkarsl12List
case .adkarsl13:
    return adkarsl13List
case .adkarsl14:
    return adkarsl14List
case .adkarsl15:
    return adkarsl15List
case .adkarsl16:
    return adkarsl16List
case .adkarsl17:
    return adkarsl17List
case .adkarsl18:
    return adkarsl18List
case .adkarsl19:
    return adkarsl19List
case .adkarsl20:
    return adkarsl20List
case .adkarsl21:
    return adkarsl21List
case .adkarsl22:
    return adkarsl22List
case .adkarsl23:
    return adkarsl23List
case .adkarsl24:
    return adkarsl24List
case .adkarsl25:
    return adkarsl25List
case .adkarsl26:
    return adkarsl26List
case .adkarsl27:
    return adkarsl27List
case .adkarsl28:
    return adkarsl28List
case .adkarsl29:
    return adkarsl29List
case .adkarsl30:
    return adkarsl30List
case .adkarsl31:
    return adkarsl31List
case .adkarsl32:
    return adkarsl32List
case .adkarsl33:
    return adkarsl33List
case .adkarsl34:
    return adkarsl34List
case .adkarsl35:
    return adkarsl35List
case .adkarsl36:
    return adkarsl36List
case .adkarsl37:
    return adkarsl37List
case .adkarsl38:
    return adkarsl38List
case .adkarsl39:
    return adkarsl39List
case .adkarsl40:
    return adkarsl40List
case .adkarsl41:
    return adkarsl41List
case .adkarsl42:
    return adkarsl42List
case .adkarsl43:
    return adkarsl43List
case .adkarsl44:
    return adkarsl44List
case .adkarsl45:
    return adkarsl45List
case .adkarsl46:
    return adkarsl46List
case .adkarsl47:
    return adkarsl47List
case .adkarsl48:
    return adkarsl48List
case .adkarsl49:
    return adkarsl49List
case .adkarsl50:
    return adkarsl50List
case .adkarsl51:
    return adkarsl51List
case .adkarsl52:
    return adkarsl52List
case .adkarsl53:
    return adkarsl53List
case .adkarsl54:
    return adkarsl54List
case .adkarsl55:
    return adkarsl55List
case .adkarsl56:
    return adkarsl56List
case .adkarsl57:
    return adkarsl57List
case .adkarsl58:
    return adkarsl58List
case .adkarsl59:
    return adkarsl59List
case .adkarsl60:
    return adkarsl60List
case .adkarsl61:
    return adkarsl61List
case .adkarsl62:
    return adkarsl62List
case .adkarsl63:
    return adkarsl63List
case .adkarsl64:
    return adkarsl64List
case .adkarsl65:
    return adkarsl65List
case .adkarsl66:
    return adkarsl66List
case .adkarsl67:
    return adkarsl67List
case .adkarsl68:
    return adkarsl68List
case .adkarsl69:
    return adkarsl69List
case .adkarsl70:
    return adkarsl70List
case .adkarsl711:
    return adkarsl711List
case .adkarsl71:
    return adkarsl71List
case .adkarsl72:
    return adkarsl72List
case .adkarsl73:
    return adkarsl73List
case .adkarsl74:
    return adkarsl74List
case .adkarsl75:
    return adkarsl75List
case .adkarsl76:
    return adkarsl76List
case .adkarsl77:
    return adkarsl77List
case .adkarsl78:
    return adkarsl78List
case .adkarsl79:
    return adkarsl79List
case .adkarsl80:
    return adkarsl80List
case .adkarsl81:
    return adkarsl81List
case .adkarsl82:
    return adkarsl82List
case .adkarsl83:
    return adkarsl83List
case .adkarsl84:
    return adkarsl84List

            
            

            
        }
    }
    
    
    
    
    private var allList: [Dhikr] {
        baseList + customList
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [dhikrType.color.opacity(0.5), .black]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if allList.isEmpty {
                VStack {
                    Spacer()
                    Text("لا توجد أذكار أو أدعية بعد\nاضغط + لإضافة ذكر جديد")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
            }
            else if isFinished {
                // شاشة الإتمام
                CompletionView(color: dhikrType.color) {
                    idx = 0
                    rep = 0
                    isFinished = false
                }
            }
            else {
                // العرض العادي للأذكار
                
                
                
VStack {
GeometryReader { geo in
    Color.clear
        .onAppear { cardWidth = geo.size.width }

    TabView(selection: $idx) {
        ForEach(allList.indices, id: \.self) { i in
            ZStack(alignment: .topLeading) {
                // الخلفية
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.5))
                    .frame(width: cardWidth - 28, height: 533)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // المحتوى (عليه onTapGesture فقط هنا)
                VStack(spacing: 15) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 15) {
                            Spacer().frame(height: 40)
                            // داخل ملف DhikrDetailView.swift، في الموضع الذي تعرض فيه النص:

let raw = allList[i].text.trimmingCharacters(in: .whitespacesAndNewlines)
let cleanedText = raw
    .replacingOccurrences(of: "«", with: "")
    .replacingOccurrences(of: "»", with: "")

// نستخدم هنا الأسهم ❮ و ❯، بحجم 80% من حجم detailFontSize ولون أخضر:
(
    Text("❮ ")
        .font(.system(size: detailFontSize * 0.8))
        .foregroundColor(.green)
    
    + Text(cleanedText)
        .foregroundColor(.white.opacity(0.8))
    
    + Text(" ❯")
        .font(.system(size: detailFontSize * 0.8))
        .foregroundColor(.red)
)
.font(.system(size: detailFontSize, weight: .medium))
.multilineTextAlignment(.center)
.lineSpacing(8)
.padding(.horizontal, 20)
.padding(.vertical, 8)
.padding(.bottom, 10)
                            Color.clear.frame(height: 80)
                        }
                    }
                    .frame(maxHeight: 500)

RepetitionCounter(
    current: rep + 1,
    total: allList[i].repetition,
    color: .green,
    fontSize: 23
)
.padding(.bottom, 4)

                    if let note = allList[i].note {
                        Text(note)
                            .font(.system(size: detailFontSize * 0.8))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 6)
                    }
                }
                // onTapGesture فقط هنا على البطاقة
                .contentShape(Rectangle())
                .onTapGesture {
                    let target = allList[idx].repetition
                    if rep + 1 < target {
                        rep += 1
                        if soundEnabled {
                            playNextSound()
                        }
                        if hapticEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } else {
                        // انتهى التكرار الحالي
                        rep = 0
                        if idx < allList.count - 1 {
                            withAnimation(.easeInOut) {
                                idx += 1
                            }
                            if soundEnabled {
                                playNextSound()
                            }
                            if hapticEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } else {
                            // لا يوجد صفحات أكثر: إظهار شاشة النهاية
                            isFinished = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // زر المشاركة
                Button {
                    if hapticEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    isSharePresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .padding(6)
                }
                .padding(.leading, 24)
                .padding(.top, 22)

                // أزرار الزووم + تحرير/حذف
                HStack(spacing: 12) {
                    Button {
                        if detailFontSize > 12 {
                            if hapticEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            detailFontSize -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 16))
                            .padding(6)
                            .foregroundColor(.white)
                    }

                    Button {
                        if detailFontSize < 22 {
                            if hapticEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            detailFontSize += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .padding(6)
                            .foregroundColor(.white)
                    }

                    if i >= baseList.count {
                        Button {
                            if hapticEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            let ci = i - baseList.count
                            newText = customList[ci].text
                            newRep  = "\(customList[ci].repetition)"
                            newNote = customList[ci].note ?? ""
                            showEdit = true
                        } label: {
                            Image(systemName: "pencil")
                                .resizable().scaledToFit()
                                .frame(width: 14, height: 14)
                                .padding(7)
                                .foregroundColor(.green)
                        }

                        Button {
                            if hapticEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .resizable().scaledToFit()
                                .frame(width: 14, height: 14)
                                .padding(6)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.trailing, 30)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            .tag(i)
            .frame(height: 533)
            .scaleEffect(x: -1, y: 1)
        }
    }
    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    .environment(\.layoutDirection, .leftToRight) // ← يجعل الاتجاه إنجليزي لكن يحافظ على النص العربي
    .scaleEffect(x: -1, y: 1)
    .animation(.easeInOut, value: idx)
    .sheet(isPresented: $isSharePresented) {
        ActivityView(activityItems: [allList[idx].text])
    }
}
                    // شريط اختيار الصفحات
ScrollViewReader { proxy in
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
            Spacer()
            ForEach(0 ..< allList.count, id: \.self) { i in
Button {
                    idx = i; rep = 0
                    if hapticEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                    if soundEnabled  { playNextSound() }
                } label: {
                    Text("\(i+1)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(idx == i ? .white : dhikrType.color)
                        .frame(width: 30, height: 35)
                        .background(idx == i ? dhikrType.color : Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(dhikrType.color, lineWidth: 2))
                        .environment(\.locale, Locale(identifier: "ar"))
                }
                .id(i)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    .environment(\.layoutDirection, .rightToLeft)
    .onAppear {
        DispatchQueue.main.async {
            proxy.scrollTo(0, anchor: .trailing)
        }
    }
    .onChange(of: idx) { newValue in
        withAnimation {
            proxy.scrollTo(newValue, anchor: .center)
        }
    }
}
.frame(height: 55)

                    Spacer()

                    // تأكيد الحذف
// تأكد أن لديك هذا في الـ View:

// … ثم بدّل الـ .alert القديم بهذا:
.alert(
    Text(isArabic ? "تأكيد الحذف" : "Confirm Deletion"),
    isPresented: $showDeleteConfirm
) {
    Button(role: .destructive) {
        delete()
    } label: {
        Text(isArabic ? "نعم، احذف" : "Delete")
    }

    Button(role: .cancel) { }
    label: {
        Text(isArabic ? "لا" : "Cancel")
    }
} message: {
    Text(isArabic
         ? "هل تريد حذف هذا الذكر؟"
         : "Are you sure you want to delete this dhikr?")
}
                
                    
                    
                    // استبدل هذا الجزء:
                    // ─── زر “التالي” ───
Button {
    // لن يتم استخدام هذا الإجراء هنا لأنه تم نقله إلى الـ ButtonStyle
} label: {
    Image(systemName: "hand.point.up.braille.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 35, height: 35)
        .foregroundColor(.white)
        .padding(18)
        .background(dhikrType.color)
        .clipShape(Circle())
}
.buttonStyle(SmoothButtonStyle(hapticEnabled: hapticEnabled) {
    next()
})

                    .navigationBarTitle(dhikrType.rawValue, displayMode: .inline)
                        .navigationBarBackButtonHidden(true)   // ← هذا يخفي الـ Back الافتراضي
.toolbar {
    ToolbarItem(
        placement: selectedLanguage == "ar"
            ? .navigationBarTrailing   // بالعربي: على اليمين
            : .navigationBarLeading    // بالإنجليزي: على اليسار
    ) {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(
                systemName: selectedLanguage == "ar"
                    ? "chevron.forward"    // سهم يمين عند العربية
                    : "chevron.backward"   // سهم يسار عند الإنجليزية
            )
            .imageScale(.large)
            .foregroundColor(.blue)
        }
    }

                            // زر “إضافة”
ToolbarItem(
    placement: selectedLanguage == "ar"
        ? .navigationBarLeading   // بالعربي: يسار
        : .navigationBarTrailing  // بالإنجليزي: يمين
) {
    Button {
        newText = ""
        newRep  = ""
        newNote = ""
        showAdd = true
    } label: {
        Image(systemName: "plus")
            .foregroundColor(.green)
            .padding(4)
            .background(Circle().fill(Color.black))
    }
}
}
                    
                    // ─── شاشة إضافة ذكر جديد ───
                    .sheet(isPresented: $showAdd) {
                        AddDhikrView(
                            color: dhikrType.color,
                            newDhikrText: $newText,
                            newDhikrRepetition: $newRep,
                            newDhikrNote: $newNote,
                            showAddDhikr: $showAdd
                        ) {
                            if let n = Int(newRep), !newText.isEmpty {
                                let noteValue = newNote.isEmpty ? nil : newNote
                                customList.append(
                                    Dhikr(text: newText, repetition: min(n, 500), note: noteValue)
                                )
                                saveDhikrsToFile()
                                newText = ""
                                newRep  = ""
                                newNote = ""
                                showAdd = false
                            }
                        }
                    }
                    
                    // ─── شاشة تحرير ذكر موجود ───
                    .sheet(isPresented: $showEdit) {
                        AddDhikrView(
                            color: dhikrType.color,
                            newDhikrText: $newText,
                            newDhikrRepetition: $newRep,
                            newDhikrNote: $newNote,
                            showAddDhikr: $showEdit
                        ) {
                            if let n = Int(newRep), !newText.isEmpty {
                                let ci = idx - baseList.count
                                customList[ci].text = newText
                                customList[ci].repetition = min(n, 500)
                                customList[ci].note = newNote.isEmpty ? nil : newNote
                                saveDhikrsToFile()
                            }
                            showEdit = false
                        }
                    }
                    
                    // ─── باقي الـ modifiers ───
.onAppear {
    loadDhikrsFromFile()
    clampIndex()
}
.onChange(of: allList.count) { _ in
    clampIndex()
}
.onChange(of: idx) { _ in
    rep = 0
}
                }
            }
        }
    }

    // MARK: – Helper Methods

// بدّل هذا داخل next()
    private func next() {
        if rep + 1 < allList[idx].repetition {
            rep += 1
            if soundEnabled {
                playNextSound()
            }
            if hapticEnabled {
                nextHaptic.prepare()
                nextHaptic.impactOccurred()
            }
            return
        }

        rep = 0

        if idx < allList.count - 1 {
            withAnimation(.easeInOut) {
                idx += 1
            }
            if soundEnabled {
                playNextSound()
            }
            if hapticEnabled {
                nextHaptic.prepare()
                nextHaptic.impactOccurred()
            }
        } else {
            isFinished = true
        }
    }



private func slidePage(direction: CGFloat, width: CGFloat) {
    slideOffset = direction * width
    withAnimation(.easeInOut(duration: 0.15)) {
        slideOffset = 0
    }
}

private func flipPage(direction: Double) {
    flipping = true
    flipDirection = direction
    withAnimation(.easeInOut(duration: 0.5)) {
        flip = direction * 180
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        flip = 0
        flipping = false
    }
}

private func delete() {
    if idx < baseList.count {
        return
    }
    let ci = idx - baseList.count
    customList.remove(at: ci)
    saveDhikrsToFile()
    idx = min(idx, allList.count - 1)
    rep = 0
}

private func clampIndex() {
    if allList.isEmpty {
        idx = 0
        rep = 0
    } else {
        idx = min(idx, allList.count - 1)
        rep = min(rep, allList[idx].repetition - 1)
    }
}

private func saveDhikrsToFile() {
        // 1. تحديد مسار الملف
        let fileName = "customDhikrs_\(dhikrType.rawValue).json"
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDir.appendingPathComponent(fileName)
        
        // 2. التحويل إلى JSON وحفظه
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try JSONEncoder().encode(self.customList)
                try data.write(to: fileURL, options: [.atomicWrite]) // الكتابة الذرية
                print("✅ تم الحفظ في: \(fileURL.path)")
            } catch {
                print("❌ فشل الحفظ:", error)
            }
        }
    }
    
    private func loadDhikrsFromFile() {
        // 1. تحديد مسار الملف
        let fileName = "customDhikrs_\(dhikrType.rawValue).json"
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDir.appendingPathComponent(fileName)
        
        // 2. إذا الملف غير موجود، لا نفعل شيئًا (التشغيل الأول)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ لا يوجد ملف لحظِظ البيانات بعد: \(fileURL.path)")
            return
        }
        
        // 3. القراءة وفك التشفير
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoded = try JSONDecoder().decode([Dhikr].self, from: data)
                DispatchQueue.main.async {
                    self.customList = decoded
                    print("✅ تم تحميل \(decoded.count) ذكر من الملف.")
                }
            } catch {
                print("❌ فشل التحميل:", error)
            }
        }
    }
}

