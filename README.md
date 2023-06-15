# HookMacros
Swift 5.9 function hooking macros

```swift
#hookf(target: socket, closure: { (x0: Int32, x1: Int32, x2: Int32, socketOrig: (@convention(c) (Int32, Int32, Int32) -> Int32)) -> Int32 in
    let orig_ = socketOrig(x0, x1, x2)
    print("orig:", orig_)
    return 0
})

#hook(cls: "NSObject", sel: "isProxy", imp: { (cls: NSObject, _cmd: Selector, orig: (@convention(c) (NSObject, Selector) -> Bool)) -> Bool in
    print("orig:", orig(cls, _cmd))
    return true
})
```

Check out HookMacrosClient for examples. 
