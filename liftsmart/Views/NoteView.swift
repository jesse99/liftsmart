//  Created by Jesse Jones on 7/24/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import MDText
import SwiftUI

/// Displays the note associated with an exercise.
struct NoteView: View {
    let formalName: String
    @State var editModal = false
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode

    init(_ display: Display, formalName: String) {
        self.display = display
        self.formalName = formalName
    }

    var body: some View {
        VStack {
            Text(self.formalName + self.display.edited).font(.largeTitle)
            MDText(markdown: self.markup()).font(.callout)
                .padding()
            Spacer()
            HStack {
                Button("Revert", action: onRevert)
                    .font(.body)
                    .disabled(!self.hasUserNote())
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal) {EditNoteView(self.display, formalName: self.formalName)}
                Spacer()
                Spacer()
                Button("Done", action: onDone).font(.callout)
            }
            .padding()
        }
    }
    
    func markup() -> String {
        return self.display.userNotes[formalName] ?? defaultNotes[formalName] ?? "No note"
    }
    
    func hasUserNote() -> Bool {
        return !((self.display.userNotes[formalName] ?? "").isEmpty)
    }
    
    func onEdit() {
        self.editModal = true
    }
    
    func onRevert() {
        self.display.send(.SetUserNote(self.formalName, nil))
    }

    func onDone() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct NoteView_Previews: PreviewProvider {
    static let display = previewDisplay()

    static var previews: some View {
        NoteView(display, formalName: "Arch Hold")
    }
}
