//
//  ViewController.h
//  aesvi
//
//  Created by Fang Lu on 10/19/25.
//

#import <Cocoa/Cocoa.h>

@interface CtxtEditorVC : NSViewController <NSTextViewDelegate>

- (void)rekey:(id)sender;
- (void)setGlobalFont:(id)sender;

@end

