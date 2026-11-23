import SwiftData
import SwiftUI

/// Pantalla principal del catálogo de inventario con buscador en vivo,
/// filtros por estado/categoría, ordenamiento y registro de equipos.
struct InventoryListView: View {
    /// `@Bindable` permite crear enlaces (`$viewModel.searchText`, etc.) hacia un objeto `@Observable`.
    @Bindable var viewModel: InventoryViewModel

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Equipment.createdAt, order: .reverse)
    private var equipmentList: [Equipment]

    @State private var isShowingAddSheet = false
    @State private var equipmentToEdit: Equipment?

    private var filteredItems: [Equipment] {
        viewModel.filteredEquipment(from: equipmentList)
    }

    var body: some View {
        NavigationStack {
            Group {
                if equipmentList.isEmpty {
                    emptyInventoryView
                } else {
                    inventoryContent
                }
            }
            .navigationTitle("Inventario")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Nombre, marca, serie o usuario"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Label("Nuevo equipo", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                EquipmentFormView()
            }
            .sheet(item: $equipmentToEdit) { equipment in
                EquipmentFormView(equipmentToEdit: equipment)
            }
        }
    }

    // MARK: - Contenido principal con barra de filtros + lista

    private var inventoryContent: some View {
        VStack(spacing: 0) {
            filterBar

            if filteredItems.isEmpty {
                noResultsView
            } else {
                List {
                    Section {
                        ForEach(filteredItems) { equipment in
                            Button {
                                equipmentToEdit = equipment
                            } label: {
                                EquipmentRowView(equipment: equipment)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteEquipment(equipment)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }

                                Button {
                                    equipmentToEdit = equipment
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    } header: {
                        HStack {
                            Text(resultsSummaryText)
                            Spacer()
                            if viewModel.hasActiveFilters {
                                Button("Limpiar filtros") {
                                    withAnimation(.snappy) {
                                        viewModel.resetFilters()
                                    }
                                }
                                .font(.caption.weight(.semibold))
                                .textCase(nil)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Barra horizontal de filtros estilo Apple

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Filtro de categoría como menú compacto
                Menu {
                    Button {
                        withAnimation(.snappy) {
                            viewModel.selectedCategory = nil
                        }
                    } label: {
                        if viewModel.selectedCategory == nil {
                            Label("Todas las categorías", systemImage: "checkmark")
                        } else {
                            Text("Todas las categorías")
                        }
                    }

                    Divider()

                    ForEach(EquipmentCategory.allCases) { category in
                        Button {
                            withAnimation(.snappy) {
                                viewModel.selectedCategory = category
                            }
                        } label: {
                            Label(
                                category.pluralName,
                                systemImage: viewModel.selectedCategory == category ? "checkmark" : category.symbolName
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: viewModel.selectedCategory?.symbolName ?? "line.3.horizontal.decrease.circle")
                        Text(viewModel.selectedCategory?.pluralName ?? "Categoría")
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.selectedCategory == nil ? Color.primary : Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        viewModel.selectedCategory?.tintColor ?? Color(.secondarySystemGroupedBackground),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(.separator).opacity(0.3), lineWidth: viewModel.selectedCategory == nil ? 0.5 : 0)
                    )
                }

                // Chips de estado (Todos, Disponible, Entregado, Mantenimiento)
                statusFilterChip(title: "Todos", status: nil, tint: .primary)

                ForEach(EquipmentStatus.allCases) { status in
                    statusFilterChip(
                        title: status.displayName,
                        status: status,
                        tint: status.tintColor
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func statusFilterChip(title: String, status: EquipmentStatus?, tint: Color) -> some View {
        let isSelected = viewModel.selectedStatus == status

        return Button {
            withAnimation(.snappy) {
                viewModel.selectedStatus = status
            }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isSelected ? (status?.tintColor ?? Color.accentColor) : Color(.secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: isSelected ? 0 : 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Menú de ordenamiento

    private var sortMenu: some View {
        Menu {
            Picker("Ordenar por", selection: $viewModel.sortOrder) {
                ForEach(InventoryViewModel.SortOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.symbolName)
                        .tag(option)
                }
            }
        } label: {
            Label("Ordenar", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Estados vacíos

    private var emptyInventoryView: some View {
        ContentUnavailableView {
            Label("Sin equipos registrados", systemImage: "laptopcomputer.and.iphone")
        } description: {
            Text("Registra tu primer notebook, monitor o periférico con su número de serie.")
        } actions: {
            Button("Registrar equipo", systemImage: "plus") {
                isShowingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("Sin coincidencias", systemImage: "magnifyingglass")
        } description: {
            Text("No encontramos equipos con los filtros o búsqueda actuales.")
        } actions: {
            Button("Limpiar filtros") {
                withAnimation(.snappy) {
                    viewModel.resetFilters()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers y acciones

    private var resultsSummaryText: String {
        if filteredItems.count == equipmentList.count {
            return "\(equipmentList.count) equipos en total"
        }
        return "Mostrando \(filteredItems.count) de \(equipmentList.count) equipos"
    }

    private func deleteEquipment(_ equipment: Equipment) {
        withAnimation(.snappy) {
            modelContext.delete(equipment)
        }
    }
}

#Preview(traits: .sampleData) {
    InventoryListView(viewModel: InventoryViewModel())
}
