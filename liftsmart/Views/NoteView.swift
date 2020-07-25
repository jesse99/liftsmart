//  Created by Jesse Jones on 7/24/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import MDText
import SwiftUI

/// Displays the note associated with an exercise.
struct NoteView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State var editModal = false
    @State var markup = ""
    @State var originalMarkup = ""
    @State var hasUserNote = false
    let formalName: String
    
    var body: some View {
        VStack {
            Text(self.formalName).font(.largeTitle)
            MDText(markdown: self.markup).padding()
            Spacer()
            HStack {
                Button("Revert", action: onRevert)
                    .font(.callout)
                    .disabled(!self.hasUserNote)
                Button("Edit", action: onEdit)
                    .font(.callout)
                    .sheet(isPresented: self.$editModal, onDismiss: self.onFinishedEditing) {EditNoteView(formalName: self.formalName)}
                Spacer()
                Spacer()
                Button("Done", action: onDone).font(.callout)
            }
            .padding()
            .onAppear {self.onUpdate(); self.originalMarkup = self.markup}
        }
    }
    
    func onEdit() {
        self.editModal = true
    }
    
    func onFinishedEditing() {
        self.onUpdate()
    }

    func onRevert() {
        userNotes[formalName] = nil

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        
        onUpdate()
    }

    func onDone() {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    func onUpdate() {
        self.markup = self.getNote()
        self.hasUserNote = !((userNotes[formalName] ?? "").isEmpty)
    }
    
    func getNote() -> String {
        return userNotes[formalName] ?? defaultNotes[formalName] ?? "No note"
    }
}

struct NoteView_Previews: PreviewProvider {
    static var previews: some View {
        NoteView(formalName: "Arch Hold")
    }
}
