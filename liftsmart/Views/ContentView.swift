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
                        Image("first")
                        Text("Workouts")
                    }
                }
                .tag(0)
            LogView(logLines)
                .font(.title)
                .tabItem {
                    VStack {
                        Image("second")
                        Text("Logs")
                    }
                }
                .tag(1)
            Text("Settings")
                .font(.title)
                .tabItem {
                    VStack {
                        Image("first")
                        Text("Settings")
                    }
                }
                .tag(2)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
