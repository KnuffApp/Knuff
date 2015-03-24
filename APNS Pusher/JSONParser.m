#import "JSONParser.h"
#import <PEGKit/PEGKit.h>


@interface JSONParser ()

@property (nonatomic, retain) NSMutableDictionary *start_memo;
@property (nonatomic, retain) NSMutableDictionary *object_memo;
@property (nonatomic, retain) NSMutableDictionary *objectContent_memo;
@property (nonatomic, retain) NSMutableDictionary *actualObject_memo;
@property (nonatomic, retain) NSMutableDictionary *property_memo;
@property (nonatomic, retain) NSMutableDictionary *commaProperty_memo;
@property (nonatomic, retain) NSMutableDictionary *propertyName_memo;
@property (nonatomic, retain) NSMutableDictionary *array_memo;
@property (nonatomic, retain) NSMutableDictionary *arrayContent_memo;
@property (nonatomic, retain) NSMutableDictionary *actualArray_memo;
@property (nonatomic, retain) NSMutableDictionary *commaValue_memo;
@property (nonatomic, retain) NSMutableDictionary *value_memo;
@property (nonatomic, retain) NSMutableDictionary *string_memo;
@property (nonatomic, retain) NSMutableDictionary *number_memo;
@property (nonatomic, retain) NSMutableDictionary *nullLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *true_memo;
@property (nonatomic, retain) NSMutableDictionary *false_memo;
@property (nonatomic, retain) NSMutableDictionary *openCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *closeCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *openBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *closeBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *colon_memo;
@end

@implementation JSONParser { }

- (instancetype)initWithDelegate:(id)d {
    self = [super initWithDelegate:d];
    if (self) {
        
        self.startRuleName = @"start";
        self.tokenKindTab[@"false"] = @(JSONPARSER_TOKEN_KIND_FALSE);
        self.tokenKindTab[@"}"] = @(JSONPARSER_TOKEN_KIND_CLOSECURLY);
        self.tokenKindTab[@"["] = @(JSONPARSER_TOKEN_KIND_OPENBRACKET);
        self.tokenKindTab[@"null"] = @(JSONPARSER_TOKEN_KIND_NULLLITERAL);
        self.tokenKindTab[@","] = @(JSONPARSER_TOKEN_KIND_COMMA);
        self.tokenKindTab[@"true"] = @(JSONPARSER_TOKEN_KIND_TRUE);
        self.tokenKindTab[@"]"] = @(JSONPARSER_TOKEN_KIND_CLOSEBRACKET);
        self.tokenKindTab[@"{"] = @(JSONPARSER_TOKEN_KIND_OPENCURLY);
        self.tokenKindTab[@":"] = @(JSONPARSER_TOKEN_KIND_COLON);

        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_FALSE] = @"false";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_CLOSECURLY] = @"}";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_OPENBRACKET] = @"[";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_NULLLITERAL] = @"null";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_COMMA] = @",";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_TRUE] = @"true";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_CLOSEBRACKET] = @"]";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_OPENCURLY] = @"{";
        self.tokenKindNameTab[JSONPARSER_TOKEN_KIND_COLON] = @":";

        self.start_memo = [NSMutableDictionary dictionary];
        self.object_memo = [NSMutableDictionary dictionary];
        self.objectContent_memo = [NSMutableDictionary dictionary];
        self.actualObject_memo = [NSMutableDictionary dictionary];
        self.property_memo = [NSMutableDictionary dictionary];
        self.commaProperty_memo = [NSMutableDictionary dictionary];
        self.propertyName_memo = [NSMutableDictionary dictionary];
        self.array_memo = [NSMutableDictionary dictionary];
        self.arrayContent_memo = [NSMutableDictionary dictionary];
        self.actualArray_memo = [NSMutableDictionary dictionary];
        self.commaValue_memo = [NSMutableDictionary dictionary];
        self.value_memo = [NSMutableDictionary dictionary];
        self.string_memo = [NSMutableDictionary dictionary];
        self.number_memo = [NSMutableDictionary dictionary];
        self.nullLiteral_memo = [NSMutableDictionary dictionary];
        self.true_memo = [NSMutableDictionary dictionary];
        self.false_memo = [NSMutableDictionary dictionary];
        self.openCurly_memo = [NSMutableDictionary dictionary];
        self.closeCurly_memo = [NSMutableDictionary dictionary];
        self.openBracket_memo = [NSMutableDictionary dictionary];
        self.closeBracket_memo = [NSMutableDictionary dictionary];
        self.comma_memo = [NSMutableDictionary dictionary];
        self.colon_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)clearMemo {
    [_start_memo removeAllObjects];
    [_object_memo removeAllObjects];
    [_objectContent_memo removeAllObjects];
    [_actualObject_memo removeAllObjects];
    [_property_memo removeAllObjects];
    [_commaProperty_memo removeAllObjects];
    [_propertyName_memo removeAllObjects];
    [_array_memo removeAllObjects];
    [_arrayContent_memo removeAllObjects];
    [_actualArray_memo removeAllObjects];
    [_commaValue_memo removeAllObjects];
    [_value_memo removeAllObjects];
    [_string_memo removeAllObjects];
    [_number_memo removeAllObjects];
    [_nullLiteral_memo removeAllObjects];
    [_true_memo removeAllObjects];
    [_false_memo removeAllObjects];
    [_openCurly_memo removeAllObjects];
    [_closeCurly_memo removeAllObjects];
    [_openBracket_memo removeAllObjects];
    [_closeBracket_memo removeAllObjects];
    [_comma_memo removeAllObjects];
    [_colon_memo removeAllObjects];
}

- (void)start {

    [self start_]; 
    [self matchEOF:YES]; 

}

- (void)__start {
    
    [self execute:^{
    
	PKTokenizer *t = self.tokenizer;
	
    // whitespace
    self.silentlyConsumesWhitespace = YES;
    t.whitespaceState.reportsWhitespaceTokens = YES;
    self.assembly.preservesWhitespaceTokens = YES;

    }];
    if ([self predicts:JSONPARSER_TOKEN_KIND_OPENBRACKET, 0]) {
        [self array_]; 
    } else if ([self predicts:JSONPARSER_TOKEN_KIND_OPENCURLY, 0]) {
        [self object_]; 
    }

    [self fireDelegateSelector:@selector(parser:didMatchStart:)];
}

- (void)start_ {
    [self parseRule:@selector(__start) withMemo:_start_memo];
}

- (void)__object {
    
    [self openCurly_]; 
    [self objectContent_]; 
    [self closeCurly_]; 

    [self fireDelegateSelector:@selector(parser:didMatchObject:)];
}

- (void)object_ {
    [self parseRule:@selector(__object) withMemo:_object_memo];
}

- (void)__objectContent {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualObject_]; 
    }

    [self fireDelegateSelector:@selector(parser:didMatchObjectContent:)];
}

- (void)objectContent_ {
    [self parseRule:@selector(__objectContent) withMemo:_objectContent_memo];
}

- (void)__actualObject {
    
    [self property_]; 
    while ([self speculate:^{ [self commaProperty_]; }]) {
        [self commaProperty_]; 
    }

    [self fireDelegateSelector:@selector(parser:didMatchActualObject:)];
}

- (void)actualObject_ {
    [self parseRule:@selector(__actualObject) withMemo:_actualObject_memo];
}

- (void)__property {
    
    [self propertyName_]; 
    [self colon_]; 
    [self value_]; 

    [self fireDelegateSelector:@selector(parser:didMatchProperty:)];
}

- (void)property_ {
    [self parseRule:@selector(__property) withMemo:_property_memo];
}

- (void)__commaProperty {
    
    [self comma_]; 
    [self property_]; 

    [self fireDelegateSelector:@selector(parser:didMatchCommaProperty:)];
}

- (void)commaProperty_ {
    [self parseRule:@selector(__commaProperty) withMemo:_commaProperty_memo];
}

- (void)__propertyName {
    
    [self matchQuotedString:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchPropertyName:)];
}

- (void)propertyName_ {
    [self parseRule:@selector(__propertyName) withMemo:_propertyName_memo];
}

- (void)__array {
    
    [self openBracket_]; 
    [self arrayContent_]; 
    [self closeBracket_]; 

    [self fireDelegateSelector:@selector(parser:didMatchArray:)];
}

- (void)array_ {
    [self parseRule:@selector(__array) withMemo:_array_memo];
}

- (void)__arrayContent {
    
    if ([self predicts:JSONPARSER_TOKEN_KIND_FALSE, JSONPARSER_TOKEN_KIND_NULLLITERAL, JSONPARSER_TOKEN_KIND_OPENBRACKET, JSONPARSER_TOKEN_KIND_OPENCURLY, JSONPARSER_TOKEN_KIND_TRUE, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualArray_]; 
    }

    [self fireDelegateSelector:@selector(parser:didMatchArrayContent:)];
}

- (void)arrayContent_ {
    [self parseRule:@selector(__arrayContent) withMemo:_arrayContent_memo];
}

- (void)__actualArray {
    
    [self value_]; 
    while ([self speculate:^{ [self commaValue_]; }]) {
        [self commaValue_]; 
    }

    [self fireDelegateSelector:@selector(parser:didMatchActualArray:)];
}

- (void)actualArray_ {
    [self parseRule:@selector(__actualArray) withMemo:_actualArray_memo];
}

- (void)__commaValue {
    
    [self comma_]; 
    [self value_]; 

    [self fireDelegateSelector:@selector(parser:didMatchCommaValue:)];
}

- (void)commaValue_ {
    [self parseRule:@selector(__commaValue) withMemo:_commaValue_memo];
}

- (void)__value {
    
    if ([self predicts:JSONPARSER_TOKEN_KIND_NULLLITERAL, 0]) {
        [self nullLiteral_]; 
    } else if ([self predicts:JSONPARSER_TOKEN_KIND_TRUE, 0]) {
        [self true_]; 
    } else if ([self predicts:JSONPARSER_TOKEN_KIND_FALSE, 0]) {
        [self false_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self number_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self string_]; 
    } else if ([self predicts:JSONPARSER_TOKEN_KIND_OPENBRACKET, 0]) {
        [self array_]; 
    } else if ([self predicts:JSONPARSER_TOKEN_KIND_OPENCURLY, 0]) {
        [self object_]; 
    } else {
        [self raise:@"No viable alternative found in rule 'value'."];
    }

    [self fireDelegateSelector:@selector(parser:didMatchValue:)];
}

- (void)value_ {
    [self parseRule:@selector(__value) withMemo:_value_memo];
}

- (void)__string {
    
    [self matchQuotedString:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchString:)];
}

- (void)string_ {
    [self parseRule:@selector(__string) withMemo:_string_memo];
}

- (void)__number {
    
    [self matchNumber:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchNumber:)];
}

- (void)number_ {
    [self parseRule:@selector(__number) withMemo:_number_memo];
}

- (void)__nullLiteral {
    
    [self match:JSONPARSER_TOKEN_KIND_NULLLITERAL discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchNullLiteral:)];
}

- (void)nullLiteral_ {
    [self parseRule:@selector(__nullLiteral) withMemo:_nullLiteral_memo];
}

- (void)__true {
    
    [self match:JSONPARSER_TOKEN_KIND_TRUE discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchTrue:)];
}

- (void)true_ {
    [self parseRule:@selector(__true) withMemo:_true_memo];
}

- (void)__false {
    
    [self match:JSONPARSER_TOKEN_KIND_FALSE discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchFalse:)];
}

- (void)false_ {
    [self parseRule:@selector(__false) withMemo:_false_memo];
}

- (void)__openCurly {
    
    [self match:JSONPARSER_TOKEN_KIND_OPENCURLY discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchOpenCurly:)];
}

- (void)openCurly_ {
    [self parseRule:@selector(__openCurly) withMemo:_openCurly_memo];
}

- (void)__closeCurly {
    
    [self match:JSONPARSER_TOKEN_KIND_CLOSECURLY discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchCloseCurly:)];
}

- (void)closeCurly_ {
    [self parseRule:@selector(__closeCurly) withMemo:_closeCurly_memo];
}

- (void)__openBracket {
    
    [self match:JSONPARSER_TOKEN_KIND_OPENBRACKET discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchOpenBracket:)];
}

- (void)openBracket_ {
    [self parseRule:@selector(__openBracket) withMemo:_openBracket_memo];
}

- (void)__closeBracket {
    
    [self match:JSONPARSER_TOKEN_KIND_CLOSEBRACKET discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchCloseBracket:)];
}

- (void)closeBracket_ {
    [self parseRule:@selector(__closeBracket) withMemo:_closeBracket_memo];
}

- (void)__comma {
    
    [self match:JSONPARSER_TOKEN_KIND_COMMA discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchComma:)];
}

- (void)comma_ {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__colon {
    
    [self match:JSONPARSER_TOKEN_KIND_COLON discard:NO]; 

    [self fireDelegateSelector:@selector(parser:didMatchColon:)];
}

- (void)colon_ {
    [self parseRule:@selector(__colon) withMemo:_colon_memo];
}

@end