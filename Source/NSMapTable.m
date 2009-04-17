/** NSMapTable implementation for GNUStep.
 * Copyright (C) 2009  Free Software Foundation, Inc.
 *
 * Author: Richard Frith-Macdonald <rfm@gnu.org>
 *
 * This file is part of the GNUstep Base Library.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02111 USA.
 *
 * <title>NSMapTable class reference</title>
 * $Date$ $Revision$
 */

#include "config.h"
#include "Foundation/NSObject.h"
#include "Foundation/NSString.h"
#include "Foundation/NSArray.h"
#include "Foundation/NSException.h"
#include "Foundation/NSPointerFunctions.h"
#include "Foundation/NSZone.h"
#include "Foundation/NSMapTable.h"
#include "Foundation/NSDebug.h"
#include "NSCallBacks.h"

@implementation	NSMapTable

@class	NSConcreteMapTable;

static Class	abstractClass = 0;
static Class	concreteClass = 0;

+ (id) allocWithZone: (NSZone*)aZone
{
  if (self == abstractClass)
    {
      return NSAllocateObject(concreteClass, 0, aZone);
    }
  return NSAllocateObject(self, 0, aZone);
}

+ (void) initialize
{
  if (abstractClass == 0)
    {
      abstractClass = [NSMapTable class];
      concreteClass = [NSConcreteMapTable class];
    }
}

+ (id) mapTableWithKeyOptions: (NSPointerFunctionsOptions)keyOptions
		 valueOptions: (NSPointerFunctionsOptions)valueOptions
{
  NSMapTable	*t;

  t = [self allocWithZone: NSDefaultMallocZone()];
  t = [t initWithKeyOptions: keyOptions
	       valueOptions: valueOptions
		   capacity: 0];
  return AUTORELEASE(t);
}

+ (id) mapTableWithStrongToStrongObjects
{
  return [self mapTableWithKeyOptions: NSPointerFunctionsObjectPersonality
			 valueOptions: NSPointerFunctionsObjectPersonality];
}

+ (id) mapTableWithStrongToWeakObjects
{
  return [self mapTableWithKeyOptions: NSPointerFunctionsObjectPersonality
			 valueOptions: NSPointerFunctionsObjectPersonality
    | NSPointerFunctionsZeroingWeakMemory];
}

+ (id) mapTableWithWeakToStrongObjects
{
  return [self mapTableWithKeyOptions: NSPointerFunctionsObjectPersonality
    | NSPointerFunctionsZeroingWeakMemory
			 valueOptions: NSPointerFunctionsObjectPersonality];
}

+ (id) mapTableWithWeakToWeakObjects
{
  return [self mapTableWithKeyOptions: NSPointerFunctionsObjectPersonality
    | NSPointerFunctionsZeroingWeakMemory
			 valueOptions: NSPointerFunctionsObjectPersonality
    | NSPointerFunctionsZeroingWeakMemory];
}

- (id) initWithKeyOptions: (NSPointerFunctionsOptions)keyOptions
	     valueOptions: (NSPointerFunctionsOptions)valueOptions
	         capacity: (NSUInteger)initialCapacity
{
  NSPointerFunctions	*k;
  NSPointerFunctions	*v;
  id			o;

  k = [[NSPointerFunctions alloc] initWithOptions: keyOptions];
  v = [[NSPointerFunctions alloc] initWithOptions: valueOptions];
  o = [self initWithKeyPointerFunctions: k
		  valuePointerFunctions: v
			       capacity: initialCapacity];
#if	!GS_WITH_GC
  [k release];
  [v release];
#endif
  return o;
}

- (id) initWithKeyPointerFunctions: (NSPointerFunctions*)keyFunctions
	     valuePointerFunctions: (NSPointerFunctions*)valueFunctions
			  capacity: (NSUInteger)initialCapacity
{
  return [self subclassResponsibility: _cmd];
}

- (id) copyWithZone: (NSZone*)aZone
{
  return [self subclassResponsibility: _cmd];
}

- (NSUInteger) count
{
  return (NSUInteger)[self subclassResponsibility: _cmd];
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState*)state 	
				   objects: (id*)stackbuf
				     count: (NSUInteger)len
{
  return (NSUInteger)[self subclassResponsibility: _cmd];
}

- (NSDictionary*) dictionaryRepresentation
{
  return [self subclassResponsibility: _cmd];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [self subclassResponsibility: _cmd];
}

- (NSUInteger) hash
{
  return (NSUInteger)[self subclassResponsibility: _cmd];
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  return [self subclassResponsibility: _cmd];
}

- (BOOL) isEqual: (id)other
{
  if ([other isKindOfClass: abstractClass] == NO) return NO;
  return NSCompareMapTables(self, other);
}

- (NSEnumerator*) keyEnumerator
{
  return [self subclassResponsibility: _cmd];
}

- (NSPointerFunctions*) keyPointerFunctions
{
  return [self subclassResponsibility: _cmd];
}

- (NSEnumerator*) objectEnumerator
{
  return [self subclassResponsibility: _cmd];
}

- (id) objectForKey: (id)aKey
{
  return [self subclassResponsibility: _cmd];
}

- (void) removeAllObjects
{
  [self subclassResponsibility: _cmd];
}

- (void) removeObjectForKey: (id)aKey
{
  [self subclassResponsibility: _cmd];
}

- (void) setObject: (id)anObject forKey: (id)aKey
{
  [self subclassResponsibility: _cmd];
}

- (NSPointerFunctions*) valuePointerFunctions
{
  return [self subclassResponsibility: _cmd];
}
@end

