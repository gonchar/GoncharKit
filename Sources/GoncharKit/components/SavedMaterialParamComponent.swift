//
//  SavedMaterialParamComponent.swift
//  
//
//  Created by Sergey Gonchar on 04/03/2024.
//

import RealityKit
import Foundation

public struct SavedMaterialParamComponent: Component {
  var originalValue:MaterialParameters.Value
  var name:String
  
  init(name: String, originalValue: MaterialParameters.Value) {
    self.name = name
    self.originalValue = originalValue
  }
}
