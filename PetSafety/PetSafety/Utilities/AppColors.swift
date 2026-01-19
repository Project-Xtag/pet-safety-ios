import SwiftUI
import UIKit

// MARK: - Design System Colors
// Note: Colors are auto-generated from Assets catalog as:
// - Color.brandColor (orange #FF914D)
// - Color.tealAccent (teal #6FB2B2)
// - Color.peachBackground (peach #FDEDD8)
// - Color.cardBackground
// - Color.mutedText (gray #737373)

// Convenience aliases for cleaner code
extension Color {
    static var brandOrange: Color { Color("BrandColor") }
}

// MARK: - Button Styles
struct BrandButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isDisabled
                    ? Color.brandOrange.opacity(0.5)
                    : (configuration.isPressed ? Color.brandOrange.opacity(0.8) : Color.brandOrange)
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .bold))
            .cornerRadius(16)
            .shadow(color: Color.brandOrange.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed
                    ? Color(UIColor.systemGray5)
                    : Color(UIColor.systemBackground)
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .semibold))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Text Field Styles
struct BrandTextFieldStyle: TextFieldStyle {
    var icon: String? = nil

    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.mutedText)
                    .frame(width: 20)
            }
            configuration
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(UIColor.systemGray4).opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - View Modifiers
struct PeachHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.peachBackground)
    }
}

extension View {
    func peachHeader() -> some View {
        modifier(PeachHeaderModifier())
    }
}
