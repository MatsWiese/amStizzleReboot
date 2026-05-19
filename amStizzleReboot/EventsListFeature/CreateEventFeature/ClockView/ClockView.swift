import SwiftUI
import Foundation

struct ClockView: View {
    @Binding var duration: TimeInterval
    let startTime: Date
    @State private var dragHours: Int? = nil
    @State private var lastDragAngle: Double? = nil

    private let ringInsetStep: CGFloat = 6
    private let baseRotation = -Double.pi / 2

    private var totalMinutes: Int {
        max(0, Int(duration) / 60)
    }

    private var hours: Int {
        totalMinutes / 60
    }

    private var minutes: Int {
        totalMinutes % 60
    }

    private var startFraction: Double {
        let minute = Calendar.current.component(.minute, from: startTime)
        return Double(minute) / 60
    }

    private var durationLabel: String {
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2

            ZStack {
                backgroundCircle
                spiralSegments(in: size, center: center, outerRadius: radius * 0.92)
                ClockTicks()

                handle(in: center, outerRadius: radius * 0.92)

                Text(durationLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .contentShape(Circle())
            .gesture(dragGesture(center: center))
        }
//        .padding(8)
    }

    private var backgroundCircle: some View {
        Circle()
            .stroke(.secondary.opacity(0.2), lineWidth: 8)
    }

    private func spiralSegments(in size: CGSize, center: CGPoint, outerRadius: CGFloat) -> some View {
        let maxTurns = max(1, Int((outerRadius - 12) / ringInsetStep))
        let totalTurnsRaw = Double(totalMinutes) / 60
        let totalTurns = min(totalTurnsRaw, Double(maxTurns))
        guard totalTurns > 0 else { return AnyView(EmptyView()) }

        let completedTurnsRaw = Int(floor(totalTurnsRaw))
        let activeFraction = totalTurnsRaw - Double(completedTurnsRaw)
        let hasActive = activeFraction > 0
        let visibleCompleted = min(completedTurnsRaw, max(0, maxTurns - (hasActive ? 1 : 0)))
        let startIndex = max(0, completedTurnsRaw - visibleCompleted)
        let activeOffset = hasActive ? 1 : 0

        return AnyView(
            ZStack {
                ForEach(0..<visibleCompleted, id: \.self) { slot in
                    let turnIndex = startIndex + slot
                    let depthFromOuter = (visibleCompleted - 1 - slot) + activeOffset
                    let startAngle = startAngleBase + (Double(turnIndex) * 2 * Double.pi)
                    let endAngle = startAngleBase + (Double(turnIndex + 1) * 2 * Double.pi)
                    let startRadius = outerRadius - (CGFloat(totalTurnsRaw - Double(turnIndex)) * ringInsetStep)
                    let endRadius = outerRadius - (CGFloat(totalTurnsRaw - Double(turnIndex + 1)) * ringInsetStep)

                    spiralPath(
                        center: center,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        startRadius: startRadius,
                        endRadius: endRadius
                    )
                    .stroke(ringColor(for: turnIndex), lineWidth: lineWidth(forDepth: depthFromOuter))
                }

                if hasActive {
                    let turnIndex = completedTurnsRaw
                    let startAngle = startAngleBase + (Double(turnIndex) * 2 * Double.pi)
                    let endAngle = startAngleBase + ((Double(turnIndex) + activeFraction) * 2 * Double.pi)
                    let startRadius = outerRadius - (CGFloat(activeFraction) * ringInsetStep)

                    spiralPath(
                        center: center,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        startRadius: startRadius,
                        endRadius: outerRadius
                    )
                    .stroke(ringColor(for: turnIndex), lineWidth: lineWidth(forDepth: 0))
                }
            }
        )
    }

    private func spiralPath(
        center: CGPoint,
        startAngle: Double,
        endAngle: Double,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) -> Path {
        let delta = endAngle - startAngle
        let steps = max(4, Int(abs(delta) / (Double.pi / 30)))

        var path = Path()
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let angle = startAngle + (delta * t)
            let radius = startRadius + (endRadius - startRadius) * CGFloat(t)
            let point = CGPoint(
                x: center.x + CGFloat(Foundation.cos(angle)) * radius,
                y: center.y + CGFloat(Foundation.sin(angle)) * radius
            )

            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }

    private var startAngleBase: Double {
        baseRotation + (startFraction * 2 * Double.pi)
    }

    private func ringColor(for index: Int) -> Color {
      let colors: [Color] = [.cyan, .orange, .green, .red, .blue, .purple]
        return colors[index % colors.count]
    }

    private func lineWidth(forDepth depth: Int) -> CGFloat {
        let base: CGFloat = 6
        let step: CGFloat = 0.8
        return max(2, base - (CGFloat(max(0, depth)) * step))
    }

    private func handle(in center: CGPoint, outerRadius: CGFloat) -> some View {
        let totalTurns = Double(totalMinutes) / 60
        let endAngle = startAngleBase + (totalTurns * 2 * Double.pi)
        let handlePoint = CGPoint(
            x: center.x + CGFloat(Foundation.cos(endAngle)) * outerRadius,
            y: center.y + CGFloat(Foundation.sin(endAngle)) * outerRadius
        )

        let activeIndex = Int(floor(totalTurns))

        return Circle()
            .fill(ringColor(for: activeIndex))
            .frame(width: 12, height: 12)
            .position(handlePoint)
            .shadow(radius: 2)
    }

    private func dragGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let angle = angleForPoint(value.location, center: center)
                var newHours = dragHours ?? hours

                let previousAngle = lastDragAngle
                var crossedBackward = false
                if let previousAngle {
                    let boundary = (baseRotationNormalized + (startFraction * 2 * Double.pi))
                        .truncatingRemainder(dividingBy: 2 * Double.pi)
                    let previousShifted = shiftedAngle(previousAngle, boundary: boundary)
                    let currentShifted = shiftedAngle(angle, boundary: boundary)

                    if previousShifted > (Double.pi * 1.75) && currentShifted < (Double.pi * 0.25) {
                        newHours += 1
                    } else if previousShifted < (Double.pi * 0.25) && currentShifted > (Double.pi * 1.75) {
                        crossedBackward = true
                        newHours = max(0, newHours - 1)
                    }
                }

                lastDragAngle = angle
                dragHours = newHours

                var newMinutes = minutesForAngle(angle)
                if newHours == 0 && crossedBackward {
                    newMinutes = 0
                }

                let newDuration = TimeInterval((newHours * 60 + newMinutes) * 60)
                duration = max(0, newDuration)
            }
            .onEnded { _ in
                dragHours = nil
                lastDragAngle = nil
            }
    }

    private var baseRotationNormalized: Double {
        baseRotation < 0 ? baseRotation + (2 * Double.pi) : baseRotation
    }

    private func angleForPoint(_ point: CGPoint, center: CGPoint) -> Double {
        let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
        var angle = atan2(vector.dy, vector.dx)
        if angle < 0 { angle += 2 * Double.pi }
        return angle
    }

    private func shiftedAngle(_ angle: Double, boundary: Double) -> Double {
        let shifted = angle - boundary
        return shifted < 0 ? shifted + (2 * Double.pi) : shifted
    }

    private func minutesForAngle(_ angle: Double) -> Int {
        let boundary = (baseRotationNormalized + (startFraction * 2 * Double.pi))
            .truncatingRemainder(dividingBy: 2 * Double.pi)
        let delta = shiftedAngle(angle, boundary: boundary) / (2 * Double.pi)
        let rawMinutes = Int(floor(delta * 60))
        return min(59, max(0, rawMinutes))
    }
}

struct ClockTicks: View {
    var body: some View {
        GeometryReader { proxy in
            tickPath(in: proxy.size)
                .stroke(.secondary.opacity(0.6), lineWidth: 2)
        }
    }

    private func tickPath(in size: CGSize) -> Path {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2
        let tickInner = radius * 0.78
        let tickOuter = radius * 0.92

        var path = Path()
        for minute in stride(from: 0, to: 60, by: 5) {
            let angle = (Double(minute) / 60) * (2 * Double.pi) - (Double.pi / 2)
            let innerPoint = CGPoint(
                x: center.x + CGFloat(Foundation.cos(angle)) * tickInner,
                y: center.y + CGFloat(Foundation.sin(angle)) * tickInner
            )
            let outerPoint = CGPoint(
                x: center.x + CGFloat(Foundation.cos(angle)) * tickOuter,
                y: center.y + CGFloat(Foundation.sin(angle)) * tickOuter
            )

            path.move(to: innerPoint)
            path.addLine(to: outerPoint)
        }
        return path
    }
}

#Preview {
  PreviewContainer()
}

private struct PreviewContainer: View {
    let startTime = Date.now
    @State private var duration: TimeInterval = 3600

    var body: some View {
        ClockView(
          duration: $duration, startTime: startTime
        )
    }
}
