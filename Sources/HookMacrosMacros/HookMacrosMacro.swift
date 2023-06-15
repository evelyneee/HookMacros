import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct HookMacro: ExpressionMacro {
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        
        var returnType: String? = nil
        var arguments: [String] = []
        var target: String! = nil
        var closure: String = ""
        var argNames: [String] = []
        
        let typeToken = node.argumentList.forEach { item in
            
            if item.firstToken(viewMode: .fixedUp)?.text == "target" {
                target = item.expression.description
            }
            
            if item.firstToken(viewMode: .fixedUp)?.text == "closure" {
                closure = String(describing: item.expression.description)
                let signature: ClosureSignatureSyntax? = item.expression.as(ClosureExprSyntax.self)?.signature
                returnType = signature?.output?.returnType.description
                signature!.input!.as(ClosureParameterClauseSyntax.self)!.parameterList.dropLast().forEach { item in
                    argNames.append(item.firstName.text)
                    if let type = item.type?.as(SimpleTypeIdentifierSyntax.self) {
                        arguments.append(type.description)
                    } else if let type = item.type?.as(OptionalTypeSyntax.self)?.wrappedType.as(SimpleTypeIdentifierSyntax.self) {
                        arguments.append(type.description+"?")
                    }
                }
            }
        }
                
        let args = arguments.joined(separator: ", ")
        return """
        {
            var orig_\(raw:target!): UnsafeMutableRawPointer? = nil
            
            let target_\(raw:target!)_cl_$$: @convention (c) (\(raw: args)) -> \(raw: returnType!) = \(raw: target!);
            let target_\(raw:target!)_ptr_$$: UnsafeMutableRawPointer = unsafeBitCast(target_\(raw:target!)_cl_$$, to: UnsafeMutableRawPointer.self);
                    
            let rep_cl_$$: @convention (c) (\(raw: args)) -> \(raw: returnType!) = { \(raw:argNames.joined(separator: ", ")) in
                let closure_cl_$$: @convention (c) (\(raw: args), @convention (c) (\(raw: args)) -> \(raw: returnType!)) -> \(raw: returnType!) = \(raw: closure)
                let proper_orig = unsafeBitCast(
                    UnsafeRawPointer(bitPattern: UInt(String(cString: getenv("ORIG_\(raw:target!)")!).dropFirst(2), radix: 16)!),
                    to: (@convention (c) (\(raw: args)) -> \(raw: returnType!)).self
                )
                return closure_cl_$$(\(raw:argNames.joined(separator: ", ")), proper_orig)
            }
            let rep_ptr_$$: UnsafeMutableRawPointer = unsafeBitCast(rep_cl_$$, to: UnsafeMutableRawPointer.self);
            
            MSHookFunction(target_\(raw:target!)_ptr_$$, rep_ptr_$$, &orig_\(raw:target!))
        
            setenv("ORIG_\(raw:target!)", String(describing: orig_\(raw:target!)!), 1)
            return
        }()
        """
    }
}

public struct SwizzleMacro: ExpressionMacro {
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        
        var returnType: String? = nil
        var arguments: [String] = []
        var cls: String? = nil
        var sel: String? = nil
        var closure: String = ""
        var argNames: [String] = []
        
        node.argumentList.forEach { item in
            
            if item.firstToken(viewMode: .fixedUp)?.text == "cls" {
                cls = String(String(item.expression.description.dropFirst()).dropLast())
            }
            
            if item.firstToken(viewMode: .fixedUp)?.text == "sel" {
                sel = String(String(item.expression.description.dropFirst()).dropLast())
            }
            
            if item.firstToken(viewMode: .fixedUp)?.text == "imp" {
                closure = String(describing: item.expression.description)
                let signature: ClosureSignatureSyntax? = item.expression.as(ClosureExprSyntax.self)?.signature
                returnType = signature?.output?.returnType.description
                signature?.input?.as(ClosureParameterClauseSyntax.self)?.parameterList.dropLast().forEach { item in
                    argNames.append(item.firstName.text)
                    if let type = item.type?.as(SimpleTypeIdentifierSyntax.self) {
                        arguments.append(type.description)
                    } else if let type = item.type?.as(OptionalTypeSyntax.self)?.wrappedType.as(SimpleTypeIdentifierSyntax.self) {
                        arguments.append(type.description+"?")
                    }
                }
            }
        }
                
        var args = arguments.joined(separator: ", ")
        args.removeAll(where: { $0 == "\n"})
        
        return """
        {
        /* \(raw:cls!) \(raw:sel!)*/
            var orig_\(raw:cls!)_\(raw:sel!): UnsafeMutableRawPointer? = nil
            
            let target_\(raw:cls!)_$$: AnyClass = NSClassFromString("\(raw:cls!)")!
            let target_\(raw:sel!)_$$: Selector = NSSelectorFromString("\(raw:sel!)")
                    
            let rep_\(raw:cls!)_\(raw:sel!)_cl_$$: @convention (c) (\(raw: args)) -> \(raw: returnType!) = { \(raw:argNames.joined(separator: ", ")) in
                let closure_cl_$$: @convention (c) (\(raw: args), @convention (c) (\(raw: args)) -> \(raw: returnType!)) -> \(raw: returnType!) = \(raw: closure)
                let proper_orig = unsafeBitCast(
                    UnsafeRawPointer(bitPattern: UInt(String(cString: getenv("ORIG_\(raw:cls!)_\(raw:sel!)")!).dropFirst(2), radix: 16)!),
                    to: (@convention (c) (\(raw: args)) -> \(raw: returnType!)).self
                )
                return closure_cl_$$(\(raw:argNames.joined(separator: ", ")), proper_orig)
            }
            let rep_ptr_\(raw:cls!)_\(raw:sel!)_$$: UnsafeMutableRawPointer = unsafeBitCast(rep_\(raw:cls!)_\(raw:sel!)_cl_$$, to: UnsafeMutableRawPointer.self);
            
            guard let method = class_getInstanceMethod(target_\(raw:cls!)_$$, target_\(raw:sel!)_$$) ?? class_getClassMethod(target_\(raw:cls!)_$$, target_\(raw:sel!)_$$) else {
                return
            }

            let old = class_replaceMethod(target_\(raw:cls!)_$$, target_\(raw:sel!)_$$, .init(UnsafeMutableRawPointer(rep_ptr_\(raw:cls!)_\(raw:sel!)_$$)), method_getTypeEncoding(method))

            if let old,
                let fp = unsafeBitCast(old, to: UnsafeMutableRawPointer?.self) {
                orig_\(raw:cls!)_\(raw:sel!) = fp
            } else if let superclass = class_getSuperclass(target_\(raw:cls!)_$$),
                        let ptr = class_getMethodImplementation(superclass, target_\(raw:sel!)_$$),
                        let fp = unsafeBitCast(ptr, to: UnsafeMutableRawPointer?.self) {
                orig_\(raw:cls!)_\(raw:sel!) = fp
            }
        
        
            setenv("ORIG_\(raw:cls!)_\(raw:sel!)", String(describing: orig_\(raw:cls!)_\(raw:sel!)!), 1)
        }()
        """
    }
}


@main
struct HookMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        HookMacro.self,
        SwizzleMacro.self,
    ]
}
