import SwiftUI

struct SurahDetailView: View {
    @StateObject private var viewModel: SurahDetailViewModel

    init(surah: Surah) {
        _viewModel = StateObject(wrappedValue: SurahDetailViewModel(surah: surah))
    }

    var body: some View {
        List(viewModel.ayat) { ayah in
            NavigationLink(destination: TafsirView(surah: viewModel.surah.id, ayah: ayah.numberInSurah)) {
                VStack(alignment: .trailing) {
                    Text(ayah.text)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .navigationTitle(viewModel.surah.name)
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
