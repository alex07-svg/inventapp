import SwiftUI

/// Tarjeta de métrica estilo Apple (inspirada en las apps Recordatorios y Salud).
/// Muestra un ícono con fondo suave, un contador destacado y un título descriptivo.
struct StatCardView: View {
    let title: String
    let value: Int
    let subtitle: String
    let symbolName: String
    let tintColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tintColor)
                    .frame(width: 38, height: 38)
                    .background(tintColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                Spacer()

                Text("\(value)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
        )
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCardView(
            title: "Disponibles",
            value: 12,
            subtitle: "Listos para asignar",
            symbolName: "checkmark.circle.fill",
            tintColor: .green
        )
        StatCardView(
            title: "Entregados",
            value: 18,
            subtitle: "En uso activo",
            symbolName: "person.crop.circle.badge.checkmark",
            tintColor: .blue
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
