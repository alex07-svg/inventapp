import SwiftUI

/// Hoja modal que muestra y permite compartir la etiqueta de código QR única de un equipo.
struct EquipmentQRLabelSheet: View {
    let equipment: Equipment

    @Environment(\.dismiss) private var dismiss

    private var qrUIImage: UIImage? {
        QRCodeService.generateQRCode(from: equipment.qrPayload)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tarjeta estilo etiqueta imprimible
                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: equipment.category.symbolName)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(equipment.category.tintColor)
                                .frame(width: 38, height: 38)
                                .background(
                                    equipment.category.tintColor.opacity(0.14),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(equipment.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(equipment.brand)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        if let qrUIImage {
                            Image(uiImage: qrUIImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        }

                        VStack(spacing: 4) {
                            Text("N.° DE SERIE")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(equipment.serialNumber)
                                .font(.title3.monospaced().weight(.bold))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
                    )

                    Text("Escanea este código desde la pestaña Escanear para consultar el estado del equipo o gestionarlo al instante.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)

                    if let qrUIImage {
                        let shareImage = Image(uiImage: qrUIImage)
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview(
                                "QR \(equipment.name) (\(equipment.serialNumber))",
                                image: shareImage
                            )
                        ) {
                            Label("Compartir o imprimir QR", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Etiqueta QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
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
    return EquipmentQRLabelSheet(equipment: sampleEquipment)
}
