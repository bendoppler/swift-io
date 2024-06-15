import AppKit

func *(l: CGFloat, r: CGPoint) -> CGPoint {
    return CGPoint(x: l * r.x, y: l * r.y)
}

extension CGRect {
    init(center: CGPoint, radius: CGFloat) {
        self.init(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}

public class PointsView: NSView {
    public struct Data {
        var s1: CGPoint = .zero
        var s2: CGPoint = .zero
        var p: CGPoint = .zero
        var c: CGPoint = .zero
    }
    var data: Data = Data() { didSet { setNeedsDisplay(bounds) } }
    
    public init(s1: CGPoint, s2: CGPoint, p: CGPoint, c: CGPoint) {
        self.data = Data(s1: s1, s2: s2, p: p, c: c)
        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 300))
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.setFillColor(.white)
        ctx.fill(bounds)
        ctx.setStrokeColor(NSColor.lightGray.cgColor)
        ctx.setLineWidth(1)
        let factor: CGFloat = 50
        for x in stride(from: bounds.minX, to: bounds.maxX, by: factor) {
            ctx.addLines(between: [CGPoint(x: x, y: bounds.minY), CGPoint(x: x, y: bounds.maxY)])
        }
        for y in stride(from: bounds.minY, to: bounds.maxY, by: factor) {
            ctx.addLines(between: [CGPoint(x: bounds.minX, y: y), CGPoint(x: bounds.maxX, y: y)])
        }
        ctx.strokePath()
        
        func draw(point: CGPoint, color: NSColor) {
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(center: factor * point, radius: 10))
        }
        
        func drawLine(from: CGPoint, to: CGPoint) {
            ctx.setStrokeColor(.black)
            ctx.addLines(between: [factor * from, factor * to])
            ctx.strokePath()
        }
        drawLine(from: data.s1, to: data.s2)
        drawLine(from: data.p, to: data.c)
        draw(point: data.s1, color: .red)
        draw(point: data.s2, color: .red)
        draw(point: data.c, color: .green)
        draw(point: data.p, color: .blue)
    }
}


