//
//  ContentView.swift
//  WiFiSwitcherESP
//
//  Created by Timur Uzakov on 4/30/26.
//

import SwiftUI

struct ContentView: View {
    @State private var statusMessage: String = ""
    @State private var ipAddress: String = "172.21.21.21"
    @State private var portString: String = "8080"
    @State private var gatewayAddress: String = "172.21.21.1"
    @State private var boardMode: String = "local"
    @State private var externalSSID: String = ""
    @State private var externalPassword: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("WiFi Switcher")
                .font(.title)

            HStack(spacing: 12) {
                VStack{
                    Text("IP Address")
                    TextField("IP Address", text: $ipAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(.roundedBorder)
                }
               
                VStack{
                    Text("Port")
                    TextField("Port", text: $portString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.numberPad)
                        .frame(width: 90)
                        .textFieldStyle(.roundedBorder)
                }
              
                
               
            }
          
            VStack(spacing: 12) {
                Text("Gateway")
                TextField("Gateway", text: $gatewayAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
            VStack{
                Text("SSID")
                TextField("SSID", text: $externalSSID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
            }
            VStack{
                Text("Password")
                TextField("Password", text: $externalPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                
            }
           
            Button {
                // TODO
                if boardMode == "local" {
                    // set to external
                    boardMode = "external"
                    statusMessage = "Set mode to external"
                }
                else{
                    // set to local
                    gatewayAddress="172.21.21.1"
                    ipAddress = "172.21.21.21"
                    portString = "8080"
                    boardMode = "local"
                    statusMessage = "Set mode to local wifi"
                }
            }
            label: {
                Label(boardMode == "local" ? "Switch to External" : "Switch to Local", systemImage: boardMode == "local" ? "wifi.router.fill" : "wifi")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.glass)
            .tint(Color.blue)
            Button {
                // TODO
            }
            label: {
                Label("Upload Settings", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.glass)
            .tint(Color.blue)
            Button {
                guard let port = UInt16(portString) else {
                    statusMessage = "Invalid port"
                    return
                }
                statusMessage = "Sending reboot command..."
                let manager = UDPConnectionManager(host: ipAddress, port: port)
                manager.sendString("app:reboot") { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            statusMessage = "Failed to send: \(error.localizedDescription)"
                        } else {
                            statusMessage = "Reboot command sent to \(ipAddress):\(port)"
                        }
                    }
                }
            } label: {
                Label("Reboot", systemImage: "power")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
            }
            .tint(.red)
            .buttonStyle(.glass)
            .disabled(ipAddress.isEmpty || portString.isEmpty)

            Text(statusMessage)
                .foregroundStyle(.secondary)
        }
        .padding(30)
    }
}

#Preview {
    ContentView()
}
