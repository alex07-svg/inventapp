import Foundation
import SwiftData

/// Representa un equipo tecnológico físico registrado en el inventario.
/// La macro `@Model` le indica a SwiftData que esta clase se guardará en la base de datos local.
@Model
final class Equipment {
    /// Número de serie único del equipo. `@Attribute(.unique)` impide duplicados en la base de datos.
    @Attribute(.unique) var serialNumber: String

    /// Nombre descriptivo del equipo (ej. "MacBook Pro 14\" M4").
    var name: String

    /// Marca fabricante (ej. "Apple", "Dell", "Logitech").
    var brand: String

    /// Modelo técnico o referencia (ej. "A3112", "U2723QE").
    var modelName: String

    /// Almacenamos los valores crudos (`String`) para compatibilidad total con consultas `#Predicate` de SwiftData.
    var categoryRawValue: String
    var statusRawValue: String

    /// Notas adicionales (estado físico, accesorios incluidos, garantía, etc.).
    var notes: String

    /// Fecha en que se dio de alta el equipo en el inventario.
    var createdAt: Date

    /// Usuario que actualmente tiene asignado este equipo (`nil` si está disponible).
    var assignedEmployee: Employee?

    /// Historial completo de entregas y devoluciones de este equipo.
    /// `.cascade` borra el historial automáticamente si el equipo se elimina del sistema.
    @Relationship(deleteRule: .cascade, inverse: \AssignmentRecord.equipment)
    var assignmentHistory: [AssignmentRecord] = []

    init(
        serialNumber: String,
        name: String,
        brand: String,
        modelName: String = "",
        category: EquipmentCategory,
        status: EquipmentStatus = .available,
        notes: String = "",
        createdAt: Date = .now,
        assignedEmployee: Employee? = nil
    ) {
        self.serialNumber = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        self.modelName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.categoryRawValue = category.rawValue
        self.statusRawValue = status.rawValue
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.assignedEmployee = assignedEmployee
    }

    // MARK: - Propiedades computadas (acceso seguro a los enums)

    /// Categoría tipada del equipo.
    var category: EquipmentCategory {
        get { EquipmentCategory(rawValue: categoryRawValue) ?? .peripheral }
        set { categoryRawValue = newValue.rawValue }
    }

    /// Estado operativo tipado del equipo.
    var status: EquipmentStatus {
        get { EquipmentStatus(rawValue: statusRawValue) ?? .available }
        set { statusRawValue = newValue.rawValue }
    }

    /// Indica si el equipo está libre para ser asignado.
    var isAvailable: Bool {
        status == .available
    }

    /// Indica si el equipo está actualmente entregado a un usuario.
    var isAssigned: Bool {
        status == .assigned
    }

    /// Contenido estandarizado para generar y leer códigos QR de etiquetas de inventario.
    var qrPayload: String {
        "INVENTAPP:\(serialNumber)"
    }
}
