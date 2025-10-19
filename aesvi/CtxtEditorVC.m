//
//  ViewController.m
//  aesvi
//
//  Created by Fang Lu on 10/19/25.
//

#import "CtxtEditorVC.h"
#import "EncryptedText.h"

@interface CtxtEditorVC ()

@property (unsafe_unretained) IBOutlet NSTextView *editor;
@property (strong) EncryptedText *doc;

@end

@implementation CtxtEditorVC

@synthesize doc = _doc;

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewWillAppear {
	[super viewWillAppear];
	
	// Apply preferences
	NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
	NSString *font_face = [prefs stringForKey:@"font_face"];
	float font_size = [prefs floatForKey:@"font_size"];
	if (!font_face) {
		font_face = @"Menlo";
	}
	if (!font_size) {
		font_size = 14;
	}
	NSFontManager *fontmgr = NSFontManager.sharedFontManager;
	[fontmgr setAction:@selector(setGlobalFont:)];
	NSFont *font = [NSFont fontWithName:font_face size:font_size];
	if (font) {
		NSLog(@"Font: %@ %f", font.fontName, font.pointSize);
		[fontmgr setSelectedFont:font isMultiple:NO];
		_editor.font = font;
	} else {
		NSLog(@"Saved font not found: %@ %f", font_face, font_size);
		[prefs removeObjectForKey:@"font_face"];
		[prefs removeObjectForKey:@"font_size"];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateDoc:self.view.window.windowController.document];
	});
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
	NSLog(@"VC: Load");
	[self updateDoc:representedObject];
}

- (void)setGlobalFont:(id)sender {
	NSFont *font = NSFontManager.sharedFontManager.selectedFont;
	NSUserDefaults *prefs = NSUserDefaults.standardUserDefaults;
	[prefs setValue:font.fontName forKey:@"font_face"];
	[prefs setFloat:font.pointSize forKey:@"font_size"];
	NSLog(@"Set font: %@ %f", font.fontName, font.pointSize);
	
	_editor.font = font;
}

- (BOOL) rekey {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = _doc.password ? @"Set new password" : @"Enter password";

	NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
	[alert setAccessoryView:input];
	[alert addButtonWithTitle:@"OK"];
	if (_doc.password) {
		[alert addButtonWithTitle:@"Cancel"];
	}
	NSModalResponse button = [alert runModal];
	if (button == NSAlertFirstButtonReturn) {
		[input validateEditing];
		NSString *pw = [input stringValue];
		if (pw.length > 0) {
			_doc.password = pw;
			return YES;
		}
	}
	return NO;
}

- (void) rekey: (id)sender {
	if ([self rekey]) {
		[_doc saveDocument: self];
	}
}

- (void)dieBy: (NSString *)reason {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = reason;
	[alert runModal];
	[self.view.window close];
}

- (void)updateDoc:(id)representedObject {
	_doc = representedObject;
	
	if (!_doc.password && ![self rekey]) {
		[self dieBy:@"No key"];
		return;
	}
	
	NSString *content = _doc.content;
	if (content) {
		[_editor setString:_doc.content];
	} else {
		[self dieBy:@"Error"];
	}
}

- (void)textDidChange:(NSNotification *)notification {
	_doc.content = _editor.textStorage.string;
}

@end
