//
// MarvinPlugIn.m
// Marvin for Xcode
//
// Created by Christoffer Winterkvist on 17/10/14.
// Copyright (c) 2014 zenangst The MIT License.
//

#import "MarvinPlugIn.h"
#import "XcodeManager.h"

@interface MarvinPlugIn ()

@property (nonatomic, strong) XcodeManager *xcodeManager;

@end

#import <AppKit/AppKit.h>

@implementation MarvinPlugIn

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static id shared = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{ shared = [[self alloc] init]; });
}

- (id)init {
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(applicationDidFinishLaunching:)
         name:NSApplicationDidFinishLaunchingNotification
         object:nil];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    
    if (editMenuItem) {
        NSMenu *marvinMenu = [[NSMenu alloc] initWithTitle:@"Marvin"];
        
        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Select Line Contents"
                                                              action:@selector(selectLineContents)
                                                       keyEquivalent:@"l"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
             NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Select Current Word"
                                                               action:@selector(selectWord)
                                                        keyEquivalent:@""];
             menuItem.target = self;
             menuItem.keyEquivalentModifierMask = NSControlKeyMask;
             menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Select Word Above"
                                                              action:@selector(selectWordAbove)
                                                       keyEquivalent:@"w"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Select Word Below"
                                                              action:@selector(selectWordBelow)
                                                       keyEquivalent:@"s"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Select Previous Word"
                                                              action:@selector(selectPreviousWord)
                                                       keyEquivalent:@"a"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Select Next Word"
                                                              action:@selector(selectNextWord)
                                                       keyEquivalent:@"d"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Delete Line"
                                                              action:@selector(deleteLine)
                                                       keyEquivalent:@"k"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask | NSShiftKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Duplicate Line"
                                                              action:@selector(duplicateLine)
                                                       keyEquivalent:@"d"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask | NSShiftKeyMask;
            menuItem;
        })];
        
        [marvinMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Join Line"
                                                              action:@selector(joinLine)
                                                       keyEquivalent:@"j"];
            menuItem.target = self;
            menuItem.keyEquivalentModifierMask = NSControlKeyMask | NSShiftKeyMask;
            menuItem;
        })];
        
        NSMenuItem *marvinMenuItem = [[NSMenuItem alloc] initWithTitle:@"Marvin"
                                                                action:nil
                                                         keyEquivalent:@""];
        marvinMenuItem.submenu = marvinMenu;
        
        [[editMenuItem submenu] addItem:marvinMenuItem];
    }
}

#pragma mark - Getters

- (XcodeManager *)xcodeManager
{
    if (_xcodeManager) return _xcodeManager;
    
    _xcodeManager = [[XcodeManager alloc] init];
    
    return _xcodeManager;
}

#pragma mark - Setters

- (void)selectLineContents
{
    self.xcodeManager.selectedRange = self.xcodeManager.lineContentsRange;
}

- (void)selectWord {
    NSRange range = self.xcodeManager.currentWordRange;
    self.xcodeManager.selectedRange = range;
}

- (void)selectWordAbove
{
    NSCharacterSet *validSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFGHIJKOLMNOPQRSTUVWXYZÅÄÆÖØabcdefghijkolmnopqrstuvwxyzåäæöø_"];
    NSRange currentRange = [self.xcodeManager selectedRange];
    unichar characterAtCursorStart = [[self.xcodeManager contents] characterAtIndex:currentRange.location];
    unichar characterAtCursorEnd = [[self.xcodeManager contents] characterAtIndex:currentRange.location-1];
    
    if (![self.xcodeManager selectedRange].length && [validSet characterIsMember:characterAtCursorStart]) {
        [self selectWord];
    } else if (![self.xcodeManager selectedRange].length && [validSet characterIsMember:characterAtCursorEnd]) {
        [self selectPreviousWord];
    } else {
        CGEventRef event = CGEventCreateKeyboardEvent(NULL, 126, true);
        CGEventSetFlags(event, 0);
        CGEventPost(kCGHIDEventTap, event);
        CFRelease(event);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSRange currentRange = [self.xcodeManager selectedRange];
            unichar characterAtCursorStart = [[self.xcodeManager contents] characterAtIndex:currentRange.location];
            
            if ([validSet characterIsMember:characterAtCursorStart]) {
                [self selectWord];
            } else {
                [self selectPreviousWord];
            }
        });
    }
}

- (void)selectWordBelow
{
    CGEventRef event = CGEventCreateKeyboardEvent(NULL, 125, true);
    CGEventSetFlags(event, 0);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self selectWord];
    });
}

- (void)selectPreviousWord
{
    self.xcodeManager.selectedRange = self.xcodeManager.previousWordRange;
    self.xcodeManager.selectedRange = self.xcodeManager.currentWordRange;
}

- (void)selectNextWord
{
    [self selectWord];
}

- (void)deleteLine
{
    [self.xcodeManager replaceCharactersInRange:self.xcodeManager.lineContentsRange withString:@""];
}

- (void)duplicateLine
{
    NSRange range = [self.xcodeManager lineRange];
    NSString *string = [self.xcodeManager contentsOfRange:range];
    NSRange duplicateRange = NSMakeRange(range.location+range.length, 0);
    [self.xcodeManager replaceCharactersInRange:duplicateRange withString:string];
    NSRange selectRange = NSMakeRange(duplicateRange.location + duplicateRange.length + string.length - 1, 0);
    [self.xcodeManager setSelectedRange:selectRange];
}

- (void)joinLine
{
    [self.xcodeManager replaceCharactersInRange:self.xcodeManager.joinRange withString:@""];
}

@end