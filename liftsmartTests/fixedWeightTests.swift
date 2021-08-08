//  Created by Jesse Jones on 8/8/21.
//  Copyright © 2021 MushinApps. All rights reserved.
//import SwiftUI
import XCTest
@testable import liftsmart

class fixedWeightTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // TODO: also extra, also extraAdds
    func testClosest() throws {
        let fws = FixedWeightSet([5, 10, 15, 20])
        
        XCTAssertEqual(fws.getClosestBelow(1), 0.0)
        XCTAssertEqual(fws.getClosest(1), 0.0)
        XCTAssertEqual(fws.getClosestAbove(1), 5.0)

        XCTAssertEqual(fws.getClosestBelow(4), 0.0)
        XCTAssertEqual(fws.getClosest(4), 5.0)
        XCTAssertEqual(fws.getClosestAbove(4), 5.0)

        XCTAssertEqual(fws.getClosestBelow(5), 5.0)
        XCTAssertEqual(fws.getClosest(5), 5.0)
        XCTAssertEqual(fws.getClosestAbove(5), 5.0)
  
        XCTAssertEqual(fws.getClosestBelow(6), 5.0)
        XCTAssertEqual(fws.getClosest(6), 5.0)
        XCTAssertEqual(fws.getClosestAbove(6), 10.0)

        XCTAssertEqual(fws.getClosestBelow(8), 5.0)
        XCTAssertEqual(fws.getClosest(8), 10.0)
        XCTAssertEqual(fws.getClosestAbove(8), 10.0)

        XCTAssertEqual(fws.getClosestBelow(20), 20.0)
        XCTAssertEqual(fws.getClosest(20), 20.0)
        XCTAssertEqual(fws.getClosestAbove(20), 20.0)

        XCTAssertEqual(fws.getClosestBelow(30), 20.0)
        XCTAssertEqual(fws.getClosest(30), 20.0)
        XCTAssertEqual(fws.getClosestAbove(30), 20.0)
    }
}
