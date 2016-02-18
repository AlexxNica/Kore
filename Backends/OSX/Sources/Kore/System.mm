#include "pch.h"
#include <Kore/System.h>
#include <Kore/Input/Keyboard.h>
#include <Kore/Log.h>
#import <Cocoa/Cocoa.h>
#import "BasicOpenGLView.h"

using namespace Kore;

extern const char* macgetresourcepath();

const char* macgetresourcepath() {
	return [[[NSBundle mainBundle] resourcePath] cStringUsingEncoding:1];
}

@interface MyApplication : NSApplication {
	bool shouldKeepRunning;
}

- (void)run;
- (void)terminate:(id)sender;

@end

@interface MyAppDelegate : NSObject<NSWindowDelegate> {
	
}

- (void)windowWillClose:(NSNotification *)notification;

@end

namespace {
	NSApplication* myapp;
	NSWindow* window;
	BasicOpenGLView* view;
	MyAppDelegate* delegate;
    
    struct KoreWindow {
        NSWindow * handle;
        int x, y;
        int width, height;
        
        KoreWindow( NSWindow * handle, int x, int y, int width, int height ) {
            this->handle = handle;
            this->x = x;
            this->y = y;
            this->width = width;
            this->height = height;
        }
    };
    
    KoreWindow* windows[10] = {nullptr,nullptr,nullptr,nullptr,nullptr,nullptr,nullptr,nullptr,nullptr,nullptr};
    int windowCounter = -1;
}

bool System::handleMessages() {
	NSEvent* event = [myapp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES]; //distantPast: non-blocking
	if (event != nil) {
		[myapp sendEvent:event];
		[myapp updateWindows];
	}
	return true;
}

void System::swapBuffers(int windowId) {
	[view switchBuffers];
}

int createWindow(const char * title, int x, int y, int width, int height, int windowMode, int targetDisplay) {
	view = [[BasicOpenGLView alloc] initWithFrame:NSMakeRect(0, 0, width, height) ];
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:TRUE];
	delegate = [MyAppDelegate alloc];
	[window setDelegate: delegate];
    [window setTitle:[NSString stringWithCString: title encoding: 1]];
	[window setAcceptsMouseMovedEvents:YES];
	[[window contentView] addSubview:view];
	[window center];
	[window makeKeyAndOrderFront: nil];
		
	return nullptr;
}

void System::destroyWindow(int windowId) {
	
}

int System::screenWidth() {
	return windows[currentDevice()]->width;
}

int System::screenHeight() {
	return windows[currentDevice()]->height;
}

int System::desktopWidth() {
	NSArray* screenArray = [NSScreen screens];
	//unsigned screenCount = [screenArray count];
	NSScreen* screen = [screenArray objectAtIndex: 0];
	NSRect screenRect = [screen visibleFrame];
	return screenRect.size.width;
}

int System::desktopHeight() {
	NSArray* screenArray = [NSScreen screens];
	//unsigned screenCount = [screenArray count];
	NSScreen* screen = [screenArray objectAtIndex: 0];
	NSRect screenRect = [screen visibleFrame];
	return screenRect.size.height;
}

namespace {
	const char* savePath = nullptr;

	void getSavePath() {
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString* resolvedPath = [paths objectAtIndex:0];
        NSString* appName = [NSString stringWithUTF8String:Kore::System::name()];
		resolvedPath = [resolvedPath stringByAppendingPathComponent:appName];
		
		NSFileManager* fileMgr = [[NSFileManager alloc] init];
		
		NSError *error;
		[fileMgr createDirectoryAtPath:resolvedPath withIntermediateDirectories:YES attributes:nil error:&error];

		resolvedPath = [resolvedPath stringByAppendingString:@"/"];
		savePath = [resolvedPath cStringUsingEncoding:1];
	}
}

const char* System::savePath() {
	if (::savePath == nullptr) getSavePath();
	return ::savePath;
}

int main(int argc, char** argv) {
	@autoreleasepool {
		myapp = [MyApplication sharedApplication];
		[myapp performSelectorOnMainThread:@selector(run) withObject:nil waitUntilDone:YES];
	}
	return 0;
}

@implementation MyApplication

- (void)run {
	@autoreleasepool {
		[self finishLaunching];
		//try {
			kore(0, nullptr);
		//}
		//catch (Kt::Exception& ex) {
		//	printf("Exception caught");
		//}
	}
}

- (void)terminate:(id)sender {
	Application::the()->stop();
}

@end

@implementation MyAppDelegate

- (void)windowWillClose:(NSNotification *)notification {
	Application::the()->stop();
}

@end