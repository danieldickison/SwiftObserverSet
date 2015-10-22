//
//  ObserverSet.swift
//  ObserverSet
//
//  Created by Mike Ash on 1/22/15.
//  Copyright (c) 2015 Mike Ash. All rights reserved.
//

import Foundation


public class ObserverSetEntry<Parameters> {
    private weak var object: AnyObject?
    private let queue: dispatch_queue_t?
    private let f: AnyObject -> Parameters -> Void
    
    private init(object: AnyObject, queue: dispatch_queue_t?, f: AnyObject -> Parameters -> Void) {
        self.object = object
        self.queue = queue
        self.f = f
    }
}


public class ObserverSet<Parameters>: CustomStringConvertible {
    // Locking support
    
    private var queue = dispatch_queue_create("com.mikeash.ObserverSet", nil)
    
    private func synchronized(f: Void -> Void) {
        dispatch_sync(queue, f)
    }
    
    
    // Main implementation
    
    private var entries: [ObserverSetEntry<Parameters>] = []
    
    public init() {}
    
    public func add<T: AnyObject>(object object: T, queue: dispatch_queue_t? = nil, _ f: T -> Parameters -> Void) -> ObserverSetEntry<Parameters> {
        let entry = ObserverSetEntry<Parameters>(object: object, queue: queue, f: { f($0 as! T) })
        synchronized {
            self.entries.append(entry)
        }
        return entry
    }
    
    public func add(queue queue: dispatch_queue_t? = nil, f: Parameters -> Void) -> ObserverSetEntry<Parameters> {
        return self.add(object: self, queue: queue) { ignored in f }
    }
    
    public func remove(entry: ObserverSetEntry<Parameters>) {
        synchronized {
            self.entries = self.entries.filter{ $0 !== entry }
        }
    }
    
    public func notify(parameters: Parameters) {
        var toCall: [ObserverSetEntry<Parameters>] = []
        
        synchronized {
            self.entries = self.entries.filter{ $0.object != nil }
            toCall = self.entries
        }
        
        for entry in toCall {
            if let queue = entry.queue {
                // This diverges from NSNotificationCenter which delivers notifications synchronously.
                dispatch_async(queue) {self.notifyEntry(entry, parameters)}
            }
            else {
                // If no queue is specified, deliver notification on the caller's thread synchronousl.
                notifyEntry(entry, parameters)
            }
        }
    }
    
    private func notifyEntry(entry: ObserverSetEntry<Parameters>, _ parameters: Parameters) {
        if let object: AnyObject = entry.object {
            entry.f(object)(parameters)
        }
    }
    
    // Test helper
    
    public var observerCount: Int {
        var count = 0
        synchronized {
            count = self.entries.count
        }
        return count
    }
    
    // Printable
    
    public var description: String {
        var entries: [ObserverSetEntry<Parameters>] = []
        synchronized {
            entries = self.entries
        }
        
        let strings = entries.map{
            entry in
            (entry.object === self
                ? "\(entry.f)"
                : "\(entry.object) \(entry.f)")
        }
        let joined = strings.joinWithSeparator(", ")
        
        return "\(Mirror(reflecting:self)): (\(joined))"
    }
}

