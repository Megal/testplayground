import Foundation

public struct StderrOutputStream: OutputStreamType {
	public mutating func write(string: String) { fputs(string, stderr) }
}
public var errStream = StderrOutputStream()

public func log(message: String) {	debugPrint("I: "+message, toStream: &errStream) }
@noreturn public func fatal(message: String = "E: Some fatal error") { log(message); abort() }

