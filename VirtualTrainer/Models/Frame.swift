//
//  Frame.swift
//  VirtualTrainer
//
//  Created by Anastasia Holovash on 01.06.2022.
//

import Foundation
import ARKit

typealias Frame = [simd_float4x4]
typealias Frames = [Frame]

extension simd_float4x4: Codable {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        try self.init(container.decode([SIMD4<Float>].self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode([columns.0,columns.1, columns.2, columns.3])
    }
}

