import SwiftUI

/// Avatar circular con las iniciales de un usuario, inspirado en Apple Contactos.
struct EmployeeAvatarView: View {
    let initials: String
    var size: CGFloat = 42
    var tintColor: Color = .blue

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(tintColor)
            .frame(width: size, height: size)
            .background(tintColor.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        EmployeeAvatarView(initials: "AM", size: 40, tintColor: .blue)
        EmployeeAvatarView(initials: "CH", size: 56, tintColor: .indigo)
    }
    .padding()
}
