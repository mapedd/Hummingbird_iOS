/// Arguments extracted from commandline
public protocol AppArguments {
  var hostname: String { get}
  var port: Int { get }
  var inMemoryTesting: Bool { get }
}

