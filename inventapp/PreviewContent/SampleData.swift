import SwiftData
import SwiftUI

/// Provee datos de ejemplo en memoria para las vistas previas (`#Preview`) de Xcode
/// y para probar la interfaz sin afectar los datos reales del dispositivo.
@MainActor
enum SampleData {
    /// Crea un contenedor de SwiftData temporal en memoria RAM con datos precargados.
    static func makePreviewContainer() throws -> ModelContainer {
        let schema = Schema([
            Equipment.self,
            Employee.self,
            AssignmentRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        populate(in: container.mainContext)
        return container
    }

    /// Inserta usuarios, equipos y registros de asignación de ejemplo en un `ModelContext`.
    static func populate(in context: ModelContext) {
        // 1. Usuarios de ejemplo
        let ana = Employee(
            fullName: "Ana Martínez",
            email: "ana.martinez@empresa.com",
            department: "Diseño de Producto"
        )
        let carlos = Employee(
            fullName: "Carlos Herrera",
            email: "carlos.herrera@empresa.com",
            department: "Ingeniería iOS"
        )
        let sofia = Employee(
            fullName: "Sofía Rojas",
            email: "sofia.rojas@empresa.com",
            department: "Operaciones TI"
        )

        [ana, carlos, sofia].forEach { context.insert($0) }

        // 2. Equipos de ejemplo (Notebooks, Monitores y Periféricos)
        let macbookPro = Equipment(
            serialNumber: "C02MBP202601",
            name: "MacBook Pro 14\" M4 Pro",
            brand: "Apple",
            modelName: "A3112",
            category: .notebook,
            status: .assigned,
            notes: "Incluye cargador MagSafe de 70W y funda.",
            assignedEmployee: carlos
        )

        let macbookAir = Equipment(
            serialNumber: "C02MBA202602",
            name: "MacBook Air 15\" M4",
            brand: "Apple",
            modelName: "A3241",
            category: .notebook,
            status: .available,
            notes: "Equipo nuevo listo para asignar."
        )

        let studioDisplay = Equipment(
            serialNumber: "APLSTD202603",
            name: "Apple Studio Display 27\"",
            brand: "Apple",
            modelName: "MK0U3",
            category: .monitor,
            status: .assigned,
            notes: "Vidrio estándar con soporte ajustable.",
            assignedEmployee: ana
        )

        let dellMonitor = Equipment(
            serialNumber: "DLU2723QE004",
            name: "Dell UltraSharp 27\" 4K",
            brand: "Dell",
            modelName: "U2723QE",
            category: .monitor,
            status: .available,
            notes: "Incluye cable USB-C de 90W."
        )

        let mxMaster = Equipment(
            serialNumber: "LOGMX3S00005",
            name: "Logitech MX Master 3S",
            brand: "Logitech",
            modelName: "910-006556",
            category: .peripheral,
            status: .assigned,
            notes: "Color grafito con receptor Logi Bolt.",
            assignedEmployee: carlos
        )

        let magicKeyboard = Equipment(
            serialNumber: "APLMKB202606",
            name: "Magic Keyboard con Touch ID",
            brand: "Apple",
            modelName: "MXCK3",
            category: .peripheral,
            status: .maintenance,
            notes: "En revisión por tecla de espacio."
        )

        let allEquipment = [
            macbookPro,
            macbookAir,
            studioDisplay,
            dellMonitor,
            mxMaster,
            magicKeyboard
        ]
        allEquipment.forEach { context.insert($0) }

        // 3. Registros históricos de asignación
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: .now) ?? .now
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: .now) ?? .now

        let record1 = AssignmentRecord(
            equipment: macbookPro,
            employee: carlos,
            assignedDate: twoWeeksAgo,
            notes: "Entrega inicial de estación de desarrollo."
        )
        let record2 = AssignmentRecord(
            equipment: studioDisplay,
            employee: ana,
            assignedDate: oneMonthAgo,
            notes: "Monitor asignado para escritorio de diseño."
        )
        let record3 = AssignmentRecord(
            equipment: mxMaster,
            employee: carlos,
            assignedDate: twoWeeksAgo,
            notes: "Periférico entregado junto al MacBook Pro."
        )

        [record1, record2, record3].forEach { context.insert($0) }
    }
}

/// Modificador reutilizable para inyectar datos de ejemplo en cualquier `#Preview` con una sola línea:
/// `#Preview(traits: .sampleData) { MiVista() }`
struct PreviewSampleData: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        try SampleData.makePreviewContainer()
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self {
        .modifier(PreviewSampleData())
    }
}
