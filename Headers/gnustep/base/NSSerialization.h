/* Protocol for NSSerialization for GNUStep
   Copyright (C) 1994 NeXT Computer, Inc.
   
   This file is part of the GNU Objective C Class Library.

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
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   */ 

#ifndef __NSSerialization_h_OBJECTS_INCLUDE
#define __NSSerialization_h_OBJECTS_INCLUDE

@protocol NSObjCTypeSerializationCallBack
- (void) deserialzeObjectAt: (id*)object
   ofObjCType: (const char *)type
   fromData: (NSData*)data
   atCursor: (unsigned*)cursor;
- (void) deserialzeObjectAt: (id*)object
   ofObjCType: (const char *)type
   intoData: (NSMutableData*)data;
@end

endif /* __NSSerialization_h_OBJECTS_INCLUDE */
