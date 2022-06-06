//
//  AddButton.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct AddButton: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 50, weight: .semibold, design: .rounded))
            .foregroundColor(Color(hex: "281B5A").opacity(0.7))
            .multilineTextAlignment(.center)
            .background(
                Image(systemName: "plus")
                    .font(.system(size: 70, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        .angularGradient(colors: [.blue, .red, .blue], center: .center, startAngle: .degrees(0), endAngle: .degrees(360))
                    )
                    .blur(radius: 12)
            )
            .frame(width: 120, height: 120, alignment: .center)
            .background(.ultraThinMaterial)
            .cornerRadius(60)
            .modifier(OutlineOverlay(cornerRadius: 60))
            .shadow(color: Color("Shadow").opacity(0.2), radius: 30, x: 0, y: 30)
    }
}

#if DEBUG
struct AddButton_Previews: PreviewProvider {
    static var previews: some View {
        AddButton()
    }
}
#endif

