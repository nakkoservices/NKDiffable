//
//  NKOrderedSet.swift
//  NKDiffable
//
//  Created by Mihai Fratu on 27/02/2020.
//  Copyright © 2020 Mihai Fratu. All rights reserved.
//

import Foundation

struct NKOrderedSet<T: Hashable>: Hashable, Sequence {
    
    typealias Iterator = Array<T>.Iterator
    
    private var array: Array<T>
    
    var count: Int {
        return array.count
    }
    
    var last: T? {
        return array.last
    }
    
    init() {
        array = Array<T>()
    }
    
    __consuming func makeIterator() -> NKOrderedSet<T>.Iterator {
        return array.makeIterator()
    }
    
    mutating func append(contentsOf newElements: [T]) {
        newElements.forEach { append($0) }
    }
    
    mutating func append(_ element: T) {
        guard !array.contains(element) else { fatalError("Item already in set!") }
        array.append(element)
    }
    
    mutating func insert(_ element: T, before beforeElement: T) {
        guard !array.contains(element) else { fatalError("Item already in set!") }
        array.insert(element, at: array.firstIndex(of: beforeElement)!)
    }
    
    mutating func insert(_ element: T, after afterElement: T) {
        guard !array.contains(element) else { fatalError("Item already in set!") }
        array.insert(element, at: array.firstIndex(of: afterElement)! + 1)
    }
    
    mutating func remove(at index: Int) {
        array.remove(at: index)
    }
    
    mutating func move(from index: Int, to toIndex: Int) {
        array.insert(array.remove(at: index), at: toIndex)
    }
    
    func firstIndex(of element: T) -> Int? {
        return array.firstIndex(of: element)
    }
    
    func map<U>(_ transform: (T) -> U) -> [U] {
        return array.map { transform($0) }
    }
    
    func flatMap<U>(_ transform: (T) -> [U]) -> [U] {
        return array.map { transform($0) }.flatMap { $0 }
    }
    
    subscript(_ index: Int) -> T {
        get {
            return array[index]
        }
        set {
            return array[index] = newValue
        }
    }
    
}
