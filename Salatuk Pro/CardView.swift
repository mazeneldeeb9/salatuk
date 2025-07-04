//
// CardView.swift
//
// Created by Anonym on 01.05.25
//
 
import SwiftUI

struct CardView: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(icon: "d1uaaIcon", title: "تجربه")
            .previewLayout(.sizeThatFits)
    }
}
