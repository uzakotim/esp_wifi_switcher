import Foundation
import Network

final class UDPConnectionManager {
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "udp.connection.manager.queue")

    init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
    }

    func start() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if self.connection != nil { return }
            let params = NWParameters.udp
            let connection = NWConnection(host: self.host, port: self.port, using: params)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("UDP connection ready to \(self.host):\(self.port)")
                case .failed(let error):
                    print("UDP connection failed: \(error)")
                case .cancelled:
                    print("UDP connection cancelled")
                default:
                    break
                }
            }
            self.connection = connection
            connection.start(queue: self.queue)
        }
    }

    func send(_ data: Data, completion: ((Error?) -> Void)? = nil) {
        start()
        queue.async { [weak self] in
            guard let self = self, let connection = self.connection else {
                completion?(NSError(domain: "UDPConnectionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection not available"]))
                return
            }
            connection.send(content: data, completion: .contentProcessed { error in
                completion?(error)
            })
        }
    }

    func sendString(_ string: String, using encoding: String.Encoding = .utf8, completion: ((Error?) -> Void)? = nil) {
        if let data = string.data(using: encoding) {
            send(data, completion: completion)
        } else {
            completion?(NSError(domain: "UDPConnectionManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode string"]))
        }
    }

    func receiveString(completion: @escaping (String?, Error?) -> Void) {
        queue.async { [weak self] in
            guard let self = self, let connection = self.connection else {
                completion(nil, NSError(domain: "UDPConnectionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection not available"]))
                return
            }
            connection.receiveMessage { data, context, isComplete, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    completion(string, nil)
                } else {
                    completion(nil, NSError(domain: "UDPConnectionManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid data received"]))
                }
            }
        }
    }

    func cancel() {
        queue.async { [weak self] in
            self?.connection?.cancel()
            self?.connection = nil
        }
    }
}
