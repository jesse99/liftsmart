//  Created by Jesse Jones on 4/24/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import MessageUI
import SwiftUI

struct LogEntry: Identifiable {
    let message: String
    let color: Color
    let id: Int
}

// From https://stackoverflow.com/questions/56784722/swiftui-send-email
struct MailView: UIViewControllerRepresentable {
    let payload: String
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.presentationMode) var presentation

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>, result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentation = presentation
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator

        let data = self.payload.data(using: .utf8)!    // safe because strings are already Unicode
        composer.addAttachmentData(data, mimeType: "text/plain", fileName: "liftsmart.log")
        
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {
    }
}

struct LogView: View {
    let logs: [LogLine]
    @State var show = LogLevel.Info
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false

    init(_ logs: [LogLine]) {
        self.logs = logs
    }

    var body: some View {
        VStack() {
            Text("Logs").font(.largeTitle)
            List(self.getEntries()) {entry in
                Text(entry.message).font(.headline).foregroundColor(entry.color)
            }
            HStack {
                Button("Email", action: onEmail).font(.callout)
                    .padding(.leading)
                    .disabled(!self.canEmail())
                    .sheet(isPresented: self.$isShowingMailView) {MailView(payload: self.getPayload(), result: self.$result)
                }
                Spacer()
                Menu(self.showStr()) {
                    Button("Cancel", action: {})
                    Button(buttonStr(.Debug), action: {self.show = .Debug})
                    Button(buttonStr(.Info), action: {self.show = .Info})
                    Button(buttonStr(.Warning), action: {self.show = .Warning})
                    Button(buttonStr(.Error), action: {self.show = .Error})
                }.font(.callout).padding(.trailing)
            }.padding(.bottom)
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
            return "Only errors"
        case.Warning:
            return "Warning and above"
        case .Info:
            return "Info and above"
        case .Debug:
            return "All"
        }
    }
    
    func canEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    func onEmail() {
        self.isShowingMailView = true
    }
    
    func getPayload() -> String {
        var payload = ""
        payload.reserveCapacity(30*self.logs.count)
        
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"
        payload += "Version: \(version)\n"

        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) ?? "?"
        payload += "Build: \(build)\n\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        payload += "Date: \(formatter.string(from: Date()))\n"

        for log in self.logs {
            payload += "\(log.timeStr()) \(log.level) \(log.line)\n"
        }

        return payload
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
