//
//  PlaneDetectionManagerTests.swift
//  ARPlaneDetectionTests
//
//  Tests for plane detection manager and color schemes

import XCTest
import simd
@testable import ARPlaneDetection

final class PlaneDetectionManagerTests: XCTestCase {

    // MARK: - Mock Delegate

    final class MockDelegate: PlaneDetectionDelegate {
        var addedPlanes: [DetectedPlane] = []
        var updatedPlanes: [DetectedPlane] = []
        var removedIDs: [UUID] = []

        func planeDetectionManager(_ manager: PlaneDetectionManager, didAdd plane: DetectedPlane) {
            addedPlanes.append(plane)
        }

        func planeDetectionManager(_ manager: PlaneDetectionManager, didUpdate plane: DetectedPlane) {
            updatedPlanes.append(plane)
        }

        func planeDetectionManager(_ manager: PlaneDetectionManager, didRemove planeID: UUID) {
            removedIDs.append(planeID)
        }
    }

    // MARK: - Helper

    private func makePlane(
        id: UUID = UUID(),
        classification: PlaneClassification = .floor,
        alignment: PlaneAlignment = .horizontal
    ) -> DetectedPlane {
        DetectedPlane(
            id: id,
            classification: classification,
            alignment: alignment,
            transform: simd_float4x4(1),
            vertices: [],
            faceIndices: []
        )
    }

    // MARK: - Add Tests

    @MainActor
    func test_handlePlaneAdded_storesPlane() async {
        let sut = PlaneDetectionManager()
        let plane = makePlane()

        await sut.handlePlaneAdded(plane)

        XCTAssertEqual(sut.detectedPlanes.count, 1)
        XCTAssertEqual(sut.detectedPlanes[plane.id]?.classification, .floor)
    }

    @MainActor
    func test_handlePlaneAdded_createsEntity() async {
        let sut = PlaneDetectionManager()
        let plane = makePlane()

        await sut.handlePlaneAdded(plane)

        XCTAssertEqual(sut.planeEntities.count, 1)
        XCTAssertNotNil(sut.planeEntities[plane.id])
    }

    @MainActor
    func test_handlePlaneAdded_notifiesDelegate() async {
        let sut = PlaneDetectionManager()
        let delegate = MockDelegate()
        sut.delegate = delegate

        let plane = makePlane()
        await sut.handlePlaneAdded(plane)

        XCTAssertEqual(delegate.addedPlanes.count, 1)
        XCTAssertEqual(delegate.addedPlanes.first?.id, plane.id)
    }

    // MARK: - Update Tests

    @MainActor
    func test_handlePlaneUpdated_updatesStoredPlane() async {
        let sut = PlaneDetectionManager()
        let id = UUID()

        let plane1 = makePlane(id: id, classification: .floor)
        await sut.handlePlaneAdded(plane1)

        let plane2 = makePlane(id: id, classification: .wall)
        await sut.handlePlaneUpdated(plane2)

        XCTAssertEqual(sut.detectedPlanes[id]?.classification, .wall)
    }

    @MainActor
    func test_handlePlaneUpdated_notifiesDelegate() async {
        let sut = PlaneDetectionManager()
        let delegate = MockDelegate()
        sut.delegate = delegate

        let plane = makePlane()
        await sut.handlePlaneAdded(plane)
        await sut.handlePlaneUpdated(plane)

        XCTAssertEqual(delegate.updatedPlanes.count, 1)
    }

    // MARK: - Remove Tests

    @MainActor
    func test_handlePlaneRemoved_removesPlane() async {
        let sut = PlaneDetectionManager()
        let id = UUID()

        let plane = makePlane(id: id)
        await sut.handlePlaneAdded(plane)
        sut.handlePlaneRemoved(id: id)

        XCTAssertTrue(sut.detectedPlanes.isEmpty)
        XCTAssertTrue(sut.planeEntities.isEmpty)
    }

    @MainActor
    func test_handlePlaneRemoved_notifiesDelegate() async {
        let sut = PlaneDetectionManager()
        let delegate = MockDelegate()
        sut.delegate = delegate
        let id = UUID()

        let plane = makePlane(id: id)
        await sut.handlePlaneAdded(plane)
        sut.handlePlaneRemoved(id: id)

        XCTAssertEqual(delegate.removedIDs, [id])
    }

    @MainActor
    func test_handlePlaneRemoved_unknownID_doesNotCrash() {
        let sut = PlaneDetectionManager()
        sut.handlePlaneRemoved(id: UUID())
        // Should not crash
        XCTAssertTrue(sut.detectedPlanes.isEmpty)
    }

    // MARK: - Multiple Planes

    @MainActor
    func test_multipleAdds_storesAll() async {
        let sut = PlaneDetectionManager()

        await sut.handlePlaneAdded(makePlane(classification: .floor))
        await sut.handlePlaneAdded(makePlane(classification: .wall))
        await sut.handlePlaneAdded(makePlane(classification: .ceiling))

        XCTAssertEqual(sut.detectedPlanes.count, 3)
        XCTAssertEqual(sut.planeEntities.count, 3)
    }

    // MARK: - DetectedPlane Model Tests

    func test_detectedPlane_identifiable() {
        let id = UUID()
        let plane = makePlane(id: id)
        XCTAssertEqual(plane.id, id)
    }

    func test_detectedPlane_storesVertices() {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 0, 1)
        ]
        let plane = DetectedPlane(
            id: UUID(), classification: .floor, alignment: .horizontal,
            transform: .init(1), vertices: vertices, faceIndices: [0, 1, 2]
        )
        XCTAssertEqual(plane.vertices.count, 3)
        XCTAssertEqual(plane.faceIndices.count, 3)
    }

    // MARK: - Color Scheme Tests

    @MainActor
    func test_defaultColorScheme_floorIsGreen() {
        let scheme = DefaultPlaneColorScheme()
        XCTAssertEqual(scheme.color(for: .floor), .systemGreen)
    }

    @MainActor
    func test_defaultColorScheme_wallIsRed() {
        let scheme = DefaultPlaneColorScheme()
        XCTAssertEqual(scheme.color(for: .wall), .systemRed)
    }

    @MainActor
    func test_defaultColorScheme_ceilingIsBlue() {
        let scheme = DefaultPlaneColorScheme()
        XCTAssertEqual(scheme.color(for: .ceiling), .systemBlue)
    }

    @MainActor
    func test_defaultColorScheme_horizontalIsOrange() {
        let scheme = DefaultPlaneColorScheme()
        XCTAssertEqual(scheme.color(for: .horizontal), .systemOrange)
    }

    @MainActor
    func test_defaultColorScheme_verticalIsPurple() {
        let scheme = DefaultPlaneColorScheme()
        XCTAssertEqual(scheme.color(for: .vertical), .systemPurple)
    }

    @MainActor
    func test_defaultColorScheme_unknownClassification_isWhite() {
        let scheme = DefaultPlaneColorScheme()
        XCTAssertEqual(scheme.color(for: PlaneClassification.unknown), .white)
    }

    // MARK: - Configuration Tests

    @MainActor
    func test_defaultConfiguration() {
        let config = PlaneDetectionManager.Configuration()
        XCTAssertFalse(config.createVisualMesh)
        XCTAssertNil(config.colorScheme)
    }

    @MainActor
    func test_customConfiguration() {
        let config = PlaneDetectionManager.Configuration(
            createVisualMesh: true,
            colorScheme: DefaultPlaneColorScheme()
        )
        XCTAssertTrue(config.createVisualMesh)
        XCTAssertNotNil(config.colorScheme)
    }
}
