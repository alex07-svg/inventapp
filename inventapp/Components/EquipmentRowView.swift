import SwiftUI

/// Fila reutilizable para mostrar un equipo en listas y en el resumen del Dashboard.
struct EquipmentRowView: View {
    let equipment: Equipment

    var body: some View {
        HStack(spacing: 14) {
            // Ícono de categoría con fondo suave redondeado
            Image(systemName: equipment.category.symbolName)
                .font(.title3.weight(.medium))
                .foregroundStyle(equipment.category.tintColor)
                .frame(width: 44, height: 44)
                .background(
                    equipment.category.tintColor.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )

            // Información principal del equipo
            VStack(alignment: .leading, spacing: 3) {
                Text(equipment.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(equipment.brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    // Tipografía monoespaciada para facilitar la lectura de números de serie
                    Text(equipment.serialNumber)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let employee = equipment.assignedEmployee {
                    Label(employee.fullName, systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Indicador de estado
            StatusBadgeView(status: equipment.status)
        }
        .padding(.vertical, 4)
    }
}

#Preview(traits: .sampleData) {
    let sampleEquipment = Equipment(
        serialNumber: "C02MBP202601",
        name: "MacBook Pro 14\" M4 Pro",
        brand: "Apple",
        modelName: "A3112",
        category: .notebook,
        status: .available
    )
    return EquipmentRowView(equipment: sampleEquipment)
        .padding()
}
