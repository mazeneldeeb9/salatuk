import SwiftUI

/// Shows tafsir for a single ayah with app styling

struct TafsirView: View {
    @StateObject private var viewModel: TafsirViewModel

    init(surah: Int, ayah: Int) {
        _viewModel = StateObject(wrappedValue: TafsirViewModel(surah: surah, ayah: ayah))
    }

    var body: some View {
        ZStack {
            quranBackgroundGradient.ignoresSafeArea()

            ScrollView {
                if let tafsir = viewModel.tafsir {
                    Text(tafsir.text)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text(LocalizedStringKey("no.tafsir"))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("tafsir.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadTafsir() }
    }
}

struct TafsirView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { TafsirView(surah: 1, ayah: 1) }
    }
}
