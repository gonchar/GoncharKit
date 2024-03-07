//
//  File.swift
//
//
//  Created by Sergey Gonchar on 10/11/2023.
//

import Foundation

import RealityKit

extension SIMD3 where Scalar == Float {
  func distance(from other: SIMD3<Float>) -> Float {
    return simd_distance(self, other)
  }
  
  var printed: String {
    String(format: "(%.8f, %.8f, %.8f)", x, y, z)
  }
  
  static let x: Self = .init(1, 0, 0)
  static let up: Self = .init(0, 1, 0)
  static let z: Self = .init(0, 0, 1)
  
}

// from Apple samples

extension simd_float4x4 {
  init(translation vector: SIMD3<Float>) {
    self.init(SIMD4<Float>(1, 0, 0, 0),
              SIMD4<Float>(0, 1, 0, 0),
              SIMD4<Float>(0, 0, 1, 0),
              SIMD4<Float>(vector.x, vector.y, vector.z, 1))
  }
  
  var translation: SIMD3<Float> {
    get {
      columns.3.xyz
    }
    set {
      self.columns.3 = [newValue.x, newValue.y, newValue.z, 1]
    }
  }
  
  var rotation: simd_quatf {
    simd_quatf(rotationMatrix)
  }
  
  var xAxis: SIMD3<Float> { columns.0.xyz }
  
  var yAxis: SIMD3<Float> { columns.1.xyz }
  
  var zAxis: SIMD3<Float> { columns.2.xyz }
  
  var rotationMatrix: simd_float3x3 {
    matrix_float3x3(xAxis,
                    yAxis,
                    zAxis)
  }
  
  /// Get a gravity-aligned copy of this 4x4 matrix.
  var gravityAligned: simd_float4x4 {
    // Project the z-axis onto the horizontal plane and normalize to length 1.
    let projectedZAxis: SIMD3<Float> = [zAxis.x, 0.0, zAxis.z]
    let normalizedZAxis = normalize(projectedZAxis)
    
    // Hardcode y-axis to point upward.
    let gravityAlignedYAxis: SIMD3<Float> = [0, 1, 0]
    
    let resultingXAxis = normalize(cross(gravityAlignedYAxis, normalizedZAxis))
    
    return simd_matrix(
      SIMD4(resultingXAxis.x, resultingXAxis.y, resultingXAxis.z, 0),
      SIMD4(gravityAlignedYAxis.x, gravityAlignedYAxis.y, gravityAlignedYAxis.z, 0),
      SIMD4(normalizedZAxis.x, normalizedZAxis.y, normalizedZAxis.z, 0),
      columns.3
    )
  }
  
  /// Pre-multiplies a 3-vector by a 4x4 matrix.
  static func * (matrix: simd_float4x4, vector: SIMD3<Float>) -> SIMD3<Float> {
    let result = matrix*SIMD4<Float>(vector, 1)
    return SIMD3<Float>(result.x, result.y, result.z)
  }
}

extension SIMD4 {
  var xyz: SIMD3<Scalar> {
    self[SIMD3(0, 1, 2)]
  }
}

extension SIMD2<Float> {
  /// Checks whether this point is inside a given triangle defined by three vertices.
  func isInsideOf(_ vertex1: SIMD2<Float>, _ vertex2: SIMD2<Float>, _ vertex3: SIMD2<Float>) -> Bool {
    // This point lies within the triangle given by v1, v2 & v3 if its barycentric coordinates are in range [0, 1].
    let coords = barycentricCoordinatesInTriangle(vertex1, vertex2, vertex3)
    return coords.x >= 0 && coords.x <= 1 && coords.y >= 0 && coords.y <= 1 && coords.z >= 0 && coords.z <= 1
  }
  
  /// Computes the barycentric coordinates of this point relative to a given triangle defined by three vertices.
  func barycentricCoordinatesInTriangle(_ vertex1: SIMD2<Float>, _ vertex2: SIMD2<Float>, _ vertex3: SIMD2<Float>) -> SIMD3<Float> {
    // Compute vectors between the vertices.
    let v2FromV1 = vertex2 - vertex1
    let v3FromV1 = vertex3 - vertex1
    let selfFromV1 = self - vertex1
    
    // Compute the area of:
    // 1. the passed in triangle,
    // 2. triangle "u" (v1, v3, self) &
    // 3. triangle "v" (v1, v2, self).
    // Note: The area of a triangle is the length of the cross product of the two vectors that span the triangle.
    let areaOverallTriangle = cross(v2FromV1, v3FromV1).z
    let areaU = cross(selfFromV1, v3FromV1).z
    let areaV = cross(v2FromV1, selfFromV1).z
    
    // The barycentric coordinates of point self are vertices v1, v2 & v3 weighted by (u, v, w).
    // Compute these weights by dividing the triangle’s areas by the overall area.
    let u = areaU / areaOverallTriangle
    let v = areaV / areaOverallTriangle
    let w = 1.0 - v - u
    return SIMD3<Float>(u, v, w)
  }
}

extension SIMD2 where Scalar == Float {
  func distance(from other: Self) -> Float {
    return simd_distance(self, other)
  }
  
  var length: Float { return distance(from: .init()) }
}

extension BoundingBox {
  var volume: Float { extents.x * extents.y * extents.z }
}
