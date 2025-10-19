//
//  Document.h
//  aesvi
//
//  Created by Fang Lu on 10/19/25.
//

#import <Cocoa/Cocoa.h>

@interface EncryptedText : NSDocument

@property (nonatomic) NSString *password;
@property (nonatomic) NSString *content;

@end
