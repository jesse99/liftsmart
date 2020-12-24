//  Created by Jesse Jones on 12/19/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct EditRepsSetView: View {
    let name: Binding<String>
    let set: Binding<[RepsSet]>
    let completion: ([RepsSet]) -> Void
    @State var reps = ""
    @State var percents = ""
    @State var rests = ""
    @State var errText: String = ""
    @Environment(\.presentationMode) private var presentationMode
    
    init(name: Binding<String>, set: Binding<[RepsSet]>, completion: @escaping ([RepsSet]) -> Void) {
        self.name = name
        self.set = set
        self.completion = completion
    }

    var body: some View {
        VStack {
            Text("Edit " + self.name.wrappedValue).font(.largeTitle)
            HStack {
                Text("Reps:").font(.headline)
                TextField("", text: self.$reps)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .onChange(of: self.reps, perform: self.onValidate)
                    .padding()
            }.padding(.leading)
            HStack {
                Text("Percents:").font(.headline)
                TextField("", text: self.$percents)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .onChange(of: self.percents, perform: self.onValidate)
                    .padding()
            }.padding(.leading)
            HStack {
                Text("Rest:").font(.headline)
                TextField("", text: self.$rests)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .onChange(of: self.rests, perform: self.onValidate)
                    .padding()
            }.padding(.leading)
            Spacer()
            Text(self.errText).foregroundColor(.red).font(.callout).padding(.leading)

            Divider()
            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout).disabled(self.hasError())
            }.padding().onAppear {self.refresh()}
        }
    }
    
    func refresh() {
        self.reps = set.wrappedValue.map({$0.reps.editable}).joined(separator: " ")
        self.percents = set.wrappedValue.map({$0.percent.editable}).joined(separator: " ")
        self.rests = set.wrappedValue.map({restToStr($0.restSecs)}).joined(separator: " ")
    }
        
    func doValidate() -> [RepsSet]? {
        // Check each rep, this can be empty (e.g. for warmups)
        var parts = self.reps.split(separator: " ")
        var repsSet: [RepRange] = []
        for part in parts {
            switch RepRange.create(String(part)) {
            case .right(let r):
                repsSet.append(r)
            case .left(let e):
                self.errText = e
                return nil
            }
        }

        // Check each percent
        parts = self.percents.split(separator: " ")
        var percentSet: [WeightPercent] = []
        for part in parts {
            switch WeightPercent.create(String(part)) {
            case .right(let r):
                percentSet.append(r)
            case .left(let e):
                self.errText = e
                return nil
            }
        }

        // Check each rest
        parts = self.rests.split(separator: " ")
        var restSet: [Int] = []
        for part in parts {
            switch strToRest(String(part)) {
            case .right(let r):
                restSet.append(r)
            case .left(let e):
                self.errText = e
                return nil
            }
        }

        // Ensure that counts match up
        if repsSet.count == percentSet.count && percentSet.count == restSet.count {
            var result: [RepsSet] = []
            for i in 0..<repsSet.count {
                result.append(RepsSet(reps: repsSet[i], percent: percentSet[i], restSecs: restSet[i]))
            }
            self.errText = ""
            return result

        } else {
            self.errText = "Number of sets must all match"
            return nil
        }
    }
    
    func onValidate(_ dummy: String) {
        let _ = doValidate()
    }
    
    func hasError() -> Bool {
        return !self.errText.isEmpty
    }
    
    func onCancel() {
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        self.errText = ""
        self.completion(doValidate()!)
        self.presentationMode.wrappedValue.dismiss()
    }
}

//struct EditRepsSetView_Previews: PreviewProvider {
//    static var previews: some View {
//        let s1 = RepsSet(reps: RepRange(min: 8, max: 12)!, percent: WeightPercent(0.7)!, restSecs: 3*60)!
//        let s2 = RepsSet(reps: RepRange(min: 6, max: 10)!, percent: WeightPercent(0.8)!, restSecs: 3*60)!
//        let s3 = RepsSet(reps: RepRange(min: 4, max: 8)!,  percent: WeightPercent(0.9)!, restSecs: 3*60 + 30)!
//        EditRepsSetView(name: "Work Sets", set: [s1, s2, s3], completion: done)
//    }
//    
//    static func done(_ reps: [RepsSet]) {
//    }
//}
