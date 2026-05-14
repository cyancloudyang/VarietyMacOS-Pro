//
//  DetailViewGeometry.swift
//  VarietyMacOS
//
//  Shared geometry state for detail view positioning
//

import SwiftUI
import Foundation

final class DetailViewGeometry: ObservableObject {
    static let shared = DetailViewGeometry()
    
    @Published var frame: CGRect = .zero
    @Published var isPresented: Bool = false
}
