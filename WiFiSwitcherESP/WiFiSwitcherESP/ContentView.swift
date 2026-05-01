//
//  ContentView.swift
//  WiFiSwitcherESP
//
//  Created by Timur Uzakov on 4/30/26.
//

import SwiftUI

struct ContentView: View {
    @State private var statusMessage: String = ""
    @State private var ipAddress: String = "192.168.1.100"
    @State private var portString: String = "8080"
    @State private var gatewayAddress: String = "192.168.1.1"
    @State private var boardMode: String = "local"
    @State private var externalSSID: String = ""
    @State private var externalPassword: String = ""
    @State private var manager: UDPConnectionManager?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("WiFi Switcher")
                .font(.title)
            
            ScrollView(.vertical){
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
                        .textFieldStyle(.roundedBorder)
                    
                }
                VStack{
                    Text("Password")
                    SecureField("Password", text: $externalPassword)
                        
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(.roundedBorder)
                    
                }
            }
            
            VStack{
                HStack{
                    VStack{ Text("Mode")
                            .font(.caption)
                            .frame(width: 60, height: 20)
                        
                        Button {
                            guard let port = UInt16(portString) else {
                                statusMessage = "Invalid port"
                                return
                            }
                            if externalSSID.isEmpty || externalPassword.isEmpty {
                                statusMessage = "SSID and password required"
                                return
                            }
                            statusMessage = "Sending mode change..."
                            
                            // Ensure manager is initialized with current settings
                            if manager == nil{
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            
                            
                            if boardMode == "local" {
                                // set to external
                                boardMode = "external"
                                
                                manager?.sendString("app:mode:1") { error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            statusMessage = "Failed to send: \(error.localizedDescription)"
                                        } else {
                                            statusMessage = "Set mode to external \(ipAddress):\(port)"
                                        }
                                    }
                                }
                               
                                
                            }
                            else{
                                boardMode = "local"
                                
                                manager?.sendString("app:mode:0") { error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            statusMessage = "Failed to send: \(error.localizedDescription)"
                                        } else {
                                            statusMessage = "Set mode to local wifi \(ipAddress):\(port)"
                                        }
                                    }
                                }
                                statusMessage = "Set mode to local wifi"
                            }
                        }
                        label: {
                            Image(systemName:boardMode == "local" ?  "wifi": "wifi.router.fill")
                                .font(.headline)
                                .padding()
                                .frame(width: 50,height: 50)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.blue)
                    }
                    VStack{ Text("Upload")
                            .font(.caption)
                            .frame(width: 60, height: 20)
                        
                        Button {
                            guard let port = UInt16(portString) else {
                                statusMessage = "Invalid port"
                                return
                            }
                            if ipAddress.isEmpty || portString.isEmpty || gatewayAddress.isEmpty || externalSSID.isEmpty || externalPassword.isEmpty {
                                statusMessage = "Please fill in all fields"
                                return
                            }
                            statusMessage = "Uploading configurations..."
                            
                            // Ensure manager is initialized with current settings
                            if manager == nil{
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            else {
                                manager?.cancel()
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            // mode
                            
                            manager?.sendString(boardMode=="local" ? "app:mode:0" : "app:mode:1") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = boardMode=="local" ? "Set mode to local..." : "Set mode to external..."
                                    }
                                }
                            }
                            // ssid
                            
                            manager?.sendString("app:set:ssid:\(externalSSID)") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = "Set SSID..."
                                    }
                                }
                            }
                            
                            // password
                            
                            manager?.sendString("app:set:pass:\(externalPassword)") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = "Set password..."
                                    }
                                }
                            }
                            
                            // ip
                            
                            manager?.sendString("app:set:ip:\(ipAddress)") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = "Set IP..."
                                    }
                                }
                            }
                            
                            // port
                            
                            manager?.sendString("app:set:port:\(portString)") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = "Set port..."
                                    }
                                }
                            }
                            
                            // gateway
                            
                            manager?.sendString("app:set:gw:\(gatewayAddress)") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = "Set gateway..."
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                statusMessage = "All set and uploaded. Please reboot."
                            }
                        }
                        label: {
                            Image(systemName:"square.and.arrow.up")
                                .font(.headline)
                                .padding()
                                .frame(width: 50,height: 50)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.blue)
                    }
                    VStack{ Text("Reload")
                                .font(.caption)
                                .frame(width: 60, height: 20)
                            Button {
                            guard let port = UInt16(portString) else {
                                statusMessage = "Invalid port"
                                return
                            }
                            statusMessage = "Reloading connection..."
                            
                            // Ensure manager is initialized with current settings
                            if manager == nil{
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            else {
                                manager?.cancel()
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            statusMessage = "Reloaded connection"
                            
                        } label: {
                            Image(systemName: "arrow.2.circlepath.circle")
                                .font(.headline)
                                .padding()
                                .frame(width: 50,height: 50)
                        }
                        .tint(.green)
                        .buttonStyle(.glass)
                        .disabled(ipAddress.isEmpty || portString.isEmpty)
                    }
                    VStack{ Text("Reboot")
                            .font(.caption)
                            .frame(width: 60, height: 20)
                        Button {
                            
                            guard let port = UInt16(portString) else {
                                statusMessage = "Invalid port"
                                return
                            }
                            statusMessage = "Sending reboot command..."
                            
                            // Ensure manager is initialized with current settings
                            if manager == nil{
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            
                            manager?.sendString("app:reboot") { error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        statusMessage = "Failed to send: \(error.localizedDescription)"
                                    } else {
                                        statusMessage = "Reboot command sent to \(ipAddress):\(port)"
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "power")
                                .font(.headline)
                                .padding()
                                .frame(width: 50,height: 50)
                        }
                        .tint(.red)
                        .buttonStyle(.glass)
                        .disabled(ipAddress.isEmpty || portString.isEmpty)
                        
                    }
                    VStack{ Text("Feedback")
                            .font(.caption)
                            .frame(width: 60, height: 20)
                        
                        Button {
                            guard let port = UInt16(portString) else {
                                statusMessage = "Invalid port"
                                return
                            }
                            if ipAddress.isEmpty || portString.isEmpty || gatewayAddress.isEmpty  {
                                statusMessage = "Please fill in ip, port, and gateway"
                                return
                            }
                            statusMessage = "Uploading configurations..."
                            
                            // Ensure manager is initialized with current settings
                            if manager == nil{
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            else {
                                manager?.cancel()
                                manager = UDPConnectionManager(host: ipAddress, port: port)
                                manager?.start()
                            }
                            // feedback
                            // listen for incoming UDP
                            DispatchQueue.global(qos: .background).async {
                                while true {
                                    guard let message = manager?.sendString("app:get:status") else {
                                        break
                                    }
                                    DispatchQueue.main.async {
                                        statusMessage = message;
                                    }
                                }
                            }
                            
                        }
                        label: {
                            Image(systemName:"square.and.arrow.down")
                                .font(.headline)
                                .padding()
                                .frame(width: 40,height: 50)
                        }
                        .buttonStyle(.glass)
                        .tint(Color.blue)
                    }
                }
            }
            
            
            Text(statusMessage)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .onAppear {
            if let port = UInt16(portString) {
                manager = UDPConnectionManager(host: ipAddress, port: port)
                manager?.start()
            }
        }
        .onDisappear {
            manager?.cancel()
        }
    }
}

#Preview {
    ContentView()
}
