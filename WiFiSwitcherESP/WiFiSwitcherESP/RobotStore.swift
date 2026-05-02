import Foundation
import Combine
import SwiftUI

struct RobotDetails: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var avatar: String
    var ip: String
    var macAddress: String
    var mode: String
}

@MainActor
final class RobotStore: ObservableObject {
    @Published var robots: [RobotDetails] = [] {
        didSet {
            saveRobots()
        }
    }
    
    private let saveKey = "SavedRobotDetails"
    
    init() {
        loadRobots()
    }
    
    private func loadRobots() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([RobotDetails].self, from: data) {
                self.robots = decoded
                return
            }
        }
        self.robots = []
    }
    
    private func saveRobots() {
        if let encoded = try? JSONEncoder().encode(robots) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // Helper to add or update a robot (using MAC address as a unique hardware identifier)
    func addOrUpdateRobot(_ robot: RobotDetails) {
        if let index = robots.firstIndex(where: { $0.macAddress == robot.macAddress }) {
            // Preserve the original UUID to avoid UI glitches with Identifiable
            var updatedRobot = robot
            updatedRobot.id = robots[index].id
            robots[index] = updatedRobot
        } else {
            robots.append(robot)
        }
    }
    
    // Helper to remove by IndexSet (useful for SwiftUI ForEach onDelete)
    func removeRobot(at offsets: IndexSet) {
        robots.remove(atOffsets: offsets)
    }
    
    // Helper to delete a specific robot
    func deleteRobot(_ robot: RobotDetails) {
        robots.removeAll { $0.id == robot.id }
    }
}
