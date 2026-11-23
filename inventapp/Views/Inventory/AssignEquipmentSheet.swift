import SwiftData
import SwiftUI

/// Hoja modal para asignar un equipo disponible a un usuario existente o recién creado.
struct AssignEquipmentSheet: View {
    let equipment: Equipment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Employee.fullName)
    private var employees: [Employee]

    @State private var selectedEmployee: Employee?
    @State private var searchText: String = ""
    @State private var deliveryNotes: String = ""
    @State private var isShowingNewEmployeeSheet = false

    private var filteredEmployees: [Employee] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return employees }
        return employees.filter {
            $0.fullName.localizedStandardContains(query)
                || $0.department.localizedStandardContains(query)
                || $0.email.localizedStandardContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Resumen del equipo a entregar
                Section("Equipo a Entregar") {
                    HStack(spacing: 12) {
                        Image(systemName: equipment.category.symbolName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(equipment.category.tintColor)
                            .frame(width: 40, height: 40)
                            .background(
                                equipment.category.tintColor.opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(equipment.name)
                                .font(.subheadline.weight(.semibold))
                            Text(equipment.serialNumber)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Selector de usuario
                Section {
                    if employees.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aún no hay usuarios registrados.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Crear primer usuario", systemImage: "person.badge.plus") {
                                isShowingNewEmployeeSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(filteredEmployees) { employee in
                            Button {
                                selectedEmployee = employee
                            } label: {
                                HStack(spacing: 12) {
                                    EmployeeAvatarView(initials: employee.initials, size: 36, tintColor: .blue)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(employee.fullName)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)

                                        Text(employee.department)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedEmployee?.persistentModelID == employee.persistentModelID {
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
                } header: {
                    HStack {
                        Text("Seleccionar Usuario")
                        Spacer()
                        Button("Nuevo", systemImage: "plus") {
                            isShowingNewEmployeeSheet = true
                        }
                        .font(.caption.weight(.semibold))
                        .textCase(nil)
                    }
                }

                // Observaciones de la entrega
                Section("Observaciones de Entrega") {
                    TextField("Ej. Entregado con cargador original y funda", text: $deliveryNotes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Asignar Equipo")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar usuario o departamento")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        confirmAssignment()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedEmployee == nil)
                }
            }
            .sheet(isPresented: $isShowingNewEmployeeSheet) {
                EmployeeFormView { newlyCreated in
                    selectedEmployee = newlyCreated
                }
            }
        }
    }

    private func confirmAssignment() {
        guard let employee = selectedEmployee else { return }
        withAnimation(.snappy) {
            InventoryViewModel.assign(
                equipment: equipment,
                to: employee,
                notes: deliveryNotes,
                in: modelContext
            )
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview(traits: .sampleData) {
    let sampleEquipment = Equipment(
        serialNumber: "C02MBA202602",
        name: "MacBook Air 15\" M4",
        brand: "Apple",
        modelName: "A3241",
        category: .notebook,
        status: .available
    )
    return AssignEquipmentSheet(equipment: sampleEquipment)
}
