//
//  Diagrams.swift
//  EnumBased
//
//  Created by Chris Eidhof on 01.02.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Foundation

public protocol Diagram {
    static func rectangle(_ rect: CGRect, _ color: NSColor) -> Self
    static func ellipse(in rect: CGRect, _ color: NSColor) -> Self
    static func combined(_ d1: Self, _ d2: Self) -> Self
}

public struct ContextRenderer {
    public let draw: (CGContext) -> ()
}

extension ContextRenderer: Diagram {

    static public func rectangle(_ rect: CGRect, _ color: NSColor) -> ContextRenderer {
        return ContextRenderer { context in
            context.saveGState()
            context.setFillColor(color.cgColor)
            context.fill(rect)
            context.restoreGState()
        }
    }

    static public func ellipse(in rect: CGRect, _ color: NSColor) -> ContextRenderer {
        return ContextRenderer { context in
            context.saveGState()
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect)
            context.restoreGState()
        }
    }

    static public func combined(_ d1: ContextRenderer, _ d2: ContextRenderer) -> ContextRenderer {
        return ContextRenderer { context in
            context.saveGState()
            d1.draw(context)
            d2.draw(context)
            context.restoreGState()
        }
    }


}

//extension Diagram {
//    public func draw(_ context: CGContext) {
//        context.saveGState()
//        switch self {
//        case let .rectangle(rect, color):
//            context.setFillColor(color.cgColor)
//            context.fill(rect)
//        case let .ellipse(rect, color):
//            context.setFillColor(color.cgColor)
//            context.fillEllipse(in: rect)
//        case let .combined(d1, d2):
//            d1.draw(context)
//            d2.draw(context)
//        case let .alpha(alpha, d):
//            context.setAlpha(alpha)
//            d.draw(context)
//        }
//        context.restoreGState()
//    }
//}
