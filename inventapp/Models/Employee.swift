import Foundation
import SwiftData

/// Representa a un usuario o colaborador que puede recibir equipos asignados.
@Model
final class Employee {
    var fullName: String
    var email: String
    var department: String
    var createdAt: Date

    /// Lista de equipos que el usuario tiene actualmente en su poder.
    /// `.nullify` asegura que si eliminamos un usuario, sus equipos NO se borren (solo quedan sin asignar).
    @Relationship(deleteRule: .nullify, inverse: \Equipment.assignedEmployee)
    var assignedEquipment: [Equipment] = []

    /// Historial de todas las asignaciones pasadas y presentes de este usuario.
    @Relationship(deleteRule: .nullify, inverse: \AssignmentRecord.employee)
    var assignmentHistory: [AssignmentRecord] = []

    init(
        fullName: String,
        email: String,
        department: String,
        createdAt: Date = .now
    ) {
        self.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.department = department.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }

    /// Iniciales del nombre (hasta 2 letras) para mostrar en avatares circulares estilo Apple.
    var initials: String {
        let components = fullName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        let result = String(components).uppercased()
        return result.isEmpty ? "?" : result
    }
}
