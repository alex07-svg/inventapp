import SwiftData
import SwiftUI

/// Pestaña principal de Escáner QR.
/// - En un iPhone/iPad físico usa la cámara en vivo con VisionKit (`DataScannerViewController`).
/// - En el Simulador de Xcode (o si el usuario elige entrada manual) ofrece un modo de prueba interactivo
///   para simular escaneos de equipos existentes o nuevos sin necesidad de cámara física.
struct QRScannerView: View {
    @Query(sort: \Equipment.createdAt, order: .reverse)
    private var equipmentList: [Equipment]

    @State private var isScanning = true
    @State private var manualCodeInput = ""
    @State private var scannedSerial: String?
    @State private var matchedEquipment: Equipment?
    @State private var serialToRegister: String?

    private var supportsLiveScanner: Bool {
        QRCodeService.isLiveCameraScannerAvailable
    }

    var body: some View {
        NavigationStack {
            Group {
                if supportsLiveScanner {
                    liveCameraContent
                } else {
                    simulatorAndManualContent
                }
            }
            .navigationTitle("Escanear QR")
            .navigationDestination(item: $matchedEquipment) { equipment in
                EquipmentDetailView(equipment: equipment)
            }
            .sheet(item: Binding(
                get: { serialToRegister.map { ScannedSerialItem(serial: $0) } },
                set: { serialToRegister = $0?.serial }
            )) { item in
                EquipmentFormView(initialSerialNumber: item.serial)
            }
            .onChange(of: matchedEquipment) { _, newValue in
                if newValue == nil {
                    isScanning = true
                }
            }
            .onChange(of: serialToRegister) { _, newValue in
                if newValue == nil {
                    isScanning = true
                }
            }
        }
    }

    // MARK: - Modo 1: Cámara en vivo (iPhone / iPad físico)

    private var liveCameraContent: some View {
        ZStack {
            CameraQRScannerRepresentable(isScanning: $isScanning) { rawCode in
                handleScannedCode(rawCode)
            }
            .ignoresSafeArea(edges: .bottom)

            // Marco visual estilo Apple para guiar al usuario
            VStack {
                Spacer()

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 3, dash: [18, 10]))
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.35), radius: 8)

                Spacer()

                if let scannedSerial {
                    unregisteredResultCard(serial: scannedSerial)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                } else {
                    Label("Apunta al código QR o número de serie", systemImage: "qrcode.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 28)
                }
            }
        }
    }

    // MARK: - Modo 2: Simulador de Xcode / Entrada Manual

    private var simulatorAndManualContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Encabezado explicativo
                VStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 84, height: 84)
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Escáner QR")
                        .font(.title2.weight(.bold))

                    Text("La cámara en vivo se activa automáticamente en un iPhone o iPad real. Aquí puedes probar el flujo completo ingresando o simulando un código QR.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Tarjeta de entrada manual
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingresar o simular código")
                        .font(.headline)

                    HStack(spacing: 10) {
                        TextField("Ej. INVENTAPP:C02MBP202601", text: $manualCodeInput)
                            .font(.subheadline.monospaced())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onSubmit {
                                processManualInput()
                            }

                        Button("Buscar") {
                            processManualInput()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manualCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
                )

                // Resultado cuando el código escaneado NO existe aún en el inventario
                if let scannedSerial {
                    unregisteredResultCard(serial: scannedSerial)
                }

                // Pruebas rápidas con 1 toque (muy útil para aprender y probar en el Simulador)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pruebas Rápidas (Simulador)")
                        .font(.headline)

                    if let firstEquipment = equipmentList.first {
                        Button {
                            handleScannedCode(firstEquipment.qrPayload)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Simular equipo existente")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("\(firstEquipment.name) • \(firstEquipment.serialNumber)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        let suggested = InventoryViewModel.suggestedSerialNumber(for: .notebook)
                        handleScannedCode("INVENTAPP:\(suggested)")
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.viewfinder")
                                .font(.title3)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Simular código QR nuevo")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Prueba el flujo de alta rápida de un equipo no registrado")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
                )
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Tarjeta de resultado no encontrado

    private func unregisteredResultCard(serial: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Equipo no registrado", systemImage: "questionmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                Spacer()

                Button {
                    withAnimation(.snappy) {
                        scannedSerial = nil
                        isScanning = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("Número de serie detectado: **\(serial)**")
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)

            Button {
                serialToRegister = serial
                scannedSerial = nil
            } label: {
                Label("Registrar equipo con esta serie", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Lógica de procesamiento de códigos

    private func processManualInput() {
        handleScannedCode(manualCodeInput)
        manualCodeInput = ""
    }

    private func handleScannedCode(_ rawCode: String) {
        let serial = QRCodeService.parseSerialNumber(from: rawCode)
        guard !serial.isEmpty else { return }

        isScanning = false

        if let existing = equipmentList.first(where: { $0.serialNumber.uppercased() == serial }) {
            scannedSerial = nil
            matchedEquipment = existing
        } else {
            withAnimation(.snappy) {
                scannedSerial = serial
            }
        }
    }
}

/// Hoja modal compacta para escanear un número de serie directamente desde el formulario de nuevo equipo.
struct QRSerialScannerSheet: View {
    let onSerialCaptured: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isScanning = true
    @State private var manualInput = ""

    var body: some View {
        NavigationStack {
            Group {
                if QRCodeService.isLiveCameraScannerAvailable {
                    CameraQRScannerRepresentable(isScanning: $isScanning) { rawCode in
                        capture(rawCode)
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    Form {
                        Section {
                            TextField("Pega o escribe el código QR / serie", text: $manualInput)
                                .font(.body.monospaced())
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()

                            Button("Usar este código") {
                                capture(manualInput)
                            }
                            .disabled(manualInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        } header: {
                            Text("Modo Simulador")
                        } footer: {
                            Text("En un iPhone físico aquí se abrirá automáticamente la cámara para escanear la etiqueta del equipo.")
                        }
                    }
                }
            }
            .navigationTitle("Escanear Serie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func capture(_ rawCode: String) {
        let serial = QRCodeService.parseSerialNumber(from: rawCode)
        guard !serial.isEmpty else { return }
        isScanning = false
        onSerialCaptured(serial)
        dismiss()
    }
}

/// Envoltorio identificable para presentar `EquipmentFormView` con un número de serie escaneado.
private struct ScannedSerialItem: Identifiable {
    let id = UUID()
    let serial: String
}

#Preview(traits: .sampleData) {
    QRScannerView()
}
