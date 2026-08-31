//
//  Workout.swift
//  GymApp1
//
//  Created by Cathal Davitt on 12/08/2026.
//
import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var name: String
    var exerciseNames: [String]

    init(name: String, exerciseNames: [String] = []) {
        self.name = name
        self.exerciseNames = exerciseNames
    }
}

@Model
final class WorkoutLog {
    var date: Date
    var name: String
    var exercises: [ExerciseLog]

    init(date: Date = .now, name: String, exercises: [ExerciseLog] = []) {
        self.date = date
        self.name = name
        self.exercises = exercises
    }
}

@Model
final class ExerciseLog {
    var name: String
    var sets: [SetLog]

    init(name: String, sets: [SetLog] = []) {
        self.name = name
        self.sets = sets
    }
}

@Model
final class SetLog {
    var reps: Int
    var weight: Double

    init(reps: Int, weight: Double) {
        self.reps = reps
        self.weight = weight
    }
}
