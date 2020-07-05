//  Created by Jesse Jones on 6/29/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import SwiftUI

struct HistoryView: View {
    var items: [History.Record]
    let title: String
    let hasNote: Bool
    @Environment(\.presentationMode) private var presentationMode
    @State var labels: [String] = Array(repeating: "", count: 200)
    @State var subLabels: [String] = Array(repeating: "", count: 200)
    @State var notes: [String] = Array(repeating: "", count: 200)
    private let timer = Timer.publish(every: TimeInterval.hours(4), tolerance: TimeInterval.minutes(30), on: .main, in: .common).autoconnect()

    // Note that updating @State members in init doesn't actually work: https://stackoverflow.com/questions/61661581/swiftui-view-apparently-laid-out-before-init-runs
    init(history: History, workout: Workout, exercise: Exercise) {
        self.items = Array(history.exercise(workout, exercise).suffix(200).reversed())
        self.title = "\(exercise.name) History"
        self.hasNote = self.items.any({!$0.note.isEmpty})
    }

    var body: some View {
        VStack() {
            Text(title).font(.largeTitle)
            List(0..<items.count) { i in
                VStack(alignment: .leading) {
                    HStack {
                        // TODO: click should allow note to be edited (will have to manually call refresh in onDismiss)
                        Text(self.labels[i]).font(.headline)
                        Spacer()
                        Text(self.subLabels[i]).font(.headline)
                    }
                    if self.hasNote {
                        Text(self.notes[i]).font(.subheadline)
                    }
                }
            }
            
            Divider()
            HStack {
                Button("Done", action: onDone).font(.callout)
                // TODO: probably should have a clear button (with confirm alert)
            }
            .padding()
            .onAppear {self.refresh()}
            .onReceive(timer) {_ in self.refresh()}
        }
    }
    
    // subLabels will change as time passes so we need the timer to ensure that our UI updates accordingly.
    // labels and notes can change via our nested sheet so we update those when this view appears.
    func refresh() {
        labels = items.map({self.label($0)})
        subLabels = items.map({$0.completed.daysName()})    // smallest reported interval is days so timer period can be very long
        notes = items.map({$0.note})
    }
    
    func label(_ record: History.Record) -> String {
        if record.weight > 0.0 {
            return "\(record.label) @ \(friendlyUnitsWeight(record.weight))"
        } else {
            return record.label
        }
    }
    
    func onDone() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        createView()
    }
    
    private static func createView() -> HistoryView {
        let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)!])
        let modality = Modality(Apparatus.bodyWeight, sets)
        let exercise = Exercise("Squats", "Body-weight Squat", modality)
        let workout = Workout("Lower", [exercise])!

        let history = History()
        exercise.current = Current(weight: 0.0)
        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        exercise.current!.setIndex = 1
        history.append(workout, exercise)

        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        history.append(workout, exercise)
        
        exercise.current?.startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        history.append(workout, exercise)
        
        exercise.current?.startDate = Date()
        exercise.current = Current(weight: 10.0)
        let record = history.append(workout, exercise)
        record.note = "Felt strong!"

        return HistoryView(history: history, workout: workout, exercise: exercise)
    }
}
