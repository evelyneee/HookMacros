
@freestanding(expression)
public macro hookf<T, C>(target: T, closure: C) = #externalMacro(module: "HookMacrosMacros", type: "HookMacro")

@freestanding(expression)
public macro hook<C>(cls: String, sel: String, imp: C) = #externalMacro(module: "HookMacrosMacros", type: "SwizzleMacro")
