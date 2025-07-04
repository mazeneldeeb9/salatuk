import SwiftUI

struct SurahListView: View {
    @StateObject private var viewModel = SurahListViewModel()

    var body: some View {
        List(viewModel.surahs) { surah in
            NavigationLink(destination: SurahDetailView(surah: surah)) {
                Text("\(surah.id). \(surah.name)")
            }
        }
        .navigationTitle(LocalizedStringKey("quran.title"))
        .onAppear { viewModel.loadSurahs() }
    }
}

struct SurahListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { SurahListView() }
    }
}
