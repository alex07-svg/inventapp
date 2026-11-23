import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import Vision
import VisionKit

/// Servicio centralizado para:
/// 1. Interpretar códigos QR/barras escaneados y extraer el número de serie.
/// 2. Generar imágenes de códigos QR nítidas con CoreImage (sin librerías externas).
/// 3. Consultar si el dispositivo físico soporta escaneo en vivo con cámara.
enum QRCodeService {
    private static let payloadPrefix = "INVENTAPP:"

    /// Indica si el dispositivo actual (por ejemplo un iPhone físico con cámara autorizada)
    /// puede usar el escáner en vivo de VisionKit. En el Simulador de Xcode devolverá `false`.
    @MainActor
    static var isLiveCameraScannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    /// Extrae y normaliza el número de serie desde un código QR de InventApp (`INVENTAPP:C02...`)
    /// o desde una etiqueta estándar del fabricante (`C02...`).
    static func parseSerialNumber(from rawCode: String) -> String {
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let uppercased = trimmed.uppercased()

        if uppercased.hasPrefix(payloadPrefix) {
            return String(uppercased.dropFirst(payloadPrefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return uppercased
    }

    /// Genera una imagen `UIImage` nítida de un código QR a partir de un texto usando `CoreImage`.
    static func generateQRCode(from text: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Escalamos la matriz de píxeles sin difuminar para que el QR sea perfectamente legible al imprimir.
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

/// Puente (`UIViewControllerRepresentable`) que integra `DataScannerViewController` de Apple (VisionKit)
/// dentro de una vista de SwiftUI para escanear códigos QR y códigos de barras en tiempo real.
struct CameraQRScannerRepresentable: UIViewControllerRepresentable {
    /// Controla si el escáner está activo o pausado (pausamos brevemente al leer un código).
    @Binding var isScanning: Bool

    /// Callback que se ejecuta en cuanto la cámara reconoce un código QR o de barras.
    let onCodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.qr, .code128, .code39, .ean13])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            if !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        } else {
            if uiViewController.isScanning {
                uiViewController.stopScanning()
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    /// Coordinador que recibe los eventos del delegado de VisionKit y los comunica a SwiftUI.
    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            handle(items: addedItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            handle(items: [item])
        }

        private func handle(items: [RecognizedItem]) {
            for item in items {
                if case .barcode(let barcode) = item,
                   let payload = barcode.payloadStringValue,
                   !payload.isEmpty {
                    onCodeScanned(payload)
                    return
                }
            }
        }
    }
}
