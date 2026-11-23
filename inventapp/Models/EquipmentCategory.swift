import SwiftUI

/// Categorías de equipos tecnológicos soportadas por el inventario.
/// Usar un `enum` evita errores de escritura y garantiza solo valores válidos.
enum EquipmentCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case notebook
    case monitor
    case peripheral

    /// Identificador único requerido por SwiftUI para iterar en `ForEach` o `Picker`.
    var id: String { rawValue }

    /// Nombre legible en singular para mostrar en la interfaz.
    var displayName: String {
        switch self {
        case .notebook:
            return "Notebook"
        case .monitor:
            return "Monitor"
        case .peripheral:
            return "Periférico"
        }
    }

    /// Nombre legible en plural para títulos o filtros.
    var pluralName: String {
        switch self {
        case .notebook:
            return "Notebooks"
        case .monitor:
            return "Monitores"
        case .peripheral:
            return "Periféricos"
        }
    }

    /// Ícono oficial de SF Symbols asociado a cada categoría.
    var symbolName: String {
        switch self {
        case .notebook:
            return "laptopcomputer"
        case .monitor:
            return "display"
        case .peripheral:
            return "keyboard"
        }
    }

    /// Color semántico para identificar rápidamente la categoría en la interfaz.
    var tintColor: Color {
        switch self {
        case .notebook:
            return .blue
        case .monitor:
            return .purple
        case .peripheral:
            return .teal
        }
    }
}
