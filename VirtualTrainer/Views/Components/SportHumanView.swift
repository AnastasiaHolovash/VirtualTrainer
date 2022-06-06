//
//  SportHumanView.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct LogoView: View {
    var image = "figure.walk"

    var body: some View {
        Image(systemName: image)
//            .resizable()
            .frame(width: 26, height: 26)
            .cornerRadius(10)
            .padding(8)
            .font(.system(.title2).bold())
            .foregroundColor(.purple)
            .background(.ultraThinMaterial)
            .backgroundStyle(cornerRadius: 18, opacity: 0.4)
    }
}

#if DEBUG
struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        LogoView()
    }
}
#endif
