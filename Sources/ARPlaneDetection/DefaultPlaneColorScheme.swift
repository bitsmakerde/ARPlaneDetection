//
//  DefaultPlaneColorScheme.swift
//  ARPlaneDetection
//
//  Default color scheme matching the original Audi app colors

import Foundation

/// Default plane color scheme: floor=green, wall=red, ceiling=blue,
/// horizontal=orange, vertical=purple, slanted=cyan
public struct DefaultPlaneColorScheme: PlaneColorScheme, Sendable {

    public init() {}

    public func color(for classification: PlaneClassification) -> PlaneColor {
        switch classification {
        case .wall:
            return .systemRed
        case .ceiling:
            return .systemBlue
        case .floor:
            return .systemGreen
        default:
            return .white
        }
    }

    public func color(for alignment: PlaneAlignment) -> PlaneColor {
        switch alignment {
        case .horizontal:
            return .systemOrange
        case .vertical:
            return .systemPurple
        case .slanted:
            return .systemCyan
        case .unknown:
            return .white
        }
    }
}
