/* Implementation for GNUStep of NSString concrete subclasses
   Copyright (C) 1997,1998,2000 Free Software Foundation, Inc.
   
   Written by Stevo Crvenkovski <stevo@btinternet.com>
   Date: February 1997
   
   Based on NSGCString and NSString
   Written by:  Andrew Kachites McCallum
   <mccallum@gnu.ai.mit.edu>
   Date: March 1995

   Optimised by  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: October 1998

   Redesign/rewrite by  Richard Frith-Macdonald <rfm@gnu.org>
   Date: September 2000

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

#include <config.h>
#include <base/preface.h>
#include <Foundation/NSString.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>
#include <base/behavior.h>
/* memcpy(), strlen(), strcmp() are gcc builtin's */

#include <base/fast.x>
#include <base/Unicode.h>

/*
 * GSCString - concrete class for strings using 8-bit character sets.
 */
@interface GSCString : GSString
{
}
@end

/*
 * GSCSubString - concrete subclass of GSCString, that relys on the
 * data stored in a GSCString object.
 */
@interface GSCSubString : GSCString
{
@public
  GSCString	*_parent;
}
@end

/*
 * GSUString - concrete class for strings using 16-bit character sets.
 */
@interface GSUString : GSString
{
}
@end

/*
 * GSUSubString - concrete subclass of GSUString, that relys on the
 * data stored in a GSUString object.
 */
@interface GSUSubString : GSUString
{
@public
  GSUString	*_parent;
}
@end

/*
 * GSMString - concrete mutable string, capable of changing its storage
 * from holding 8-bit to 16-bit character set.
 */
@interface GSMString : NSMutableString
{
  union {
    unichar		*u;
    unsigned char	*c;
  } _contents;
  unsigned int	_count;
  struct {
    unsigned int	wide: 1;
    unsigned int	free: 1;
    unsigned int	unused: 2;
    unsigned int	hash: 28;
  } _flags;
  NSZone	*_zone;
  unsigned int	_capacity;
}
@end

/*
 * Typedef for access to internals of concrete string objects.
 */
typedef struct {
  @defs(GSMString)
} *ivars;

/*
 *	Include sequence handling code with instructions to generate search
 *	and compare functions for NSString objects.
 */
#define	GSEQ_STRCOMP	strCompUsNs
#define	GSEQ_STRRANGE	strRangeUsNs
#define	GSEQ_O	GSEQ_NS
#define	GSEQ_S	GSEQ_US
#include <GSeq.h>

#define	GSEQ_STRCOMP	strCompUsUs
#define	GSEQ_STRRANGE	strRangeUsUs
#define	GSEQ_O	GSEQ_US
#define	GSEQ_S	GSEQ_US
#include <GSeq.h>

#define	GSEQ_STRCOMP	strCompUsCs
#define	GSEQ_STRRANGE	strRangeUsCs
#define	GSEQ_O	GSEQ_CS
#define	GSEQ_S	GSEQ_US
#include <GSeq.h>

#define	GSEQ_STRCOMP	strCompCsNs
#define	GSEQ_STRRANGE	strRangeCsNs
#define	GSEQ_O	GSEQ_NS
#define	GSEQ_S	GSEQ_CS
#include <GSeq.h>

#define	GSEQ_STRCOMP	strCompCsUs
#define	GSEQ_STRRANGE	strRangeCsUs
#define	GSEQ_O	GSEQ_US
#define	GSEQ_S	GSEQ_CS
#include <GSeq.h>

#define	GSEQ_STRCOMP	strCompCsCs
#define	GSEQ_STRRANGE	strRangeCsCs
#define	GSEQ_O	GSEQ_CS
#define	GSEQ_S	GSEQ_CS
#include <GSeq.h>

static Class NSDataClass = 0;
static Class NSStringClass = 0;
static Class GSStringClass = 0;
static Class GSCStringClass = 0;
static Class GSCSubStringClass = 0;
static Class GSUStringClass = 0;
static Class GSUSubStringClass = 0;
static Class GSMStringClass = 0;
static Class NXConstantStringClass = 0;

static SEL	convertSel = @selector(canBeConvertedToEncoding:);
static BOOL	(*convertImp)(id, SEL, NSStringEncoding) = 0;
static SEL	equalSel = @selector(isEqualToString:);
static BOOL	(*equalImp)(id, SEL, id) = 0;
static SEL	hashSel = @selector(hash);
static unsigned (*hashImp)(id, SEL) = 0;

static NSStringEncoding defEnc = 0;

/*
 * The setup() function is called when any concrete string class is
 * initialized, and cached classes and some method implementations.
 */
static void
setup()
{
  static BOOL	beenHere = NO;

  if (beenHere == NO)
    {
      beenHere = YES;

      NSDataClass = [NSData class];
      NSStringClass = [NSString class];
      GSStringClass = [GSString class];
      GSCStringClass = [GSCString class];
      GSUStringClass = [GSUString class];
      GSCSubStringClass = [GSCSubString class];
      GSUSubStringClass = [GSUSubString class];
      GSMStringClass = [GSMString class];
      NXConstantStringClass = [NXConstantString class];

      convertImp = (BOOL (*)(id, SEL, NSStringEncoding))
	[NSStringClass instanceMethodForSelector: convertSel];
      equalImp = (BOOL (*)(id, SEL, id))
	[NSStringClass instanceMethodForSelector: equalSel];
      hashImp = (unsigned (*)(id, SEL))
	[NSStringClass instanceMethodForSelector: hashSel];

      defEnc = [NSString defaultCStringEncoding];
    }
}


/*
 * The following inline functions are used by the concrete string classes
 * to implement their core functionality.
 * GSCString uses the functions with the _c suffix.
 * GSCSubString and NXConstant inherit methods from GSCString.
 * GSUString uses the functions with the _u suffix.
 * GSUSubString inherits methods from GSUString.
 * GSMString uses all the functions, selecting the _c or _u versions
 * depending on whether its storage is 8-bit or 16-bit.
 * In addition, GSMString uses a few functions without a suffix that are
 * peculiar to its memory management (shrinking, growing, and converting).
 */

static inline BOOL
boolValue_c(ivars self)
{
  if (self->_count == 0)
    {
      return NO;
    }
  else
    {
      unsigned	len = self->_count < 10 ? self->_count : 9;

      if (len == 3
	&& (self->_contents.c[0] == 'Y' || self->_contents.c[0] == 'y')
	&& (self->_contents.c[1] == 'E' || self->_contents.c[1] == 'e')
	&& (self->_contents.c[2] == 'S' || self->_contents.c[2] == 's'))
	{
	  return YES;
	}
      else
	{
	  unsigned char	buf[len+1];

	  memcpy(buf, self->_contents.c, len);
	  buf[len] = '\0';
	  return atoi(buf);
	}
    }
}

static inline BOOL
boolValue_u(ivars self)
{
  if (self->_count == 0)
    {
      return NO;
    }
  else
    {
      unsigned	len = self->_count < 10 ? self->_count : 9;
      char	buf[len+1];

      encode_ustrtostr(buf, self->_contents.u, len, defEnc);
      buf[len] = '\0';
      if (len == 3
	&& (buf[0] == 'Y' || buf[0] == 'y')
	&& (buf[1] == 'E' || buf[1] == 'e')
	&& (buf[2] == 'S' || buf[2] == 's'))
	{
	  return YES;
	}
      else
	{
	  return atoi(buf);
	}
    }
}

static inline BOOL
canBeConvertedToEncoding_c(ivars self, NSStringEncoding enc)
{
  if (enc == defEnc)
    return YES;
  else
    {
      BOOL	result = (*convertImp)((id)self, convertSel, enc);

      return result;
    }
}

static inline BOOL
canBeConvertedToEncoding_u(ivars self, NSStringEncoding enc)
{
  BOOL	result = (*convertImp)((id)self, convertSel, enc);

  return result;
}

static inline unichar
characterAtIndex_c(ivars self, unsigned index)
{
  unichar	c;

  if (index >= self->_count)
    [NSException raise: NSRangeException format: @"Invalid index."];
  c = self->_contents.c[index];
  if (c > 127)
    {
      c = encode_chartouni(c, defEnc);
    }
  return c;
}

static inline unichar
characterAtIndex_u(ivars self,unsigned index)
{
  if (index >= self->_count)
    [NSException raise: NSRangeException format: @"Invalid index."];
  return self->_contents.u[index];
}

static inline NSComparisonResult
compare_c(ivars self, NSString *aString, unsigned mask, NSRange aRange)
{
  Class	c;

  if (aString == nil)
    [NSException raise: NSInvalidArgumentException format: @"compare with nil"];
  if (fastIsInstance(aString) == NO)
    return strCompCsNs((id)self, aString, mask, aRange);

  c = fastClass(aString);
  if (fastClassIsKindOfClass(c, GSUStringClass) == YES
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 1))
    return strCompCsUs((id)self, aString, mask, aRange);
  else if (fastClassIsKindOfClass(c, GSCStringClass) == YES
    || c == NXConstantStringClass
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 0))
    return strCompCsCs((id)self, aString, mask, aRange);
  else
    return strCompCsNs((id)self, aString, mask, aRange);
}

static inline NSComparisonResult
compare_u(ivars self, NSString *aString, unsigned mask, NSRange aRange)
{
  Class	c;

  if (aString == nil)
    [NSException raise: NSInvalidArgumentException format: @"compare with nil"];
  if (fastIsInstance(aString) == NO)
    return strCompUsNs((id)self, aString, mask, aRange);

  c = fastClass(aString);
  if (fastClassIsKindOfClass(c, GSUStringClass)
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 1))
    return strCompUsUs((id)self, aString, mask, aRange);
  else if (fastClassIsKindOfClass(c, GSCStringClass)
    || c == NXConstantStringClass
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 0))
    return strCompUsCs((id)self, aString, mask, aRange);
  else
    return strCompUsNs((id)self, aString, mask, aRange);
}

static inline char*
cString_c(ivars self)
{
  char *r = (char*)_fastMallocBuffer(self->_count+1);

  if (self->_count > 0)
    {
      memcpy(r, self->_contents.c, self->_count);
    }
  r[self->_count] = '\0';
  
  return r;
}

static inline char*
cString_u(ivars self)
{
  char *r = (char*)_fastMallocBuffer(self->_count+1);

  if (self->_count > 0)
    {
      if (encode_ustrtostr_strict(r, self->_contents.u, self->_count, defEnc)
	== 0)
	{
	  [NSException raise: NSCharacterConversionException
		      format: @"Can't get cString from Unicode string."];
	}
    }
  r[self->_count] = '\0';
  
  return r;
}

static inline unsigned int
cStringLength_c(ivars self)
{
  return self->_count;
}

static inline unsigned int
cStringLength_u(ivars self)
{
  unsigned	c;

  if (self->_count > 0)
    {
      char	*r;

      r = (char*)NSZoneMalloc(NSDefaultMallocZone(), self->_count+1);
      if (encode_ustrtostr(r, self->_contents.u, self->_count, defEnc) == 0)
	{
	  NSZoneFree(NSDefaultMallocZone(), r);
	  [NSException raise: NSCharacterConversionException
		      format: @"Can't get cStringLength from Unicode string."];
	}
      r[self->_count] = '\0';
      c = strlen(r);
      NSZoneFree(NSDefaultMallocZone(), r);
    }
  else
    {
      c = 0;
    }
  return c;
}

static inline NSData*
dataUsingEncoding_c(ivars self, NSStringEncoding encoding, BOOL flag)
{
  unsigned	len = self->_count;

  if (len == 0)
    {
      return [NSDataClass data];
    }

  if ((encoding == defEnc)
    || ((defEnc == NSASCIIStringEncoding) 
    && ((encoding == NSISOLatin1StringEncoding)
    || (encoding == NSISOLatin2StringEncoding)
    || (encoding == NSNEXTSTEPStringEncoding)
    || (encoding == NSNonLossyASCIIStringEncoding))))
    {
      unsigned char *buff;

      buff = (unsigned char*)NSZoneMalloc(NSDefaultMallocZone(), len);
      memcpy(buff, self->_contents.c, len);
      return [NSDataClass dataWithBytesNoCopy: buff length: len];
    }
  else if (encoding == NSUnicodeStringEncoding)
    {
      int	t;
      unichar	*buff;

      buff = (unichar*)NSZoneMalloc(NSDefaultMallocZone(),
	sizeof(unichar)*(len+1));
      buff[0] = 0xFEFF;
      t = encode_strtoustr(buff+1, self->_contents.c, len, defEnc);
      return [NSDataClass dataWithBytesNoCopy: buff
				       length: sizeof(unichar)*(t+1)];
    }
  else
    {
      int	t;
      unichar	*ubuff;
      unsigned char *buff;

      ubuff = (unichar*)NSZoneMalloc(NSDefaultMallocZone(),
	sizeof(unichar)*len);
      t = encode_strtoustr(ubuff, self->_contents.c, len, defEnc);
      buff = (unsigned char*)NSZoneMalloc(NSDefaultMallocZone(), t);
      if (flag)
	t = encode_ustrtostr(buff, ubuff, t, encoding);
      else 
	t = encode_ustrtostr_strict(buff, ubuff, t, encoding);
      NSZoneFree(NSDefaultMallocZone(), ubuff);
      if (t == 0)
        {
	  NSZoneFree(NSDefaultMallocZone(), buff);
	  return nil;
	}
      return [NSDataClass dataWithBytesNoCopy: buff length: t];
    }
}

static inline NSData*
dataUsingEncoding_u(ivars self, NSStringEncoding encoding, BOOL flag)
{
  unsigned	len = self->_count;

  if (len == 0)
    {
      return [NSDataClass data];
    }

  if (encoding == NSUnicodeStringEncoding)
    {
      unichar *buff;

      buff = (unichar*)NSZoneMalloc(NSDefaultMallocZone(),
	sizeof(unichar)*(len+1));
      buff[0] = 0xFEFF;
      memcpy(buff+1, self->_contents.u, sizeof(unichar)*len);
      return [NSData dataWithBytesNoCopy: buff
				  length: sizeof(unichar)*(len+1)];
    }
  else
    {
      int t;
      unsigned char *buff;

      buff = (unsigned char*)NSZoneMalloc(NSDefaultMallocZone(), len);
      if (flag == YES)
	t = encode_ustrtostr(buff, self->_contents.u, len, encoding);
      else 
	t = encode_ustrtostr_strict(buff, self->_contents.u, len, encoding);
      if (!t)
        {
	  NSZoneFree(NSDefaultMallocZone(), buff);
	  return nil;
	}
      return [NSDataClass dataWithBytesNoCopy: buff length: t];
    }
}

static inline double
doubleValue_c(ivars self)
{
  if (self->_count == 0)
    {
      return 0;
    }
  else
    {
      unsigned	len = self->_count < 32 ? self->_count : 31;
      char	buf[len+1];

      memcpy(buf, self->_contents.c, len);
      buf[len] = '\0';
      return atof(buf);
    }
}

static inline double
doubleValue_u(ivars self)
{
  if (self->_count == 0)
    {
      return 0;
    }
  else
    {
      unsigned	len = self->_count < 32 ? self->_count : 31;
      char	buf[len+1];

      encode_ustrtostr(buf, self->_contents.u, len, defEnc);
      buf[len] = '\0';
      return atof(buf);
    }
}

static inline void
fillHole(ivars self, unsigned index, unsigned size)
{
  NSCAssert(size > 0, @"size <= zero");
  NSCAssert(index + size <= self->_count, @"index + size > length");

  self->_count -= size;
#ifndef STABLE_MEMCPY
  {
    int i;

    if (self->_flags.wide == 1)
      {
	for (i = index; i <= self->_count; i++)
	  {
	    self->_contents.u[i] = self->_contents.u[i+size];
	  }
      }
    else
      {
	for (i = index; i <= self->_count; i++)
	  {
	    self->_contents.c[i] = self->_contents.c[i+size];
	  }
      }
  }
#else
  if (self->_flags.wide == 1)
    {
      memcpy(self->_contents.u + index + size,
	self->_contents.u + index,
	sizeof(unichar)*(self->_count - index));
    }
  else
    {
      memcpy(self->_contents.c + index + size,
	self->_contents.c + index, (self->_count - index));
    }
#endif // STABLE_MEMCPY
  self->_flags.hash = 0;
}

static inline void
getCharacters_c(ivars self, unichar *buffer, NSRange aRange)
{
  encode_strtoustr(buffer, self->_contents.c + aRange.location,
    aRange.length, defEnc);
}

static inline void
getCharacters_u(ivars self, unichar *buffer, NSRange aRange)
{
  memcpy(buffer, self->_contents.u + aRange.location,
    aRange.length*sizeof(unichar));
}

static inline void
getCString_c(ivars self, char *buffer, unsigned int maxLength,
  NSRange aRange, NSRange *leftoverRange)
{
  int len;

  if (maxLength > self->_count)
    {
      maxLength = self->_count;
    }
  if (maxLength < aRange.length)
    {
      len = maxLength;
      if (leftoverRange != 0)
	{
	  leftoverRange->location = 0;
	  leftoverRange->length = 0;
	}
    }
  else
    {
      len = aRange.length;
      if (leftoverRange != 0)
	{
	  leftoverRange->location = aRange.location + maxLength;
	  leftoverRange->length = aRange.length - maxLength;
	}
    }

  memcpy(buffer, &self->_contents.c[aRange.location], len);
  buffer[len] = '\0';
}

static inline void
getCString_u(ivars self, char *buffer, unsigned int maxLength,
  NSRange aRange, NSRange *leftoverRange)
{
  int len;

  if (maxLength > self->_count)
    {
      maxLength = self->_count;
    }
  if (maxLength < aRange.length)
    {
      len = maxLength;
      if (leftoverRange != 0)
	{
	  leftoverRange->location = 0;
	  leftoverRange->length = 0;
	}
    }
  else
    {
      len = aRange.length;
      if (leftoverRange != 0)
	{
	  leftoverRange->location = aRange.location + maxLength;
	  leftoverRange->length = aRange.length - maxLength;
	}
    }

  encode_ustrtostr_strict(buffer, &self->_contents.u[aRange.location],
    maxLength, defEnc);
  buffer[len] = '\0';
}

static inline int
intValue_c(ivars self)
{
  if (self->_count == 0)
    {
      return 0;
    }
  else
    {
      unsigned	len = self->_count < 32 ? self->_count : 31;
      char	buf[len+1];

      memcpy(buf, self->_contents.c, len);
      buf[len] = '\0';
      return atol(buf);
    }
}

static inline int
intValue_u(ivars self)
{
  if (self->_count == 0)
    {
      return 0;
    }
  else
    {
      unsigned	len = self->_count < 32 ? self->_count : 31;
      char	buf[len+1];

      encode_ustrtostr(buf, self->_contents.u, len, defEnc);
      buf[len] = '\0';
      return atol(buf);
    }
}

static inline BOOL
isEqual_c(ivars self, id anObject)
{
  Class	c;

  if (anObject == (id)self)
    {
      return YES;
    }
  if (anObject == nil)
    {
      return NO;
    }
  if (fastIsInstance(anObject) == NO)
    {
      return NO;
    }
  c = fastClassOfInstance(anObject);
  if (c == NXConstantStringClass)
    {
      ivars	other = (ivars)anObject;
      NSRange	r = {0, self->_count};

      if (strCompCsCs((id)self, (id)other, 0, r) == NSOrderedSame)
	return YES;
      return NO;
    }
  else if (fastClassIsKindOfClass(c, GSStringClass) == YES)
    {
      ivars	other = (ivars)anObject;
      NSRange	r = {0, self->_count};

      /*
       * First see if the hash is the same - if not, we can't be equal.
       */
      if (self->_flags.hash == 0)
        self->_flags.hash = (*hashImp)((id)self, hashSel);
      if (other->_flags.hash == 0)
        other->_flags.hash = (*hashImp)((id)other, hashSel);
      if (self->_flags.hash != other->_flags.hash)
	return NO;

      /*
       * Do a compare depending on the type of the other string.
       */
      if (other->_flags.wide == 1)
	{
	  if (strCompCsUs((id)self, (id)other, 0, r) == NSOrderedSame)
	    return YES;
	}
      else
	{
	  if (strCompCsCs((id)self, (id)other, 0, r) == NSOrderedSame)
	    return YES;
	}
      return NO;
    }
  else if (fastClassIsKindOfClass(c, NSStringClass))
    {
      return (*equalImp)((id)self, equalSel, anObject);
    }
  else
    {
      return NO;
    }
}

static inline BOOL
isEqual_u(ivars self, id anObject)
{
  Class	c;

  if (anObject == (id)self)
    {
      return YES;
    }
  if (anObject == nil)
    {
      return NO;
    }
  if (fastIsInstance(anObject) == NO)
    {
      return NO;
    }
  c = fastClassOfInstance(anObject);
  if (c == NXConstantStringClass)
    {
      ivars	other = (ivars)anObject;
      NSRange	r = {0, self->_count};

      if (strCompUsCs((id)self, (id)other, 0, r) == NSOrderedSame)
	return YES;
      return NO;
    }
  else if (fastClassIsKindOfClass(c, GSStringClass) == YES)
    {
      ivars	other = (ivars)anObject;
      NSRange	r = {0, self->_count};

      /*
       * First see if the hash is the same - if not, we can't be equal.
       */
      if (self->_flags.hash == 0)
        self->_flags.hash = (*hashImp)((id)self, hashSel);
      if (other->_flags.hash == 0)
        other->_flags.hash = (*hashImp)((id)other, hashSel);
      if (self->_flags.hash != other->_flags.hash)
	return NO;

      /*
       * Do a compare depending on the type of the other string.
       */
      if (other->_flags.wide == 1)
	{
	  if (strCompUsUs((id)self, (id)other, 0, r) == NSOrderedSame)
	    return YES;
	}
      else
	{
	  if (strCompUsCs((id)self, (id)other, 0, r) == NSOrderedSame)
	    return YES;
	}
      return NO;
    }
  else if (fastClassIsKindOfClass(c, NSStringClass))
    {
      return (*equalImp)((id)self, equalSel, anObject);
    }
  else
    {
      return NO;
    }
}

static inline const char*
lossyCString_c(ivars self)
{
  unsigned char	*r = (unsigned char*)_fastMallocBuffer(self->_count+1);

  memcpy(r, self->_contents.c, self->_count);
  r[self->_count] = '\0';
  return (const char*)r;
}

static inline const char*
lossyCString_u(ivars self)
{
  unsigned char	*r = (unsigned char*)_fastMallocBuffer(self->_count+1);

  encode_ustrtostr(r, self->_contents.u, self->_count, defEnc);
  r[self->_count] = '\0';
  return (const char*)r;
}

static inline void
makeHole(ivars self, int index, int size)
{
  unsigned	want;

  NSCAssert(size > 0, @"size < zero");
  NSCAssert(index <= self->_count, @"index > length");

  want = size + self->_count + 1;
  if (want > self->_capacity)
    {
      self->_capacity += self->_capacity/2;
      if (want > self->_capacity)
	{
	  self->_capacity = want;
	}
      if (self->_flags.free == 1)
	{
	  /*
	   * If we own the character buffer, we can simply realloc.
	   */
	  if (self->_flags.wide == 1)
	    {
	      self->_contents.u = NSZoneRealloc(self->_zone,
		self->_contents.u, self->_capacity*sizeof(unichar));
	    }
	  else
	    {
	      self->_contents.c = NSZoneRealloc(self->_zone,
		self->_contents.c, self->_capacity);
	    }
	}
      else
	{
	  /*
	   * If the initial data was not to be freed, we must allocate new
	   * buffer, copy the data, and set up the zone we are using.
	   */
	  if (self->_zone == 0)
	    {
#if	GS_WITH_GC
	      self->_zone = GSAtomicMallocZone();
#else
	      self->_zone = fastZone((NSObject*)self);
#endif
	    }
	  if (self->_flags.wide == 1)
	    {
	      unichar	*tmp = self->_contents.u;

	      self->_contents.u = NSZoneMalloc(self->_zone,
		self->_capacity*sizeof(unichar));
	      if (self->_count > 0)
		{
		  memcpy(self->_contents.u, tmp, self->_count*sizeof(unichar));
		}
	    }
	  else
	    {
	      unsigned char	*tmp = self->_contents.c;

	      self->_contents.c = NSZoneMalloc(self->_zone, self->_capacity);
	      if (self->_count > 0)
		{
		  memcpy(self->_contents.c, tmp, self->_count);
		}
	    }
	  self->_flags.free = 1;
	}
    }

  if (index < self->_count)
    {
#ifndef STABLE_MEMCPY
      if (self->_flags.wide == 1)
	{
	  int i;

	  for (i = self->_count; i >= index; i--)
	    {
	      self->_contents.u[i+size] = self->_contents.u[i];
	    }
	}
      else
	{
	  int i;

	  for (i = self->_count; i >= index; i--)
	    {
	      self->_contents.c[i+size] = self->_contents.c[i];
	    }
	}
#else
      if (self->_flags.wide == 1)
	{
	  memcpy(self->_contents.u + index,
	    self->_contents.u + index + size,
	    sizeof(unichar)*(self->_count - index));
	}
      else
	{
	  memcpy(self->_contents.c + index,
	    self->_contents.c + index + size,
	    (self->_count - index));
	}
#endif /* STABLE_MEMCPY */
    }

  self->_count += size;
  self->_flags.hash = 0;
}

static inline NSRange
rangeOfSequence_c(ivars self, unsigned anIndex)
{
  if (anIndex >= self->_count)
    [NSException raise: NSRangeException format:@"Invalid location."];

  return (NSRange){anIndex, 1};
}

static inline NSRange
rangeOfSequence_u(ivars self, unsigned anIndex)
{
  unsigned	start;
  unsigned	end;

  if (anIndex >= self->_count)
    [NSException raise: NSRangeException format:@"Invalid location."];

  start = anIndex;
  while (uni_isnonsp(self->_contents.u[start]) && start > 0)
    start--;
  end = start + 1;
  if (end < self->_count)
    while ((end < self->_count) && (uni_isnonsp(self->_contents.u[end])) )
      end++;
  return (NSRange){start, end-start};
}

static inline NSRange
rangeOfString_c(ivars self, NSString *aString, unsigned mask, NSRange aRange)
{
  Class	c;

  if (aString == nil)
    [NSException raise: NSInvalidArgumentException format: @"range of nil"];
  if (fastIsInstance(aString) == NO)
    return strRangeCsNs((id)self, aString, mask, aRange);

  c = fastClass(aString);
  if (fastClassIsKindOfClass(c, GSUStringClass) == YES
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 1))
    return strRangeCsUs((id)self, aString, mask, aRange);
  else if (fastClassIsKindOfClass(c, GSCStringClass) == YES
    || c == NXConstantStringClass
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 0))
    return strRangeCsCs((id)self, aString, mask, aRange);
  else
    return strRangeCsNs((id)self, aString, mask, aRange);
}

static inline NSRange
rangeOfString_u(ivars self, NSString *aString, unsigned mask, NSRange aRange)
{
  Class	c;

  if (aString == nil)
    [NSException raise: NSInvalidArgumentException format: @"range of nil"];
  if (fastIsInstance(aString) == NO)
    return strRangeUsNs((id)self, aString, mask, aRange);

  c = fastClass(aString);
  if (fastClassIsKindOfClass(c, GSUStringClass) == YES
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 1))
    return strRangeUsUs((id)self, aString, mask, aRange);
  else if (fastClassIsKindOfClass(c, GSCStringClass) == YES
    || c == NXConstantStringClass
    || (c == GSMStringClass && ((ivars)aString)->_flags.wide == 0))
    return strRangeUsCs((id)self, aString, mask, aRange);
  else
    return strRangeUsNs((id)self, aString, mask, aRange);
}

static inline NSString*
substring_c(ivars self, NSRange aRange)
{
  GSCSubString	*sub;

  sub = [GSCSubStringClass allocWithZone: NSDefaultMallocZone()];
  sub = [sub initWithCStringNoCopy: self->_contents.c + aRange.location
			    length: aRange.length
		      freeWhenDone: NO];
  if (sub != nil)
    {
      sub->_parent = RETAIN((id)self);
      AUTORELEASE(sub);
    }
  return sub;
}

static inline NSString*
substring_u(ivars self, NSRange aRange)
{
  GSUSubString	*sub;

  sub = [GSUSubStringClass allocWithZone: NSDefaultMallocZone()];
  sub = [sub initWithCharactersNoCopy: self->_contents.u + aRange.location
			       length: aRange.length
			 freeWhenDone: NO];
  if (sub != nil)
    {
      sub->_parent = RETAIN((id)self);
      AUTORELEASE(sub);
    }
  return sub;
}

/*
 * Function to examine the given string and see if it is one of our concrete
 * string classes.  Converts the mutable string (self) from 8-bit to 16-bit
 * representation if necessary in order to contain the data in aString.
 * Returns a pointer to aStrings ivars if aString is a concrete class
 * from which contents may be copied directly without conversion.
 */
static inline ivars
transmute(ivars self, NSString *aString)
{
  ivars	other;
  BOOL	transmute;
  Class	c = fastClass(aString);

  other = (ivars)aString;
  transmute = YES;

  if (self->_flags.wide == 1)
    {
      /*
       * This is already a unicode string, so we don't need to transmute,
       * but we still need to know if the other string is a unicode
       * string whose ivars we can access directly.
       */
      transmute = NO;
      if ((c != GSMStringClass || other->_flags.wide != 1)
	&& c != GSUStringClass)
	{
	  other = 0;
	}
    }
  else
    {
      if (c == GSCStringClass || c == NXConstantStringClass
	|| (c == GSMStringClass && other->_flags.wide == 0))
	{
	  /*
	   * This is a C string, but the other string is also a C string
	   * so we don't need to transmute, and we can use its ivars.
	   */
	  transmute = NO;
	}
      else if ([aString canBeConvertedToEncoding: defEnc] == YES)
	{
	  /*
	   * This is a C string, but the other string can be converted to
	   * a C string, so we don't need to transmute, but we can not use
	   * its ivars.
	   */
	  transmute = NO;
	  other = 0;
	}
      else if ((c == GSMStringClass && other->_flags.wide == 1)
	|| c == GSUStringClass)
	{
	  /*
	   * This is a C string, and the other string can not be converted
	   * to a C string, so we need to transmute, and will then be able
	   * to use its ivars.
	   */
	  transmute = YES;
	}
      else
	{
	  /*
	   * This is a C string, and the other string can not be converted
	   * to a C string, so we need to transmute, but even then we will
	   * not be able to use  the other strings ivars.
	   */
	  other = 0;
	}
    }

  if (transmute == YES)
    {
      unichar	*tmp;

      tmp = NSZoneMalloc(self->_zone, self->_capacity * sizeof(unichar));
      encode_strtoustr(tmp, self->_contents.c, self->_count, defEnc);
      if (self->_flags.free == 1)
	{
	  NSZoneFree(self->_zone, self->_contents.c);
	}
      else
	{
	  self->_flags.free = 1;
	}
      self->_contents.u = tmp;
      self->_flags.wide = 1;
    }

  return other;
}



@implementation	GSString
- (void) dealloc
{
  if (_flags.free == 1 && _contents.c != 0)
    {
      NSZoneFree(NSZoneFromPointer(_contents.c), _contents.c);
      _contents.c = 0;
    }
  [super dealloc];
}

- (id) initWithCharactersNoCopy: (unichar*)chars
			 length: (unsigned int)length
		   freeWhenDone: (BOOL)flag
{
  isa = GSUStringClass;
  _count = length;
  _contents.u = chars;
  _flags.wide = 1;
  if (flag == YES)
    _flags.free = 1;
  return self;
}

- (id) initWithCStringNoCopy: (char*)chars
		      length: (unsigned int)length
	        freeWhenDone: (BOOL)flag
{
  isa = GSCStringClass;
  _count = length;
  _contents.c = chars;
  _flags.wide = 0;
  if (flag == YES)
    _flags.free = 1;
  return self;
}
@end

@implementation GSCString

+ (id) alloc
{
  return NSAllocateObject (self, 0, NSDefaultMallocZone());
}

+ (id) allocWithZone: (NSZone*)z
{
  return NSAllocateObject (self, 0, z);
}

+ (void) initialize
{
  setup();
}

- (BOOL) boolValue
{
  return boolValue_c((ivars)self);
}

- (BOOL) canBeConvertedToEncoding: (NSStringEncoding)enc
{
  return canBeConvertedToEncoding_c((ivars)self, enc);
}

- (unichar) characterAtIndex: (unsigned int)index
{
  return characterAtIndex_c((ivars)self, index);
}

- (NSComparisonResult) compare: (NSString*)aString
		       options: (unsigned int)mask
			 range: (NSRange)aRange
{
  return compare_c((ivars)self, aString, mask, aRange);
}

- (id) copy
{
  if (NSShouldRetainWithZone(self, NSDefaultMallocZone()) == NO)
    {
      GSCString	*obj;

      obj = (GSCString*)NSCopyObject(self, 0, NSDefaultMallocZone());
      if (_contents.c != 0)
	{
	  unsigned char	*tmp;

	  tmp = NSZoneMalloc(NSDefaultMallocZone(), _count);
	  memcpy(tmp, _contents.c, _count);
	  obj->_contents.c = tmp;
	}
      return obj;
    }
  else 
    {
      return RETAIN(self);
    }
}

- (id) copyWithZone: (NSZone*)z
{
  if (NSShouldRetainWithZone(self, z) == NO)
    {
      GSCString	*obj;

      obj = (GSCString*)NSCopyObject(self, 0, z);
      if (_contents.c != 0)
	{
	  unsigned char	*tmp;

	  tmp = NSZoneMalloc(z, _count);
	  memcpy(tmp, _contents.c, _count);
	  obj->_contents.c = tmp;
	}
      return obj;
    }
  else 
    {
      return RETAIN(self);
    }
}

- (const char *) cString
{
  return cString_c((ivars)self);
}

- (unsigned int) cStringLength
{
  return cStringLength_c((ivars)self);
}

- (NSData*) dataUsingEncoding: (NSStringEncoding)encoding
	 allowLossyConversion: (BOOL)flag
{
  return dataUsingEncoding_c((ivars)self, encoding, flag);
}

- (double) doubleValue
{
  return doubleValue_c((ivars)self);
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &_count];
  if (_count > 0)
    {
      [aCoder encodeValueOfObjCType: @encode(NSStringEncoding) at: &defEnc];
      [aCoder encodeArrayOfObjCType: @encode(unsigned char)
			      count: _count
				 at: _contents.c];
    }
}

- (NSStringEncoding) fastestEncoding
{
  return defEnc;
}

- (float) floatValue
{
  return doubleValue_c((ivars)self);
}

- (void) getCharacters: (unichar*)buffer
{
  getCharacters_c((ivars)self, buffer, (NSRange){0, _count});
}

- (void) getCharacters: (unichar*)buffer range: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  getCharacters_c((ivars)self, buffer, aRange);
}

- (void) getCString: (char*)buffer
{
  getCString_c((ivars)self, buffer, NSMaximumStringLength,
    (NSRange){0, _count}, 0);
}

- (void) getCString: (char*)buffer
	  maxLength: (unsigned int)maxLength
{
  getCString_c((ivars)self, buffer, maxLength, (NSRange){0, _count}, 0);
}

- (void) getCString: (char*)buffer
	  maxLength: (unsigned int)maxLength
	      range: (NSRange)aRange
     remainingRange: (NSRange*)leftoverRange
{
  GS_RANGE_CHECK(aRange, _count);
  getCString_c((ivars)self, buffer, maxLength, aRange, leftoverRange);
}

- (unsigned) hash
{
  if (self->_flags.hash == 0)
    {
      self->_flags.hash = (*hashImp)((id)self, hashSel);
    }
  return self->_flags.hash;
}

- (int) intValue
{
  return intValue_c((ivars)self);
}

- (BOOL) isEqual: (id)anObject
{
  return isEqual_c((ivars)self, anObject);
}

- (BOOL) isEqualToString: (NSString*)anObject
{
  return isEqual_c((ivars)self, anObject);
}

- (unsigned int) length
{
  return _count;
}

- (const char*) lossyCString
{
  return lossyCString_c((ivars)self);
}

- (id) mutableCopy
{
  GSMString	*obj = [GSMStringClass allocWithZone: NSDefaultMallocZone()];

  obj = [obj initWithCString: _contents.c length: _count];
  return obj;
}

- (id) mutableCopyWithZone: (NSZone*)z
{
  GSMString	*obj = [GSMStringClass allocWithZone: z];

  obj = [obj initWithCString: _contents.c length: _count];
  return obj;
}

- (NSRange) rangeOfComposedCharacterSequenceAtIndex: (unsigned)anIndex
{
  return rangeOfSequence_c((ivars)self, anIndex);
}

- (NSRange) rangeOfString: (NSString*)aString
		  options: (unsigned)mask
		    range: (NSRange)aRange
{
  return rangeOfString_c((ivars)self, aString, mask, aRange);
}

- (NSStringEncoding) smallestEncoding
{
  return defEnc;
}

- (NSString*) substringFromRange: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  return substring_c((ivars)self, aRange);
}

- (NSString*) substringWithRange: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  return substring_c((ivars)self, aRange);
}

// private method for Unicode level 3 implementation
- (int) _baseLength
{
  return _count;
} 

@end



@implementation	GSCSubString
- (void) dealloc
{
  RELEASE(_parent);
  [super dealloc];
}
@end



@implementation GSUString

+ (id) alloc
{
  return NSAllocateObject (self, 0, NSDefaultMallocZone());
}

+ (id) allocWithZone: (NSZone*)z
{
  return NSAllocateObject (self, 0, z);
}

+ (void) initialize
{
  setup();
}

- (BOOL) boolValue
{
  return boolValue_u((ivars)self);
}

- (BOOL) canBeConvertedToEncoding: (NSStringEncoding)enc
{
  return canBeConvertedToEncoding_u((ivars)self, enc);
}

- (unichar) characterAtIndex: (unsigned int)index
{
  return characterAtIndex_u((ivars)self, index);
}

- (NSComparisonResult) compare: (NSString*)aString
		       options: (unsigned int)mask
			 range: (NSRange)aRange
{
  return compare_u((ivars)self, aString, mask, aRange);
}

- (id) copy
{
  if (NSShouldRetainWithZone(self, NSDefaultMallocZone()) == NO)
    {
      GSUString	*obj;

      obj = (GSUString*)NSCopyObject(self, 0, NSDefaultMallocZone());
      if (_contents.u != 0)
	{
	  unichar	*tmp;

	  tmp = NSZoneMalloc(NSDefaultMallocZone(), _count*sizeof(unichar));
	  memcpy(tmp, _contents.u, _count*sizeof(unichar));
	  obj->_contents.u = tmp;
	}
      return obj;
    }
  else 
    {
      return RETAIN(self);
    }
}

- (id) copyWithZone: (NSZone*)z
{
  if (NSShouldRetainWithZone(self, z) == NO)
    {
      GSUString	*obj;

      obj = (GSUString*)NSCopyObject(self, 0, z);
      if (_contents.u != 0)
	{
	  unichar	*tmp;

	  tmp = NSZoneMalloc(z, _count*sizeof(unichar));
	  memcpy(tmp, _contents.u, _count*sizeof(unichar));
	  obj->_contents.u = tmp;
	}
      return obj;
    }
  else 
    {
      return RETAIN(self);
    }
}

- (const char *) cString
{
  return cString_u((ivars)self);
}

- (unsigned int) cStringLength
{
  return cStringLength_u((ivars)self);
}

- (NSData*) dataUsingEncoding: (NSStringEncoding)encoding
	 allowLossyConversion: (BOOL)flag
{
  return dataUsingEncoding_u((ivars)self, encoding, flag);
}

- (double) doubleValue
{
  return doubleValue_u((ivars)self);
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &_count];
  if (_count > 0)
    {
      NSStringEncoding	enc = NSUnicodeStringEncoding;

      [aCoder encodeValueOfObjCType: @encode(NSStringEncoding) at: &enc];
      [aCoder encodeArrayOfObjCType: @encode(unichar)
			      count: _count
				 at: _contents.u];
    }
}

- (NSStringEncoding) fastestEncoding
{
  return NSUnicodeStringEncoding;
}

- (float) floatValue
{
  return doubleValue_u((ivars)self);
}

- (void) getCharacters: (unichar*)buffer
{
  getCharacters_u((ivars)self, buffer, (NSRange){0, _count});
}

- (void) getCharacters: (unichar*)buffer range: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  getCharacters_u((ivars)self, buffer, aRange);
}

- (void) getCString: (char*)buffer
{
  getCString_u((ivars)self, buffer, NSMaximumStringLength,
    (NSRange){0, _count}, 0);
}

- (void) getCString: (char*)buffer
	  maxLength: (unsigned int)maxLength
{
  getCString_u((ivars)self, buffer, maxLength, (NSRange){0, _count}, 0);
}

- (void) getCString: (char*)buffer
	  maxLength: (unsigned int)maxLength
	      range: (NSRange)aRange
     remainingRange: (NSRange*)leftoverRange
{
  GS_RANGE_CHECK(aRange, _count);

  getCString_u((ivars)self, buffer, maxLength, aRange, leftoverRange);
}

- (unsigned) hash
{
  if (self->_flags.hash == 0)
    {
      self->_flags.hash = (*hashImp)((id)self, hashSel);
    }
  return self->_flags.hash;
}

- (int) intValue
{
  return intValue_u((ivars)self);
}

- (BOOL) isEqual: (id)anObject
{
  return isEqual_u((ivars)self, anObject);
}

- (BOOL) isEqualToString: (NSString*)anObject
{
  return isEqual_u((ivars)self, anObject);
}

- (unsigned int) length
{
  return _count;
}

- (const char*) lossyCString
{
  return lossyCString_u((ivars)self);
}

- (id) mutableCopy
{
  GSMString	*obj = [GSMStringClass allocWithZone: NSDefaultMallocZone()];

  obj = [obj initWithCharacters: _contents.u length: _count];
  return obj;
}

- (id) mutableCopyWithZone: (NSZone*)z
{
  GSMString	*obj = [GSMStringClass allocWithZone: z];

  obj = [obj initWithCharacters: _contents.u length: _count];
  return obj;
}

- (NSRange) rangeOfComposedCharacterSequenceAtIndex: (unsigned)anIndex
{
  return rangeOfSequence_u((ivars)self, anIndex);
}

- (NSRange) rangeOfString: (NSString*)aString
		  options: (unsigned)mask
		    range: (NSRange)aRange
{
  return rangeOfString_u((ivars)self, aString, mask, aRange);
}

- (NSStringEncoding) smallestEncoding
{
  return NSUnicodeStringEncoding;
}

- (NSString*) substringFromRange: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  return substring_u((ivars)self, aRange);
}

- (NSString*) substringWithRange: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  return substring_u((ivars)self, aRange);
}

// private method for Unicode level 3 implementation
- (int) _baseLength
{
  int count = 0;
  int blen = 0;

  while (count < _count)
    if (!uni_isnonsp(_contents.u[count++]))
      blen++;
  return blen;
} 

@end



@implementation	GSUSubString
- (void) dealloc
{
  RELEASE(_parent);
  [super dealloc];
}
@end



@implementation GSMString

+ (id) alloc
{
  return NSAllocateObject (self, 0, NSDefaultMallocZone());
}

+ (id) allocWithZone: (NSZone*)z
{
  return NSAllocateObject (self, 0, z);
}

+ (void) initialize
{
  setup();
}

- (BOOL) boolValue
{
  if (_flags.wide == 1)
    return boolValue_u((ivars)self);
  else
    return boolValue_c((ivars)self);
}

- (BOOL) canBeConvertedToEncoding: (NSStringEncoding)enc
{
  if (_flags.wide == 1)
    return canBeConvertedToEncoding_u((ivars)self, enc);
  else
    return canBeConvertedToEncoding_c((ivars)self, enc);
}

- (unichar) characterAtIndex: (unsigned int)index
{
  if (_flags.wide == 1)
    return characterAtIndex_u((ivars)self, index);
  else
    return characterAtIndex_c((ivars)self, index);
}

- (NSComparisonResult) compare: (NSString*)aString
		       options: (unsigned int)mask
			 range: (NSRange)aRange
{
  if (_flags.wide == 1)
    return compare_u((ivars)self, aString, mask, aRange);
  else
    return compare_c((ivars)self, aString, mask, aRange);
}

- (id) copy
{
  id	copy;

  if (_flags.wide == 1)
    {
      copy = [GSUStringClass allocWithZone: NSDefaultMallocZone()];
      copy = [copy initWithCharacters: _contents.u length: _count];
    }
  else
    {
      copy = [GSCStringClass allocWithZone: NSDefaultMallocZone()];
      copy = [copy initWithCString: _contents.c length: _count];
    }
  return copy;
}

- (id) copyWithZone: (NSZone*)z
{
  id	copy;

  if (_flags.wide == 1)
    {
      copy = [GSUStringClass allocWithZone: z];
      copy = [copy initWithCharacters: _contents.u length: _count];
    }
  else
    {
      copy = [GSCStringClass allocWithZone: z];
      copy = [copy initWithCString: _contents.c length: _count];
    }
  return copy;
}

- (const char *) cString
{
  if (_flags.wide == 1)
    return cString_u((ivars)self);
  else
    return cString_c((ivars)self);
}

- (unsigned int) cStringLength
{
  if (_flags.wide == 1)
    return cStringLength_u((ivars)self);
  else
    return cStringLength_c((ivars)self);
}

- (NSData*) dataUsingEncoding: (NSStringEncoding)encoding
	 allowLossyConversion: (BOOL)flag
{
  if (_flags.wide == 1)
    return dataUsingEncoding_u((ivars)self, encoding, flag);
  else
    return dataUsingEncoding_c((ivars)self, encoding, flag);
}

- (void) dealloc
{
  if (_flags.free == 1 && _zone != 0 && _contents.c != 0)
    {
      NSZoneFree(self->_zone, self->_contents.c);
      self->_contents.c = 0;
      self->_zone = 0;
    }
  [super dealloc];
}

- (void) deleteCharactersInRange: (NSRange)range
{
  GS_RANGE_CHECK(range, _count);
  fillHole((ivars)self, range.location, range.length);
}

- (double) doubleValue
{
  if (_flags.wide == 1)
    return doubleValue_u((ivars)self);
  else
    return doubleValue_c((ivars)self);
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &_count];
  if (_count > 0)
    {
      if (_flags.wide == 1)
	{
	  NSStringEncoding	enc = NSUnicodeStringEncoding;

	  [aCoder encodeValueOfObjCType: @encode(NSStringEncoding) at: &enc];
	  [aCoder encodeArrayOfObjCType: @encode(unichar)
				  count: _count
				     at: _contents.u];
	}
      else
	{
	  [aCoder encodeValueOfObjCType: @encode(NSStringEncoding) at: &defEnc];
	  [aCoder encodeArrayOfObjCType: @encode(unsigned char)
				  count: _count
				     at: _contents.c];
	}
    }
}

- (NSStringEncoding) fastestEncoding
{
  if (_flags.wide == 1)
    return NSUnicodeStringEncoding;
  else
    return defEnc;
}

- (float) floatValue
{
  if (_flags.wide == 1)
    return doubleValue_u((ivars)self);
  else
    return doubleValue_c((ivars)self);
}

- (void) getCharacters: (unichar*)buffer
{
  if (_flags.wide == 1)
    getCharacters_u((ivars)self, buffer, (NSRange){0, _count});
  else
    getCharacters_c((ivars)self, buffer, (NSRange){0, _count});
}

- (void) getCharacters: (unichar*)buffer range: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  if (_flags.wide == 1)
    {
      getCharacters_u((ivars)self, buffer, aRange);
    }
  else
    {
      getCharacters_c((ivars)self, buffer, aRange);
    }
}

- (void) getCString: (char*)buffer
{
  if (_flags.wide == 1)
    getCString_u((ivars)self, buffer, NSMaximumStringLength,
      (NSRange){0, _count}, 0);
  else
    getCString_c((ivars)self, buffer, NSMaximumStringLength,
      (NSRange){0, _count}, 0);
}

- (void) getCString: (char*)buffer
	  maxLength: (unsigned int)maxLength
{
  if (_flags.wide == 1)
    getCString_u((ivars)self, buffer, maxLength, (NSRange){0, _count}, 0);
  else
    getCString_c((ivars)self, buffer, maxLength, (NSRange){0, _count}, 0);
}

- (void) getCString: (char*)buffer
	  maxLength: (unsigned int)maxLength
	      range: (NSRange)aRange
     remainingRange: (NSRange*)leftoverRange
{
  GS_RANGE_CHECK(aRange, _count);
  if (_flags.wide == 1)
    {
      getCString_u((ivars)self, buffer, maxLength, aRange, leftoverRange);
    }
  else
    {
      getCString_c((ivars)self, buffer, maxLength, aRange, leftoverRange);
    }
}

- (unsigned) hash
{
  if (self->_flags.hash == 0)
    {
      self->_flags.hash = (*hashImp)((id)self, hashSel);
    }
  return self->_flags.hash;
}

- (id) init
{
  return [self initWithCapacity: 0];
}

- (id) initWithCapacity: (unsigned)capacity
{
  if (capacity < 2)
    {
      capacity = 2;
    }
  _count = 0;
  _capacity = capacity;
#if	GS_WITH_GC
  _zone = GSAtomicMallocZone();
#else
  _zone = fastZone(self);
#endif
  _contents.c = NSZoneMalloc(_zone, capacity + 1);
  _flags.wide = 0;
  _flags.free = 1;
  return self;
}

- (id) initWithCharactersNoCopy: (unichar*)chars
			 length: (unsigned int)length
		   freeWhenDone: (BOOL)flag
{
  _count = length;
  _capacity = length;
  _contents.u = chars;
  _flags.wide = 1;
  if (flag == YES && chars != 0)
    {
#if	GS_WITH_GC
      _zone = GSAtomicMallocZone();
#else
      _zone = NSZoneFromPointer(chars);
#endif
      _flags.free = 1;
    }
  else
    {
      _zone = 0;
    }
  return self;
}

- (id) initWithCStringNoCopy: (char*)byteString
		      length: (unsigned int)length
	        freeWhenDone: (BOOL)flag
{
  _count = length;
  _capacity = length;
  _contents.c = byteString;
  _flags.wide = 0;
  if (flag == YES && byteString != 0)
    {
#if	GS_WITH_GC
      _zone = GSAtomicMallocZone();
#else
      _zone = NSZoneFromPointer(byteString);
#endif
      _flags.free = 1;
    }
  else
    {
      _zone = 0;
    }
  return self;
}

- (int) intValue
{
  if (_flags.wide == 1)
    return intValue_u((ivars)self);
  else
    return intValue_c((ivars)self);
}

- (BOOL) isEqual: (id)anObject
{
  if (_flags.wide == 1)
    return isEqual_u((ivars)self, anObject);
  else
    return isEqual_c((ivars)self, anObject);
}

- (BOOL) isEqualToString: (NSString*)anObject
{
  if (_flags.wide == 1)
    return isEqual_u((ivars)self, anObject);
  else
    return isEqual_c((ivars)self, anObject);
}

- (unsigned int) length
{
  return _count;
}

- (const char*) lossyCString
{
  if (_flags.wide == 1)
    return lossyCString_u((ivars)self);
  else
    return lossyCString_c((ivars)self);
}

- (id) mutableCopy
{
  GSMString	*obj = [GSMStringClass allocWithZone: NSDefaultMallocZone()];

  if (_flags.wide == 1)
    obj = [obj initWithCharacters: _contents.u length: _count];
  else
    obj = [obj initWithCString: _contents.c length: _count];
  return obj;
}

- (id) mutableCopyWithZone: (NSZone*)z
{
  GSMString	*obj = [GSMStringClass allocWithZone: z];

  if (_flags.wide == 1)
    obj = [obj initWithCharacters: _contents.u length: _count];
  else
    obj = [obj initWithCString: _contents.c length: _count];
  return obj;
}

- (NSRange) rangeOfComposedCharacterSequenceAtIndex: (unsigned)anIndex
{
  if (_flags.wide == 1)
    return rangeOfSequence_u((ivars)self, anIndex);
  else
    return rangeOfSequence_c((ivars)self, anIndex);
}

- (NSRange) rangeOfString: (NSString*)aString
		  options: (unsigned)mask
		    range: (NSRange)aRange
{
  if (_flags.wide == 1)
    return rangeOfString_u((ivars)self, aString, mask, aRange);
  else
    return rangeOfString_c((ivars)self, aString, mask, aRange);
}

- (void) replaceCharactersInRange: (NSRange)aRange
		       withString: (NSString*)aString
{
  int		offset;
  unsigned	length;

  GS_RANGE_CHECK(aRange, _count);

  length = (aString == nil) ? 0 : [aString length];
  offset = length - aRange.length;

  if (offset < 0)
    {
      fillHole((ivars)self, NSMaxRange(aRange) + offset, -offset);
    }
  else if (offset > 0)
    {
      makeHole((ivars)self, NSMaxRange(aRange), offset);
    }

  if (length > 0)
    {
      ivars	other = transmute((ivars)self, aString);

      if (_flags.wide == 1)
	{
	  if (other == 0)
	    {
	      /*
	       * Not a cString class - use standard method to get characters.
	       */
	      [aString getCharacters: &_contents.u[aRange.location]];
	    }
	  else
	    {
	      memcpy(&_contents.u[aRange.location], other->_contents.u,
		length * sizeof(unichar));
	    }
	}
      else
	{
	  if (other == 0)
	    {
	      unsigned	l;

	      /*
	       * Since getCString appends a '\0' terminator, we must ask for
	       * one character less than we actually want, then get the last
	       * character separately.
	       */
	      l = length - 1;
	      if (l > 0)
		{
		  [aString getCString: &_contents.c[aRange.location]
			    maxLength: l];
		}
	      _contents.c[aRange.location + l]
		= encode_unitochar([aString characterAtIndex: l], defEnc);
	    }
	  else
	    {
	      /*
	       * Simply copy cString data from other string into self.
	       */
	      memcpy(&_contents.c[aRange.location], other->_contents.c, length);
	    }
	}
      _flags.hash = 0;
    }
}

- (void) setString: (NSString*)aString
{
  int	len = (aString == nil) ? 0 : [aString length];
  ivars	other;

  if (len == 0)
    {
      _count = 0;
      return;
    }
  other = transmute((ivars)self, aString);
  if (_count < len)
    {
      makeHole((ivars)self, _count, len - _count);
    }
  else
    {
      _count = len;
      _flags.hash = 0;
    }

  if (_flags.wide == 1)
    {
      if (other == 0)
	{
	  [aString getCharacters: _contents.u];
	}
      else
	{
	  memcpy(_contents.u, other->_contents.u, len * sizeof(unichar));
	}
    }
  else
    {
      if (other == 0)
	{
	  unsigned	l;

	  /*
	   * Since getCString appends a '\0' terminator, we must ask for
	   * one character less than we actually want, then get the last
	   * character separately.
	   */
	  l = len - 1;
	  if (l > 0)
	    {
	      [aString getCString: _contents.c maxLength: l];
	    }
	  _contents.c[l]
	    = encode_unitochar([aString characterAtIndex: l], defEnc);
	}
      else
	{
	  memcpy(_contents.c, other->_contents.c, len);
	}
    }
}

- (NSStringEncoding) smallestEncoding
{
  if (_flags.wide == 1)
    {
      return NSUnicodeStringEncoding;
    }
  else
    return defEnc;
}

- (NSString*) substringFromRange: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  
  if (_flags.wide == 1)
    {
      return [GSUStringClass stringWithCharacters:
	self->_contents.u + aRange.location length: aRange.length];
    }
  else
    {
      return [GSCStringClass stringWithCString:
	self->_contents.c + aRange.location length: aRange.length];
    }
}

- (NSString*) substringWithRange: (NSRange)aRange
{
  GS_RANGE_CHECK(aRange, _count);
  
  if (_flags.wide == 1)
    {
      return [GSUStringClass stringWithCharacters:
	self->_contents.u + aRange.location length: aRange.length];
    }
  else
    {
      return [GSCStringClass stringWithCString:
	self->_contents.c + aRange.location length: aRange.length];
    }
}

// private method for Unicode level 3 implementation
- (int) _baseLength
{
  if (_flags.wide == 1)
    {
      int count = 0;
      int blen = 0;

      while (count < _count)
	if (!uni_isnonsp(_contents.u[count++]))
	  blen++;
      return blen;
    }
  else
    return _count;
} 

@end



@implementation NXConstantString

+ (id) alloc
{
  [NSException raise: NSGenericException
	      format: @"Attempt to allocate an NXConstantString"];
  return nil;
}

+ (id) allocWithZone: (NSZone*)z
{
  [NSException raise: NSGenericException
	      format: @"Attempt to allocate an NXConstantString"];
  return nil;
}

+ (void) initialize
{
  if (self == [NXConstantString class])
    {
      behavior_class_add_class(self, [GSCString class]);
    }
}

- (id) initWithCharacters: (unichar*)byteString
		   length: (unsigned int)length
	     freeWhenDone: (BOOL)flag
{
  [NSException raise: NSGenericException
	      format: @"Attempt to init an NXConstantString"];
  return nil;
}

- (id) initWithCStringNoCopy: (char*)byteString
		      length: (unsigned int)length
		freeWhenDone: (BOOL)flag
{
  [NSException raise: NSGenericException
	      format: @"Attempt to init an NXConstantString"];
  return nil;
}

- (void) dealloc
{
}

- (const char*) cString
{
  return (const char*)_contents.c;
}

- (id) retain
{
  return self;
}

- (oneway void) release
{
  return;
}

- (id) autorelease
{
  return self;
}

- (id) copy
{
  return self;
}

- (id) copyWithZone: (NSZone*)z
{
  return self;
}

- (NSZone*) zone
{
  return NSDefaultMallocZone();
}

- (NSStringEncoding) fastestEncoding
{
  return NSASCIIStringEncoding;
}

- (NSStringEncoding) smallestEncoding
{
  return NSASCIIStringEncoding;
}


/*
 * Return a 28-bit hash value for the string contents - this
 * MUST match the algorithm used by the NSString base class.
 */
- (unsigned) hash
{
  unsigned ret = 0;

  int len = _count;

  if (len > NSHashStringLength)
    len = NSHashStringLength;
  if (len)
    {
      const unsigned char	*p;
      unsigned			char_count = 0;

      p = _contents.c;
      while (*p != 0 && char_count++ < NSHashStringLength)
	{
	  unichar	c = *p++;

	  if (c > 127)
	    {
	      c = encode_chartouni(c, defEnc);
	    }
	  ret = (ret << 5) + ret + c;
	}

      /*
       * The hash caching in our concrete string classes uses zero to denote
       * an empty cache value, so we MUST NOT return a hash of zero.
       */
      if (ret == 0)
	ret = 0x0fffffff;
      else
	ret &= 0x0fffffff;
    }
  else
    {
      ret = 0x0ffffffe;	/* Hash for an empty string.	*/
    }
  return ret;
}

- (BOOL) isEqual: (id)anObject
{
  Class	c;

  if (anObject == self)
    {
      return YES;
    }
  if (anObject == nil)
    {
      return NO;
    }
  if (fastIsInstance(anObject) == NO)
    {
      return NO;
    }
  c = fastClassOfInstance(anObject);

  if (fastClassIsKindOfClass(c, GSCStringClass) == YES
    || c == NXConstantStringClass
    || (c == GSMStringClass && ((ivars)anObject)->_flags.wide == 0))
    {
      ivars	other = (ivars)anObject;

      if (_count != other->_count)
	return NO;
      if (memcmp(_contents.c, other->_contents.c, _count) != 0)
	return NO;
      return YES;
    }
  else if (fastClassIsKindOfClass(c, GSUStringClass) == YES
    || c == GSMStringClass)
    {
      if (strCompCsUs(self, anObject, 0, (NSRange){0,_count}) == NSOrderedSame)
	return YES;
      return NO;
    }
  else if (fastClassIsKindOfClass(c, NSStringClass))
    {
      return (*equalImp)(self, equalSel, anObject);
    }
  else
    {
      return NO;
    }
}

- (BOOL) isEqualToString: (NSString*)anObject
{
  Class	c;

  if (anObject == self)
    {
      return YES;
    }
  if (anObject == nil)
    {
      return NO;
    }
  if (fastIsInstance(anObject) == NO)
    {
      return NO;
    }
  c = fastClassOfInstance(anObject);

  if (fastClassIsKindOfClass(c, GSCStringClass) == YES
    || c == NXConstantStringClass
    || (c == GSMStringClass && ((ivars)anObject)->_flags.wide == 0))
    {
      ivars	other = (ivars)anObject;

      if (_count != other->_count)
	return NO;
      if (memcmp(_contents.c, other->_contents.c, _count) != 0)
	return NO;
      return YES;
    }
  else if (fastClassIsKindOfClass(c, GSUStringClass) == YES
    || c == GSMStringClass)
    {
      if (strCompCsUs(self, anObject, 0, (NSRange){0,_count}) == NSOrderedSame)
	return YES;
      return NO;
    }
  else if (fastClassIsKindOfClass(c, NSStringClass))
    {
      return (*equalImp)(self, equalSel, anObject);
    }
  else
    {
      return NO;
    }
}

@end


/*
 * Some classes for backward compatibility with archives.
 */
@interface	NSGCString : NSString
@end
@implementation	NSGCString
- (id) initWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  RELEASE(self);
  self = [GSCString alloc];
  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
  if (count > 0)
    {
      unsigned char	*chars;

      chars = NSZoneMalloc(NSDefaultMallocZone(), count+1);
      [aCoder decodeArrayOfObjCType: @encode(unsigned char)
			      count: count
				 at: chars];
      self = [self initWithCStringNoCopy: chars
				  length: count
			    freeWhenDone: YES];
    }
  else
    {
      self = [self initWithCStringNoCopy: 0 length: 0 freeWhenDone: NO];
    }
  return self;
}
@end

@interface	NSGMutableCString : NSMutableString
@end
@implementation	NSGMutableCString
- (id) initWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  RELEASE(self);
  self = [GSMString alloc];
  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
  if (count > 0)
    {
      unsigned char	*chars;

      chars = NSZoneMalloc(NSDefaultMallocZone(), count+1);
      [aCoder decodeArrayOfObjCType: @encode(unsigned char)
			      count: count
				 at: chars];
      self = [self initWithCStringNoCopy: chars
				  length: count
			    freeWhenDone: YES];
    }
  else
    {
      self = [self initWithCStringNoCopy: 0 length: 0 freeWhenDone: NO];
    }
  return self;
}
@end

@interface	NSGString : NSString
@end
@implementation	NSGString
- (id) initWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  RELEASE(self);
  self = [GSUString alloc];
  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
  if (count > 0)
    {
      unichar	*chars;

      chars = NSZoneMalloc(NSDefaultMallocZone(), count*sizeof(unichar));
      [aCoder decodeArrayOfObjCType: @encode(unichar)
			      count: count
				 at: chars];
      self = [self initWithCharactersNoCopy: chars
				     length: count
			       freeWhenDone: YES];
    }
  else
    {
      self = [self initWithCharactersNoCopy: 0 length: 0 freeWhenDone: NO];
    }
  return self;
}
@end

@interface	NSGMutableString : NSMutableString
@end
@implementation	NSGMutableString
- (id) initWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  RELEASE(self);
  self = [GSMString alloc];
  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
  if (count > 0)
    {
      unichar	*chars;

      chars = NSZoneMalloc(NSDefaultMallocZone(), count*sizeof(unichar));
      [aCoder decodeArrayOfObjCType: @encode(unichar)
			      count: count
				 at: chars];
      self = [self initWithCharactersNoCopy: chars
				     length: count
			       freeWhenDone: YES];
    }
  else
    {
      self = [self initWithCharactersNoCopy: 0 length: 0 freeWhenDone: NO];
    }
  return self;
}
@end

