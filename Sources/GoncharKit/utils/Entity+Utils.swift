//
//  Entity+Utils.swift
//
//  Created by Sergey Gonchar on 02/10/2023.
//

import RealityKit
import UIKit

extension Entity {
  static func createEntityBox(_ color: UIColor, size: Float) -> Entity {
    let model = ModelComponent(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: color, isMetallic: true)])
    let result = Entity()
    result.components.set(model)
    return result
  }
  
  var modelComponent: ModelComponent? {
    components[ModelComponent.self]
  }
  
  var shaderGraphMaterial: ShaderGraphMaterial? {
    modelComponent?.materials.first as? ShaderGraphMaterial
  }
  
  var physicallyBasedMaterial: PhysicallyBasedMaterial? {
    modelComponent?.materials.first as? PhysicallyBasedMaterial
  }
  
  func update(shaderGraphMaterial oldMaterial: ShaderGraphMaterial,
              _ handler: (inout ShaderGraphMaterial) throws -> Void) rethrows {
    var material = oldMaterial
    try handler(&material)
    
    if var component = modelComponent {
      component.materials = [material]
      components.set(component)
    }
  }
  
  func replaceAndStoreOldMaterials(material: Material, copyPBRInputs: Bool = true) {
    if var modelComponent = modelComponent {
      let count = modelComponent.materials.count
      
      var saveMaterialComponent = SaveOriginalMaterialComponent()
      saveMaterialComponent.originalMaterials = modelComponent.materials
      components.set(saveMaterialComponent)
      
      var mats:[RealityKit.Material] = []
      for i in 0..<count {
        if copyPBRInputs {
          if var newMaterial = material as? PhysicallyBasedMaterial, let oldMaterial = modelComponent.materials[i] as? PhysicallyBasedMaterial {
            oldMaterial.copyParametersExceptBaseColorTo(&newMaterial)
            mats.append(newMaterial)
          }
        } else {
          mats.append(material)
        }
      }
      modelComponent.materials = mats
      components.set(modelComponent)
    }
    
    children.forEach { child in
      child.replaceAndStoreOldMaterials(material: material)
    }
  }
  
  func restoreOriginalMaterials() {
    if var modelComponent = modelComponent {
      if let savedMats = components[SaveOriginalMaterialComponent.self] {
        for i in 0 ..< savedMats.originalMaterials.count {
          modelComponent.materials[i] = savedMats.originalMaterials[i]
        }
        components.set(modelComponent)
        components.remove(SaveOriginalMaterialComponent.self)
      }
    }
    
    children.forEach { child in
      child.restoreOriginalMaterials()
    }
  }
}

extension Entity {
  func distance(from other: Entity) -> Float {
    transform.translation.distance(from: other.transform.translation)
  }
  
  func distance(from point: SIMD3<Float>) -> Float {
    transform.translation.distance(from: point)
  }
  
  func isDistanceWithinThreshold(from other: Entity, max: Float) -> Bool {
    isDistanceWithinThreshold(from: transform.translation, max: max)
  }
  
  func isDistanceWithinThreshold(from point: SIMD3<Float>, max: Float) -> Bool {
    transform.translation.distance(from: point) < max
  }
}

extension Entity {
  func findParentWithComponent<T: Component>(withComponent componentClass: T.Type) -> Entity? {
    if components.has(componentClass) {
      return self
    }
    
    if let parent = parent {
      return parent.findParentWithComponent(withComponent: componentClass)
    }
    
    return nil
  }
  
  /// Recursive search of children looking for any descendants with a specific component and calling a closure with them.
  func forEachDescendant<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
    for child in children {
      if let component = child.components[componentClass] {
        closure(child, component)
      }
      child.forEachDescendant(withComponent: componentClass, closure)
    }
  }
  
  func forEach<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
    if let component = self.components[componentClass] {
      closure(self, component)
    }
    
    for child in children {
      child.forEach(withComponent: componentClass, closure)
    }
  }
  
  func removeComponentFromHierarchy(componentType: Component.Type) {
    if components.has(componentType) {
      components.remove(componentType)
    }
    
    for child in children {
      child.removeComponentFromHierarchy(componentType: componentType)
    }
  }
}

