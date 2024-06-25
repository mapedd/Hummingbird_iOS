import Hummingbird
import Foundation

struct TodoController<Repository: TodoRepository> : Sendable {
  // Todo repository
  let repository: Repository
  
  
  // add Todos API to router group
  func addRoutes(to group: RouterGroup<some RequestContext>) {
    group
      .get(":id", use: get)
      .get(use: list)
      .post(use: create)
      .patch(":id", use: update)
      .delete(":id", use: delete)
      .delete(use: deleteAll)
  }
  
  /// Delete all todos endpoint
  func deleteAll(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
    try await self.repository.deleteAll()
    return .ok
  }
  
  /// Get todo endpoint
  func get(request: Request, context: some RequestContext) async throws -> Todo? {
    let id = try context.parameters.require("id", as: UUID.self)
    return try await self.repository.get(id: id)
  }
  
  /// Delete todo endpoint
  func delete(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    if try await self.repository.delete(id: id) {
      return .ok
    } else {
      return .badRequest
    }
  }
  
  struct UpdateRequest: Decodable {
    let title: String?
    let order: Int?
    let completed: Bool?
  }
  /// Update todo endpoint
  func update(request: Request, context: some RequestContext) async throws -> Todo? {
    let id = try context.parameters.require("id", as: UUID.self)
    let request = try await request.decode(as: UpdateRequest.self, context: context)
    guard let todo = try await self.repository.update(
      id: id, 
      title: request.title, 
      order: request.order, 
      completed: request.completed
    ) else {
      throw HTTPError(.badRequest)
    }
    return todo
  }
  
  /// Get list of todos endpoint
  func list(request: Request, context: some RequestContext) async throws -> [Todo] {
    return try await self.repository.list()
  }
  
  struct CreateRequest: Decodable {
    let title: String
    let order: Int?
  }
  /// Create todo endpoint
  func create(request: Request, context: some RequestContext) async throws -> Todo {
    let request = try await request.decode(as: CreateRequest.self, context: context)
    return try await self.repository.create(title: request.title, order: request.order, urlPrefix: "http://localhost:8080/todos/")
  }
}
