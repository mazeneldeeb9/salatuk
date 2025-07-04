import SwiftUI

struct TafsirView: View {
    @StateObject private var viewModel: TafsirViewModel

    init(surah: Int, ayah: Int) {
        _viewModel = StateObject(wrappedValue: TafsirViewModel(surah: surah, ayah: ayah))
    }

    var body: some View {
        ScrollView {
            if let tafsir = viewModel.tafsir {
                Text(tafsir.text)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                Text(LocalizedStringKey("no.tafsir"))
            }
        }
        .navigationTitle(LocalizedStringKey("tafsir.title"))
        .onAppear { viewModel.loadTafsir() }
    }
}

struct TafsirView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { TafsirView(surah: 1, ayah: 1) }
    }
}
