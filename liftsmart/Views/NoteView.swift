//  Created by Jesse Jones on 7/24/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import MDText
import SwiftUI

/// Displays the note associated with an exercise.
struct NoteView: View {
    @Environment(\.presentationMode) private var presentationMode
    let formalName: String
    
    var body: some View {
        VStack {
            Text(self.formalName).font(.largeTitle)
            MDText(markdown: self.getNote()).padding()
            Spacer()
            HStack {
                Button("Revert", action: onRevert).disabled(true)
                Button("Edit", action: onEdit).disabled(true)      // TODO: disable this if there us no userNote
                Spacer()
                Spacer()
                Button("Done", action: onDone)
            }.padding()
        }
    }
    
    func onEdit() {
    }

    func onRevert() {
    }

    func onDone() {
        self.presentationMode.wrappedValue.dismiss()
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
