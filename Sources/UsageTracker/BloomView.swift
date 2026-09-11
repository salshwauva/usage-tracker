import SwiftUI
import UsageTrackerCore

/// Five petals, one per share of the weekly hour budget.
/// Default budget is 5 hours, so each petal is one hour. If the budget
/// changes, each petal is still an equal slice.
struct BloomView: View {
    var budget: WeeklyBudget
    var size: CGFloat
    var showsPistil: Bool = true

    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2
            let fills = budget.petalFills()
            let petalCount = fills.count
            let petalLength = radius * 0.92
            let petalWidth = radius * 0.62
            let fillColor = budget.isOver ? palette.over : palette.petal

            for (index, fill) in fills.enumerated() {
                let angle = Angle.degrees(Double(index) / Double(petalCount) * 360 - 90)
                var petal = petalPath(center: center, length: petalLength, width: petalWidth)
                let transform = CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: CGFloat(angle.radians))
                    .translatedBy(x: -center.x, y: -center.y)
                petal = petal.applying(transform)

                context.fill(petal, with: .color(palette.petalPale))

                if fill > 0 {
                    var filled = context
                    filled.clip(to: petal)
                    let r = radius * 0.18 + petalLength * fill
                    let disk = Path(ellipseIn: CGRect(
                        x: center.x - r,
                        y: center.y - r,
                        width: r * 2,
                        height: r * 2
                    ))
                    filled.fill(disk, with: .color(fillColor))
                }

                context.stroke(
                    petal,
                    with: .color(palette.petalDeep.opacity(0.40)),
                    lineWidth: size < 28 ? 0.6 : 1
                )
            }

            if showsPistil {
                let pistilRadius = max(radius * 0.16, 1.5)
                let pistil = Path(ellipseIn: CGRect(
                    x: center.x - pistilRadius,
                    y: center.y - pistilRadius,
                    width: pistilRadius * 2,
                    height: pistilRadius * 2
                ))
                context.fill(pistil, with: .color(palette.pistil))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func petalPath(center: CGPoint, length: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        let base = CGPoint(x: center.x, y: center.y)
        let tip = CGPoint(x: center.x, y: center.y - length)
        let left = CGPoint(x: center.x - width / 2, y: center.y - length * 0.42)
        let right = CGPoint(x: center.x + width / 2, y: center.y - length * 0.42)
        path.move(to: base)
        path.addQuadCurve(to: tip, control: left)
        path.addQuadCurve(to: base, control: right)
        path.closeSubpath()
        return path
    }
}

struct MiniBloom: View {
    var fraction: Double?
    var over: Bool = false

    @Environment(\.palette) private var palette

    var body: some View {
        let fill = fraction ?? 0
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            for i in 0..<5 {
                let angle = Angle.degrees(Double(i) / 5 * 360 - 90)
                let tip = CGPoint(
                    x: center.x + cos(angle.radians) * radius * 0.9,
                    y: center.y + sin(angle.radians) * radius * 0.9
                )
                var path = Path()
                path.move(to: center)
                let left = CGPoint(
                    x: center.x + cos(angle.radians - 0.45) * radius * 0.45,
                    y: center.y + sin(angle.radians - 0.45) * radius * 0.45
                )
                let right = CGPoint(
                    x: center.x + cos(angle.radians + 0.45) * radius * 0.45,
                    y: center.y + sin(angle.radians + 0.45) * radius * 0.45
                )
                path.addQuadCurve(to: tip, control: left)
                path.addQuadCurve(to: center, control: right)
                let petalShare = min(max(fill * 5 - Double(i), 0), 1)
                let color = petalShare > 0.15
                    ? (over ? palette.over : palette.petal)
                    : palette.petalPale
                context.fill(path, with: .color(color))
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}
