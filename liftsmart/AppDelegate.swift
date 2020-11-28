//  Created by Jesse Vorisek on 4/18/20.
//  Copyright © 2020 MushinApps. All rights reserved.
import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    override init() {
        super.init()

//        let path = getPath(fileName: "program_name")
//        if let name = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? String {
//            program = loadProgram(name)
//        }
//
//        if program == nil {
//            os_log("failed to load program from %@", type: .info, path)
//            program = PhraksGreyskull()
//            currentProgram = program
//        }
//
//        let defaults = UserDefaults.standard
//        totalWorkouts = defaults.integer(forKey: "totalWorkouts")
//        bodyWeight = defaults.integer(forKey: "bodyWeight")
//        if totalWorkouts < program.numWorkouts {    // this is here so that my program has the right totalWorkouts
//            totalWorkouts = program.numWorkouts
//        }
        
        loadState()
//        loadAchievements()

        //        let warmups = Warmups(withBar: 0, firstPercent: 0.5, lastPercent: 0.9, reps: [5, 3, 1])
        //        let plan = AMRAPPlan("default plan", warmups, workSets: 3, workReps: 5)
        //        let plan = CycleRepsPlan("default plan", warmups, numSets: 3, minReps: 4, maxReps: 8)
        //        let plan = VariableRepsPlan("default plan", numSets: 3, minReps: 4, maxReps: 8)
        //        runWeighted(plan)
        
        //        let plan = FiveThreeOneBeginnerPlan("default plan", withBar: 0)
        //        runWeighted(plan, numWorkouts: 20, defaultWeight: 3)
        
        //        let cycles = [
        //            Cycle(withBar: 2, firstPercent: 0.5, warmups: [5, 3, 1, 1, 1], sets: 3, reps: 5, at: 1.0),
        //            Cycle(withBar: 2, firstPercent: 0.5, warmups: [5, 3, 1, 1, 1], sets: 3, reps: 3, at: 1.05),
        //            Cycle(withBar: 2, firstPercent: 0.5, warmups: [5, 3, 1, 1, 1], sets: 3, reps: 1, at: 1.1)
        //        ]
        //        let plan = MastersBasicCyclePlan("default plan", cycles)
        //        runWeighted(plan, numWorkouts: 15, defaultWeight: 2)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveState()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveState()
    }
    
    func loadState() {
        if let store = loadStore(from: "history") {
            history = History(from: store)
        }
        if let store = loadStore(from: "program6") {
            program = Program(from: store)
        }
        if let store = loadStore(from: "userNotes") {
            loadUserNotes(store)
        }
    }
    
    func saveState() {
        storeObject(program, to: "program6")
        storeObject(history, to: "history")
        storeUserNotes(to: "userNotes")
        
//        for achievement in achievements {
//            achievement.save(self)
//        }
//
//        let defaults = UserDefaults.standard
//        defaults.set(totalWorkouts, forKey: "totalWorkouts")
//        defaults.set(bodyWeight, forKey: "bodyWeight")
//        defaults.synchronize()
    }

    func loadStore(from fileName: String) -> Store? {
        if let encoded = loadEncoded(from: fileName) {
            if let data = encoded as? Data {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                do {
                    return try decoder.decode(Store.self, from: data)
                } catch {
                    os_log("Error decoding %@: %@", type: .error, fileName, error.localizedDescription)
                }
            } else {
                os_log("%@ couldnt be cast to Data", type: .error, fileName)
            }
        }
        return nil
    }

    func loadEncoded(from fileName: String) -> AnyObject? {
        guard let dirURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
            os_log("urls for documentDirectory failed", type: .error)
            return nil
        }

        let url = dirURL.appendingPathComponent(fileName)
        do {
            if let data = try? Data(contentsOf: url) {
                return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as AnyObject
            }
        } catch {
            os_log("Error saving object %@: %@", type: .error, fileName, error.localizedDescription)
        }
        return nil
    }

    func storeObject(_ object: Storable, to fileName: String) {
        let store = Store()
        object.save(store)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        do {
            let data = try encoder.encode(store)
            saveEncoded(data as AnyObject, to: fileName)
        } catch {
            os_log("Error encoding program %@: %@", type: .error, program.name, error.localizedDescription)
        }
    }
    
    func storeUserNotes(to fileName: String) {
        let store = Store()
        store.addStrArray("userNoteKeys", Array(userNotes.keys))
        store.addStrArray("userNoteValues", Array(userNotes.values))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        do {
            let data = try encoder.encode(store)
            saveEncoded(data as AnyObject, to: fileName)
        } catch {
            os_log("Error encoding program %@: %@", type: .error, program.name, error.localizedDescription)
        }
    }
    
    func loadUserNotes(_ store: Store) {
        let keys = store.getStrArray("userNoteKeys")
        let values = store.getStrArray("userNoteValues")
        
        userNotes = [:]
        for (i, key) in keys.enumerated() {
            userNotes[key] = values[i]
        }
    }

    func saveEncoded(_ object: AnyObject, to fileName: String) {
        guard let dirURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
            os_log("urls for documentDirectory failed", type: .error)
            return
        }

        let url = dirURL.appendingPathComponent(fileName)
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
            try data.write(to: url)
        } catch {
            os_log("Error saving object %@: %@", type: .error, fileName, error.localizedDescription)
        }
    }

//    private func sanitizeFileName(_ name: String) -> String {
//        var result = ""
//
//        for ch in name {
//            switch ch {
//            // All we really should have to re-map is "/" but other characters can be annoying
//            // in file names so we'll zap those too. List is from:
//            // https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
//            case "/", "\\", "?", "%", "*", ":", "|", "\"", "<", ">", ".", " ":
//                result += "_"
//            default:
//                result.append(ch)
//            }
//        }
//
//        return result
//    }
}

