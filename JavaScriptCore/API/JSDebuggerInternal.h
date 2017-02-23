//
//  JSDebuggerInternal.h
//  JavaScriptCore
//
//  Created by Orian Beltrame da Silva on 2/16/17.
//
//



#ifndef JSDebuggerInternal_h
#define JSDebuggerInternal_h

#include "JSBase.h"
#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#include "Debugger.h"

#ifndef __cplusplus
#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
 
/*!
 @function
 @abstract         Creates a JavaScript string from a null-terminated UTF8 string.
 @param string     The null-terminated UTF8 string to copy into the new JSString.
 @result           A JSString containing string. Ownership follows the Create Rule.
 */
JS_EXPORT JSStringRef JSStringCreateWithUTF8CString(const char* string);

class JSDebuggerInternal : public JSC::Debugger {
    
public:
    intptr_t delegate;
    
    JSDebuggerInternal();
  
    bool needPauseHandling(JSC::JSGlobalObject* global);
    void handlePause(JSC::Debugger::ReasonForPause reason, JSC::JSGlobalObject * globalObject);
    void sourceParsed(JSC::ExecState *exec, JSC::SourceProvider *sourceProvider, int errorLineNumber, const WTF::String &errorMessage);
    void handleBreakpointHit(const JSC::Breakpoint& breakpoint);
    
    
    bool addBreakpoint();
    
};
    
#ifdef __cplusplus
}
#endif

#endif
