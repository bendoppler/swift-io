//
//  ContentView.swift
//  MyAsyncImage
//
//  Created by Chris Eidhof on 10.06.21.
//

import SwiftUI

func mySleep(_ seconds: Int) async {
    sleep(UInt32(seconds))
}

struct MyAsyncImage: View {
    @State private var image: Image?
    var url: URL
    
    var body: some View {
        ZStack {
            if let i = image {
                i
            } else {
                ProgressView()
            }
        }.task(id: url) {
            do {
                await mySleep(1)
                guard !Task.isCancelled else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                if let i = UIImage(data: data) {
                    self.image = Image(uiImage: i)
                }
            } catch {
                
            }
        }
    }
}

struct ContentView: View {
    @State var url = URL(string: "https://via.placeholder.com/350x150")!
    var body: some View {
        VStack {
            MyAsyncImage(url: url)
            Button("Change") {
                url = URL(string: "https://via.placeholder.com/250")!
            }
        }
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
