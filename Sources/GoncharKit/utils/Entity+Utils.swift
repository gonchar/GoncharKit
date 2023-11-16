//
//  Entity+Utils.swift
//
//  Created by Sergey Gonchar on 02/10/2023.
//

import RealityKit
import UIKit

extension Entity {
  func visualizeBones(size: Float = 0.5) {
    var bonesDebug:Entity? = parent?.findEntity(named: "bonesDebug")
    if bonesDebug == nil {
      bonesDebug = Entity()
      bonesDebug!.name = "bonesDebug"
      parent?.addChild(bonesDebug!)
    }
    
    var modelEntities:[ModelEntity] = []
    
    forEach(withComponent: ModelComponent.self) { entity, component in
      if component.mesh.contents.skeletons.count > 0 {
        if let modelEntity = entity as? ModelEntity {
          modelEntities.append(modelEntity)
        }
      }
    }
    
    for modelEntity in modelEntities {
      
      modelEntity.components.set(OpacityComponent(opacity: 0.5))
      //create full map first
      var jointsDict:[String:Transform] = [:]
      for i in 0 ..< modelEntity.jointNames.count {
        let jointName = modelEntity.jointNames[i]
        let jointTrm = modelEntity.jointTransforms[i]
        jointsDict[jointName] = jointTrm
      }
      
      //
      for i in 0 ..< modelEntity.jointNames.count {
        let jointName = modelEntity.jointNames[i]
        let allowedEntityName = jointName.replacing("/", with: "_")
        let pathComponents = jointName.split(separator: "/")
        
        var boneDebug = bonesDebug?.findEntity(named: allowedEntityName)
        if boneDebug == nil {
          boneDebug = Entity()
          boneDebug?.name = allowedEntityName
          bonesDebug?.addChild(boneDebug!)
          
          let mesh = ModelEntity(mesh: .generateCone(height: size, radius: size / 3.0), materials: [SimpleMaterial(color: .purple, isMetallic: true)])
          mesh.transform.translation = .init(x: 0.0, y: size / 2.0, z: 0.0)
          boneDebug?.addChild(mesh)
        }
        
        var combinedMatrix:float4x4 = .init(1.0)
        
        for i in (0 ..< pathComponents.count).reversed() {
          let sampleJointName = (0 ... i).map { pathComponents[$0] }.joined(separator: "/")
          combinedMatrix = jointsDict[sampleJointName]!.matrix * combinedMatrix
        }
        
        let combinedTrm = Transform(matrix: combinedMatrix)
        boneDebug?.transform = modelEntity.convert(transform: combinedTrm, to: bonesDebug)
      }
    }
  }
  
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

