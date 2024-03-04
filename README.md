# RealityKit helper functions for visionOS

In the spirit of collaboration and knowledge sharing, I've decided to open source a selection of helper functions that I've developed during my journey of creating the first visionOS experience using RealityKit.

## Outline Mesh Generation
<img width="1242" alt="Screenshot 2023-11-11 at 19 18 44" src="https://github.com/gonchar/GoncharKit/assets/1416917/888af853-779a-414f-8914-d069563cec99">

## DoubleSided materials
<img width="1078" alt="Screenshot 2023-11-11 at 19 53 00" src="https://github.com/gonchar/GoncharKit/assets/1416917/1768bc36-6d73-4400-a970-8e957ec86dca">

## Skeleton Visualization
```
yourEntity?.visualizeBones()
```
<img width="1310" alt="Screenshot 2023-11-16 at 23 23 18" src="https://github.com/gonchar/GoncharKit/assets/1416917/05949eed-b649-4372-abc9-993577cbae9f">


# All extension functions for RealityKit Entity
* `visualizeBones(size: Float = 0.5)`
  * Visualizes the bones of a model entity by creating a debug entity with a cone mesh representing each bone.
  
* `createEntityBox(_ color: UIColor, size: Float) -> Entity`
  * Creates a box-shaped entity with the specified color and size.
  
* `update(shaderGraphMaterial oldMaterial: ShaderGraphMaterial, _ handler: (inout ShaderGraphMaterial) throws -> Void) rethrows`
  * Updates the shader graph material of the entity by applying the changes defined in the handler closure.
  
* `replaceAndStoreOldMaterials(material: Material, copyPBRInputs: Bool = false)`
  * Replaces the current materials of the entity with a new material and optionally copies the inputs from the physically based rendering (PBR) materials.
  
* `restoreOriginalMaterials()`
  * Restores the original materials of the entity that were saved before replacement.
  
* `saveMaterialParam(paramName: String)`
  * Saves the parameter value of the shader graph material with the given name.
  
* `getMaterialParam(paramName: String) -> MaterialParameters.Value?`
  * Retrieves the value of the material parameter with the given name.
  
* `setMaterialParamWeight(paramName: String, value: Float)`
  * Sets the weight of the material parameter with the given name, multiplying it by the saved value if it exists.
  
* `setMaterialParam(paramName: String, value: MaterialParameters.Value)`
  * Sets the value of the material parameter with the given name.
  
* `playAllAnimations(shouldLoop: Bool = false)`
  * Plays all available animations for the entity, with an option to loop them indefinitely.
  
* `distance(from other: Entity) -> Float`
  * Calculates the distance between the entity and another entity.
  
* `distance(from point: SIMD3<Float>) -> Float`
  * Calculates the distance between the entity and a point in 3D space.
  
* `isDistanceWithinThreshold(from other: Entity, max: Float) -> Bool`
  * Checks if the distance between the entity and another entity is within a specified threshold.
  
* `isDistanceWithinThreshold(from point: SIMD3<Float>, max: Float) -> Bool`
  * Checks if the distance between the entity and a point in 3D space is within a specified threshold.
  
* `findParentWithName(_ findName: String) -> Entity?`
  * Searches for a parent entity with the specified name.
  
* `findParentWithAnyComponents(withComponents componentClasses: [Component.Type]) -> Entity?`
  * Searches for a parent entity that has any of the specified components.
  
* `findParentWithComponent<T: Component>(withComponent componentClass: T.Type) -> Entity?`
  * Searches for a parent entity that has the specified component type.
  
* `findFirstComponent<T: Component>(withComponent componentClass: T.Type) -> T?`
  * Searches for the first component of the specified type in the entity hierarchy.
  
* `hasComponentInHierarchy<T: Component>(withComponent componentClass: T.Type) -> Bool`
  * Checks if any entity in the hierarchy has the specified component type.
  
* `forEachDescendant<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void)`
  * Iterates over all descendants with the specified component type and performs the given closure.
  
* `forEach<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void)`
  * Iterates over the entity and its children with the specified component type and performs the given closure.
  
* `removeComponentFromHierarchy(componentType: Component.Type)`
  * Removes the specified component type from the entity and its descendants.
  
* `fixObjectPivot() -> Entity?`
  * Fixes the pivot of the entity by creating a new entity at the visual center and re-parenting the original entity to it.
  
* `generateCollisionsForEnabledOnly()`
  * Generates collision shapes for the entity and its children if they are enabled.
  
* `generatePreciseCollisionsForEachEnabled<T: Component>(withComponent componentClass: T.Type) async`
  * Asynchronously generates precise collision shapes for each enabled entity with the specified component type.
  
* `generatePreciseCollisionShapes() async`
  * Asynchronously generates precise collision shapes for the entity if it is enabled.
  
* `stopEmittingParticleEmitters()`
  * Stops all particle emitters from emitting particles in the entity hierarchy.
  
* `removeAllParticleEmitters()`
  * Removes all particle emitter components from the entity hierarchy.
  
* `playAllParticles()`
  * Starts emitting particles for all particle emitters in the entity hierarchy.
  
* `addMeshOutline(outlineMaterial: RealityKit.Material, offset: Float)`
  * Adds an outline to the mesh of the entity using the specified material and offset.
  
* `makeMeshResourcesUnique()`
  * Makes the mesh resources of the entity unique to avoid sharing them with other entities.
  
* `addDoubleSide()`
  * Adds double-sided rendering to the entity's mesh.
  
* `addDoubleSide(otherSideMaterial: RealityKit.Material, ignoreComponentTypes: [Component.Type]?)`
  * Adds double-sided rendering to the entity's mesh with the specified material for the other side, ignoring entities with specified component types.
  

