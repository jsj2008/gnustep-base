/** All of the external data
   Copyright (C) 1997 Free Software Foundation, Inc.
   
   Written by:  Scott Christley <scottc@net-community.com>
   Date: August 1997
   
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
#include <Foundation/NSString.h>


#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSMapTable.h>
#include "NSCallBacks.h"
#include <Foundation/NSHashTable.h>

/* Global lock to be used by classes when operating on any global
   data that invoke other methods which also access global; thus,
   creating the potential for deadlock. */
@class	NSRecursiveLock;
NSRecursiveLock *gnustep_global_lock = nil;

/*
 * Connection Notification Strings.
 */
NSString *NSConnectionDidDieNotification;

NSString *NSConnectionDidInitializeNotification;


/*
 * NSThread Notifications
 */
NSString *NSWillBecomeMultiThreadedNotification;

NSString *NSThreadDidStartNotification;

NSString *NSThreadWillExitNotification;


/*
 * Port Notifications
 */
NSString *PortBecameInvalidNotification;

NSString *InPortClientBecameInvalidNotification;

NSString *InPortAcceptedClientNotification;


NSString *NSPortDidBecomeInvalidNotification;



/* RunLoop modes */
NSString *NSDefaultRunLoopMode;

NSString *NSConnectionReplyMode;



/* Exceptions */
NSString * const NSCharacterConversionException;

NSString * const NSGenericException;

NSString * const NSInternalInconsistencyException;

NSString * const NSInvalidArgumentException;

NSString * const NSMallocException;

NSString * const NSRangeException;


/* Exception handler */
NSUncaughtExceptionHandler *_NSUncaughtExceptionHandler;

/* NSBundle */
NSString *NSBundleDidLoadNotification;

NSString *NSShowNonLocalizedStrings;

NSString *NSLoadedClasses;


/* Stream */
NSString *StreamException;


/*
 * File attributes names
 */

/* File Attributes */

NSString *NSFileDeviceIdentifier;

NSString *NSFileGroupOwnerAccountName;

NSString *NSFileGroupOwnerAccountNumber;

NSString *NSFileModificationDate;

NSString *NSFileOwnerAccountName;

NSString *NSFileOwnerAccountNumber;

NSString *NSFilePosixPermissions;

NSString *NSFileReferenceCount;

NSString *NSFileSize;

NSString *NSFileSystemFileNumber;

NSString *NSFileSystemNumber;

NSString *NSFileType;


/* File Types */

NSString *NSFileTypeDirectory;

NSString *NSFileTypeRegular;

NSString *NSFileTypeSymbolicLink;

NSString *NSFileTypeSocket;

NSString *NSFileTypeFifo;

NSString *NSFileTypeCharacterSpecial;

NSString *NSFileTypeBlockSpecial;

NSString *NSFileTypeUnknown;


/* FileSystem Attributes */

NSString *NSFileSystemSize;

NSString *NSFileSystemFreeSize;

NSString *NSFileSystemNodes;

NSString *NSFileSystemFreeNodes;


/* Standard domains */
NSString *NSArgumentDomain;

NSString *NSGlobalDomain;

NSString *NSRegistrationDomain;


/* Public notification */
NSString *NSUserDefaultsDidChangeNotification;


/* Keys for language-dependent information */
NSString *NSWeekDayNameArray;

NSString *NSShortWeekDayNameArray;

NSString *NSMonthNameArray;

NSString *NSShortMonthNameArray;

NSString *NSTimeFormatString;

NSString *NSDateFormatString;

NSString *NSShortDateFormatString;

NSString *NSTimeDateFormatString;

NSString *NSShortTimeDateFormatString;

NSString *NSCurrencySymbol;

NSString *NSDecimalSeparator;

NSString *NSThousandsSeparator;

NSString *NSInternationalCurrencyString;

NSString *NSCurrencyString;

NSString *NSNegativeCurrencyFormatString;

NSString *NSPositiveCurrencyFormatString;

NSString *NSDecimalDigits;

NSString *NSAMPMDesignation;


NSString *NSHourNameDesignations;

NSString *NSYearMonthWeekDesignations;

NSString *NSEarlierTimeDesignations;

NSString *NSLaterTimeDesignations;

NSString *NSThisDayDesignations;

NSString *NSNextDayDesignations;

NSString *NSNextNextDayDesignations;

NSString *NSPriorDayDesignations;

NSString *NSDateTimeOrdering;


/* These are in OPENSTEP 4.2 */
NSString *NSLanguageCode;

NSString *NSLanguageName;

NSString *NSFormalName;

/* For GNUstep */
NSString *NSLocale;


/*
 * Keys for the NSDictionary returned by [NSConnection -statistics]
 */
/* These in OPENSTEP 4.2 */
NSString *NSConnectionRepliesReceived;

NSString *NSConnectionRepliesSent;

NSString *NSConnectionRequestsReceived;

NSString *NSConnectionRequestsSent;

/* These Are GNUstep extras */
NSString *NSConnectionLocalCount;

NSString *NSConnectionProxyCount;

/*
 * Keys for NSURLHandle
 */
NSString *NSHTTPPropertyStatusCodeKey;

NSString *NSHTTPPropertyStatusReasonKey;

NSString *NSHTTPPropertyServerHTTPVersionKey;
 
NSString *NSHTTPPropertyRedirectionHeadersKey;

NSString *NSHTTPPropertyErrorPageDataKey;
 
/* These are GNUstep extras */
NSString *GSHTTPPropertyMethodKey;

NSString *GSHTTPPropertyProxyHostKey;

NSString *GSHTTPPropertyProxyPortKey;
 

/* Class description notification */
NSString *NSClassDescriptionNeededForClassNotification;


/*
 *	Setup function called when NSString is initialised.
 *	We make all the constant strings not be constant strings so they can
 *	cache their hash values and be used much more efficiently as keys in
 *	dictionaries etc.
 */
void
GSBuildStrings()
{
  static Class	SClass = 0;

  if (SClass == 0)
    {
      SClass = [NSString class];

      /*
       * Ensure that NSString is initialized ... because we are called
       * from [NSObject +initialize] which might be executing as a
       * result of a call to [NSString +initialize] !
       */
      [SClass initialize];

      InPortAcceptedClientNotification
	= [[SClass alloc] initWithCString:
	"InPortAcceptedClientNotification"];
      InPortClientBecameInvalidNotification
	= [[SClass alloc] initWithCString:
	"InPortClientBecameInvalidNotification"];
      NSAMPMDesignation
	= [[SClass alloc] initWithCString: "NSAMPMDesignation"];
      NSArgumentDomain
	= [[SClass alloc] initWithCString: "NSArgumentDomain"];
      NSBundleDidLoadNotification
	= [[SClass alloc] initWithCString: "NSBundleDidLoadNotification"];
      *(NSString**)&NSCharacterConversionException
	= [[SClass alloc] initWithCString:
	"NSCharacterConversionException"];
      NSConnectionDidDieNotification
	= [[SClass alloc] initWithCString:
	"NSConnectionDidDieNotification"];
      NSConnectionDidInitializeNotification
	= [[SClass alloc] initWithCString:
	"NSConnectionDidInitializeNotification"];
      NSConnectionLocalCount
	= [[SClass alloc] initWithCString: "NSConnectionLocalCount"];
      NSConnectionProxyCount
	= [[SClass alloc] initWithCString: "NSConnectionProxyCount"];
      NSConnectionRepliesReceived
	= [[SClass alloc] initWithCString: "NSConnectionRepliesReceived"];
      NSConnectionRepliesSent
	= [[SClass alloc] initWithCString: "NSConnectionRepliesSent"];
      NSConnectionReplyMode
	= [[SClass alloc] initWithCString: "NSConnectionReplyMode"];
      NSConnectionRequestsReceived
	= [[SClass alloc] initWithCString: "NSConnectionRequestsReceived"];
      NSConnectionRequestsSent
	= [[SClass alloc] initWithCString: "NSConnectionRequestsSent"];
      NSCurrencyString
	= [[SClass alloc] initWithCString: "NSCurrencyString"];
      NSCurrencySymbol
	= [[SClass alloc] initWithCString: "NSCurrencySymbol"];
      NSDateFormatString
	= [[SClass alloc] initWithCString: "NSDateFormatString"];
      NSDateTimeOrdering
	= [[SClass alloc] initWithCString: "NSDateTimeOrdering"];
      NSDecimalDigits
	= [[SClass alloc] initWithCString: "NSDecimalDigits"];
      NSDecimalSeparator
	= [[SClass alloc] initWithCString: "NSDecimalSeparator"];
      NSDefaultRunLoopMode
	= [[SClass alloc] initWithCString: "NSDefaultRunLoopMode"];
      NSEarlierTimeDesignations
	= [[SClass alloc] initWithCString: "NSEarlierTimeDesignations"];
      NSFileDeviceIdentifier
	= [[SClass alloc] initWithCString: "NSFileDeviceIdentifier"];
      NSFileGroupOwnerAccountName
	= [[SClass alloc] initWithCString: "NSFileGroupOwnerAccountName"];
      NSFileGroupOwnerAccountNumber
	= [[SClass alloc] initWithCString: "NSFileGroupOwnerAccountNumber"];
      NSFileModificationDate
	= [[SClass alloc] initWithCString: "NSFileModificationDate"];
      NSFileOwnerAccountName
	= [[SClass alloc] initWithCString: "NSFileOwnerAccountName"];
      NSFileOwnerAccountNumber
	= [[SClass alloc] initWithCString: "NSFileOwnerAccountNumber"];
      NSFilePosixPermissions
	= [[SClass alloc] initWithCString: "NSFilePosixPermissions"];
      NSFileReferenceCount
	= [[SClass alloc] initWithCString: "NSFileReferenceCount"];
      NSFileSize
	= [[SClass alloc] initWithCString: "NSFileSize"];
      NSFileSystemFileNumber
	= [[SClass alloc] initWithCString: "NSFileSystemFileNumber"];
      NSFileSystemFreeNodes
	= [[SClass alloc] initWithCString: "NSFileSystemFreeNodes"];
      NSFileSystemFreeSize
	= [[SClass alloc] initWithCString: "NSFileSystemFreeSize"];
      NSFileSystemNodes
	= [[SClass alloc] initWithCString: "NSFileSystemNodes"];
      NSFileSystemNumber
	= [[SClass alloc] initWithCString: "NSFileSystemNumber"];
      NSFileSystemSize
	= [[SClass alloc] initWithCString: "NSFileSystemSize"];
      NSFileType
	= [[SClass alloc] initWithCString: "NSFileType"];
      NSFileTypeBlockSpecial
	= [[SClass alloc] initWithCString: "NSFileTypeBlockSpecial"];
      NSFileTypeCharacterSpecial
	= [[SClass alloc] initWithCString: "NSFileTypeCharacterSpecial"];
      NSFileTypeDirectory
	= [[SClass alloc] initWithCString: "NSFileTypeDirectory"];
      NSFileTypeFifo
	= [[SClass alloc] initWithCString: "NSFileTypeFifo"];
      NSFileTypeRegular
	= [[SClass alloc] initWithCString: "NSFileTypeRegular"];
      NSFileTypeSocket
	= [[SClass alloc] initWithCString: "NSFileTypeSocket"];
      NSFileTypeSymbolicLink
	= [[SClass alloc] initWithCString: "NSFileTypeSymbolicLink"];
      NSFileTypeUnknown
	= [[SClass alloc] initWithCString: "NSFileTypeUnknown"];
      NSFormalName
        = [[SClass alloc] initWithCString: "NSFormalName"];
      *(NSString**)&NSGenericException
	= [[SClass alloc] initWithCString: "NSGenericException"];
      NSGlobalDomain
	= [[SClass alloc] initWithCString: "NSGlobalDomain"];
      NSHourNameDesignations
	= [[SClass alloc] initWithCString: "NSHourNameDesignations"];
      *(NSString**)&NSInternalInconsistencyException
	= [[SClass alloc] initWithCString:
	"NSInternalInconsistencyException"];
      NSInternationalCurrencyString
	= [[SClass alloc] initWithCString: "NSInternationalCurrencyString"];
      *(NSString**)&NSInvalidArgumentException
	= [[SClass alloc] initWithCString: "NSInvalidArgumentException"];
      NSLanguageCode
        = [[SClass alloc] initWithCString: "NSLanguageCode"];
      NSLanguageName
        = [[SClass alloc] initWithCString: "NSLanguageName"];
      NSLaterTimeDesignations
	= [[SClass alloc] initWithCString: "NSLaterTimeDesignations"];
      NSLoadedClasses
	= [[SClass alloc] initWithCString: "NSLoadedClasses"];
      NSLocale
	= [[SClass alloc] initWithCString: "NSLocale"];
      *(NSString**)&NSMallocException
	= [[SClass alloc] initWithCString: "NSMallocException"];
      NSMonthNameArray
	= [[SClass alloc] initWithCString: "NSMonthNameArray"];
      NSNegativeCurrencyFormatString
        = [[SClass alloc] initWithCString:
	"NSNegativeCurrencyFormatString"];
      NSNextDayDesignations
	= [[SClass alloc] initWithCString: "NSNextDayDesignations"];
      NSNextNextDayDesignations
	= [[SClass alloc] initWithCString: "NSNextNextDayDesignations"];
      NSPortDidBecomeInvalidNotification
	= [[SClass alloc] initWithCString:
	"NSPortDidBecomeInvalidNotification"];
      NSPositiveCurrencyFormatString
        = [[SClass alloc] initWithCString:
	"NSPositiveCurrencyFormatString"];
      NSPriorDayDesignations
	= [[SClass alloc] initWithCString: "NSPriorDayDesignations"];
      *(NSString**)&NSRangeException
	= [[SClass alloc] initWithCString: "NSRangeException"];
      NSRegistrationDomain
	= [[SClass alloc] initWithCString: "NSRegistrationDomain"];
      NSShortDateFormatString
        = [[SClass alloc] initWithCString: "NSShortDateFormatString"];
      NSShortMonthNameArray
	= [[SClass alloc] initWithCString: "NSShortMonthNameArray"];
      NSShortTimeDateFormatString
	= [[SClass alloc] initWithCString: "NSShortTimeDateFormatString"];
      NSShortWeekDayNameArray
	= [[SClass alloc] initWithCString: "NSShortWeekDayNameArray"];
      NSShowNonLocalizedStrings
	= [[SClass alloc] initWithCString: "NSShowNonLocalizedStrings"];
      NSThisDayDesignations
	= [[SClass alloc] initWithCString: "NSThisDayDesignations"];
      NSThousandsSeparator
	= [[SClass alloc] initWithCString: "NSThousandsSeparator"];
      NSThreadDidStartNotification
	= [[SClass alloc] initWithCString: "NSThreadDidStartNotification"];
      NSThreadWillExitNotification
	= [[SClass alloc] initWithCString: "NSThreadWillExitNotification"];
      NSTimeDateFormatString
	= [[SClass alloc] initWithCString: "NSTimeDateFormatString"];
      NSTimeFormatString
	= [[SClass alloc] initWithCString: "NSTimeFormatString"];
      NSUserDefaultsDidChangeNotification
	= [[SClass alloc] initWithCString:
	"NSUserDefaultsDidChangeNotification"];
      NSWeekDayNameArray
	= [[SClass alloc] initWithCString: "NSWeekDayNameArray"];
      NSWillBecomeMultiThreadedNotification
	= [[SClass alloc] initWithCString:
	"NSWillBecomeMultiThreadedNotification"];
      NSYearMonthWeekDesignations
	= [[SClass alloc] initWithCString: "NSYearMonthWeekDesignations"];
      PortBecameInvalidNotification
	= [[SClass alloc] initWithCString: "PortBecameInvalidNotification"];
      StreamException
	= [[SClass alloc] initWithCString: "StreamException"];

      NSHTTPPropertyStatusCodeKey
	= [[SClass alloc] initWithCString: "HTTPPropertyStatusCodeKey"];
      NSHTTPPropertyStatusReasonKey
	= [[SClass alloc] initWithCString: "HTTPPropertyStatusReasonKey"];
      NSHTTPPropertyServerHTTPVersionKey
	= [[SClass alloc] initWithCString: "HTTPPropertyServerHTTPVersionKey"];
      NSHTTPPropertyRedirectionHeadersKey
	= [[SClass alloc] initWithCString: "HTTPPropertyRedirectionHeadersKey"];
      NSHTTPPropertyErrorPageDataKey
	= [[SClass alloc] initWithCString: "HTTPPropertyErrorPageDataKey"];

      GSHTTPPropertyMethodKey
	= [[SClass alloc] initWithCString: "GSHTTPPropertyMethodKey"];
      GSHTTPPropertyProxyHostKey
	= [[SClass alloc] initWithCString: "GSHTTPPropertyProxyHostKey"];
      GSHTTPPropertyProxyPortKey
	= [[SClass alloc] initWithCString: "GSHTTPPropertyProxyPortKey"];

      NSClassDescriptionNeededForClassNotification
        = [[SClass alloc] initWithCString:
	"NSClassDescriptionNeededForClassNotification"];
    }
}



/* These are to increase readabilty locally. */
typedef unsigned int (*NSMT_hash_func_t)(NSMapTable *, const void *);
typedef BOOL (*NSMT_is_equal_func_t)(NSMapTable *, const void *, const void *);
typedef void (*NSMT_retain_func_t)(NSMapTable *, const void *);
typedef void (*NSMT_release_func_t)(NSMapTable *, const void *);
typedef NSString *(*NSMT_describe_func_t)(NSMapTable *, const void *);


/* Standard MapTable callbacks */
const NSMapTableKeyCallBacks NSIntMapKeyCallBacks = 
{
  (NSMT_hash_func_t) _NS_int_hash,
  (NSMT_is_equal_func_t) _NS_int_is_equal,
  (NSMT_retain_func_t) _NS_int_retain,
  (NSMT_release_func_t) _NS_int_release,
  (NSMT_describe_func_t) _NS_int_describe,
  NSNotAnIntMapKey
};

const NSMapTableKeyCallBacks NSNonOwnedPointerMapKeyCallBacks = 
{
  (NSMT_hash_func_t) _NS_non_owned_void_p_hash,
  (NSMT_is_equal_func_t) _NS_non_owned_void_p_is_equal,
  (NSMT_retain_func_t) _NS_non_owned_void_p_retain,
  (NSMT_release_func_t) _NS_non_owned_void_p_release,
  (NSMT_describe_func_t) _NS_non_owned_void_p_describe,
  NSNotAPointerMapKey
};

const NSMapTableKeyCallBacks NSNonOwnedPointerOrNullMapKeyCallBacks = 
{
  (NSMT_hash_func_t) _NS_non_owned_void_p_hash,
  (NSMT_is_equal_func_t) _NS_non_owned_void_p_is_equal,
  (NSMT_retain_func_t) _NS_non_owned_void_p_retain,
  (NSMT_release_func_t) _NS_non_owned_void_p_release,
  (NSMT_describe_func_t) _NS_non_owned_void_p_describe,
  NSNotAPointerMapKey
};

const NSMapTableKeyCallBacks NSNonRetainedObjectMapKeyCallBacks = 
{
  (NSMT_hash_func_t) _NS_non_retained_id_hash,
  (NSMT_is_equal_func_t) _NS_non_retained_id_is_equal,
  (NSMT_retain_func_t) _NS_non_retained_id_retain,
  (NSMT_release_func_t) _NS_non_retained_id_release,
  (NSMT_describe_func_t) _NS_non_retained_id_describe,
  NSNotAPointerMapKey
};

const NSMapTableKeyCallBacks NSObjectMapKeyCallBacks = 
{
  (NSMT_hash_func_t) _NS_id_hash,
  (NSMT_is_equal_func_t) _NS_id_is_equal,
  (NSMT_retain_func_t) _NS_id_retain,
  (NSMT_release_func_t) _NS_id_release,
  (NSMT_describe_func_t) _NS_id_describe,
  NSNotAPointerMapKey
};

const NSMapTableKeyCallBacks NSOwnedPointerMapKeyCallBacks = 
{
  (NSMT_hash_func_t) _NS_owned_void_p_hash,
  (NSMT_is_equal_func_t) _NS_owned_void_p_is_equal,
  (NSMT_retain_func_t) _NS_owned_void_p_retain,
  (NSMT_release_func_t) _NS_owned_void_p_release,
  (NSMT_describe_func_t) _NS_owned_void_p_describe,
  NSNotAPointerMapKey
};

const NSMapTableValueCallBacks NSIntMapValueCallBacks = 
{
  (NSMT_retain_func_t) _NS_int_retain,
  (NSMT_release_func_t) _NS_int_release,
  (NSMT_describe_func_t) _NS_int_describe
};

const NSMapTableValueCallBacks NSNonOwnedPointerMapValueCallBacks = 
{
  (NSMT_retain_func_t) _NS_non_owned_void_p_retain,
  (NSMT_release_func_t) _NS_non_owned_void_p_release,
  (NSMT_describe_func_t) _NS_non_owned_void_p_describe
};

const NSMapTableValueCallBacks NSNonRetainedObjectMapValueCallBacks = 
{
  (NSMT_retain_func_t) _NS_non_retained_id_retain,
  (NSMT_release_func_t) _NS_non_retained_id_release,
  (NSMT_describe_func_t) _NS_non_retained_id_describe
};

const NSMapTableValueCallBacks NSObjectMapValueCallBacks = 
{
  (NSMT_retain_func_t) _NS_id_retain,
  (NSMT_release_func_t) _NS_id_release,
  (NSMT_describe_func_t) _NS_id_describe
};

const NSMapTableValueCallBacks NSOwnedPointerMapValueCallBacks = 
{
  (NSMT_retain_func_t) _NS_owned_void_p_retain,
  (NSMT_release_func_t) _NS_owned_void_p_release,
  (NSMT_describe_func_t) _NS_owned_void_p_describe
};

/* These are to increase readabilty locally. */
typedef unsigned int (*NSHT_hash_func_t)(NSHashTable *, const void *);
typedef BOOL (*NSHT_isEqual_func_t)(NSHashTable *, const void *, const void *);
typedef void (*NSHT_retain_func_t)(NSHashTable *, const void *);
typedef void (*NSHT_release_func_t)(NSHashTable *, const void *);
typedef NSString *(*NSHT_describe_func_t)(NSHashTable *, const void *);

/**** Function Prototypes ****************************************************/
/** Standard NSHashTable callbacks... **/
     
const NSHashTableCallBacks NSIntHashCallBacks =
{
  (NSHT_hash_func_t) _NS_int_hash,
  (NSHT_isEqual_func_t) _NS_int_is_equal,
  (NSHT_retain_func_t) _NS_int_retain,
  (NSHT_release_func_t) _NS_int_release,
  (NSHT_describe_func_t) _NS_int_describe
};

const NSHashTableCallBacks NSNonOwnedPointerHashCallBacks = 
{
  (NSHT_hash_func_t) _NS_non_owned_void_p_hash,
  (NSHT_isEqual_func_t) _NS_non_owned_void_p_is_equal,
  (NSHT_retain_func_t) _NS_non_owned_void_p_retain,
  (NSHT_release_func_t) _NS_non_owned_void_p_release,
  (NSHT_describe_func_t) _NS_non_owned_void_p_describe
};

const NSHashTableCallBacks NSNonRetainedObjectHashCallBacks = 
{
  (NSHT_hash_func_t) _NS_non_retained_id_hash,
  (NSHT_isEqual_func_t) _NS_non_retained_id_is_equal,
  (NSHT_retain_func_t) _NS_non_retained_id_retain,
  (NSHT_release_func_t) _NS_non_retained_id_release,
  (NSHT_describe_func_t) _NS_non_retained_id_describe
};

const NSHashTableCallBacks NSObjectHashCallBacks = 
{
  (NSHT_hash_func_t) _NS_id_hash,
  (NSHT_isEqual_func_t) _NS_id_is_equal,
  (NSHT_retain_func_t) _NS_id_retain,
  (NSHT_release_func_t) _NS_id_release,
  (NSHT_describe_func_t) _NS_id_describe
};

const NSHashTableCallBacks NSOwnedPointerHashCallBacks = 
{
  (NSHT_hash_func_t) _NS_owned_void_p_hash,
  (NSHT_isEqual_func_t) _NS_owned_void_p_is_equal,
  (NSHT_retain_func_t) _NS_owned_void_p_retain,
  (NSHT_release_func_t) _NS_owned_void_p_release,
  (NSHT_describe_func_t) _NS_owned_void_p_describe
};

const NSHashTableCallBacks NSPointerToStructHashCallBacks = 
{
  (NSHT_hash_func_t) _NS_int_p_hash,
  (NSHT_isEqual_func_t) _NS_int_p_is_equal,
  (NSHT_retain_func_t) _NS_int_p_retain,
  (NSHT_release_func_t) _NS_int_p_release,
  (NSHT_describe_func_t) _NS_int_p_describe
};

