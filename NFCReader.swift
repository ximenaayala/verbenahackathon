import Foundation
import CoreNFC

/// Lee etiquetas NDEF y devuelve el identificador del activo escrito en ellas.
@MainActor
final class NFCReader: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var errorMessage: String?

    private var session: NFCNDEFReaderSession?
    private var onRead: ((String) -> Void)?

    var isAvailable: Bool { NFCNDEFReaderSession.readingAvailable }

    func beginScan(onRead: @escaping (String) -> Void) {
        guard isAvailable else {
            errorMessage = "Este dispositivo no puede leer etiquetas NFC."
            return
        }

        self.onRead = onRead
        errorMessage = nil
        isScanning = true

        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session.alertMessage = "Acerca el envase a la parte superior del teléfono"
        session.begin()
        self.session = session
    }

    func cancel() {
        session?.invalidate()
        session = nil
        isScanning = false
    }

    /// Extrae texto de un payload NDEF, soportando registros de texto y de URI.
    fileprivate static func decode(_ payload: NFCNDEFPayload) -> String? {
        if let (text, _) = payload.wellKnownTypeTextPayload() {
            return text
        }
        if let url = payload.wellKnownTypeURIPayload() {
            // Soporta tags escritos como http://host/scan?id=VRD-4471-ES
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let id = components?.queryItems?.first(where: { $0.name == "id" })?.value {
                return id
            }
            return url.absoluteString
        }
        return String(data: payload.payload, encoding: .utf8)
    }
}

extension NFCReader: NFCNDEFReaderSessionDelegate {

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let identifier = messages
            .flatMap { $0.records }
            .compactMap { NFCReader.decode($0) }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        Task { @MainActor in
            self.isScanning = false
            if let identifier {
                session.alertMessage = "Envase \(identifier) registrado"
                self.onRead?(identifier)
            } else {
                session.alertMessage = "Etiqueta vacía"
                self.errorMessage = "La etiqueta no contiene datos legibles."
            }
        }
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.isScanning = false
            self.session = nil

            let nfcError = error as? NFCReaderError
            switch nfcError?.code {
            case .readerSessionInvalidationErrorUserCanceled,
                 .readerSessionInvalidationErrorFirstNDEFTagRead:
                self.errorMessage = nil
            default:
                self.errorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}
}
