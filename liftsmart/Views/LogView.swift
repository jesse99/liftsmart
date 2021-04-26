//  Created by Jesse Jones on 4/24/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct LogEntry: Identifiable {
    let message: String
    let color: Color
    let id: Int
}

struct LogView: View {
    let logs: [LogLine]
    @State var show = LogLevel.Info

    init(_ logs: [LogLine]) {
        self.logs = logs
    }

    var body: some View {
        VStack() {
            Text("Logs").font(.largeTitle)
            List(self.getEntries()) {entry in
                Text(entry.message).font(.headline).foregroundColor(entry.color)
            }
            Menu(self.showStr()) {
                Button("Cancel", action: {})
                Button(buttonStr(.Debug), action: {self.show = .Debug})
                Button(buttonStr(.Info), action: {self.show = .Info})
                Button(buttonStr(.Warning), action: {self.show = .Warning})
                Button(buttonStr(.Error), action: {self.show = .Error})
            }.font(.callout).padding(.leading)
        }
    }
    
    func getEntries() -> [LogEntry] {
        func toEntry(_ index: Int, _ log: LogLine) -> LogEntry {
            switch log.level {
            case .Debug:
                return LogEntry(message: log.timeStr() + "  " + log.line, color: .gray, id: index)
            case .Error:
                return LogEntry(message: log.timeStr() + "  " + log.line, color: .red, id: index)
            case .Info:
                return LogEntry(message: log.timeStr() + "  " + log.line, color: .black, id: index)
            case.Warning:
                return LogEntry(message: log.timeStr() + "  " + log.line, color: .orange, id: index)
            }
        }
        
        func filterIn(_ log: LogLine) -> Bool {
            return log.level.rawValue <= self.show.rawValue
        }
        
        // Would be kind of nice to reverse this but that does get wonky with multi-line logs
        // (like caller traces).
        let lines = self.logs.filter(filterIn)
        return lines.mapi {toEntry($0, $1)}
    }
    
    func buttonStr(_ level: LogLevel) -> String {
        switch level {
        case .Error:
            return "Errors only"
        case.Warning:
            return "Warning and above"
        case .Info:
            return "Info and above"
        case .Debug:
            return "All logs"
        }
    }
    
    func showStr() -> String {
        switch self.show {
        case .Error:
            return "Show only errors"
        case.Warning:
            return "Show warning and above"
        case .Info:
            return "Show info and above"
        case .Debug:
            return "Show all"
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static let l0 = LogLine(seconds: 0.0, level: .Info, line: "Started up")
    static let l1 = LogLine(seconds: 1.0, level: .Info, line: "Starting Skullcrushers")
    static let l2 = LogLine(seconds: 1.5, level: .Error, line: "Crushed head")
    static let l3 = LogLine(seconds: 2.0, level: .Info, line: "Stopped")

    static var previews: some View {
        LogView([l0, l1, l2, l3])
    }
}
