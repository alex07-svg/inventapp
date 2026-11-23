import SwiftUI

/// Etiqueta tipo cápsula que muestra el estado actual de un equipo
/// con su ícono de SF Symbols y color semántico estilo Apple.
struct StatusBadgeView: View {
    let status: EquipmentStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbolName)
                .font(.caption2.weight(.semibold))
            Text(status.displayName)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(status.tintColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.tintColor.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(EquipmentStatus.allCases) { status in
            StatusBadgeView(status: status)
        }
    }
    .padding()
}
