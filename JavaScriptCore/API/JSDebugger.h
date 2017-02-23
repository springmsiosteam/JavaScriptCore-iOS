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


@interface JSDebugger : NSObject

@property (nonatomic, assign)  intptr_t* m_internal_debugger;

-(bool)attach:(JSContextRef)ctx;

@end


#endif
