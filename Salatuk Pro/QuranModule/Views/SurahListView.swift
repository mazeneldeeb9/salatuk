import SwiftUI

/// List of all surahs with styling similar to the rest of the app

struct SurahListView: View {
    @StateObject private var viewModel = SurahListViewModel()

    var body: some View {
        ZStack {
            quranBackgroundGradient.ignoresSafeArea()

            List(viewModel.surahs) { surah in
                NavigationLink(destination: SurahDetailView(surah: surah)) {
                    HStack {
                        Text("\(surah.id).")
                            .foregroundColor(.white)
                        Text(surah.name)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
        .navigationTitle(LocalizedStringKey("quran.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadSurahs() }
    }
}

struct SurahListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { SurahListView() }
    }
}
