import math

from ast import Node, NodeType
from obj import
  Obj,
  Env,
  setVar,
  getVar,
  containsVar,
  newInteger,
  newFloat,
  newStr,
  newError,
  ObjType,
  hasNumberType,
  promoteToFloatValue,
  TRUE,
  FALSE


proc eval*(node: Node, env: var Env): Obj # Forward declaration

proc toBoolObj(boolValue: bool): Obj =
  if boolValue: TRUE else: FALSE

proc evalProgram(node: Node, env: var Env): Obj =
  var resultValue: Obj = nil
  for statement in node.statements:
    resultValue = eval(statement, env)

    if resultValue == nil:
      continue

    if resultValue.objType == ObjType.OTError:
      return resultValue
  return resultValue

proc evalInfixIntegerExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "+":
      return newInteger(left.intValue + right.intValue)
    of "-":
      return newInteger(left.intValue - right.intValue)
    of "*":
      return newInteger(left.intValue * right.intValue)
    of "/":
      return newFloat(left.intValue / right.intValue)
    of "%":
      return newInteger(left.intValue mod right.intValue)
    of "**":
      return newInteger(left.intValue ^ right.intValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixFloatExpression(operator: string, left: Obj, right: Obj): Obj =
  var
    leftValue: float = left.promoteToFloatValue()
    rightValue: float = right.promoteToFloatValue()

  case operator:
    of "+":
      return newFloat(leftValue + rightValue)
    of "-":
      return newFloat(leftValue - rightValue)
    of "*":
      return newFloat(leftValue * rightValue)
    of "/":
      return newFloat(leftValue / rightValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixStringExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "&":
      return newStr(left.strValue & right.strValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixBooleanExpression(operator: string, left: Obj, right: Obj): Obj =
  case operator:
    of "and":
      return toBoolObj(left.boolValue and right.boolValue)
    of "or":
      return toBoolObj(left.boolValue or right.boolValue)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evalInfixExpression(operator: string, left: Obj, right: Obj): Obj =
  if left.objType == ObjType.OTInteger and right.objType == ObjType.OTInteger:
    return evalInfixIntegerExpression(operator, left, right)
  if left.hasNumberType() and right.hasNumberType():
    return evalInfixFloatExpression(operator, left, right)
  if left.objType == ObjType.OTString and right.objType == ObjType.OTString:
    return evalInfixStringExpression(operator, left, right)
  if left.objType == ObjType.OTBoolean and right.objType == ObjType.OTBoolean:
    return evalInfixBooleanExpression(operator, left, right)

  return newError(errorMsg="Unknown infix operator " & operator)

proc evaluateMinusOperatorExpression(right: Obj): Obj =
  if right.objType == ObjType.OTInteger:
    return newInteger(-right.intValue)
  if right.objType == ObjType.OTFloat:
    return newFloat(-right.floatValue)

  return newError(
    errorMsg="Prefix operator - does not support type " & $(right.objType)
  )

proc evaluateNotOperatorExpression(right: Obj): Obj =
  if right.objType == ObjType.OTBoolean:
    return toBoolObj(not right.boolValue)

  return newError(
    errorMsg="Prefix operator - does not support type " & $(right.objType)
  )

proc evalPrefixExpression(operator: string, right: Obj): Obj =
  case operator:
    of "-":
      return evaluateMinusOperatorExpression(right)
    of "not":
      return evaluateNotOperatorExpression(right)

  return newError(errorMsg="Unknown prefix operator " & operator)

proc evalIdentifier(node: Node, env: var Env) : Obj =
  var exists: bool = containsVar(env, node.identValue)

  if not exists:
    return newError(errorMsg="Name " & node.identValue & " is not defined")

  return getVar(env, node.identValue)


proc eval*(node: Node, env: var Env): Obj =
  case node.nodeType:
    of NTProgram: evalProgram(node, env)
    of NTExpressionStatement: eval(node.expression, env)
    of NTIntegerLiteral: newInteger(intValue=node.intValue)
    of NTFloatLiteral: newFloat(floatValue=node.floatValue)
    of NTStringLiteral: newStr(strValue=node.strValue)
    of NTInfixExpression:
      var infixLeft: Obj = eval(node.infixLeft, env)
      var infixRight: Obj = eval(node.infixRight, env)
      evalInfixExpression(
        node.infixOperator, infixLeft, infixRight
      )
    of NTPrefixExpression:
      var prefixRight: Obj = eval(node.prefixRight, env)
      evalPrefixExpression(node.prefixOperator, prefixRight)
    of NTAssignStatement:
      var assignmentValue = eval(node.assignValue, env)
      env = setVar(env, node.assignName.identValue, assignmentValue)
      nil
    of NTIdentifier: evalIdentifier(node, env)
    of NTBoolean: toBoolObj(node.boolValue)
    #else: nil
