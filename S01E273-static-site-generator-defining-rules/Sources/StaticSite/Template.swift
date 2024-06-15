//
//  File.swift
//  
//
//  Created by Do Thai Bao on 25/03/2023.
//

import Foundation
import Swim

protocol Template {
    func apply(content: Node) -> Node
}

enum TemplateKey: EnvironmentKey {
    static var defaultValue: [Template] = []
}

extension EnvironmentValues {
    var template: [Template] {
        get { self[TemplateKey.self] }
        set { self[TemplateKey.self] = newValue }
    }
}

extension Rule {
    func wrap<T: Template>(_ t: T) -> some Rule {
        EnvironmentWritingModifier(content: self) { values in
            values.template.append(t)
        }
    }
}
