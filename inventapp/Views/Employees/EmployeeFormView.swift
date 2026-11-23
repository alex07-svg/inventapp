import SwiftData
import SwiftUI

/// Formulario modal para registrar un nuevo usuario o editar uno existente.
struct EmployeeFormView: View {
    let employeeToEdit: Employee?

    /// Callback opcional que devuelve el usuario recién creado (útil al crear uno directo al asignar un equipo).
    var onCreated: ((Employee) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var department: String = ""

    init(employeeToEdit: Employee? = nil, onCreated: ((Employee) -> Void)? = nil) {
        self.employeeToEdit = employeeToEdit
        self.onCreated = onCreated

        if let employee = employeeToEdit {
            _fullName = State(initialValue: employee.fullName)
            _email = State(initialValue: employee.email)
            _department = State(initialValue: employee.department)
        }
    }

    private var isEditing: Bool {
        employeeToEdit != nil
    }

    private var canSave: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del Usuario") {
                    TextField("Nombre completo (ej. Ana Martínez)", text: $fullName)
                        .textInputAutocapitalization(.words)

                    TextField("Departamento (ej. Ingeniería iOS)", text: $department)
                        .textInputAutocapitalization(.words)

                    TextField("Correo electrónico (opcional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(isEditing ? "Editar Usuario" : "Nuevo Usuario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveEmployee()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveEmployee() {
        guard canSave else { return }

        if let employee = employeeToEdit {
            employee.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            employee.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            employee.department = department.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let newEmployee = Employee(
                fullName: fullName,
                email: email,
                department: department
            )
            modelContext.insert(newEmployee)
            onCreated?(newEmployee)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview("Nuevo usuario", traits: .sampleData) {
    EmployeeFormView()
}
