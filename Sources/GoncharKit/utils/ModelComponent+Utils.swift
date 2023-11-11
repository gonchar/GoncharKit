//
//  ModelComponent+Utils.swift
//  loonavision
//
//  Created by Sergey Gonchar on 19/10/2023.
//

import Foundation
import RealityKit


extension Entity {
  
  public func addMeshOutline(outlineMaterial: RealityKit.Material, offset: Float) {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      if entity.components[IgnoreOutlineGenerationComponent.self] != nil {
        return;
      }
      if let newMC = modelComponent.generateOutlineMeshParts(outlineMaterial: outlineMaterial, offset: offset) {
        entity.components.set(newMC)
      }
    }
  }
  
  public func makeMeshResourcesUnique() {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      var newMC = modelComponent;
      newMC.makeMeshResourceUnique()
      entity.components.set(newMC)
    }
  }
  
  public func addDoubleSide() {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      if let newMC = modelComponent.generetaDoubleSided(otherSideMaterial: nil) {
        entity.components.set(newMC)
      }
    }
  }
  
  public func addDoubleSide(otherSideMaterial: RealityKit.Material) {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      if let newMC = modelComponent.generetaDoubleSided(otherSideMaterial: otherSideMaterial) {
        entity.components.set(newMC)
      }
    }
  }
}

extension ModelComponent {
  
  public mutating func makeMeshResourceUnique() {
    do {
      self.mesh = try MeshResource.generate(from: mesh.contents)
    }
    catch {
      print("⚠️ GoncharKit::makeMeshResourceUnique. Can't generate new mesh")
    }
  }
  
  public func generetaDoubleSided(otherSideMaterial: RealityKit.Material?) -> ModelComponent? {
    var newModelComponent = self
    
    var newMaterials = self.materials;
    
    if let otherSideMaterial = otherSideMaterial {
      newMaterials.append(otherSideMaterial)
    }
    
    var newContents = newModelComponent.mesh.contents;
    
    //duplicate models
    
    for (_, contentModel) in newContents.models.enumerated() {
      var parts:[MeshResource.Part] = []
      for (_, part) in contentModel.parts.enumerated() {
        var newPart = part
        newPart.id = part.id + "_other_side"
        
        if otherSideMaterial == nil {
          //copy material to original side
          newPart.materialIndex = part.materialIndex
        } else {
          newPart.materialIndex = newMaterials.count - 1
        }
        
        if let reversedTriangleIndices = part.triangleIndices?.elements.reversed() {
          newPart.triangleIndices = MeshBuffer(reversedTriangleIndices)
        }
        
        parts.append(newPart)
      }
      
      var newContentModel:MeshResource.Model = contentModel;
      newContentModel.id = contentModel.id + "_other_side"
      parts.forEach { part in
        newContentModel.parts.insert(part)
      }
      
      newContents.models.insert(newContentModel)
    }
    
    //create instances
    
    for (_, contentInstance) in newContents.instances.enumerated() {
      var newInstance = contentInstance
      newInstance.id = contentInstance.id + "_other_side"
      newInstance.model = contentInstance.model + "_other_side"
      newContents.instances.insert(newInstance)
    }
    
    
    do {
      try newModelComponent.mesh.replace(with: newContents)
    } catch {
      print("⚠️ GoncharKit::generetaDoubleSided. Error replacing mesh: \(error)")
    }
    
    newModelComponent.materials = newMaterials
    
    return newModelComponent
  }
  
  public func generateOutlineMeshParts(outlineMaterial: RealityKit.Material, offset: Float) -> ModelComponent?  {
    var newModelComponent = self
    var newMaterials = self.materials;
    newMaterials.append(outlineMaterial)
    let outlineMaterialIndex = newMaterials.count - 1
    
    newMaterials.append(OcclusionMaterial())
    let occluderMaterialIndex = newMaterials.count - 1
    
    newModelComponent.materials = newMaterials
    
    var newContents = newModelComponent.mesh.contents;
    
    //duplicate models
    for (_, contentModel) in newContents.models.enumerated() {
      var parts:[MeshResource.Part] = []
      for (_, part) in contentModel.parts.enumerated() {
        var newPart = part
        newPart.id = part.id + "_outline"
        
        guard let normals = part.normals else {
          print("⚠️ GoncharKit::generateOutlineMeshParts. No normals for outline")
          return nil
        }
        
        let newNormals = normals.enumerated().map { index, normal in
          var newNormal = normal
          newNormal.x = -newNormal.x
          newNormal.y = -newNormal.y
          newNormal.z = -newNormal.z
          return newNormal
        }
        newPart.normals = MeshBuffer(newNormals)
        
        let normalsElements = normals.elements
        let newPositions = part.positions.enumerated().map { index, position in
          let normal = normalsElements[index];
          return position + normal * offset
        }
        newPart.positions = MeshBuffer(newPositions)
        newPart.materialIndex = outlineMaterialIndex
        guard let triangleIndices = newPart.triangleIndices else {
          print("⚠️ GoncharKit::generateOutlineMeshParts. No triangle indices")
          return nil
        }
        newPart.triangleIndices = MeshBuffer(triangleIndices.reversed())
        parts.append(newPart)
      }
      
      //OCCLUDER
      for (_, part) in contentModel.parts.enumerated() {
        var newPart = part
        newPart.id = part.id + "_outline_occluder"
        
        guard let normals = part.normals else {
          print("⚠️ GoncharKit::generateOutlineMeshParts. No normals for occluder")
          return nil
        }
        
        let newNormals = normals.enumerated().map { index, normal in
          return normal
        }
        newPart.normals = MeshBuffer(newNormals)
        
        let normalsElements = normals.elements
        let newPositions = part.positions.enumerated().map { index, position in
          let normal = normalsElements[index];
          return position - normal * (offset * 0.1)
        }
        newPart.positions = MeshBuffer(newPositions)
        newPart.materialIndex = occluderMaterialIndex
        guard let triangleIndices = newPart.triangleIndices else {
          print("⚠️ GoncharKit::generateOutlineMeshParts. No triangle indices")
          return nil
        }
        parts.append(newPart)
      }
      
      
      var newContentModel:MeshResource.Model = contentModel;
      newContentModel.id = contentModel.id + "_outline"
      newContentModel.parts.removeAll()
      parts.forEach { part in
        newContentModel.parts.insert(part)
      }
      
      newContents.models.insert(newContentModel)
    }
    
    //create instances
    for (_, contentInstance) in newContents.instances.enumerated() {
      var newInstance = contentInstance
      newInstance.id = contentInstance.id + "_outline"
      newInstance.model = contentInstance.model + "_outline"
      newContents.instances.insert(newInstance)
    }
    
    do {
      try newModelComponent.mesh.replace(with: newContents)
    } catch {
      print("⚠️ GoncharKit::generateOutlineMeshParts. Error replacing mesh: \(error)")
    }
  
    return newModelComponent
  }
  
}
