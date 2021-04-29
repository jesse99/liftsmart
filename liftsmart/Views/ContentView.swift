//  Created by Jesse Jones on 4/18/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @StateObject var display = Display()

    var body: some View {
        TabView(selection: $selection){
            ProgramView(self.display)
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "figure.walk")
                        Text("Workouts" + self.display.edited)
                    }
                }
                .tag(0)
            LogView(logLines)
                .font(.title)
                .tabItem {
                    VStack {
                        // TODO: Would be great if this was color coded when not selected but that seems to require
                        // some work, see https://stackoverflow.com/questions/60803755/change-color-of-image-icon-in-tabitems-in-swiftui
                        Image(systemName: self.logsName())
                        Text("Logs")
                    }
                }
                .tag(1)
            Text("Settings")
                .font(.title)
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                }
                .tag(2)
        }
    }
    
    private func logsName() -> String {
        if numLogErrors > 0 {
            return "exclamationmark.triangle.fill"
        } else if numLogWarnings > 0 {
            return "drop.triangle.fill"
        } else {
            return "text.bubble"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
