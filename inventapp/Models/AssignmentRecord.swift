import Foundation
import SwiftData

/// Registro histórico de entrega y devolución de un equipo a un usuario.
/// Permite auditar quién tuvo un equipo y durante qué período.
@Model
final class AssignmentRecord {
    var equipment: Equipment?
    var employee: Employee?

    /// Fecha en que se entregó el equipo.
    var assignedDate: Date

    /// Fecha en que se devolvió el equipo (`nil` mientras la asignación siga activa).
    var returnedDate: Date?

    /// Observaciones de la entrega o devolución (ej. "Entregado con cargador original").
    var notes: String

    init(
        equipment: Equipment,
        employee: Employee,
        assignedDate: Date = .now,
        returnedDate: Date? = nil,
        notes: String = ""
    ) {
        self.equipment = equipment
        self.employee = employee
        self.assignedDate = assignedDate
        self.returnedDate = returnedDate
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `true` si el equipo todavía no ha sido devuelto.
    var isActive: Bool {
        returnedDate == nil
    }
}
