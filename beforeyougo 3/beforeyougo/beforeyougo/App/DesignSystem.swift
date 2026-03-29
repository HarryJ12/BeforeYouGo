import SwiftUI

// MARK: - Color Palette (Bevel-Inspired)
extension Color {
    // Primary
    static let byg_primary = Color(red: 0.29, green: 0.56, blue: 0.89)       // #4A90E2
    static let byg_primaryDark = Color(red: 0.20, green: 0.42, blue: 0.72)    // #336BB8
    
    // Accent
    static let byg_accent = Color(red: 0.49, green: 0.83, blue: 0.13)         // #7ED321
    static let byg_accentSoft = Color(red: 0.49, green: 0.83, blue: 0.13).opacity(0.15)
    
    // Status
    static let byg_caution = Color(red: 0.96, green: 0.65, blue: 0.14)        // #F5A623
    static let byg_urgent = Color(red: 0.82, green: 0.01, blue: 0.11)         // #D0021B
    static let byg_success = Color(red: 0.22, green: 0.78, blue: 0.46)        // #38C776
    
    // Backgrounds
    static let byg_background = Color(red: 0.97, green: 0.97, blue: 0.98)     // #F8F9FA
    static let byg_cardBg = Color.white
    static let byg_secondaryBg = Color(red: 0.94, green: 0.95, blue: 0.97)    // #F0F2F7
    
    // Text
    static let byg_textPrimary = Color(red: 0.13, green: 0.15, blue: 0.20)    // #212633
    static let byg_textSecondary = Color(red: 0.45, green: 0.49, blue: 0.56)  // #737D8F
    static let byg_textTertiary = Color(red: 0.68, green: 0.72, blue: 0.78)   // #ADB8C7
}

// MARK: - Card Modifier
struct BYGCardStyle: ViewModifier {
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.byg_cardBg)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func bygCard(padding: CGFloat = 16) -> some View {
        modifier(BYGCardStyle(padding: padding))
    }
}

// MARK: - Button Styles
struct BYGPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.byg_primary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct BYGSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.byg_primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.byg_primary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Section Header
struct BYGSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.byg_textPrimary)
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.byg_primary)
                }
            }
        }
    }
}
