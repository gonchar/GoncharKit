//
//  ModelComponent+Utils.swift
//
//  Created by Sergey Gonchar on 19/10/2023.
//

import Foundation
import RealityKit

extension ModelComponent {
  
  public mutating func makeMeshResourceUnique() {
    do {
      var newContents = mesh.contents
      triggerSkeleton(newContents: &newContents)
      self.mesh = try MeshResource.generate(from: mesh.contents)
    }
    catch {
      print("⚠️ GoncharKit::makeMeshResourceUnique. Can't generate new mesh")
    }
  }
  
  private func triggerSkeleton(newContents:inout MeshResource.Contents) {
    guard newContents.skeletons.count > 0 else { return }
    for model in newContents.models {
      var parts = model.parts
      for part in parts {
        
        if let buffer = part[MeshBuffers.jointInfluences] {
          var newPart = part
          newPart.jointInfluences = .init(influences: buffer, influencesPerVertex: buffer.count / newPart.positions.count)
          parts.update(newPart)
        }
      }
      
      var newModel = model
      newModel.parts = parts
      newContents.models.update(newModel)
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
      for (_, oldPart) in contentModel.parts.enumerated() {
        var newPart = oldPart
        newPart.id = oldPart.id + "_other_side"
        
        if otherSideMaterial == nil {
          //copy material to original side
          newPart.materialIndex = oldPart.materialIndex
        } else {
          newPart.materialIndex = newMaterials.count - 1
        }
        
        if let reversedTriangleIndices = oldPart.triangleIndices?.elements.reversed() {
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
    
    // trigger skeleton to fix a bug
    triggerSkeleton(newContents: &newContents)
    
    do {
      newModelComponent.mesh = try MeshResource.generate(from: newContents)
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
        guard newPart.triangleIndices != nil else {
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
    
    // trigger skeleton to fix a bug
    triggerSkeleton(newContents: &newContents)
    
    do {
      newModelComponent.mesh = try MeshResource.generate(from: newContents)
    } catch {
      print("⚠️ GoncharKit::generateOutlineMeshParts. Error replacing mesh: \(error)")
    }
  
    return newModelComponent
  }
  
}
