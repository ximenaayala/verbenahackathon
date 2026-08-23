import SwiftUI

private let brandGreen = Color(red: 0.11, green: 0.62, blue: 0.46)
private let brandGreenSoft = Color(red: 0.88, green: 0.96, blue: 0.93)
private let brandAmberSoft = Color(red: 0.98, green: 0.93, blue: 0.85)
private let brandAmberInk = Color(red: 0.52, green: 0.31, blue: 0.04)

struct ContentView: View {
    @EnvironmentObject private var store: LoopStore
    @StateObject private var reader = NFCReader()
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    pointsCard
                    statsRow
                    impactCard
                    if let message = store.statusMessage ?? reader.errorMessage {
                        noticeBanner(message)
                    }
                    scanButton
                    if !store.events.isEmpty { historySection }
                }
                .padding(20)
            }
            .navigationTitle("Hola, \(store.userName)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reiniciar", systemImage: "arrow.counterclockwise") { store.reset() }
                        .labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $showResult) { ScanResultView() }
        }
    }

    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tus puntos")
                .font(.footnote)
                .foregroundStyle(brandGreen)
            Text("\(store.points)")
                .font(.system(size: 38, weight: .medium, design: .rounded))
            Text(tierCaption)
                .font(.footnote)
                .foregroundStyle(brandGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(brandGreenSoft, in: RoundedRectangle(cornerRadius: 14))
    }

    private var tierCaption: String {
        if let remaining = store.pointsToNextTier {
            return "Nivel \(store.tier.rawValue) · \(remaining) para el siguiente"
        }
        return "Nivel \(store.tier.rawValue) · nivel máximo"
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(label: "Racha", value: "\(store.streakDays) días")
            statTile(label: "Devueltos", value: "\(store.totalReturns)")
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var impactCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tu impacto").font(.caption).foregroundStyle(.secondary)
            Label(String(format: "%.1f kg CO₂ evitados", store.co2SavedKg), systemImage: "leaf")
                .font(.subheadline)
            Label("\(store.totalReturns) envases fuera del vertedero", systemImage: "arrow.3.trianglepath")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func noticeBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(brandAmberInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(brandAmberSoft, in: RoundedRectangle(cornerRadius: 10))
    }

    private var scanButton: some View {
        Button {
            reader.beginScan { assetID in
                store.registerReturn(assetID: assetID)
                if store.statusMessage == nil { showResult = true }
            }
        } label: {
            Label(reader.isScanning ? "Buscando etiqueta…" : "Devolver envase",
                  systemImage: "wave.3.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.primary)
        .disabled(reader.isScanning || !reader.isAvailable)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Devoluciones de hoy")
                .font(.subheadline.weight(.medium))
            ForEach(store.events) { event in
                HStack {
                    Text(event.assetID).font(.callout.monospaced())
                    Spacer()
                    Text("+\(event.pointsAwarded + event.bonusAwarded)")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(brandGreen)
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

struct ScanResultView: View {
    @EnvironmentObject private var store: LoopStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(brandGreen)
                .padding(.top, 36)

            VStack(spacing: 4) {
                Text("Devolución registrada").font(.title3.weight(.medium))
                if let event = store.lastEvent {
                    Text(event.assetID)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 10) {
                row("Depósito devuelto", String(format: "€%.2f", store.depositRefunded))
                row("Puntos ganados", "+\(store.lastEvent?.pointsAwarded ?? 0)")
                row("Bonus de racha", "+\(store.lastEvent?.bonusAwarded ?? 0)", highlight: true)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Label("Racha de \(store.streakDays) días", systemImage: "flame")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(brandAmberInk)
                Text("Sigue así para mantener el bonus")
                    .font(.footnote)
                    .foregroundStyle(brandAmberInk.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(brandAmberSoft, in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            Button("Listo") { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(.primary)
        }
        .padding(20)
        .presentationDetents([.medium, .large])
    }

    private func row(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(highlight ? brandGreen : .primary)
        }
    }
}

#Preview {
    ContentView().environmentObject(LoopStore())
}
