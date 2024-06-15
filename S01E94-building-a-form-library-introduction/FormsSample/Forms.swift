//
//  Forms.swift
//  FormsSample
//
//  Created by Do Thai Bao on 05/08/2022.
//  Copyright © 2022 objc.io. All rights reserved.
//

import UIKit

class Section: Equatable {
    let cells: [FormCell]
    var footerTitle: String?
    var isVisible: Bool

    init(cells: [FormCell], footerTitle: String?, isVisible: Bool) {
        self.cells = cells
        self.footerTitle = footerTitle
        self.isVisible = isVisible
    }

    static func ==(lhs: Section, rhs: Section) -> Bool {
        return lhs === rhs
    }
}

class FormCell: UITableViewCell {
    var shouldHighlight = false
    var didSelect: (() -> ())?
}

class FormViewController: UITableViewController {
    var sections: [Section] = []
    var previouslyVisibleSections: [Section] = []
    var visibleSections: [Section] {
        return sections.filter { $0.isVisible }
    }
    var firstResponder: UIResponder?

    func reloadSections() {
        tableView.beginUpdates()
        for index in sections.indices {
            let section = sections[index]
            let newIndex = visibleSections.firstIndex(of: section)
            let oldIndex = previouslyVisibleSections.firstIndex(of: section)
            switch (newIndex, oldIndex) {
            case (nil, nil), (.some, .some):
                break
            case let (newIndex?, nil):
                tableView.insertSections([newIndex], with: .automatic)
            case let (nil, oldIndex?):
                tableView.deleteSections([oldIndex], with: .automatic)
            }
            let footer = tableView.footerView(forSection: index)
            footer?.textLabel?.text = tableView(tableView, titleForFooterInSection: index)
            footer?.setNeedsLayout()
        }
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        previouslyVisibleSections = visibleSections
    }

    init(sections: [Section], title: String, firstResponder: UIResponder? = nil) {
        self.firstResponder = firstResponder
        self.sections = sections
        super.init(style: .grouped)
        self.previouslyVisibleSections = visibleSections
        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = title
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstResponder?.becomeFirstResponder()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return visibleSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSections[section].cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return visibleSections[indexPath.section].cells[indexPath.row]
    }

    private func cell(for indexPath: IndexPath) -> FormCell {
        return visibleSections[indexPath.section].cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return cell(for: indexPath).shouldHighlight
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return visibleSections[section].footerTitle
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cell(for: indexPath).didSelect?()
    }
}

class FormDriver<State> {
    var formViewController: FormViewController!
    var renderedElement: RenderedElement<[Section], State>!

    var state: State {
        didSet {
            renderedElement.update(state)
            formViewController.reloadSections()
        }
    }

    init(initial state: State, build: (RenderingContext<State>) -> RenderedElement<[Section], State>) {
        self.state = state
        let renderedElement = build(RenderingContext(state: state, change: { [unowned self] f in
            f(&self.state)
        }, pushViewController: { [unowned self] vc in
            self.formViewController.navigationController?.pushViewController(vc, animated: true)
        }, popViewController: {
            self.formViewController.navigationController?.popViewController(animated: true)
        }))
        self.renderedElement = renderedElement
        renderedElement.update(state)
        formViewController = FormViewController(sections: renderedElement.element, title: "Personal Hotspot Settings")
    }
}

final class TargetAction {
    let execute: () -> ()

    init(_ execute: @escaping () -> ()) {
        self.execute = execute
    }

    @objc func action(_ sender: Any) {
        execute()
    }
}

struct RenderedElement<Element, State> {
    var element: Element
    var strongReferences: [Any]
    var update: (State) -> ()
}

struct RenderingContext<State> {
    let state: State
    let change: ((inout State) -> ()) -> ()
    let pushViewController: (UIViewController) -> ()
    let popViewController: () -> ()
}

func uiSwitch<State>(keyPath: WritableKeyPath<State, Bool>) -> Element<UIView, State> {
    return { context in
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        let toggleTarget = TargetAction {
            context.change {
                $0[keyPath: keyPath] = toggle.isOn
            }
        }
        toggle.addTarget(toggleTarget, action: #selector(TargetAction.action(_:)), for: .valueChanged)
        return RenderedElement(element: toggle, strongReferences: [toggleTarget], update: { state in
            toggle.isOn = state[keyPath: keyPath]
        })
    }
}

func textField<State>(keyPath: WritableKeyPath<State, String>) -> Element<UIView, State> {
    return { context in
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        let didEnd = TargetAction {
            context.change { $0[keyPath: keyPath] = textField.text ?? "" }
        }
        let didExit = TargetAction {
            context.change { $0[keyPath: keyPath] = textField.text ?? "" }
            context.popViewController()
        }
        textField.addTarget(didEnd, action: #selector(TargetAction.action(_:)), for: .editingDidEnd)
        textField.addTarget(didExit, action: #selector(TargetAction.action(_:)), for: .editingDidEndOnExit)
        return RenderedElement(element: textField, strongReferences: [didEnd, didExit], update: { state in
            textField.text = state[keyPath: keyPath]
        })
    }
}

func controlCell<State>(title: String, control: @escaping Element<UIView, State>, leftAligned: Bool = false) -> Element<FormCell, State> {
    return { context in
        let cell = FormCell(style: .value1, reuseIdentifier: nil)
        let renderedControl = control(context)
        cell.textLabel?.text = title
        cell.contentView.addSubview(renderedControl.element)
        renderedControl.element.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addConstraints([
            renderedControl.element.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            renderedControl.element.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor)
        ])
        if leftAligned {
            cell.contentView.addConstraint(renderedControl.element.leadingAnchor.constraint(equalTo: cell.textLabel!.trailingAnchor, constant: 20))
        }
        return RenderedElement(element: cell, strongReferences: renderedControl.strongReferences, update: renderedControl.update)
    }
}

func detailTextCell<State>(title: String, keyPath: KeyPath<State, String>, form: @escaping Form<State>) -> Element<FormCell, State> {
    return { context in
        let cell = FormCell(style: .value1, reuseIdentifier: nil)
        cell.shouldHighlight = true
        cell.textLabel?.text = title
        cell.accessoryType = .disclosureIndicator
        let rendered = form(context)
        let nested = FormViewController(sections: rendered.element, title: title)
        cell.didSelect = {
            context.pushViewController(nested)
        }
        return RenderedElement(element: cell, strongReferences: rendered.strongReferences) { state in
            cell.detailTextLabel?.text = state[keyPath: keyPath]
            rendered.update(state)
            nested.reloadSections()
        }
    }
}

typealias Element<El, A> = (RenderingContext<A>) -> RenderedElement<El, A>
typealias Form<A> = Element<[Section], A>
typealias RenderedSection<A> = Element<Section, A>

func section<State>(_ cells: [Element<FormCell, State>], footer keyPath: KeyPath<State, String?>? = nil, isVisible: KeyPath<State, Bool>? = nil) -> RenderedSection<State> {
    return { context in
        let renderedCells = cells.map { $0(context) }
        let strongReferences = renderedCells.flatMap { $0.strongReferences }
        let section = Section(cells: renderedCells.map { $0.element }, footerTitle: nil, isVisible: true)
        let update: (State) -> () = { state in
            for c in renderedCells {
                c.update(state)
            }
            if let keyPath = keyPath {
                section.footerTitle = state[keyPath: keyPath]
            }
            if let iv = isVisible {
                section.isVisible = state[keyPath: iv]
            }
        }
        return RenderedElement(element: section,
                               strongReferences: strongReferences,
                               update: update)
    }
}

func sections<State>(_ sections: [RenderedSection<State>]) -> Form<State> {
    return { context in
        let renderedSections = sections.map { $0(context) }
        let strongReferences = renderedSections.flatMap { $0.strongReferences }
        let update: (State) -> () = { state in
            for c in renderedSections {
                c.update(state)
            }
        }
        return RenderedElement(element: renderedSections.map { $0.element },
                               strongReferences: strongReferences,
                               update: update)
    }
}

func nestedTextField<State>(title: String, keyPath: WritableKeyPath<State, String>) -> Element<FormCell, State> {
    let nested: Form<State> =
        sections([
            section([
                controlCell(
                    title: title,
                    control: textField(
                        keyPath: keyPath
                    ),
                    leftAligned: true)
            ])
        ])
    return detailTextCell(title: title, keyPath: keyPath, form: nested)
}

func optionCell<Input: Equatable, State>(title: String, option: Input, keyPath: WritableKeyPath<State, Input>) -> Element<FormCell, State> {
    return { context in
        let cell = FormCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.shouldHighlight = true
        cell.didSelect = {
            context.change { $0[keyPath: keyPath] = option }
        }
        return RenderedElement(element: cell, strongReferences: []) { state in
            cell.accessoryType = state[keyPath: keyPath] == option ? .checkmark : .none
        }
    }
}

func bind<State, NestedState>(form: @escaping Form<NestedState>, to keyPath: WritableKeyPath<State, NestedState>) -> Form<State> {
    return { context in
        let nestedContext = RenderingContext<NestedState>(
            state: context.state[keyPath: keyPath],
            change: { nestedChange in
                context.change { state in
                    nestedChange(&state[keyPath: keyPath])
                }
            },
            pushViewController: context.pushViewController,
            popViewController: context.popViewController
        )

        let sections = form(nestedContext)

        return RenderedElement<[Section], State>(element: sections.element, strongReferences: sections.strongReferences) { state in
            sections.update(state[keyPath: keyPath])
        }
    }
}
