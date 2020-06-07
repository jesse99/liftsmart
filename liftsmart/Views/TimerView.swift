//  Created by Jesse Jones on 5/31/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import AVFoundation // for vibrate
import SwiftUI

struct TimerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State var duration: Int
    @State var secondDuration: Int = 0    // used to wait twice
    @State private var startTime = Date()
    @State private var elapsed: Int = 0
    private let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    @State private var label: String = ""
    @State private var waiting: Bool = true
    @State private var resting: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            if self.waiting {
                Text("\(label)").font(.system(size: 64.0)).onReceive(timer, perform: onTimer)
            } else {
                Text("\(label)").font(.system(size: 64.0)).foregroundColor(Color.green) // TODO: better to use DarkGreen
            }
            Spacer()
            Button(buttonLabel(), action: onStopTimer).font(.system(size: 20.0))
            Spacer()
            Spacer()
        }
    }
    
    func onStopTimer() {
        if self.secondDuration > 0 {
            self.duration = self.secondDuration
            self.secondDuration = 0
            self.startTime = Date()
            self.elapsed = 0
            self.resting = true
        } else {
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    // This will count down to duration seconds and, if the count down goes far enough past
    // duration, auto-close this modal view.
    func onTimer(_ currentTime: Date) {
        let secs = Double(self.duration) - Date().timeIntervalSince(self.startTime)
        if secs > 0.0 {
            self.label = secsToShortDurationName(secs)
        } else if secs >= -2 {
            self.label = "Done!"
        } else if secs >= -2*60 {
            self.label = "+" + secsToShortDurationName(-secs)
        } else {
            self.onStopTimer()
            return
        }
        
        let wasWaiting = self.waiting
        self.waiting = secs > 0.0
        if self.waiting != wasWaiting {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
    
    func buttonLabel() -> String {
        if resting {
            return "Stop Resting"
        } else {
            return "Stop Timer"
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(duration: 10, secondDuration: 5)
    }
}
