public indirect enum Expression: Hashable {
    case variable(name: String)
    case tag(name: String, attributes: [String:Expression] = [:], body: [Expression] = [])
}

public struct ParseError: Error, Hashable {
    public enum Reason: Hashable {
        case expected(String)
        case expectedClosingTag(String)
        case expectedIdentifier
        case expectedTagName
        case unexpectedRemainder
    }
    public var reason: Reason
    public var offset: String.Index
}

extension String {
    public func parse() throws -> Expression {
        var remainder = self[...]
        return try remainder.parse()
    }
}

extension Substring {
    mutating func remove(prefix: String) -> Bool {
        guard hasPrefix(prefix) else { return false }
        removeFirst(prefix.count)
        return true
    }
    
    mutating func skipWS() {
        while first?.isWhitespace == true {
            removeFirst()
        }
    }

    func err(_ reason: ParseError.Reason) -> ParseError {
        ParseError(reason: reason, offset: startIndex)
    }
    
    mutating func parse() throws -> Expression {
        if remove(prefix: "{") {
            skipWS()
            let name = try parseIdentifier()
            skipWS()
            try remove(expecting: "}")
            return .variable(name: name)
        } else if remove(prefix: "<") {
            let name = try parseTagName()
            try remove(expecting: ">")
            let closingTag = "</\(name)>"
            var body: [Expression] = []
            while !remove(prefix: closingTag) {
                guard !isEmpty else {
                    throw err(.expectedClosingTag(name))
                }
                body.append(try parse())
            }
            return .tag(name: name, body: body)
        } else {
            throw err(.unexpectedRemainder)
        }
    }
    
    mutating func remove(expecting: String) throws {
        guard remove(prefix: expecting) else {
            throw err(.expected(expecting))
        }
    }
    
    mutating func remove(while cond: (Element) -> Bool) -> SubSequence {
        var current = startIndex
        while current < endIndex, cond(self[current]) {
            formIndex(after: &current)
        }
        let result = self[startIndex..<current]
        self = self[current...]
        return result
    }

    mutating func parseTagName() throws -> String {
        let result = remove(while: { $0.isTagName })
        guard !result.isEmpty else { throw err(.expectedTagName) }
        return String(result)
    }

    mutating func parseIdentifier() throws -> String {
        let result = remove(while: { $0.isIdentifier })
        guard !result.isEmpty else { throw err(.expectedIdentifier) }
        return String(result)
    }
}

extension Character {
    var isIdentifier: Bool {
        isLetter
    }

    var isTagName: Bool {
        isLetter
    }
}
