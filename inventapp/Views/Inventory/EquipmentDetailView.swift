import SwiftData
import SwiftUI
import UIKit

/// Vista de detalle completa de un equipo tecnológico.
/// Permite ver sus especificaciones, asignar/devolver el equipo, editarlo y revisar su historial.
struct EquipmentDetailView: View {
    let equipment: Equipment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingEditSheet = false
    @State private var isShowingAssignSheet = false
    @State private var isShowingQRSheet = false
    @State private var isShowingReturnConfirmation = false
    @State private var isShowingDeleteAlert = false
    @State private var copiedSerialFeedback = false

    /// Historial ordenado desde la asignación más reciente a la más antigua.
    private var sortedHistory: [AssignmentRecord] {
        equipment.assignmentHistory.sorted { $0.assignedDate > $1.assignedDate }
    }

    var body: some View {
        List {
            // 1. Encabezado visual del equipo
            headerSection

            // 2. Asignación actual y acciones principales
            assignmentSection

            // 3. Ficha técnica y notas
            specificationsSection

            // 4. Historial completo de entregas y devoluciones
            historySection

            // 5. Acción destructiva al final (estándar Apple Settings/Contacts)
            Section {
                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Label("Eliminar equipo del inventario", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingQRSheet = true
                } label: {
                    Label("Ver código QR", systemImage: "qrcode")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    isShowingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EquipmentFormView(equipmentToEdit: equipment)
        }
        .sheet(isPresented: $isShowingAssignSheet) {
            AssignEquipmentSheet(equipment: equipment)
        }
        .sheet(isPresented: $isShowingQRSheet) {
            EquipmentQRLabelSheet(equipment: equipment)
        }
        .confirmationDialog(
            "Registrar devolución",
            isPresented: $isShowingReturnConfirmation,
            titleVisibility: .visible
        ) {
            Button("Devolver y marcar como Disponible") {
                returnEquipment(as: .available)
            }
            Button("Devolver y enviar a Mantenimiento") {
                returnEquipment(as: .maintenance)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            if let employee = equipment.assignedEmployee {
                Text("¿Cómo deseas registrar la devolución de \(equipment.name) por parte de \(employee.fullName)?")
            }
        }
        .alert("¿Eliminar equipo?", isPresented: $isShowingDeleteAlert) {
            Button("Eliminar", role: .destructive) {
                modelContext.delete(equipment)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará \"\(equipment.name)\" y todo su historial de asignaciones. Esta acción no se puede deshacer.")
        }
    }

    // MARK: - Sección 1: Encabezado

    private var headerSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: equipment.category.symbolName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(equipment.category.tintColor)
                    .frame(width: 72, height: 72)
                    .background(
                        equipment.category.tintColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )

                VStack(spacing: 4) {
                    Text(equipment.name)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(brandAndModelText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                StatusBadgeView(status: equipment.status)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Sección 2: Asignación actual

    private var assignmentSection: some View {
        Section("Asignación") {
            if let employee = equipment.assignedEmployee, equipment.status == .assigned {
                NavigationLink {
                    EmployeeDetailView(employee: employee)
                } label: {
                    HStack(spacing: 12) {
                        EmployeeAvatarView(initials: employee.initials, size: 42, tintColor: .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(employee.fullName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(employee.department)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Button {
                    isShowingReturnConfirmation = true
                } label: {
                    Label("Registrar devolución", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else if equipment.status == .available {
                Button {
                    isShowingAssignSheet = true
                } label: {
                    Label("Asignar a un usuario", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Equipo en mantenimiento", systemImage: EquipmentStatus.maintenance.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)

                    Text("Márcalo como disponible cuando finalice la revisión para poder asignarlo nuevamente.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                Button {
                    withAnimation(.snappy) {
                        equipment.status = .available
                        try? modelContext.save()
                    }
                } label: {
                    Label("Marcar como Disponible", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Sección 3: Especificaciones y número de serie

    private var specificationsSection: some View {
        Section("Especificaciones") {
            LabeledContent("Categoría", value: equipment.category.displayName)
            LabeledContent("Marca", value: equipment.brand)

            if !equipment.modelName.isEmpty {
                LabeledContent("Modelo", value: equipment.modelName)
            }

            HStack {
                Text("N.° de Serie")
                Spacer()
                Text(equipment.serialNumber)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)

                Button {
                    copySerialNumber()
                } label: {
                    Image(systemName: copiedSerialFeedback ? "checkmark" : "doc.on.doc")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(copiedSerialFeedback ? .green : .blue)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Copiar número de serie")
            }

            LabeledContent("Registrado el") {
                Text(equipment.createdAt, format: .dateTime.day().month(.abbreviated).year())
            }

            if !equipment.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(equipment.notes)
                        .font(.subheadline)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Sección 4: Historial de entregas

    private var historySection: some View {
        Section("Historial de Entregas (\(sortedHistory.count))") {
            if sortedHistory.isEmpty {
                Text("Este equipo aún no registra entregas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedHistory) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(record.employee?.fullName ?? "Usuario eliminado")
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            if record.isActive {
                                Text("Activa")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.14), in: Capsule())
                            } else {
                                Text("Devuelto")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(.tertiarySystemFill), in: Capsule())
                            }
                        }

                        HStack(spacing: 4) {
                            Text("Entregado:")
                                .foregroundStyle(.secondary)
                            Text(record.assignedDate, format: .dateTime.day().month(.abbreviated).year())
                                .foregroundStyle(.secondary)

                            if let returnedDate = record.returnedDate {
                                Text("• Devuelto:")
                                    .foregroundStyle(.secondary)
                                Text(returnedDate, format: .dateTime.day().month(.abbreviated).year())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)

                        if !record.notes.isEmpty {
                            Text(record.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Helpers

    private var brandAndModelText: String {
        if equipment.modelName.isEmpty {
            return equipment.brand
        }
        return "\(equipment.brand) • \(equipment.modelName)"
    }

    private func returnEquipment(as newStatus: EquipmentStatus) {
        withAnimation(.snappy) {
            InventoryViewModel.returnEquipment(equipment, newStatus: newStatus)
            try? modelContext.save()
        }
    }

    private func copySerialNumber() {
        UIPasteboard.general.string = equipment.serialNumber
        withAnimation(.snappy) {
            copiedSerialFeedback = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.snappy) {
                copiedSerialFeedback = false
            }
        }
    }
}

#Preview(traits: .sampleData) {
    let sampleEmployee = Employee(
        fullName: "Carlos Herrera",
        email: "carlos.herrera@empresa.com",
        department: "Ingeniería iOS"
    )
    let sampleEquipment = Equipment(
        serialNumber: "C02MBP202601",
        name: "MacBook Pro 14\" M4 Pro",
        brand: "Apple",
        modelName: "A3112",
        category: .notebook,
        status: .assigned,
        notes: "Incluye cargador MagSafe de 70W.",
        assignedEmployee: sampleEmployee
    )
    return NavigationStack {
        EquipmentDetailView(equipment: sampleEquipment)
    }
}
