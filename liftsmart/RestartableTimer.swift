//  Created by Jesse Jones on 7/4/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import Combine
import Foundation

// Timers are a little goofy in SwiftUI: there's no good way to start and stop them and they are automatically
// stopped (invalidated) if they're in a NavigationLink view and the user goes back and then returns.
class RestartableTimer: ObservableObject {
    var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    private let every: TimeInterval
    private let tolerance: TimeInterval
    
    // Note that the timer won't fire until the every interval elapses.
    init(every: TimeInterval, tolerance: TimeInterval? = nil) {
        self.every = every
        self.tolerance = tolerance ?? 0.8*every
        self.timer = Timer.publish(every: self.every, tolerance: self.tolerance, on: .main, in: .common).autoconnect()
    }

    func restart() {
        self.timer = Timer.publish(every: every, tolerance: tolerance, on: .main, in: .common).autoconnect()
    }

    func stop() {
        self.timer.upstream.connect().cancel()
    }
}

