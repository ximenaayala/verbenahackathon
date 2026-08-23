import Foundation
import Combine

// Cambia esto por la IP que imprime server.py al arrancar.
let serverBaseURL = "http://192.168.1.42:8080"

// Puntos base por devolución y bonus por mantener la racha.
private let pointsPerReturn = 25
private let streakBonus = 10
private let depositAmount = 0.15

// Factores de impacto por envase devuelto (supuestos declarados en el reporte).
private let co2SavedPerReturn = 0.142   // kg CO2e evitados
private let goldThreshold = 1500
private let silverThreshold = 500

struct ReturnEvent: Identifiable, Codable {
    let id: UUID
    let assetID: String
    let timestamp: Date
    let pointsAwarded: Int
    let bonusAwarded: Int

    init(assetID: String, pointsAwarded: Int, bonusAwarded: Int) {
        self.id = UUID()
        self.assetID = assetID
        self.timestamp = Date()
        self.pointsAwarded = pointsAwarded
        self.bonusAwarded = bonusAwarded
    }
}

enum Tier: String {
    case bronce = "Bronce"
    case plata = "Plata"
    case oro = "Oro"

    static func from(points: Int) -> Tier {
        if points >= goldThreshold { return .oro }
        if points >= silverThreshold { return .plata }
        return .bronce
    }
}

@MainActor
final class LoopStore: ObservableObject {
    @Published var userName = "Ana"
    @Published var points = 1_240
    @Published var streakDays = 14
    @Published var totalReturns = 87
    @Published var events: [ReturnEvent] = []

    @Published var lastEvent: ReturnEvent?
    @Published var statusMessage: String?
    @Published var isSending = false

    var tier: Tier { Tier.from(points: points) }

    var pointsToNextTier: Int? {
        switch tier {
        case .bronce: return silverThreshold - points
        case .plata: return goldThreshold - points
        case .oro: return nil
        }
    }

    var co2SavedKg: Double { Double(totalReturns) * co2SavedPerReturn }

    var depositRefunded: Double { depositAmount }

    /// Registra una devolución leída por NFC: actualiza el estado local y avisa al dashboard.
    func registerReturn(assetID: String) {
        let trimmed = assetID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "La etiqueta no contiene un identificador válido."
            return
        }

        guard !events.contains(where: { $0.assetID == trimmed }) else {
            statusMessage = "Este envase ya se registró en esta sesión."
            return
        }

        let bonus = streakDays > 0 ? streakBonus : 0
        let event = ReturnEvent(assetID: trimmed, pointsAwarded: pointsPerReturn, bonusAwarded: bonus)

        points += pointsPerReturn + bonus
        totalReturns += 1
        streakDays += 1
        events.insert(event, at: 0)
        lastEvent = event
        statusMessage = nil

        Task { await push(event: event) }
    }

    /// Envía el evento al servidor puente que alimenta el dashboard proyectado.
    private func push(event: ReturnEvent) async {
        guard let url = URL(string: "\(serverBaseURL)/event") else { return }

        let payload: [String: Any] = [
            "asset_id": event.assetID,
            "user": userName,
            "points": event.pointsAwarded + event.bonusAwarded,
            "deposit": depositAmount,
            "channel": "b2c_app",
            "co2_saved_kg": co2SavedPerReturn
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 5

        isSending = true
        defer { isSending = false }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                statusMessage = "El dashboard respondió \(http.statusCode)."
            }
        } catch {
            // La demo no debe romperse si el laptop no está accesible.
            statusMessage = "Registrado en el teléfono. Dashboard sin conexión."
        }
    }

    func reset() {
        points = 1_240
        streakDays = 14
        totalReturns = 87
        events.removeAll()
        lastEvent = nil
        statusMessage = nil
    }
}
