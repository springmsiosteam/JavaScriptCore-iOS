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

using namespace JSC;

#pragma mark - prototyping

JSDebuggerInternal* toInternal(intptr_t* p);
intptr_t* toExternal(JSDebuggerInternal* p);

#pragma mark - implementation Internal

JSDebuggerInternal* toInternal(intptr_t* p){
    return reinterpret_cast<JSDebuggerInternal*>(p);
}

intptr_t* toExternal(JSDebuggerInternal* p){
    return reinterpret_cast<intptr_t*>(p);
}

JSDebuggerInternal::JSDebuggerInternal()
: JSC::Debugger(false){
    
}

void JSDebuggerInternal::sourceParsed(JSC::ExecState *, JSC::SourceProvider *, int errorLineNumber, const WTF::String &errorMessage){
    #pragma unused(errorLineNumber)
    #pragma unused(errorMessage)
}

#pragma mark - implementation Public

@implementation JSDebugger

-(instancetype)init{
    self = [super init];
    if(self){
        JSDebuggerInternal* internal = new JSDebuggerInternal();
        _m_internal_debugger = toExternal(internal);
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

@end


