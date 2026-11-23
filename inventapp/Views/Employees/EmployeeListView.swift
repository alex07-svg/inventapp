import SwiftData
import SwiftUI

/// Directorio de usuarios/colaboradores a quienes se les asignan equipos tecnológicos.
struct EmployeeListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Employee.fullName)
    private var employees: [Employee]

    @State private var searchText: String = ""
    @State private var isShowingAddSheet = false
    @State private var employeeToEdit: Employee?

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
            Group {
                if employees.isEmpty {
                    emptyEmployeesView
                } else if filteredEmployees.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        Section("\(filteredEmployees.count) usuarios") {
                            ForEach(filteredEmployees) { employee in
                                NavigationLink {
                                    EmployeeDetailView(employee: employee)
                                } label: {
                                    employeeRow(employee)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation(.snappy) {
                                            InventoryViewModel.deleteEmployee(employee, in: modelContext)
                                            try? modelContext.save()
                                        }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }

                                    Button {
                                        employeeToEdit = employee
                                    } label: {
                                        Label("Editar", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Usuarios")
            .searchable(text: $searchText, prompt: "Nombre, departamento o correo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Label("Nuevo usuario", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                EmployeeFormView()
            }
            .sheet(item: $employeeToEdit) { employee in
                EmployeeFormView(employeeToEdit: employee)
            }
        }
    }

    // MARK: - Fila de usuario

    private func employeeRow(_ employee: Employee) -> some View {
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

            Spacer()

            // Contador de equipos actualmente asignados
            let count = employee.assignedEquipment.count
            HStack(spacing: 4) {
                Image(systemName: "laptopcomputer")
                    .font(.caption2)
                Text("\(count)")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(count > 0 ? .blue : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                count > 0 ? Color.blue.opacity(0.12) : Color(.tertiarySystemFill),
                in: Capsule()
            )
        }
        .padding(.vertical, 3)
    }

    // MARK: - Estado vacío

    private var emptyEmployeesView: some View {
        ContentUnavailableView {
            Label("Sin usuarios registrados", systemImage: "person.2")
        } description: {
            Text("Registra a los colaboradores de tu organización para asignarles notebooks, monitores y periféricos.")
        } actions: {
            Button("Registrar usuario", systemImage: "person.badge.plus") {
                isShowingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

#Preview(traits: .sampleData) {
    EmployeeListView()
}
