import Foundation
import CocoaMQTT
import UIKit

struct LoSASMessageItem: Identifiable, Codable, Equatable {
    let id: UUID
    let topic: String
    let message: String
    let timestamp: Date

    init(id: UUID = UUID(), topic: String, message: String, timestamp: Date = Date()) {
        self.id = id
        self.topic = topic
        self.message = message
        self.timestamp = timestamp
    }

    static func == (lhs: LoSASMessageItem, rhs: LoSASMessageItem) -> Bool {
        lhs.id == rhs.id
    }
}

class MQTTManager: NSObject, ObservableObject {
    @Published var messages: [LoSASMessageItem] = []
    @Published var isConnected: Bool = false

    private var mqtt: CocoaMQTT?
    private let messagesFileName = "mqtt_messages.json"

    override init() {
        super.init()

        loadMessages()

        let clientID = "iOSClient-\(UUID().uuidString)"
        mqtt = CocoaMQTT(clientID: clientID, host: "192.168.1.79", port: 1883)
        mqtt?.delegate = self
        mqtt?.cleanSession = false

        // Auto-connect on app start
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.connect()
        }

        // Reconnect when returning from background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleAppWillEnterForeground() {
        print("🚀 App returned to foreground — ensuring MQTT connection.")
        connect()
    }

    func connect() {
        guard let mqtt = mqtt else { return }

        if mqtt.connState == .connected || mqtt.connState == .connecting {
            print("⚠️ Already connected or connecting.")
            return
        }

        print("🔌 Connecting to \(mqtt.host):\(mqtt.port)")
        mqtt.connect()
    }

    // MARK: - Storage

    private func getMessagesFileURL() -> URL {
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDir.appendingPathComponent(messagesFileName)
    }

    private func saveMessages() {
        let url = getMessagesFileURL()
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: url)
        } catch {
            print("❌ Failed to save messages: \(error.localizedDescription)")
        }
    }

    private func loadMessages() {
        let url = getMessagesFileURL()
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([LoSASMessageItem].self, from: data)
            self.messages = decoded
            print("📂 Loaded \(decoded.count) messages from storage.")
        } catch {
            print("⚠️ No previous messages found or failed to load.")
            self.messages = []
        }
    }

    private func reconnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            print("🔁 Reconnecting...")
            self.connect()
        }
    }
}

// MARK: - CocoaMQTTDelegate
extension MQTTManager: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("✅ Connected to \(host):\(port)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("✅ Connection acknowledged with \(ack)")
        DispatchQueue.main.async { self.isConnected = true }
        mqtt.subscribe("test/hello")
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        print("🔄 MQTT state changed to: \(state)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        let msg = message.string ?? ""
        let topic = message.topic
        print("📩 [\(topic)] \(msg)")

        let item = LoSASMessageItem(topic: topic, message: msg, timestamp: Date())

        DispatchQueue.main.async {
            self.messages.append(item)
            self.saveMessages()
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("📌 Subscribed successfully: \(success)")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: (any Error)?) {
        print("❌ Disconnected: \(err?.localizedDescription ?? "no error")")
        DispatchQueue.main.async { self.isConnected = false }
        reconnect()
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("📤 Published message \(message.string ?? "") to \(message.topic)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}
    func mqttDidPing(_ mqtt: CocoaMQTT) {}
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}
}

//import Foundation
//import CocoaMQTT
//import Combine
//
//struct LoSASMessageItem: Identifiable, Equatable, Codable {
//    let id = UUID()
//    let topic: String
//    let message: String
//    let timestamp: Date
//
//    static func == (lhs: LoSASMessageItem, rhs: LoSASMessageItem) -> Bool {
//        lhs.id == rhs.id
//    }
//}
//
//class MQTTManager: NSObject, ObservableObject {
//    @Published var messages: [LoSASMessageItem] = []
//    @Published var isConnected: Bool = false
//    private var mqtt: CocoaMQTT?
//    private let serverURL = "http://192.168.1.79:5000/messages" // Flask server
//
//    override init() {
//        super.init()
//
//        let clientID = "iOSClient-\(UUID().uuidString)"
//        mqtt = CocoaMQTT(clientID: clientID, host: "192.168.1.79", port: 1883)
//        mqtt?.keepAlive = 60
//        mqtt?.cleanSession = true
//        mqtt?.autoReconnect = true
//        mqtt?.delegate = self
//
//        // Auto-connect and restore messages
//        connect()
//        fetchSavedMessages()
//    }
//
//    func connect() {
//        guard let mqtt = mqtt else { return }
//
//        if mqtt.connState == .connected || mqtt.connState == .connecting {
//            print("⚠️ Already connected or connecting — skipping connect()")
//            return
//        }
//
//        print("🔌 Connecting to \(mqtt.host):\(mqtt.port)...")
//        mqtt.connect()
//    }
//
//    private func fetchSavedMessages() {
//        guard let url = URL(string: serverURL) else { return }
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            guard let data = data, error == nil else {
//                print("❌ Error fetching messages: \(error?.localizedDescription ?? "unknown")")
//                return
//            }
//
//            do {
//                let decoded = try JSONDecoder().decode([LoSASMessageItem].self, from: data)
//                DispatchQueue.main.async {
//                    self.messages = decoded
//                }
//            } catch {
//                print("❌ JSON decode error: \(error)")
//            }
//        }.resume()
//    }
//
//    private func saveMessageToServer(_ item: LoSASMessageItem) {
//        guard let url = URL(string: serverURL) else { return }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        do {
//            request.httpBody = try JSONEncoder().encode(item)
//        } catch {
//            print("❌ Failed to encode message: \(error)")
//            return
//        }
//
//        URLSession.shared.dataTask(with: request).resume()
//    }
//
//    func reconnect() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            print("🔁 Attempting reconnection...")
//            self.mqtt?.connect()
//        }
//    }
//}
//
//// MARK: - CocoaMQTTDelegate
//extension MQTTManager: CocoaMQTTDelegate {
//    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
//        print("✅ Connected to MQTT broker.")
//        mqtt.subscribe("test/hello")
//    }
//
//    // ✅ Some versions include 'retained' argument, others do not.
//    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
//        handleIncomingMessage(message)
//    }
//
//    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16, retained: Bool) {
//        handleIncomingMessage(message)
//    }
//
//    private func handleIncomingMessage(_ message: CocoaMQTTMessage) {
//        let msg = message.string ?? ""
//        let topic = message.topic
//        print("📩 [\(topic)] \(msg)")
//
//        let item = LoSASMessageItem(topic: topic, message: msg, timestamp: Date())
//        DispatchQueue.main.async {
//            self.messages.append(item)
//        }
//
//        saveMessageToServer(item)
//    }
//
//    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics topics: NSDictionary, failed: [String]) {
//        print("📡 Subscribed to topics: \(topics)")
//    }
//
//    // ✅ Safe version-agnostic disconnect handler
//    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
//        print("❌ Disconnected: \(err?.localizedDescription ?? "no error")")
//        reconnect()
//    }
//
//    // Optional methods
//    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {}
//    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {}
//    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {}
//    func mqttDidPing(_ mqtt: CocoaMQTT) {}
//    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {}
//}
