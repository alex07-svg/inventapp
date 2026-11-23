import SwiftData
import SwiftUI

/// Formulario estilo Apple (`Form`) para registrar un equipo nuevo o editar uno existente.
struct EquipmentFormView: View {
    /// Si es `nil`, estamos creando un equipo nuevo. Si tiene valor, estamos editando ese equipo.
    let equipmentToEdit: Equipment?

    /// Permite pre-rellenar el número de serie (lo aprovecharemos en el Paso 6 desde el escáner QR).
    let initialSerialNumber: String?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Consultamos todos los equipos para validar en vivo que el número de serie no esté repetido.
    @Query private var existingEquipment: [Equipment]

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var modelName: String = ""
    @State private var serialNumber: String = ""
    @State private var category: EquipmentCategory = .notebook
    @State private var status: EquipmentStatus = .available
    @State private var notes: String = ""

    @State private var errorMessage: String?

    init(equipmentToEdit: Equipment? = nil, initialSerialNumber: String? = nil) {
        self.equipmentToEdit = equipmentToEdit
        self.initialSerialNumber = initialSerialNumber

        if let equipment = equipmentToEdit {
            _name = State(initialValue: equipment.name)
            _brand = State(initialValue: equipment.brand)
            _modelName = State(initialValue: equipment.modelName)
            _serialNumber = State(initialValue: equipment.serialNumber)
            _category = State(initialValue: equipment.category)
            _status = State(initialValue: equipment.status)
            _notes = State(initialValue: equipment.notes)
        } else if let initialSerialNumber {
            _serialNumber = State(initialValue: InventoryViewModel.normalizeSerialNumber(initialSerialNumber))
        }
    }

    // MARK: - Propiedades de validación

    private var isEditing: Bool {
        equipmentToEdit != nil
    }

    private var normalizedSerial: String {
        InventoryViewModel.normalizeSerialNumber(serialNumber)
    }

    private var isDuplicateSerial: Bool {
        InventoryViewModel.isSerialNumberDuplicate(
            serialNumber,
            in: existingEquipment,
            excluding: equipmentToEdit
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !normalizedSerial.isEmpty
            && !isDuplicateSerial
    }

    /// Opciones de estado disponibles desde el formulario.
    /// Si el equipo no tiene usuario asignado, evitamos marcarlo manualmente como "Entregado"
    /// (la entrega formal con usuario e historial la haremos en el Paso 5).
    private var selectableStatuses: [EquipmentStatus] {
        if let equipmentToEdit, equipmentToEdit.assignedEmployee != nil {
            return EquipmentStatus.allCases
        }
        return [.available, .maintenance]
    }

    var body: some View {
        NavigationStack {
            Form {
                // Sección 1: Datos generales del equipo
                Section("Información del Equipo") {
                    Picker("Categoría", selection: $category) {
                        ForEach(EquipmentCategory.allCases) { item in
                            Label(item.displayName, systemImage: item.symbolName)
                                .tag(item)
                        }
                    }

                    TextField("Nombre (ej. MacBook Pro 14\" M4)", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Marca (ej. Apple, Dell, Logitech)", text: $brand)
                        .textInputAutocapitalization(.words)

                    TextField("Modelo (opcional, ej. A3112)", text: $modelName)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                // Sección 2: Número de serie con validación en tiempo real
                Section {
                    HStack {
                        TextField("Ej. C02MBP202601", text: $serialNumber)
                            .font(.body.monospaced())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        if !isEditing {
                            Button("Sugerir") {
                                serialNumber = InventoryViewModel.suggestedSerialNumber(for: category)
                            }
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    if isDuplicateSerial {
                        Label(
                            "Este número de serie ya está registrado en el inventario.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                } header: {
                    Text("Número de Serie")
                } footer: {
                    Text("El número de serie identifica de forma única a cada equipo y servirá para buscarlo mediante código QR.")
                }

                // Sección 3: Estado y notas
                Section {
                    Picker("Estado", selection: $status) {
                        ForEach(selectableStatuses) { item in
                            Label(item.displayName, systemImage: item.symbolName)
                                .tag(item)
                        }
                    }

                    TextField("Notas adicionales (cargador, estado físico, garantía...)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Estado y Observaciones")
                } footer: {
                    if equipmentToEdit?.assignedEmployee == nil {
                        Text("Para marcar un equipo como Entregado, asígnalo a un usuario desde su vista de detalle.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar Equipo" : "Nuevo Equipo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveEquipment()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .alert("No se pudo guardar", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Ocurrió un error inesperado.")
            }
        }
    }

    // MARK: - Guardado en SwiftData

    private func saveEquipment() {
        guard canSave else { return }

        if let equipment = equipmentToEdit {
            equipment.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            equipment.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
            equipment.modelName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
            equipment.serialNumber = normalizedSerial
            equipment.category = category
            equipment.status = status
            equipment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let newEquipment = Equipment(
                serialNumber: normalizedSerial,
                name: name,
                brand: brand,
                modelName: modelName,
                category: category,
                status: status,
                notes: notes
            )
            modelContext.insert(newEquipment)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Verifica que el número de serie no esté duplicado e inténtalo nuevamente."
        }
    }
}

#Preview("Nuevo equipo", traits: .sampleData) {
    EquipmentFormView()
}
