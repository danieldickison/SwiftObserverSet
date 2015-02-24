//
//  ObserverSetTests.swift
//  ObserverSetTests
//
//  Created by Mike Ash on 1/22/15.
//  Copyright (c) 2015 Mike Ash. All rights reserved.
//

import Cocoa
import XCTest

class ObserverSetTests: XCTestCase {
    class TestObservee {
        let voidObservers = ObserverSet<Void>()
        let stringObservers = ObserverSet<String>()
        let twoStringObservers = ObserverSet<(String, String)>()
        let intObservers = ObserverSet<(Int, Int)>()
        let intAndStringObservers = ObserverSet<(Int, String)>()
        let namedParameterObservers = ObserverSet<(name: String, count: Int)>()
        
        func testNotify() {
            voidObservers.notify()
            stringObservers.notify("Sup")
            twoStringObservers.notify("hello", "world")
            intObservers.notify(42, 43)
            intAndStringObservers.notify(42, "hello")
            namedParameterObservers.notify(name: "someName", count: 42)
        }
    }
    
    class TestObserver {
        private(set) var receivedNotifications: [String] = []
        let expectedNotifications = ["void", "Sup", "hello", "world", "42", "43", "42", "hello", "someName", "42"]
        
        init(observee: TestObservee) {
            observee.voidObservers.add(self, voidSent)
            observee.stringObservers.add(self, stringChanged)
            observee.twoStringObservers.add(self, twoStringChanged)
            observee.intObservers.add(self, intChanged)
            observee.intAndStringObservers.add(self, intAndStringChanged)
            observee.namedParameterObservers.add(self, namedParameterSent)
        }
        
        deinit {
            println("deinit!!!!")
        }
        
        func reset() {
            receivedNotifications.removeAll()
        }
        
        func voidSent() {
            receivedNotifications.append("void")
        }
        
        func stringChanged(s: String) {
            receivedNotifications.append(s)
        }
        
        func twoStringChanged(s1: String, s2: String) {
            receivedNotifications.append(s1)
            receivedNotifications.append(s2)
        }
        
        func intChanged(i: Int, j: Int) {
            receivedNotifications.append(i.description)
            receivedNotifications.append(j.description)
        }
        
        func intAndStringChanged(i: Int, s: String) {
            receivedNotifications.append(i.description)
            receivedNotifications.append(s)
        }
        
        func namedParameterSent(name: String, count: Int) {
            receivedNotifications.append(name)
            receivedNotifications.append(count.description)
        }
    }
    
    func testBasics() {
        let observee = TestObservee()
        var obj: TestObserver? = TestObserver(observee: observee)
        var closureValues: [String] = []

        XCTAssertEqual(observee.intAndStringObservers.observerCount, 1)
        let token = observee.intAndStringObservers.add{ closureValues.append($0.description); closureValues.append($1) }
        XCTAssertEqual(observee.intAndStringObservers.observerCount, 2)
        observee.testNotify()
        XCTAssertEqual(closureValues, ["42", "hello"])
        XCTAssertEqual(obj!.receivedNotifications, obj!.expectedNotifications)
        obj = nil
        observee.testNotify()
        XCTAssertEqual(closureValues, ["42", "hello", "42", "hello"])
        XCTAssertEqual(observee.intAndStringObservers.observerCount, 1, "Deallocated method-based observer should be removed after notify")
        observee.intAndStringObservers.remove(token)
        XCTAssertEqual(observee.intAndStringObservers.observerCount, 0, "Token-based observer should be removed immediately")
        observee.testNotify()
        XCTAssertEqual(closureValues, ["42", "hello", "42", "hello"], "Token-based observer should stop receiving")
        
        println("intAndStringObservers: \(observee.intAndStringObservers.description)")
    }
}
