import SwiftData
import SwiftUI

/// Pantalla principal de resumen (Dashboard) con estética moderna estilo Apple.
/// Lee los datos en tiempo real desde SwiftData mediante `@Query`.
struct DashboardView: View {
    /// Enlace bidireccional (`@Binding`) a la pestaña seleccionada en `MainTabView`,
    /// para que los botones de acceso rápido puedan cambiar de pestaña.
    @Binding var selectedTab: AppTab

    /// `@Environment(\.modelContext)` nos da acceso a la base de datos para insertar o guardar cambios.
    @Environment(\.modelContext) private var modelContext

    /// `@Query` consulta SwiftData automáticamente y redibuja la vista cada vez que cambia un equipo.
    @Query(sort: \Equipment.createdAt, order: .reverse)
    private var equipmentList: [Equipment]

    @Query(sort: \Employee.fullName)
    private var employees: [Employee]

    // MARK: - Métricas calculadas

    private var totalCount: Int { equipmentList.count }

    private var availableCount: Int {
        equipmentList.filter { $0.status == .available }.count
    }

    private var assignedCount: Int {
        equipmentList.filter { $0.status == .assigned }.count
    }

    private var maintenanceCount: Int {
        equipmentList.filter { $0.status == .maintenance }.count
    }

    private var recentEquipment: [Equipment] {
        Array(equipmentList.prefix(4))
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        NavigationStack {
            Group {
                if equipmentList.isEmpty {
                    emptyStateView
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Resumen")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                if equipmentList.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Datos demo", systemImage: "sparkles") {
                            loadSampleData()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Contenido principal del Dashboard

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. Cuadrícula de métricas principales
                metricsGridSection

                // 2. Accesos rápidos
                quickActionsSection

                // 3. Desglose por categoría (Notebooks, Monitores, Periféricos)
                categoryBreakdownSection

                // 4. Equipos agregados recientemente
                recentEquipmentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Sección 1: Cuadrícula de métricas

    private var metricsGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Estado del Inventario")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                StatCardView(
                    title: "Total Equipos",
                    value: totalCount,
                    subtitle: "\(employees.count) usuarios registrados",
                    symbolName: "shippingbox.fill",
                    tintColor: .indigo
                )

                StatCardView(
                    title: "Disponibles",
                    value: availableCount,
                    subtitle: percentageText(for: availableCount),
                    symbolName: EquipmentStatus.available.symbolName,
                    tintColor: EquipmentStatus.available.tintColor
                )

                StatCardView(
                    title: "Entregados",
                    value: assignedCount,
                    subtitle: percentageText(for: assignedCount),
                    symbolName: EquipmentStatus.assigned.symbolName,
                    tintColor: EquipmentStatus.assigned.tintColor
                )

                StatCardView(
                    title: "Mantenimiento",
                    value: maintenanceCount,
                    subtitle: maintenanceCount == 0 ? "Todo operativo" : "En revisión técnica",
                    symbolName: EquipmentStatus.maintenance.symbolName,
                    tintColor: EquipmentStatus.maintenance.tintColor
                )
            }
        }
    }

    // MARK: - Sección 2: Accesos rápidos

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Accesos Rápidos")

            HStack(spacing: 10) {
                quickActionButton(
                    title: "Inventario",
                    symbolName: "laptopcomputer",
                    tint: .blue
                ) {
                    selectedTab = .inventory
                }

                quickActionButton(
                    title: "Escanear QR",
                    symbolName: "qrcode.viewfinder",
                    tint: .indigo
                ) {
                    selectedTab = .scanner
                }

                quickActionButton(
                    title: "Usuarios",
                    symbolName: "person.2.fill",
                    tint: .teal
                ) {
                    selectedTab = .employees
                }
            }
        }
    }

    private func quickActionButton(
        title: String,
        symbolName: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sección 3: Desglose por categoría

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Por Categoría")

            VStack(spacing: 16) {
                ForEach(EquipmentCategory.allCases) { category in
                    let items = equipmentList.filter { $0.category == category }
                    let available = items.filter { $0.isAvailable }.count
                    let assigned = items.filter { $0.isAssigned }.count
                    let ratio = totalCount > 0 ? Double(items.count) / Double(totalCount) : 0

                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: category.symbolName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(category.tintColor)
                                .frame(width: 34, height: 34)
                                .background(
                                    category.tintColor.opacity(0.14),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.pluralName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("\(available) disp. • \(assigned) entregados")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(items.count)")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                        }

                        // Barra de proporción visual
                        ProgressView(value: ratio)
                            .tint(category.tintColor)
                    }

                    if category != EquipmentCategory.allCases.last {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Sección 4: Equipos recientes

    private var recentEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Equipos Recientes")
                Spacer()
                Button("Ver todos") {
                    selectedTab = .inventory
                }
                .font(.subheadline.weight(.medium))
            }

            VStack(spacing: 0) {
                ForEach(recentEquipment) { item in
                    EquipmentRowView(equipment: item)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if item.id != recentEquipment.last?.id {
                        Divider()
                            .padding(.leading, 74)
                    }
                }
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Estado vacío inicial

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Tu inventario está vacío", systemImage: "shippingbox")
        } description: {
            Text("Registra notebooks, monitores y periféricos o carga datos de ejemplo para explorar la aplicación.")
        } actions: {
            Button("Cargar datos de ejemplo", systemImage: "sparkles") {
                loadSampleData()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 4)
    }

    private func percentageText(for count: Int) -> String {
        guard totalCount > 0 else { return "0% del total" }
        let percentage = Int((Double(count) / Double(totalCount) * 100).rounded())
        return "\(percentage)% del total"
    }

    private func loadSampleData() {
        withAnimation(.snappy) {
            SampleData.populate(in: modelContext)
        }
    }
}

#Preview(traits: .sampleData) {
    DashboardView(selectedTab: .constant(.dashboard))
}
