import SwiftUI

/// Pestañas principales de la aplicación.
/// Usamos un `enum` para controlar de forma segura qué pestaña está activa.
enum AppTab: Hashable {
    case dashboard
    case inventory
    case employees
    case scanner
}

/// Contenedor principal de navegación basado en barra de pestañas (`TabView`).
struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Resumen", systemImage: "square.grid.2x2.fill", value: AppTab.dashboard) {
                DashboardView(selectedTab: $selectedTab)
            }

            Tab("Inventario", systemImage: "laptopcomputer.and.iphone", value: AppTab.inventory) {
                UpcomingFeaturePlaceholderView(
                    title: "Inventario",
                    symbolName: "laptopcomputer.and.iphone",
                    stepDescription: "En el Paso 4 construiremos el catálogo completo con buscador por serie, filtros por categoría/estado y registro de equipos."
                )
            }

            Tab("Usuarios", systemImage: "person.2.fill", value: AppTab.employees) {
                UpcomingFeaturePlaceholderView(
                    title: "Usuarios",
                    symbolName: "person.2.fill",
                    stepDescription: "En el Paso 5 construiremos el directorio de usuarios, la asignación de equipos y el historial de entregas."
                )
            }

            Tab("Escanear", systemImage: "qrcode.viewfinder", value: AppTab.scanner) {
                UpcomingFeaturePlaceholderView(
                    title: "Escáner QR",
                    symbolName: "qrcode.viewfinder",
                    stepDescription: "En el Paso 6 integraremos la cámara para leer códigos QR de equipos y un modo simulado para probar en Xcode."
                )
            }
        }
    }
}

/// Vista temporal amigable para las pestañas que iremos completando en los próximos pasos.
private struct UpcomingFeaturePlaceholderView: View {
    let title: String
    let symbolName: String
    let stepDescription: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: symbolName,
                description: Text(stepDescription)
            )
            .navigationTitle(title)
        }
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
