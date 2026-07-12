import SwiftUI

/// A classic 5-point tone curve editor — each point's input position is
/// fixed (0/0.25/0.5/0.75/1, matching `CIToneCurve`'s five control
/// points); dragging only moves a point's output value up/down. Locking
/// the x-position is deliberate: letting a point drag freely in both
/// directions could let two points cross over each other and produce a
/// curve that folds back on itself, which would look like a bug rather
/// than a creative choice.
struct CurveEditorView: View {
    @Binding var points: [Double]

    private static let xPositions: [Double] = [0, 0.25, 0.5, 0.75, 1]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: 0))
                }
                .stroke(PBColor.line, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                Path { path in
                    let coords = coordinates(in: size)
                    path.move(to: coords[0])
                    for coord in coords.dropFirst() {
                        path.addLine(to: coord)
                    }
                }
                .stroke(PBColor.accent, lineWidth: 2)

                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(PBColor.accentGradient)
                        .frame(width: 16, height: 16)
                        .position(coordinate(for: index, in: size))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = 1 - (value.location.y / size.height)
                                    points[index] = min(1, max(0, newValue))
                                }
                        )
                }
            }
        }
        .frame(height: 180)
        .background(PBColor.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(PBColor.line, lineWidth: 1)
        )
    }

    /// Graph coordinates have Y growing downward, but a curve's output of
    /// 1 (brightest) should sit at the *top* — hence `1 - value`.
    private func coordinate(for index: Int, in size: CGSize) -> CGPoint {
        CGPoint(x: Self.xPositions[index] * size.width, y: (1 - points[index]) * size.height)
    }

    private func coordinates(in size: CGSize) -> [CGPoint] {
        points.indices.map { coordinate(for: $0, in: size) }
    }
}

#Preview {
    CurveEditorView(points: .constant(PhotoAdjustments.identityCurve))
        .padding()
        .background(PBColor.background)
}
