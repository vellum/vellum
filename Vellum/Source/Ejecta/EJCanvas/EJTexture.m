#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "EJTexture.h"
#import "EJConvertWebGL.h"

#import "EJSharedTextureCache.h"


@implementation EJTexture

@synthesize contentScale;
@synthesize format;
@synthesize width, height;

- (id)initEmptyForWebGL {
	// For WebGL textures; this will not create a textureStorage
	
	if( self = [super init] ) {
		contentScale = 1;
		owningContext = kEJTextureOwningContextWebGL;
		
		params[kEJTextureParamMinFilter] = GL_LINEAR;
		params[kEJTextureParamMagFilter] = GL_LINEAR;
		params[kEJTextureParamWrapS] = GL_REPEAT;
		params[kEJTextureParamWrapT] = GL_REPEAT;
	}
	return self;
}

- (id)initWithPath:(NSString *)path {
	// For loading on the main thread (blocking)
	
	if( self = [super init] ) {
		contentScale = 1;
		fullPath = [path retain];
		owningContext = kEJTextureOwningContextCanvas2D;
		
		NSMutableData *pixels = [self loadPixelsFromPath:path];
		[self createWithPixels:pixels format:GL_RGBA];
	}

	return self;
}

+ (id)cachedTextureWithPath:(NSString *)path loadOnQueue:(NSOperationQueue *)queue callback:(NSOperation *)callback {
	// For loading on a background thread (non-blocking), but tries the cache first
	
	EJTexture *texture = [EJSharedTextureCache instance].textures[path];
	if( texture ) {
		// We already have a texture, but it may hasn't finished loading yet. If
		// the texture's loadCallback is still present, add it as an dependency
		// for the current callback.
		
		if( texture->loadCallback ) {
			[callback addDependency:texture->loadCallback];
		}
		[NSOperationQueue.mainQueue addOperation:callback];
	}
	else {
		// Create a new texture and add it to the cache
		texture = [[EJTexture alloc] initWithPath:path loadOnQueue:queue callback:callback];
		
		[EJSharedTextureCache instance].textures[path] = texture;
		[texture autorelease];
		texture->cached = true;
	}
	return texture;
}

- (id)initWithPath:(NSString *)path loadOnQueue:(NSOperationQueue *)queue callback:(NSOperation *)callback {
	// For loading on a background thread (non-blocking)
	if( self = [super init] ) {
		contentScale = 1;
		fullPath = [path retain];
		owningContext = kEJTextureOwningContextCanvas2D;
		
		loadCallback = [[NSBlockOperation alloc] init];
		
		// Load the image file in a background thread
		[queue addOperationWithBlock:^{
			NSMutableData *pixels = [self loadPixelsFromPath:path];
			
			// Upload the pixel data in the main thread, otherwise the GLContext gets confused.	
			// We could use a sharegroup here, but it turned out quite buggy and has little
			// benefits - the main bottleneck is loading the image file.
			[loadCallback addExecutionBlock:^{
				[self createWithPixels:pixels format:GL_RGBA];
				[loadCallback release];
				loadCallback = nil;
			}];
			[callback addDependency:loadCallback];
			
			[NSOperationQueue.mainQueue addOperation:loadCallback];
			[NSOperationQueue.mainQueue addOperation:callback];
		}];
	}
	return self;
}

- (id)initWithWidth:(int)widthp height:(int)heightp {
	// Create an empty RGBA texture
	return [self initWithWidth:widthp height:heightp format:GL_RGBA];
}

- (id)initWithWidth:(int)widthp height:(int)heightp format:(GLenum)formatp {
	// Create an empty texture
	
	if( self = [super init] ) {
		contentScale = 1;
		owningContext = kEJTextureOwningContextCanvas2D;
		
		width = widthp;
		height = heightp;
		[self createWithPixels:NULL format:formatp];
	}
	return self;
}

- (id)initWithWidth:(int)widthp height:(int)heightp pixels:(NSData *)pixels {
	// Creates a texture with the given pixels
	
	if( self = [super init] ) {
		contentScale = 1;
		owningContext = kEJTextureOwningContextCanvas2D;
		
		width = widthp;
		height = heightp;
		[self createWithPixels:pixels format:GL_RGBA];
	}
	return self;
}

- (id)initAsRenderTargetWithWidth:(int)widthp height:(int)heightp fbo:(GLuint)fbop contentScale:(float)contentScalep {
	if( self = [self initWithWidth:widthp*contentScalep height:heightp*contentScalep] ) {
		fbo = fbop;
		contentScale = contentScalep;
	}
	return self;
}

- (void)dealloc {
	if( cached ) {
		[[EJSharedTextureCache instance].textures removeObjectForKey:fullPath];
	}
	[loadCallback release];
	
	[fullPath release];
	[textureStorage release];
	[super dealloc];
}

- (void)ensureMutableKeepPixels:(BOOL)keepPixels forTarget:(GLenum)target {

	// If we have a TextureStorage but it's not mutable (i.e. created by Canvas2D) and
	// we're not the only owner of it, we have to create a new TextureStorage
	if( textureStorage && textureStorage.immutable && textureStorage.retainCount > 1 ) {
	
		// Keep pixel data of the old TextureStorage when creating the new?
		if( keepPixels ) {
			NSMutableData *pixels = self.pixels;
			if( pixels ) {
				[self createWithPixels:pixels format:GL_RGBA target:target];
			}
		}
		else {
			[textureStorage release];
			textureStorage = NULL;
		}
	}
	
	if( !textureStorage ) {
		textureStorage = [[EJTextureStorage alloc] init];
	}
}

- (GLuint)textureId {
	return textureStorage.textureId;
}

- (BOOL)isDynamic {
	return !fullPath;
}

- (id)copyWithZone:(NSZone *)zone {
	EJTexture *copy = [[EJTexture allocWithZone:zone] init];
	
	// This retains the textureStorage object and sets the associated properties
	[copy createWithTexture:self];
	
	// Copy texture parameters and owningContext, not handled
	// by createWithTexture
	memcpy(copy->params, params, sizeof(EJTextureParams));
	copy->owningContext = owningContext;
	
	if( self.isDynamic ) {
		// We want a static copy. So if this texture is used by an FBO, we have to
		// re-create the texture from pixels again
		[copy createWithPixels:self.pixels format:format];
	}

	return copy;
}

- (void)createWithTexture:(EJTexture *)other {
	[textureStorage release];
	[fullPath release];
	
	format = other->format;
	contentScale = other->contentScale;
	fullPath = [other->fullPath retain];
	
	width = other->width;
	height = other->height;
	
	textureStorage = [other->textureStorage retain];
}

- (void)createWithPixels:(NSData *)pixels format:(GLenum)formatp {
	[self createWithPixels:pixels format:formatp target:GL_TEXTURE_2D];
}

- (void)createWithPixels:(NSData *)pixels format:(GLenum)formatp target:(GLenum)target {
	// Release previous texture if we had one
	if( textureStorage ) {
		[textureStorage release];
		textureStorage = NULL;
	}
	
	// Set the default texture params for Canvas2D
	params[kEJTextureParamMinFilter] = GL_LINEAR;
	params[kEJTextureParamMagFilter] = GL_LINEAR;
	params[kEJTextureParamWrapS] = GL_CLAMP_TO_EDGE;
	params[kEJTextureParamWrapT] = GL_CLAMP_TO_EDGE;

	GLint maxTextureSize;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
	
	if( width > maxTextureSize || height > maxTextureSize ) {
		NSLog(@"Warning: Image %@ larger than MAX_TEXTURE_SIZE (%d)", fullPath ? fullPath : @"[Dynamic]", maxTextureSize);
	}
	format = formatp;
	
	GLint boundTexture = 0;
	GLenum bindingName = (target == GL_TEXTURE_2D)
		? GL_TEXTURE_BINDING_2D
		: GL_TEXTURE_BINDING_CUBE_MAP;
	glGetIntegerv(bindingName, &boundTexture);
	
	textureStorage = [[EJTextureStorage alloc] initImmutable];
	[textureStorage bindToTarget:target withParams:params];
	glTexImage2D(target, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, pixels.bytes);
	glBindTexture(target, boundTexture);
}

- (void)updateWithPixels:(NSData *)pixels atX:(int)sx y:(int)sy width:(int)sw height:(int)sh {	
	int boundTexture = 0;
	glGetIntegerv(GL_TEXTURE_BINDING_2D, &boundTexture);
	
	glBindTexture(GL_TEXTURE_2D, textureStorage.textureId);
	glTexSubImage2D(GL_TEXTURE_2D, 0, sx, sy, sw, sh, format, GL_UNSIGNED_BYTE, pixels.bytes);
	
	glBindTexture(GL_TEXTURE_2D, boundTexture);
}

- (NSMutableData *)pixels {
	if( fullPath ) {
		return [self loadPixelsFromPath:fullPath];
	}
	else if( fbo ) {
		GLint boundFrameBuffer;
		glGetIntegerv( GL_FRAMEBUFFER_BINDING, &boundFrameBuffer );
		
		glBindFramebuffer(GL_FRAMEBUFFER, fbo);
		
		int size = width * height * EJGetBytesPerPixel(GL_UNSIGNED_BYTE, format);
		NSMutableData *data = [NSMutableData dataWithLength:size];
		glReadPixels(0, 0, width, height, format, GL_UNSIGNED_BYTE, data.mutableBytes);
		
		glBindFramebuffer(GL_FRAMEBUFFER, boundFrameBuffer);
		return data;
	}

	NSLog(@"Warning: Can't get pixels from texture - dynamicly created but not attached to an FBO.");
	return NULL;
}

- (NSMutableData *)loadPixelsFromPath:(NSString *)path {
	// Try @2x texture?
	if( [UIScreen mainScreen].scale == 2 ) {
		NSString *path2x = [[[path stringByDeletingPathExtension]
			stringByAppendingString:@"@2x"]
			stringByAppendingPathExtension:[path pathExtension]];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath:path2x] ) {
			contentScale = 2;
			path = path2x;
		}
	}
	
	UIImage *tmpImage = [[UIImage alloc] initWithContentsOfFile:path];
	if( !tmpImage ) {
		NSLog(@"Error Loading image %@ - not found.", path);
		return NULL;
	}
	
	CGImageRef image = tmpImage.CGImage;
	
	width = CGImageGetWidth(image);
	height = CGImageGetHeight(image);
	
	NSMutableData *pixels = [NSMutableData dataWithLength:width*height*4];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixels.mutableBytes, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	[tmpImage release];
	
	return pixels;
}

- (GLint)getParam:(GLenum)pname {
	if(pname == GL_TEXTURE_MIN_FILTER) return params[kEJTextureParamMinFilter];
	if(pname == GL_TEXTURE_MAG_FILTER) return params[kEJTextureParamMagFilter];
	if(pname == GL_TEXTURE_WRAP_S) return params[kEJTextureParamWrapS];
	if(pname == GL_TEXTURE_WRAP_T) return params[kEJTextureParamWrapT];
	return 0;
}

- (void)setParam:(GLenum)pname param:(GLenum)param {
	if(pname == GL_TEXTURE_MIN_FILTER) params[kEJTextureParamMinFilter] = param;
	else if(pname == GL_TEXTURE_MAG_FILTER) params[kEJTextureParamMagFilter] = param;
	else if(pname == GL_TEXTURE_WRAP_S) params[kEJTextureParamWrapS] = param;
	else if(pname == GL_TEXTURE_WRAP_T) params[kEJTextureParamWrapT] = param;
}

- (void)bindWithFilter:(GLenum)filter {
	params[kEJTextureParamMinFilter] = filter;
	params[kEJTextureParamMagFilter] = filter;
	[textureStorage bindToTarget:GL_TEXTURE_2D withParams:params];
}

- (void)bindToTarget:(GLenum)target {
	[textureStorage bindToTarget:target withParams:params];
}


+ (void)premultiplyPixels:(const GLubyte *)inPixels to:(GLubyte *)outPixels byteLength:(int)byteLength format:(GLenum)format {
	const GLubyte *premultiplyTable = [EJSharedTextureCache instance].premultiplyTable.bytes;
	
	if( format == GL_RGBA ) {
		for( int i = 0; i < byteLength; i += 4 ) {
			unsigned short a = inPixels[i+3] * 256;
			outPixels[i+0] = premultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = premultiplyTable[ a + inPixels[i+1] ];
			outPixels[i+2] = premultiplyTable[ a + inPixels[i+2] ];
			outPixels[i+3] = inPixels[i+3];
		}
	}
	else if ( format == GL_LUMINANCE_ALPHA ) {		
		for( int i = 0; i < byteLength; i += 2 ) {
			unsigned short a = inPixels[i+1] * 256;
			outPixels[i+0] = premultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = inPixels[i+1];
		}
	}
}

+ (void)unPremultiplyPixels:(const GLubyte *)inPixels to:(GLubyte *)outPixels byteLength:(int)byteLength format:(GLenum)format {
	const GLubyte *unPremultiplyTable = [EJSharedTextureCache instance].unPremultiplyTable.bytes;
	
	if( format == GL_RGBA ) {
		for( int i = 0; i < byteLength; i += 4 ) {
			unsigned short a = inPixels[i+3] * 256;
			outPixels[i+0] = unPremultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = unPremultiplyTable[ a + inPixels[i+1] ];
			outPixels[i+2] = unPremultiplyTable[ a + inPixels[i+2] ];
			outPixels[i+3] = inPixels[i+3];
		}
	}
	else if ( format == GL_LUMINANCE_ALPHA ) {		
		for( int i = 0; i < byteLength; i += 2 ) {
			unsigned short a = inPixels[i+1] * 256;
			outPixels[i+0] = unPremultiplyTable[ a + inPixels[i+0] ];
			outPixels[i+1] = inPixels[i+1];
		}
	}
}

+ (void)flipPixelsY:(GLubyte *)pixels bytesPerRow:(int)bytesPerRow rows:(int)rows {
	if( !pixels ) { return; }
	
	GLuint middle = rows/2;
	GLuint intsPerRow = bytesPerRow / sizeof(GLuint);
	GLuint remainingBytes = bytesPerRow - intsPerRow * sizeof(GLuint);
	
	for( GLuint rowTop = 0, rowBottom = rows-1; rowTop < middle; rowTop++, rowBottom-- ) {
		
		// Swap bytes in packs of sizeof(GLuint) bytes
		GLuint *iTop = (GLuint *)(pixels + rowTop * bytesPerRow);
		GLuint *iBottom = (GLuint *)(pixels + rowBottom * bytesPerRow);
		
		GLuint itmp;
		GLint n = intsPerRow;
		do {
			itmp = *iTop;
			*iTop++ = *iBottom;
			*iBottom++ = itmp;
		} while(--n > 0);
		
		// Swap the remaining bytes
		GLubyte *bTop = (GLubyte *)iTop;
		GLubyte *bBottom = (GLubyte *)iBottom;
		
		GLubyte btmp;
		switch( remainingBytes ) {
			case 3: btmp = *bTop; *bTop++ = *bBottom; *bBottom++ = btmp;
			case 2: btmp = *bTop; *bTop++ = *bBottom; *bBottom++ = btmp;
			case 1: btmp = *bTop; *bTop = *bBottom; *bBottom = btmp;
		}
	}
}
- (UIImage *)imageFromPixels {
	UIImage *newImage = nil;
    
	int scaledWidth = self.width  * self.contentScale;
	int scaledHeight = self.height * self.contentScale;
	int nrOfColorComponents = 4; // RGBA
	int bitsPerColorComponent = 8;
	int rawImageDataLength = scaledWidth * scaledHeight * nrOfColorComponents;
	BOOL interpolateAndSmoothPixels = NO;
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
	CGDataProviderRef dataProviderRef;
	CGColorSpaceRef colorSpaceRef;
	CGImageRef imageRef;
    
	@try {
		dataProviderRef = CGDataProviderCreateWithData(NULL, self.pixels.bytes, rawImageDataLength, nil);
		colorSpaceRef = CGColorSpaceCreateDeviceRGB();
		imageRef = CGImageCreate(
                                 width, height,
                                 bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents,
                                 colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent
                                 );
		newImage = [[UIImage alloc] initWithCGImage:imageRef scale:self.contentScale orientation:UIImageOrientationUp];
	}
	@finally {
		CGDataProviderRelease(dataProviderRef);
		CGColorSpaceRelease(colorSpaceRef);
		CGImageRelease(imageRef);
	}
    
	return newImage;
}

@end
