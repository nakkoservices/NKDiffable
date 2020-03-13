//
//  NKDiffableTests.swift
//  NKDiffableTests
//
//  Created by Mihai Fratu on 27/02/2020.
//  Copyright © 2020 Mihai Fratu. All rights reserved.
//

import XCTest
@testable import NKDiffable

class NKDiffableTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    let array = [Int](0...10000)
    let otherArray = [Int](7500...15000)

    func testNKDifference() {
        measure {
            _ = array.nkDifference(from: otherArray)
        }
    }
    
    func testNKDifferenceOld() {
        measure {
            _ = array.nkDifferenceOld(from: otherArray)
        }
    }

}
