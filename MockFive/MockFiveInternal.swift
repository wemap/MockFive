import Foundation

extension Mock {
    fileprivate(set) public var invocations: [String] { get { return mockRecords[mockFiveLock] ?? [] } set(new) { mockRecords[mockFiveLock] = new } }
    
    public func resetMock() {
        mockRecords[mockFiveLock] = []
        mockBlocks[mockFiveLock] = [:]
    }
    
    public func unregisterStub(_ identifier: String) {
        var blocks = mockBlocks[mockFiveLock] ?? [:] as [String:Any]
        blocks.removeValue(forKey: identifier)
        mockBlocks[mockFiveLock] = blocks
    }
    
    public func registerStub<T>(_ identifier: String, returns: @escaping ([Any?]) -> T) {
        var blocks = mockBlocks[mockFiveLock] ?? [:] as [String:Any]
        blocks[identifier] = returns
        mockBlocks[mockFiveLock] = blocks
    }
    
    public func stub<T: ExpressibleByNilLiteral>(identifier: String, arguments: Any?..., function: String = #function, returns: ([Any?]) -> T = { _ in nil }) -> T {
        logInvocation(stringify(function, arguments: arguments, returnType: "\(T.self)"))
        if let registeredStub = mockBlocks[mockFiveLock]?[identifier] {
            guard let typecastStub = registeredStub as? ([Any?]) -> T else { fatalError("MockFive: Incompatible block of type '\(type(of: (registeredStub) as AnyObject))' registered for function '\(identifier)' requiring block type '([Any?]) -> \(T.self)'") }
            return typecastStub(arguments)
        }
        else { return returns(arguments) }
    }
    
    public func stub<T>(identifier: String, arguments: Any?..., function: String = #function, returns: ([Any?]) -> T) -> T {
        logInvocation(stringify(function, arguments: arguments, returnType: "\(T.self)"))
        if let registeredStub = mockBlocks[mockFiveLock]?[identifier] {
            guard let typecastStub = registeredStub as? ([Any?]) -> T else { fatalError("MockFive: Incompatible block of type '\(type(of: (registeredStub) as AnyObject))' registered for function '\(identifier)' requiring block type '([Any?]) -> \(T.self)'") }
            return typecastStub(arguments)
        }
        else { return returns(arguments) }
    }
    
    public func stub(identifier: String, arguments: Any?..., function: String = #function, returns: ([Any?]) -> () = { _ in }) {
        logInvocation(stringify(function, arguments: arguments, returnType: .none))
        if let registeredStub = mockBlocks[mockFiveLock]?[identifier] {
            guard let typecastStub = registeredStub as? ([Any?]) -> () else { fatalError("MockFive: Incompatible block of type '\(type(of: (registeredStub) as AnyObject))' registered for function '\(identifier)' requiring block type '([Any?]) -> ()'") }
            typecastStub(arguments)
        }
        else { returns(arguments) }
    }
    
    // Utility stuff
    fileprivate func logInvocation(_ invocation: String) {
        var invocations = [String]()
        invocations.append(invocation)
        if let existingInvocations = mockRecords[mockFiveLock] { invocations = existingInvocations + invocations }
        mockRecords[mockFiveLock] = invocations
    }
}
   
public func resetMockFive() { globalObjectIDIndex = 0; mockRecords = [:]; mockBlocks = [:] }
public func lock(_ signature: String = #file + ":\(#line):\(OSAtomicIncrement32(&globalObjectIDIndex))") -> String { return signature }

func + <T, U> (left: [T:U], right: [T:U]) -> [T:U] {
    var result: [T:U] = [:]
    for (k, v) in left  { result.updateValue(v, forKey: k) }
    for (k, v) in right { result.updateValue(v, forKey: k) }
    return result
}

// Private
private var globalObjectIDIndex: Int32 = 0
private var mockRecords: [String:[String]] = [:]
private var mockBlocks: [String:[String:Any]] = [:]

private func stringify(_ function: String, arguments: [Any?], returnType: String?) -> String {
    var invocation = ""
    let arguments = arguments.map { $0 ?? "nil" } as [Any]
    if .none == function.rangeOfCharacter(from: CharacterSet(charactersIn: "()")) {
        invocation = function + "(\(arguments.first ?? "nil"))"
        if let returnType = returnType { invocation += " -> \(returnType)" }
    } else if let _ = function.range(of: "()") {
        invocation = function
        if let returnType = returnType { invocation += " -> \(returnType)" }
    } else {
        let startIndex = function.range(of: "(")!.upperBound
        let endIndex = function.range(of: ")")!.lowerBound
        invocation += function.substring(to: startIndex)
        
        let argumentLabels = function.substring(with: (startIndex ..< endIndex)).components(separatedBy: ":")
        for i in 0..<argumentLabels.count - 1 {
            invocation += argumentLabels[i] + ": "
            if (i < arguments.count) { invocation += "\(arguments[i])" }
            invocation += ", "
        }
        invocation = invocation.substring(to: invocation.characters.index(invocation.endIndex, offsetBy: -2)) + ")"
        if let returnType = returnType { invocation += " -> \(returnType)" }
        if argumentLabels.count - 1 != arguments.count {
            invocation += " [Expected \(argumentLabels.count - 1), got \(arguments.count)"
            if argumentLabels.count < arguments.count {
                let remainder = arguments[argumentLabels.count - 1..<arguments.count]
                let roughArguments = remainder.reduce(": ", { $0 + "\($1), " })
                invocation += roughArguments.substring(to: roughArguments.characters.index(roughArguments.endIndex, offsetBy: -2))
            }
            invocation += "]"
        }
    }
    return invocation
}

// Testing
func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never  {
    FatalErrorUtil.fatalErrorClosure(message(), file, line)
}

struct FatalErrorUtil {
    static var fatalErrorClosure: (String, StaticString, UInt) -> Never = defaultFatalErrorClosure
    fileprivate static let defaultFatalErrorClosure = { Swift.fatalError($0, file: $1, line: $2) }
    static func replaceFatalError(_ closure: @escaping (String, StaticString, UInt) -> Never) { fatalErrorClosure = closure }
    static func restoreFatalError() { fatalErrorClosure = defaultFatalErrorClosure }
}
