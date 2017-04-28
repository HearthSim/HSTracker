//
//  AlgorithmTests.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 21/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

class AlgorithmTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	func testLinkedList() {
		let list = LinkedList<Int>()
		
		list.append(value: 0)
		list.append(value: 1)
		list.append(value: 2)
		
		XCTAssertEqual(list.count, 3, "List elements do not match")
		XCTAssertEqual(list.first?.value, 0, "List head does not match")
		XCTAssertEqual(list.last?.value, 2, "List head does not match")
		
		XCTAssertNil(list.nodeAt(index: -1), "Node with negative index exists")
		XCTAssertNil(list.nodeAt(index: 3), "Node with out-of-bounds index exists")
		XCTAssertEqual(list.nodeAt(index: 1)?.value, 1)
		
		list.remove(at: 0)
		XCTAssertEqual(list.first?.value, 1, "List head does not match")
		XCTAssertEqual(list.count, 2, "List elements do not match")
		
		list.clear()
		XCTAssertEqual(list.count, 0, "List elements do not match")
		
	}
	
	func testConcurrentQueue() {
		let queue = ConcurrentQueue<Date>()
		XCTAssert(queue.count == 0, "Queue is not empty")
		
		let date1 = Date()
		let date2 = date1.addingTimeInterval(60)
		let date3 = date2.addingTimeInterval(60)
		
		queue.enqueue(value: date1)
		queue.enqueue(value: date2)
		queue.enqueue(value: date3)
		
		XCTAssertEqual(queue.count, 3, "Queue size is wrong")
		
		XCTAssertEqual(queue.dequeue(), date1, "Dequeued data does not match")
		XCTAssertEqual(queue.count, 2, "Queue size is wrong")
		
		XCTAssertEqual(queue.dequeue(), date2, "Dequeued data does not match")
		XCTAssertEqual(queue.count, 1, "Queue size is wrong")
		
		XCTAssertEqual(queue.dequeue(), date3, "Dequeued data does not match")
		XCTAssertEqual(queue.count, 0, "Queue size is wrong")
		
		queue.enqueue(value: date1)
		queue.enqueue(value: date2)
		queue.enqueue(value: date3)
		
		XCTAssertEqual(queue.count, 3, "Queue size is wrong")
		
		queue.clear()
		
		XCTAssertEqual(queue.count, 0, "Queue size is wrong")
	}
	
}

