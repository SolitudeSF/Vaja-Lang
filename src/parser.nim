import tables
from strutils import parseInt, parseFloat

from lexer import Lexer, nextToken
from token import Token, TokenType
from ast import
  newProgram,
  newExpressionStatement,
  newIntegerLiteral,
  newFloatLiteral,
  newPrefixExpression,
  newInfixExpression,
  newIdentifier,
  newBoolean,
  newStringLiteral,
  newAssignStatement,
  Node,
  toCode

type
  Parser* = object
    lexer*: Lexer
    errors*: seq[string]
    curToken: Token
    peekToken: Token
  Precedence* = enum
    LOWEST = 0
    SUM = 4
    PRODUCT = 5
    PREFIX = 6
var
  precedences: Table[TokenType, Precedence] = {
    TokenType.PLUS: Precedence.SUM,
    TokenType.MINUS: Precedence.SUM,
    TokenType.SLASH: Precedence.PRODUCT,
    TokenType.ASTERISK: Precedence.PRODUCT,
    TokenType.MODULO: Precedence.PRODUCT,
    TokenType.EXPONENT: Precedence.PRODUCT,
    TokenType.AMP: Precedence.PRODUCT,
  }.toTable

method nextParserToken(parser: var Parser): Token {.base.} =
  parser.curToken = parser.peekToken
  parser.peekToken = parser.lexer.nextToken()

  return parser.curToken

proc parseIntegerLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
    intValue: int = parseInt(literal)
  return newIntegerLiteral(token=parser.curToken, intValue=intValue)

proc parseFloatLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
    floatValue: float = parseFloat(literal)
  return newFloatLiteral(token=parser.curToken, floatValue=floatValue)

proc parseIdentifier(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
  return newIdentifier(token=parser.curToken, identValue=literal)

proc parseBoolean(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
  return newBoolean(token=parser.curToken, boolValue=literal == "true")

proc parseStringLiteral(parser: var Parser): Node =
  var
    literal: string = parser.curToken.literal
  return newStringLiteral(token=parser.curToken, strValue=literal)

method parseExpression(parser: var Parser, precedence: Precedence): Node {.base.} # forward declaration

proc parsePrefixExpression(parser: var Parser): Node =
  var
    token: Token = parser.curToken
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(Precedence.PREFIX)
  return newPrefixExpression(
    token=token, prefixRight=right, prefixOperator=token.literal
  )

type PrefixFunction = proc (parser: var Parser): Node

proc getPrefixFn(tokenType: TokenType): PrefixFunction =
  return case tokenType:
    of MINUS: parsePrefixExpression
    of INT: parseIntegerLiteral
    of FLOAT: parseFloatLiteral
    of IDENT: parseIdentifier
    of TRUE: parseBoolean
    of FALSE: parseBoolean
    of STRING: parseStringLiteral
    else: nil

method currentPrecedence(parser: var Parser): Precedence {.base.} =
  if not precedences.hasKey(parser.curToken.tokenType):
    return Precedence.LOWEST

  return precedences[parser.curToken.tokenType]

method peekPrecedence(parser: var Parser): Precedence {.base.} =
  if not precedences.hasKey(parser.peekToken.tokenType):
    return Precedence.LOWEST

  return precedences[parser.peekToken.tokenType]

method parseInfixExpression(parser: var Parser, left: Node): Node {.base.} =
  var
    token: Token = parser.curToken
    precedence: Precedence = parser.currentPrecedence()
  discard parser.nextParserToken()

  var right: Node = parser.parseExpression(precedence)
  return newInfixExpression(
    token=token, infixLeft=left, infixRight=right, infixOperator=token.literal
  )

type InfixFunction = proc (parser: var Parser, left: Node): Node

proc getInfixFn(tokenType: TokenType): InfixFunction =
  return case tokenType:
    of PLUS: parseInfixExpression
    of MINUS: parseInfixExpression
    of SLASH: parseInfixExpression
    of ASTERISK: parseInfixExpression
    of MODULO: parseInfixExpression
    of EXPONENT: parseInfixExpression
    of AMP: parseInfixExpression
    else: nil

method parseExpression(parser: var Parser, precedence: Precedence): Node =
  var
    prefixFn = getPrefixFn(parser.curToken.tokenType)

  if prefixFn == nil:
    var errorMsg = "No prefix found for " & $(parser.curToken.tokenType)
    parser.errors.add(errorMsg)
    echo errorMsg
    return

  var
    leftExpression: Node = prefixFn(parser)

  while (
    parser.peekToken.tokenType != TokenType.SEMICOLON and
    precedence < parser.peekPrecedence()
  ):
    var
      infixFn = getInfixFn(parser.peekToken.tokenType)

    if infixFn == nil:
      return leftExpression

    discard parser.nextParserToken()
    leftExpression = infixFn(parser, leftExpression)

  return leftExpression

method parseExpressionStatement(parser: var Parser): Node {.base.} =
  var
    expression = parser.parseExpression(Precedence.LOWEST)
  return newExpressionStatement(token=parser.curToken, expression=expression)

method parseAssignmentStatement(parser: var Parser): Node {.base.} =
  var
    token: Token = parser.nextParserToken()
    identToken: Token = parser.curToken
    assignName: Node = newIdentifier(token=identToken, identValue=token.literal)

  discard parser.nextParserToken()
  discard parser.nextParserToken()

  var assignValue: Node = parser.parseExpression(Precedence.LOWEST)

  if parser.peekToken.tokenType in [TokenType.NEWLINE, TokenType.SEMICOLON]:
    discard parser.nextParserToken()

  return newAssignStatement(
    token=token,
    assignName=assignName,
    assignValue=assignValue,
  )

method parseStatement(parser: var Parser): Node {.base.} =
  if parser.curToken.tokenType == TokenType.LET:
    return parser.parseAssignmentStatement()
  return parser.parseExpressionStatement()

method parseProgram*(parser: var Parser): Node {.base.} =
  var statements: seq[Node] = @[]
  while parser.curToken.tokenType != TokenType.EOF:
    if parser.curToken.tokenType in [TokenType.SEMICOLON, TokenType.NEWLINE]:
      discard parser.nextParserToken()
      continue

    var statement = parser.parseStatement()
    statements.add(statement)

    discard parser.nextParserToken()

  return newProgram(statements = statements)

proc newParser*(lexer: Lexer): Parser =
  var parser: Parser = Parser(lexer: lexer)
  parser.errors = @[]
  parser.curToken = parser.lexer.nextToken()
  parser.peekToken = parser.lexer.nextToken()
  return parser
