#![allow(clippy::missing_safety_doc)]

pub type ConstantId = u32;
#[doc = "A struct that represents a stack of bools."]
pub type StateStack = u32;
#[doc = "When the encoding that is being used to parse the source is changed by YARP,\n we provide the ability here to call out to a user-defined function."]
pub type EncodingChangedCallback = ::std::option::Option<unsafe extern "C" fn(parser: *mut Parser)>;
#[doc = "When an encoding is encountered that isn't understood by YARP, we provide\n the ability here to call out to a user-defined function to get an encoding\n struct. If the function returns something that isn't NULL, we set that to\n our encoding and use it to parse identifiers."]
pub type EncodingDecodeCallback = ::std::option::Option<
    unsafe extern "C" fn(
        parser: *mut Parser,
        name: *const ::std::os::raw::c_char,
        width: usize,
    ) -> *mut Encoding,
>;
#[repr(C)]
pub struct __BindgenUnionField<T>(::std::marker::PhantomData<T>);
#[repr(C)]
#[derive(Debug)]
pub struct ConstantIdList {
    pub ids: *mut ConstantId,
    pub size: usize,
    pub capacity: usize,
}
#[repr(C)]
#[derive(Debug)]
pub struct Constant {
    pub id: ConstantId,
    pub start: *const ::std::os::raw::c_char,
    pub length: usize,
    pub hash: usize,
}
#[repr(C)]
#[derive(Debug)]
pub struct ConstantPool {
    pub constants: *mut Constant,
    pub size: usize,
    pub capacity: usize,
}
#[doc = "This struct represents a string value."]
#[repr(C)]
pub struct String {
    pub type_: StringUnknownTy1,
    pub as_: StringUnknownTy2,
}
#[repr(C)]
pub struct StringUnknownTy2 {
    pub shared: __BindgenUnionField<StringUnknownTy2UnknownTy1>,
    pub owned: __BindgenUnionField<StringUnknownTy2UnknownTy2>,
    pub constant: __BindgenUnionField<StringUnknownTy2UnknownTy3>,
    pub bindgen_union_field: [u64; 2usize],
}
#[repr(C)]
#[derive(Debug)]
pub struct StringUnknownTy2UnknownTy1 {
    pub start: *const ::std::os::raw::c_char,
    pub end: *const ::std::os::raw::c_char,
}
#[repr(C)]
#[derive(Debug)]
pub struct StringUnknownTy2UnknownTy2 {
    pub source: *mut ::std::os::raw::c_char,
    pub length: usize,
}
#[repr(C)]
#[derive(Debug)]
pub struct StringUnknownTy2UnknownTy3 {
    pub source: *const ::std::os::raw::c_char,
    pub length: usize,
}
#[doc = "This struct represents a token in the Ruby source. We use it to track both\n type and location information."]
#[repr(C)]
#[derive(Debug)]
pub struct Token {
    pub type_: TokenType,
    pub start: *const ::std::os::raw::c_char,
    pub end: *const ::std::os::raw::c_char,
}
#[doc = "This represents a range of bytes in the source string to which a node or\n token corresponds."]
#[repr(C)]
#[derive(Debug)]
pub struct Location {
    pub start: *const ::std::os::raw::c_char,
    pub end: *const ::std::os::raw::c_char,
}
#[repr(C)]
#[derive(Debug)]
pub struct LocationList {
    pub locations: *mut Location,
    pub size: usize,
    pub capacity: usize,
}
#[repr(C)]
#[derive(Debug)]
pub struct NodeList {
    pub nodes: *mut *mut Node,
    pub size: usize,
    pub capacity: usize,
}
#[doc = "This is the overall tagged union representing a node in the syntax tree."]
#[repr(C)]
#[derive(Debug)]
pub struct Node {
    #[doc = "This represents the type of the node. It somewhat maps to the nodes that\n existed in the original grammar and ripper, but it's not a 1:1 mapping."]
    pub type_: NodeType,
    #[doc = "This is the location of the node in the source. It's a range of bytes\n containing a start and an end."]
    pub location: Location,
}
#[doc = "AliasNode"]
#[repr(C)]
#[derive(Debug)]
pub struct AliasNode {
    pub base: Node,
    pub new_name: *mut Node,
    pub old_name: *mut Node,
    pub keyword_loc: Location,
}
#[doc = "AlternationPatternNode"]
#[repr(C)]
#[derive(Debug)]
pub struct AlternationPatternNode {
    pub base: Node,
    pub left: *mut Node,
    pub right: *mut Node,
    pub operator_loc: Location,
}
#[doc = "AndNode"]
#[repr(C)]
#[derive(Debug)]
pub struct AndNode {
    pub base: Node,
    pub left: *mut Node,
    pub right: *mut Node,
    pub operator_loc: Location,
}
#[doc = "ArgumentsNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ArgumentsNode {
    pub base: Node,
    pub arguments: NodeList,
}
#[doc = "ArrayNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ArrayNode {
    pub base: Node,
    pub elements: NodeList,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "ArrayPatternNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ArrayPatternNode {
    pub base: Node,
    pub constant: *mut Node,
    pub requireds: NodeList,
    pub rest: *mut Node,
    pub posts: NodeList,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "AssocNode"]
#[repr(C)]
#[derive(Debug)]
pub struct AssocNode {
    pub base: Node,
    pub key: *mut Node,
    pub value: *mut Node,
    pub operator_loc: Location,
}
#[doc = "AssocSplatNode"]
#[repr(C)]
#[derive(Debug)]
pub struct AssocSplatNode {
    pub base: Node,
    pub value: *mut Node,
    pub operator_loc: Location,
}
#[doc = "BackReferenceReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BackReferenceReadNode {
    pub base: Node,
}
#[doc = "BeginNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BeginNode {
    pub base: Node,
    pub begin_keyword_loc: Location,
    pub statements: *mut StatementsNode,
    pub rescue_clause: *mut RescueNode,
    pub else_clause: *mut ElseNode,
    pub ensure_clause: *mut EnsureNode,
    pub end_keyword_loc: Location,
}
#[doc = "BlockArgumentNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BlockArgumentNode {
    pub base: Node,
    pub expression: *mut Node,
    pub operator_loc: Location,
}
#[doc = "BlockNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BlockNode {
    pub base: Node,
    pub locals: ConstantIdList,
    pub parameters: *mut BlockParametersNode,
    pub statements: *mut Node,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "BlockParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BlockParameterNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
}
#[doc = "BlockParametersNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BlockParametersNode {
    pub base: Node,
    pub parameters: *mut ParametersNode,
    pub locals: LocationList,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "BreakNode"]
#[repr(C)]
#[derive(Debug)]
pub struct BreakNode {
    pub base: Node,
    pub arguments: *mut ArgumentsNode,
    pub keyword_loc: Location,
}
#[doc = "CallNode"]
#[repr(C)]
pub struct CallNode {
    pub base: Node,
    pub receiver: *mut Node,
    pub operator_loc: Location,
    pub message_loc: Location,
    pub opening_loc: Location,
    pub arguments: *mut ArgumentsNode,
    pub closing_loc: Location,
    pub block: *mut BlockNode,
    pub flags: u32,
    pub name: String,
}
#[doc = "CallOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct CallOperatorAndWriteNode {
    pub base: Node,
    pub target: *mut CallNode,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "CallOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct CallOperatorOrWriteNode {
    pub base: Node,
    pub target: *mut CallNode,
    pub value: *mut Node,
    pub operator_loc: Location,
}
#[doc = "CallOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct CallOperatorWriteNode {
    pub base: Node,
    pub target: *mut CallNode,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub operator_id: ConstantId,
}
#[doc = "CapturePatternNode"]
#[repr(C)]
#[derive(Debug)]
pub struct CapturePatternNode {
    pub base: Node,
    pub value: *mut Node,
    pub target: *mut Node,
    pub operator_loc: Location,
}
#[doc = "CaseNode"]
#[repr(C)]
#[derive(Debug)]
pub struct CaseNode {
    pub base: Node,
    pub predicate: *mut Node,
    pub conditions: NodeList,
    pub consequent: *mut ElseNode,
    pub case_keyword_loc: Location,
    pub end_keyword_loc: Location,
}
#[doc = "ClassNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ClassNode {
    pub base: Node,
    pub locals: ConstantIdList,
    pub class_keyword_loc: Location,
    pub constant_path: *mut Node,
    pub inheritance_operator_loc: Location,
    pub superclass: *mut Node,
    pub statements: *mut Node,
    pub end_keyword_loc: Location,
}
#[doc = "ClassVariableOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ClassVariableOperatorAndWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ClassVariableOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ClassVariableOperatorOrWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ClassVariableOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ClassVariableOperatorWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub operator: ConstantId,
}
#[doc = "ClassVariableReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ClassVariableReadNode {
    pub base: Node,
}
#[doc = "ClassVariableWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ClassVariableWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub value: *mut Node,
    pub operator_loc: Location,
}
#[doc = "ConstantOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantOperatorAndWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ConstantOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantOperatorOrWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ConstantOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantOperatorWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub operator: ConstantId,
}
#[doc = "ConstantPathNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantPathNode {
    pub base: Node,
    pub parent: *mut Node,
    pub child: *mut Node,
    pub delimiter_loc: Location,
}
#[doc = "ConstantPathOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantPathOperatorAndWriteNode {
    pub base: Node,
    pub target: *mut ConstantPathNode,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ConstantPathOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantPathOperatorOrWriteNode {
    pub base: Node,
    pub target: *mut ConstantPathNode,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ConstantPathOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantPathOperatorWriteNode {
    pub base: Node,
    pub target: *mut ConstantPathNode,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub operator: ConstantId,
}
#[doc = "ConstantPathWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantPathWriteNode {
    pub base: Node,
    pub target: *mut Node,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "ConstantReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ConstantReadNode {
    pub base: Node,
}
#[doc = "DefNode"]
#[repr(C)]
#[derive(Debug)]
pub struct DefNode {
    pub base: Node,
    pub name_loc: Location,
    pub receiver: *mut Node,
    pub parameters: *mut ParametersNode,
    pub statements: *mut Node,
    pub locals: ConstantIdList,
    pub def_keyword_loc: Location,
    pub operator_loc: Location,
    pub lparen_loc: Location,
    pub rparen_loc: Location,
    pub equal_loc: Location,
    pub end_keyword_loc: Location,
}
#[doc = "DefinedNode"]
#[repr(C)]
#[derive(Debug)]
pub struct DefinedNode {
    pub base: Node,
    pub lparen_loc: Location,
    pub value: *mut Node,
    pub rparen_loc: Location,
    pub keyword_loc: Location,
}
#[doc = "ElseNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ElseNode {
    pub base: Node,
    pub else_keyword_loc: Location,
    pub statements: *mut StatementsNode,
    pub end_keyword_loc: Location,
}
#[doc = "EmbeddedStatementsNode"]
#[repr(C)]
#[derive(Debug)]
pub struct EmbeddedStatementsNode {
    pub base: Node,
    pub opening_loc: Location,
    pub statements: *mut StatementsNode,
    pub closing_loc: Location,
}
#[doc = "EmbeddedVariableNode"]
#[repr(C)]
#[derive(Debug)]
pub struct EmbeddedVariableNode {
    pub base: Node,
    pub operator_loc: Location,
    pub variable: *mut Node,
}
#[doc = "EnsureNode"]
#[repr(C)]
#[derive(Debug)]
pub struct EnsureNode {
    pub base: Node,
    pub ensure_keyword_loc: Location,
    pub statements: *mut StatementsNode,
    pub end_keyword_loc: Location,
}
#[doc = "FalseNode"]
#[repr(C)]
#[derive(Debug)]
pub struct FalseNode {
    pub base: Node,
}
#[doc = "FindPatternNode"]
#[repr(C)]
#[derive(Debug)]
pub struct FindPatternNode {
    pub base: Node,
    pub constant: *mut Node,
    pub left: *mut Node,
    pub requireds: NodeList,
    pub right: *mut Node,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "FloatNode"]
#[repr(C)]
#[derive(Debug)]
pub struct FloatNode {
    pub base: Node,
}
#[doc = "ForNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ForNode {
    pub base: Node,
    pub index: *mut Node,
    pub collection: *mut Node,
    pub statements: *mut StatementsNode,
    pub for_keyword_loc: Location,
    pub in_keyword_loc: Location,
    pub do_keyword_loc: Location,
    pub end_keyword_loc: Location,
}
#[doc = "ForwardingArgumentsNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ForwardingArgumentsNode {
    pub base: Node,
}
#[doc = "ForwardingParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ForwardingParameterNode {
    pub base: Node,
}
#[doc = "ForwardingSuperNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ForwardingSuperNode {
    pub base: Node,
    pub block: *mut BlockNode,
}
#[doc = "GlobalVariableOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct GlobalVariableOperatorAndWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "GlobalVariableOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct GlobalVariableOperatorOrWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "GlobalVariableOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct GlobalVariableOperatorWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub operator: ConstantId,
}
#[doc = "GlobalVariableReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct GlobalVariableReadNode {
    pub base: Node,
}
#[doc = "GlobalVariableWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct GlobalVariableWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "HashNode"]
#[repr(C)]
#[derive(Debug)]
pub struct HashNode {
    pub base: Node,
    pub opening_loc: Location,
    pub elements: NodeList,
    pub closing_loc: Location,
}
#[doc = "HashPatternNode"]
#[repr(C)]
#[derive(Debug)]
pub struct HashPatternNode {
    pub base: Node,
    pub constant: *mut Node,
    pub assocs: NodeList,
    pub kwrest: *mut Node,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "IfNode"]
#[repr(C)]
#[derive(Debug)]
pub struct IfNode {
    pub base: Node,
    pub if_keyword_loc: Location,
    pub predicate: *mut Node,
    pub statements: *mut StatementsNode,
    pub consequent: *mut Node,
    pub end_keyword_loc: Location,
}
#[doc = "ImaginaryNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ImaginaryNode {
    pub base: Node,
    pub numeric: *mut Node,
}
#[doc = "InNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InNode {
    pub base: Node,
    pub pattern: *mut Node,
    pub statements: *mut StatementsNode,
    pub in_loc: Location,
    pub then_loc: Location,
}
#[doc = "InstanceVariableOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InstanceVariableOperatorAndWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "InstanceVariableOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InstanceVariableOperatorOrWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "InstanceVariableOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InstanceVariableOperatorWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub operator: ConstantId,
}
#[doc = "InstanceVariableReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InstanceVariableReadNode {
    pub base: Node,
}
#[doc = "InstanceVariableWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InstanceVariableWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub value: *mut Node,
    pub operator_loc: Location,
}
#[doc = "IntegerNode"]
#[repr(C)]
#[derive(Debug)]
pub struct IntegerNode {
    pub base: Node,
}
#[doc = "InterpolatedRegularExpressionNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InterpolatedRegularExpressionNode {
    pub base: Node,
    pub opening_loc: Location,
    pub parts: NodeList,
    pub closing_loc: Location,
    pub flags: u32,
}
#[doc = "InterpolatedStringNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InterpolatedStringNode {
    pub base: Node,
    pub opening_loc: Location,
    pub parts: NodeList,
    pub closing_loc: Location,
}
#[doc = "InterpolatedSymbolNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InterpolatedSymbolNode {
    pub base: Node,
    pub opening_loc: Location,
    pub parts: NodeList,
    pub closing_loc: Location,
}
#[doc = "InterpolatedXStringNode"]
#[repr(C)]
#[derive(Debug)]
pub struct InterpolatedXStringNode {
    pub base: Node,
    pub opening_loc: Location,
    pub parts: NodeList,
    pub closing_loc: Location,
}
#[doc = "KeywordHashNode"]
#[repr(C)]
#[derive(Debug)]
pub struct KeywordHashNode {
    pub base: Node,
    pub elements: NodeList,
}
#[doc = "KeywordParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct KeywordParameterNode {
    pub base: Node,
    pub name_loc: Location,
    pub value: *mut Node,
}
#[doc = "KeywordRestParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct KeywordRestParameterNode {
    pub base: Node,
    pub operator_loc: Location,
    pub name_loc: Location,
}
#[doc = "LambdaNode"]
#[repr(C)]
#[derive(Debug)]
pub struct LambdaNode {
    pub base: Node,
    pub locals: ConstantIdList,
    pub opening_loc: Location,
    pub parameters: *mut BlockParametersNode,
    pub statements: *mut Node,
}
#[doc = "LocalVariableOperatorAndWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct LocalVariableOperatorAndWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub constant_id: ConstantId,
}
#[doc = "LocalVariableOperatorOrWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct LocalVariableOperatorOrWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub constant_id: ConstantId,
}
#[doc = "LocalVariableOperatorWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct LocalVariableOperatorWriteNode {
    pub base: Node,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub constant_id: ConstantId,
    pub operator_id: ConstantId,
}
#[doc = "LocalVariableReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct LocalVariableReadNode {
    pub base: Node,
    pub constant_id: ConstantId,
    pub depth: u32,
}
#[doc = "LocalVariableWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct LocalVariableWriteNode {
    pub base: Node,
    pub constant_id: ConstantId,
    pub depth: u32,
    pub value: *mut Node,
    pub name_loc: Location,
    pub operator_loc: Location,
}
#[doc = "MatchPredicateNode"]
#[repr(C)]
#[derive(Debug)]
pub struct MatchPredicateNode {
    pub base: Node,
    pub value: *mut Node,
    pub pattern: *mut Node,
    pub operator_loc: Location,
}
#[doc = "MatchRequiredNode"]
#[repr(C)]
#[derive(Debug)]
pub struct MatchRequiredNode {
    pub base: Node,
    pub value: *mut Node,
    pub pattern: *mut Node,
    pub operator_loc: Location,
}
#[doc = "MissingNode"]
#[repr(C)]
#[derive(Debug)]
pub struct MissingNode {
    pub base: Node,
}
#[doc = "ModuleNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ModuleNode {
    pub base: Node,
    pub locals: ConstantIdList,
    pub module_keyword_loc: Location,
    pub constant_path: *mut Node,
    pub statements: *mut Node,
    pub end_keyword_loc: Location,
}
#[doc = "MultiWriteNode"]
#[repr(C)]
#[derive(Debug)]
pub struct MultiWriteNode {
    pub base: Node,
    pub targets: NodeList,
    pub operator_loc: Location,
    pub value: *mut Node,
    pub lparen_loc: Location,
    pub rparen_loc: Location,
}
#[doc = "NextNode"]
#[repr(C)]
#[derive(Debug)]
pub struct NextNode {
    pub base: Node,
    pub arguments: *mut ArgumentsNode,
    pub keyword_loc: Location,
}
#[doc = "NilNode"]
#[repr(C)]
#[derive(Debug)]
pub struct NilNode {
    pub base: Node,
}
#[doc = "NoKeywordsParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct NoKeywordsParameterNode {
    pub base: Node,
    pub operator_loc: Location,
    pub keyword_loc: Location,
}
#[doc = "NumberedReferenceReadNode"]
#[repr(C)]
#[derive(Debug)]
pub struct NumberedReferenceReadNode {
    pub base: Node,
}
#[doc = "OptionalParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct OptionalParameterNode {
    pub base: Node,
    pub constant_id: ConstantId,
    pub name_loc: Location,
    pub operator_loc: Location,
    pub value: *mut Node,
}
#[doc = "OrNode"]
#[repr(C)]
#[derive(Debug)]
pub struct OrNode {
    pub base: Node,
    pub left: *mut Node,
    pub right: *mut Node,
    pub operator_loc: Location,
}
#[doc = "ParametersNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ParametersNode {
    pub base: Node,
    pub requireds: NodeList,
    pub optionals: NodeList,
    pub posts: NodeList,
    pub rest: *mut RestParameterNode,
    pub keywords: NodeList,
    pub keyword_rest: *mut Node,
    pub block: *mut BlockParameterNode,
}
#[doc = "ParenthesesNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ParenthesesNode {
    pub base: Node,
    pub statements: *mut Node,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "PinnedExpressionNode"]
#[repr(C)]
#[derive(Debug)]
pub struct PinnedExpressionNode {
    pub base: Node,
    pub expression: *mut Node,
    pub operator_loc: Location,
    pub lparen_loc: Location,
    pub rparen_loc: Location,
}
#[doc = "PinnedVariableNode"]
#[repr(C)]
#[derive(Debug)]
pub struct PinnedVariableNode {
    pub base: Node,
    pub variable: *mut Node,
    pub operator_loc: Location,
}
#[doc = "PostExecutionNode"]
#[repr(C)]
#[derive(Debug)]
pub struct PostExecutionNode {
    pub base: Node,
    pub statements: *mut StatementsNode,
    pub keyword_loc: Location,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "PreExecutionNode"]
#[repr(C)]
#[derive(Debug)]
pub struct PreExecutionNode {
    pub base: Node,
    pub statements: *mut StatementsNode,
    pub keyword_loc: Location,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "ProgramNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ProgramNode {
    pub base: Node,
    pub locals: ConstantIdList,
    pub statements: *mut StatementsNode,
}
#[doc = "RangeNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RangeNode {
    pub base: Node,
    pub left: *mut Node,
    pub right: *mut Node,
    pub operator_loc: Location,
    pub flags: u32,
}
#[doc = "RationalNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RationalNode {
    pub base: Node,
    pub numeric: *mut Node,
}
#[doc = "RedoNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RedoNode {
    pub base: Node,
}
#[doc = "RegularExpressionNode"]
#[repr(C)]
pub struct RegularExpressionNode {
    pub base: Node,
    pub opening_loc: Location,
    pub content_loc: Location,
    pub closing_loc: Location,
    pub unescaped: String,
    pub flags: u32,
}
#[doc = "RequiredDestructuredParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RequiredDestructuredParameterNode {
    pub base: Node,
    pub parameters: NodeList,
    pub opening_loc: Location,
    pub closing_loc: Location,
}
#[doc = "RequiredParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RequiredParameterNode {
    pub base: Node,
    pub constant_id: ConstantId,
}
#[doc = "RescueModifierNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RescueModifierNode {
    pub base: Node,
    pub expression: *mut Node,
    pub keyword_loc: Location,
    pub rescue_expression: *mut Node,
}
#[doc = "RescueNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RescueNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub exceptions: NodeList,
    pub operator_loc: Location,
    pub exception: *mut Node,
    pub statements: *mut StatementsNode,
    pub consequent: *mut RescueNode,
}
#[doc = "RestParameterNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RestParameterNode {
    pub base: Node,
    pub operator_loc: Location,
    pub name_loc: Location,
}
#[doc = "RetryNode"]
#[repr(C)]
#[derive(Debug)]
pub struct RetryNode {
    pub base: Node,
}
#[doc = "ReturnNode"]
#[repr(C)]
#[derive(Debug)]
pub struct ReturnNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub arguments: *mut ArgumentsNode,
}
#[doc = "SelfNode"]
#[repr(C)]
#[derive(Debug)]
pub struct SelfNode {
    pub base: Node,
}
#[doc = "SingletonClassNode"]
#[repr(C)]
#[derive(Debug)]
pub struct SingletonClassNode {
    pub base: Node,
    pub locals: ConstantIdList,
    pub class_keyword_loc: Location,
    pub operator_loc: Location,
    pub expression: *mut Node,
    pub statements: *mut Node,
    pub end_keyword_loc: Location,
}
#[doc = "SourceEncodingNode"]
#[repr(C)]
#[derive(Debug)]
pub struct SourceEncodingNode {
    pub base: Node,
}
#[doc = "SourceFileNode"]
#[repr(C)]
pub struct SourceFileNode {
    pub base: Node,
    pub filepath: String,
}
#[doc = "SourceLineNode"]
#[repr(C)]
#[derive(Debug)]
pub struct SourceLineNode {
    pub base: Node,
}
#[doc = "SplatNode"]
#[repr(C)]
#[derive(Debug)]
pub struct SplatNode {
    pub base: Node,
    pub operator_loc: Location,
    pub expression: *mut Node,
}
#[doc = "StatementsNode"]
#[repr(C)]
#[derive(Debug)]
pub struct StatementsNode {
    pub base: Node,
    pub body: NodeList,
}
#[doc = "StringConcatNode"]
#[repr(C)]
#[derive(Debug)]
pub struct StringConcatNode {
    pub base: Node,
    pub left: *mut Node,
    pub right: *mut Node,
}
#[doc = "StringNode"]
#[repr(C)]
pub struct StringNode {
    pub base: Node,
    pub opening_loc: Location,
    pub content_loc: Location,
    pub closing_loc: Location,
    pub unescaped: String,
}
#[doc = "SuperNode"]
#[repr(C)]
#[derive(Debug)]
pub struct SuperNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub lparen_loc: Location,
    pub arguments: *mut ArgumentsNode,
    pub rparen_loc: Location,
    pub block: *mut BlockNode,
}
#[doc = "SymbolNode"]
#[repr(C)]
pub struct SymbolNode {
    pub base: Node,
    pub opening_loc: Location,
    pub value_loc: Location,
    pub closing_loc: Location,
    pub unescaped: String,
}
#[doc = "TrueNode"]
#[repr(C)]
#[derive(Debug)]
pub struct TrueNode {
    pub base: Node,
}
#[doc = "UndefNode"]
#[repr(C)]
#[derive(Debug)]
pub struct UndefNode {
    pub base: Node,
    pub names: NodeList,
    pub keyword_loc: Location,
}
#[doc = "UnlessNode"]
#[repr(C)]
#[derive(Debug)]
pub struct UnlessNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub predicate: *mut Node,
    pub statements: *mut StatementsNode,
    pub consequent: *mut ElseNode,
    pub end_keyword_loc: Location,
}
#[doc = "UntilNode"]
#[repr(C)]
#[derive(Debug)]
pub struct UntilNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub predicate: *mut Node,
    pub statements: *mut StatementsNode,
}
#[doc = "WhenNode"]
#[repr(C)]
#[derive(Debug)]
pub struct WhenNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub conditions: NodeList,
    pub statements: *mut StatementsNode,
}
#[doc = "WhileNode"]
#[repr(C)]
#[derive(Debug)]
pub struct WhileNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub predicate: *mut Node,
    pub statements: *mut StatementsNode,
}
#[doc = "XStringNode"]
#[repr(C)]
pub struct XStringNode {
    pub base: Node,
    pub opening_loc: Location,
    pub content_loc: Location,
    pub closing_loc: Location,
    pub unescaped: String,
}
#[doc = "YieldNode"]
#[repr(C)]
#[derive(Debug)]
pub struct YieldNode {
    pub base: Node,
    pub keyword_loc: Location,
    pub lparen_loc: Location,
    pub arguments: *mut ArgumentsNode,
    pub rparen_loc: Location,
}
#[doc = "This represents a node in the linked list."]
#[repr(C)]
#[derive(Debug)]
pub struct ListNode {
    pub next: *mut ListNode,
}
#[doc = "This represents the overall linked list. It keeps a pointer to the head and\n tail so that iteration is easy and pushing new nodes is easy."]
#[repr(C)]
#[derive(Debug)]
pub struct List {
    pub head: *mut ListNode,
    pub tail: *mut ListNode,
}
#[doc = "This struct represents a diagnostic found during parsing."]
#[repr(C)]
#[derive(Debug)]
pub struct Diagnostic {
    pub node: ListNode,
    pub start: *const ::std::os::raw::c_char,
    pub end: *const ::std::os::raw::c_char,
    pub message: *const ::std::os::raw::c_char,
}
#[doc = "This struct defines the functions necessary to implement the encoding\n interface so we can determine how many bytes the subsequent character takes.\n Each callback should return the number of bytes, or 0 if the next bytes are\n invalid for the encoding and type."]
#[repr(C)]
#[derive(Debug)]
pub struct Encoding {
    #[doc = "Return the number of bytes that the next character takes if it is valid\n in the encoding."]
    pub char_width:
        ::std::option::Option<unsafe extern "C" fn(c: *const ::std::os::raw::c_char) -> usize>,
    #[doc = "Return the number of bytes that the next character takes if it is valid\n in the encoding and is alphabetical."]
    pub alpha_char:
        ::std::option::Option<unsafe extern "C" fn(c: *const ::std::os::raw::c_char) -> usize>,
    #[doc = "Return the number of bytes that the next character takes if it is valid\n in the encoding and is alphanumeric."]
    pub alnum_char:
        ::std::option::Option<unsafe extern "C" fn(c: *const ::std::os::raw::c_char) -> usize>,
    #[doc = "Return true if the next character is valid in the encoding and is an\n uppercase character."]
    pub isupper_char:
        ::std::option::Option<unsafe extern "C" fn(c: *const ::std::os::raw::c_char) -> bool>,
    #[doc = "The name of the encoding. This should correspond to a value that can be\n passed to Encoding.find in Ruby."]
    pub name: *const ::std::os::raw::c_char,
    #[doc = "Return true if the encoding is a multibyte encoding."]
    pub multibyte: bool,
}
#[doc = "A list of offsets of newlines in a string. The offsets are assumed to be\n sorted/inserted in ascending order."]
#[repr(C)]
#[derive(Debug)]
pub struct NewlineList {
    pub start: *const ::std::os::raw::c_char,
    pub offsets: *mut usize,
    pub size: usize,
    pub capacity: usize,
    pub last_offset: usize,
    pub last_index: usize,
}
#[doc = "A line and column in a string."]
#[repr(C)]
#[derive(Debug, Default)]
pub struct LineColumn {
    pub line: usize,
    pub column: usize,
}
#[doc = "When lexing Ruby source, the lexer has a small amount of state to tell which\n kind of token it is currently lexing. For example, when we find the start of\n a string, the first token that we return is a TOKEN_STRING_BEGIN token. After\n that the lexer is now in the YP_LEX_STRING mode, and will return tokens that\n are found as part of a string."]
#[repr(C)]
pub struct LexMode {
    pub mode: LexModeUnknownTy1,
    pub as_: LexModeUnknownTy2,
    #[doc = "The previous lex state so that it knows how to pop."]
    pub prev: *mut LexMode,
}
#[repr(C)]
pub struct LexModeUnknownTy2 {
    pub list: __BindgenUnionField<LexModeUnknownTy2UnknownTy1>,
    pub regexp: __BindgenUnionField<LexModeUnknownTy2UnknownTy2>,
    pub string: __BindgenUnionField<LexModeUnknownTy2UnknownTy3>,
    pub numeric: __BindgenUnionField<LexModeUnknownTy2UnknownTy4>,
    pub heredoc: __BindgenUnionField<LexModeUnknownTy2UnknownTy5>,
    pub bindgen_union_field: [u64; 4usize],
}
#[repr(C)]
#[derive(Debug, Default)]
pub struct LexModeUnknownTy2UnknownTy1 {
    #[doc = "This keeps track of the nesting level of the list."]
    pub nesting: usize,
    #[doc = "Whether or not interpolation is allowed in this list."]
    pub interpolation: bool,
    #[doc = "When lexing a list, it takes into account balancing the\n terminator if the terminator is one of (), [], {}, or <>."]
    pub incrementor: ::std::os::raw::c_char,
    #[doc = "This is the terminator of the list literal."]
    pub terminator: ::std::os::raw::c_char,
    #[doc = "This is the character set that should be used to delimit the\n tokens within the list."]
    pub breakpoints: [::std::os::raw::c_char; 11usize],
}
#[repr(C)]
#[derive(Debug, Default)]
pub struct LexModeUnknownTy2UnknownTy2 {
    #[doc = "This keeps track of the nesting level of the regular expression."]
    pub nesting: usize,
    #[doc = "When lexing a regular expression, it takes into account balancing\n the terminator if the terminator is one of (), [], {}, or <>."]
    pub incrementor: ::std::os::raw::c_char,
    #[doc = "This is the terminator of the regular expression."]
    pub terminator: ::std::os::raw::c_char,
    #[doc = "This is the character set that should be used to delimit the\n tokens within the regular expression."]
    pub breakpoints: [::std::os::raw::c_char; 6usize],
}
#[repr(C)]
#[derive(Debug, Default)]
pub struct LexModeUnknownTy2UnknownTy3 {
    #[doc = "This keeps track of the nesting level of the string."]
    pub nesting: usize,
    #[doc = "Whether or not interpolation is allowed in this string."]
    pub interpolation: bool,
    #[doc = "Whether or not at the end of the string we should allow a :,\n which would indicate this was a dynamic symbol instead of a\n string."]
    pub label_allowed: bool,
    #[doc = "When lexing a string, it takes into account balancing the\n terminator if the terminator is one of (), [], {}, or <>."]
    pub incrementor: ::std::os::raw::c_char,
    #[doc = "This is the terminator of the string. It is typically either a\n single or double quote."]
    pub terminator: ::std::os::raw::c_char,
    #[doc = "This is the character set that should be used to delimit the\n tokens within the string."]
    pub breakpoints: [::std::os::raw::c_char; 6usize],
}
#[repr(C)]
#[derive(Debug)]
pub struct LexModeUnknownTy2UnknownTy4 {
    pub type_: TokenType,
    pub start: *const ::std::os::raw::c_char,
    pub end: *const ::std::os::raw::c_char,
}
#[repr(C)]
#[derive(Debug)]
pub struct LexModeUnknownTy2UnknownTy5 {
    #[doc = "These pointers point to the beginning and end of the heredoc\n identifier."]
    pub ident_start: *const ::std::os::raw::c_char,
    pub ident_length: usize,
    pub quote: HeredocQuote,
    pub indent: HeredocIndent,
    #[doc = "This is the pointer to the character where lexing should resume\n once the heredoc has been completely processed."]
    pub next_start: *const ::std::os::raw::c_char,
}
#[doc = "This is a node in a linked list of contexts."]
#[repr(C)]
#[derive(Debug)]
pub struct ContextNode {
    pub context: Context,
    pub prev: *mut ContextNode,
}
#[doc = "This is a node in the linked list of comments that we've found while parsing."]
#[repr(C)]
#[derive(Debug)]
pub struct Comment {
    pub node: ListNode,
    pub start: *const ::std::os::raw::c_char,
    pub end: *const ::std::os::raw::c_char,
    pub type_: CommentType,
}
#[doc = "When you are lexing through a file, the lexer needs all of the information\n that the parser additionally provides (for example, the local table). So if\n you want to properly lex Ruby, you need to actually lex it in the context of\n the parser. In order to provide this functionality, we optionally allow a\n struct to be attached to the parser that calls back out to a user-provided\n callback when each token is lexed."]
#[repr(C)]
#[derive(Debug)]
pub struct LexCallback {
    #[doc = "This opaque pointer is used to provide whatever information the user\n deemed necessary to the callback. In our case we use it to pass the array\n that the tokens get appended into."]
    pub data: *mut ::std::os::raw::c_void,
    #[doc = "This is the callback that is called when a token is lexed. It is passed\n the opaque data pointer, the parser, and the token that was lexed."]
    pub callback: ::std::option::Option<
        unsafe extern "C" fn(
            data: *mut ::std::os::raw::c_void,
            parser: *mut Parser,
            token: *mut Token,
        ),
    >,
}
#[doc = "This struct represents a node in a linked list of scopes. Some scopes can see\n into their parent scopes, while others cannot."]
#[repr(C)]
#[derive(Debug)]
pub struct Scope {
    #[doc = "The IDs of the locals in the given scope."]
    pub locals: ConstantIdList,
    #[doc = "A boolean indicating whether or not this scope can see into its parent.\n If closed is true, then the scope cannot see into its parent."]
    pub closed: bool,
    #[doc = "A pointer to the previous scope in the linked list."]
    pub previous: *mut Scope,
}
#[doc = "This struct represents the overall parser. It contains a reference to the\n source file, as well as pointers that indicate where in the source it's\n currently parsing. It also contains the most recent and current token that\n it's considering."]
#[repr(C)]
pub struct Parser {
    #[doc = "the current state of the lexer"]
    pub lex_state: LexState,
    #[doc = "whether or not we're at the beginning of a command"]
    pub command_start: bool,
    #[doc = "tracks the current nesting of (), [], and {}"]
    pub enclosure_nesting: ::std::os::raw::c_int,
    #[doc = "Used to temporarily track the nesting of enclosures to determine if a {\n is the beginning of a lambda following the parameters of a lambda."]
    pub lambda_enclosure_nesting: ::std::os::raw::c_int,
    #[doc = "Used to track the nesting of braces to ensure we get the correct value\n when we are interpolating blocks with braces."]
    pub brace_nesting: ::std::os::raw::c_int,
    #[doc = "the stack used to determine if a do keyword belongs to the predicate of a\n while, until, or for loop"]
    pub do_loop_stack: StateStack,
    #[doc = "the stack used to determine if a do keyword belongs to the beginning of a\n block"]
    pub accepts_block_stack: StateStack,
    pub lex_modes: ParserUnknownTy1,
    #[doc = "the pointer to the start of the source"]
    pub start: *const ::std::os::raw::c_char,
    #[doc = "the pointer to the end of the source"]
    pub end: *const ::std::os::raw::c_char,
    #[doc = "the previous token we were considering"]
    pub previous: Token,
    #[doc = "the current token we're considering"]
    pub current: Token,
    #[doc = "This is a special field set on the parser when we need the parser to jump\n to a specific location when lexing the next token, as opposed to just\n using the end of the previous token. Normally this is NULL."]
    pub next_start: *const ::std::os::raw::c_char,
    #[doc = "This field indicates the end of a heredoc whose identifier was found on\n the current line. If another heredoc is found on the same line, then this\n will be moved forward to the end of that heredoc. If no heredocs are\n found on a line then this is NULL."]
    pub heredoc_end: *const ::std::os::raw::c_char,
    #[doc = "the list of comments that have been found while parsing"]
    pub comment_list: List,
    #[doc = "the list of warnings that have been found while parsing"]
    pub warning_list: List,
    #[doc = "the list of errors that have been found while parsing"]
    pub error_list: List,
    #[doc = "the current local scope"]
    pub current_scope: *mut Scope,
    #[doc = "the current parsing context"]
    pub current_context: *mut ContextNode,
    #[doc = "whether or not we're currently recovering from a syntax error"]
    pub recovering: bool,
    #[doc = "The encoding functions for the current file is attached to the parser as\n it's parsing so that it can change with a magic comment."]
    pub encoding: Encoding,
    #[doc = "Whether or not the encoding has been changed by a magic comment. We use\n this to provide a fast path for the lexer instead of going through the\n function pointer."]
    pub encoding_changed: bool,
    #[doc = "When the encoding that is being used to parse the source is changed by\n YARP, we provide the ability here to call out to a user-defined function."]
    pub encoding_changed_callback: EncodingChangedCallback,
    #[doc = "When an encoding is encountered that isn't understood by YARP, we provide\n the ability here to call out to a user-defined function to get an\n encoding struct. If the function returns something that isn't NULL, we\n set that to our encoding and use it to parse identifiers."]
    pub encoding_decode_callback: EncodingDecodeCallback,
    #[doc = "This pointer indicates where a comment must start if it is to be\n considered an encoding comment."]
    pub encoding_comment_start: *const ::std::os::raw::c_char,
    #[doc = "This is an optional callback that can be attached to the parser that will\n be called whenever a new token is lexed by the parser."]
    pub lex_callback: *mut LexCallback,
    #[doc = "This flag indicates that we are currently parsing a pattern matching\n expression and impacts that calculation of newlines."]
    pub pattern_matching_newlines: bool,
    #[doc = "This flag indicates that we are currently parsing a keyword argument."]
    pub in_keyword_arg: bool,
    #[doc = "This is the path of the file being parsed\n We use the filepath when constructing SourceFileNodes"]
    pub filepath_string: String,
    #[doc = "This constant pool keeps all of the constants defined throughout the file\n so that we can reference them later."]
    pub constant_pool: ConstantPool,
    #[doc = "This is the list of newline offsets in the source file."]
    pub newline_list: NewlineList,
}
#[repr(C)]
pub struct ParserUnknownTy1 {
    #[doc = "the current mode of the lexer"]
    pub current: *mut LexMode,
    #[doc = "the stack of lexer modes"]
    pub stack: [LexMode; 4usize],
    #[doc = "the current index into the lexer mode stack"]
    pub index: usize,
}
#[doc = "This struct stores the information gathered by the yp_node_memsize function.\n It contains both the memory footprint and additionally metadata about the\n shape of the tree."]
#[repr(C)]
#[derive(Debug, Default)]
pub struct Memsize {
    pub memsize: usize,
    pub node_count: usize,
}
#[repr(C)]
#[derive(Debug)]
pub struct StringList {
    pub strings: *mut String,
    pub length: usize,
    pub capacity: usize,
}
#[doc = "A yp_buffer_t is a simple memory buffer that stores data in a contiguous\n block of memory. It is used to store the serialized representation of a\n YARP tree."]
#[repr(C)]
#[derive(Debug)]
pub struct Buffer {
    pub value: *mut ::std::os::raw::c_char,
    pub length: usize,
    pub capacity: usize,
}
pub const ENCODING_ALPHABETIC_BIT: u32 = 1;
pub const ENCODING_ALPHANUMERIC_BIT: u32 = 2;
pub const ENCODING_UPPERCASE_BIT: u32 = 4;
pub const LEX_STACK_SIZE: u32 = 4;
pub const VERSION_MAJOR: u32 = 0;
pub const VERSION_MINOR: u32 = 4;
pub const VERSION_PATCH: u32 = 0;
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantIdList() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantIdList> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantIdList>(),
        24usize,
        concat!("Size of: ", stringify!(ConstantIdList))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantIdList>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantIdList))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).ids) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantIdList),
            "::",
            stringify!(ids)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).size) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantIdList),
            "::",
            stringify!(size)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantIdList),
            "::",
            stringify!(capacity)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Constant() {
    const UNINIT: ::std::mem::MaybeUninit<Constant> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Constant>(),
        32usize,
        concat!("Size of: ", stringify!(Constant))
    );
    assert_eq!(
        ::std::mem::align_of::<Constant>(),
        8usize,
        concat!("Alignment of ", stringify!(Constant))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).id) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Constant),
            "::",
            stringify!(id)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Constant),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).length) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Constant),
            "::",
            stringify!(length)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).hash) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(Constant),
            "::",
            stringify!(hash)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantPool() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantPool> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantPool>(),
        24usize,
        concat!("Size of: ", stringify!(ConstantPool))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantPool>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantPool))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constants) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPool),
            "::",
            stringify!(constants)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).size) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPool),
            "::",
            stringify!(size)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPool),
            "::",
            stringify!(capacity)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringUnknownTy2UnknownTy1() {
    const UNINIT: ::std::mem::MaybeUninit<StringUnknownTy2UnknownTy1> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringUnknownTy2UnknownTy1>(),
        16usize,
        concat!("Size of: ", stringify!(StringUnknownTy2UnknownTy1))
    );
    assert_eq!(
        ::std::mem::align_of::<StringUnknownTy2UnknownTy1>(),
        8usize,
        concat!("Alignment of ", stringify!(StringUnknownTy2UnknownTy1))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2UnknownTy1),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2UnknownTy1),
            "::",
            stringify!(end)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringUnknownTy2UnknownTy2() {
    const UNINIT: ::std::mem::MaybeUninit<StringUnknownTy2UnknownTy2> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringUnknownTy2UnknownTy2>(),
        16usize,
        concat!("Size of: ", stringify!(StringUnknownTy2UnknownTy2))
    );
    assert_eq!(
        ::std::mem::align_of::<StringUnknownTy2UnknownTy2>(),
        8usize,
        concat!("Alignment of ", stringify!(StringUnknownTy2UnknownTy2))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).source) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2UnknownTy2),
            "::",
            stringify!(source)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).length) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2UnknownTy2),
            "::",
            stringify!(length)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringUnknownTy2UnknownTy3() {
    const UNINIT: ::std::mem::MaybeUninit<StringUnknownTy2UnknownTy3> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringUnknownTy2UnknownTy3>(),
        16usize,
        concat!("Size of: ", stringify!(StringUnknownTy2UnknownTy3))
    );
    assert_eq!(
        ::std::mem::align_of::<StringUnknownTy2UnknownTy3>(),
        8usize,
        concat!("Alignment of ", stringify!(StringUnknownTy2UnknownTy3))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).source) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2UnknownTy3),
            "::",
            stringify!(source)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).length) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2UnknownTy3),
            "::",
            stringify!(length)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringUnknownTy2() {
    const UNINIT: ::std::mem::MaybeUninit<StringUnknownTy2> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringUnknownTy2>(),
        16usize,
        concat!("Size of: ", stringify!(StringUnknownTy2))
    );
    assert_eq!(
        ::std::mem::align_of::<StringUnknownTy2>(),
        8usize,
        concat!("Alignment of ", stringify!(StringUnknownTy2))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).shared) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2),
            "::",
            stringify!(shared)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).owned) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2),
            "::",
            stringify!(owned)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringUnknownTy2),
            "::",
            stringify!(constant)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_String() {
    const UNINIT: ::std::mem::MaybeUninit<String> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<String>(),
        24usize,
        concat!("Size of: ", stringify!(String))
    );
    assert_eq!(
        ::std::mem::align_of::<String>(),
        8usize,
        concat!("Alignment of ", stringify!(String))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).type_) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(String),
            "::",
            stringify!(type_)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).as_) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(String),
            "::",
            stringify!(as_)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Token() {
    const UNINIT: ::std::mem::MaybeUninit<Token> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Token>(),
        24usize,
        concat!("Size of: ", stringify!(Token))
    );
    assert_eq!(
        ::std::mem::align_of::<Token>(),
        8usize,
        concat!("Alignment of ", stringify!(Token))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).type_) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Token),
            "::",
            stringify!(type_)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Token),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Token),
            "::",
            stringify!(end)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Location() {
    const UNINIT: ::std::mem::MaybeUninit<Location> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Location>(),
        16usize,
        concat!("Size of: ", stringify!(Location))
    );
    assert_eq!(
        ::std::mem::align_of::<Location>(),
        8usize,
        concat!("Alignment of ", stringify!(Location))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Location),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Location),
            "::",
            stringify!(end)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LocationList() {
    const UNINIT: ::std::mem::MaybeUninit<LocationList> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LocationList>(),
        24usize,
        concat!("Size of: ", stringify!(LocationList))
    );
    assert_eq!(
        ::std::mem::align_of::<LocationList>(),
        8usize,
        concat!("Alignment of ", stringify!(LocationList))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locations) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LocationList),
            "::",
            stringify!(locations)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).size) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LocationList),
            "::",
            stringify!(size)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(LocationList),
            "::",
            stringify!(capacity)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_NodeList() {
    const UNINIT: ::std::mem::MaybeUninit<NodeList> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<NodeList>(),
        24usize,
        concat!("Size of: ", stringify!(NodeList))
    );
    assert_eq!(
        ::std::mem::align_of::<NodeList>(),
        8usize,
        concat!("Alignment of ", stringify!(NodeList))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).nodes) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(NodeList),
            "::",
            stringify!(nodes)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).size) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(NodeList),
            "::",
            stringify!(size)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(NodeList),
            "::",
            stringify!(capacity)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Node() {
    const UNINIT: ::std::mem::MaybeUninit<Node> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Node>(),
        24usize,
        concat!("Size of: ", stringify!(Node))
    );
    assert_eq!(
        ::std::mem::align_of::<Node>(),
        8usize,
        concat!("Alignment of ", stringify!(Node))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).type_) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Node),
            "::",
            stringify!(type_)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).location) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Node),
            "::",
            stringify!(location)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_AliasNode() {
    const UNINIT: ::std::mem::MaybeUninit<AliasNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<AliasNode>(),
        56usize,
        concat!("Size of: ", stringify!(AliasNode))
    );
    assert_eq!(
        ::std::mem::align_of::<AliasNode>(),
        8usize,
        concat!("Alignment of ", stringify!(AliasNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(AliasNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).new_name) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(AliasNode),
            "::",
            stringify!(new_name)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).old_name) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(AliasNode),
            "::",
            stringify!(old_name)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(AliasNode),
            "::",
            stringify!(keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_AlternationPatternNode() {
    const UNINIT: ::std::mem::MaybeUninit<AlternationPatternNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<AlternationPatternNode>(),
        56usize,
        concat!("Size of: ", stringify!(AlternationPatternNode))
    );
    assert_eq!(
        ::std::mem::align_of::<AlternationPatternNode>(),
        8usize,
        concat!("Alignment of ", stringify!(AlternationPatternNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(AlternationPatternNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).left) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(AlternationPatternNode),
            "::",
            stringify!(left)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).right) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(AlternationPatternNode),
            "::",
            stringify!(right)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(AlternationPatternNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_AndNode() {
    const UNINIT: ::std::mem::MaybeUninit<AndNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<AndNode>(),
        56usize,
        concat!("Size of: ", stringify!(AndNode))
    );
    assert_eq!(
        ::std::mem::align_of::<AndNode>(),
        8usize,
        concat!("Alignment of ", stringify!(AndNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(AndNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).left) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(AndNode),
            "::",
            stringify!(left)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).right) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(AndNode),
            "::",
            stringify!(right)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(AndNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ArgumentsNode() {
    const UNINIT: ::std::mem::MaybeUninit<ArgumentsNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ArgumentsNode>(),
        48usize,
        concat!("Size of: ", stringify!(ArgumentsNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ArgumentsNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ArgumentsNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ArgumentsNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ArgumentsNode),
            "::",
            stringify!(arguments)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ArrayNode() {
    const UNINIT: ::std::mem::MaybeUninit<ArrayNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ArrayNode>(),
        80usize,
        concat!("Size of: ", stringify!(ArrayNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ArrayNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ArrayNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).elements) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayNode),
            "::",
            stringify!(elements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ArrayPatternNode() {
    const UNINIT: ::std::mem::MaybeUninit<ArrayPatternNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ArrayPatternNode>(),
        120usize,
        concat!("Size of: ", stringify!(ArrayPatternNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ArrayPatternNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ArrayPatternNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(constant)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).requireds) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(requireds)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rest) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(rest)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).posts) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(posts)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        104usize,
        concat!(
            "Offset of field: ",
            stringify!(ArrayPatternNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_AssocNode() {
    const UNINIT: ::std::mem::MaybeUninit<AssocNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<AssocNode>(),
        56usize,
        concat!("Size of: ", stringify!(AssocNode))
    );
    assert_eq!(
        ::std::mem::align_of::<AssocNode>(),
        8usize,
        concat!("Alignment of ", stringify!(AssocNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).key) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocNode),
            "::",
            stringify!(key)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_AssocSplatNode() {
    const UNINIT: ::std::mem::MaybeUninit<AssocSplatNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<AssocSplatNode>(),
        48usize,
        concat!("Size of: ", stringify!(AssocSplatNode))
    );
    assert_eq!(
        ::std::mem::align_of::<AssocSplatNode>(),
        8usize,
        concat!("Alignment of ", stringify!(AssocSplatNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocSplatNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocSplatNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(AssocSplatNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BackReferenceReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<BackReferenceReadNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BackReferenceReadNode>(),
        24usize,
        concat!("Size of: ", stringify!(BackReferenceReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BackReferenceReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BackReferenceReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BackReferenceReadNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BeginNode() {
    const UNINIT: ::std::mem::MaybeUninit<BeginNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BeginNode>(),
        88usize,
        concat!("Size of: ", stringify!(BeginNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BeginNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BeginNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).begin_keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(begin_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rescue_clause) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(rescue_clause)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).else_clause) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(else_clause)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).ensure_clause) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(ensure_clause)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(BeginNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BlockArgumentNode() {
    const UNINIT: ::std::mem::MaybeUninit<BlockArgumentNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BlockArgumentNode>(),
        48usize,
        concat!("Size of: ", stringify!(BlockArgumentNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BlockArgumentNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BlockArgumentNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockArgumentNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).expression) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockArgumentNode),
            "::",
            stringify!(expression)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockArgumentNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BlockNode() {
    const UNINIT: ::std::mem::MaybeUninit<BlockNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BlockNode>(),
        96usize,
        concat!("Size of: ", stringify!(BlockNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BlockNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BlockNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parameters) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockNode),
            "::",
            stringify!(parameters)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BlockParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<BlockParameterNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BlockParameterNode>(),
        56usize,
        concat!("Size of: ", stringify!(BlockParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BlockParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BlockParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParameterNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParameterNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BlockParametersNode() {
    const UNINIT: ::std::mem::MaybeUninit<BlockParametersNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BlockParametersNode>(),
        88usize,
        concat!("Size of: ", stringify!(BlockParametersNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BlockParametersNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BlockParametersNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParametersNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parameters) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParametersNode),
            "::",
            stringify!(parameters)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParametersNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParametersNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(BlockParametersNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_BreakNode() {
    const UNINIT: ::std::mem::MaybeUninit<BreakNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<BreakNode>(),
        48usize,
        concat!("Size of: ", stringify!(BreakNode))
    );
    assert_eq!(
        ::std::mem::align_of::<BreakNode>(),
        8usize,
        concat!("Alignment of ", stringify!(BreakNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(BreakNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(BreakNode),
            "::",
            stringify!(arguments)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(BreakNode),
            "::",
            stringify!(keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_CallNode() {
    const UNINIT: ::std::mem::MaybeUninit<CallNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<CallNode>(),
        144usize,
        concat!("Size of: ", stringify!(CallNode))
    );
    assert_eq!(
        ::std::mem::align_of::<CallNode>(),
        8usize,
        concat!("Alignment of ", stringify!(CallNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).receiver) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(receiver)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).message_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(message_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(arguments)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(closing_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).block) as usize - ptr as usize },
        104usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(block)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).flags) as usize - ptr as usize },
        112usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(flags)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name) as usize - ptr as usize },
        120usize,
        concat!(
            "Offset of field: ",
            stringify!(CallNode),
            "::",
            stringify!(name)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_CallOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<CallOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<CallOperatorAndWriteNode>(),
        56usize,
        concat!("Size of: ", stringify!(CallOperatorAndWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<CallOperatorAndWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(CallOperatorAndWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorAndWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_CallOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<CallOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<CallOperatorOrWriteNode>(),
        56usize,
        concat!("Size of: ", stringify!(CallOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<CallOperatorOrWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(CallOperatorOrWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorOrWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_CallOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<CallOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<CallOperatorWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(CallOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<CallOperatorWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(CallOperatorWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_id) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(CallOperatorWriteNode),
            "::",
            stringify!(operator_id)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_CapturePatternNode() {
    const UNINIT: ::std::mem::MaybeUninit<CapturePatternNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<CapturePatternNode>(),
        56usize,
        concat!("Size of: ", stringify!(CapturePatternNode))
    );
    assert_eq!(
        ::std::mem::align_of::<CapturePatternNode>(),
        8usize,
        concat!("Alignment of ", stringify!(CapturePatternNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(CapturePatternNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(CapturePatternNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(CapturePatternNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(CapturePatternNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_CaseNode() {
    const UNINIT: ::std::mem::MaybeUninit<CaseNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<CaseNode>(),
        96usize,
        concat!("Size of: ", stringify!(CaseNode))
    );
    assert_eq!(
        ::std::mem::align_of::<CaseNode>(),
        8usize,
        concat!("Alignment of ", stringify!(CaseNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(CaseNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).predicate) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(CaseNode),
            "::",
            stringify!(predicate)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).conditions) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(CaseNode),
            "::",
            stringify!(conditions)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).consequent) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(CaseNode),
            "::",
            stringify!(consequent)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).case_keyword_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(CaseNode),
            "::",
            stringify!(case_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(CaseNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ClassNode() {
    const UNINIT: ::std::mem::MaybeUninit<ClassNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ClassNode>(),
        120usize,
        concat!("Size of: ", stringify!(ClassNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ClassNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ClassNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).class_keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(class_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_path) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(constant_path)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).inheritance_operator_loc) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(inheritance_operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).superclass) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(superclass)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        96usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        104usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ClassVariableOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ClassVariableOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ClassVariableOperatorAndWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(ClassVariableOperatorAndWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ClassVariableOperatorAndWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(ClassVariableOperatorAndWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorAndWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ClassVariableOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ClassVariableOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ClassVariableOperatorOrWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(ClassVariableOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ClassVariableOperatorOrWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(ClassVariableOperatorOrWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorOrWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ClassVariableOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ClassVariableOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ClassVariableOperatorWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(ClassVariableOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ClassVariableOperatorWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ClassVariableOperatorWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableOperatorWriteNode),
            "::",
            stringify!(operator)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ClassVariableReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<ClassVariableReadNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ClassVariableReadNode>(),
        24usize,
        concat!("Size of: ", stringify!(ClassVariableReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ClassVariableReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ClassVariableReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableReadNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ClassVariableWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ClassVariableWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ClassVariableWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(ClassVariableWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ClassVariableWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ClassVariableWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ClassVariableWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantOperatorAndWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(ConstantOperatorAndWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantOperatorAndWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantOperatorAndWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorAndWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantOperatorOrWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(ConstantOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantOperatorOrWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantOperatorOrWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorOrWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantOperatorWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(ConstantOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantOperatorWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantOperatorWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantOperatorWriteNode),
            "::",
            stringify!(operator)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantPathNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantPathNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantPathNode>(),
        56usize,
        concat!("Size of: ", stringify!(ConstantPathNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantPathNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantPathNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parent) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathNode),
            "::",
            stringify!(parent)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).child) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathNode),
            "::",
            stringify!(child)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).delimiter_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathNode),
            "::",
            stringify!(delimiter_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantPathOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantPathOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantPathOperatorAndWriteNode>(),
        56usize,
        concat!("Size of: ", stringify!(ConstantPathOperatorAndWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantPathOperatorAndWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(ConstantPathOperatorAndWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorAndWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantPathOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantPathOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantPathOperatorOrWriteNode>(),
        56usize,
        concat!("Size of: ", stringify!(ConstantPathOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantPathOperatorOrWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantPathOperatorOrWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorOrWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantPathOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantPathOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantPathOperatorWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(ConstantPathOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantPathOperatorWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantPathOperatorWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathOperatorWriteNode),
            "::",
            stringify!(operator)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantPathWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantPathWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantPathWriteNode>(),
        56usize,
        concat!("Size of: ", stringify!(ConstantPathWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantPathWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantPathWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).target) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathWriteNode),
            "::",
            stringify!(target)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantPathWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ConstantReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<ConstantReadNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ConstantReadNode>(),
        24usize,
        concat!("Size of: ", stringify!(ConstantReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ConstantReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ConstantReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ConstantReadNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_DefNode() {
    const UNINIT: ::std::mem::MaybeUninit<DefNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<DefNode>(),
        184usize,
        concat!("Size of: ", stringify!(DefNode))
    );
    assert_eq!(
        ::std::mem::align_of::<DefNode>(),
        8usize,
        concat!("Alignment of ", stringify!(DefNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).receiver) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(receiver)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parameters) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(parameters)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).def_keyword_loc) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(def_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        104usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lparen_loc) as usize - ptr as usize },
        120usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(lparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rparen_loc) as usize - ptr as usize },
        136usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(rparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).equal_loc) as usize - ptr as usize },
        152usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(equal_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        168usize,
        concat!(
            "Offset of field: ",
            stringify!(DefNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_DefinedNode() {
    const UNINIT: ::std::mem::MaybeUninit<DefinedNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<DefinedNode>(),
        80usize,
        concat!("Size of: ", stringify!(DefinedNode))
    );
    assert_eq!(
        ::std::mem::align_of::<DefinedNode>(),
        8usize,
        concat!("Alignment of ", stringify!(DefinedNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(DefinedNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lparen_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(DefinedNode),
            "::",
            stringify!(lparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(DefinedNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rparen_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(DefinedNode),
            "::",
            stringify!(rparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(DefinedNode),
            "::",
            stringify!(keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ElseNode() {
    const UNINIT: ::std::mem::MaybeUninit<ElseNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ElseNode>(),
        64usize,
        concat!("Size of: ", stringify!(ElseNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ElseNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ElseNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ElseNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).else_keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ElseNode),
            "::",
            stringify!(else_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ElseNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ElseNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_EmbeddedStatementsNode() {
    const UNINIT: ::std::mem::MaybeUninit<EmbeddedStatementsNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<EmbeddedStatementsNode>(),
        64usize,
        concat!("Size of: ", stringify!(EmbeddedStatementsNode))
    );
    assert_eq!(
        ::std::mem::align_of::<EmbeddedStatementsNode>(),
        8usize,
        concat!("Alignment of ", stringify!(EmbeddedStatementsNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedStatementsNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedStatementsNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedStatementsNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedStatementsNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_EmbeddedVariableNode() {
    const UNINIT: ::std::mem::MaybeUninit<EmbeddedVariableNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<EmbeddedVariableNode>(),
        48usize,
        concat!("Size of: ", stringify!(EmbeddedVariableNode))
    );
    assert_eq!(
        ::std::mem::align_of::<EmbeddedVariableNode>(),
        8usize,
        concat!("Alignment of ", stringify!(EmbeddedVariableNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedVariableNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedVariableNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).variable) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(EmbeddedVariableNode),
            "::",
            stringify!(variable)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_EnsureNode() {
    const UNINIT: ::std::mem::MaybeUninit<EnsureNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<EnsureNode>(),
        64usize,
        concat!("Size of: ", stringify!(EnsureNode))
    );
    assert_eq!(
        ::std::mem::align_of::<EnsureNode>(),
        8usize,
        concat!("Alignment of ", stringify!(EnsureNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(EnsureNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).ensure_keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(EnsureNode),
            "::",
            stringify!(ensure_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(EnsureNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(EnsureNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_FalseNode() {
    const UNINIT: ::std::mem::MaybeUninit<FalseNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<FalseNode>(),
        24usize,
        concat!("Size of: ", stringify!(FalseNode))
    );
    assert_eq!(
        ::std::mem::align_of::<FalseNode>(),
        8usize,
        concat!("Alignment of ", stringify!(FalseNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(FalseNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_FindPatternNode() {
    const UNINIT: ::std::mem::MaybeUninit<FindPatternNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<FindPatternNode>(),
        104usize,
        concat!("Size of: ", stringify!(FindPatternNode))
    );
    assert_eq!(
        ::std::mem::align_of::<FindPatternNode>(),
        8usize,
        concat!("Alignment of ", stringify!(FindPatternNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(constant)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).left) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(left)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).requireds) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(requireds)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).right) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(right)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(FindPatternNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_FloatNode() {
    const UNINIT: ::std::mem::MaybeUninit<FloatNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<FloatNode>(),
        24usize,
        concat!("Size of: ", stringify!(FloatNode))
    );
    assert_eq!(
        ::std::mem::align_of::<FloatNode>(),
        8usize,
        concat!("Alignment of ", stringify!(FloatNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(FloatNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ForNode() {
    const UNINIT: ::std::mem::MaybeUninit<ForNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ForNode>(),
        112usize,
        concat!("Size of: ", stringify!(ForNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ForNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ForNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).index) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(index)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).collection) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(collection)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).for_keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(for_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).in_keyword_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(in_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).do_keyword_loc) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(do_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        96usize,
        concat!(
            "Offset of field: ",
            stringify!(ForNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ForwardingArgumentsNode() {
    const UNINIT: ::std::mem::MaybeUninit<ForwardingArgumentsNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ForwardingArgumentsNode>(),
        24usize,
        concat!("Size of: ", stringify!(ForwardingArgumentsNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ForwardingArgumentsNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ForwardingArgumentsNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ForwardingArgumentsNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ForwardingParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<ForwardingParameterNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ForwardingParameterNode>(),
        24usize,
        concat!("Size of: ", stringify!(ForwardingParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ForwardingParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ForwardingParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ForwardingParameterNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ForwardingSuperNode() {
    const UNINIT: ::std::mem::MaybeUninit<ForwardingSuperNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ForwardingSuperNode>(),
        32usize,
        concat!("Size of: ", stringify!(ForwardingSuperNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ForwardingSuperNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ForwardingSuperNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ForwardingSuperNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).block) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ForwardingSuperNode),
            "::",
            stringify!(block)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_GlobalVariableOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<GlobalVariableOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<GlobalVariableOperatorAndWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(GlobalVariableOperatorAndWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<GlobalVariableOperatorAndWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(GlobalVariableOperatorAndWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorAndWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_GlobalVariableOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<GlobalVariableOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<GlobalVariableOperatorOrWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(GlobalVariableOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<GlobalVariableOperatorOrWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(GlobalVariableOperatorOrWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorOrWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_GlobalVariableOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<GlobalVariableOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<GlobalVariableOperatorWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(GlobalVariableOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<GlobalVariableOperatorWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(GlobalVariableOperatorWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableOperatorWriteNode),
            "::",
            stringify!(operator)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_GlobalVariableReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<GlobalVariableReadNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<GlobalVariableReadNode>(),
        24usize,
        concat!("Size of: ", stringify!(GlobalVariableReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<GlobalVariableReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(GlobalVariableReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableReadNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_GlobalVariableWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<GlobalVariableWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<GlobalVariableWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(GlobalVariableWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<GlobalVariableWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(GlobalVariableWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(GlobalVariableWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_HashNode() {
    const UNINIT: ::std::mem::MaybeUninit<HashNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<HashNode>(),
        80usize,
        concat!("Size of: ", stringify!(HashNode))
    );
    assert_eq!(
        ::std::mem::align_of::<HashNode>(),
        8usize,
        concat!("Alignment of ", stringify!(HashNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(HashNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(HashNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).elements) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(HashNode),
            "::",
            stringify!(elements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(HashNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_HashPatternNode() {
    const UNINIT: ::std::mem::MaybeUninit<HashPatternNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<HashPatternNode>(),
        96usize,
        concat!("Size of: ", stringify!(HashPatternNode))
    );
    assert_eq!(
        ::std::mem::align_of::<HashPatternNode>(),
        8usize,
        concat!("Alignment of ", stringify!(HashPatternNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(HashPatternNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(HashPatternNode),
            "::",
            stringify!(constant)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).assocs) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(HashPatternNode),
            "::",
            stringify!(assocs)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).kwrest) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(HashPatternNode),
            "::",
            stringify!(kwrest)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(HashPatternNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(HashPatternNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_IfNode() {
    const UNINIT: ::std::mem::MaybeUninit<IfNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<IfNode>(),
        80usize,
        concat!("Size of: ", stringify!(IfNode))
    );
    assert_eq!(
        ::std::mem::align_of::<IfNode>(),
        8usize,
        concat!("Alignment of ", stringify!(IfNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(IfNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).if_keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(IfNode),
            "::",
            stringify!(if_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).predicate) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(IfNode),
            "::",
            stringify!(predicate)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(IfNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).consequent) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(IfNode),
            "::",
            stringify!(consequent)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(IfNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ImaginaryNode() {
    const UNINIT: ::std::mem::MaybeUninit<ImaginaryNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ImaginaryNode>(),
        32usize,
        concat!("Size of: ", stringify!(ImaginaryNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ImaginaryNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ImaginaryNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ImaginaryNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).numeric) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ImaginaryNode),
            "::",
            stringify!(numeric)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InNode() {
    const UNINIT: ::std::mem::MaybeUninit<InNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InNode>(),
        72usize,
        concat!("Size of: ", stringify!(InNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InNode>(),
        8usize,
        concat!("Alignment of ", stringify!(InNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).pattern) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InNode),
            "::",
            stringify!(pattern)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(InNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).in_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InNode),
            "::",
            stringify!(in_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).then_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(InNode),
            "::",
            stringify!(then_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InstanceVariableOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<InstanceVariableOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InstanceVariableOperatorAndWriteNode>(),
        64usize,
        concat!(
            "Size of: ",
            stringify!(InstanceVariableOperatorAndWriteNode)
        )
    );
    assert_eq!(
        ::std::mem::align_of::<InstanceVariableOperatorAndWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(InstanceVariableOperatorAndWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorAndWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InstanceVariableOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<InstanceVariableOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InstanceVariableOperatorOrWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(InstanceVariableOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InstanceVariableOperatorOrWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(InstanceVariableOperatorOrWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorOrWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InstanceVariableOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<InstanceVariableOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InstanceVariableOperatorWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(InstanceVariableOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InstanceVariableOperatorWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(InstanceVariableOperatorWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableOperatorWriteNode),
            "::",
            stringify!(operator)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InstanceVariableReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<InstanceVariableReadNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InstanceVariableReadNode>(),
        24usize,
        concat!("Size of: ", stringify!(InstanceVariableReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InstanceVariableReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(InstanceVariableReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableReadNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InstanceVariableWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<InstanceVariableWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InstanceVariableWriteNode>(),
        64usize,
        concat!("Size of: ", stringify!(InstanceVariableWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InstanceVariableWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(InstanceVariableWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(InstanceVariableWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_IntegerNode() {
    const UNINIT: ::std::mem::MaybeUninit<IntegerNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<IntegerNode>(),
        24usize,
        concat!("Size of: ", stringify!(IntegerNode))
    );
    assert_eq!(
        ::std::mem::align_of::<IntegerNode>(),
        8usize,
        concat!("Alignment of ", stringify!(IntegerNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(IntegerNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InterpolatedRegularExpressionNode() {
    const UNINIT: ::std::mem::MaybeUninit<InterpolatedRegularExpressionNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InterpolatedRegularExpressionNode>(),
        88usize,
        concat!("Size of: ", stringify!(InterpolatedRegularExpressionNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InterpolatedRegularExpressionNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(InterpolatedRegularExpressionNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedRegularExpressionNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedRegularExpressionNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parts) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedRegularExpressionNode),
            "::",
            stringify!(parts)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedRegularExpressionNode),
            "::",
            stringify!(closing_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).flags) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedRegularExpressionNode),
            "::",
            stringify!(flags)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InterpolatedStringNode() {
    const UNINIT: ::std::mem::MaybeUninit<InterpolatedStringNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InterpolatedStringNode>(),
        80usize,
        concat!("Size of: ", stringify!(InterpolatedStringNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InterpolatedStringNode>(),
        8usize,
        concat!("Alignment of ", stringify!(InterpolatedStringNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedStringNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedStringNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parts) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedStringNode),
            "::",
            stringify!(parts)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedStringNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InterpolatedSymbolNode() {
    const UNINIT: ::std::mem::MaybeUninit<InterpolatedSymbolNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InterpolatedSymbolNode>(),
        80usize,
        concat!("Size of: ", stringify!(InterpolatedSymbolNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InterpolatedSymbolNode>(),
        8usize,
        concat!("Alignment of ", stringify!(InterpolatedSymbolNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedSymbolNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedSymbolNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parts) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedSymbolNode),
            "::",
            stringify!(parts)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedSymbolNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_InterpolatedXStringNode() {
    const UNINIT: ::std::mem::MaybeUninit<InterpolatedXStringNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<InterpolatedXStringNode>(),
        80usize,
        concat!("Size of: ", stringify!(InterpolatedXStringNode))
    );
    assert_eq!(
        ::std::mem::align_of::<InterpolatedXStringNode>(),
        8usize,
        concat!("Alignment of ", stringify!(InterpolatedXStringNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedXStringNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedXStringNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parts) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedXStringNode),
            "::",
            stringify!(parts)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(InterpolatedXStringNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_KeywordHashNode() {
    const UNINIT: ::std::mem::MaybeUninit<KeywordHashNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<KeywordHashNode>(),
        48usize,
        concat!("Size of: ", stringify!(KeywordHashNode))
    );
    assert_eq!(
        ::std::mem::align_of::<KeywordHashNode>(),
        8usize,
        concat!("Alignment of ", stringify!(KeywordHashNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordHashNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).elements) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordHashNode),
            "::",
            stringify!(elements)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_KeywordParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<KeywordParameterNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<KeywordParameterNode>(),
        48usize,
        concat!("Size of: ", stringify!(KeywordParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<KeywordParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(KeywordParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordParameterNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordParameterNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_KeywordRestParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<KeywordRestParameterNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<KeywordRestParameterNode>(),
        56usize,
        concat!("Size of: ", stringify!(KeywordRestParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<KeywordRestParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(KeywordRestParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordRestParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordRestParameterNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(KeywordRestParameterNode),
            "::",
            stringify!(name_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LambdaNode() {
    const UNINIT: ::std::mem::MaybeUninit<LambdaNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LambdaNode>(),
        80usize,
        concat!("Size of: ", stringify!(LambdaNode))
    );
    assert_eq!(
        ::std::mem::align_of::<LambdaNode>(),
        8usize,
        concat!("Alignment of ", stringify!(LambdaNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LambdaNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LambdaNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(LambdaNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parameters) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(LambdaNode),
            "::",
            stringify!(parameters)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(LambdaNode),
            "::",
            stringify!(statements)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LocalVariableOperatorAndWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<LocalVariableOperatorAndWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LocalVariableOperatorAndWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(LocalVariableOperatorAndWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<LocalVariableOperatorAndWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(LocalVariableOperatorAndWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorAndWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorAndWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorAndWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorAndWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorAndWriteNode),
            "::",
            stringify!(constant_id)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LocalVariableOperatorOrWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<LocalVariableOperatorOrWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LocalVariableOperatorOrWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(LocalVariableOperatorOrWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<LocalVariableOperatorOrWriteNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(LocalVariableOperatorOrWriteNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorOrWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorOrWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorOrWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorOrWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorOrWriteNode),
            "::",
            stringify!(constant_id)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LocalVariableOperatorWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<LocalVariableOperatorWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LocalVariableOperatorWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(LocalVariableOperatorWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<LocalVariableOperatorWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(LocalVariableOperatorWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorWriteNode),
            "::",
            stringify!(constant_id)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_id) as usize - ptr as usize },
        68usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableOperatorWriteNode),
            "::",
            stringify!(operator_id)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LocalVariableReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<LocalVariableReadNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LocalVariableReadNode>(),
        32usize,
        concat!("Size of: ", stringify!(LocalVariableReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<LocalVariableReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(LocalVariableReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableReadNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableReadNode),
            "::",
            stringify!(constant_id)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).depth) as usize - ptr as usize },
        28usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableReadNode),
            "::",
            stringify!(depth)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LocalVariableWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<LocalVariableWriteNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LocalVariableWriteNode>(),
        72usize,
        concat!("Size of: ", stringify!(LocalVariableWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<LocalVariableWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(LocalVariableWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableWriteNode),
            "::",
            stringify!(constant_id)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).depth) as usize - ptr as usize },
        28usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableWriteNode),
            "::",
            stringify!(depth)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableWriteNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(LocalVariableWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_MatchPredicateNode() {
    const UNINIT: ::std::mem::MaybeUninit<MatchPredicateNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<MatchPredicateNode>(),
        56usize,
        concat!("Size of: ", stringify!(MatchPredicateNode))
    );
    assert_eq!(
        ::std::mem::align_of::<MatchPredicateNode>(),
        8usize,
        concat!("Alignment of ", stringify!(MatchPredicateNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchPredicateNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchPredicateNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).pattern) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchPredicateNode),
            "::",
            stringify!(pattern)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchPredicateNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_MatchRequiredNode() {
    const UNINIT: ::std::mem::MaybeUninit<MatchRequiredNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<MatchRequiredNode>(),
        56usize,
        concat!("Size of: ", stringify!(MatchRequiredNode))
    );
    assert_eq!(
        ::std::mem::align_of::<MatchRequiredNode>(),
        8usize,
        concat!("Alignment of ", stringify!(MatchRequiredNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchRequiredNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchRequiredNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).pattern) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchRequiredNode),
            "::",
            stringify!(pattern)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(MatchRequiredNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_MissingNode() {
    const UNINIT: ::std::mem::MaybeUninit<MissingNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<MissingNode>(),
        24usize,
        concat!("Size of: ", stringify!(MissingNode))
    );
    assert_eq!(
        ::std::mem::align_of::<MissingNode>(),
        8usize,
        concat!("Alignment of ", stringify!(MissingNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(MissingNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ModuleNode() {
    const UNINIT: ::std::mem::MaybeUninit<ModuleNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ModuleNode>(),
        96usize,
        concat!("Size of: ", stringify!(ModuleNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ModuleNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ModuleNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ModuleNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ModuleNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).module_keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ModuleNode),
            "::",
            stringify!(module_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_path) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(ModuleNode),
            "::",
            stringify!(constant_path)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(ModuleNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(ModuleNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_MultiWriteNode() {
    const UNINIT: ::std::mem::MaybeUninit<MultiWriteNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<MultiWriteNode>(),
        104usize,
        concat!("Size of: ", stringify!(MultiWriteNode))
    );
    assert_eq!(
        ::std::mem::align_of::<MultiWriteNode>(),
        8usize,
        concat!("Alignment of ", stringify!(MultiWriteNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(MultiWriteNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).targets) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(MultiWriteNode),
            "::",
            stringify!(targets)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(MultiWriteNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(MultiWriteNode),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lparen_loc) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(MultiWriteNode),
            "::",
            stringify!(lparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rparen_loc) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(MultiWriteNode),
            "::",
            stringify!(rparen_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_NextNode() {
    const UNINIT: ::std::mem::MaybeUninit<NextNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<NextNode>(),
        48usize,
        concat!("Size of: ", stringify!(NextNode))
    );
    assert_eq!(
        ::std::mem::align_of::<NextNode>(),
        8usize,
        concat!("Alignment of ", stringify!(NextNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(NextNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(NextNode),
            "::",
            stringify!(arguments)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(NextNode),
            "::",
            stringify!(keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_NilNode() {
    const UNINIT: ::std::mem::MaybeUninit<NilNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<NilNode>(),
        24usize,
        concat!("Size of: ", stringify!(NilNode))
    );
    assert_eq!(
        ::std::mem::align_of::<NilNode>(),
        8usize,
        concat!("Alignment of ", stringify!(NilNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(NilNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_NoKeywordsParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<NoKeywordsParameterNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<NoKeywordsParameterNode>(),
        56usize,
        concat!("Size of: ", stringify!(NoKeywordsParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<NoKeywordsParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(NoKeywordsParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(NoKeywordsParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(NoKeywordsParameterNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(NoKeywordsParameterNode),
            "::",
            stringify!(keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_NumberedReferenceReadNode() {
    const UNINIT: ::std::mem::MaybeUninit<NumberedReferenceReadNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<NumberedReferenceReadNode>(),
        24usize,
        concat!("Size of: ", stringify!(NumberedReferenceReadNode))
    );
    assert_eq!(
        ::std::mem::align_of::<NumberedReferenceReadNode>(),
        8usize,
        concat!("Alignment of ", stringify!(NumberedReferenceReadNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(NumberedReferenceReadNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_OptionalParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<OptionalParameterNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<OptionalParameterNode>(),
        72usize,
        concat!("Size of: ", stringify!(OptionalParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<OptionalParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(OptionalParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(OptionalParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(OptionalParameterNode),
            "::",
            stringify!(constant_id)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(OptionalParameterNode),
            "::",
            stringify!(name_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(OptionalParameterNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(OptionalParameterNode),
            "::",
            stringify!(value)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_OrNode() {
    const UNINIT: ::std::mem::MaybeUninit<OrNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<OrNode>(),
        56usize,
        concat!("Size of: ", stringify!(OrNode))
    );
    assert_eq!(
        ::std::mem::align_of::<OrNode>(),
        8usize,
        concat!("Alignment of ", stringify!(OrNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(OrNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).left) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(OrNode),
            "::",
            stringify!(left)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).right) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(OrNode),
            "::",
            stringify!(right)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(OrNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ParametersNode() {
    const UNINIT: ::std::mem::MaybeUninit<ParametersNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ParametersNode>(),
        144usize,
        concat!("Size of: ", stringify!(ParametersNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ParametersNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ParametersNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).requireds) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(requireds)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).optionals) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(optionals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).posts) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(posts)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rest) as usize - ptr as usize },
        96usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(rest)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keywords) as usize - ptr as usize },
        104usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(keywords)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_rest) as usize - ptr as usize },
        128usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(keyword_rest)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).block) as usize - ptr as usize },
        136usize,
        concat!(
            "Offset of field: ",
            stringify!(ParametersNode),
            "::",
            stringify!(block)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ParenthesesNode() {
    const UNINIT: ::std::mem::MaybeUninit<ParenthesesNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ParenthesesNode>(),
        64usize,
        concat!("Size of: ", stringify!(ParenthesesNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ParenthesesNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ParenthesesNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ParenthesesNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ParenthesesNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(ParenthesesNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ParenthesesNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_PinnedExpressionNode() {
    const UNINIT: ::std::mem::MaybeUninit<PinnedExpressionNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<PinnedExpressionNode>(),
        80usize,
        concat!("Size of: ", stringify!(PinnedExpressionNode))
    );
    assert_eq!(
        ::std::mem::align_of::<PinnedExpressionNode>(),
        8usize,
        concat!("Alignment of ", stringify!(PinnedExpressionNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedExpressionNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).expression) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedExpressionNode),
            "::",
            stringify!(expression)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedExpressionNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lparen_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedExpressionNode),
            "::",
            stringify!(lparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rparen_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedExpressionNode),
            "::",
            stringify!(rparen_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_PinnedVariableNode() {
    const UNINIT: ::std::mem::MaybeUninit<PinnedVariableNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<PinnedVariableNode>(),
        48usize,
        concat!("Size of: ", stringify!(PinnedVariableNode))
    );
    assert_eq!(
        ::std::mem::align_of::<PinnedVariableNode>(),
        8usize,
        concat!("Alignment of ", stringify!(PinnedVariableNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedVariableNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).variable) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedVariableNode),
            "::",
            stringify!(variable)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(PinnedVariableNode),
            "::",
            stringify!(operator_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_PostExecutionNode() {
    const UNINIT: ::std::mem::MaybeUninit<PostExecutionNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<PostExecutionNode>(),
        80usize,
        concat!("Size of: ", stringify!(PostExecutionNode))
    );
    assert_eq!(
        ::std::mem::align_of::<PostExecutionNode>(),
        8usize,
        concat!("Alignment of ", stringify!(PostExecutionNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(PostExecutionNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(PostExecutionNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(PostExecutionNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(PostExecutionNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(PostExecutionNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_PreExecutionNode() {
    const UNINIT: ::std::mem::MaybeUninit<PreExecutionNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<PreExecutionNode>(),
        80usize,
        concat!("Size of: ", stringify!(PreExecutionNode))
    );
    assert_eq!(
        ::std::mem::align_of::<PreExecutionNode>(),
        8usize,
        concat!("Alignment of ", stringify!(PreExecutionNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(PreExecutionNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(PreExecutionNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(PreExecutionNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(PreExecutionNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(PreExecutionNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ProgramNode() {
    const UNINIT: ::std::mem::MaybeUninit<ProgramNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ProgramNode>(),
        56usize,
        concat!("Size of: ", stringify!(ProgramNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ProgramNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ProgramNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ProgramNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ProgramNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(ProgramNode),
            "::",
            stringify!(statements)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RangeNode() {
    const UNINIT: ::std::mem::MaybeUninit<RangeNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RangeNode>(),
        64usize,
        concat!("Size of: ", stringify!(RangeNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RangeNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RangeNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RangeNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).left) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RangeNode),
            "::",
            stringify!(left)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).right) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(RangeNode),
            "::",
            stringify!(right)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(RangeNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).flags) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(RangeNode),
            "::",
            stringify!(flags)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RationalNode() {
    const UNINIT: ::std::mem::MaybeUninit<RationalNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RationalNode>(),
        32usize,
        concat!("Size of: ", stringify!(RationalNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RationalNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RationalNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RationalNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).numeric) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RationalNode),
            "::",
            stringify!(numeric)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RedoNode() {
    const UNINIT: ::std::mem::MaybeUninit<RedoNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RedoNode>(),
        24usize,
        concat!("Size of: ", stringify!(RedoNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RedoNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RedoNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RedoNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RegularExpressionNode() {
    const UNINIT: ::std::mem::MaybeUninit<RegularExpressionNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RegularExpressionNode>(),
        104usize,
        concat!("Size of: ", stringify!(RegularExpressionNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RegularExpressionNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RegularExpressionNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RegularExpressionNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RegularExpressionNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).content_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(RegularExpressionNode),
            "::",
            stringify!(content_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(RegularExpressionNode),
            "::",
            stringify!(closing_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).unescaped) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(RegularExpressionNode),
            "::",
            stringify!(unescaped)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).flags) as usize - ptr as usize },
        96usize,
        concat!(
            "Offset of field: ",
            stringify!(RegularExpressionNode),
            "::",
            stringify!(flags)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RequiredDestructuredParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<RequiredDestructuredParameterNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RequiredDestructuredParameterNode>(),
        80usize,
        concat!("Size of: ", stringify!(RequiredDestructuredParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RequiredDestructuredParameterNode>(),
        8usize,
        concat!(
            "Alignment of ",
            stringify!(RequiredDestructuredParameterNode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RequiredDestructuredParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).parameters) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RequiredDestructuredParameterNode),
            "::",
            stringify!(parameters)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(RequiredDestructuredParameterNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(RequiredDestructuredParameterNode),
            "::",
            stringify!(closing_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RequiredParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<RequiredParameterNode> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RequiredParameterNode>(),
        32usize,
        concat!("Size of: ", stringify!(RequiredParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RequiredParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RequiredParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RequiredParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_id) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RequiredParameterNode),
            "::",
            stringify!(constant_id)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RescueModifierNode() {
    const UNINIT: ::std::mem::MaybeUninit<RescueModifierNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RescueModifierNode>(),
        56usize,
        concat!("Size of: ", stringify!(RescueModifierNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RescueModifierNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RescueModifierNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueModifierNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).expression) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueModifierNode),
            "::",
            stringify!(expression)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueModifierNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rescue_expression) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueModifierNode),
            "::",
            stringify!(rescue_expression)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RescueNode() {
    const UNINIT: ::std::mem::MaybeUninit<RescueNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RescueNode>(),
        104usize,
        concat!("Size of: ", stringify!(RescueNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RescueNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RescueNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).exceptions) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(exceptions)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).exception) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(exception)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).consequent) as usize - ptr as usize },
        96usize,
        concat!(
            "Offset of field: ",
            stringify!(RescueNode),
            "::",
            stringify!(consequent)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RestParameterNode() {
    const UNINIT: ::std::mem::MaybeUninit<RestParameterNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RestParameterNode>(),
        56usize,
        concat!("Size of: ", stringify!(RestParameterNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RestParameterNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RestParameterNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RestParameterNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(RestParameterNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(RestParameterNode),
            "::",
            stringify!(name_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_RetryNode() {
    const UNINIT: ::std::mem::MaybeUninit<RetryNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<RetryNode>(),
        24usize,
        concat!("Size of: ", stringify!(RetryNode))
    );
    assert_eq!(
        ::std::mem::align_of::<RetryNode>(),
        8usize,
        concat!("Alignment of ", stringify!(RetryNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(RetryNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ReturnNode() {
    const UNINIT: ::std::mem::MaybeUninit<ReturnNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ReturnNode>(),
        48usize,
        concat!("Size of: ", stringify!(ReturnNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ReturnNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ReturnNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ReturnNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(ReturnNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(ReturnNode),
            "::",
            stringify!(arguments)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SelfNode() {
    const UNINIT: ::std::mem::MaybeUninit<SelfNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SelfNode>(),
        24usize,
        concat!("Size of: ", stringify!(SelfNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SelfNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SelfNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SelfNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SingletonClassNode() {
    const UNINIT: ::std::mem::MaybeUninit<SingletonClassNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SingletonClassNode>(),
        112usize,
        concat!("Size of: ", stringify!(SingletonClassNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SingletonClassNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SingletonClassNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).class_keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(class_keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).expression) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(expression)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        88usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        96usize,
        concat!(
            "Offset of field: ",
            stringify!(SingletonClassNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SourceEncodingNode() {
    const UNINIT: ::std::mem::MaybeUninit<SourceEncodingNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SourceEncodingNode>(),
        24usize,
        concat!("Size of: ", stringify!(SourceEncodingNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SourceEncodingNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SourceEncodingNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SourceEncodingNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SourceFileNode() {
    const UNINIT: ::std::mem::MaybeUninit<SourceFileNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SourceFileNode>(),
        48usize,
        concat!("Size of: ", stringify!(SourceFileNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SourceFileNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SourceFileNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SourceFileNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).filepath) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(SourceFileNode),
            "::",
            stringify!(filepath)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SourceLineNode() {
    const UNINIT: ::std::mem::MaybeUninit<SourceLineNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SourceLineNode>(),
        24usize,
        concat!("Size of: ", stringify!(SourceLineNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SourceLineNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SourceLineNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SourceLineNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SplatNode() {
    const UNINIT: ::std::mem::MaybeUninit<SplatNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SplatNode>(),
        48usize,
        concat!("Size of: ", stringify!(SplatNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SplatNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SplatNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SplatNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).operator_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(SplatNode),
            "::",
            stringify!(operator_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).expression) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(SplatNode),
            "::",
            stringify!(expression)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StatementsNode() {
    const UNINIT: ::std::mem::MaybeUninit<StatementsNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StatementsNode>(),
        48usize,
        concat!("Size of: ", stringify!(StatementsNode))
    );
    assert_eq!(
        ::std::mem::align_of::<StatementsNode>(),
        8usize,
        concat!("Alignment of ", stringify!(StatementsNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StatementsNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).body) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(StatementsNode),
            "::",
            stringify!(body)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringConcatNode() {
    const UNINIT: ::std::mem::MaybeUninit<StringConcatNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringConcatNode>(),
        40usize,
        concat!("Size of: ", stringify!(StringConcatNode))
    );
    assert_eq!(
        ::std::mem::align_of::<StringConcatNode>(),
        8usize,
        concat!("Alignment of ", stringify!(StringConcatNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringConcatNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).left) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(StringConcatNode),
            "::",
            stringify!(left)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).right) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(StringConcatNode),
            "::",
            stringify!(right)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringNode() {
    const UNINIT: ::std::mem::MaybeUninit<StringNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringNode>(),
        96usize,
        concat!("Size of: ", stringify!(StringNode))
    );
    assert_eq!(
        ::std::mem::align_of::<StringNode>(),
        8usize,
        concat!("Alignment of ", stringify!(StringNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(StringNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).content_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(StringNode),
            "::",
            stringify!(content_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(StringNode),
            "::",
            stringify!(closing_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).unescaped) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(StringNode),
            "::",
            stringify!(unescaped)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SuperNode() {
    const UNINIT: ::std::mem::MaybeUninit<SuperNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SuperNode>(),
        88usize,
        concat!("Size of: ", stringify!(SuperNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SuperNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SuperNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SuperNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(SuperNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lparen_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(SuperNode),
            "::",
            stringify!(lparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(SuperNode),
            "::",
            stringify!(arguments)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rparen_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(SuperNode),
            "::",
            stringify!(rparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).block) as usize - ptr as usize },
        80usize,
        concat!(
            "Offset of field: ",
            stringify!(SuperNode),
            "::",
            stringify!(block)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_SymbolNode() {
    const UNINIT: ::std::mem::MaybeUninit<SymbolNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<SymbolNode>(),
        96usize,
        concat!("Size of: ", stringify!(SymbolNode))
    );
    assert_eq!(
        ::std::mem::align_of::<SymbolNode>(),
        8usize,
        concat!("Alignment of ", stringify!(SymbolNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(SymbolNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(SymbolNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(SymbolNode),
            "::",
            stringify!(value_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(SymbolNode),
            "::",
            stringify!(closing_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).unescaped) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(SymbolNode),
            "::",
            stringify!(unescaped)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_TrueNode() {
    const UNINIT: ::std::mem::MaybeUninit<TrueNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<TrueNode>(),
        24usize,
        concat!("Size of: ", stringify!(TrueNode))
    );
    assert_eq!(
        ::std::mem::align_of::<TrueNode>(),
        8usize,
        concat!("Alignment of ", stringify!(TrueNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(TrueNode),
            "::",
            stringify!(base)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_UndefNode() {
    const UNINIT: ::std::mem::MaybeUninit<UndefNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<UndefNode>(),
        64usize,
        concat!("Size of: ", stringify!(UndefNode))
    );
    assert_eq!(
        ::std::mem::align_of::<UndefNode>(),
        8usize,
        concat!("Alignment of ", stringify!(UndefNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(UndefNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).names) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(UndefNode),
            "::",
            stringify!(names)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(UndefNode),
            "::",
            stringify!(keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_UnlessNode() {
    const UNINIT: ::std::mem::MaybeUninit<UnlessNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<UnlessNode>(),
        80usize,
        concat!("Size of: ", stringify!(UnlessNode))
    );
    assert_eq!(
        ::std::mem::align_of::<UnlessNode>(),
        8usize,
        concat!("Alignment of ", stringify!(UnlessNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(UnlessNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(UnlessNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).predicate) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(UnlessNode),
            "::",
            stringify!(predicate)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(UnlessNode),
            "::",
            stringify!(statements)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).consequent) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(UnlessNode),
            "::",
            stringify!(consequent)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end_keyword_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(UnlessNode),
            "::",
            stringify!(end_keyword_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_UntilNode() {
    const UNINIT: ::std::mem::MaybeUninit<UntilNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<UntilNode>(),
        56usize,
        concat!("Size of: ", stringify!(UntilNode))
    );
    assert_eq!(
        ::std::mem::align_of::<UntilNode>(),
        8usize,
        concat!("Alignment of ", stringify!(UntilNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(UntilNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(UntilNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).predicate) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(UntilNode),
            "::",
            stringify!(predicate)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(UntilNode),
            "::",
            stringify!(statements)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_WhenNode() {
    const UNINIT: ::std::mem::MaybeUninit<WhenNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<WhenNode>(),
        72usize,
        concat!("Size of: ", stringify!(WhenNode))
    );
    assert_eq!(
        ::std::mem::align_of::<WhenNode>(),
        8usize,
        concat!("Alignment of ", stringify!(WhenNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(WhenNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(WhenNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).conditions) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(WhenNode),
            "::",
            stringify!(conditions)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(WhenNode),
            "::",
            stringify!(statements)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_WhileNode() {
    const UNINIT: ::std::mem::MaybeUninit<WhileNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<WhileNode>(),
        56usize,
        concat!("Size of: ", stringify!(WhileNode))
    );
    assert_eq!(
        ::std::mem::align_of::<WhileNode>(),
        8usize,
        concat!("Alignment of ", stringify!(WhileNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(WhileNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(WhileNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).predicate) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(WhileNode),
            "::",
            stringify!(predicate)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).statements) as usize - ptr as usize },
        48usize,
        concat!(
            "Offset of field: ",
            stringify!(WhileNode),
            "::",
            stringify!(statements)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_XStringNode() {
    const UNINIT: ::std::mem::MaybeUninit<XStringNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<XStringNode>(),
        96usize,
        concat!("Size of: ", stringify!(XStringNode))
    );
    assert_eq!(
        ::std::mem::align_of::<XStringNode>(),
        8usize,
        concat!("Alignment of ", stringify!(XStringNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(XStringNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).opening_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(XStringNode),
            "::",
            stringify!(opening_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).content_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(XStringNode),
            "::",
            stringify!(content_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closing_loc) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(XStringNode),
            "::",
            stringify!(closing_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).unescaped) as usize - ptr as usize },
        72usize,
        concat!(
            "Offset of field: ",
            stringify!(XStringNode),
            "::",
            stringify!(unescaped)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_YieldNode() {
    const UNINIT: ::std::mem::MaybeUninit<YieldNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<YieldNode>(),
        80usize,
        concat!("Size of: ", stringify!(YieldNode))
    );
    assert_eq!(
        ::std::mem::align_of::<YieldNode>(),
        8usize,
        concat!("Alignment of ", stringify!(YieldNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).base) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(YieldNode),
            "::",
            stringify!(base)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).keyword_loc) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(YieldNode),
            "::",
            stringify!(keyword_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lparen_loc) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(YieldNode),
            "::",
            stringify!(lparen_loc)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).arguments) as usize - ptr as usize },
        56usize,
        concat!(
            "Offset of field: ",
            stringify!(YieldNode),
            "::",
            stringify!(arguments)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).rparen_loc) as usize - ptr as usize },
        64usize,
        concat!(
            "Offset of field: ",
            stringify!(YieldNode),
            "::",
            stringify!(rparen_loc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ListNode() {
    const UNINIT: ::std::mem::MaybeUninit<ListNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ListNode>(),
        8usize,
        concat!("Size of: ", stringify!(ListNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ListNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ListNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).next) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ListNode),
            "::",
            stringify!(next)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_List() {
    const UNINIT: ::std::mem::MaybeUninit<List> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<List>(),
        16usize,
        concat!("Size of: ", stringify!(List))
    );
    assert_eq!(
        ::std::mem::align_of::<List>(),
        8usize,
        concat!("Alignment of ", stringify!(List))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).head) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(List),
            "::",
            stringify!(head)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).tail) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(List),
            "::",
            stringify!(tail)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Diagnostic() {
    const UNINIT: ::std::mem::MaybeUninit<Diagnostic> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Diagnostic>(),
        32usize,
        concat!("Size of: ", stringify!(Diagnostic))
    );
    assert_eq!(
        ::std::mem::align_of::<Diagnostic>(),
        8usize,
        concat!("Alignment of ", stringify!(Diagnostic))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).node) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Diagnostic),
            "::",
            stringify!(node)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Diagnostic),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Diagnostic),
            "::",
            stringify!(end)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).message) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(Diagnostic),
            "::",
            stringify!(message)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Encoding() {
    const UNINIT: ::std::mem::MaybeUninit<Encoding> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Encoding>(),
        48usize,
        concat!("Size of: ", stringify!(Encoding))
    );
    assert_eq!(
        ::std::mem::align_of::<Encoding>(),
        8usize,
        concat!("Alignment of ", stringify!(Encoding))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).char_width) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Encoding),
            "::",
            stringify!(char_width)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).alpha_char) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Encoding),
            "::",
            stringify!(alpha_char)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).alnum_char) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Encoding),
            "::",
            stringify!(alnum_char)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).isupper_char) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(Encoding),
            "::",
            stringify!(isupper_char)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).name) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(Encoding),
            "::",
            stringify!(name)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).multibyte) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(Encoding),
            "::",
            stringify!(multibyte)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_NewlineList() {
    const UNINIT: ::std::mem::MaybeUninit<NewlineList> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<NewlineList>(),
        48usize,
        concat!("Size of: ", stringify!(NewlineList))
    );
    assert_eq!(
        ::std::mem::align_of::<NewlineList>(),
        8usize,
        concat!("Alignment of ", stringify!(NewlineList))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(NewlineList),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).offsets) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(NewlineList),
            "::",
            stringify!(offsets)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).size) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(NewlineList),
            "::",
            stringify!(size)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(NewlineList),
            "::",
            stringify!(capacity)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).last_offset) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(NewlineList),
            "::",
            stringify!(last_offset)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).last_index) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(NewlineList),
            "::",
            stringify!(last_index)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LineColumn() {
    const UNINIT: ::std::mem::MaybeUninit<LineColumn> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LineColumn>(),
        16usize,
        concat!("Size of: ", stringify!(LineColumn))
    );
    assert_eq!(
        ::std::mem::align_of::<LineColumn>(),
        8usize,
        concat!("Alignment of ", stringify!(LineColumn))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).line) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LineColumn),
            "::",
            stringify!(line)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).column) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LineColumn),
            "::",
            stringify!(column)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexModeUnknownTy2UnknownTy1() {
    const UNINIT: ::std::mem::MaybeUninit<LexModeUnknownTy2UnknownTy1> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexModeUnknownTy2UnknownTy1>(),
        24usize,
        concat!("Size of: ", stringify!(LexModeUnknownTy2UnknownTy1))
    );
    assert_eq!(
        ::std::mem::align_of::<LexModeUnknownTy2UnknownTy1>(),
        8usize,
        concat!("Alignment of ", stringify!(LexModeUnknownTy2UnknownTy1))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).nesting) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy1),
            "::",
            stringify!(nesting)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).interpolation) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy1),
            "::",
            stringify!(interpolation)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).incrementor) as usize - ptr as usize },
        9usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy1),
            "::",
            stringify!(incrementor)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).terminator) as usize - ptr as usize },
        10usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy1),
            "::",
            stringify!(terminator)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).breakpoints) as usize - ptr as usize },
        11usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy1),
            "::",
            stringify!(breakpoints)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexModeUnknownTy2UnknownTy2() {
    const UNINIT: ::std::mem::MaybeUninit<LexModeUnknownTy2UnknownTy2> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexModeUnknownTy2UnknownTy2>(),
        16usize,
        concat!("Size of: ", stringify!(LexModeUnknownTy2UnknownTy2))
    );
    assert_eq!(
        ::std::mem::align_of::<LexModeUnknownTy2UnknownTy2>(),
        8usize,
        concat!("Alignment of ", stringify!(LexModeUnknownTy2UnknownTy2))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).nesting) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy2),
            "::",
            stringify!(nesting)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).incrementor) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy2),
            "::",
            stringify!(incrementor)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).terminator) as usize - ptr as usize },
        9usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy2),
            "::",
            stringify!(terminator)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).breakpoints) as usize - ptr as usize },
        10usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy2),
            "::",
            stringify!(breakpoints)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexModeUnknownTy2UnknownTy3() {
    const UNINIT: ::std::mem::MaybeUninit<LexModeUnknownTy2UnknownTy3> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexModeUnknownTy2UnknownTy3>(),
        24usize,
        concat!("Size of: ", stringify!(LexModeUnknownTy2UnknownTy3))
    );
    assert_eq!(
        ::std::mem::align_of::<LexModeUnknownTy2UnknownTy3>(),
        8usize,
        concat!("Alignment of ", stringify!(LexModeUnknownTy2UnknownTy3))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).nesting) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy3),
            "::",
            stringify!(nesting)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).interpolation) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy3),
            "::",
            stringify!(interpolation)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).label_allowed) as usize - ptr as usize },
        9usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy3),
            "::",
            stringify!(label_allowed)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).incrementor) as usize - ptr as usize },
        10usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy3),
            "::",
            stringify!(incrementor)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).terminator) as usize - ptr as usize },
        11usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy3),
            "::",
            stringify!(terminator)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).breakpoints) as usize - ptr as usize },
        12usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy3),
            "::",
            stringify!(breakpoints)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexModeUnknownTy2UnknownTy4() {
    const UNINIT: ::std::mem::MaybeUninit<LexModeUnknownTy2UnknownTy4> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexModeUnknownTy2UnknownTy4>(),
        24usize,
        concat!("Size of: ", stringify!(LexModeUnknownTy2UnknownTy4))
    );
    assert_eq!(
        ::std::mem::align_of::<LexModeUnknownTy2UnknownTy4>(),
        8usize,
        concat!("Alignment of ", stringify!(LexModeUnknownTy2UnknownTy4))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).type_) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy4),
            "::",
            stringify!(type_)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy4),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy4),
            "::",
            stringify!(end)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexModeUnknownTy2UnknownTy5() {
    const UNINIT: ::std::mem::MaybeUninit<LexModeUnknownTy2UnknownTy5> =
        ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexModeUnknownTy2UnknownTy5>(),
        32usize,
        concat!("Size of: ", stringify!(LexModeUnknownTy2UnknownTy5))
    );
    assert_eq!(
        ::std::mem::align_of::<LexModeUnknownTy2UnknownTy5>(),
        8usize,
        concat!("Alignment of ", stringify!(LexModeUnknownTy2UnknownTy5))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).ident_start) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy5),
            "::",
            stringify!(ident_start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).ident_length) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy5),
            "::",
            stringify!(ident_length)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).quote) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy5),
            "::",
            stringify!(quote)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).indent) as usize - ptr as usize },
        20usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy5),
            "::",
            stringify!(indent)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).next_start) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2UnknownTy5),
            "::",
            stringify!(next_start)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexModeUnknownTy2() {
    const UNINIT: ::std::mem::MaybeUninit<LexModeUnknownTy2> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexModeUnknownTy2>(),
        32usize,
        concat!("Size of: ", stringify!(LexModeUnknownTy2))
    );
    assert_eq!(
        ::std::mem::align_of::<LexModeUnknownTy2>(),
        8usize,
        concat!("Alignment of ", stringify!(LexModeUnknownTy2))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).list) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2),
            "::",
            stringify!(list)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).regexp) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2),
            "::",
            stringify!(regexp)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).string) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2),
            "::",
            stringify!(string)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).numeric) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2),
            "::",
            stringify!(numeric)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).heredoc) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexModeUnknownTy2),
            "::",
            stringify!(heredoc)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexMode() {
    const UNINIT: ::std::mem::MaybeUninit<LexMode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexMode>(),
        48usize,
        concat!("Size of: ", stringify!(LexMode))
    );
    assert_eq!(
        ::std::mem::align_of::<LexMode>(),
        8usize,
        concat!("Alignment of ", stringify!(LexMode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).mode) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexMode),
            "::",
            stringify!(mode)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).as_) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexMode),
            "::",
            stringify!(as_)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).prev) as usize - ptr as usize },
        40usize,
        concat!(
            "Offset of field: ",
            stringify!(LexMode),
            "::",
            stringify!(prev)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ContextNode() {
    const UNINIT: ::std::mem::MaybeUninit<ContextNode> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ContextNode>(),
        16usize,
        concat!("Size of: ", stringify!(ContextNode))
    );
    assert_eq!(
        ::std::mem::align_of::<ContextNode>(),
        8usize,
        concat!("Alignment of ", stringify!(ContextNode))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).context) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ContextNode),
            "::",
            stringify!(context)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).prev) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(ContextNode),
            "::",
            stringify!(prev)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Comment() {
    const UNINIT: ::std::mem::MaybeUninit<Comment> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Comment>(),
        32usize,
        concat!("Size of: ", stringify!(Comment))
    );
    assert_eq!(
        ::std::mem::align_of::<Comment>(),
        8usize,
        concat!("Alignment of ", stringify!(Comment))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).node) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Comment),
            "::",
            stringify!(node)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Comment),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Comment),
            "::",
            stringify!(end)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).type_) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(Comment),
            "::",
            stringify!(type_)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_LexCallback() {
    const UNINIT: ::std::mem::MaybeUninit<LexCallback> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<LexCallback>(),
        16usize,
        concat!("Size of: ", stringify!(LexCallback))
    );
    assert_eq!(
        ::std::mem::align_of::<LexCallback>(),
        8usize,
        concat!("Alignment of ", stringify!(LexCallback))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).data) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(LexCallback),
            "::",
            stringify!(data)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).callback) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(LexCallback),
            "::",
            stringify!(callback)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Scope() {
    const UNINIT: ::std::mem::MaybeUninit<Scope> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Scope>(),
        40usize,
        concat!("Size of: ", stringify!(Scope))
    );
    assert_eq!(
        ::std::mem::align_of::<Scope>(),
        8usize,
        concat!("Alignment of ", stringify!(Scope))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).locals) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Scope),
            "::",
            stringify!(locals)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).closed) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(Scope),
            "::",
            stringify!(closed)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).previous) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(Scope),
            "::",
            stringify!(previous)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_ParserUnknownTy1() {
    const UNINIT: ::std::mem::MaybeUninit<ParserUnknownTy1> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<ParserUnknownTy1>(),
        208usize,
        concat!("Size of: ", stringify!(ParserUnknownTy1))
    );
    assert_eq!(
        ::std::mem::align_of::<ParserUnknownTy1>(),
        8usize,
        concat!("Alignment of ", stringify!(ParserUnknownTy1))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).current) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(ParserUnknownTy1),
            "::",
            stringify!(current)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).stack) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(ParserUnknownTy1),
            "::",
            stringify!(stack)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).index) as usize - ptr as usize },
        200usize,
        concat!(
            "Offset of field: ",
            stringify!(ParserUnknownTy1),
            "::",
            stringify!(index)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Parser() {
    const UNINIT: ::std::mem::MaybeUninit<Parser> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Parser>(),
        584usize,
        concat!("Size of: ", stringify!(Parser))
    );
    assert_eq!(
        ::std::mem::align_of::<Parser>(),
        8usize,
        concat!("Alignment of ", stringify!(Parser))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lex_state) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(lex_state)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).command_start) as usize - ptr as usize },
        4usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(command_start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).enclosure_nesting) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(enclosure_nesting)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lambda_enclosure_nesting) as usize - ptr as usize },
        12usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(lambda_enclosure_nesting)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).brace_nesting) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(brace_nesting)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).do_loop_stack) as usize - ptr as usize },
        20usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(do_loop_stack)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).accepts_block_stack) as usize - ptr as usize },
        24usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(accepts_block_stack)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lex_modes) as usize - ptr as usize },
        32usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(lex_modes)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).start) as usize - ptr as usize },
        240usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).end) as usize - ptr as usize },
        248usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(end)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).previous) as usize - ptr as usize },
        256usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(previous)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).current) as usize - ptr as usize },
        280usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(current)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).next_start) as usize - ptr as usize },
        304usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(next_start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).heredoc_end) as usize - ptr as usize },
        312usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(heredoc_end)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).comment_list) as usize - ptr as usize },
        320usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(comment_list)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).warning_list) as usize - ptr as usize },
        336usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(warning_list)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).error_list) as usize - ptr as usize },
        352usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(error_list)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).current_scope) as usize - ptr as usize },
        368usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(current_scope)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).current_context) as usize - ptr as usize },
        376usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(current_context)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).recovering) as usize - ptr as usize },
        384usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(recovering)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).encoding) as usize - ptr as usize },
        392usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(encoding)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).encoding_changed) as usize - ptr as usize },
        440usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(encoding_changed)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).encoding_changed_callback) as usize - ptr as usize },
        448usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(encoding_changed_callback)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).encoding_decode_callback) as usize - ptr as usize },
        456usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(encoding_decode_callback)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).encoding_comment_start) as usize - ptr as usize },
        464usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(encoding_comment_start)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).lex_callback) as usize - ptr as usize },
        472usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(lex_callback)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).pattern_matching_newlines) as usize - ptr as usize },
        480usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(pattern_matching_newlines)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).in_keyword_arg) as usize - ptr as usize },
        481usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(in_keyword_arg)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).filepath_string) as usize - ptr as usize },
        488usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(filepath_string)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).constant_pool) as usize - ptr as usize },
        512usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(constant_pool)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).newline_list) as usize - ptr as usize },
        536usize,
        concat!(
            "Offset of field: ",
            stringify!(Parser),
            "::",
            stringify!(newline_list)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Memsize() {
    const UNINIT: ::std::mem::MaybeUninit<Memsize> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Memsize>(),
        16usize,
        concat!("Size of: ", stringify!(Memsize))
    );
    assert_eq!(
        ::std::mem::align_of::<Memsize>(),
        8usize,
        concat!("Alignment of ", stringify!(Memsize))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).memsize) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Memsize),
            "::",
            stringify!(memsize)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).node_count) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Memsize),
            "::",
            stringify!(node_count)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_StringList() {
    const UNINIT: ::std::mem::MaybeUninit<StringList> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<StringList>(),
        24usize,
        concat!("Size of: ", stringify!(StringList))
    );
    assert_eq!(
        ::std::mem::align_of::<StringList>(),
        8usize,
        concat!("Alignment of ", stringify!(StringList))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).strings) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(StringList),
            "::",
            stringify!(strings)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).length) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(StringList),
            "::",
            stringify!(length)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(StringList),
            "::",
            stringify!(capacity)
        )
    );
}
#[test]
#[allow(non_snake_case)]
fn bindgen_test_layout_Buffer() {
    const UNINIT: ::std::mem::MaybeUninit<Buffer> = ::std::mem::MaybeUninit::uninit();
    let ptr = UNINIT.as_ptr();
    assert_eq!(
        ::std::mem::size_of::<Buffer>(),
        24usize,
        concat!("Size of: ", stringify!(Buffer))
    );
    assert_eq!(
        ::std::mem::align_of::<Buffer>(),
        8usize,
        concat!("Alignment of ", stringify!(Buffer))
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).value) as usize - ptr as usize },
        0usize,
        concat!(
            "Offset of field: ",
            stringify!(Buffer),
            "::",
            stringify!(value)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).length) as usize - ptr as usize },
        8usize,
        concat!(
            "Offset of field: ",
            stringify!(Buffer),
            "::",
            stringify!(length)
        )
    );
    assert_eq!(
        unsafe { ::std::ptr::addr_of!((*ptr).capacity) as usize - ptr as usize },
        16usize,
        concat!(
            "Offset of field: ",
            stringify!(Buffer),
            "::",
            stringify!(capacity)
        )
    );
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum StringUnknownTy1 {
    StringShared = 0,
    StringOwned = 1,
    StringConstant = 2,
}
#[repr(u32)]
#[doc = "This enum represents every type of token in the Ruby source."]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum TokenType {
    #[doc = "final token in the file"]
    Eof = 1,
    #[doc = "a token that was expected but not found"]
    Missing = 2,
    #[doc = "a token that was not present but it is okay"]
    NotProvided = 3,
    #[doc = "&"]
    Ampersand = 4,
    #[doc = "&&"]
    AmpersandAmpersand = 5,
    #[doc = "&&="]
    AmpersandAmpersandEqual = 6,
    #[doc = "&."]
    AmpersandDot = 7,
    #[doc = "&="]
    AmpersandEqual = 8,
    #[doc = "`"]
    Backtick = 9,
    #[doc = "a back reference"]
    BackReference = 10,
    #[doc = "! or !@"]
    Bang = 11,
    #[doc = "!="]
    BangEqual = 12,
    #[doc = "!~"]
    BangTilde = 13,
    #[doc = "{"]
    BraceLeft = 14,
    #[doc = "}"]
    BraceRight = 15,
    #[doc = "["]
    BracketLeft = 16,
    #[doc = "[ for the beginning of an array"]
    BracketLeftArray = 17,
    #[doc = "[]"]
    BracketLeftRight = 18,
    #[doc = "[]="]
    BracketLeftRightEqual = 19,
    #[doc = "]"]
    BracketRight = 20,
    #[doc = "^"]
    Caret = 21,
    #[doc = "^="]
    CaretEqual = 22,
    #[doc = "a character literal"]
    CharacterLiteral = 23,
    #[doc = "a class variable"]
    ClassVariable = 24,
    #[doc = ":"]
    Colon = 25,
    #[doc = "::"]
    ColonColon = 26,
    #[doc = ","]
    Comma = 27,
    #[doc = "a comment"]
    Comment = 28,
    #[doc = "a constant"]
    Constant = 29,
    #[doc = "."]
    Dot = 30,
    #[doc = ".."]
    DotDot = 31,
    #[doc = "..."]
    DotDotDot = 32,
    #[doc = "=begin"]
    EmbdocBegin = 33,
    #[doc = "=end"]
    EmbdocEnd = 34,
    #[doc = "a line inside of embedded documentation"]
    EmbdocLine = 35,
    #[doc = "#{"]
    EmbexprBegin = 36,
    #[doc = "}"]
    EmbexprEnd = 37,
    #[doc = "#"]
    Embvar = 38,
    #[doc = "="]
    Equal = 39,
    #[doc = "=="]
    EqualEqual = 40,
    #[doc = "==="]
    EqualEqualEqual = 41,
    #[doc = "=>"]
    EqualGreater = 42,
    #[doc = "=~"]
    EqualTilde = 43,
    #[doc = "a floating point number"]
    Float = 44,
    #[doc = "a global variable"]
    GlobalVariable = 45,
    #[doc = ">"]
    Greater = 46,
    #[doc = ">="]
    GreaterEqual = 47,
    #[doc = ">>"]
    GreaterGreater = 48,
    #[doc = ">>="]
    GreaterGreaterEqual = 49,
    #[doc = "the end of a heredoc"]
    HeredocEnd = 50,
    #[doc = "the start of a heredoc"]
    HeredocStart = 51,
    #[doc = "an identifier"]
    Identifier = 52,
    #[doc = "an ignored newline"]
    IgnoredNewline = 53,
    #[doc = "an imaginary number literal"]
    ImaginaryNumber = 54,
    #[doc = "an instance variable"]
    InstanceVariable = 55,
    #[doc = "an integer (any base)"]
    Integer = 56,
    #[doc = "alias"]
    KeywordAlias = 57,
    #[doc = "and"]
    KeywordAnd = 58,
    #[doc = "begin"]
    KeywordBegin = 59,
    #[doc = "BEGIN"]
    KeywordBeginUpcase = 60,
    #[doc = "break"]
    KeywordBreak = 61,
    #[doc = "case"]
    KeywordCase = 62,
    #[doc = "class"]
    KeywordClass = 63,
    #[doc = "def"]
    KeywordDef = 64,
    #[doc = "defined?"]
    KeywordDefined = 65,
    #[doc = "do"]
    KeywordDo = 66,
    #[doc = "do keyword for a predicate in a while, until, or for loop"]
    KeywordDoLoop = 67,
    #[doc = "else"]
    KeywordElse = 68,
    #[doc = "elsif"]
    KeywordElsif = 69,
    #[doc = "end"]
    KeywordEnd = 70,
    #[doc = "END"]
    KeywordEndUpcase = 71,
    #[doc = "ensure"]
    KeywordEnsure = 72,
    #[doc = "false"]
    KeywordFalse = 73,
    #[doc = "for"]
    KeywordFor = 74,
    #[doc = "if"]
    KeywordIf = 75,
    #[doc = "if in the modifier form"]
    KeywordIfModifier = 76,
    #[doc = "in"]
    KeywordIn = 77,
    #[doc = "module"]
    KeywordModule = 78,
    #[doc = "next"]
    KeywordNext = 79,
    #[doc = "nil"]
    KeywordNil = 80,
    #[doc = "not"]
    KeywordNot = 81,
    #[doc = "or"]
    KeywordOr = 82,
    #[doc = "redo"]
    KeywordRedo = 83,
    #[doc = "rescue"]
    KeywordRescue = 84,
    #[doc = "rescue in the modifier form"]
    KeywordRescueModifier = 85,
    #[doc = "retry"]
    KeywordRetry = 86,
    #[doc = "return"]
    KeywordReturn = 87,
    #[doc = "self"]
    KeywordSelf = 88,
    #[doc = "super"]
    KeywordSuper = 89,
    #[doc = "then"]
    KeywordThen = 90,
    #[doc = "true"]
    KeywordTrue = 91,
    #[doc = "undef"]
    KeywordUndef = 92,
    #[doc = "unless"]
    KeywordUnless = 93,
    #[doc = "unless in the modifier form"]
    KeywordUnlessModifier = 94,
    #[doc = "until"]
    KeywordUntil = 95,
    #[doc = "until in the modifier form"]
    KeywordUntilModifier = 96,
    #[doc = "when"]
    KeywordWhen = 97,
    #[doc = "while"]
    KeywordWhile = 98,
    #[doc = "while in the modifier form"]
    KeywordWhileModifier = 99,
    #[doc = "yield"]
    KeywordYield = 100,
    #[doc = "__ENCODING__"]
    KeywordEncoding = 101,
    #[doc = "__FILE__"]
    KeywordFile = 102,
    #[doc = "__LINE__"]
    KeywordLine = 103,
    #[doc = "a label"]
    Label = 104,
    #[doc = "the end of a label"]
    LabelEnd = 105,
    #[doc = "{"]
    LambdaBegin = 106,
    #[doc = "<"]
    Less = 107,
    #[doc = "<="]
    LessEqual = 108,
    #[doc = "<=>"]
    LessEqualGreater = 109,
    #[doc = "<<"]
    LessLess = 110,
    #[doc = "<<="]
    LessLessEqual = 111,
    #[doc = "-"]
    Minus = 112,
    #[doc = "-="]
    MinusEqual = 113,
    #[doc = "->"]
    MinusGreater = 114,
    #[doc = "a newline character outside of other tokens"]
    Newline = 115,
    #[doc = "a numbered reference to a capture group in the previous regular expression match"]
    NumberedReference = 116,
    #[doc = "("]
    ParenthesisLeft = 117,
    #[doc = "( for a parentheses node"]
    ParenthesisLeftParentheses = 118,
    #[doc = ")"]
    ParenthesisRight = 119,
    #[doc = "%"]
    Percent = 120,
    #[doc = "%="]
    PercentEqual = 121,
    #[doc = "%i"]
    PercentLowerI = 122,
    #[doc = "%w"]
    PercentLowerW = 123,
    #[doc = "%x"]
    PercentLowerX = 124,
    #[doc = "%I"]
    PercentUpperI = 125,
    #[doc = "%W"]
    PercentUpperW = 126,
    #[doc = "|"]
    Pipe = 127,
    #[doc = "|="]
    PipeEqual = 128,
    #[doc = "||"]
    PipePipe = 129,
    #[doc = "||="]
    PipePipeEqual = 130,
    #[doc = "+"]
    Plus = 131,
    #[doc = "+="]
    PlusEqual = 132,
    #[doc = "?"]
    QuestionMark = 133,
    #[doc = "a rational number literal"]
    RationalNumber = 134,
    #[doc = "the beginning of a regular expression"]
    RegexpBegin = 135,
    #[doc = "the end of a regular expression"]
    RegexpEnd = 136,
    #[doc = ";"]
    Semicolon = 137,
    #[doc = "/"]
    Slash = 138,
    #[doc = "/="]
    SlashEqual = 139,
    #[doc = "*"]
    Star = 140,
    #[doc = "*="]
    StarEqual = 141,
    #[doc = "**"]
    StarStar = 142,
    #[doc = "**="]
    StarStarEqual = 143,
    #[doc = "the beginning of a string"]
    StringBegin = 144,
    #[doc = "the contents of a string"]
    StringContent = 145,
    #[doc = "the end of a string"]
    StringEnd = 146,
    #[doc = "the beginning of a symbol"]
    SymbolBegin = 147,
    #[doc = "~ or ~@"]
    Tilde = 148,
    #[doc = "unary ::"]
    UcolonColon = 149,
    #[doc = "unary .."]
    UdotDot = 150,
    #[doc = "unary ..."]
    UdotDotDot = 151,
    #[doc = "-@"]
    Uminus = 152,
    #[doc = "-@ for a number"]
    UminusNum = 153,
    #[doc = "+@"]
    Uplus = 154,
    #[doc = "unary *"]
    Ustar = 155,
    #[doc = "unary **"]
    UstarStar = 156,
    #[doc = "a separator between words in a list"]
    WordsSep = 157,
    #[doc = "marker for the point in the file at which the parser should stop"]
    End = 158,
    #[doc = "the maximum token value"]
    Maximum = 159,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum NodeType {
    AliasNode = 1,
    AlternationPatternNode = 2,
    AndNode = 3,
    ArgumentsNode = 4,
    ArrayNode = 5,
    ArrayPatternNode = 6,
    AssocNode = 7,
    AssocSplatNode = 8,
    BackReferenceReadNode = 9,
    BeginNode = 10,
    BlockArgumentNode = 11,
    BlockNode = 12,
    BlockParameterNode = 13,
    BlockParametersNode = 14,
    BreakNode = 15,
    CallNode = 16,
    CallOperatorAndWriteNode = 17,
    CallOperatorOrWriteNode = 18,
    CallOperatorWriteNode = 19,
    CapturePatternNode = 20,
    CaseNode = 21,
    ClassNode = 22,
    ClassVariableOperatorAndWriteNode = 23,
    ClassVariableOperatorOrWriteNode = 24,
    ClassVariableOperatorWriteNode = 25,
    ClassVariableReadNode = 26,
    ClassVariableWriteNode = 27,
    ConstantOperatorAndWriteNode = 28,
    ConstantOperatorOrWriteNode = 29,
    ConstantOperatorWriteNode = 30,
    ConstantPathNode = 31,
    ConstantPathOperatorAndWriteNode = 32,
    ConstantPathOperatorOrWriteNode = 33,
    ConstantPathOperatorWriteNode = 34,
    ConstantPathWriteNode = 35,
    ConstantReadNode = 36,
    DefNode = 37,
    DefinedNode = 38,
    ElseNode = 39,
    EmbeddedStatementsNode = 40,
    EmbeddedVariableNode = 41,
    EnsureNode = 42,
    FalseNode = 43,
    FindPatternNode = 44,
    FloatNode = 45,
    ForNode = 46,
    ForwardingArgumentsNode = 47,
    ForwardingParameterNode = 48,
    ForwardingSuperNode = 49,
    GlobalVariableOperatorAndWriteNode = 50,
    GlobalVariableOperatorOrWriteNode = 51,
    GlobalVariableOperatorWriteNode = 52,
    GlobalVariableReadNode = 53,
    GlobalVariableWriteNode = 54,
    HashNode = 55,
    HashPatternNode = 56,
    IfNode = 57,
    ImaginaryNode = 58,
    InNode = 59,
    InstanceVariableOperatorAndWriteNode = 60,
    InstanceVariableOperatorOrWriteNode = 61,
    InstanceVariableOperatorWriteNode = 62,
    InstanceVariableReadNode = 63,
    InstanceVariableWriteNode = 64,
    IntegerNode = 65,
    InterpolatedRegularExpressionNode = 66,
    InterpolatedStringNode = 67,
    InterpolatedSymbolNode = 68,
    InterpolatedXStringNode = 69,
    KeywordHashNode = 70,
    KeywordParameterNode = 71,
    KeywordRestParameterNode = 72,
    LambdaNode = 73,
    LocalVariableOperatorAndWriteNode = 74,
    LocalVariableOperatorOrWriteNode = 75,
    LocalVariableOperatorWriteNode = 76,
    LocalVariableReadNode = 77,
    LocalVariableWriteNode = 78,
    MatchPredicateNode = 79,
    MatchRequiredNode = 80,
    MissingNode = 81,
    ModuleNode = 82,
    MultiWriteNode = 83,
    NextNode = 84,
    NilNode = 85,
    NoKeywordsParameterNode = 86,
    NumberedReferenceReadNode = 87,
    OptionalParameterNode = 88,
    OrNode = 89,
    ParametersNode = 90,
    ParenthesesNode = 91,
    PinnedExpressionNode = 92,
    PinnedVariableNode = 93,
    PostExecutionNode = 94,
    PreExecutionNode = 95,
    ProgramNode = 96,
    RangeNode = 97,
    RationalNode = 98,
    RedoNode = 99,
    RegularExpressionNode = 100,
    RequiredDestructuredParameterNode = 101,
    RequiredParameterNode = 102,
    RescueModifierNode = 103,
    RescueNode = 104,
    RestParameterNode = 105,
    RetryNode = 106,
    ReturnNode = 107,
    SelfNode = 108,
    SingletonClassNode = 109,
    SourceEncodingNode = 110,
    SourceFileNode = 111,
    SourceLineNode = 112,
    SplatNode = 113,
    StatementsNode = 114,
    StringConcatNode = 115,
    StringNode = 116,
    SuperNode = 117,
    SymbolNode = 118,
    TrueNode = 119,
    UndefNode = 120,
    UnlessNode = 121,
    UntilNode = 122,
    WhenNode = 123,
    WhileNode = 124,
    XStringNode = 125,
    YieldNode = 126,
}
#[repr(u32)]
#[doc = "CallNodeFlags"]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum CallNodeFlags {
    SafeNavigation = 1,
}
#[repr(u32)]
#[doc = "RangeNodeFlags"]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum RangeNodeFlags {
    ExcludeEnd = 1,
}
#[repr(u32)]
#[doc = "RegularExpressionFlags"]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum RegularExpressionFlags {
    IgnoreCase = 1,
    MultiLine = 2,
    Extended = 4,
    EucJp = 8,
    Ascii8bit = 16,
    Windows31j = 32,
    Utf8 = 64,
    Once = 128,
}
#[repr(u32)]
#[doc = "This enum provides various bits that represent different kinds of states that\n the lexer can track. This is used to determine which kind of token to return\n based on the context of the parser."]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum LexStateBit {
    Beg = 0,
    End = 1,
    Endarg = 2,
    Endfn = 3,
    Arg = 4,
    Cmdarg = 5,
    Mid = 6,
    Fname = 7,
    Dot = 8,
    Class = 9,
    Label = 10,
    Labeled = 11,
    Fitem = 12,
}
#[repr(u32)]
#[doc = "This enum combines the various bits from the above enum into individual\n values that represent the various states of the lexer."]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum LexState {
    None = 0,
    Beg = 1,
    End = 2,
    Endarg = 4,
    Endfn = 8,
    Arg = 16,
    Cmdarg = 32,
    Mid = 64,
    Fname = 128,
    Dot = 256,
    Class = 512,
    Label = 1024,
    Labeled = 2048,
    Fitem = 4096,
    BegAny = 577,
    ArgAny = 48,
    EndAny = 14,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum HeredocQuote {
    None = 0,
    Single = 39,
    Double = 34,
    Backtick = 96,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum HeredocIndent {
    None = 0,
    Dash = 1,
    Tilde = 2,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum LexModeUnknownTy1 {
    #[doc = "This state is used when any given token is being lexed."]
    LexDefault = 0,
    #[doc = "This state is used when we're lexing as normal but inside an embedded\n expression of a string."]
    LexEmbexpr = 1,
    #[doc = "This state is used when we're lexing a variable that is embedded\n directly inside of a string with the # shorthand."]
    LexEmbvar = 2,
    #[doc = "This state is used when you are inside the content of a heredoc."]
    LexHeredoc = 3,
    #[doc = "This state is used when we are lexing a list of tokens, as in a %w\n word list literal or a %i symbol list literal."]
    LexList = 4,
    #[doc = "This state is used when a regular expression has been begun and we\n are looking for the terminator."]
    LexRegexp = 5,
    #[doc = "This state is used when we are lexing a string or a string-like\n token, as in string content with either quote or an xstring."]
    LexString = 6,
    #[doc = "you lexed a number with extra information attached"]
    LexNumeric = 7,
}
#[repr(u32)]
#[doc = "While parsing, we keep track of a stack of contexts. This is helpful for\n error recovery so that we can pop back to a previous context when we hit a\n token that is understood by a parent context but not by the current context."]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum Context {
    #[doc = "a begin statement"]
    Begin = 0,
    #[doc = "expressions in block arguments using braces"]
    BlockBraces = 1,
    #[doc = "expressions in block arguments using do..end"]
    BlockKeywords = 2,
    #[doc = "a case when statements"]
    CaseWhen = 3,
    #[doc = "a case in statements"]
    CaseIn = 4,
    #[doc = "a class declaration"]
    Class = 5,
    #[doc = "a method definition"]
    Def = 6,
    #[doc = "a method definition's parameters"]
    DefParams = 7,
    #[doc = "a method definition's default parameter"]
    DefaultParams = 8,
    #[doc = "an else clause"]
    Else = 9,
    #[doc = "an elsif clause"]
    Elsif = 10,
    #[doc = "an interpolated expression"]
    Embexpr = 11,
    #[doc = "an ensure statement"]
    Ensure = 12,
    #[doc = "a for loop"]
    For = 13,
    #[doc = "an if statement"]
    If = 14,
    #[doc = "a lambda expression with braces"]
    LambdaBraces = 15,
    #[doc = "a lambda expression with do..end"]
    LambdaDoEnd = 16,
    #[doc = "the top level context"]
    Main = 17,
    #[doc = "a module declaration"]
    Module = 18,
    #[doc = "a parenthesized expression"]
    Parens = 19,
    #[doc = "an END block"]
    Postexe = 20,
    #[doc = "a predicate inside an if/elsif/unless statement"]
    Predicate = 21,
    #[doc = "a BEGIN block"]
    Preexe = 22,
    #[doc = "a rescue else statement"]
    RescueElse = 23,
    #[doc = "a rescue statement"]
    Rescue = 24,
    #[doc = "a singleton class definition"]
    Sclass = 25,
    #[doc = "an unless statement"]
    Unless = 26,
    #[doc = "an until statement"]
    Until = 27,
    #[doc = "a while statement"]
    While = 28,
}
#[repr(u32)]
#[doc = "This is the type of a comment that we've found while parsing."]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum CommentType {
    Inline = 0,
    Embdoc = 1,
    End = 2,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackVersion {
    PackVersion320 = 0,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackVariant {
    Pack = 0,
    Unpack = 1,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackType {
    Space = 0,
    Comment = 1,
    Integer = 2,
    Utf8 = 3,
    Ber = 4,
    Float = 5,
    StringSpacePadded = 6,
    StringNullPadded = 7,
    StringNullTerminated = 8,
    StringMsb = 9,
    StringLsb = 10,
    StringHexHigh = 11,
    StringHexLow = 12,
    StringUu = 13,
    StringMime = 14,
    StringBase64 = 15,
    StringFixed = 16,
    StringPointer = 17,
    Move = 18,
    Back = 19,
    Null = 20,
    End = 21,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackSigned {
    PackUnsigned = 0,
    PackSigned = 1,
    Na = 2,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackEndian {
    PackAgnosticEndian = 0,
    #[doc = "aka 'VAX', or 'V'"]
    PackLittleEndian = 1,
    #[doc = "aka 'network', or 'N'"]
    PackBigEndian = 2,
    PackNativeEndian = 3,
    Na = 4,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackSize {
    Short = 0,
    Int = 1,
    Long = 2,
    LongLong = 3,
    PackSize8 = 4,
    PackSize16 = 5,
    PackSize32 = 6,
    PackSize64 = 7,
    P = 8,
    Na = 9,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackLengthType {
    Fixed = 0,
    Max = 1,
    #[doc = "special case for unpack @*"]
    Relative = 2,
    Na = 3,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackEncoding {
    Start = 0,
    Ascii8bit = 1,
    UsAscii = 2,
    Utf8 = 3,
}
#[repr(u32)]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum PackResult {
    PackOk = 0,
    PackErrorUnsupportedDirective = 1,
    PackErrorUnknownDirective = 2,
    PackErrorLengthTooBig = 3,
    PackErrorBangNotAllowed = 4,
    PackErrorDoubleEndian = 5,
}
#[repr(u32)]
#[doc = "The type of unescape we are performing."]
#[derive(Debug, Clone, Hash, PartialEq, Eq)]
pub enum UnescapeType {
    #[doc = "When we're creating a string inside of a list literal like %w, we\n shouldn't escape anything."]
    None = 0,
    #[doc = "When we're unescaping a single-quoted string, we only need to unescape\n single quotes and backslashes."]
    Minimal = 1,
    #[doc = "When we're unescaping a double-quoted string, we need to unescape all\n escapes."]
    All = 2,
}
impl<T> __BindgenUnionField<T> {
    #[inline]
    pub const fn new() -> Self {
        __BindgenUnionField(::std::marker::PhantomData)
    }
    #[inline]
    pub unsafe fn as_ref(&self) -> &T {
        ::std::mem::transmute(self)
    }
    #[inline]
    pub unsafe fn as_mut(&mut self) -> &mut T {
        ::std::mem::transmute(self)
    }
}
impl<T> ::std::default::Default for __BindgenUnionField<T> {
    #[inline]
    fn default() -> Self {
        Self::new()
    }
}
impl<T> ::std::clone::Clone for __BindgenUnionField<T> {
    #[inline]
    fn clone(&self) -> Self {
        Self::new()
    }
}
impl<T> ::std::marker::Copy for __BindgenUnionField<T> {}
impl<T> ::std::fmt::Debug for __BindgenUnionField<T> {
    fn fmt(&self, fmt: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        fmt.write_str("__BindgenUnionField")
    }
}
impl<T> ::std::hash::Hash for __BindgenUnionField<T> {
    fn hash<H: ::std::hash::Hasher>(&self, _state: &mut H) {}
}
impl<T> ::std::cmp::PartialEq for __BindgenUnionField<T> {
    fn eq(&self, _other: &__BindgenUnionField<T>) -> bool {
        true
    }
}
impl<T> ::std::cmp::Eq for __BindgenUnionField<T> {}
impl Default for ConstantIdList {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Constant {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantPool {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StringUnknownTy2UnknownTy1 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StringUnknownTy2UnknownTy2 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StringUnknownTy2UnknownTy3 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StringUnknownTy2 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for StringUnknownTy2 {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write!(f, "StringUnknownTy2 {{ union }}")
    }
}
impl Default for String {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for String {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write!(f, "String {{ type: {:?}, as: {:?} }}", self.type_, self.as_)
    }
}
impl Default for Token {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Location {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LocationList {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for NodeList {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Node {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for AliasNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for AlternationPatternNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for AndNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ArgumentsNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ArrayNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ArrayPatternNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for AssocNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for AssocSplatNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BackReferenceReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BeginNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BlockArgumentNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BlockNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BlockParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BlockParametersNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for BreakNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for CallNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for CallNode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write ! (f , "CallNode {{ base: {:?}, receiver: {:?}, operator_loc: {:?}, message_loc: {:?}, opening_loc: {:?}, arguments: {:?}, closing_loc: {:?}, block: {:?}, name: {:?} }}" , self . base , self . receiver , self . operator_loc , self . message_loc , self . opening_loc , self . arguments , self . closing_loc , self . block , self . name)
    }
}
impl Default for CallOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for CallOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for CallOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for CapturePatternNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for CaseNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ClassNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ClassVariableOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ClassVariableOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ClassVariableOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ClassVariableReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ClassVariableWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantPathNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantPathOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantPathOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantPathOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantPathWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ConstantReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for DefNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for DefinedNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ElseNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for EmbeddedStatementsNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for EmbeddedVariableNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for EnsureNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for FalseNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for FindPatternNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for FloatNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ForNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ForwardingArgumentsNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ForwardingParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ForwardingSuperNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for GlobalVariableOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for GlobalVariableOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for GlobalVariableOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for GlobalVariableReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for GlobalVariableWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for HashNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for HashPatternNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for IfNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ImaginaryNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InstanceVariableOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InstanceVariableOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InstanceVariableOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InstanceVariableReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InstanceVariableWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for IntegerNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InterpolatedRegularExpressionNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InterpolatedStringNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InterpolatedSymbolNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for InterpolatedXStringNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for KeywordHashNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for KeywordParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for KeywordRestParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LambdaNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LocalVariableOperatorAndWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LocalVariableOperatorOrWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LocalVariableOperatorWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LocalVariableReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LocalVariableWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for MatchPredicateNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for MatchRequiredNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for MissingNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ModuleNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for MultiWriteNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for NextNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for NilNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for NoKeywordsParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for NumberedReferenceReadNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for OptionalParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for OrNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ParametersNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ParenthesesNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for PinnedExpressionNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for PinnedVariableNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for PostExecutionNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for PreExecutionNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ProgramNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RangeNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RationalNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RedoNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RegularExpressionNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for RegularExpressionNode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write ! (f , "RegularExpressionNode {{ base: {:?}, opening_loc: {:?}, content_loc: {:?}, closing_loc: {:?}, unescaped: {:?} }}" , self . base , self . opening_loc , self . content_loc , self . closing_loc , self . unescaped)
    }
}
impl Default for RequiredDestructuredParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RequiredParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RescueModifierNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RescueNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RestParameterNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for RetryNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ReturnNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for SelfNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for SingletonClassNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for SourceEncodingNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for SourceFileNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for SourceFileNode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write!(
            f,
            "SourceFileNode {{ base: {:?}, filepath: {:?} }}",
            self.base, self.filepath
        )
    }
}
impl Default for SourceLineNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for SplatNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StatementsNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StringConcatNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for StringNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for StringNode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write ! (f , "StringNode {{ base: {:?}, opening_loc: {:?}, content_loc: {:?}, closing_loc: {:?}, unescaped: {:?} }}" , self . base , self . opening_loc , self . content_loc , self . closing_loc , self . unescaped)
    }
}
impl Default for SuperNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for SymbolNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for SymbolNode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write ! (f , "SymbolNode {{ base: {:?}, opening_loc: {:?}, value_loc: {:?}, closing_loc: {:?}, unescaped: {:?} }}" , self . base , self . opening_loc , self . value_loc , self . closing_loc , self . unescaped)
    }
}
impl Default for TrueNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for UndefNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for UnlessNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for UntilNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for WhenNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for WhileNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for XStringNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for XStringNode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write ! (f , "XStringNode {{ base: {:?}, opening_loc: {:?}, content_loc: {:?}, closing_loc: {:?}, unescaped: {:?} }}" , self . base , self . opening_loc , self . content_loc , self . closing_loc , self . unescaped)
    }
}
impl Default for YieldNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ListNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for List {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Diagnostic {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Encoding {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for NewlineList {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LexModeUnknownTy2UnknownTy4 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LexModeUnknownTy2UnknownTy5 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LexModeUnknownTy2 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for LexModeUnknownTy2 {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write!(f, "LexModeUnknownTy2 {{ union }}")
    }
}
impl Default for LexMode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for LexMode {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write!(
            f,
            "LexMode {{ mode: {:?}, as: {:?}, prev: {:?} }}",
            self.mode, self.as_, self.prev
        )
    }
}
impl Default for ContextNode {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Comment {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for LexCallback {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Scope {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for ParserUnknownTy1 {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for ParserUnknownTy1 {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write!(
            f,
            "ParserUnknownTy1 {{ current: {:?}, stack: {:?} }}",
            self.current, self.stack
        )
    }
}
impl Default for Parser {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl ::std::fmt::Debug for Parser {
    fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
        write ! (f , "Parser {{ lex_state: {:?}, command_start: {:?}, enclosure_nesting: {:?}, lambda_enclosure_nesting: {:?}, brace_nesting: {:?}, lex_modes: {:?}, start: {:?}, end: {:?}, previous: {:?}, current: {:?}, next_start: {:?}, heredoc_end: {:?}, comment_list: {:?}, warning_list: {:?}, error_list: {:?}, current_scope: {:?}, current_context: {:?}, recovering: {:?}, encoding: {:?}, encoding_changed: {:?}, encoding_changed_callback: {:?}, encoding_decode_callback: {:?}, encoding_comment_start: {:?}, lex_callback: {:?}, pattern_matching_newlines: {:?}, in_keyword_arg: {:?}, filepath_string: {:?}, constant_pool: {:?}, newline_list: {:?} }}" , self . lex_state , self . command_start , self . enclosure_nesting , self . lambda_enclosure_nesting , self . brace_nesting , self . lex_modes , self . start , self . end , self . previous , self . current , self . next_start , self . heredoc_end , self . comment_list , self . warning_list , self . error_list , self . current_scope , self . current_context , self . recovering , self . encoding , self . encoding_changed , self . encoding_changed_callback , self . encoding_decode_callback , self . encoding_comment_start , self . lex_callback , self . pattern_matching_newlines , self . in_keyword_arg , self . filepath_string , self . constant_pool , self . newline_list)
    }
}
impl Default for StringList {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
impl Default for Buffer {
    fn default() -> Self {
        let mut s = ::std::mem::MaybeUninit::<Self>::uninit();
        unsafe {
            ::std::ptr::write_bytes(s.as_mut_ptr(), 0, 1);
            s.assume_init()
        }
    }
}
extern "C" {
    #[doc = "In case strncasecmp isn't present on the system, we provide our own."]
    pub fn yp_strncasecmp(
        string1: *const ::std::os::raw::c_char,
        string2: *const ::std::os::raw::c_char,
        length: usize,
    ) -> ::std::os::raw::c_int;
    #[doc = "Initialize a list of constant ids."]
    pub fn yp_constant_id_list_init(list: *mut ConstantIdList);
    #[doc = "Append a constant id to a list of constant ids. Returns false if any\n potential reallocations fail."]
    pub fn yp_constant_id_list_append(list: *mut ConstantIdList, id: ConstantId) -> bool;
    #[doc = "Checks if the current constant id list includes the given constant id."]
    pub fn yp_constant_id_list_includes(list: *mut ConstantIdList, id: ConstantId) -> bool;
    #[doc = "Get the memory size of a list of constant ids."]
    pub fn yp_constant_id_list_memsize(list: *mut ConstantIdList) -> usize;
    #[doc = "Free the memory associated with a list of constant ids."]
    pub fn yp_constant_id_list_free(list: *mut ConstantIdList);
    #[doc = "Initialize a new constant pool with a given capacity."]
    pub fn yp_constant_pool_init(pool: *mut ConstantPool, capacity: usize) -> bool;
    #[doc = "Insert a constant into a constant pool. Returns the id of the constant, or 0\n if any potential calls to resize fail."]
    pub fn yp_constant_pool_insert(
        pool: *mut ConstantPool,
        start: *const ::std::os::raw::c_char,
        length: usize,
    ) -> ConstantId;
    #[doc = "Free the memory associated with a constant pool."]
    pub fn yp_constant_pool_free(pool: *mut ConstantPool);
    #[doc = "Initialize a shared string that is based on initial input."]
    pub fn yp_string_shared_init(
        string: *mut String,
        start: *const ::std::os::raw::c_char,
        end: *const ::std::os::raw::c_char,
    );
    #[doc = "Initialize an owned string that is responsible for freeing allocated memory."]
    pub fn yp_string_owned_init(
        string: *mut String,
        source: *mut ::std::os::raw::c_char,
        length: usize,
    );
    #[doc = "Initialize a constant string that doesn't own its memory source."]
    pub fn yp_string_constant_init(
        string: *mut String,
        source: *const ::std::os::raw::c_char,
        length: usize,
    );
    #[doc = "Returns the memory size associated with the string."]
    pub fn yp_string_memsize(string: *const String) -> usize;
    #[doc = "Ensure the string is owned. If it is not, then reinitialize it as owned and\n copy over the previous source."]
    pub fn yp_string_ensure_owned(string: *mut String);
    #[doc = "Returns the length associated with the string."]
    pub fn yp_string_length(string: *const String) -> usize;
    #[doc = "Returns the start pointer associated with the string."]
    pub fn yp_string_source(string: *const String) -> *const ::std::os::raw::c_char;
    #[doc = "Free the associated memory of the given string."]
    pub fn yp_string_free(string: *mut String);
    #[doc = "Initializes a new list."]
    pub fn yp_list_init(list: *mut List);
    #[doc = "Returns true if the given list is empty."]
    pub fn yp_list_empty_p(list: *mut List) -> bool;
    #[doc = "Append a node to the given list."]
    pub fn yp_list_append(list: *mut List, node: *mut ListNode);
    #[doc = "Deallocate the internal state of the given list."]
    pub fn yp_list_free(list: *mut List);
    #[doc = "Append a diagnostic to the given list of diagnostics."]
    pub fn yp_diagnostic_list_append(
        list: *mut List,
        start: *const ::std::os::raw::c_char,
        end: *const ::std::os::raw::c_char,
        message: *const ::std::os::raw::c_char,
    ) -> bool;
    #[doc = "Deallocate the internal state of the given diagnostic list."]
    pub fn yp_diagnostic_list_free(list: *mut List);
    #[doc = "The function is shared between all of the encodings that use single bytes to\n represent characters. They don't have need of a dynamic function to determine\n their width."]
    pub fn yp_encoding_single_char_width(c: *const ::std::os::raw::c_char) -> usize;
    #[doc = "These functions are reused by some other encodings, so they are defined here\n so they can be shared."]
    pub fn yp_encoding_ascii_alpha_char(c: *const ::std::os::raw::c_char) -> usize;
    pub fn yp_encoding_ascii_alnum_char(c: *const ::std::os::raw::c_char) -> usize;
    pub fn yp_encoding_ascii_isupper_char(c: *const ::std::os::raw::c_char) -> bool;
    #[doc = "These functions are shared between the actual encoding and the fast path in\n the parser so they need to be internally visible."]
    pub fn yp_encoding_utf_8_alpha_char(c: *const ::std::os::raw::c_char) -> usize;
    pub fn yp_encoding_utf_8_alnum_char(c: *const ::std::os::raw::c_char) -> usize;
    #[doc = "Initialize a new newline list with the given capacity. Returns true if the\n allocation of the offsets succeeds, otherwise returns false."]
    pub fn yp_newline_list_init(
        list: *mut NewlineList,
        start: *const ::std::os::raw::c_char,
        capacity: usize,
    ) -> bool;
    #[doc = "Append a new offset to the newline list. Returns true if the reallocation of\n the offsets succeeds (if one was necessary), otherwise returns false."]
    pub fn yp_newline_list_append(
        list: *mut NewlineList,
        cursor: *const ::std::os::raw::c_char,
    ) -> bool;
    #[doc = "Returns the line and column of the given offset. If the offset is not in the\n list, the line and column of the closest offset less than the given offset\n are returned."]
    pub fn yp_newline_list_line_column(
        list: *mut NewlineList,
        cursor: *const ::std::os::raw::c_char,
    ) -> LineColumn;
    #[doc = "Free the internal memory allocated for the newline list."]
    pub fn yp_newline_list_free(list: *mut NewlineList);
    #[doc = "Initializes the state stack to an empty stack."]
    pub fn yp_state_stack_init(stack: *mut StateStack);
    #[doc = "Pushes a value onto the stack."]
    pub fn yp_state_stack_push(stack: *mut StateStack, value: bool);
    #[doc = "Pops a value off the stack."]
    pub fn yp_state_stack_pop(stack: *mut StateStack);
    #[doc = "Returns the value at the top of the stack."]
    pub fn yp_state_stack_p(stack: *mut StateStack) -> bool;
    #[doc = "Append a token to the given list."]
    pub fn yp_location_list_append(list: *mut LocationList, token: *const Token);
    #[doc = "Append a new node onto the end of the node list."]
    pub fn yp_node_list_append(list: *mut NodeList, node: *mut Node);
    #[doc = "Clear the node but preserves the location."]
    pub fn yp_node_clear(node: *mut Node);
    #[doc = "Deallocate a node and all of its children."]
    pub fn yp_node_destroy(parser: *mut Parser, node: *mut Node);
    #[doc = "Calculates the memory footprint of a given node."]
    pub fn yp_node_memsize(node: *mut Node, memsize: *mut Memsize);
    #[doc = "Parse a single directive from a pack or unpack format string.\n\n Parameters:\n  - [in] yp_pack_version version    the version of Ruby\n  - [in] yp_pack_variant variant    pack or unpack\n  - [in out] const char **format    the start of the next directive to parse\n      on calling, and advanced beyond the parsed directive on return, or as\n      much of it as was consumed until an error was encountered\n  - [in] const char *format_end     the end of the format string\n  - [out] yp_pack_type *type        the type of the directive\n  - [out] yp_pack_signed *signed_type\n                                    whether the value is signed\n  - [out] yp_pack_endian *endian    the endianness of the value\n  - [out] yp_pack_size *size        the size of the value\n  - [out] yp_pack_length_type *length_type\n                                    what kind of length is specified\n  - [out] size_t *length            the length of the directive\n  - [in out] yp_pack_encoding *encoding\n                                    takes the current encoding of the string\n      which would result from parsing the whole format string, and returns a\n      possibly changed directive - the encoding should be\n      YP_PACK_ENCODING_START when yp_pack_parse is called for the first\n      directive in a format string\n\n Return:\n  - YP_PACK_OK on success\n  - YP_PACK_ERROR_* on error\n\n Notes:\n   Consult Ruby documentation for the meaning of directives."]
    pub fn yp_pack_parse(
        variant_arg: PackVariant,
        format: *mut *const ::std::os::raw::c_char,
        format_end: *const ::std::os::raw::c_char,
        type_: *mut PackType,
        signed_type: *mut PackSigned,
        endian: *mut PackEndian,
        size: *mut PackSize,
        length_type: *mut PackLengthType,
        length: *mut u64,
        encoding: *mut PackEncoding,
    ) -> PackResult;
    #[doc = "YARP abstracts sizes away from the native system - this converts an abstract\n size to a native size."]
    pub fn yp_size_to_native(size: PackSize) -> usize;
    #[doc = "Allocate a new yp_string_list_t."]
    pub fn yp_string_list_alloc() -> *mut StringList;
    #[doc = "Initialize a yp_string_list_t with its default values."]
    pub fn yp_string_list_init(string_list: *mut StringList);
    #[doc = "Append a yp_string_t to the given string list."]
    pub fn yp_string_list_append(string_list: *mut StringList, string: *mut String);
    #[doc = "Free the memory associated with the string list."]
    pub fn yp_string_list_free(string_list: *mut StringList);
    #[doc = "Parse a regular expression and extract the names of all of the named capture\n groups."]
    pub fn yp_regexp_named_capture_group_names(
        source: *const ::std::os::raw::c_char,
        size: usize,
        named_captures: *mut StringList,
    ) -> bool;
    #[doc = "Returns the number of characters at the start of the string that are\n whitespace. Disallows searching past the given maximum number of characters."]
    pub fn yp_strspn_whitespace(string: *const ::std::os::raw::c_char, length: isize) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are\n whitespace while also tracking the location of each newline. Disallows\n searching past the given maximum number of characters."]
    pub fn yp_strspn_whitespace_newlines(
        string: *const ::std::os::raw::c_char,
        length: ::std::os::raw::c_long,
        newline_list: *mut NewlineList,
    ) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are inline\n whitespace. Disallows searching past the given maximum number of characters."]
    pub fn yp_strspn_inline_whitespace(
        string: *const ::std::os::raw::c_char,
        length: isize,
    ) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are decimal\n digits. Disallows searching past the given maximum number of characters."]
    pub fn yp_strspn_decimal_digit(string: *const ::std::os::raw::c_char, length: isize) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are\n hexadecimal digits. Disallows searching past the given maximum number of\n characters."]
    pub fn yp_strspn_hexadecimal_digit(
        string: *const ::std::os::raw::c_char,
        length: isize,
    ) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are octal\n digits or underscores.  Disallows searching past the given maximum number of\n characters."]
    pub fn yp_strspn_octal_number(string: *const ::std::os::raw::c_char, length: isize) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are decimal\n digits or underscores. Disallows searching past the given maximum number of\n characters."]
    pub fn yp_strspn_decimal_number(string: *const ::std::os::raw::c_char, length: isize) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are\n hexadecimal digits or underscores. Disallows searching past the given maximum\n number of characters."]
    pub fn yp_strspn_hexadecimal_number(
        string: *const ::std::os::raw::c_char,
        length: isize,
    ) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are regexp\n options. Disallows searching past the given maximum number of characters."]
    pub fn yp_strspn_regexp_option(string: *const ::std::os::raw::c_char, length: isize) -> usize;
    #[doc = "Returns the number of characters at the start of the string that are binary\n digits or underscores. Disallows searching past the given maximum number of\n characters."]
    pub fn yp_strspn_binary_number(string: *const ::std::os::raw::c_char, length: isize) -> usize;
    #[doc = "Returns true if the given character is a whitespace character."]
    pub fn yp_char_is_whitespace(c: ::std::os::raw::c_char) -> bool;
    #[doc = "Returns true if the given character is an inline whitespace character."]
    pub fn yp_char_is_inline_whitespace(c: ::std::os::raw::c_char) -> bool;
    #[doc = "Returns true if the given character is a binary digit."]
    pub fn yp_char_is_binary_digit(c: ::std::os::raw::c_char) -> bool;
    #[doc = "Returns true if the given character is an octal digit."]
    pub fn yp_char_is_octal_digit(c: ::std::os::raw::c_char) -> bool;
    #[doc = "Returns true if the given character is a decimal digit."]
    pub fn yp_char_is_decimal_digit(c: ::std::os::raw::c_char) -> bool;
    #[doc = "Returns true if the given character is a hexadecimal digit."]
    pub fn yp_char_is_hexadecimal_digit(c: ::std::os::raw::c_char) -> bool;
    #[doc = "Unescape the contents of the given token into the given string using the\n given unescape mode."]
    pub fn yp_unescape_manipulate_string(
        value: *const ::std::os::raw::c_char,
        length: usize,
        string: *mut String,
        unescape_type: UnescapeType,
        error_list: *mut List,
    );
    pub fn yp_unescape_calculate_difference(
        value: *const ::std::os::raw::c_char,
        end: *const ::std::os::raw::c_char,
        unescape_type: UnescapeType,
        expect_single_codepoint: bool,
        error_list: *mut List,
    ) -> usize;
    #[doc = "Initialize a yp_buffer_t with its default values."]
    pub fn yp_buffer_init(buffer: *mut Buffer) -> bool;
    #[doc = "Append the given amount of space as zeroes to the buffer."]
    pub fn yp_buffer_append_zeroes(buffer: *mut Buffer, length: usize);
    #[doc = "Append a string to the buffer."]
    pub fn yp_buffer_append_str(
        buffer: *mut Buffer,
        value: *const ::std::os::raw::c_char,
        length: usize,
    );
    #[doc = "Append a single byte to the buffer."]
    pub fn yp_buffer_append_u8(buffer: *mut Buffer, value: u8);
    #[doc = "Append a 32-bit unsigned integer to the buffer."]
    pub fn yp_buffer_append_u32(buffer: *mut Buffer, value: u32);
    #[doc = "Free the memory associated with the buffer."]
    pub fn yp_buffer_free(buffer: *mut Buffer);
    #[doc = "Here we have rolled our own version of strpbrk. The standard library strpbrk\n has undefined behavior when the source string is not null-terminated. We want\n to support strings that are not null-terminated because yp_parse does not\n have the contract that the string is null-terminated. (This is desirable\n because it means the extension can call yp_parse with the result of a call to\n mmap).\n\n The standard library strpbrk also does not support passing a maximum length\n to search. We want to support this for the reason mentioned above, but we\n also don't want it to stop on null bytes. Ruby actually allows null bytes\n within strings, comments, regular expressions, etc. So we need to be able to\n skip past them.\n\n Finally, we want to support encodings wherein the charset could contain\n characters that are trailing bytes of multi-byte characters. For example, in\n Shift-JIS, the backslash character can be a trailing byte. In that case we\n need to take a slower path and iterate one multi-byte character at a time."]
    pub fn yp_strpbrk(
        parser: *mut Parser,
        source: *const ::std::os::raw::c_char,
        charset: *const ::std::os::raw::c_char,
        length: isize,
    ) -> *const ::std::os::raw::c_char;
    pub fn yp_serialize_content(parser: *mut Parser, node: *mut Node, buffer: *mut Buffer);
    pub fn yp_print_node(parser: *mut Parser, node: *mut Node);
    #[doc = "Returns the YARP version and notably the serialization format"]
    pub fn yp_version() -> *const ::std::os::raw::c_char;
    #[doc = "Initialize a parser with the given start and end pointers."]
    pub fn yp_parser_init(
        parser: *mut Parser,
        source: *const ::std::os::raw::c_char,
        size: usize,
        filepath: *const ::std::os::raw::c_char,
    );
    #[doc = "Register a callback that will be called whenever YARP changes the encoding it\n is using to parse based on the magic comment."]
    pub fn yp_parser_register_encoding_changed_callback(
        parser: *mut Parser,
        callback: EncodingChangedCallback,
    );
    #[doc = "Register a callback that will be called when YARP encounters a magic comment\n with an encoding referenced that it doesn't understand. The callback should\n return NULL if it also doesn't understand the encoding or it should return a\n pointer to a yp_encoding_t struct that contains the functions necessary to\n parse identifiers."]
    pub fn yp_parser_register_encoding_decode_callback(
        parser: *mut Parser,
        callback: EncodingDecodeCallback,
    );
    #[doc = "Free any memory associated with the given parser."]
    pub fn yp_parser_free(parser: *mut Parser);
    #[doc = "Parse the Ruby source associated with the given parser and return the tree."]
    pub fn yp_parse(parser: *mut Parser) -> *mut Node;
    #[doc = "Pretty-prints the AST represented by the given node to the given buffer."]
    pub fn yp_prettyprint(parser: *mut Parser, node: *mut Node, buffer: *mut Buffer);
    #[doc = "Serialize the AST represented by the given node to the given buffer."]
    pub fn yp_serialize(parser: *mut Parser, node: *mut Node, buffer: *mut Buffer);
    #[doc = "Parse and serialize the AST represented by the given source to the given\n buffer."]
    pub fn yp_parse_serialize(
        source: *const ::std::os::raw::c_char,
        size: usize,
        buffer: *mut Buffer,
    );
    #[doc = "Returns a string representation of the given token type."]
    pub fn yp_token_type_to_str(token_type: TokenType) -> *const ::std::os::raw::c_char;
}
