//
//  EncryptedText.m
//  aesvi
//
//  Created by Fang Lu on 10/19/25.
//

#import "EncryptedText.h"
#include "tinycrypt/ctr_mode.h"
#include "tinycrypt/sha256.h"

@interface EncryptedText ()

@property (strong, nonatomic) NSData *ciphertext;
@property (strong, nonatomic) NSData *plaintext;

@end

typedef struct etxt_file {
	uint8_t iv[16];
	uint8_t data[];
} etxt_file_t;

@implementation EncryptedText

@synthesize password = _password;
@synthesize ciphertext = _ciphertext;
@synthesize plaintext = _plaintext;

- (NSString *) content {
	if (!_password) {
		return nil;
	}
	if (!_plaintext) {
		if (!_ciphertext) {
			return @"";
		}
		[self decrypt];
	}
	
	NSString *text = [[NSString alloc] initWithData:_plaintext encoding:NSUTF8StringEncoding];
	if (!text) {
		NSLog(@"Decryption failed");
		_password = nil;
		_plaintext = nil;
	}
	return text;
}

- (void) setContent:(NSString *)content {
	NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
	if (![data isEqualToData:_plaintext]) {
		_plaintext = data;
		_ciphertext = nil;
	}
}

- (struct tc_aes_key_sched_struct) keysetup: (const uint8_t *) iv {
	struct tc_sha256_state_struct hash;
	const char *pw = _password.UTF8String;
	uint8_t md[32];
	
	tc_sha256_init(&hash);
	tc_sha256_update(&hash, iv, 16);
	tc_sha256_update(&hash, (const uint8_t *)pw, strlen(pw));
	tc_sha256_final(md, &hash);
	
	struct tc_aes_key_sched_struct key;
	tc_aes128_set_encrypt_key(&key, md);
	return key;
}

int urandom(uint8_t *dest, unsigned int size) {
	if (!dest || size <= 0)
		return 0;
	
	int fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
	if (fd == -1) {
		fd = open("/dev/random", O_RDONLY | O_CLOEXEC);
		if (fd == -1) {
			return 0;
		}
	}
	
	char *ptr = (char *)dest;
	size_t left = (size_t) size;
	while (left > 0) {
		ssize_t bytes_read = read(fd, ptr, left);
		if (bytes_read <= 0) {
			close(fd);
			return 0;
		}
		left -= bytes_read;
		ptr += bytes_read;
	}
	
	close(fd);
	return 1;
}

- (void) decrypt {
	const etxt_file_t *file = (etxt_file_t *) _ciphertext.bytes;
	uint8_t iv[16];
	memcpy(iv, file->iv, sizeof(iv));
	struct tc_aes_key_sched_struct key = [self keysetup:iv];
	int len = (int)_ciphertext.length - offsetof(etxt_file_t, data);
	NSMutableData *buf = [[NSMutableData alloc] initWithLength:len];
	tc_ctr_mode(buf.mutableBytes, len, file->data, len, iv, &key);
	_plaintext = buf;
	_ciphertext = nil;
}

- (void) encrypt {
	uint8_t iv[16];
	urandom(iv, sizeof(iv));
	struct tc_aes_key_sched_struct key = [self keysetup:iv];
	
	int len = (int) _plaintext.length, clen = len + offsetof(etxt_file_t, data);
	NSMutableData *buf = [[NSMutableData alloc] initWithLength:clen];
	etxt_file_t *file = (etxt_file_t *) buf.mutableBytes;
	memcpy(file->iv, iv, sizeof(iv));
	tc_ctr_mode(file->data, len, _plaintext.bytes, len, iv, &key);
	_ciphertext = buf;
}

- (instancetype)init {
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		self.hasUndoManager = YES;
    }
    return self;
}

+ (BOOL)autosavesInPlace {
	return NO;
}

- (void)makeWindowControllers {
	// Override to return the Storyboard file name of the document.
	[self addWindowController:[[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"Document Window Controller"]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return nil.
	// Alternatively, you could remove this method and override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	if (!_password) {
		NSLog(@"Save: no key");
		*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil];
		return nil;
	}
		
	if (!_ciphertext) {
		if (!_plaintext) {
			NSLog(@"Save: empty");
			return [NSData data];
		}
		[self encrypt];
	}
	if (!_ciphertext) {
		NSLog(@"Save: failed");
		*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil];
	}
	NSLog(@"Saved");
	return _ciphertext;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	_ciphertext = data.length > 16 ? data : nil;
	_plaintext = nil;
	return YES;
}


@end
