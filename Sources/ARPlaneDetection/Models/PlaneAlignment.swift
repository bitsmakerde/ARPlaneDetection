//
//  PlaneAlignment.swift
//  ARPlaneDetection
//
//  Platform-agnostic plane alignment

import Foundation

/// Alignment/orientation of a detected plane
public enum PlaneAlignment: String, Codable, Sendable {
    case horizontal
    case vertical
    case slanted
    case unknown
}
