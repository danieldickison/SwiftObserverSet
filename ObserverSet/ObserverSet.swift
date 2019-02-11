//
//  ObserverSet.swift
//  ObserverSet
//
//  Created by Mike Ash on 1/22/15.
//  Copyright (c) 2015 Mike Ash. All rights reserved.
//

import Foundation


public class ObserverSetEntry<Parameters> {
    fileprivate weak var object: AnyObject?
    fileprivate let queue: DispatchQueue?
    fileprivate let f: (AnyObject) -> (Parameters) -> Void
    
    fileprivate init(object: AnyObject, queue: DispatchQueue?, f: @escaping (AnyObject) -> (Parameters) -> Void) {
        self.object = object
        self.queue = queue
        self.f = f
    }
}


public class ObserverSet<Parameters>: CustomStringConvertible {
    // Locking support
    
    private var queue = DispatchQueue(label: "com.mikeash.ObserverSet")
    
    private func synchronized(f: () -> Void) {
        queue.sync(execute: f)
    }
    
    
    // Main implementation
    
    private var entries: [ObserverSetEntry<Parameters>] = []
    
    public init() {}
    
    @discardableResult
    public func add<T: AnyObject>(object: T, queue: DispatchQueue? = nil, _ f: @escaping (T) -> (Parameters) -> Void) -> ObserverSetEntry<Parameters> {
        let entry = ObserverSetEntry<Parameters>(object: object, queue: queue, f: { f($0 as! T) })
        synchronized {
            self.entries.append(entry)
        }
        return entry
    }
    
    @discardableResult
    public func add(queue: DispatchQueue? = nil, _ f: @escaping (Parameters) -> Void) -> ObserverSetEntry<Parameters> {
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
                queue.async { self.notify(entry: entry, parameters) }
            }
            else {
                // If no queue is specified, deliver notification on the caller's thread synchronousl.
                notify(entry: entry, parameters)
            }
        }
    }
    
    private func notify(entry: ObserverSetEntry<Parameters>, _ parameters: Parameters) {
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
                : "\(String(describing: entry.object)) \(entry.f)")
        }
        let joined = strings.joined(separator: ", ")
        
        return "\(Mirror(reflecting:self)): (\(joined))"
    }
}

