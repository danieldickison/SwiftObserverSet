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
            observee.voidObservers.add(self, self.dynamicType.voidSent)
            observee.stringObservers.add(self, self.dynamicType.stringChanged)
            observee.twoStringObservers.add(self, self.dynamicType.twoStringChanged)
            observee.intObservers.add(self, self.dynamicType.intChanged)
            observee.intAndStringObservers.add(self, self.dynamicType.intAndStringChanged)
            observee.namedParameterObservers.add(self, self.dynamicType.namedParameterSent)
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
    
    class QueueObserver {
        private let queue = dispatch_queue_create("queued observer", DISPATCH_QUEUE_SERIAL)
        private var context = UnsafeMutablePointer<Void>.alloc(1)
        var count = 0
        
        init(observee: TestObservee) {
            dispatch_queue_set_specific(queue, unsafeAddressOf(self), context, nil)
            observee.voidObservers.add(self, queue: queue, self.dynamicType.voidOnQueue)
            observee.voidObservers.add(self, self.dynamicType.voidOffQueue)
        }
        
        deinit {
            context.dealloc(1)
        }
        
        func voidOnQueue() {
            let specific = dispatch_get_specific(unsafeAddressOf(self))
            XCTAssertEqual(specific, context, "Should dispatch on private queue")
            count++
        }
        
        func voidOffQueue() {
            let specific = dispatch_get_specific(unsafeAddressOf(self))
            XCTAssertEqual(specific, UnsafeMutablePointer(), "Should not dispatch on private queue")
            count++
        }
        
        func sync() {
            dispatch_sync(queue) {}
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
    
    func testQueues() {
        let observee = TestObservee()
        let observer1 = QueueObserver(observee: observee)
        var observer2: QueueObserver? = QueueObserver(observee: observee)
        
        XCTAssertEqual(observee.voidObservers.observerCount, 4)
        observee.testNotify()
        observer1.sync()
        XCTAssertEqual(observer1.count, 2)
        observer2!.sync()
        XCTAssertEqual(observer2!.count, 2)
        
        observer2 = nil
        observee.testNotify()
        XCTAssertEqual(observee.voidObservers.observerCount, 2)
        observer1.sync()
        XCTAssertEqual(observer1.count, 4)
    }
}
