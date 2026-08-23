//
//  DashboardsTabView.swift
//  Verdana
//
//  Created by Ivanna Torres Mora on 22/08/26.
//

import SwiftUI
import WebKit

private let brandGreen = Color(red: 0.08, green: 0.42, blue: 0.28)

/// Envuelve WKWebView para SwiftUI. Recarga cuando cambia la URL.
struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @Binding var reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastURL != url || context.coordinator.lastToken != reloadToken {
            context.coordinator.lastURL = url
            context.coordinator.lastToken = reloadToken
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewContainer
        var lastURL: URL?
        var lastToken: Int = -1

        init(_ parent: WebViewContainer) { self.parent = parent }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in parent.isLoading = true; parent.loadFailed = false }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in parent.isLoading = false }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in parent.isLoading = false; parent.loadFailed = true }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in parent.isLoading = false; parent.loadFailed = true }
        }
    }
}

/// Tab de "Panel operativo": alterna entre los tres dashboards servidos por server.py.
/// Requiere que python3 server.py esté corriendo en la misma red que el teléfono.
struct DashboardsTabView: View {
    private enum Panel: String, CaseIterable, Identifiable {
        case torre = "Torre de control"
        case b2b = "Retail B2B"
        case horeca = "HoReCa"

        var id: String { rawValue }
        var path: String {
            switch self {
            case .torre: return "/dashboard.html"
            case .b2b: return "/b2b.html"
            case .horeca: return "/horeca.html"
            }
        }
    }

    @State private var selected: Panel = .torre
    @State private var reloadToken = 0
    @State private var isLoading = false
    @State private var loadFailed = false

    private var currentURL: URL? {
        URL(string: serverBaseURL + selected.path)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Panel", selection: $selected) {
                    ForEach(Panel.allCases) { panel in
                        Text(panel.rawValue).tag(panel)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)

                ZStack {
                    if let url = currentURL {
                        WebViewContainer(url: url, reloadToken: $reloadToken, isLoading: $isLoading, loadFailed: $loadFailed)
                    }

                    if loadFailed {
                        connectionErrorView
                    } else if isLoading {
                        ProgressView("Cargando panel…")
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Panel operativo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Recargar", systemImage: "arrow.clockwise") { reloadToken += 1 }
                }
            }
        }
    }

    private var connectionErrorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("No se pudo conectar con el servidor")
                .font(.subheadline.weight(.medium))
            Text(serverBaseURL)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Text("Verifica que python3 server.py esté corriendo\ny que el teléfono esté en la misma red WiFi.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Reintentar") { reloadToken += 1 }
                .buttonStyle(.borderedProminent)
                .tint(brandGreen)
                .padding(.top, 6)
        }
        .padding(24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(30)
    }
}
