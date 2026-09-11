import SwiftUI

/// Cherry-blossom paper. Names come from the garden, not a gray ramp.
struct Palette {
    let washi: Color
    let washiInset: Color
    let row: Color
    let bark: Color
    let barkSoft: Color
    let muted: Color
    let petal: Color
    let petalDeep: Color
    let petalPale: Color
    let pistil: Color
    let branch: Color
    let over: Color
    let hairline: Color
    let focus: Color

    static func current(_ scheme: ColorScheme) -> Palette {
        switch scheme {
        case .dark:
            return Palette(
                washi: Color(hex: 0x1A1216),
                washiInset: Color(hex: 0x140E11),
                row: Color(hex: 0x241A1F),
                bark: Color(hex: 0xF7EDE8),
                barkSoft: Color(hex: 0xD4C0C4),
                muted: Color(hex: 0xC4A8AE),
                petal: Color(hex: 0xE8A4B8),
                petalDeep: Color(hex: 0xF0B8C6),
                petalPale: Color(hex: 0x5A3340),
                pistil: Color(hex: 0xD4B896),
                branch: Color(hex: 0xC4A49C),
                over: Color(hex: 0xF0A0B4),
                hairline: Color.white.opacity(0.10),
                focus: Color(hex: 0xE8A4B8)
            )
        default:
            return Palette(
                washi: Color(hex: 0xFBF6F1),
                washiInset: Color(hex: 0xF3E8E4),
                row: Color(hex: 0xF7EEE9),
                bark: Color(hex: 0x2C1F24),
                barkSoft: Color(hex: 0x5C444C),
                muted: Color(hex: 0x6E5359),
                petal: Color(hex: 0xE8A4B8),
                petalDeep: Color(hex: 0xC45C7A),
                petalPale: Color(hex: 0xF7D6E0),
                pistil: Color(hex: 0xC4A574),
                branch: Color(hex: 0x6B4A42),
                over: Color(hex: 0x7A2E44),
                hairline: Color.black.opacity(0.10),
                focus: Color(hex: 0xC45C7A)
            )
        }
    }
}

enum Typeface {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func label(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

enum Space {
    static let unit: CGFloat = 4
    static let micro: CGFloat = 4
    static let tight: CGFloat = 8
    static let row: CGFloat = 12
    static let section: CGFloat = 16
    static let popoverWidth: CGFloat = 308
}

enum Radius {
    static let chip: CGFloat = 8
    static let row: CGFloat = 12
    static let bloom: CGFloat = 20
}

enum Motion {
    static let press: Double = 0.14
    static let appear: Double = 0.22
    static let stagger: Double = 0.04
    static let ease = Animation.timingCurve(0.23, 1, 0.32, 1, duration: appear)
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.current(.light)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension View {
    func sakuraPalette(_ scheme: ColorScheme) -> some View {
        environment(\.palette, Palette.current(scheme))
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
