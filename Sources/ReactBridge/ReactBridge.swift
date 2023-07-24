@attached(conformance)
@attached(member, names: named(moduleName), named(_registerModule), named(requiresMainQueueSetup))
public macro ReactModule(jsName: String? = nil, isMainQueue: Bool = false) = #externalMacro(module: "ReactBridgeMacros", type: "ReactModuleMacro")

@attached(peer, names: arbitrary)
public macro ReactMethod(jsName: String? = nil, isSync: Bool = false) = #externalMacro(module: "ReactBridgeMacros", type: "ReactMethodMacro")

@attached(peer, names: arbitrary)
public macro ReactViewProperty() = #externalMacro(module: "ReactBridgeMacros", type: "ReactViewPropertyMacro")
