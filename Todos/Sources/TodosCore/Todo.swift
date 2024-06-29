import Foundation
import Hummingbird

extension Todo: Codable {}
extension Todo: Equatable {}

public struct Todo: Sendable {
  public init(
    id: UUID,
    title: String,
    order: Int? = nil,
    url: String,
    completed: Bool? = nil
  ) {
    self.id = id
    self.title = title
    self.order = order
    self.url = url
    self.completed = completed
  }
  
  // Todo ID
  public var id: UUID
  // Title
  public var title: String
  // Order number
  public var order: Int?
  // URL to get this ToDo
  public var url: String
  // Is Todo complete
  public var completed: Bool?
}

extension Todo: ResponseEncodable {}
