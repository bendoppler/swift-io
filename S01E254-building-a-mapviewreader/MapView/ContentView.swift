//
//  ContentView.swift
//  MapViewTesting
//
//  Created by Chris Eidhof on 10.05.21.
//

import SwiftUI
import MapKit

extension CLLocationCoordinate2D {
    static let brandenburgerTor = CLLocationCoordinate2D(latitude: 52.5162746, longitude: 13.3777041)
}

struct Annotation: Identifiable {
    var id = UUID()
    var location: CLLocationCoordinate2D
}

let annotations = [
    Annotation(location: .brandenburgerTor)
]

struct ContentView: View {
    @State var region: MKCoordinateRegion = MKCoordinateRegion(center: .brandenburgerTor, latitudinalMeters: 200, longitudinalMeters: 200)
    @State var showOverlay = false
    
    var body: some View {
        MapViewReader { proxy in
            Map(coordinateRegion: $region, annotationItems:
                annotations
            , annotationContent: { item in
                MapPin(coordinate: item.location, tint: .blue)
            })
            .toolbar(content: {
                Button("Re-Center") { region.center = .brandenburgerTor }
                Button(proxy.mapType == .standard ? "Satellite" : "Standard") { proxy.mapType = .satellite }
            })
        }
    }
}

struct MapViewReader<Child: View>: NSViewRepresentable {
    var run: (MapViewProxy) -> Child
    
    final class Coordinator {
        let proxy = MapViewProxy()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> NSHostingView<Child> {
        NSHostingView(rootView: run(context.coordinator.proxy))
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.rootView = run(context.coordinator.proxy)
        context.coordinator.proxy.mapView = nsView.firstSubview(with: MKMapView.self)
    }
}

extension NSView {
    func firstSubview<T: NSView>(with type: T.Type) -> T? {
        if let result = self as? T { return result }
        for v in subviews {
            if let result = v.firstSubview(with: type) { return result }
        }
        return nil
    }
}

class MapViewProxy {
    fileprivate var mapView: MKMapView?

    var mapType: MKMapType {
        get { mapView?.mapType ?? .standard }
        set { mapView?.mapType = newValue }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
