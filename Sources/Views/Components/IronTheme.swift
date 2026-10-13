import SwiftUI

enum IronTheme {
    static let ember = Color(red: 1, green: 0.43, blue: 0.22)
    static let mint = Color(red: 0.70, green: 0.94, blue: 0.44)
    static let canvas = Color(red: 0.025, green: 0.03, blue: 0.04)
    static let surface = Color(red: 0.08, green: 0.09, blue: 0.11)

    static func weight(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    static func estimate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    static func week(_ number: Int) -> String {
        switch number {
        case 1: return "5s week"
        case 2: return "3s week"
        case 3: return "5/3/1 week"
        case 4: return "Deload"
        default: return "Training"
        }
    }
}

struct IronButtonStyle: ButtonStyle {
    var accent: Color = IronTheme.mint
    var secondary = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundStyle(secondary ? Color.white : Color.black)
            .background(secondary ? IronTheme.surface : accent, in: RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(secondary ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IronCard: ViewModifier {
    var accent: Color = .white

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 17)
                    .fill(LinearGradient(
                        colors: [accent.opacity(0.10), IronTheme.surface],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .strokeBorder(accent.opacity(0.16), lineWidth: 1)
            }
    }
}

struct IronEyebrow: View {
    let text: String
    var color: Color = .secondary

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(1)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct IronMetric: View {
    let title: String
    let value: String
    var unit: String = ""
    var accent: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            IronEyebrow(text: title)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(accent)
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
