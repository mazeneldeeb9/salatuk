import SwiftUI

struct ZakatCalculatorView: View {
    enum Mode {
        case gold, money
    }

    @AppStorage("selectedLanguage")
    private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    @Environment(\.presentationMode) private var presentationMode

    @State private var mode: Mode = .gold

    // — Inputs for gold mode —
    @State private var weight: String = ""
    @State private var pricePerGram: String = ""
    @State private var purityIndex: Int = 0

    // — Inputs for money mode —
    @State private var amount: String = ""
    @State private var moneyGoldPrice: String = ""

    // — Outputs —
    @State private var result: Double?
    @State private var pureZakat: Double?
    @State private var exemptMessage: String?
    @State private var showPurityAlert: Bool = false
    @State private var purityAlertMessage: String = ""

    // — Track manual calculate —
    @State private var hasCalculatedOnce: Bool = false

    private let purityLabels: [LocalizedStringKey] = [
        "Purity.PureGold",
        "Purity.24Ct",
        "Purity.21Ct",
        "Purity.18Ct"
    ]

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "OMR"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.2,  green: 0.1,  blue: 0.3),
                    Color(red: 0.1,  green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.15, blue: 0.1),
                    Color(red: 0.15, green: 0.05, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)

            ScrollView {
                VStack(spacing: 20) {
                    // — Mode selector —
                    HStack {
                        Button("Zakat.Gold") {
                            mode = .gold
                            clearResults()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(mode == .gold ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Zakat.Money") {
                            mode = .money
                            clearResults()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(mode == .money ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // — Inputs —
                    if mode == .gold {
                        goldInputs
                    } else {
                        moneyInputs
                    }

                    // — Result for Zakat —
                    if let zakat = result {
                        Text(
                            String(
                                format: NSLocalizedString("zakat.result", comment: ""),
                                zakat,
                                currencyCode
                            )
                        )
                        .font(.title2)
                        .foregroundColor(.green)
                        .padding(.bottom, 4)

                        // عرض زكاة الخالص فقط لعيار 21 أو 18
                        if let pure = pureZakat, purityIndex >= 2 {
                            let formattedPure = String(format: "%.2f", pure)
                            Text("زكاة لو كان الذهب خالص (24 قيراط): \(formattedPure) \(currencyCode)")
                                .font(.body)
                                .foregroundColor(.orange)
                                .padding(.bottom, 8)
                        }
                    }

                    // — Exempt message —
                    if let msg = exemptMessage {
                        Text(msg)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // — Calculate button —
                    Button(LocalizedStringKey("calculate.button")) {
                        calculate()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 30)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 30)
            }
        }
        // — Swipe to dismiss —
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let screenWidth = UIScreen.main.bounds.width
                    if value.startLocation.x > screenWidth - 20 && value.translation.width < -100 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
        // — Alert for purity notice —
        .alert("تنبيه مهم", isPresented: $showPurityAlert) {
            Button("حسناً", role: .cancel) { }
        } message: {
            Text(purityAlertMessage)
        }
        .navigationTitle(LocalizedStringKey("zakat.calculator.title"))
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
                    .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: – Subviews

    private var goldInputs: some View {
        VStack(spacing: 12) {
            Text(LocalizedStringKey("gold.weight"))
                .foregroundColor(.white)
                .bold()

            TextField(LocalizedStringKey("weight_placeholder"), text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: weight) { _ in clearResults() }

            Text(String(format: NSLocalizedString("price_per_gram", comment: ""), currencyCode))
                .foregroundColor(.white)
                .bold()

            TextField(LocalizedStringKey("price_placeholder"), text: $pricePerGram)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: pricePerGram) { _ in clearResults() }

            Text(LocalizedStringKey("gold_type"))
                .foregroundColor(.white)
                .bold()

            HStack(spacing: 6) {
                ForEach(0..<purityLabels.count, id: \.self) { idx in
                    Button(action: { purityIndex = idx }) {
                        Text(purityLabels[idx])
                            .font(.caption2)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(purityIndex == idx ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
        // إعادة الحساب تلقائيًا بعد أول احتساب لأي عيار
        .onChange(of: purityIndex) { _ in
            if mode == .gold && hasCalculatedOnce {
                calculate()
            }
        }
    }

    private var moneyInputs: some View {
        VStack(spacing: 12) {
            Text(LocalizedStringKey("money.amount"))
                .foregroundColor(.white)
                .bold()

            TextField(LocalizedStringKey("amount_placeholder"), text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: amount) { _ in clearResults() }

            Text(String(format: NSLocalizedString("price_per_gram", comment: ""), currencyCode))
                .foregroundColor(.white)
                .bold()

            TextField(LocalizedStringKey("price_placeholder"), text: $moneyGoldPrice)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: moneyGoldPrice) { _ in clearResults() }
        }
        .padding(.horizontal)
    }

    // MARK: – Logic

    private func calculate() {
        // سجل أن المستخدم احتسب مرة واحدة
        hasCalculatedOnce = true

        clearResults()

        switch mode {
        case .gold:
            guard
                let w = Double(weight.replacingOccurrences(of: ",", with: ".")),
                let p = Double(pricePerGram.replacingOccurrences(of: ",", with: "."))
            else { return }

            let karat = [24.0, 24.0, 21.0, 18.0][purityIndex]
            if karat == 21.0 {
                purityAlertMessage = """
                لقد اخترت ذهب عيار 21 (نقاء 87.5%). \
                سيقوم التطبيق بتحويل الوزن إلى ما يعادله من ذهب خالص (عيار 24) ثم يحسب الزكاة بدقة.
                """
                showPurityAlert = true
            } else if karat == 18.0 {
                purityAlertMessage = """
                لقد اخترت ذهب عيار 18 (نقاء 75%). \
                سيقوم التطبيق بتحويل الوزن إلى ما يعادله من ذهب خالص (عيار 24) ثم يحسب الزكاة بدقة. \
                تأكد من أن السعر المدخل هو سعر غرام الذهب الخالص أو سعر مجوهرات العيار 18 قبل المتابعة.
                """
                showPurityAlert = true
            }

            let purity    = karat / 24.0
            let pureValue = w * p
            let value     = pureValue * purity
            let nisabGold = 85.0 * p

            if value < nisabGold {
                let formattedP     = String(format: "%.2f", p)
                let formattedNisab = String(format: "%.2f", nisabGold)
                exemptMessage = String(
                    format: NSLocalizedString("zakat.exempt_message", comment: ""),
                    formattedP, formattedNisab, currencyCode
                )
            } else {
                result = value * 0.025
                pureZakat = pureValue * 0.025
            }

        case .money:
            guard
                let a = Double(amount.replacingOccurrences(of: ",", with: ".")),
                let p = Double(moneyGoldPrice.replacingOccurrences(of: ",", with: "."))
            else { return }

            let nisabMoney = 85.0 * p
            if a < nisabMoney {
                let formattedNisabMoney = String(format: "%.2f", nisabMoney)
                exemptMessage = String(
                    format: NSLocalizedString("zakat.money_exempt_message", comment: ""),
                    formattedNisabMoney, currencyCode
                )
            } else {
                result = a * 0.025
            }
        }
    }

    private func clearResults() {
        result = nil
        pureZakat = nil
        exemptMessage = nil
        showPurityAlert = false
        purityAlertMessage = ""
    }
}