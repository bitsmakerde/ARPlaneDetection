//
//  PlaneDetectionManager.swift
//  ARPlaneDetection
//
//  Manages AR plane detection and provides a testable API

import Foundation
import RealityKit
import simd

#if os(visionOS)
import ARKit
#endif

/// Manages plane detection, creating collision entities for detected planes.
@Observable
@MainActor
public final class PlaneDetectionManager {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public var createVisualMesh: Bool
        public var colorScheme: (any PlaneColorScheme)?

        #if os(visionOS)
        public var alignments: [PlaneAnchor.Alignment]

        public init(
            createVisualMesh: Bool = false,
            colorScheme: (any PlaneColorScheme)? = nil,
            alignments: [PlaneAnchor.Alignment] = [.horizontal]
        ) {
            self.createVisualMesh = createVisualMesh
            self.colorScheme = colorScheme
            self.alignments = alignments
        }
        #else
        public init(
            createVisualMesh: Bool = false,
            colorScheme: (any PlaneColorScheme)? = nil
        ) {
            self.createVisualMesh = createVisualMesh
            self.colorScheme = colorScheme
        }
        #endif
    }

    // MARK: - State

    public private(set) var detectedPlanes: [UUID: DetectedPlane] = [:]
    public private(set) var planeEntities: [UUID: Entity] = [:]
    public weak var delegate: (any PlaneDetectionDelegate)?

    public let configuration: Configuration

    #if os(visionOS)
    /// The ARKit provider instance (managed internally)
    public private(set) var provider: PlaneDetectionProvider?
    #endif

    // MARK: - Init

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: - Session Management

    #if os(visionOS)
    /// Start plane detection (creates and returns the provider for ARKitSession.run)
    public func startSession() -> PlaneDetectionProvider {
        let provider = PlaneDetectionProvider(alignments: configuration.alignments)
        self.provider = provider
        return provider
    }

    /// Stop plane detection and cleanup
    public func stopSession() {
        provider = nil
        detectedPlanes.removeAll()
        for entity in planeEntities.values {
            entity.removeFromParent()
        }
        planeEntities.removeAll()
    }
    #endif

    // MARK: - visionOS: Process ARKit PlaneDetectionProvider updates

    #if os(visionOS)
    public func processPlaneUpdates(from provider: PlaneDetectionProvider) async {
        guard PlaneDetectionProvider.isSupported else { return }
        for await update in provider.anchorUpdates {
            switch update.event {
            case .added, .updated:
                let anchor = update.anchor
                let plane = DetectedPlane(from: anchor)
                if update.event == .added {
                    await handlePlaneAdded(plane)
                } else {
                    await handlePlaneUpdated(plane)
                }

            case .removed:
                let anchor = update.anchor
                handlePlaneRemoved(id: anchor.id)
            }
        }
    }

    /// Convenience method to process updates from the internally managed provider
    public func processPlaneUpdates() async {
        guard let provider else {
            print("Warning: PlaneDetectionManager provider not started. Call startSession() first.")
            return
        }
        await processPlaneUpdates(from: provider)
    }
    #endif

    // MARK: - Testable API

    /// Handle a newly detected plane
    public func handlePlaneAdded(_ plane: DetectedPlane) async {
        detectedPlanes[plane.id] = plane

        let entity = await createPlaneEntity(for: plane)
        planeEntities[plane.id] = entity

        delegate?.planeDetectionManager(self, didAdd: plane)
    }

    /// Handle an updated plane
    public func handlePlaneUpdated(_ plane: DetectedPlane) async {
        detectedPlanes[plane.id] = plane

        // Update existing entity transform
        if let entity = planeEntities[plane.id] {
            entity.setTransformMatrix(plane.transform, relativeTo: nil)
        } else {
            let entity = await createPlaneEntity(for: plane)
            planeEntities[plane.id] = entity
        }

        delegate?.planeDetectionManager(self, didUpdate: plane)
    }

    /// Handle a removed plane
    public func handlePlaneRemoved(id: UUID) {
        detectedPlanes.removeValue(forKey: id)

        if let entity = planeEntities[id] {
            entity.removeFromParent()
            planeEntities.removeValue(forKey: id)
        }

        delegate?.planeDetectionManager(self, didRemove: id)
    }

    // MARK: - Entity Creation

    /// Create a RealityKit entity with collision for a detected plane
    public func createPlaneEntity(for plane: DetectedPlane) async -> Entity {
        let entity = Entity()
        entity.name = "Plane \(plane.id)"
        entity.setTransformMatrix(plane.transform, relativeTo: nil)

        // Create mesh from vertices/faces if available
        if !plane.vertices.isEmpty && !plane.faceIndices.isEmpty {
            if let meshResource = createMeshResource(vertices: plane.vertices, faceIndices: plane.faceIndices) {
                // Add collision
                if #available(macOS 15.0, iOS 18.0, visionOS 2.0, *) {
                    let collisionShape = try? await ShapeResource.generateStaticMesh(from: meshResource)
                    if let collisionShape {
                        entity.components.set(CollisionComponent(shapes: [collisionShape]))
                    }
                }

                // Optionally add visual material
                if configuration.createVisualMesh {
                    var material = PhysicallyBasedMaterial()
                    if let colorScheme = configuration.colorScheme {
                        material.baseColor.tint = colorScheme.color(for: plane.classification)
                    }
                    entity.components.set(ModelComponent(mesh: meshResource, materials: [material]))
                }
            }
        }

        return entity
    }

    // MARK: - Mesh Generation

    private func createMeshResource(vertices: [SIMD3<Float>], faceIndices: [UInt32]) -> MeshResource? {
        do {
            var contents = MeshResource.Contents()
            contents.instances = [MeshResource.Instance(id: "main", model: "model")]
            var part = MeshResource.Part(id: "part", materialIndex: 0)
            part.positions = MeshBuffers.Positions(vertices)
            part.triangleIndices = MeshBuffer(faceIndices)
            contents.models = [MeshResource.Model(id: "model", parts: [part])]
            return try MeshResource.generate(from: contents)
        } catch {
            print("Failed to create mesh resource for plane: \(error)")
            return nil
        }
    }
}

// MARK: - visionOS ARKit Conversion

#if os(visionOS)
extension DetectedPlane {
    /// Create a DetectedPlane from an ARKit PlaneAnchor
    init(from anchor: PlaneAnchor) {
        self.id = anchor.id

        // Convert classification
        let classification: PlaneClassification
        switch anchor.classification {
        case .wall: classification = .wall
        case .ceiling: classification = .ceiling
        case .floor: classification = .floor
        case .table: classification = .table
        case .seat: classification = .seat
        case .window: classification = .window
        case .door: classification = .door
        default: classification = .unknown
        }

        // Convert alignment
        let alignment: PlaneAlignment
        switch anchor.alignment {
        case .horizontal: alignment = .horizontal
        case .vertical: alignment = .vertical
        default: alignment = .unknown
        }

        // Convert vertices
        let meshVertices = anchor.geometry.meshVertices
        var vertexArray: [SIMD3<Float>] = []
        for i in 0..<meshVertices.count {
            let vertex = meshVertices.buffer.contents()
                .advanced(by: meshVertices.offset + meshVertices.stride * i)
                .assumingMemoryBound(to: (Float, Float, Float).self)
                .pointee
            vertexArray.append(SIMD3<Float>(vertex.0, vertex.1, vertex.2))
        }

        // Convert faces
        let meshFaces = anchor.geometry.meshFaces
        var faceArray: [UInt32] = []
        let totalFaces = meshFaces.count * meshFaces.primitive.indexCount
        for i in 0..<totalFaces {
            let face = meshFaces.buffer.contents()
                .advanced(by: i * MemoryLayout<Int32>.size)
                .assumingMemoryBound(to: Int32.self)
                .pointee
            faceArray.append(UInt32(face))
        }

        self.classification = classification
        self.alignment = alignment
        self.transform = anchor.originFromAnchorTransform
        self.vertices = vertexArray
        self.faceIndices = faceArray
    }
}
#endif
