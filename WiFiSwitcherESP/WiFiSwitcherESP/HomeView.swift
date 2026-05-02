import SwiftUI

struct HomeView: View {
    @StateObject private var store = RobotStore()
    @State private var showingAddRobot = false
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if store.robots.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Robots Found")
                            .font(.headline)
                        Text("Tap the + button to search and add a new robot.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(store.robots) { robot in
                            NavigationLink(destination: ContentView(store: store, robot: robot)) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        Text(robot.avatar)
                                            .font(.system(size: 40))
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                store.deleteRobot(robot)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    
                                    Text(robot.name)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.primary)
                                    
                                    Text(robot.ip)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Robots")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRobot = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRobot) {
                AddRobotView(store: store)
            }
        }
    }
}

#Preview {
    HomeView()
}
