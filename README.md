# ARPlaneDetection

A Swift package for detecting and managing AR planes across iOS, visionOS, and macOS platforms. This package provides a clean, testable API for plane detection with RealityKit integration and customizable visualization.

## Features

- **Cross-Platform Support**: Works on iOS 26+, visionOS 26+, and macOS 26+
- **Real-time Plane Detection**: Detects horizontal and vertical planes in AR environments
- **Plane Classification**: Identifies different surface types (floor, wall, ceiling, table, etc.)
- **RealityKit Integration**: Automatically creates collision entities for detected planes
- **Customizable Visualization**: Optional visual mesh rendering with configurable color schemes
- **Delegate Pattern**: Receive callbacks for plane additions, updates, and removals
- **Testable Architecture**: Public APIs designed for unit testing without requiring ARKit

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/ARPlaneDetection.git", from: "1.0.0")
]
```

Or in Xcode:
1. File > Add Package Dependencies
2. Enter the repository URL
3. Select your desired version

## Usage

### Basic Setup (visionOS)

```swift
import ARKit
import ARPlaneDetection

@MainActor
class MyARView: ObservableObject {
    let planeManager = PlaneDetectionManager()
    let arkitSession = ARKitSession()
    
    func startPlaneDetection() async {
        // Configure plane detection
        let config = PlaneDetectionManager.Configuration(
            createVisualMesh: true,
            colorScheme: DefaultPlaneColorScheme(),
            alignments: [.horizontal, .vertical]
        )
        
        let manager = PlaneDetectionManager(configuration: config)
        
        // Start ARKit session with plane detection
        let provider = manager.startSession()
        
        do {
            try await arkitSession.run([provider])
            
            // Process plane updates in a Task
            Task {
                await manager.processPlaneUpdates()
            }
        } catch {
            print("Failed to start ARKit session: \(error)")
        }
    }
}
```

### Configuration Options

```swift
let config = PlaneDetectionManager.Configuration(
    createVisualMesh: true,           // Show visual representation of planes
    colorScheme: DefaultPlaneColorScheme(), // Custom colors for plane types
    alignments: [.horizontal, .vertical]    // Which plane orientations to detect
)
```

### Using the Delegate Pattern

Implement `PlaneDetectionDelegate` to receive real-time updates:

```swift
class MyPlaneHandler: PlaneDetectionDelegate {
    func planeDetectionManager(_ manager: PlaneDetectionManager, didAdd plane: DetectedPlane) {
        print("New plane detected: \(plane.classification)")
    }
    
    func planeDetectionManager(_ manager: PlaneDetectionManager, didUpdate plane: DetectedPlane) {
        print("Plane updated: \(plane.id)")
    }
    
    func planeDetectionManager(_ manager: PlaneDetectionManager, didRemove planeID: UUID) {
        print("Plane removed: \(planeID)")
    }
}

// Set the delegate
planeManager.delegate = myHandler
```

### Accessing Detected Planes

```swift
// Get all detected planes
let planes = planeManager.detectedPlanes

// Get plane entities for RealityKit scene
let entities = planeManager.planeEntities

// Find specific plane
if let plane = planeManager.detectedPlanes[planeID] {
    print("Plane classification: \(plane.classification)")
    print("Plane alignment: \(plane.alignment)")
    print("Vertices: \(plane.vertices.count)")
}
```

### Custom Color Schemes

Create a custom color scheme by conforming to `PlaneColorScheme`:

```swift
@MainActor
struct MyColorScheme: PlaneColorScheme {
    func color(for classification: PlaneClassification) -> PlaneColor {
        switch classification {
        case .floor:
            return .green.withAlphaComponent(0.5)
        case .wall:
            return .blue.withAlphaComponent(0.5)
        case .table:
            return .orange.withAlphaComponent(0.5)
        default:
            return .gray.withAlphaComponent(0.3)
        }
    }
    
    func color(for alignment: PlaneAlignment) -> PlaneColor {
        switch alignment {
        case .horizontal:
            return .green.withAlphaComponent(0.5)
        case .vertical:
            return .blue.withAlphaComponent(0.5)
        default:
            return .gray.withAlphaComponent(0.3)
        }
    }
}
```

### Adding Plane Entities to RealityKit Scene

```swift
import RealityKit

// Add detected plane entities to your RealityKit scene
for (_, entity) in planeManager.planeEntities {
    contentEntity.addChild(entity)
}
```

### Testing Without ARKit

The package provides a testable API that doesn't require ARKit:

```swift
func testPlaneDetection() async {
    let manager = PlaneDetectionManager()
    
    // Create a mock plane
    let plane = DetectedPlane(
        id: UUID(),
        classification: .floor,
        alignment: .horizontal,
        transform: matrix_identity_float4x4,
        vertices: [SIMD3<Float>(0, 0, 0)],
        faceIndices: [0]
    )
    
    // Test plane handling
    await manager.handlePlaneAdded(plane)
    
    XCTAssertEqual(manager.detectedPlanes.count, 1)
    XCTAssertNotNil(manager.planeEntities[plane.id])
}
```

## API Reference

### PlaneDetectionManager

The main class for managing plane detection.

**Properties:**
- `detectedPlanes: [UUID: DetectedPlane]` - All currently detected planes
- `planeEntities: [UUID: Entity]` - RealityKit entities for each plane
- `delegate: PlaneDetectionDelegate?` - Delegate for receiving updates
- `configuration: Configuration` - Detection configuration

**Methods:**
- `startSession() -> PlaneDetectionProvider` - Start plane detection (visionOS)
- `stopSession()` - Stop detection and cleanup (visionOS)
- `processPlaneUpdates()` - Process ARKit plane updates
- `handlePlaneAdded(_ plane: DetectedPlane)` - Handle new plane
- `handlePlaneUpdated(_ plane: DetectedPlane)` - Handle plane update
- `handlePlaneRemoved(id: UUID)` - Handle plane removal

### DetectedPlane

A platform-agnostic representation of a detected plane.

**Properties:**
- `id: UUID` - Unique identifier
- `classification: PlaneClassification` - Surface type
- `alignment: PlaneAlignment` - Orientation
- `transform: simd_float4x4` - Position and rotation
- `vertices: [SIMD3<Float>]` - Mesh vertices
- `faceIndices: [UInt32]` - Triangle indices

### PlaneClassification

Enum representing different surface types:
- `unknown`
- `wall`
- `floor`
- `ceiling`
- `table`
- `seat`
- `window`
- `door`

### PlaneAlignment

Enum representing plane orientations:
- `horizontal`
- `vertical`
- `unknown`

## Requirements

- iOS 26.0+
- visionOS 26.0+
- macOS 26.0+
- Swift 6.2+
- Xcode 16.0+

## License

See LICENSE.txt for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
