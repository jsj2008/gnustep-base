/* NSSet - Set object to store key/value pairs
   Copyright (C) 1995 Free Software Foundation, Inc.
   
   Written by:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Created: Sep 1995
   
   This file is part of the Gnustep Base Library.
   
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

#include <Foundation/NSSet.h>
#include <Foundation/NSGSet.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSUtilities.h>
#include <gnustep/base/NSString.h>
#include <assert.h>

@implementation NSSet 

static Class NSSet_concrete_class;
static Class NSMutableSet_concrete_class;

+ (void) _setConcreteClass: (Class)c
{
  NSSet_concrete_class = c;
}

+ (void) _setMutableConcreteClass: (Class)c
{
  NSMutableSet_concrete_class = c;
}

+ (Class) _concreteClass
{
  return NSSet_concrete_class;
}

+ (Class) _mutableConcreteClass
{
  return NSMutableSet_concrete_class;
}

+ (void) initialize
{
  NSSet_concrete_class = [NSGSet class];
  NSMutableSet_concrete_class = [NSGMutableSet class];
}

+ allocWithZone: (NSZone*)z
{
  return NSAllocateObject([self _concreteClass], 0, z);
}

+ set
{
  return [[[self alloc] init] 
	  autorelease];
}

+ setWithObjects: (id*)objects 
	   count: (unsigned)count
{
  return [[[self alloc] initWithObjects:objects
			count:count]
	  autorelease];
}

+ setWithArray: (NSArray*)objects
{
  /* xxx Only works because NSArray also responds to objectEnumerator
     and nextObject. */
  return [[[self alloc] initWithSet:(NSSet*)objects]
	  autorelease];
}

+ setWithObject: anObject
{
  return [[[self alloc] initWithObjects:&anObject
			count:1]
	  autorelease];
}

/* Same as NSArray */
/* Not very pretty... */
#define INITIAL_OBJECTS_SIZE 10
- initWithObjects: firstObject rest: (va_list)ap
{
  id *objects;
  int i = 0;
  int s = INITIAL_OBJECTS_SIZE;

  OBJC_MALLOC(objects, id, s);
  if (firstObject != nil)
    {
      objects[i++] = firstObject;
      while ((objects[i++] = va_arg(ap, id)))
	{
	  if (i >= s)
	    {
	      s *= 2;
	      OBJC_REALLOC(objects, id, s);
	    }
	}
    }
  self = [self initWithObjects:objects count:i-1];
  OBJC_FREE(objects);
  return self;
}

/* Same as NSArray */
+ setWithObjects: firstObject, ...
{
  va_list ap;
  va_start(ap, firstObject);
  self = [[self alloc] initWithObjects:firstObject rest:ap];
  va_end(ap);
  return [self autorelease];
}

/* This is the designated initializer */
- initWithObjects: (id*)objects
	    count: (unsigned)count
{
  [self subclassResponsibility:_cmd];
  return 0;
}

- initWithArray: (NSArray*)array
{
  /* xxx Only works because NSArray also responds to objectEnumerator
     and nextObject. */
  return [self initWithSet:(NSSet*)array];
}

/* Same as NSArray */
- initWithObjects: firstObject, ...
{
  va_list ap;
  va_start(ap, firstObject);
  self = [self initWithObjects:firstObject rest:ap];
  va_end(ap);
  return self;
}

/* Override superclass's designated initializer */
- init
{
  return [self initWithObjects:NULL count:0];
}

- initWithSet: (NSSet*)other copyItems: (BOOL)flag
{
  int c = [other count];
  id os[c], o, e = [other objectEnumerator];
  int i = 0;

  while ((o = [e nextObject]))
    {
      if (flag)
	os[i] = [o copy];
      else
	os[i] = o;
      i++;
    }
  return [self initWithObjects:os count:c];
}

- initWithSet: (NSSet*)other 
{
  return [self initWithSet:other copyItems:NO];
}

- (NSArray*) allObjects
{
  id e = [self objectEnumerator];
  int i, c = [self count];
  id k[c];

  for (i = 0; i < c; i++)
    {
      k[i] = [e nextObject];
      assert(k[i]);
    }
  assert(![e nextObject]);
  return [[[NSArray alloc] initWithObjects:k count:c]
	  autorelease];
}

- anyObject
{
  return [self notImplemented:_cmd];
}

- (BOOL) containsObject: anObject
{
  return (([self member:anObject]) ? YES : NO);
}

- (unsigned) count
{
  [self subclassResponsibility:_cmd];
  return 0;
}

- member: anObject
{
  return [self subclassResponsibility:_cmd];
  return 0;  
}

- (NSEnumerator*) objectEnumerator
{
  return [self subclassResponsibility:_cmd];
}

- (void) makeObjectsPerform: (SEL)aSelector
{
  id o, e = [self objectEnumerator];
  while ((o = [e nextObject]))
    [o perform:aSelector];
}

- (void) makeObjectsPerform: (SEL)aSelector withObject:argument
{
  id o, e = [self objectEnumerator];
  while ((o = [e nextObject]))
    [o perform:aSelector withObject: argument];
}

- (BOOL) intersectsSet: (NSSet*) otherSet
{
  [self notImplemented:_cmd];
  return NO;
}

- (BOOL) isSubsetOfSet: (NSSet*) otherSet
{
  [self notImplemented:_cmd];
  return NO;
}

- (BOOL) isEqual: other
{
  if ([other isKindOfClass:[NSSet class]])
    return [self isEqualToSet:other];
  return NO;
}

- (BOOL) isEqualToSet: (NSSet*)other
{
  if ([self count] != [other count])
    return NO;
  {
    id o, e = [self objectEnumerator];
    while ((o = [e nextObject]))
      if (![other member:o])
	return NO;
  }
  /* xxx Recheck this. */
  return YES;
}

- (NSString*) description
{
  [self notImplemented:_cmd];
  return 0;
}

- (NSString*) descriptionWithLocale: (NSDictionary*)ld;
{
  [self notImplemented:_cmd];
  return nil;
}

- copyWithZone: (NSZone*)z
{
  /* a deep copy */
  int count = [self count];
  id objects[count];
  id enumerator = [self objectEnumerator];
  id o;
  int i;

  for (i = 0; (o = [enumerator nextObject]); i++)
    objects[i] = [o copyWithZone:z];
  return [[[[self class] _concreteClass] alloc] 
	  initWithObjects:objects
	  count:count];
}

- mutableCopyWithZone: (NSZone*)z
{
  /* a shallow copy */
  return [[[[[self class] _mutableConcreteClass] _mutableConcreteClass] alloc] 
	  initWithSet:self];
}

@end

@implementation NSMutableSet

+ allocWithZone: (NSZone*)z
{
  return NSAllocateObject([self _mutableConcreteClass], 0, z);
}

+ setWithCapacity: (unsigned)numItems
{
  return [[[self alloc] initWithCapacity:numItems]
	  autorelease];
}

/* This is the designated initializer */
- initWithCapacity: (unsigned)numItems
{
  return [self subclassResponsibility:_cmd];
}

/* Override superclass's designated initializer */
- initWithObjects: (id*)objects
	    count: (unsigned)count
{
  [self initWithCapacity:count];
  while (count--)
    [self addObject:objects[count]];
  return self;
}

- (void) addObject: anObject
{
  [self subclassResponsibility:_cmd];
}

- (void) addObjectsFromArray: (NSArray*)array
{
  [self notImplemented:_cmd];
}

- (void) unionSet: (NSSet*) other
{
  [self notImplemented:_cmd];
}

- (void) intersectSet: (NSSet*) other
{
  [self notImplemented:_cmd];
}

- (void) minusSet: (NSSet*) other
{
  [self notImplemented:_cmd];
}

- (void) removeAllObjects
{
  [self subclassResponsibility:_cmd];
}

- (void) removeObject: anObject
{
  [self subclassResponsibility:_cmd];
}

@end
