//  Created by Jesse Jones on 7/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

/// Generic view allowing the user to enter in one line of arbitrary text.
struct EditTextView: View {
    typealias Validator = (String) -> String?   // nil result => valid, otherwise error (can be an empty error message)
    
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    let placeHolder: String
    @State var content: String
    @State var error: String = " "      // use a space instead of empty so layout doesn't shift when there is a real error
    let type: UIKeyboardType = .default
    let autoCorrect: Bool = true
    let validator: Validator?
    let completion: (String) -> Void
    
    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle)
            Spacer()
            TextField(self.placeHolder, text: self.$content)    // for multi-line use TextEditor (could do this with an if)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(self.type)
                .disableAutocorrection(!self.autoCorrect)
                .padding()
            Text(self.error).foregroundColor(.red)
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
        if let checker = self.validator, let err = checker(self.content) {
            self.error = err
        } else {
            self.error = " "
            self.completion(self.content)
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditTextView_Previews: PreviewProvider {
    static var previews: some View {
        EditTextView(title: "Edit Text", placeHolder: "arbitrary", content: "", validator: nil, completion: done)
    }
    
    static func done(_ text: String) {
    }
}
