import ArgumentParser
import Hummingbird
import Logging
import PostgresNIO
import TodosCore

@main
struct Todos: AsyncParsableCommand, AppArguments {
  
  @Option(name: .shortAndLong)
  var hostname: String = "127.0.0.1"
  
  @Option(name: .shortAndLong)
  var port: Int = 8080
  
  var inMemoryTesting = true
  
  func run() async throws {
    let app = try await buildApplication(self)
    try await app.runService()
  }
}
