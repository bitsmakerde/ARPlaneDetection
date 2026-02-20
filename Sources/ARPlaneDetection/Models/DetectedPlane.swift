//
//  DetectedPlane.swift
//  ARPlaneDetection
//
//  Platform-agnostic representation of a detected AR plane

import Foundation
import simd

/// A detected plane surface in the AR scene
public struct DetectedPlane: Identifiable, Sendable {
    public let id: UUID
    public let classification: PlaneClassification
    public let alignment: PlaneAlignment
    public let transform: simd_float4x4
    public let vertices: [SIMD3<Float>]
    public let faceIndices: [UInt32]

    public init(
        id: UUID,
        classification: PlaneClassification,
        alignment: PlaneAlignment,
        transform: simd_float4x4,
        vertices: [SIMD3<Float>],
        faceIndices: [UInt32]
    ) {
        self.id = id
        self.classification = classification
        self.alignment = alignment
        self.transform = transform
        self.vertices = vertices
        self.faceIndices = faceIndices
    }
}
