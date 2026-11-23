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
    @State private var inventoryViewModel = InventoryViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Resumen", systemImage: "square.grid.2x2.fill", value: AppTab.dashboard) {
                DashboardView(
                    selectedTab: $selectedTab,
                    onFilterInventory: openInventory(status:category:)
                )
            }

            Tab("Inventario", systemImage: "laptopcomputer.and.iphone", value: AppTab.inventory) {
                InventoryListView(viewModel: inventoryViewModel)
            }

            Tab("Usuarios", systemImage: "person.2.fill", value: AppTab.employees) {
                EmployeeListView()
            }

            Tab("Escanear", systemImage: "qrcode.viewfinder", value: AppTab.scanner) {
                QRScannerView()
            }
        }
    }

    /// Navega a la pestaña de Inventario aplicando automáticamente el filtro elegido desde el Dashboard.
    private func openInventory(status: EquipmentStatus?, category: EquipmentCategory?) {
        inventoryViewModel.searchText = ""
        inventoryViewModel.selectedStatus = status
        inventoryViewModel.selectedCategory = category
        selectedTab = .inventory
    }
}

#Preview(traits: .sampleData) {
    MainTabView()
}
