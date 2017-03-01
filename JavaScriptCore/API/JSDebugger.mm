//
//  JSDebugger.m
//  JavaScriptCore
//
//  Created by Orian Beltrame da Silva on 2/16/17.
//
//

#import "config.h"
#import "JSDebugger.h"
#import "JSDebuggerInternal.h"
#import "JSContextRef.h"
#import "JSStringRefCF.h"
#import <CoreFoundation/CoreFoundation.h>
#import "CallFrame.h"
#import "Debugger.h"
#import "APICast.h"
#import "Breakpoint.h"
#import "DebuggerPrimitives.h"
#import "SourceProvider.h"

using namespace JSC;

#pragma mark - prototyping

JSDebuggerInternal* toInternal(intptr_t p);
intptr_t toExternal(JSDebuggerInternal* p);
static NSURL *toNSURL(const String& s);
id toId(intptr_t ptr);

#pragma mark - implementation Internal

static NSURL *toNSURL(const String& s)
{
    if (s.isEmpty())
        return nil;
    NSString* sample = (NSString*)s;
    return [NSURL URLWithString:sample];
}

JSDebuggerInternal* toInternal(intptr_t p){
    return reinterpret_cast<JSDebuggerInternal*>(p);
}

intptr_t toExternal(JSDebuggerInternal* p){
    return reinterpret_cast<intptr_t>(p);
}

JSDebuggerInternal::JSDebuggerInternal()
: JSC::Debugger(false){
    setPauseOnExceptionsState(PauseOnAllExceptions);
}

id toId(intptr_t ptr){
    return reinterpret_cast<id>(ptr);
}

bool JSDebuggerInternal::needPauseHandling(JSC::JSGlobalObject* global){
    #pragma unused(global)
    return  true;
}

void JSDebuggerInternal::handlePause(JSC::Debugger::ReasonForPause reason, JSC::JSGlobalObject * globalObject){
    #pragma unused(globalObject)
    
    
    if(delegate){
    
        DebuggerCallFrame* debuggerCallFrame = currentDebuggerCallFrame();
        JSDebuggerBreakpoint* breakpoint = [[JSDebuggerBreakpoint alloc] init];
        breakpoint.sourceID = debuggerCallFrame->sourceID();
        breakpoint.line = debuggerCallFrame->line();
        breakpoint.condition = (NSString*)debuggerCallFrame->functionName();
    
        switch (reason) {
            
            case JSC::Debugger::PausedAfterCall:
            case JSC::Debugger::PausedBeforeReturn:
            case JSC::Debugger::PausedAtEndOfProgram:
            case JSC::Debugger::PausedAtStartOfProgram:
            case JSC::Debugger::PausedAtStatement:
            {
                [toId(delegate) handleStepHit:breakpoint];
            }
                break;
            
            case JSC::Debugger::PausedForException:
            {
                breakpoint.isException = true;
                [toId(delegate) handleExceptionHit:breakpoint];
             
            }
                break;
            
            case JSC::Debugger::PausedForBreakpoint:
            case JSC::Debugger::NotPaused:
                break;
        }
    
        [breakpoint release];
        
    }
}


void JSDebuggerInternal::handleBreakpointHit(const JSC::Breakpoint& breakpoint){
    if(delegate){
        JSDebuggerBreakpoint  *_breakpoint = [[JSDebuggerBreakpoint alloc] init];
        _breakpoint.sourceID = breakpoint.sourceID;
        _breakpoint.line = breakpoint.line;
        _breakpoint.condition = (NSString*)breakpoint.condition;
        [toId(delegate) handleBreakpointHit:_breakpoint];
        [_breakpoint release];
    }
}

void JSDebuggerInternal::sourceParsed(JSC::ExecState *exec, JSC::SourceProvider *sourceProvider, int errorLineNumber, const WTF::String &errorMessage){
    
    #pragma unused(exec)
    #pragma unused(errorLineNumber)
    #pragma unused(errorMessage)
    
    if(delegate){
        NSURL *nsURL = toNSURL(sourceProvider->url());
        int firstLine = sourceProvider->startPosition().m_line.oneBasedInt();
        intptr_t sourceID = sourceProvider->asID();
        [toId(delegate) handleSourceParsed:nsURL line:firstLine sourceId:sourceID];
    }
}

#pragma mark - implementation Public

@implementation JSDebuggerBreakpoint

-(NSString *)getKey{
    return [NSString stringWithFormat:@"%@_%u", [_sourceUrl absoluteString], _line];
}

@end

@implementation JSDebuggerSource

-(NSString *)getKey{
    return [NSString stringWithFormat:@"%@", [_sourceUrl absoluteString]];
}

@end

@implementation JSDebugger

-(instancetype)init{
    self = [super init];
    if(self){
        JSDebuggerInternal* internal = new JSDebuggerInternal();
        internal->delegate =  reinterpret_cast<intptr_t>(self);
        _m_internal_debugger = toExternal(internal);
        self.sourceDictByID = [NSMutableDictionary dictionary];
        self.sourceDictByURL = [NSMutableDictionary dictionary];
        self.breakpoints = [NSMutableDictionary dictionary];
      
    }
    return self;
}

-(bool)attach:(JSContextRef)ctx{
    

    ExecState* exec = toJS(ctx);
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    JSGlobalObject* globalObject = exec->lexicalGlobalObject();
    internal->attach(globalObject);

    return true;
}

-(bool)detach:(JSContextRef)ctx{
    
    ExecState* exec = toJS(ctx);
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    JSGlobalObject* globalObject = exec->lexicalGlobalObject();
    internal->detach(globalObject);
    
    return true;
}

-(void)handleStepHit:(JSDebuggerBreakpoint *)breakpoint
{
    if(self.delegate){
        breakpoint.sourceUrl = [[self.sourceDictByID objectForKey:@(breakpoint.sourceID)] sourceUrl];
        [self.delegate handleStepHit:breakpoint];
    }
}


-(void)handleExceptionHit:(JSDebuggerBreakpoint *)breakpoint
{
    if(self.delegate){
        breakpoint.sourceUrl = [[self.sourceDictByID objectForKey:@(breakpoint.sourceID)] sourceUrl];
        [self.delegate handleExceptionHit:breakpoint];
    }
}

-(void)handleBreakpointHit:(JSDebuggerBreakpoint *)breakpoint
{
    if(self.delegate){
        breakpoint.sourceUrl = [[self.sourceDictByID objectForKey:@(breakpoint.sourceID)] sourceUrl];
        [self.delegate handleBreakpointHit:breakpoint];
    }
}

-(void)handleStep:(JSDebuggerBreakpoint *)breakpoint
{
    if(self.delegate){
        breakpoint.sourceUrl = [[self.sourceDictByID objectForKey:@(breakpoint.sourceID)] sourceUrl];
        [self.delegate handleBreakpointHit:breakpoint];
    }
}

-(void)setBreakpoint:(JSDebuggerBreakpoint *)breakpoint{
    
    NSString* key = [breakpoint.sourceUrl absoluteString];
    JSDebuggerSource* source = [self.sourceDictByURL objectForKey:key];
    Breakpoint bp = Breakpoint([source sourceID], breakpoint.line, 0, WTF::String(), false);
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    unsigned int actualLine = 0, actualColumn = 0;
    unsigned int &pointA = actualLine, &pointB = actualColumn;
    
    breakpoint.breakpointID = internal->setBreakpoint(bp, pointA, pointB);
    [self.breakpoints setObject:breakpoint forKey:[breakpoint getKey]];
    
}

-(void)removerBreakpoint:(JSDebuggerBreakpoint *)breakpoint{
    
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    JSDebuggerBreakpoint *bp = [self.breakpoints objectForKey:[breakpoint getKey]];
    if(bp.breakpointID != noBreakpointID)
        internal->removeBreakpoint(bp.breakpointID);
}

-(void)handleSourceParsed:(NSURL*)url line:(int)line sourceId:(size_t)sourceID{

    if(url != nil){
        JSDebuggerSource* newSource = [[JSDebuggerSource alloc] init];
        newSource.sourceID =  sourceID;
        newSource.sourceUrl = url;
        newSource.firstLine =  line;
        [self.sourceDictByURL setObject:newSource forKey:[newSource getKey]];
        [self.sourceDictByID setObject:newSource forKey:@(sourceID)];
        [newSource release];
        
    }
}

-(JSValueRef)evaluateScript:(JSStringRef)script thisValue:(JSValueRef)thisValue exception:(JSValueRef*) exception
{
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    
    
    JSValue evaluationException;
    JSValue vthisValue = toJS(internal->currentDebuggerCallFrame()->exec(), thisValue);
    JSValue returnValue = internal->currentDebuggerCallFrame()->evaluateWithThisValue(vthisValue, script->string(), evaluationException);
    
    if (evaluationException) {
        if (exception)
            *exception = toRef(internal->currentDebuggerCallFrame()->exec(), evaluationException);
        return 0;
    }
    
    if (returnValue)
        return toRef(internal->currentDebuggerCallFrame()->exec(), returnValue);
    
    // happens, for example, when the only statement is an empty (';') statement
    return toRef(internal->currentDebuggerCallFrame()->exec(), jsUndefined());
}

-(JSValueRef)currentException {
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    JSValueRef exception =  toRef(internal->currentDebuggerCallFrame()->exec(), internal->currentException());
    return exception;
}

-(JSContextRef)ctx{
    JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    return toRef(internal->currentDebuggerCallFrame()->exec());
}

-(void) setPauseOnNextStatement:(bool)pause{
   JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    internal->setPauseOnNextStatement(pause);
}

-(void) breakProgram{
   JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
   internal->breakProgram();
}

-(void) continueProgram{
   JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    internal->continueProgram();
}

-(void) stepIntoStatement{
   JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    internal->stepIntoStatement();
}

-(void) stepOverStatement{
   JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    internal->stepOverStatement();
}

-(void) stepOutOfFunction{
   JSDebuggerInternal* internal = toInternal(_m_internal_debugger);
    internal->stepOutOfFunction();
}

@end

