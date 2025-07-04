import SwiftUI

/// Detail view showing ayat of a surah using app styling

struct SurahDetailView: View {
    @StateObject private var viewModel: SurahDetailViewModel

    init(surah: Surah) {
        _viewModel = StateObject(wrappedValue: SurahDetailViewModel(surah: surah))
    }

    var body: some View {
        ZStack {
            quranBackgroundGradient.ignoresSafeArea()

            List(viewModel.ayat) { ayah in
                NavigationLink(destination: TafsirView(surah: viewModel.surah.id, ayah: ayah.numberInSurah)) {
                    VStack(alignment: .trailing) {
                        Text(ayah.text)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
        .navigationTitle(viewModel.surah.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadAyat() }
    }
}

struct SurahDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SurahDetailView(surah: Surah(id: 1, name: "الفاتحة", englishName: "Al-Fatihah", englishNameTranslation: nil, numberOfAyahs: 7))
        }
    }
}
