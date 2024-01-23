//
//  TextRepresentation.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/2/23.
//

import Foundation

protocol CodeRepresentable {
    static func parseCode(with: Scanner) -> Self?
    func printCode(with: Printer)
}

extension Optional: CodeRepresentable where Wrapped: CodeRepresentable {
    
    static func parseCode(with scanner: Scanner) -> Optional<Wrapped>? {
        if scanner.peek() == .identifier("nil") {
            _ = scanner.next()
            return nil
        } else {
            return Wrapped.parseCode(with: scanner)
        }
    }
    
    func printCode(with printer: Printer) {
        if let wrapped = self {
            wrapped.printCode(with: printer)
        } else {
            printer.write("nil")
        }
    }
    
}

extension Bool: CodeRepresentable {
    
    static func parseCode(with scanner: Scanner) -> Bool? {
        switch scanner.next() {
        case .identifier("false"):
            return false
        case .identifier("true"):
            return true
        default:
            return nil
        }
    }
    
    func printCode(with printer: Printer) {
        printer.write(self ? "true" : "false")
    }
    
}

extension Int: CodeRepresentable {
    
    static func parseCode(with scanner: Scanner) -> Int? {
        switch scanner.next() {
        case .number(let value):
            return Int(value)
        default:
            return nil
        }
    }
    
    func printCode(with printer: Printer) {
        printer.write(String(self))
    }
    
}

extension Array: CodeRepresentable where Element: CodeRepresentable {
    
    static func parseCode(with scanner: Scanner) -> Array<Element>? {
        guard scanner.next() == .openBracket else { return nil }
        guard let first = Element.parseCode(with: scanner) else { return nil }
        var elements: Array<Element> = [first]
        while scanner.peek() == .comma {
            let _ = scanner.next()
            guard let element = Element.parseCode(with: scanner) else { return nil }
            elements.append(element)
        }
        guard scanner.next() == .closeBracket else { return nil }
        return elements
    }
    
    func printCode(with printer: Printer) {
        printer.write("[")
        printer.with(indentation: 1) {
            for i in indices {
                if i > 0 {
                    printer.write(",\n")
                }
                self[i].printCode(with: printer)
            }
        }
        printer.write("]")
    }
        
}

enum Token: Equatable {
    case end
    case colon, comma, openParen, closeParen, openBracket, closeBracket
    case identifier(String)
    case number(Float64)
    case invalid
}

class Scanner {
    private let text: String
    private var textPosition: String.Index
    
    private struct TokenInfo {
        let token: Token
        let range: ClosedRange<String.Index>
    }
    
    private var tokenInfo: TokenInfo?
    var token: Token { tokenInfo!.token }
    var tokenRange: ClosedRange<String.Index> { tokenInfo!.range }
    var tokenText: String { String(text[tokenInfo!.range]) }
    
    init(for text: String) {
        self.text = text
        self.textPosition = text.startIndex
    }
    
    func peek() -> Token { Scanner.next(text, textPosition).token }
    
    func next() -> Token {
        tokenInfo = Scanner.next(text, textPosition)
        if textPosition != text.endIndex {
            if tokenRange.upperBound == text.endIndex {
                textPosition = text.endIndex
            } else {
                textPosition = text.index(after: tokenRange.upperBound)                
            }
        }
        return token
    }
    
    private static func next(_ text: String, _ textPosition: String.Index) -> TokenInfo {
        var textPosition = textPosition
        while textPosition < text.endIndex && text[textPosition].isWhitespace {
            textPosition = text.index(after: textPosition)
        }
        if textPosition == text.endIndex {
            return TokenInfo(token: .end, range: text.endIndex...text.endIndex)
        }
        
        switch text[textPosition] {
        case ":":
            return TokenInfo(token: .colon, range: textPosition...textPosition)
        case ",":
            return TokenInfo(token: .comma, range: textPosition...textPosition)
        case "(":
            return TokenInfo(token: .openParen, range: textPosition...textPosition)
        case ")":
            return TokenInfo(token: .closeParen, range: textPosition...textPosition)
        case "[":
            return TokenInfo(token: .openBracket, range: textPosition...textPosition)
        case "]":
            return TokenInfo(token: .closeBracket, range: textPosition...textPosition)
        case "A"..."Z", "a"..."z":
            return nextIdentifier(text, textPosition)
        case "0"..."9", "+", "-":
            return nextNumber(text, textPosition)
        default:
            return TokenInfo(token: .invalid, range: textPosition...text.endIndex)
        }
    }
    
    private static func nextIdentifier(_ text: String,
                                       _ textStartPosition: String.Index) -> TokenInfo {
        var textPosition = text.index(after: textStartPosition)
        while textPosition < text.endIndex && text[textPosition].isLetter {
            textPosition = text.index(after: textPosition)
        }
        let textEndPosition = text.index(before: textPosition)
        let range = textStartPosition...textEndPosition
        return TokenInfo(token: .identifier(String(text[range])), range: range)
    }
    
    private static func nextNumber(_ text: String, _ textStartPosition: String.Index) -> TokenInfo {
        var textPosition = text.index(after: textStartPosition)
        while textPosition < text.endIndex &&
                (text[textPosition].isNumber || text[textPosition] == ".") {
            textPosition = text.index(after: textPosition)
        }
        let textEndPosition = text.index(before: textPosition)
        let range = textStartPosition...textEndPosition
        guard let number = Float64(text[range]) else {
            return TokenInfo(token: .invalid, range: range)
        }
        return TokenInfo(token: .number(number), range: range)
    }
    
}

class Printer {
    private(set) var text: String = ""
    private var indentationLevel: Int = 0
    private var indentation: String { String(repeating: " ", count: indentationLevel) }
    
    func with(indentation temporaryIndentation: Int, _ printFunc: () -> ()) {
        self.indentationLevel += temporaryIndentation
        printFunc()
        self.indentationLevel -= temporaryIndentation
    }
    
    func write(_ text: String) {
        self.text += text.replacing("\n", with: "\n" + indentation)
    }
}

func parseArgument<T: CodeRepresentable>(label: String, scanner: Scanner) -> T? {
    guard scanner.next() == .identifier(label) &&
          scanner.next() == .colon else { return nil }
    return T.parseCode(with: scanner)
}

func print<T: CodeRepresentable>(label: String, argument: T, printer: Printer) {
    printer.write(label + ": ")
    printer.with(indentation: label.count + 2) {
        argument.printCode(with: printer)
    }
}

func print(label: String, argument: any CodeRepresentable, printer: Printer) {
    printer.write(label + ": ")
    printer.with(indentation: label.count + 2) {
        argument.printCode(with: printer)
    }
}

func parseArguments<T1: CodeRepresentable, 
                    T2: CodeRepresentable>(labels: [String], 
                                           scanner: Scanner) -> (T1, T2)? {
    guard let arg1: T1 = parseArgument(label: labels[0], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg2: T2 = parseArgument(label: labels[1], scanner: scanner) else { return nil }
    return (arg1, arg2)
}

func parseArguments<T1: CodeRepresentable,
                    T2: CodeRepresentable,
                    T3: CodeRepresentable>(labels: [String], 
                                           scanner: Scanner) -> (T1, T2, T3)? {
    guard let arg1: T1 = parseArgument(label: labels[0], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg2: T2 = parseArgument(label: labels[1], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg3: T3 = parseArgument(label: labels[2], scanner: scanner) else { return nil }
    return (arg1, arg2, arg3)
}

func parseArguments<T1: CodeRepresentable,
                    T2: CodeRepresentable,
                    T3: CodeRepresentable,
                    T4: CodeRepresentable>(labels: [String],
                                           scanner: Scanner) -> (T1, T2, T3, T4)? {
    guard let arg1: T1 = parseArgument(label: labels[0], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg2: T2 = parseArgument(label: labels[1], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg3: T3 = parseArgument(label: labels[2], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg4: T4 = parseArgument(label: labels[3], scanner: scanner) else { return nil }
    return (arg1, arg2, arg3, arg4)
}

func parseArguments<T1: CodeRepresentable,
                    T2: CodeRepresentable,
                    T3: CodeRepresentable,
                    T4: CodeRepresentable,
                    T5: CodeRepresentable>(labels: [String],
                                           scanner: Scanner) -> (T1, T2, T3, T4, T5)? {
    guard let arg1: T1 = parseArgument(label: labels[0], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg2: T2 = parseArgument(label: labels[1], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg3: T3 = parseArgument(label: labels[2], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg4: T4 = parseArgument(label: labels[3], scanner: scanner) else { return nil }
    guard scanner.next() == .comma else { return nil }
    guard let arg5: T5 = parseArgument(label: labels[4], scanner: scanner) else { return nil }
    return (arg1, arg2, arg3, arg4, arg5)
}

func print(labelsAndArguments: [(String, any CodeRepresentable)],
           onSeparateLines: Bool = true,
           printer: Printer) {
    let separator = onSeparateLines ? ",\n" : ", "
    for i in labelsAndArguments.indices {
        if i > 0 {
            printer.write(separator)
        }
        let (label, argument) = labelsAndArguments[i]
        print(label: label, argument: argument, printer: printer)
    }
}

func parseStruct<T>(name: String,
                    scanner: Scanner,
                    _ parseFunc: () -> T?) -> T? {
    guard scanner.next() == .identifier(name) &&
          scanner.next() == .openParen else { return nil }
    guard let result = parseFunc() else { return nil }
    guard scanner.next() == .closeParen else { return nil }
    return result
}

func printStruct(name: String,
                 printer: Printer,
                 _ printFunc: () -> ()) {
    printer.write(name)
    printer.write("(")
    printer.with(indentation: name.count + 1) {
        printFunc()
    }
    printer.write(")")
}

func parse<T: CodeRepresentable>(_ text: String) -> T? {
    let scanner = Scanner(for: text)
    return T.parseCode(with: scanner)
}

func print<T: CodeRepresentable>(_ value: T) -> String {
    let printer = Printer()
    value.printCode(with: printer)
    return printer.text
}

func print(_ value: any CodeRepresentable) -> String {
    let printer = Printer()
    value.printCode(with: printer)
    return printer.text
}
