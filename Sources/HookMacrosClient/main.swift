
import HookMacros
import Foundation

@_silgen_name("MSHookFunction")
func MSHookFunction(_ target: UnsafeMutableRawPointer, _ replacement: UnsafeMutableRawPointer, _ orig: UnsafeMutablePointer<UnsafeMutableRawPointer?>?)

@_silgen_name("MSHookMessageEx")
func MSHookMessageEx(_ cls: AnyClass, _ sel: Selector, _ imp: IMP, _ orig: UnsafeMutablePointer<UnsafeMutableRawPointer?>?)

#hookf(target: atoi, closure: { (thingy: UnsafePointer<CChar>?, orig: (@convention(c) (UnsafePointer<CChar>?) -> Int32)) -> Int32 in
    print("orig:", orig("4"))
    return 0
})

print("rep: ", atoi("4"))

#hookf(target: socket, closure: { (x0: Int32, x1: Int32, x2: Int32, socketOrig: (@convention(c) (Int32, Int32, Int32) -> Int32)) -> Int32 in
    let orig_ = socketOrig(x0, x1, x2)
    print("orig:", orig_)
    return 0
})

print("rep: ", socket(0, 4, 3))

#hook(cls: "NSObject", sel: "isProxy", imp: { (cls: NSObject, _cmd: Selector, orig: (@convention(c) (NSObject, Selector) -> Bool)) -> Bool in
    print("uwu", orig(cls, _cmd))
    return true
})

print(NSObject().isProxy())
