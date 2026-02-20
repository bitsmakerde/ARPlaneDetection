//
//  PlaneDetectionDelegate.swift
//  ARPlaneDetection
//
//  Delegate protocol for plane detection events

import Foundation

/// Receives callbacks when planes are added, updated, or removed
@MainActor
public protocol PlaneDetectionDelegate: AnyObject {
    func planeDetectionManager(_ manager: PlaneDetectionManager, didAdd plane: DetectedPlane)
    func planeDetectionManager(_ manager: PlaneDetectionManager, didUpdate plane: DetectedPlane)
    func planeDetectionManager(_ manager: PlaneDetectionManager, didRemove planeID: UUID)
}
