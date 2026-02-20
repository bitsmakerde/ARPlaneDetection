//
//  PlaneClassification.swift
//  ARPlaneDetection
//
//  Platform-agnostic plane surface classification

import Foundation

/// Classification of a detected plane surface
public enum PlaneClassification: String, Codable, Sendable {
    case wall
    case ceiling
    case floor
    case table
    case seat
    case window
    case door
    case unknown
}
