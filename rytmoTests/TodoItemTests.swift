//
//  TodoItemTests.swift
//  rytmoTests
//
//  Unit tests for TodoItem model
//

import XCTest
@testable import rytmo

final class TodoItemTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInit_WithTitleOnly() {
        let todo = TodoItem(title: "Test Task")
        
        XCTAssertEqual(todo.title, "Test Task")
        XCTAssertEqual(todo.notes, "")
        XCTAssertFalse(todo.isCompleted)
        XCTAssertNil(todo.dueDate)
        XCTAssertNil(todo.completedAt)
        XCTAssertEqual(todo.orderIndex, 0)
        XCTAssertNotNil(todo.id)
        XCTAssertNotNil(todo.createdAt)
    }
    
    func testInit_WithAllParameters() {
        let dueDate = Date()
        let todo = TodoItem(
            title: "Full Task",
            notes: "Some notes",
            dueDate: dueDate,
            orderIndex: 5
        )
        
        XCTAssertEqual(todo.title, "Full Task")
        XCTAssertEqual(todo.notes, "Some notes")
        XCTAssertEqual(todo.dueDate, dueDate)
        XCTAssertEqual(todo.orderIndex, 5)
    }
    
    // MARK: - ID Uniqueness Tests
    
    func testInit_GeneratesUniqueIDs() {
        let todo1 = TodoItem(title: "Task 1")
        let todo2 = TodoItem(title: "Task 2")
        
        XCTAssertNotEqual(todo1.id, todo2.id)
    }
    
    // MARK: - Completion Tests
    
    func testCompletion_DefaultIsFalse() {
        let todo = TodoItem(title: "Test")
        XCTAssertFalse(todo.isCompleted)
    }
    
    func testCompletion_CanBeToggled() {
        let todo = TodoItem(title: "Test")
        
        todo.isCompleted = true
        XCTAssertTrue(todo.isCompleted)
        
        todo.isCompleted = false
        XCTAssertFalse(todo.isCompleted)
    }
    
    func testCompletedAt_InitiallyNil() {
        let todo = TodoItem(title: "Test")
        XCTAssertNil(todo.completedAt)
    }
    
    func testCompletedAt_CanBeSet() {
        let todo = TodoItem(title: "Test")
        let completionDate = Date()
        
        todo.isCompleted = true
        todo.completedAt = completionDate
        
        XCTAssertEqual(todo.completedAt, completionDate)
    }
    
    // MARK: - Property Modification Tests
    
    func testTitle_CanBeModified() {
        let todo = TodoItem(title: "Original")
        todo.title = "Modified"
        
        XCTAssertEqual(todo.title, "Modified")
    }
    
    func testNotes_CanBeModified() {
        let todo = TodoItem(title: "Test")
        todo.notes = "Updated notes"
        
        XCTAssertEqual(todo.notes, "Updated notes")
    }
    
    func testDueDate_CanBeModified() {
        let todo = TodoItem(title: "Test")
        let newDate = Date().addingTimeInterval(86400)
        
        todo.dueDate = newDate
        
        XCTAssertEqual(todo.dueDate, newDate)
    }
    
    func testOrderIndex_CanBeModified() {
        let todo = TodoItem(title: "Test")
        todo.orderIndex = 10
        
        XCTAssertEqual(todo.orderIndex, 10)
    }
}
