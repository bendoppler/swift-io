//
//  Helpers.swift
//  RenderMarkdown
//
//  Created by Florian Kugler on 01-03-2018.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Foundation

extension Array where Element: NSAttributedString {
    func join(separator: String = "") -> NSAttributedString {
        guard !isEmpty else { return NSAttributedString() }
        let result = self[0].mutableCopy() as! NSMutableAttributedString
        for element in self[1...] {
            result.append(NSAttributedString(string: separator))
            result.append(element)
        }
        return result
    }
}


