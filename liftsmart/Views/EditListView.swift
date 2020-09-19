//  Created by Jesse Jones on 9/12/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

var listID: Int = 0

struct ListEntry: Identifiable {
    let name: String
    let id: Int
    let index: Int      // can't use this as an index because ids should change when entries change

    init(_ name: String, _ index: Int) {
        self.name = name
        self.id = listID
        self.index = index
        
        listID += 1
    }
}

/// Allows the user to edit sequences of arbitrary objects.
struct EditListView: View {
    typealias NamesFn = () -> [String]
    typealias AddFn = (String) -> String?   // returns an error message if the add failed
    typealias DeleteFn = (Int) -> Void
    typealias MoveDownFn = (Int) -> Void
    typealias MoveUpFn = (Int) -> Void
    
    @State var entries: [ListEntry] = []
    @State var showEditActions: Bool = false
    @State var editIndex: Int = 0
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    var names: NamesFn
    var add: AddFn?
    var delete: DeleteFn?
    var moveDown: MoveDownFn?
    var moveUp: MoveUpFn?
    
    // TODO: have an optional red error message label at the bottom
    var body: some View {
        VStack {
            Text(self.title).font(.largeTitle)
            
            List(self.entries) {entry in
                VStack(alignment: .leading) {
                    Text(entry.name).font(.headline)
                }
                .contentShape(Rectangle())  // so we can click within spacer
                    .onTapGesture {self.showEditActions = true; self.editIndex = entry.index}
            }
            
            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout)
            }
            .padding()
            .onAppear {self.refresh()}
        }
        .actionSheet(isPresented: $showEditActions) {
            ActionSheet(title: Text(self.entries[self.editIndex].name), buttons: editButtons())}
    }

    func refresh() {
        self.entries = self.names().mapi({ListEntry($1, $0)})
    }
    
    func editButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        if let delete = self.delete {
            buttons.append(.default(Text("Delete"), action: {delete(self.editIndex); self.refresh()}))
        }
        
        buttons.append(.cancel(Text("Cancel"), action: {}))
        
        return buttons
    }

    func onCancel() {
        // TODO: call a cancel callback
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EditListView_Previews: PreviewProvider {
    static var names = ["Alpha", "Beta", "Gamma"]
    
    static var previews: some View {
        EditListView(title: "Workouts", names: onNames, delete: onDelete)
    }
    
    static func onNames() -> [String] {
        return names
    }

    static func onDelete(_ index: Int) {
        names.remove(at: index)
    }
}
