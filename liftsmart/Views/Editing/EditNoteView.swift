//  Created by Jesse Jones on 7/25/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI
import TextView

struct EditNoteView: View {
    let formalName: String
    @State var text: String
    @State var isEditing = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode

    init(_ display: Display, formalName: String) {
        self.display = display
        self.formalName = formalName
        self._text = State(initialValue: userNotes[formalName] ?? defaultNotes[formalName] ?? "")
        self.display.send(.BeginTransaction(name: "change note"))
    }
    
    var body: some View {
        VStack {
            Text("Edit " + self.formalName + self.display.edited).font(.largeTitle)
            TextView(text: $text, isEditing: $isEditing).padding()  // TODO: with ios14 can use TextEditor
            Spacer()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Button("Help", action: onHelp).font(.callout)
                Spacer()
                Spacer()
                Button("Done", action: onDone).font(.callout)
            }.padding()
        }
    }
    
    func onHelp() {
        UIApplication.shared.open(URL(string: "https://commonmark.org/help/")!)
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "change note"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onDone() {
        if self.text != (userNotes[formalName] ?? defaultNotes[formalName] ?? "") {
            self.display.send(.SetUserNote(self.formalName, self.text))
        }
        self.display.send(.ConfirmTransaction(name: "change note"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditNoteView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        EditNoteView(display, formalName: "Arch Hold")
    }
}
