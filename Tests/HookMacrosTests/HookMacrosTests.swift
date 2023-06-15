import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import HookMacrosMacros

let testMacros: [String: Macro.Type] = [
    "functionHook": HookMacro.self,
    "messageHook": HookMacro.self,
]

final class HookMacrosTests: XCTestCase {
    func testMacro() {
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
    }

    func testMacroWithStringLiteral() {
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
    }
}
