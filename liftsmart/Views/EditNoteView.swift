//  Created by Jesse Jones on 7/25/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI
import TextView

struct EditNoteView: View {
    @Environment(\.presentationMode) private var presentationMode
    let formalName: String
    @State var text = ""
    @State var isEditing = false
        
    var body: some View {
        VStack {
            Text("Edit " + self.formalName).font(.largeTitle)
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
        .onAppear {self.text = userNotes[self.formalName] ?? defaultNotes[self.formalName] ?? ""}
    }
    
    func onHelp() {
        UIApplication.shared.open(URL(string: "https://commonmark.org/help/")!)
    }

    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onDone() {
        userNotes[formalName] = text

        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditNoteView_Previews: PreviewProvider {
    static var previews: some View {
        EditNoteView(formalName: "Arch Hold")
    }
}
