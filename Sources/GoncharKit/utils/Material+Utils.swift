//
//  Material+Utils.swift
//
//  Created by Sergey Gonchar on 19/10/2023.
//

import Foundation
import RealityKit

extension PhysicallyBasedMaterial {
  public func copyParametersExceptBaseColorTo(_ target: inout PhysicallyBasedMaterial) {
    target.roughness = self.roughness
    target.metallic = self.metallic
    target.emissiveColor = self.emissiveColor
    target.emissiveIntensity = self.emissiveIntensity
    target.normal = self.normal
    target.ambientOcclusion = self.ambientOcclusion
    target.blending = self.blending
  }
  
  public func copyOpacity(_ target: inout PhysicallyBasedMaterial) {
    target.blending = self.blending
  }
}
