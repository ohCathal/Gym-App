//
//  Progress.swift
//  GymApp1
//
//  Created by Cathal Davitt on 12/08/2026.
//
import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date
    var weight: Double

    init(date: Date = .now, weight: Double) {
        self.date = date
        self.weight = weight
    }
}

@Model
final class ProgressPhoto {
    var date: Date
    @Attribute(.externalStorage) var imageData: Data

    init(date: Date = .now, imageData: Data) {
        self.date = date
        self.imageData = imageData
    }
}
