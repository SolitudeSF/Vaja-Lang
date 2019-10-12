import tables

type
  ObjType* = enum
    OTInteger
    OTFloat
    OTString
    OTBoolean
    OTError
  Obj* = ref object
    case objType*: ObjType
      of OTInteger: intValue*: int
      of OTFloat: floatValue*: float
      of OTString: strValue*: string
      of OTBoolean: boolValue*: bool
      of OTError: errorMsg*: string
  Env* = ref object
    store: Table[string, Obj]


proc newEnv*(): Env =
  return Env(store: initTable[string, Obj]())

method setVar*(env: Env, name: string, value: Obj): Env {.base.} =
  env.store[name] = value
  return env

method containsVar*(env: Env, name: string): bool {.base.} =
  return contains(env.store, name)

method getVar*(env: Env, name: string): Obj {.base.} =
  return env.store[name]

method hasNumberType*(obj: Obj): bool {.base.} =
  obj.objType == OTInteger or obj.objType == OTFloat

method promoteToFloatValue*(obj: Obj): float {.base.} =
  if obj.objType == OTInteger:
    return float(obj.intValue)

  if obj.objType == OTFloat:
    return obj.floatValue

method inspect*(obj: Obj): string {.base.} =
  if obj == nil:
    return ""

  case obj.objType:
    of OTInteger: $obj.intValue
    of OTFloat: $obj.floatValue
    of OTString: obj.strValue
    of OTBoolean:
      if obj.boolValue: "true" else: "false"
    of OTError: obj.errorMsg
    #else: ""

proc newInteger*(intValue: int): Obj =
  return Obj(objType: ObjType.OTInteger, intValue: intValue)

proc newFloat*(floatValue: float): Obj =
  return Obj(objType: ObjType.OTFloat, floatValue: floatValue)

proc newBoolean*(boolValue: bool): Obj =
  return Obj(objType: ObjType.OTBoolean, boolValue: boolValue)

proc newStr*(strValue: string): Obj =
  return Obj(objType: ObjType.OTString, strValue: strValue)

proc newError*(errorMsg: string): Obj =
  return Obj(objType: ObjType.OTError, errorMsg: errorMsg)

var
  TRUE*: Obj = newBoolean(boolValue=true)
  FALSE*: Obj = newBoolean(boolValue=true)
