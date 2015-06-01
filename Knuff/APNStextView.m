//
//  APNStextView.m
//  Knuff
//
//  Created by Simon Blommegard on 17/05/15.
//  Copyright (c) 2015 Bowtie. All rights reserved.
//

#import "APNStextView.h"
#import <PEGKit/PEGKit.h>

@interface APNStextView () <NSTextStorageDelegate>
@end

@implementation APNStextView

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    self.textStorage.delegate = self;
  }
  
  return self;
}

#pragma mark - NSTextStorageDelegate

- (void)textStorageDidProcessEditing:(NSNotification *)notification {
  PKTokenizer *t = [[PKTokenizer alloc] initWithString:self.textStorage.string];
  
  NSTextStorage *storage = self.textStorage;
  
  [storage beginEditing];

  // Clear
  [storage enumerateAttributesInRange:NSMakeRange(0, storage.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
    
    NSFont *font = attrs[NSFontAttributeName];
    
    // [storage setAttributes: range:NSMakeRange(0, storage.length)];
    // :(
    
    if (font) {
      if (![font.fontName isEqualToString:@"AppleColorEmoji"]) {
        [storage setAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:13]} range:range];
      } else {
        [storage removeAttribute:NSForegroundColorAttributeName range:range];
      }
    }
    
    NSColor *color = attrs[NSBackgroundColorAttributeName];
    
    if (color) {
      [storage removeAttribute:NSBackgroundColorAttributeName range:range];
    }
    
  }];
  
  // JSON Error
  NSData *data = [storage.string dataUsingEncoding:NSUTF8StringEncoding];
  
  NSError *error;
  [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  
  if (error) {
    NSString *errorDescription = error.userInfo[@"NSDebugDescription"];
    
    // try to find error
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"character (\\d+)\\." options:0 error:&error];
    NSTextCheckingResult *result =[expression firstMatchInString:errorDescription options:0 range:NSMakeRange(0, errorDescription.length)];
    
    if (result.numberOfRanges > 1) {
      NSRange range = [result rangeAtIndex:1];
      
      NSString *characterRangeString = [errorDescription substringWithRange:range];
      
      [self.textStorage addAttribute:NSBackgroundColorAttributeName
                               value:[NSColor redColor]
                               range:NSMakeRange(characterRangeString.integerValue, 1)];
    }
  }
  
  
  // Syntax
  [t enumerateTokensUsingBlock:^(PKToken *tok, BOOL *stop) {
    if (tok.tokenType == PKTokenTypeNumber) {
      [self.textStorage addAttribute:NSForegroundColorAttributeName
                               value:[NSColor blueColor]
                               range:NSMakeRange(tok.offset, tok.stringValue.length)];
    }
    else if (tok.tokenType == PKTokenTypeWord) {
      if ([@[@"true", @"false", @"null"] containsObject:tok.stringValue]) {
        [self.textStorage addAttribute:NSForegroundColorAttributeName
                                 value:[NSColor blueColor]
                                 range:NSMakeRange(tok.offset, tok.stringValue.length)];
      }
    }
    else if (tok.tokenType == PKTokenTypeQuotedString) {
      [self.textStorage addAttribute:NSForegroundColorAttributeName
                               value:[NSColor redColor]
                               range:NSMakeRange(tok.offset, tok.stringValue.length)];
    }
  }];

  [storage endEditing];
}

- (void)insertText:(id)aString {
  if ([aString isKindOfClass:NSString.class]) {
    if ([aString isEqualToString:@"}"]) {
      unichar characterToCheck;
      NSInteger location = [self selectedRange].location;
      NSString *completeString = [self string];
      NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
      NSRange currentLineRange = [completeString lineRangeForRange:NSMakeRange([self selectedRange].location, 0)];
      NSInteger lineLocation = location;
      NSInteger lineStart = currentLineRange.location;
      while (--lineLocation >= lineStart) { // If there are any characters before } on the line skip indenting
        if ([whitespaceCharacterSet characterIsMember:[completeString characterAtIndex:lineLocation]]) {
          continue;
        }
        [super insertText:aString];
        return;
      }
      
      BOOL hasInsertedBrace = NO;
      NSUInteger skipMatchingBrace = 0;
      while (location--) {
        characterToCheck = [completeString characterAtIndex:location];
        if (characterToCheck == '{') {
          if (skipMatchingBrace == 0) { // If we have found the opening brace check first how much space is in front of that line so the same amount can be inserted in front of the new line
            NSString *openingBraceLineWhitespaceString;
            NSScanner *openingLineScanner = [[NSScanner alloc] initWithString:[completeString substringWithRange:[completeString lineRangeForRange:NSMakeRange(location, 0)]]];
            [openingLineScanner setCharactersToBeSkipped:nil];
            BOOL foundOpeningBraceWhitespace = [openingLineScanner scanCharactersFromSet:whitespaceCharacterSet intoString:&openingBraceLineWhitespaceString];
            
            if (foundOpeningBraceWhitespace == YES) {
              NSMutableString *newLineString = [NSMutableString stringWithString:openingBraceLineWhitespaceString];
              [newLineString appendString:@"}"];
              [newLineString appendString:[completeString substringWithRange:NSMakeRange([self selectedRange].location, NSMaxRange(currentLineRange) - [self selectedRange].location)]];
              if ([self shouldChangeTextInRange:currentLineRange replacementString:newLineString]) {
                [self replaceCharactersInRange:currentLineRange withString:newLineString];
                [self didChangeText];
              }
              hasInsertedBrace = YES;
              [self setSelectedRange:NSMakeRange(currentLineRange.location + [openingBraceLineWhitespaceString length] + 1, 0)]; // +1 because we have inserted a character
            } else {
              NSString *restOfLineString = [completeString substringWithRange:NSMakeRange([self selectedRange].location, NSMaxRange(currentLineRange) - [self selectedRange].location)];
              if ([restOfLineString length] != 0) { // To fix a bug where text after the } can be deleted
                NSMutableString *replaceString = [NSMutableString stringWithString:@"}"];
                [replaceString appendString:restOfLineString];
                hasInsertedBrace = YES;
                NSInteger lengthOfWhiteSpace = 0;
                if (foundOpeningBraceWhitespace == YES) {
                  lengthOfWhiteSpace = [openingBraceLineWhitespaceString length];
                }
                if ([self shouldChangeTextInRange:currentLineRange replacementString:replaceString]) {
                  [self replaceCharactersInRange:[completeString lineRangeForRange:currentLineRange] withString:replaceString];
                  [self didChangeText];
                }
                [self setSelectedRange:NSMakeRange(currentLineRange.location + lengthOfWhiteSpace + 1, 0)]; // +1 because we have inserted a character
              } else {
                [self replaceCharactersInRange:[completeString lineRangeForRange:currentLineRange] withString:@""]; // Remove whitespace before }
              }
              
            }
            break;
          } else {
            skipMatchingBrace--;
          }
        } else if (characterToCheck == '}') {
          skipMatchingBrace++;
        }
      }
      if (hasInsertedBrace == NO) {
        [super insertText:aString];
      }
    } else if ([aString isEqualToString:@"{"]) {
      [super insertText:aString];
      NSRange selectedRange = [self selectedRange];
      if ([self shouldChangeTextInRange:selectedRange replacementString:@"}"]) {
        [self replaceCharactersInRange:selectedRange withString:@"}"];
        [self didChangeText];
        [self setSelectedRange:NSMakeRange(selectedRange.location - 0, 0)];
      }
    } else {
      [super insertText:aString];
    }
  } else {
    [super insertText:aString];
  }
}

- (void)insertNewline:(id)sender
{
  [super insertNewline:sender];
  
  // If we should indent automatically, check the previous line and scan all the whitespace at the beginning of the line into a string and insert that string into the new line
  NSString *lastLineString = [[self string] substringWithRange:[[self string] lineRangeForRange:NSMakeRange([self selectedRange].location - 1, 0)]];
    NSString *previousLineWhitespaceString;
    NSScanner *previousLineScanner = [[NSScanner alloc] initWithString:[[self string] substringWithRange:[[self string] lineRangeForRange:NSMakeRange([self selectedRange].location - 1, 0)]]];
    [previousLineScanner setCharactersToBeSkipped:nil];
    if ([previousLineScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&previousLineWhitespaceString]) {
      [self insertText:previousLineWhitespaceString];
    }
  
      NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
      NSInteger idx = [lastLineString length];
      while (idx--) {
        if ([characterSet characterIsMember:[lastLineString characterAtIndex:idx]]) {
          continue;
        }
        if ([lastLineString characterAtIndex:idx] == '{') {
          [self insertTab:sender];
        }
        break;
      }
}

@end
