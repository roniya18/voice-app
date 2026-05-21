import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    var color: Color = .blue.opacity(0.3)
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 2
    var minHeight: CGFloat = 3
    var animated: Bool = true

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let total = samples.count
                guard total > 1 else { return }

                let path = Path { p in
                    for (i, sample) in samples.enumerated() {
                        let x = size.width * CGFloat(i) / CGFloat(total - 1)
                        let amplitude = CGFloat(sample) * size.height
                        let y = size.height - amplitude

                        if i == 0 {
                            p.move(to: CGPoint(x: x, y: y))
                        } else {
                            let prevX = size.width * CGFloat(i - 1) / CGFloat(total - 1)
                            let prevSample = CGFloat(samples[i - 1]) * size.height
                            let prevY = size.height - prevSample
                            let cpX = (prevX + x) / 2
                            p.addCurve(
                                to: CGPoint(x: x, y: y),
                                control1: CGPoint(x: cpX, y: prevY),
                                control2: CGPoint(x: cpX, y: y)
                            )
                        }
                    }
                }

                // Filled area beneath the wave
                let filledPath = Path { p in
                    p.addPath(path)
                    p.addLine(to: CGPoint(x: size.width, y: size.height))
                    p.addLine(to: CGPoint(x: 0, y: size.height))
                    p.closeSubpath()
                }
                context.fill(filledPath, with: .color(color))
            }
        }
    }
}

