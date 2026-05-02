import SwiftUI

struct AddRobotView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: RobotStore
    @StateObject private var searchManager = SearchManager()
    
    @State private var selectedDevice: DiscoveredDevice?
    @State private var name: String = ""
    @State private var avatar: String = "🤖" // Default emoji
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Search Network")) {
                    if searchManager.isSearching {
                        HStack {
                            ProgressView()
                            Text("Searching 192.168.1.2-255...")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        }
                    } else {
                        Button("Find Robots") {
                            selectedDevice = nil
                            searchManager.search()
                        }
                    }
                    
                    if !searchManager.foundDevices.isEmpty {
                        ForEach(searchManager.foundDevices) { device in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.ip).font(.headline)
                                    Text("MAC: \(device.mac)").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedDevice?.id == device.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDevice = device
                            }
                        }
                    } else if !searchManager.isSearching && searchManager.foundDevices.isEmpty {
                        Text("No devices found yet.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                if selectedDevice != nil {
                    Section(header: Text("Robot Details")) {
                        TextField("Name", text: $name)
                        TextField("Avatar Emoji", text: $avatar)
                            // Basic check to encourage short string/single emoji
                            .onChange(of: avatar) { newValue in
                                if newValue.count > 1 {
                                    avatar = String(newValue.prefix(1))
                                }
                            }
                    }
                }
            }
            .navigationTitle("Add Robot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let device = selectedDevice, !name.isEmpty {
                            let robot = RobotDetails(
                                name: name,
                                avatar: avatar.isEmpty ? "🤖" : avatar,
                                ip: device.ip,
                                macAddress: device.mac,
                                mode: device.mode
                            )
                            store.addOrUpdateRobot(robot)
                            dismiss()
                        }
                    }
                    .disabled(selectedDevice == nil || name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddRobotView(store: RobotStore())
}
