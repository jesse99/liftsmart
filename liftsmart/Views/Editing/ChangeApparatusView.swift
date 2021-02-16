//  Created by Jesse Jones on 2/15/21.
//  Copyright © 2021 MushinApps. All rights reserved.
import SwiftUI

struct ChangeApparatusView: View {
    var workout: Workout
    let index: Int
    let dismiss: () -> Void
    let original: Exercise
    @State var apparatusLabel = "TypeTypeTypeType"
    @State var apparatus = Apparatus.bodyWeight
    @State var showHelp = false
    @State var helpText = ""
    @Environment(\.presentationMode) private var presentationMode
    
    init(workout: Workout, index: Int, dismiss: @escaping () -> Void) {
        self.workout = workout
        self.index = index
        self.dismiss = dismiss
        self.original = workout.exercises[index]
    }
    
    var body: some View {
        VStack() {
            Text("Change Apparatus").font(.largeTitle)

            VStack(alignment: .leading) {
                HStack {
                    Menu(self.apparatusLabel) {
                        Button("Body Weight", action: {self.onChange(.bodyWeight)})
                        Button("Fixed Weights", action: {self.onChange(.fixedWeights(name: nil))})
                        Button("Cancel", action: {})
                    }.font(.callout).padding(.leading)
                    Spacer()
                    Button("?", action: self.onHelp).font(.callout).padding(.trailing)
                }
            }
            Spacer()

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
        .alert(isPresented: $showHelp) {   // and views can only have one alert
            return Alert(
                title: Text("Help"),
                message: Text(self.helpText),
                dismissButton: .default(Text("OK")))
        }
    }
    
    func refresh() {
        self.apparatus = self.workout.exercises[self.index].modality.apparatus
        self.apparatusLabel = getApparatusLabel(self.apparatus)
    }
    
    func onChange(_ apparatus: Apparatus) {
        let exercise = self.workout.exercises[self.index]
        exercise.modality.apparatus = apparatus

        self.refresh()
    }
    
    func onHelp() {
        self.helpText = getApparatusHelp(apparatus)
        self.showHelp = true
    }

    func onCancel() {
        self.workout.exercises[self.index].restore(self.original)
        self.presentationMode.wrappedValue.dismiss()
    }

    func onOK() {
        let app = UIApplication.shared.delegate as! AppDelegate
        app.saveState()
        self.dismiss()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ChangeApparatusView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeApparatusView(workout: cardio(), index: 0, dismiss: ChangeApparatusView_Previews.onDismiss)
    }
    
    static func onDismiss() {
    }
    
    private static func cardio() -> Workout {
        func burpees() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Burpees", "Burpees", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }
        
        func squats() -> Exercise {
            let sets = Sets.durations([DurationSet(secs: 60, restSecs: 60)])
            let modality = Modality(Apparatus.bodyWeight, sets)
            let e = Exercise("Squats", "Body-weight Squat", modality)
            e.current = Current(weight: 0.0)
            e.current?.startDate = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
            e.current!.setIndex = 1
            return e
        }

        return createWorkout("Cardio", [burpees(), squats()], day: nil).unwrap()
    }
}

