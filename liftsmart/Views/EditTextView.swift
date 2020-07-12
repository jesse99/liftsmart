//  Created by Jesse Jones on 7/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

/// Generic view allowing the user to enter in one line of arbitrary text.
struct EditTextView: View {
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    let placeHolder: String
    @State var content: String
    let completion: (String) -> Void
    
    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle)
            Spacer()
            TextField(self.placeHolder, text: self.$content)    // for multi-line use TextEditor (could do this with an if)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
//                .disableAutocorrection(true)
                .padding()
            Spacer()
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Spacer()
                Button("OK", action: onOK)
            }.padding()
        }
    }
    
    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.completion(self.content)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditTextView_Previews: PreviewProvider {
    static var previews: some View {
        EditTextView(title: "Edit Text", placeHolder: "arbitrary", content: "", completion: done)
    }
    
    static func done(_ text: String) {
    }
}
