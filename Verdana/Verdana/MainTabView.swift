import SwiftUI
import MapKit

// Paleta de colores inspirada en Bibigo y estándares europeos de sustentabilidad
private let brandGreen = Color(red: 0.08, green: 0.42, blue: 0.28)
private let brandGreenSoft = Color(red: 0.92, green: 0.96, blue: 0.94)
private let brandAmberSoft = Color(red: 0.96, green: 0.94, blue: 0.90)
private let brandAmberInk = Color(red: 0.40, green: 0.32, blue: 0.20)

struct MainTabView: View {
    // Orden lógico: 0: Perfil, 1: Recompensas, 2: E-commerce, 3: Mapa
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: ContentViewTab()
                case 1: RewardsView()
                case 2: EcommerceView()
                default: MapView()
                }
            }

            CustomFloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - 1. PESTAÑA PERFIL (INICIO)
struct ContentViewTab: View {
    @EnvironmentObject private var store: LoopStore
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    pointsCard
                    statsRow
                    impactCard
                    if let message = store.statusMessage {
                        noticeBanner(message)
                    }
                    scanButton
                    if !store.events.isEmpty { historySection }
                }
                .padding(20)
                .padding(.bottom, 70) // Espacio para que la barra flotante no tape elementos
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hola, \(store.userName)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reiniciar", systemImage: "arrow.counterclockwise") { store.reset() }
                        .labelStyle(.iconOnly)
                        .tint(brandGreen)
                }
            }
            .sheet(isPresented: $showResult) { ScanResultView() }
        }
    }

    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tu puntuación")
                    .font(.footnote)
                    .foregroundStyle(brandGreen)
                Spacer()
                Label(store.tier.rawValue, systemImage: "medal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(brandGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(brandGreen.opacity(0.15), in: Capsule())
            }
            Text("\(store.points) pts")
                .font(.system(size: 38, weight: .bold, design: .rounded))
            Text(tierCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var tierCaption: String {
        if let remaining = store.pointsToNextTier {
            return "¡Faltan \(remaining) pts para el siguiente nivel EU!"
        }
        return "¡Nivel máximo alcanzado (PPWR Compliant)!"
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(label: "Racha", value: "\(store.streakDays) días", icon: "flame.fill", iconColor: .orange)
            statTile(label: "Devueltos", value: "\(store.totalReturns)", icon: "shippingbox.fill", iconColor: brandGreen)
        }
    }

    private func statTile(label: String, value: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title3.weight(.bold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var impactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Impacto Planta España (300k u/día)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Label(String(format: "%.1f kg CO₂ evitados", store.co2SavedKg), systemImage: "leaf.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(brandGreen)
            Label("\(store.totalReturns) envases reutilizados en circuito", systemImage: "arrow.3.trianglepath")
                .font(.subheadline.weight(.medium))
            Label(String(format: "€%.2f de ahorro operativo generado", store.savingsEur), systemImage: "eurosign.circle.fill")
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private func noticeBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(brandAmberInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(brandAmberSoft, in: RoundedRectangle(cornerRadius: 12))
    }

    private var scanButton: some View {
        Button {
            let randomID = "VRD-ESP-" + String(Int.random(in: 1000...9999))
            store.registerReturn(assetID: randomID)
            if store.statusMessage == nil { showResult = true }
        } label: {
            Label("Registrar Devolución", systemImage: "wave.3.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(brandGreen)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Devoluciones de hoy")
                .font(.subheadline.weight(.bold))
            ForEach(store.events) { event in
                HStack {
                    Text(event.assetID).font(.callout.monospaced())
                    Spacer()
                    Text("+\(event.pointsAwarded + event.bonusAwarded) pts")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(brandGreen)
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 2. PESTAÑA RECOMPENSAS
struct RewardsView: View {
    @EnvironmentObject private var store: LoopStore
    @State private var selectedLocation = "España · Madrid Hub"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Módulo de Recompensas")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Label(selectedLocation, systemImage: "mappin.and.ellipse")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(brandGreen)
                        }

                        Text("\(store.points) Puntos disponibles")
                            .font(.system(size: 30, weight: .bold))

                        ProgressView(value: store.tierProgress)
                            .tint(brandGreen)

                        Text("Canjea tus puntos por cumplir con la normativa europea PPWR.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Canjes destacados").font(.headline)
                        rewardCard(title: "Zumos & Fruta Fresca Gratis", cost: "350 pts", subtitle: "Canjeable en supermercados asociados B2B", icon: "cup.and.saucer.fill")
                        rewardCard(title: "15% Descuento en Próximo Pedido", cost: "500 pts", subtitle: "Línea ready-to-eat y bebidas VERDANA", icon: "tag.fill")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Puntos de colecta cercanos en España").font(.headline)
                        collectionSpotCard(name: "Hub Logístico Madrid Norte", time: "Hoy, 8:00 AM - 6:00 PM", distance: "1.2 km")
                        collectionSpotCard(name: "Supermercado Partner Valencia", time: "Abierto 24/7 (B2B Automatizado)", distance: "450 m")
                    }
                }
                .padding(20)
                .padding(.bottom, 70)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Recompensas")
        }
    }

    private func rewardCard(title: String, cost: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(brandGreen)
                .frame(width: 50, height: 50)
                .background(brandGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.bold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(cost)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(brandGreen, in: Capsule())
                .foregroundStyle(.white)
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func collectionSpotCard(name: String, time: String, distance: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.subheadline.weight(.bold))
                Text(time).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(distance)
                .font(.caption.weight(.bold))
                .foregroundStyle(brandGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(brandGreen.opacity(0.1), in: Capsule())
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 3. PESTAÑA E-COMMERCE (estilo Rappi / Uber Eats)
private struct VerdanaProduct: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let price: Double
    let icon: String
}

private let verdanaCatalog: [VerdanaProduct] = [
    VerdanaProduct(name: "Ensalada César", subtitle: "Ready-to-eat · 280 g", price: 4.90, icon: "leaf.fill"),
    VerdanaProduct(name: "Wrap de pollo", subtitle: "Ready-to-eat · 220 g", price: 5.50, icon: "takeoutbag.and.cup.and.straw.fill"),
    VerdanaProduct(name: "Jugo de naranja", subtitle: "Bebida · 500 ml", price: 2.30, icon: "cup.and.saucer.fill"),
    VerdanaProduct(name: "Smoothie frutos rojos", subtitle: "Bebida · 400 ml", price: 3.10, icon: "cup.and.saucer.fill"),
    VerdanaProduct(name: "Agua embotellada", subtitle: "Bebida · 600 ml", price: 1.20, icon: "drop.fill"),
    VerdanaProduct(name: "Bebida láctea infantil", subtitle: "Bebida · 200 ml", price: 1.80, icon: "cup.and.saucer.fill")
]

struct EcommerceView: View {
    @EnvironmentObject private var store: LoopStore
    @State private var quantities: [UUID: Int] = [:]
    @State private var showCheckout = false
    @State private var reusablePackaging = true
    @State private var showConfirmation = false

    private var cartCount: Int { quantities.values.reduce(0, +) }

    private var cartTotal: Double {
        verdanaCatalog.reduce(0) { total, product in
            total + Double(quantities[product.id] ?? 0) * product.price
        }
    }

    private var reusableUnits: Int { reusablePackaging ? cartCount : 0 }
    private var depositTotal: Double { Double(reusableUnits) * 0.15 }
    private var pointsPreview: Int { reusableUnits * 25 }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        productsSection
                    }
                    .padding(20)
                    .padding(.bottom, cartCount > 0 ? 130 : 70)
                }
                .background(Color(.systemGroupedBackground))

                if cartCount > 0 { floatingCartBar }
            }
            .navigationTitle("VERDANA Market")
            .sheet(isPresented: $showCheckout) { checkoutSheet }
            .sheet(isPresented: $showConfirmation) {
                OrderConfirmedView(reusableUnits: reusableUnits, deposit: depositTotal, points: pointsPreview)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Entrega en 25-35 min").font(.caption).foregroundStyle(.secondary)
                Text("Hola, \(store.userName) 👋").font(.title3.weight(.bold))
            }
            Spacer()
            Label("\(store.points) pts", systemImage: "star.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(brandGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(brandGreen.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready-to-eat y bebidas").font(.headline)
            ForEach(verdanaCatalog) { product in
                productRow(product)
            }
        }
    }

    private func productRow(_ product: VerdanaProduct) -> some View {
        HStack(spacing: 14) {
            Image(systemName: product.icon)
                .font(.title2)
                .foregroundStyle(brandGreen)
                .frame(width: 52, height: 52)
                .background(brandGreenSoft, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name).font(.subheadline.weight(.semibold))
                Text(product.subtitle).font(.caption).foregroundStyle(.secondary)
                Text(String(format: "€%.2f", product.price)).font(.subheadline.weight(.bold))
            }

            Spacer()

            stepper(for: product)
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private func stepper(for product: VerdanaProduct) -> some View {
        let qty = quantities[product.id] ?? 0
        return Group {
            if qty == 0 {
                Button {
                    quantities[product.id] = 1
                } label: {
                    Text("Agregar")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(brandGreen, in: Capsule())
                        .foregroundStyle(.white)
                }
            } else {
                HStack(spacing: 10) {
                    Button {
                        quantities[product.id] = max(0, qty - 1)
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(brandGreen)
                    }
                    Text("\(qty)").font(.subheadline.weight(.bold)).frame(minWidth: 16)
                    Button {
                        quantities[product.id] = qty + 1
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(brandGreen)
                    }
                }
                .font(.title3)
            }
        }
    }

    private var floatingCartBar: some View {
        Button {
            showCheckout = true
        } label: {
            HStack {
                Image(systemName: "bag.fill")
                Text("\(cartCount) producto\(cartCount == 1 ? "" : "s")")
                Spacer()
                Text(String(format: "€%.2f", cartTotal)).fontWeight(.bold)
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(brandGreen, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)
            .padding(.bottom, 84) // encima de la barra flotante de tabs
        }
    }

    private var checkoutSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tu pedido").font(.headline)
                        ForEach(verdanaCatalog.filter { (quantities[$0.id] ?? 0) > 0 }) { product in
                            HStack {
                                Text("\(quantities[product.id] ?? 0)×").foregroundStyle(.secondary)
                                Text(product.name)
                                Spacer()
                                Text(String(format: "€%.2f", product.price * Double(quantities[product.id] ?? 0)))
                            }
                            .font(.subheadline)
                        }
                        Divider()
                        HStack {
                            Text("Total").font(.subheadline.weight(.bold))
                            Spacer()
                            Text(String(format: "€%.2f", cartTotal)).font(.subheadline.weight(.bold))
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))

                    packagingSection

                    Button {
                        showCheckout = false
                        showConfirmation = true
                        quantities.removeAll()
                    } label: {
                        Text("Confirmar pedido")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Checkout VERDANA")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { showCheckout = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var packagingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Empaque de tu pedido").font(.headline)

            Button {
                reusablePackaging = true
            } label: {
                packagingOption(
                    title: "Empaque reusable EU",
                    subtitle: "Recogida automática en tu siguiente entrega",
                    badge: "Recomendado PPWR",
                    selected: reusablePackaging
                )
            }
            .buttonStyle(.plain)

            Button {
                reusablePackaging = false
            } label: {
                packagingOption(
                    title: "Empaque estándar",
                    subtitle: "Cartón de un solo uso · sin depósito",
                    badge: nil,
                    selected: !reusablePackaging
                )
            }
            .buttonStyle(.plain)

            if reusablePackaging {
                HStack {
                    Text("Depósito reembolsable").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "€%.2f", depositTotal)).font(.subheadline.weight(.bold))
                }
                HStack {
                    Text("Puntos al devolver").font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    Text("+\(pointsPreview) pts").font(.subheadline.weight(.bold)).foregroundStyle(brandGreen)
                }
                HStack(spacing: 10) {
                    Image(systemName: "leaf.fill").foregroundStyle(brandGreen)
                    Text("Evitas **\(String(format: "%.2f", Double(reusableUnits) * 15.87)) kg de CO₂** con esta elección.")
                        .font(.footnote)
                }
                .padding(12)
                .background(brandGreenSoft, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func packagingOption(title: String, subtitle: String, badge: String?, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? brandGreen : .secondary)
                Text(title).font(.subheadline.weight(.semibold))
                if let badge {
                    Spacer()
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(brandGreen.opacity(0.15), in: Capsule())
                        .foregroundStyle(brandGreen)
                }
            }
            Text(subtitle).font(.caption).foregroundStyle(.secondary).padding(.leading, 26)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? brandGreen : Color.clear, lineWidth: 2)
        )
    }
}

private struct OrderConfirmedView: View {
    @Environment(\.dismiss) private var dismiss
    let reusableUnits: Int
    let deposit: Double
    let points: Int

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(brandGreen)
                .padding(.top, 36)

            Text("¡Pedido confirmado!").font(.title3.weight(.bold))
            Text("Tu repartidor VERDANA está en camino").font(.subheadline).foregroundStyle(.secondary)

            if reusableUnits > 0 {
                VStack(spacing: 10) {
                    HStack {
                        Text("Envases reusables").foregroundStyle(.secondary)
                        Spacer()
                        Text("\(reusableUnits)").fontWeight(.bold)
                    }
                    HStack {
                        Text("Depósito a pagar").foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "€%.2f", deposit)).fontWeight(.bold)
                    }
                    HStack {
                        Text("Puntos al devolver").foregroundStyle(.secondary)
                        Spacer()
                        Text("+\(points)").fontWeight(.bold).foregroundStyle(brandGreen)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button("Listo") { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .buttonStyle(.borderedProminent)
                .tint(brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(20)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 4. PESTAÑA MAPA B2B (España / Madrid)
struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038), // Madrid, España
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    Marker("Planta VERDANA España (300k u/día)", coordinate: CLLocationCoordinate2D(latitude: 40.4200, longitude: -3.7000))
                        .tint(brandGreen)
                    Marker("Punto B2B Madrid Centro", coordinate: CLLocationCoordinate2D(latitude: 40.4150, longitude: -3.7100))
                }
                .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Punto de Recolección Más Cercano", systemImage: "location.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(brandGreen)
                        Spacer()
                        Text("A 350 m")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(brandGreen.opacity(0.15), in: Capsule())
                    }
                    Text("Hub Planta España - Zona B2B")
                        .font(.headline)
                    Text("Abierto hoy hasta las 21:00 · Inspección y limpieza automática.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(20)
                .padding(.bottom, 60)
            }
            .navigationTitle("Red Logística B2B España")
        }
    }
}

// MARK: - BARRA DE NAVEGACIÓN FLOTANTE (Orden correcto)
struct CustomFloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabBarItem(index: 0, title: "Perfil", systemImage: "person.fill")
            tabBarItem(index: 1, title: "Recompensas", systemImage: "gift.fill")
            tabBarItem(index: 2, title: "E-commerce", systemImage: "bag.fill")
            tabBarItem(index: 3, title: "Mapa", systemImage: "map.fill")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
    }

    private func tabBarItem(index: Int, title: String, systemImage: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == index ? brandGreen : .secondary)
        }
    }
}

struct ScanResultView: View {
    @EnvironmentObject private var store: LoopStore
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            ConfettiView()
                .opacity(showConfetti ? 1 : 0)

            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(brandGreen)
                    .padding(.top, 36)

                VStack(spacing: 4) {
                    Text("Devolución registrada").font(.title3.weight(.bold))
                    if let event = store.lastEvent {
                        Text(event.assetID)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 4) {
                    Text("¡Gracias por sumarte a la economía circular!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(String(format: "Evitaste %.1f kg de CO₂ con esta devolución", store.co2SavedPerReturnDisplay))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(brandGreen, in: RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 10) {
                    row("Depósito devuelto", String(format: "€%.2f", store.depositRefunded))
                    row("Puntos ganados", "+\(store.lastEvent?.pointsAwarded ?? 0)")
                    row("Bonus de racha", "+\(store.lastEvent?.bonusAwarded ?? 0)", highlight: true)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                Spacer()

                Button("Listo") { dismiss() }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .buttonStyle(.borderedProminent)
                    .tint(brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
        .onAppear {
            withAnimation { showConfetti = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(highlight ? brandGreen : .primary)
        }
    }
}
