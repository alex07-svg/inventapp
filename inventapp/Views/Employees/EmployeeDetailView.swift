import SwiftData
import SwiftUI

/// Perfil de un usuario con sus datos, los equipos que tiene actualmente asignados,
/// acceso rápido para entregarle un equipo disponible y su historial de entregas.
struct EmployeeDetailView: View {
    let employee: Employee

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingEditSheet = false
    @State private var isShowingPickEquipmentSheet = false
    @State private var isShowingDeleteAlert = false

    private var sortedAssignedEquipment: [Equipment] {
        employee.assignedEquipment.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var sortedHistory: [AssignmentRecord] {
        employee.assignmentHistory.sorted { $0.assignedDate > $1.assignedDate }
    }

    var body: some View {
        List {
            // 1. Encabezado de perfil estilo Apple Contactos
            profileHeaderSection

            // 2. Equipos actualmente a cargo del usuario
            assignedEquipmentSection

            // 3. Historial de movimientos del usuario
            historySection

            // 4. Eliminar usuario (liberando equipos de forma segura)
            Section {
                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Label("Eliminar usuario", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Usuario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    isShowingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EmployeeFormView(employeeToEdit: employee)
        }
        .sheet(isPresented: $isShowingPickEquipmentSheet) {
            PickAvailableEquipmentSheet(employee: employee)
        }
        .alert("¿Eliminar a \(employee.fullName)?", isPresented: $isShowingDeleteAlert) {
            Button("Eliminar", role: .destructive) {
                InventoryViewModel.deleteEmployee(employee, in: modelContext)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            if employee.assignedEquipment.isEmpty {
                Text("El usuario será eliminado del directorio.")
            } else {
                Text("Los \(employee.assignedEquipment.count) equipos que tiene asignados volverán automáticamente al estado Disponible.")
            }
        }
    }

    // MARK: - Sección 1: Perfil

    private var profileHeaderSection: some View {
        Section {
            VStack(spacing: 10) {
                EmployeeAvatarView(initials: employee.initials, size: 72, tintColor: .blue)

                VStack(spacing: 3) {
                    Text(employee.fullName)
                        .font(.title3.weight(.bold))

                    Text(employee.department)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !employee.email.isEmpty {
                        Text(employee.email)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Sección 2: Equipos asignados actualmente

    private var assignedEquipmentSection: some View {
        Section {
            if sortedAssignedEquipment.isEmpty {
                Text("No tiene equipos asignados actualmente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedAssignedEquipment) { equipment in
                    NavigationLink {
                        EquipmentDetailView(equipment: equipment)
                    } label: {
                        EquipmentRowView(equipment: equipment)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            withAnimation(.snappy) {
                                InventoryViewModel.returnEquipment(equipment, newStatus: .available)
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Devolver", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.orange)
                    }
                }
            }

            Button {
                isShowingPickEquipmentSheet = true
            } label: {
                Label("Asignar equipo disponible", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
        } header: {
            Text("Equipos Asignados (\(sortedAssignedEquipment.count))")
        } footer: {
            if !sortedAssignedEquipment.isEmpty {
                Text("Desliza un equipo hacia la izquierda para registrar su devolución rápidamente.")
            }
        }
    }

    // MARK: - Sección 3: Historial

    private var historySection: some View {
        Section("Historial de Entregas (\(sortedHistory.count))") {
            if sortedHistory.isEmpty {
                Text("Sin historial de entregas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedHistory) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.equipment?.name ?? "Equipo eliminado")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(record.isActive ? "En uso" : "Devuelto")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(record.isActive ? .blue : .secondary)
                        }

                        if let serial = record.equipment?.serialNumber {
                            Text(serial)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 4) {
                            Text(record.assignedDate, format: .dateTime.day().month(.abbreviated).year())
                            if let returned = record.returnedDate {
                                Text("→")
                                Text(returned, format: .dateTime.day().month(.abbreviated).year())
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }
}

/// Hoja modal para elegir un equipo disponible y asignarlo directamente desde el perfil de un usuario.
private struct PickAvailableEquipmentSheet: View {
    let employee: Employee

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Equipment.name)
    private var allEquipment: [Equipment]

    @State private var searchText: String = ""
    @State private var selectedEquipment: Equipment?
    @State private var notes: String = ""

    private var availableEquipment: [Equipment] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return allEquipment.filter { item in
            guard item.status == .available else { return false }
            if query.isEmpty { return true }
            return item.name.localizedStandardContains(query)
                || item.brand.localizedStandardContains(query)
                || item.serialNumber.localizedStandardContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if availableEquipment.isEmpty {
                    ContentUnavailableView(
                        "Sin equipos disponibles",
                        systemImage: "shippingbox",
                        description: Text("No hay equipos con estado Disponible que coincidan con tu búsqueda.")
                    )
                } else {
                    Section("Equipos Disponibles") {
                        ForEach(availableEquipment) { equipment in
                            Button {
                                selectedEquipment = equipment
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: equipment.category.symbolName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(equipment.category.tintColor)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            equipment.category.tintColor.opacity(0.14),
                                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(equipment.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(equipment.serialNumber)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedEquipment?.persistentModelID == equipment.persistentModelID {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("Observaciones de Entrega") {
                        TextField("Opcional (ej. Entrega con adaptador)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                    }
                }
            }
            .navigationTitle("Entregar a \(employee.fullName)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar equipo o serie")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Asignar") {
                        guard let equipment = selectedEquipment else { return }
                        withAnimation(.snappy) {
                            InventoryViewModel.assign(
                                equipment: equipment,
                                to: employee,
                                notes: notes,
                                in: modelContext
                            )
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedEquipment == nil)
                }
            }
        }
    }
}

#Preview(traits: .sampleData) {
    let sampleEmployee = Employee(
        fullName: "Ana Martínez",
        email: "ana.martinez@empresa.com",
        department: "Diseño de Producto"
    )
    return NavigationStack {
        EmployeeDetailView(employee: sampleEmployee)
    }
}
