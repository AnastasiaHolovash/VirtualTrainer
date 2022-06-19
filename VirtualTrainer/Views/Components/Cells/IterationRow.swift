//
//  IterationRow.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 06.06.2022.
//

import SwiftUI

struct IterationRow: View {
    var iteration: IterationResults

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(iteration.scoreDescription)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(width: 36, height: 36)
                .mask(Circle())
                .padding(12)
                .background(Color(UIColor.systemBackground).opacity(0.3))
                .mask(Circle())
                .overlay(CircularView(value: CGFloat(iteration.normalisedScore)))
            VStack(alignment: .leading, spacing: 8) {
                Text("\(iteration.number) повторення")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(iteration.quality.rawValue)
                    .fontWeight(.semibold)
                Text(iteration.speedDescription)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

/*
struct IterationRow_Previews: PreviewProvider {
    static var previews: some View {
        IterationRow(iteration: iterationResultsMock)
    }
}
*/
