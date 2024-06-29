import ArgumentParser
import TodosCore
import AsyncHTTPClient
import Foundation
import NIOCore
import Logging

let logger = {
  var logger = Logger(label: "Todos.Tester")
  logger.logLevel = .debug
  return logger
}()

@main
struct TodosTester: AsyncParsableCommand {
  
  var client: HTTPClient {
    .shared
  }
  
  func run() async throws {
    let response = try await client.execute(CreateRequest(title: "Tittle", order: 1).httpRequest(), timeout: .seconds(30))
    guard response.status == .ok else {
      logger.debug("error status = \(response.status)")
      return
    }
    let output: Todo = try await response.decode()
    logger.debug("response = \(output)")
   
    try await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
  }
}

extension HTTPClientResponse {
  func decode<T: Decodable>() async throws -> T {
    let body = try await self.body.collect(upTo: 1024 * 1024) // 1 MB
    let responseBody = Data(buffer: body)
    let output = try JSONDecoder().decode(T.self, from: responseBody)
    return output
  }
}

extension CreateRequest {
  func httpRequest() throws -> HTTPClientRequest {
    var request = HTTPClientRequest(url: "http://127.0.0.1:8080/todos")
    request.method = .POST
    let encoder = JSONEncoder()
    var buffer = ByteBuffer()
    try encoder.encode(self, into: &buffer)
    request.body = .bytes(buffer)
    return request
  }
}
