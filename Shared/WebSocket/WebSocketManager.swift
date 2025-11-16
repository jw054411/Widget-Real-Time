//
//  WebSocketManager.swift
//  MarketWidget
//
//  Manages WebSocket connection for real-time market data
//

import Foundation

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveMarketData(_ data: MarketData)
    func didReceiveError(_ error: Error)
    func didConnect()
    func didDisconnect()
}

class WebSocketManager: NSObject {
    static let shared = WebSocketManager()

    weak var delegate: WebSocketManagerDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectAttempts = 0
    private var isManualDisconnect = false

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        return URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
    }()

    private override init() {
        super.init()
    }

    // MARK: - Connection Management

    func connect() {
        guard webSocketTask == nil else {
            print("⚠️ WebSocket already connected")
            return
        }

        isManualDisconnect = false

        guard let url = URL(string: Config.websocketURL) else {
            print("❌ Invalid WebSocket URL")
            return
        }

        var request = URLRequest(url: url)

        // Add API key to headers if available
        if let apiKey = Config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        print("🔌 Connecting to WebSocket: \(url)")

        // Start receiving messages
        receiveMessage()
    }

    func disconnect() {
        isManualDisconnect = true
        reconnectAttempts = 0

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        print("🔌 Disconnected from WebSocket")
        delegate?.didDisconnect()
    }

    // MARK: - Message Handling

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving messages
                self.receiveMessage()

            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self.handleDisconnection(error: error)
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseMarketData(from: text)

        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMarketData(from: text)
            }

        @unknown default:
            print("⚠️ Unknown message type received")
        }
    }

    private func parseMarketData(from text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Try to parse as WebSocketMessage wrapper first
            if let message = try? decoder.decode(WebSocketMessage.self, from: data),
               let marketData = message.payload {
                handleMarketData(marketData)
                return
            }

            // Try to parse as direct MarketData
            if let marketData = try? decoder.decode(MarketData.self, from: data) {
                handleMarketData(marketData)
                return
            }

            // Try to parse as array of MarketData
            if let marketDataArray = try? decoder.decode([MarketData].self, from: data) {
                marketDataArray.forEach { handleMarketData($0) }
                return
            }

            print("⚠️ Unable to parse market data from: \(text)")

        } catch {
            print("❌ JSON parsing error: \(error)")
            delegate?.didReceiveError(error)
        }
    }

    private func handleMarketData(_ data: MarketData) {
        print("📊 Received market data for \(data.symbol): \(data.formattedPrice)")

        // Notify delegate
        delegate?.didReceiveMarketData(data)

        // Update shared storage
        updateSharedStorage(with: data)
    }

    private func updateSharedStorage(with newData: MarketData) {
        // Load existing data
        var marketDataList = SharedDataStore.shared.loadMarketData() ?? []

        // Update or append new data
        if let index = marketDataList.firstIndex(where: { $0.symbol == newData.symbol }) {
            marketDataList[index] = newData
        } else {
            marketDataList.append(newData)
        }

        // Save back to shared storage
        SharedDataStore.shared.saveMarketData(marketDataList)
    }

    // MARK: - Reconnection Logic

    private func handleDisconnection(error: Error) {
        webSocketTask = nil

        guard !isManualDisconnect else {
            print("🔌 Manual disconnect, not reconnecting")
            return
        }

        delegate?.didDisconnect()

        if reconnectAttempts < Config.maxReconnectAttempts {
            reconnectAttempts += 1
            let delay = Config.reconnectDelay * Double(reconnectAttempts)

            print("🔄 Reconnecting in \(delay)s (attempt \(reconnectAttempts)/\(Config.maxReconnectAttempts))")

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.connect()
            }
        } else {
            print("❌ Max reconnection attempts reached")
            delegate?.didReceiveError(error)
        }
    }

    // MARK: - Sending Messages

    func send(message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)

        webSocketTask?.send(message) { error in
            if let error = error {
                print("❌ WebSocket send error: \(error)")
            } else {
                print("✅ Message sent successfully")
            }
        }
    }

    func sendJSON<T: Encodable>(_ object: T) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(object)

            if let jsonString = String(data: data, encoding: .utf8) {
                send(message: jsonString)
            }
        } catch {
            print("❌ Failed to encode JSON: \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected")
        reconnectAttempts = 0
        delegate?.didConnect()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket closed with code: \(closeCode.rawValue)")

        let error = NSError(domain: "WebSocket", code: closeCode.rawValue, userInfo: [
            NSLocalizedDescriptionKey: "WebSocket closed"
        ])

        handleDisconnection(error: error)
    }
}
