/* Definitions to allow compilation of GNU objc code with NeXT runtime
   Copyright (C) 1993,1994, 1996 Free Software Foundation, Inc.

   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date: May 1993

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/ 

/* This file is by no means complete. */

#ifndef __objc_gnu2next_h_GNUSTEP_BASE_INCLUDE
#define __objc_gnu2next_h_GNUSTEP_BASE_INCLUDE

#if NeXT_RUNTIME

#include <objc/objc-class.h>
#include <stddef.h>

#define arglist_t marg_list
#define retval_t void*
#define TypedStream void*

#define class_pointer isa

#define class_create_instance(CLASS) class_createInstance(CLASS, 0)

#define sel_get_name		sel_getName
#define sel_get_uid		sel_getUid
#define sel_eq(s1, s2) 		(s1 == s2)

/* FIXME: Any equivalent for this ? */
#define sel_get_type(SELECTOR) \
     (NULL)
     
#define class_get_instance_method	class_getInstanceMethod
#define class_get_class_method 		class_getClassMethod
#define class_add_method_list		class_addMethods
#define method_get_sizeof_arguments	method_getSizeOfArguments
#define objc_lookup_class		objc_lookUpClass
#define sel_get_any_uid			sel_getUid
#define objc_get_class			objc_getClass
#define class_get_version		class_getVersion
#define sel_register_name		sel_registerName
#define sel_is_mapped			sel_isMapped

#define class_get_class_name(CLASSPOINTER) \
     (((struct objc_class*)(CLASSPOINTER))->name)
#define object_get_class(OBJECT) \
    (((struct objc_class*)(OBJECT))->isa)
#define class_get_super_class(CLASSPOINTER) \
    (((struct objc_class*)(CLASSPOINTER))->super_class)

#define __objc_responds_to(OBJECT,SEL) \
    class_getInstanceMethod(object_get_class(OBJECT), SEL)
#define CLS_ISCLASS(CLASSPOINTER) \
    ((((struct objc_class*)(CLASSPOINTER))->info) & CLS_CLASS)
#define CLS_ISMETA(CLASSPOINTER) \
    ((((struct objc_class*)(CLASSPOINTER))->info) & CLS_META)
#define objc_msg_lookup(OBJ,SEL) \
    (class_getInstanceMethod(object_get_class(OBJ), SEL)->method_imp)


#define OBJC_READONLY 1
#define OBJC_WRITEONLY 2

/*
** Standard functions for memory allocation and disposal.
** Users should use these functions in their ObjC programs so
** that they work properly with garbage collectors as well as
** can take advantage of the exception/error handling available.
*/
void *
objc_malloc(size_t size);

void *
objc_atomic_malloc(size_t size);

void *
objc_valloc(size_t size);

void *
objc_realloc(void *mem, size_t size);

void *
objc_calloc(size_t nelem, size_t size);

void
objc_free(void *mem);

/*
** Hook functions for memory allocation and disposal.
** This makes it easy to substitute garbage collection systems
** such as Boehm's GC by assigning these function pointers
** to the GC's allocation routines.  By default these point
** to the ANSI standard malloc, realloc, free, etc.
**
** Users should call the normal objc routines above for
** memory allocation and disposal within their programs.
*/
extern void *(*_objc_malloc)(size_t);
extern void *(*_objc_atomic_malloc)(size_t);
extern void *(*_objc_valloc)(size_t);
extern void *(*_objc_realloc)(void *, size_t);
extern void *(*_objc_calloc)(size_t, size_t);
extern void (*_objc_free)(void *);

#endif /* NeXT_RUNTIME */

#endif /* __objc_gnu2next_h_GNUSTEP_BASE_INCLUDE */
