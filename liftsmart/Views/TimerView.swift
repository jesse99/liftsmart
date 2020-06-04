//  Created by Jesse Jones on 5/31/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import AVFoundation // for vibrate
import SwiftUI

struct TimerView: View {
    @Environment(\.presentationMode) var presentationMode
    let duration: Int
    let startTime = Date()
    var elapsed: Int = 0
    let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    @State var label: String = ""
    @State var waiting: Bool = true
    
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
            Button("Stop Timer", action: onStopTimer).font(.system(size: 20.0))
            Spacer()
            Spacer()
        }
    }
    
    func onStopTimer() {
        self.presentationMode.wrappedValue.dismiss()
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
            self.presentationMode.wrappedValue.dismiss()
        }
        
        let wasWaiting = self.waiting
        self.waiting = secs > 0.0
        if self.waiting != wasWaiting {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(duration: 10)
    }
}
