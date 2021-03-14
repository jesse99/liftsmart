//  Created by Jesse Jones on 3/14/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

/// Generic view allowing the user to enter in one line of arbitrary text.
struct EditTextView: View {  
    typealias Validator = (String) -> Action
    typealias Sender = (String) -> Action
    
    let title: String
    let placeHolder: String
    let type: UIKeyboardType
    let autoCorrect: Bool
    let validator: Validator?           // nil if any string is OK
    let sender: Sender
    @State var content: String
    @ObservedObject var display: Display
    @Environment(\.presentationMode) private var presentationMode

    init(_ display: Display, title: String, content: String, placeHolder: String = "", type: UIKeyboardType = .default, autoCorrect: Bool = true, validator: Validator? = nil, sender: @escaping Sender) {
        self.display = display
        self.title = title
        self.placeHolder = placeHolder
        self.type = type
        self.autoCorrect = autoCorrect
        self.validator = validator
        self.sender = sender
        self._content = State(initialValue: content)
        self.display.send(.BeginTransaction(name: "edit text"))
    }

    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle)
//            Spacer()  // TODO: maybe https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-fixed-size-spacer
            TextField(self.placeHolder, text: self.$content)    // for multi-line use TextEditor (could do this with an if)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(self.type)
                .disableAutocorrection(!self.autoCorrect)
                .onChange(of: self.content, perform: self.onEdited)
                .padding()
            Spacer()
            Text(self.display.errMesg).foregroundColor(self.display.errColor).font(.callout)
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.display.hasError)
            }.padding()
        }.onAppear(perform: {
            self.onEdited(self.content)
        })
    }
    
    func onEdited(_ text: String) {
        if let closure = self.validator {
            self.display.send(closure(text))
        }
    }

    func onCancel() {
        self.display.send(.RollbackTransaction(name: "edit text"))
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.display.send(sender(self.content))
        self.display.send(.ConfirmTransaction(name: "edit text"))
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditTextView_Previews: PreviewProvider {
    static var previews: some View {
        EditTextView(previewDisplay(), title: "Edit Text", content: "", placeHolder: "arbitrary", sender: done)
    }
    
    static func done(_ text: String) -> Action {
        return .ValidateProgramName(text)
    }
}
