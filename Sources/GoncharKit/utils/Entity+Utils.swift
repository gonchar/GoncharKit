//
//  Entity+Utils.swift
//
//  Created by Sergey Gonchar on 02/10/2023.
//

import RealityKit
import UIKit


extension Entity {
  
  public static func getVisualise(_ name: String, color: UIColor, parent:Entity? = nil, scene:RealityKit.Scene? = nil) -> Entity? {
    var whereToLook:Entity? = parent
    
    if whereToLook == nil {
      whereToLook = scene?.findEntity(named: "appRoot")
    }
    
    if let any = whereToLook?.findEntity(named: name) {
      return any
    }
    let vis = Entity.createEntityBox(color, size: 0.02)
    vis.name = name
    whereToLook?.addChild(vis)
    return vis
  }
  
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
  
  public static func createEntityBox(_ color: UIColor, size: Float) -> Entity {
    let model = ModelComponent(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: color, isMetallic: true)])
    let result = Entity()
    result.components.set(model)
    return result
  }
  
  public var modelComponent: ModelComponent? {
    components[ModelComponent.self]
  }
  
  public var shaderGraphMaterial: ShaderGraphMaterial? {
    modelComponent?.materials.first as? ShaderGraphMaterial
  }
  
  public var physicallyBasedMaterial: PhysicallyBasedMaterial? {
    modelComponent?.materials.first as? PhysicallyBasedMaterial
  }
  
  public func update(shaderGraphMaterial oldMaterial: ShaderGraphMaterial,
              _ handler: (inout ShaderGraphMaterial) throws -> Void) rethrows {
    var material = oldMaterial
    try handler(&material)
    
    if var component = modelComponent {
      component.materials = [material]
      components.set(component)
    }
  }
  
  public func replaceAndStoreOldMaterials(material: Material, copyPBRInputs: Bool = false) {
    if var modelComponent = modelComponent {
      let count = modelComponent.materials.count
      
      var saveMaterialComponent = SaveOriginalMaterialComponent()
      saveMaterialComponent.originalMaterials = modelComponent.materials
      components.set(saveMaterialComponent)
      
      var mats:[RealityKit.Material] = []
      for i in 0..<count {
        // this is quite custom logic, disabled by default
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
  
  public func restoreOriginalMaterials() {
    if var modelComponent = modelComponent {
      if let savedMats = components[SaveOriginalMaterialComponent.self] {
        for i in 0 ..< savedMats.originalMaterials.count {
          modelComponent.materials[i] = savedMats.originalMaterials[i]
        }
        components.set(modelComponent)
        components.remove(SaveOriginalMaterialComponent.self)
      }
    }
    
    for child in children {
      child.restoreOriginalMaterials()
    }
  }
  
  public func saveMaterialParam(paramName:String) {
    guard isEnabled && isEnabledInHierarchy else { return }
    if let modelComponent = modelComponent {
      for i in 0 ..< modelComponent.materials.count {
        if let shaderGraph = modelComponent.materials[i] as? ShaderGraphMaterial,
           shaderGraph.parameterNames.contains(paramName),
           let value = shaderGraph.getParameter(name: paramName)
        {
          components.set(SavedMaterialParamComponent(name: paramName, originalValue: value))
        }
      }
    }
    
    for child in children {
      child.saveMaterialParam(paramName: paramName)
    }
  }
  
  public func getMaterialParam(paramName:String) -> MaterialParameters.Value? {
    guard isEnabled && isEnabledInHierarchy else { return nil }
    if let modelComponent = modelComponent {
      for i in 0 ..< modelComponent.materials.count {
        if let shaderGraph = modelComponent.materials[i] as? ShaderGraphMaterial,
           shaderGraph.parameterNames.contains(paramName),
           let value = shaderGraph.getParameter(name: paramName)
//           case let MaterialParameters.Value.float(paramValue) = value
        {
          return value
        }
      }
    }
    
    for child in children {
      return child.getMaterialParam(paramName: paramName)
    }
    return nil
  }
  
  public func setMaterialParamWeight(paramName:String, value: Float) {
    guard isEnabled && isEnabledInHierarchy else { return }
    if var modelComponent = modelComponent {
      for i in 0 ..< modelComponent.materials.count {
        if var shaderGraph = modelComponent.materials[i] as? ShaderGraphMaterial,
           shaderGraph.parameterNames.contains(paramName)
        {
          if let savedValue = components[SavedMaterialParamComponent.self],
             savedValue.name == paramName {
            
            if case let MaterialParameters.Value.float(savedFloat) = savedValue.originalValue {
              try? shaderGraph.setParameter(name: paramName, value: .float(value * savedFloat))
            } else {
              print("🛑 GoncharKit: Implementation mission for material value type \(savedValue.originalValue)")
            }
            
          } else {
            try? shaderGraph.setParameter(name: paramName, value: .float(value))
          }
          modelComponent.materials[i] = shaderGraph
        }
      }
      components.set(modelComponent)
    }
    for child in children {
      child.setMaterialParamWeight(paramName: paramName, value: value)
    }
  }
  
  
  public func setMaterialParam(paramName:String, value: MaterialParameters.Value) {
    guard isEnabled && isEnabledInHierarchy else { return }
    if var modelComponent = modelComponent {
      for i in 0 ..< modelComponent.materials.count {
        if var shaderGraph = modelComponent.materials[i] as? ShaderGraphMaterial,
           shaderGraph.parameterNames.contains(paramName)
        {
          try? shaderGraph.setParameter(name: paramName, value: value)
          modelComponent.materials[i] = shaderGraph
        }
      }
      components.set(modelComponent)
    }
    for child in children {
      child.setMaterialParam(paramName: paramName, value: value)
    }
  }
}

extension Entity {
  public func playAllAnimations(shouldLoop: Bool = false) {
    for anim in availableAnimations {
      if shouldLoop {
        let newAnim = anim.repeat(duration: .infinity)
        playAnimation(newAnim, transitionDuration: 0.1)
      } else {
        playAnimation(anim, transitionDuration: 0.1)
      }
    }
  }
}

extension Entity {
  public func distance(from other: Entity) -> Float {
    transform.translation.distance(from: other.transform.translation)
  }
  
  public func distance(from point: SIMD3<Float>) -> Float {
    transform.translation.distance(from: point)
  }
  
  public func isDistanceWithinThreshold(from other: Entity, max: Float) -> Bool {
    isDistanceWithinThreshold(from: transform.translation, max: max)
  }
  
  public func isDistanceWithinThreshold(from point: SIMD3<Float>, max: Float) -> Bool {
    transform.translation.distance(from: point) < max
  }
}

extension Entity {
  public func findParentWithName(_ findName: String) -> Entity? {
    if name == findName {
      return self
    }
    
    if let parent = parent {
      return parent.findParentWithName(findName)
    }
    
    return nil
  }
  
  public func findParentWithAnyComponents(withComponents componentClasses: [Component.Type]) -> Entity? {
    for componentClass in componentClasses {
      if components.has(componentClass) {
        return self
      }
    }
    
    if let parent = parent {
      return parent.findParentWithAnyComponents(withComponents: componentClasses)
    }
    
    return nil
  }
  
  public func findParentWithComponent<T: Component>(withComponent componentClass: T.Type) -> Entity? {
    if components.has(componentClass) {
      return self
    }
    
    if let parent = parent {
      return parent.findParentWithComponent(withComponent: componentClass)
    }
    
    return nil
  }
  
  public func findFirstComponent<T: Component>(withComponent componentClass: T.Type) -> T? {
    if let component = self.components[componentClass] {
      return component
    }
    
    for child in children {
      if let success = child.findFirstComponent(withComponent: componentClass) {
        return success
      }
    }
    
    return nil
  }
  
  public func hasComponentInHierarchy<T: Component>(withComponent componentClass: T.Type) -> Bool {
    if self.components.has(componentClass) {
      return true
    }
    
    for child in children {
      if child.hasComponentInHierarchy(withComponent: componentClass) {
        return true
      }
    }
    
    return false
  }
  
  /// Recursive search of children looking for any descendants with a specific component and calling a closure with them.
  public func forEachDescendant<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
    for child in children {
      if let component = child.components[componentClass] {
        closure(child, component)
      }
      child.forEachDescendant(withComponent: componentClass, closure)
    }
  }
  
  public func forEach<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
    if let component = self.components[componentClass] {
      closure(self, component)
    }
    
    for child in children {
      child.forEach(withComponent: componentClass, closure)
    }
  }
  
  public func removeComponentFromHierarchy(componentType: Component.Type) {
    if components.has(componentType) {
      components.remove(componentType)
    }
    
    for child in children {
      child.removeComponentFromHierarchy(componentType: componentType)
    }
  }
  
  public func fixObjectPivot() -> Entity? {
    if let parent = parent {
      let bounds = visualBounds(relativeTo: parent)
      let newEntity = Entity()
      newEntity.transform.translation = bounds.center
      parent.addChild(newEntity)
      
      let newTrm = parent.convert(transform: transform, to: newEntity)
      newEntity.addChild(self)
      transform = newTrm
      
      return newEntity
    }
    return nil
  }
}


extension Entity {
  
  public func generateCollisionsForEnabledOnly() {
    guard isEnabled && isEnabledInHierarchy else { return }
    if components.has(ModelComponent.self) {
      components.remove(CollisionComponent.self)
      generateCollisionShapes(recursive: false, static: true)
    }
    
    for child in children {
      child.generateCollisionsForEnabledOnly()
    }
  }
  
  public func generatePreciseCollisionsForEachEnabled<T: Component>(withComponent componentClass: T.Type) async {
    guard isEnabled && isEnabledInHierarchy else { return }
    
    if self.components.has(componentClass)
    {
      await generatePreciseCollisionShapes()
    }
    
    for child in children {
      await child.generatePreciseCollisionsForEachEnabled(withComponent: componentClass)
    }
  }
  
  public func generatePreciseCollisionShapes() async {
    guard isEnabled && isEnabledInHierarchy else { return }
    if let mc = components[ModelComponent.self] {
      var shapes:[ShapeResource] = []
      for model in mc.mesh.contents.models {
        var positions:[SIMD3<Float>] = []
        var indices:[UInt16] = []
        for part in model.parts {
          positions += part.positions.elements
          indices += part.triangleIndices!.elements.map { UInt16($0) }
        }
        //todo: support bones
        let newShape = try! await ShapeResource.generateStaticMesh(positions: positions, faceIndices: indices)
        shapes.append(newShape)
      }
      components.set(CollisionComponent(shapes: shapes))
    }
    
    for child in children {
      await child.generatePreciseCollisionShapes()
    }
  }
  
  public func generateConvexCollisionShapes() async {
    guard isEnabled && isEnabledInHierarchy else { return }
    if let mc = components[ModelComponent.self] {
      var shapes:[ShapeResource] = []
      for model in mc.mesh.contents.models {
        var positions:[SIMD3<Float>] = []
        for part in model.parts {
          positions += part.positions.elements
        }
        //todo: support bones
        let newShape = try! await ShapeResource.generateConvex(from: positions)
        shapes.append(newShape)
      }
      components.set(CollisionComponent(shapes: shapes))
    }
    
    for child in children {
      await child.generateConvexCollisionShapes()
    }
  }
}

extension Entity {
  func stopEmittingParticleEmitters() {
    forEachDescendant(withComponent: ParticleEmitterComponent.self) { ent, _ in
      ent.components[ParticleEmitterComponent.self]?.isEmitting = false
    }
  }
  
  public func removeAllParticleEmitters() {
    removeComponentFromHierarchy(componentType: ParticleEmitterComponent.self)
  }
  
  public func playAllParticles() {
    forEach(withComponent: ParticleEmitterComponent.self) { ent, _ in
      ent.components[ParticleEmitterComponent.self]?.isEmitting = true
      ent.components[ParticleEmitterComponent.self]?.restart()
    }
  }
}

extension Entity {
  
  public func addMeshOutline(outlineMaterial: RealityKit.Material, offset: Float) {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      guard entity.isEnabled && entity.isEnabledInHierarchy else { return }
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
      guard entity.isEnabled && entity.isEnabledInHierarchy else { return }
      var newMC = modelComponent;
      newMC.makeMeshResourceUnique()
      entity.components.set(newMC)
    }
  }
  
  public func addDoubleSide() {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      guard entity.isEnabled && entity.isEnabledInHierarchy else { return }
      if let newMC = modelComponent.generetaDoubleSided(otherSideMaterial: nil) {
        entity.components.set(newMC)
      }
    }
  }
  
  public func addDoubleSide(otherSideMaterial: RealityKit.Material, ignoreComponentTypes: [Component.Type]?) {
    self.forEach(withComponent: ModelComponent.self) { entity, modelComponent in
      guard entity.isEnabled && entity.isEnabledInHierarchy else { return }
      
      if let ignoreComponentTypes = ignoreComponentTypes {
        for i in 0 ..< ignoreComponentTypes.count {
          if entity.components.has(ignoreComponentTypes[i].self) {
            return;
          }
        }
      }
      
      if let newMC = modelComponent.generetaDoubleSided(otherSideMaterial: otherSideMaterial) {
        entity.components.set(newMC)
      }
    }
  }
}
