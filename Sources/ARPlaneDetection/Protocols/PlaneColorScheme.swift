//
//  PlaneColorScheme.swift
//  ARPlaneDetection
//
//  Protocol for customizing plane visualization colors

import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlaneColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias PlaneColor = NSColor
#endif

/// Provides colors for plane visualization based on classification or alignment
@MainActor
public protocol PlaneColorScheme: Sendable {
    func color(for classification: PlaneClassification) -> PlaneColor
    func color(for alignment: PlaneAlignment) -> PlaneColor
}
