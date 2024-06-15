//
//  ContentView.swift
//  Recordings
//
//  Created by Florian Kugler on 20-03-2020.
//  Copyright © 2020 objc.io. All rights reserved.
//

import SwiftUI
import Combine

func ??<A: View, B: View>(lhs: A?, rhs: B) -> some View {
    Group {
        if let v = lhs {
            v
        } else {
            rhs
        }
    }
}

extension Binding where Value == Item {
    var destination: some View {
        Group {
            if wrappedValue.isFolder {
                FolderList(folder: self)
            } else {
                EmptyView()
//                PlayerWrapper(recording: self as! Recording)
            }
        }
    }
}

extension Item {
    subscript(_ id: UUID) -> Item {
        get {
            contents!.first { $0.id == id }!
        }
        set {
            let idx = contents!.firstIndex { $0.id == id }!
            contents![idx] = newValue
        }
    }

    var symbolName: String {
        self.isFolder ? "folder" : "waveform"
    }
}

@dynamicMemberLookup
final class Lazy<O: ObservableObject>: ObservableObject {
    var objectWillChange: O.ObjectWillChangePublisher {
        return value.objectWillChange
    }
    var value: O {
        get {
            buildValueIfNeeded()
            return _value!
        }
    }

    private var _value: O?
    private let build: () -> O
    init(_ build: @escaping () -> O) {
        self.build = build
    }

    func buildValueIfNeeded() {
        guard _value == nil else { return }
        _value = build()
    }

    subscript<Property>(dynamicMember dynamicMember: ReferenceWritableKeyPath<O, Property>) -> Property {
        get {
            return value[keyPath: dynamicMember]
        }
        set {
            value[keyPath: dynamicMember] = newValue
        }
    }

    subscript<Property>(dynamicMember dynamicMember: KeyPath<O, Property>) -> Property {
        return value[keyPath: dynamicMember]
    }
}

//extension Item {
//    var isDeleted: Bool {
//        return parent == nil
//    }
//}
//
//struct PlayerWrapper: View {
//    @ObservedObject var recording: Recording
//    var body: some View {
//        Group {
//            if recording.isDeleted {
//                NoRecordingSelected()
//            } else {
//                PlayerView(recording: recording) ?? Text("Something went wrong.")
//            }
//        }
//    }
//}

//struct PlayerView: View {
//    let recording: Recording
//    @State private var name: String = ""
//    @State private var position: TimeInterval = 0
//    @ObservedObject private var player: Lazy<Player> // TODO create lazily
//
//    init?(recording: Recording) {
//        self.recording = recording
//        self._name = State(initialValue: recording.name)
//        guard let u = recording.fileURL else { return nil }
//        self.player = Lazy { Player(url: u)! }
//    }
//
//    var playButtonTitle: String  {
//        if player.isPlaying {
//            return "Pause"
//        } else if player.isPaused {
//            return "Resume"
//        } else {
//            return "Play"
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Text("Name")
//                TextField("Name", text: $name, onEditingChanged: { _ in
//                    recording.setName(name)
//                })
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//            }
//            HStack {
//                Text(timeString(0))
//                Spacer()
//                Text(timeString(player.duration)) // TODO
//            }
//            Slider(value: $player.time, in: 0...player.duration) // TODO
//            Button(playButtonTitle) {
//                player.value.togglePlay()
//            }
//            .buttonStyle(PrimaryButtonStyle())
//            Spacer()
//        }
//        .padding()
//    }
//}

struct FolderList: View {
    @Binding var folder: Item
    @State var presentsNewRecording = false
    @State var createFolder = false
    var body: some View {
        List {
            ForEach(folder.contents!) { item in
                NavigationLink(destination: $folder[item.id].destination) {
                    HStack {
                        Image(systemName: item.symbolName)
                            .frame(width: 20, alignment: .leading)
                        Text(item.name)
                    }
                }.isDetailLink(!item.isFolder)
            }.onDelete(perform: { indices in
                let items = indices.map { folder.contents![$0] }
                for item in items {
                    folder.remove(item)
                }
            })
        }
        .textAlert(
            isPresented: $createFolder,
            title: "Create Folder",
            placeholder: "Name",
            callback: { name in
                guard let n = name else { return }
                folder.add(Item(folder: n))
            }
        )
        .navigationBarTitle("Recordings")
        .navigationBarItems(trailing: HStack {
            Button(action: {
                self.createFolder = true
            }, label: {
                Image(systemName: "folder.badge.plus")
            })

            Button(action: {
                self.presentsNewRecording = true
            }, label: {
                Image(systemName: "waveform.path.badge.plus")
            })
        })
//        .sheet(isPresented: $presentsNewRecording) {
//            RecordingView(folder: folder, isPresented: $presentsNewRecording)
//        }
    }
}

extension View {
    func textAlert(isPresented: Binding<Bool>, title: String, placeholder: String = "", callback: @escaping (String?) -> ()) -> some View {
        return AlertWrapper(isPresented: isPresented, title: title, placeholder: placeholder, callback: callback, content: self)
    }
}

struct AlertWrapper<Content:View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let title: String
    let placeholder: String
    let callback: (String?) -> ()
    let content: Content

    init(
        isPresented: Binding<Bool>,
        title: String,
        placeholder: String,
        callback: @escaping (String?) -> (),
        content: Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.placeholder = placeholder
        self.callback = callback
        self.content = content
    }

    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
        uiViewController.rootView = content
        if isPresented && uiViewController.presentedViewController == nil {
            let vc = modalTextAlert(title: title, placeholder: placeholder, callback: {
                self.isPresented = false
                self.callback($0)
            })
            uiViewController.present(vc, animated: true)
        }
    }
}

//struct RecordingView: View {
//    let folder: Folder
//    @Binding var isPresented: Bool
//
//    private let recording = Recording(name: "", uuid: UUID())
//    @ObservedObject private var recorder: Lazy<Recorder>
//    @State private var isSaving: Bool = false
//    @State private var deleteOnCancel: Bool = true
//
//    init?(folder: Folder, isPresented: Binding<Bool>) {
//        self.folder = folder
//        self._isPresented = isPresented
//        guard let s = folder.store, let url = s.fileURL(for: recording) else { return nil }
//        self.recorder = Lazy { Recorder(url: url) }
//    }
//
//    func save(name: String?) {
//        recorder.value.stop()
//        if let n = name {
//            recording.setName(n)
//            folder.add(recording)
//            self.deleteOnCancel = false
//        }
//        isPresented = false
//    }
//
//    func cancel() {
//        recorder.value.stop()
//        guard self.deleteOnCancel else { return }
//        recording.deleted()
//    }
//
//    var body: some View {
//        VStack(spacing: 20) {
//            if recorder.error == .noPermission {
//                Text("Go to settings.")
//            } else if recorder.error != nil {
//                Text("An error occurred.")
//            } else {
//                Text("Recording")
//                Text(timeString(recorder.currentTime))
//                    .font(.title)
//                Button("Stop") { self.isSaving = true }
//                .buttonStyle(PrimaryButtonStyle())
//            }
//        }
//        .padding()
//        .textAlert(
//            isPresented: $isSaving,
//            title: "Save Recording",
//            placeholder: "Name",
//            callback: { save(name: $0) }
//        )
//        .onDisappear {
//            cancel()
//        }
//    }
//}

struct NoRecordingSelected: View {
    let body = Text("No recording selected.")
}

struct ContentView: View {
    @ObservedObject var store = Store.shared
    var body: some View {
        NavigationView {
            FolderList(folder: $store.rootFolder)
            NoRecordingSelected()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 5).fill(.orange))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
