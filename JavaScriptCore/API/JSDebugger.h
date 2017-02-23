//
//  JSDebugger.h
//  JavaScriptCore
//
//  Created by Orian Beltrame da Silva on 2/16/17.
//
//


#ifndef JSDebugger_h
#define JSDebugger_h

#include "JSBase.h"
#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include <JavascriptCore/JavaScript.h>

@interface JSDebuggerBreakpoint : NSObject

@property (nonatomic)  size_t breakpointID;
@property (nonatomic) size_t sourceID;
@property (nonatomic, strong) NSURL* sourceUrl;
@property (nonatomic) unsigned line;
@property (nonatomic) unsigned column;
@property (nonatomic, strong)  NSString* condition;
@property (nonatomic) bool autoContinue;
@property (nonatomic) bool isException;

@end

@interface JSDebuggerSource : NSObject

@property (nonatomic) size_t sourceID;
@property (nonatomic) int firstLine;
@property (nonatomic, strong) NSURL* sourceUrl;


-(NSString*)getKey;

@end

@protocol JSDebuggerDelegate <NSObject>

-(void)handleBreakpointHit:(JSDebuggerBreakpoint*)Breakpoint;
-(void)handleExceptionHit:(JSDebuggerBreakpoint*)Breakpoint;
-(void)handleStepHit:(JSDebuggerBreakpoint*)Breakpoint;


@end

@interface JSDebugger : NSObject

@property (nonatomic, assign) bool dummy;
@property (nonatomic, strong) NSMutableDictionary* sourceDictByURL;
@property (nonatomic, strong) NSMutableDictionary* sourceDictByID;
@property (nonatomic, strong) NSMutableDictionary* breakpoints;
@property (nonatomic, assign) intptr_t m_internal_debugger;
@property (nonatomic, assign) NSObject<JSDebuggerDelegate> *delegate;

-(bool)attach:(JSContextRef)ctx;

-(bool)detach:(JSContextRef)ctx;

-(void)handleBreakpointHit:(JSDebuggerBreakpoint*)breakpoint;

-(void)handleExceptionHit:(JSDebuggerBreakpoint*)breakpoint;

-(void)setBreakpoint:(JSDebuggerBreakpoint*)breakpoint;

-(void)removerBreakpoint:(JSDebuggerBreakpoint *)breakpoint;

-(void)handleSourceParsed:(NSURL*)url line:(int)line sourceId:(size_t)sourceID;

-(JSValueRef)evaluateScript:(JSStringRef)script thisValue:(JSValueRef)thisValue exception:(JSValueRef*) exception;

-(JSContextRef)ctx;

-(JSValueRef)currentException;

-(void) setPauseOnNextStatement:(bool)pause;
-(void) breakProgram;
-(void) continueProgram;
-(void) stepIntoStatement;
-(void) stepOverStatement;
-(void) stepOutOfFunction;

@end


#endif
