import SwiftUI

/// Shared gradient background used across Quran views
let quranBackgroundGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.05, green: 0.05, blue: 0.15),
        Color(red: 0.2, green: 0.1, blue: 0.3),
        Color(red: 0.1, green: 0.15, blue: 0.3),
        Color(red: 0.05, green: 0.15, blue: 0.1),
        Color(red: 0.15, green: 0.05, blue: 0.25)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
