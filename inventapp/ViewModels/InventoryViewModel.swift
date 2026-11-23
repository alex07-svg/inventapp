import Foundation
import Observation
import SwiftData

/// ViewModel encargado de la lógica de filtrado, búsqueda, ordenamiento
/// y validación de números de serie del inventario.
///
/// `@Observable` permite que cualquier vista de SwiftUI se actualice automáticamente
/// cuando cambia cualquiera de sus propiedades (como `searchText` o `selectedStatus`).
@Observable
final class InventoryViewModel {
    /// Criterios de ordenamiento disponibles para la lista de equipos.
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Más recientes"
        case nameAscending = "Nombre (A-Z)"
        case serialNumber = "Número de serie"

        var id: String { rawValue }

        var symbolName: String {
            switch self {
            case .newest:
                return "clock"
            case .nameAscending:
                return "textformat.abc"
            case .serialNumber:
                return "number"
            }
        }
    }

    var searchText: String = ""
    var selectedCategory: EquipmentCategory? = nil
    var selectedStatus: EquipmentStatus? = nil
    var sortOrder: SortOption = .newest

    /// Indica si hay algún filtro o texto de búsqueda activo.
    var hasActiveFilters: Bool {
        selectedCategory != nil
            || selectedStatus != nil
            || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Restablece todos los filtros para volver a mostrar el inventario completo.
    func resetFilters() {
        searchText = ""
        selectedCategory = nil
        selectedStatus = nil
    }

    /// Aplica filtros por categoría, estado y búsqueda de texto, y luego ordena el resultado.
    func filteredEquipment(from items: [Equipment]) -> [Equipment] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = items.filter { item in
            // 1. Filtro por categoría (si el usuario seleccionó una)
            if let selectedCategory, item.category != selectedCategory {
                return false
            }

            // 2. Filtro por estado (Disponible / Entregado / Mantenimiento)
            if let selectedStatus, item.status != selectedStatus {
                return false
            }

            // 3. Búsqueda de texto libre en nombre, marca, modelo, número de serie o usuario
            if !query.isEmpty {
                let matchesName = item.name.localizedStandardContains(query)
                let matchesBrand = item.brand.localizedStandardContains(query)
                let matchesModel = item.modelName.localizedStandardContains(query)
                let matchesSerial = item.serialNumber.localizedStandardContains(query)
                let matchesEmployee = item.assignedEmployee?.fullName.localizedStandardContains(query) ?? false

                return matchesName || matchesBrand || matchesModel || matchesSerial || matchesEmployee
            }

            return true
        }

        // 4. Ordenamiento final
        return filtered.sorted { lhs, rhs in
            switch sortOrder {
            case .newest:
                return lhs.createdAt > rhs.createdAt
            case .nameAscending:
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .serialNumber:
                return lhs.serialNumber.localizedStandardCompare(rhs.serialNumber) == .orderedAscending
            }
        }
    }

    // MARK: - Utilidades de validación

    /// Limpia espacios y convierte un número de serie a mayúsculas para mantener consistencia.
    static func normalizeSerialNumber(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Verifica si ya existe otro equipo con el mismo número de serie.
    /// El parámetro `excluding` permite editar un equipo sin marcarse a sí mismo como duplicado.
    static func isSerialNumberDuplicate(
        _ rawSerial: String,
        in items: [Equipment],
        excluding currentEquipment: Equipment? = nil
    ) -> Bool {
        let normalized = normalizeSerialNumber(rawSerial)
        guard !normalized.isEmpty else { return false }

        return items.contains { item in
            if let currentEquipment, item.persistentModelID == currentEquipment.persistentModelID {
                return false
            }
            return item.serialNumber.uppercased() == normalized
        }
    }

    /// Genera un número de serie sugerido basado en la categoría (útil para pruebas o equipos sin etiqueta).
    static func suggestedSerialNumber(for category: EquipmentCategory) -> String {
        let prefix: String
        switch category {
        case .notebook:
            prefix = "NB"
        case .monitor:
            prefix = "MN"
        case .peripheral:
            prefix = "PR"
        }
        let year = Calendar.current.component(.year, from: .now)
        let randomSuffix = Int.random(in: 1000...9999)
        return "\(prefix)-\(year)-\(randomSuffix)"
    }

    // MARK: - Lógica de Asignaciones y Devoluciones

    /// Asigna un equipo disponible a un usuario, cambia su estado a `.assigned`
    /// y crea un registro histórico en SwiftData.
    static func assign(
        equipment: Equipment,
        to employee: Employee,
        notes: String = "",
        in context: ModelContext
    ) {
        // Si por alguna razón había un registro abierto anterior, lo cerramos primero.
        closeActiveAssignmentRecords(for: equipment)

        equipment.assignedEmployee = employee
        equipment.status = .assigned

        let record = AssignmentRecord(
            equipment: equipment,
            employee: employee,
            assignedDate: .now,
            notes: notes
        )
        context.insert(record)
    }

    /// Registra la devolución de un equipo, cierra el registro histórico activo
    /// y deja el equipo en el nuevo estado elegido (por defecto `.available`).
    static func returnEquipment(
        _ equipment: Equipment,
        newStatus: EquipmentStatus = .available,
        returnNote: String = ""
    ) {
        let trimmedNote = returnNote.trimmingCharacters(in: .whitespacesAndNewlines)
        closeActiveAssignmentRecords(for: equipment, appendNote: trimmedNote)

        equipment.assignedEmployee = nil
        equipment.status = newStatus == .assigned ? .available : newStatus
    }

    /// Elimina un usuario de forma segura: primero libera sus equipos asignados
    /// para evitar equipos huérfanos con estado `.assigned` sin usuario.
    static func deleteEmployee(_ employee: Employee, in context: ModelContext) {
        let currentlyAssigned = employee.assignedEquipment
        for equipment in currentlyAssigned {
            returnEquipment(
                equipment,
                newStatus: .available,
                returnNote: "Devuelto automáticamente al eliminar usuario."
            )
        }
        context.delete(employee)
    }

    /// Cierra cualquier `AssignmentRecord` sin fecha de devolución para un equipo dado.
    private static func closeActiveAssignmentRecords(for equipment: Equipment, appendNote: String = "") {
        for record in equipment.assignmentHistory where record.isActive {
            record.returnedDate = .now
            if !appendNote.isEmpty {
                if record.notes.isEmpty {
                    record.notes = appendNote
                } else {
                    record.notes += " • Devolución: \(appendNote)"
                }
            }
        }
    }
}
