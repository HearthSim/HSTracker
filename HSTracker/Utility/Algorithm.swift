//
//  Algorithm.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 20/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

/// integer power function operator
precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Int, power: Int) -> Int {
	return Int(pow(Double(radix), Double(power)))
}

// MARK: - Data structures

/// Data structure that handles element in a LIFO way
public class Stack<T> {
    private var data = [T]()
    
    public var count: Int {
        return data.count
    }
    
    public func push(_ element: T) {
        data.append(element)
    }
    
    public func peek() -> T? {
        return data.last
    }
    
    public func pop() -> T? {
        if self.count == 0 {
            return nil
        }
        return data.removeLast()
    }
}

/// Node for linked list containers
public class Node<T> {
    var value: T
    
    var next: Node<T>?
    weak var previous: Node<T>?
    
    init(value: T) {
        self.value = value
    }
}

/// Data structure that stores element in a linked list
public class LinkedList<T> {
    
    fileprivate var head: Node<T>?
    private var tail: Node<T>?
    private var _count: Int = 0
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public var first: Node<T>? {
        return head
    }
    
    public var last: Node<T>? {
        return tail
    }
    
    public func append(_ value: T) {
        
        let newNode = Node(value: value)
        
        if let tailNode = tail {
            newNode.previous = tailNode
            tailNode.next = newNode
        } else {
            head = newNode
        }
        
        tail = newNode
        _count += 1
    }
	
	public func appendAll(_ collection: [T]) {
		for i in collection {
			self.append(i)
		}
	}
    
    public func nodeAt(index: Int) -> Node<T>? {

        if self._count <= index {
            return nil
        }
        
        if index >= 0 {
            var node = head
            var i = index

            while node != nil {
                if i == 0 { return node }
                i -= 1
                node = node!.next
            }
        }

        return nil
    }
    
    public func clear() {
        var cur = tail
        while let node = cur {
          node.next = nil
          cur = cur?.previous
        }

        head = nil
        tail = nil
        _count = 0
    }
    
    public func remove(node: Node<T>) -> T {
        let prev = node.previous
        let next = node.next
        
        if let prev = prev {
            prev.next = next
        } else {
            head = next
        }
        next?.previous = prev
        
        if next == nil {
            tail = prev
        }
        
        self._count -= 1
        
        node.previous = nil 
        node.next = nil
        return node.value
    }
    
    public func remove(at: Int) {
        if let node = nodeAt(index: at) {
            _ = remove(node: node)
        }
    }
    
	public var count: Int {
        return self._count
    }
    
    deinit {
        clear()
    }
}

/**
 * Thread-safe queue implementation
 */
public class ConcurrentQueue<T> {

    private var elements = LinkedList<T>()
    private let lock = UnfairLock()
    
    public func enqueue(value: T) {
        lock.around {
            self.elements.append(value)
        }
    }
	
	public func enqueueAll(collection: [T]) {
        lock.around {
			self.elements.appendAll(collection)
		}
	}
	
    public func dequeue() -> T? {
        return lock.around {
            if let head = self.elements.first {
                return self.elements.remove(node: head)
            }
            return nil
        }
    }
    
	public var count: Int {
        return lock.around {
            return self.elements.count
        }
    }
    
    public func clear() {
        lock.around {
            self.elements.clear()
        }
    }
}

class ConcurrentSet<T: Hashable> {
    let lock = UnfairLock()
    var set = Set<T>()
    
    var count: Int {
        return lock.around {
            return set.count
        }
    }
    
    func insert(_ newElement: T) {
        _ = lock.around {
            set.insert(newElement)
        }
    }
    
    func popFirst() -> T? {
        return lock.around {
            return set.popFirst()
        }
    }
}
