import Foundation
import Combine

struct DiscoveredDevice: Identifiable, Hashable {
    let id = UUID()
    let ip: String
    let mac: String
    let mode: String
    let port: String
}

@MainActor
final class SearchManager: ObservableObject {
    @Published var foundDevices: [DiscoveredDevice] = []
    @Published var isSearching: Bool = false
    
    private var activeManagers: [UDPConnectionManager] = []
    
    func search(port: UInt16 = 8080) {
        guard !isSearching else { return }
        isSearching = true
        foundDevices.removeAll()
        
        // Clean up any lingering managers just in case
        for manager in activeManagers {
            manager.cancel()
        }
        activeManagers.removeAll()
        
        for i in 2...254 {
            let ip = "192.168.1.\(i)"
            let manager = UDPConnectionManager(host: ip, port: port)
            activeManagers.append(manager)
            
            manager.start()
            manager.sendString("app:get:status") { error in
                if error == nil {
                    manager.receiveString { [weak self] string, _ in
                        // Only process valid responses (ignores echoed "app:get:status" packets)
                        if let string = string, string.contains("MAC:") {
                            DispatchQueue.main.async {
                                let device = Self.parseStatus(string, ip: ip)
                                // Avoid adding duplicates
                                if !(self?.foundDevices.contains(where: { $0.ip == ip }) ?? true) {
                                    self?.foundDevices.append(device)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // End the search after 1.5 seconds and clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            for manager in self.activeManagers {
                manager.cancel()
            }
            self.activeManagers.removeAll()
            self.isSearching = false
        }
    }
    
    func searchSpecificIP(_ ip: String, port: UInt16 = 8080) {
        guard !isSearching else { return }
        isSearching = true
        foundDevices.removeAll()
        
        for manager in activeManagers {
            manager.cancel()
        }
        activeManagers.removeAll()
        
        let manager = UDPConnectionManager(host: ip, port: port)
        activeManagers.append(manager)
        
        manager.start()
        manager.sendString("app:get:status") { error in
            if error == nil {
                manager.receiveString { [weak self] string, _ in
                    if let string = string, string.contains("MAC:") {
                        DispatchQueue.main.async {
                            let device = Self.parseStatus(string, ip: ip)
                            if !(self?.foundDevices.contains(where: { $0.ip == ip }) ?? true) {
                                self?.foundDevices.append(device)
                            }
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            for manager in self.activeManagers {
                manager.cancel()
            }
            self.activeManagers.removeAll()
            self.isSearching = false
        }
    }
    
    private nonisolated static func parseStatus(_ message: String, ip: String) -> DiscoveredDevice {
        var mac = ""
        var mode = ""
        var port = ""
        
        let components = message.components(separatedBy: " | ")
        for component in components {
            if component.hasPrefix("MAC:") {
                mac = String(component.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            } else if component.hasPrefix("Port:") {
                port = String(component.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if component.hasPrefix("Mode:") {
                mode = String(component.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        return DiscoveredDevice(ip: ip, mac: mac, mode: mode, port: port)
    }
}

