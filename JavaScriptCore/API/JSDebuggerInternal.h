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
    JSDebuggerInternal();
    bool addBreakpoint();
    void sourceParsed(JSC::ExecState *, JSC::SourceProvider *, int errorLineNumber, const WTF::String &errorMessage);
};
    
#ifdef __cplusplus
}
#endif

#endif
