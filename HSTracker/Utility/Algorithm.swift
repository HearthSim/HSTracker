//
//  Algorithm.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 20/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Int, power: Int) -> Int {
	return Int(pow(Double(radix), Double(power)))
}

public class Node<T> {
    var value: T
    
    var next: Node<T>?
    weak var previous: Node<T>?
    
    init(value: T) {
        self.value = value
    }
}

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
    
    public func append(value: T) {
        
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
	
	public func appendAll(collection: [T]) {
		for i in collection {
			self.append(value: i)
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
}

/**
 * Thread-safe queue implementation
 */
public class ConcurrentQueue<T> {

    private var elements = LinkedList<T>()
    private let accessQueue = DispatchQueue(label: "be.michotte.hstracker.concurrentQueue")
    
    public func enqueue(value: T) {
        self.accessQueue.sync {
            self.elements.append(value: value)
        }
    }
	
	public func enqueueAll(collection: [T]) {
		self.accessQueue.sync {
			self.elements.appendAll(collection: collection)
		}
	}
	
    public func dequeue() -> T? {
        var result: T?
        self.accessQueue.sync {
            if let head = self.elements.first {
                result = self.elements.remove(node: head)
            }
        }
        return result
    }
    
	public var count: Int {
        var result = 0
        self.accessQueue.sync {
            result = self.elements.count
        }
        return result
    }
    
    public func clear() {
        self.accessQueue.sync {
            self.elements.clear()
        }
    }
}
