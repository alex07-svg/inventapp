import SwiftUI

/// Estado operativo actual de un equipo en el inventario.
enum EquipmentStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case available
    case assigned
    case maintenance

    var id: String { rawValue }

    /// Etiqueta visible para el usuario.
    var displayName: String {
        switch self {
        case .available:
            return "Disponible"
        case .assigned:
            return "Entregado"
        case .maintenance:
            return "Mantenimiento"
        }
    }

    /// Ícono de SF Symbols que refuerza visualmente el estado.
    var symbolName: String {
        switch self {
        case .available:
            return "checkmark.circle.fill"
        case .assigned:
            return "person.crop.circle.badge.checkmark"
        case .maintenance:
            return "wrench.and.screwdriver.fill"
        }
    }

    /// Color semántico estilo Apple para etiquetas e indicadores.
    var tintColor: Color {
        switch self {
        case .available:
            return .green
        case .assigned:
            return .blue
        case .maintenance:
            return .orange
        }
    }
}
