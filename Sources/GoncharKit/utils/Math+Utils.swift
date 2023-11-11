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
}

