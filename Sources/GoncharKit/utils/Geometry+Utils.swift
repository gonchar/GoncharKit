import Foundation
import RealityKit
import ARKit

extension GeometrySource {
  public func asArray<T>(ofType: T.Type) -> [T] {
    assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
    return (0..<count).map {
      buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
    }
  }
  
  public func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
    asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
  }
  
  public subscript(_ index: Int32) -> (Float, Float, Float) {
    precondition(format == .float3, "This subscript operator can only be used on GeometrySource instances with format .float3")
    return buffer.contents().advanced(by: offset + (stride * Int(index))).assumingMemoryBound(to: (Float, Float, Float).self).pointee
  }
}

extension GeometryElement {
  public subscript(_ index: Int) -> [Int32] {
    precondition(bytesPerIndex == MemoryLayout<Int32>.size,
                     """
This subscript operator can only be used on GeometryElement instances with bytesPerIndex == \(MemoryLayout<Int32>.size).
This GeometryElement has bytesPerIndex == \(bytesPerIndex)
"""
    )
    var data = [Int32]()
    data.reserveCapacity(primitive.indexCount)
    for indexOffset in 0 ..< primitive.indexCount {
      data.append(buffer
        .contents()
        .advanced(by: (Int(index) * primitive.indexCount + indexOffset) * MemoryLayout<Int32>.size)
        .assumingMemoryBound(to: Int32.self).pointee)
    }
    return data
  }
  
  public func asInt32Array() -> [Int32] {
    var data = [Int32]()
    let totalNumberOfInt32 = count * primitive.indexCount
    data.reserveCapacity(totalNumberOfInt32)
    for indexOffset in 0 ..< totalNumberOfInt32 {
      data.append(buffer.contents().advanced(by: indexOffset * MemoryLayout<Int32>.size).assumingMemoryBound(to: Int32.self).pointee)
    }
    return data
  }
  
  public func asUInt16Array() -> [UInt16] {
    asInt32Array().map { UInt16($0) }
  }
  
  public func asUInt32Array() -> [UInt32] {
    asInt32Array().map { UInt32($0) }
  }
}

extension MeshResource.Contents {
  public init(planeGeometry: PlaneAnchor.Geometry) {
    self.init()
    self.instances = [MeshResource.Instance(id: "main", model: "model")]
    var part = MeshResource.Part(id: "part", materialIndex: 0)
    part.positions = MeshBuffers.Positions(planeGeometry.meshVertices.asSIMD3(ofType: Float.self))
    part.triangleIndices = MeshBuffer(planeGeometry.meshFaces.asUInt32Array())
    self.models = [MeshResource.Model(id: "model", parts: [part])]
  }
}
