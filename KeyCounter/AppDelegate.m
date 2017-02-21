//
//  AppDelegate.m
//  KeyCounter
//
//  Created by zakky705 on 2017/02/21.
//  Copyright © 2017年 zakky705. All rights reserved.
//

#import "AppDelegate.h"

#include <IOKit/hid/IOHIDBase.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHidDevice.h>
#include <IOKit/hid/IOHIDKeys.h>

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *keyCounterMenu;
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    NSStatusItem *_statusItem;
    NSUInteger _count;
    IOHIDManagerRef _manager;
    NSThread* _threadRunLoop;
    CFRunLoopRef _runLoop;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self setupStatusItem];
    [self setupIOHIDManager];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self terminateIOHIDManager];
}

- (void)countup
{
    _count++;
    [self updateCount];
}

- (void)setupStatusItem
{
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
    _statusItem = [systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setHighlightMode:YES];
    [_statusItem setTitle:@"KeyCounter"];
    [_statusItem setImage:[NSImage imageNamed:@"KeyCounterIconTemplate"]];
    [_statusItem setMenu:self.keyCounterMenu];
}

void valueCallback (
                    void * _Nullable        context,
                    IOReturn                result,
                    void * _Nullable        sender,
                    IOHIDValueRef           value)
{
    AppDelegate* delegate = (__bridge AppDelegate*)context;
    CFIndex index = IOHIDValueGetIntegerValue(value);
//    uint8_t* ptr = IOHIDValueGetBytePtr(value);
//    uint64_t timestamp = IOHIDValueGetTimeStamp(value);
//    IOHIDElementRef element = IOHIDValueGetElement(value);
//    IOHIDElementType type = IOHIDElementGetType(element);
//    uint32_t reportCount = IOHIDElementGetReportCount(element);
//
//    printf("[%llu]callback value:%ld len:%ld type:%d reportCount:%d\n",
//           timestamp, index, IOHIDValueGetLength(value), type, reportCount);
//
//    printf("Byte:");
//    for(int i=0; i<reportCount; i++){
//        printf("%02x ", *(ptr+i));
//    }
//    printf("\n");
    
    if(index == 1){
        [delegate countup];
    }
}

//void inputCallback(
//                   void* context,
//                   IOReturn result,
//                   void* sender,
//                   IOHIDReportType type,
//                   uint32_t reportID,
//                   uint8_t* report,
//                   CFIndex reportLength)
//{
//    AppDelegate* delegate = (__bridge AppDelegate*)context;
//    
//    printf("input callback rid:%u length:%ld\n", reportID, reportLength);
//    [delegate countup];
//}

- (void)threadRunLoop
{
    NSArray* dictArray = @[@{@kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
                              @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_Keyboard),
                              }
                           ];
    IOHIDManagerSetDeviceMatchingMultiple(_manager, (__bridge CFArrayRef)dictArray);
    IOHIDManagerScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDManagerRegisterInputValueCallback(_manager, valueCallback, (__bridge void * _Nullable)(self));
//    IOHIDManagerRegisterInputReportCallback(_manager, inputCallback, (__bridge void* _Nullable)(self));
    _runLoop = CFRunLoopGetCurrent();
    CFRunLoopRun();
}

- (void)setupIOHIDManager
{
    _manager = IOHIDManagerCreate(NULL, kIOHIDManagerOptionNone);
    IOHIDManagerOpen(_manager, kIOHIDManagerOptionNone);
    
    _threadRunLoop = [[NSThread alloc] initWithTarget:self selector:@selector(threadRunLoop) object:nil];
    [_threadRunLoop start];
}

- (void)terminateIOHIDManager
{
    CFRunLoopStop(_runLoop);
    IOHIDManagerClose(_manager, kIOHIDManagerOptionNone);
    CFRelease(_manager);
}

- (void)updateCount
{
    [_statusItem setTitle:[NSString stringWithFormat:@"%lu types", _count]];
}

- (IBAction)countReset:(id)sender {
    _count = 0;
    [self updateCount];
}


@end
