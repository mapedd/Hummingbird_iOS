import Testing
import Hummingbird
import Foundation
import HummingbirdTesting
@testable import Todos
import Logging

struct Todos {
  let logger = Logger(label: "Todos.testing")
  struct TestArguments: AppArguments {
    let hostname = "127.0.0.1"
    let port = 8080
    let inMemoryTesting = true
  }
  
  struct CreateRequest: Encodable {
    let title: String
    let order: Int?
  }
  
  func create(title: String, order: Int? = nil, client: some TestClientProtocol) async throws -> Todo {
    let request = CreateRequest(title: title, order: order)
    let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
    return try await client.execute(uri: "/todos", method: .post, body: buffer) { response in
      #expect(response.status == .ok)
      return try JSONDecoder().decode(Todo.self, from: response.body)
    }
  }
  
  func get(id: UUID, client: some TestClientProtocol) async throws -> (todo: Todo?, status: HTTPResponse.Status) {
    try await client.execute(uri: "/todos/\(id)", method: .get) { response in
      if response.body.readableBytes > 0 {
        return (try JSONDecoder().decode(Todo.self, from: response.body), response.status)
      } else {
        return (nil, response.status)
      }
    }
  }
  
  func list(client: some TestClientProtocol) async throws -> [Todo] {
    try await client.execute(uri: "/todos", method: .get) { response in
      #expect(response.status == .ok)
      return try JSONDecoder().decode([Todo].self, from: response.body)
    }
  }
  
  struct UpdateRequest: Encodable {
    let title: String?
    let order: Int?
    let completed: Bool?
  }
  
  func patch(
    id: UUID,
    title: String? = nil,
    order: Int? = nil,
    completed: Bool? = nil,
    client: some TestClientProtocol
  ) async throws -> (todo: Todo?, status: HTTPResponse.Status) {
    let request = UpdateRequest(title: title, order: order, completed: completed)
    let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
    return try await client.execute(uri: "/todos/\(id)", method: .patch, body: buffer) { response in
      if response.body.readableBytes > 0 {
        return (try JSONDecoder().decode(Todo.self, from: response.body), response.status)
      } else {
        return (nil, response.status)
      }
    }
  }
  
  func delete(id: UUID, client: some TestClientProtocol) async throws -> HTTPResponse.Status {
    try await client.execute(uri: "/todos/\(id)", method: .delete) { response in
      response.status
    }
  }
  
  func deleteAll(client: some TestClientProtocol) async throws -> Void {
    try await client.execute(uri: "/todos", method: .delete) { _ in }
  }
  
  @Test
  func create() async throws {
    let app = try await buildApplication(TestArguments())
    try await app.test(.router) { client in
      let todo = try await self.create(title: "My first todo", client: client)
      #expect(todo.title == "My first todo")
    }
  }
  
  @Test
  func patch() async throws {
    let app = try await buildApplication(TestArguments())
    try await app.test(.router) { client in
      // create todo
      let todo = try await self.create(title: "Deliver parcels to James", client: client)
      // rename it
      _ = try await self.patch(id: todo.id, title: "Deliver parcels to Claire", client: client)
      let editedTodo = try await self.get(id: todo.id, client: client).todo
      #expect(editedTodo?.title == "Deliver parcels to Claire")
      // set it to completed
      _ = try await self.patch(id: todo.id, completed: true, client: client)
      let editedTodo2 = try await self.get(id: todo.id, client: client).todo
      #expect(editedTodo2?.completed == true)
      // revert it
      _ = try await self.patch(id: todo.id, title: "Deliver parcels to James", completed: false, client: client)
      let editedTodo3 = try await self.get(id: todo.id, client: client).todo
      #expect(editedTodo3?.title == "Deliver parcels to James")
      #expect(editedTodo3?.completed == false)
    }
  }
  
  @Test
  func integrationAPI() async throws {
    let app = try await buildApplication(TestArguments())
    try await app.test(.router) { client in
      // create two todos
      let todo1 = try await self.create(title: "Wash my hair", client: client)
      let todo2 = try await self.create(title: "Brush my teeth", client: client)
      // get first todo
      let getTodo = try await self.get(id: todo1.id, client: client).todo
      #expect(getTodo == todo1)
      // patch second todo
      let optionalPatchedTodo = try await self.patch(id: todo2.id, completed: true, client: client).todo
      let patchedTodo = try  #require(optionalPatchedTodo)
      #expect(patchedTodo.completed == true)
      #expect(patchedTodo.title == todo2.title)
      // get all todos and check first todo and patched second todo are in the list
      let todos = try await self.list(client: client)
      _ = try #require(todos.firstIndex(of: todo1))
      _ = try #require(todos.firstIndex(of: patchedTodo))
      // delete a todo and verify it has been deleted
      let status = try await self.delete(id: todo1.id, client: client)
      #expect(status == .ok)
      let deletedTodo = try await self.get(id: todo1.id, client: client)
      #expect(deletedTodo.todo == nil)
      // delete all todos and verify there are none left
      try await self.deleteAll(client: client)
      let todos2 = try await self.list(client: client)
      #expect(todos2.count == 0)
    }
  }
  
  @Test
  func deletingTodoTwiceReturnsBadRequest() async throws {
    let app = try await buildApplication(TestArguments())
    try await app.test(.router) { client in
      
      let todo = try await self.create(title: "Wash my hair", client: client)
      
      let status = try await self.delete(id: todo.id, client: client)
      #expect(status == .ok)
      let deletedTodo = try await self.get(id: todo.id, client: client)
      #expect(deletedTodo.todo == nil)
      #expect(deletedTodo.status == .noContent)
      let statusDeleted = try await self.delete(id: todo.id, client: client)
      #expect(statusDeleted == .badRequest)
    }
  }
  
  @Test
  func gettingTodoWithInvalidUUIDReturnsBadRequest() async throws {
    let app = try await buildApplication(TestArguments())
    try await app.test(.router) { client in
      let status = try await self.get(id: UUID(uuidString: "58460d0c-82ac-4c13-8270-4a9532ce213e")!, client: client).status
      #expect(status == .noContent)
    }
  }
  
  @Test
  func concurrentlyCreatedTodosAreAllCreated() async throws {
    let app = try await buildApplication(TestArguments())
    let values = Array(0...30)
    
    let uuids = try await withThrowingTaskGroup(of: UUID.self, returning: [UUID].self) { taskGroup in
      for value in values {
        taskGroup.addTask {
          let uuid = try await app.test(.router) { client in
            logger.info("creating at \(value)")
            let todo = try await self.create(title: "item_\(value)", client: client)
            logger.info("created at \(value)")
            return todo.id
          }
          return uuid
        }
      }
      
      var uuids = [UUID]()
      for try await result in taskGroup {
        uuids.append(result)
      }
      return uuids
    }
    
    await withThrowingTaskGroup(of: Void.self) { group in
      for uuid in uuids {
        group.addTask {
          try await app.test(.router) { client in
            logger.info("reading for \(uuid)")
            let status = try await self.get(id: uuid, client: client).status
            logger.info("found \(uuid) \(status)")
            #expect(status == .ok)
          }
        }
      }
    }
  }
  
  @Test
  func updatingNonExistentTodoReturnsBadRequest() async throws {
    let app = try await buildApplication(TestArguments())
    try await app.test(.router) { client in
      let optionalPatchedTodo = try await self.patch(id: UUID(uuidString: "58460d0c-82ac-4c13-8270-4a9532ce213e")!, completed: true, client: client)
      #expect(optionalPatchedTodo.status == .badRequest)
    }
  }
}
