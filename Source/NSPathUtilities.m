/* Implementation of filesystem & path-related functions for GNUstep
   Copyright (C) 1996-2004 Free Software Foundation, Inc.

   Written by:  Andrew Kachites McCallum <address@hidden>
   Created: May 1996
   Rewrite by:  Sheldon Gill
   Date:    Jan 2004
   Rewrites by:  Richard Frith-Macdonald
   Date:    2004-2005

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
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.

   <title>NSPathUtilities function reference</title>
   $Date$ $Revision$
   */

/**
   <unit>
   <heading>Path Utility Functions</heading>
   <p>
   Path utilities provides functions to dynamically discover paths
   for the platform the application is running on.
   This avoids the need for hard coding paths, making porting easier
   and also allowing for places to change without breaking
   applications.
   (why do this? Well imagine we're running GNUstep 1 and the new
   wonderful GNUstep 2 becomes available but we're not sure of it
   yet. You could install /GNUstep/System2/ and have applications
   use which ever System you wanted at the time...)
   </p>
   <p>
   On unix systems, the paths are initialised by reading a configuration
   file. Something like "/etc/GNUstep/GNUstep.conf". This provides the basic
   information required by the library to establish all locations required.
   </p>
   <p>
   See <REF "filesystem.pdf">GNUstep File System Hierarchy</REF> document
   for more information and detailed descriptions.</p>
   </unit>
*/

#include "config.h"
#include "GNUstepBase/preface.h"
#include "objc-load.h"
#include "Foundation/NSObjCRuntime.h"
#include "Foundation/NSString.h"
#include "Foundation/NSPathUtilities.h"
#include "Foundation/NSException.h"
#include "Foundation/NSArray.h"
#include "Foundation/NSDebug.h"
#include "Foundation/NSDictionary.h"
#include "Foundation/NSFileManager.h"
#include "Foundation/NSProcessInfo.h"
#include "Foundation/NSString.h"
#include "Foundation/NSValue.h"
#include "Foundation/NSLock.h"
#include "Foundation/NSUserDefaults.h"
#include "GNUstepBase/GSCategories.h"

#include "GSPrivate.h"

#ifdef HAVE_UNISTD_H
#include <unistd.h>		// for getuid()
#endif
#ifdef	HAVE_PWD_H
#include <pwd.h>		// for getpwnam()
#endif
#include <sys/types.h>
#include <stdio.h>

NSMutableDictionary* GNUstepConfig(NSDictionary *newConfig);

void GNUstepUserConfig(NSMutableDictionary *config, NSString *userName);


/* The global configuration file. The real value is read from config.h */
#ifndef GNUSTEP_TARGET_CONFIG_FILE
# define   GNUSTEP_TARGET_CONFIG_FILE  "/etc/GNUstep/GNUstep.conf"
#endif

static NSString	*gnustep_target_cpu =
#ifdef GNUSTEP_TARGET_CPU
  @GNUSTEP_TARGET_CPU;
#else
  nil;
#endif
static NSString	*gnustep_target_os =
#ifdef GNUSTEP_TARGET_OS
  @GNUSTEP_TARGET_OS;
#else
  nil;
#endif
static NSString	*library_combo =
#ifdef LIBRARY_COMBO
  @LIBRARY_COMBO;
#else
  nil;
#endif
static NSString	*gnustep_is_flattened =
#ifdef GNUSTEP_IS_FLATTENED
  @GNUSTEP_IS_FLATTENED;
#else
  nil;
#endif

#if	defined(__MINGW32__)

#include	<lmaccess.h>

/*
 * FIXME ... should check access properly if the file is on an NTFS volume.
 */
#define	ATTRMASK	0700
#else
#define	ATTRMASK	0777
#endif

#define	MGR()	[NSFileManager defaultManager]

/* ------------------ */
/* Internal variables */
/* ------------------ */

static NSString	*gnustepConfigPath = nil;

/* This will be deprecated and removed.  */
static NSString *gnustepUserRoot = nil;        /*    GNUSTEP_USER_ROOT path */
/* This will be deprecated and removed.  */
static NSString *gnustepLocalRoot = nil;       /*   GNUSTEP_LOCAL_ROOT path */
/* This will be deprecated and removed.  */
static NSString *gnustepNetworkRoot = nil;     /* GNUSTEP_NETWORK_ROOT path */
/* This will be deprecated and removed.  */
static NSString *gnustepSystemRoot = nil;      /*  GNUSTEP_SYSTEM_ROOT path */

static NSString *gnustepUserDir = nil;
static NSString *gnustepUserHome = nil;
static NSString *gnustepUserDefaultsDir = nil;

static NSString *theUserName = nil;             /* The user's login name */
static NSString *theFullUserName = nil;         /* The user's full login name */
static NSString *tempDir = nil;                 /* user's temporary directory */

/* The following list entirely describe our filesystem configuration.  */
static NSString *gnustepMakefiles = nil;

static NSString *gnustepSystemApps = nil;
static NSString *gnustepSystemTools = nil;
static NSString *gnustepSystemLibrary = nil;
static NSString *gnustepSystemLibraries = nil;
static NSString *gnustepSystemHeaders = nil;
static NSString *gnustepSystemDocumentation = nil;
static NSString *gnustepSystemDocumentationInfo = nil;
static NSString *gnustepSystemDocumentationMan = nil;

static NSString *gnustepNetworkApps = nil;
static NSString *gnustepNetworkTools = nil;
static NSString *gnustepNetworkLibrary = nil;
static NSString *gnustepNetworkLibraries = nil;
static NSString *gnustepNetworkHeaders = nil;
static NSString *gnustepNetworkDocumentation = nil;
static NSString *gnustepNetworkDocumentationInfo = nil;
static NSString *gnustepNetworkDocumentationMan = nil;

static NSString *gnustepLocalApps = nil;
static NSString *gnustepLocalTools = nil;
static NSString *gnustepLocalLibrary = nil;
static NSString *gnustepLocalLibraries = nil;
static NSString *gnustepLocalHeaders = nil;
static NSString *gnustepLocalDocumentation = nil;
static NSString *gnustepLocalDocumentationInfo = nil;
static NSString *gnustepLocalDocumentationMan = nil;

static NSString *gnustepUserApps = nil;
static NSString *gnustepUserTools = nil;
static NSString *gnustepUserLibrary = nil;
static NSString *gnustepUserLibraries = nil;
static NSString *gnustepUserHeaders = nil;
static NSString *gnustepUserDocumentation = nil;
static NSString *gnustepUserDocumentationInfo = nil;
static NSString *gnustepUserDocumentationMan = nil;

/* These are the same as the corresponding User variables, but
 * they hold the path before GNUSTEP_HOME is prepended.  It's what
 * we read from config files.
 */
static NSString *gnustepUserDirApps = nil;
static NSString *gnustepUserDirTools = nil;
static NSString *gnustepUserDirLibrary = nil;
static NSString *gnustepUserDirLibraries = nil;
static NSString *gnustepUserDirHeaders = nil;
static NSString *gnustepUserDirDocumentation = nil;
static NSString *gnustepUserDirDocumentationInfo = nil;
static NSString *gnustepUserDirDocumentationMan = nil;

static BOOL ParseConfigurationFile(NSString *name, NSMutableDictionary *dict,
  NSString *userName);

static void InitialisePathUtilities(void);
static void ShutdownPathUtilities(void);

/* Conditionally assign an object from a dictionary to var
 * We don't need to retain val before releasing var, because we
 * can be sure that if var is val it is retained by the dictionary
 * as well as being retained when it was first placed in var.
 */
#define ASSIGN_IF_SET(var, dictionary, key) ({\
  id val = [dictionary objectForKey: key];\
  if (val != nil)\
    {\
      RELEASE(var);\
      var = RETAIN(val);\
      [dictionary removeObjectForKey: key];\
    }\
})

#define ASSIGN_PATH(var, dictionary, key) ({\
  id val = getPathConfig(dictionary, key);\
  if (val != nil)\
    {\
      RELEASE(var);\
      var = RETAIN(val);\
      [dictionary removeObjectForKey: key];\
    }\
})

/* Conditionally assign lval to var only if var is nil */
#define TEST_ASSIGN(var, lval) ({\
  if ((var == nil)&&(lval != nil))\
    {\
      var = RETAIN(lval);\
    }\
  })

#define ASSIGN_DEFAULT_PATH(var, default) ({\
  if (var == nil)\
    {\
      var = default; \
      var = RETAIN(getPath(var)); \
    }\
  })


/* Get a full path string */
static inline NSString *
getPath(NSString *path)
{
  if ([path hasPrefix: @"./"] == YES)
    {
      path = [gnustepConfigPath stringByAppendingPathComponent:
	[path substringFromIndex: 2]];
      path = [path stringByStandardizingPath];
    }
  return path;
}

/* Get a full path string from a dictionary */
static inline NSString *
getPathConfig(NSDictionary *dict, NSString *key)
{
  NSString	*path;

  path = [dict objectForKey: key];
  if (path != nil)
    {
      path = getPath(path);
      if ([path isAbsolutePath] == NO)
	{
	  NSLog(@"GNUstep configuration file entry '%@' ('%@') is not "
	    @"an absolute path.  Please fix your configuration file",
	    key, [dict objectForKey: key]);
#if	defined(__MINGW32_)
	  if ([path length] > 2)
	    {
	      unichar	buf[3];

	      [path getCharacters: buf range: NSMakeRange(0, 3)];
	      if ((buf[0] == '/' || bug[0] == '\\') && isalpha(buf[1])
		&& (buf[2] == '/' || bug[2] == '\\'))
		{
		  path = [NSString stringWithFormat: @"%c:%@", (char)buf[1],
		    [path substringFromindex: 2]];
		  path = [path stringByReplacingString: @"/"
					    withString: @"\\"];
		  NSLog(@"I am guessing that you meant '%@'", path);
		}
	    }
#endif
	}
    }
  return path;
}

static void ExtractValuesFromConfig(NSDictionary *config)
{
  NSMutableDictionary	*c = [config mutableCopy];
  NSString		*extra;

  /*
   * Move values out of the dictionary and into variables for rapid reference.
   */
  ASSIGN_PATH(gnustepSystemRoot, c, @"GNUSTEP_SYSTEM_ROOT");
  ASSIGN_PATH(gnustepNetworkRoot, c, @"GNUSTEP_NETWORK_ROOT");
  ASSIGN_PATH(gnustepLocalRoot, c, @"GNUSTEP_LOCAL_ROOT");

  ASSIGN_IF_SET(gnustepUserDir, c, @"GNUSTEP_USER_DIR");
  ASSIGN_IF_SET(gnustepUserDefaultsDir, c, @"GNUSTEP_USER_DEFAULTS_DIR");

  ASSIGN_PATH(gnustepMakefiles, c, @"GNUSTEP_MAKEFILES");

  ASSIGN_PATH(gnustepSystemApps, c, @"GNUSTEP_SYSTEM_APPS");
  ASSIGN_PATH(gnustepSystemTools, c, @"GNUSTEP_SYSTEM_TOOLS");
  ASSIGN_PATH(gnustepSystemLibrary, c, @"GNUSTEP_SYSTEM_LIBRARY");
  ASSIGN_PATH(gnustepSystemLibraries, c, @"GNUSTEP_SYSTEM_LIBRARIES");
  ASSIGN_PATH(gnustepSystemHeaders, c, @"GNUSTEP_SYSTEM_HEADERS");
  ASSIGN_PATH(gnustepSystemDocumentation, c, @"GNUSTEP_SYSTEM_DOCUMENTATION");
  ASSIGN_PATH(gnustepSystemDocumentationMan, c, @"GNUSTEP_SYSTEM_DOCUMENTATION_MAN");
  ASSIGN_PATH(gnustepSystemDocumentationInfo, c, @"GNUSTEP_SYSTEM_DOCUMENTATION_INFO");

  ASSIGN_PATH(gnustepNetworkApps, c, @"GNUSTEP_NETWORK_APPS");
  ASSIGN_PATH(gnustepNetworkTools, c, @"GNUSTEP_NETWORK_TOOLS");
  ASSIGN_PATH(gnustepNetworkLibrary, c, @"GNUSTEP_NETWORK_LIBRARY");
  ASSIGN_PATH(gnustepNetworkLibraries, c, @"GNUSTEP_NETWORK_LIBRARIES");
  ASSIGN_PATH(gnustepNetworkHeaders, c, @"GNUSTEP_NETWORK_HEADERS");
  ASSIGN_PATH(gnustepNetworkDocumentation, c, @"GNUSTEP_NETWORK_DOCUMENTATION");
  ASSIGN_PATH(gnustepNetworkDocumentationMan, c, @"GNUSTEP_NETWORK_DOCUMENTATION_MAN");
  ASSIGN_PATH(gnustepNetworkDocumentationInfo, c, @"GNUSTEP_NETWORK_DOCUMENTATION_INFO");

  ASSIGN_PATH(gnustepLocalApps, c, @"GNUSTEP_LOCAL_APPS");
  ASSIGN_PATH(gnustepLocalTools, c, @"GNUSTEP_LOCAL_TOOLS");
  ASSIGN_PATH(gnustepLocalLibrary, c, @"GNUSTEP_LOCAL_LIBRARY");
  ASSIGN_PATH(gnustepLocalLibraries, c, @"GNUSTEP_LOCAL_LIBRARIES");
  ASSIGN_PATH(gnustepLocalHeaders, c, @"GNUSTEP_LOCAL_HEADERS");
  ASSIGN_PATH(gnustepLocalDocumentation, c, @"GNUSTEP_LOCAL_DOCUMENTATION");
  ASSIGN_PATH(gnustepLocalDocumentationMan, c, @"GNUSTEP_LOCAL_DOCUMENTATION_MAN");
  ASSIGN_PATH(gnustepLocalDocumentationInfo, c, @"GNUSTEP_LOCAL_DOCUMENTATION_INFO");

  ASSIGN_IF_SET(gnustepUserDirApps, c, @"GNUSTEP_USER_DIR_APPS");
  ASSIGN_IF_SET(gnustepUserDirTools, c, @"GNUSTEP_USER_DIR_TOOLS");
  ASSIGN_IF_SET(gnustepUserDirLibrary, c, @"GNUSTEP_USER_DIR_LIBRARY");
  ASSIGN_IF_SET(gnustepUserDirLibraries, c, @"GNUSTEP_USER_DIR_LIBRARIES");
  ASSIGN_IF_SET(gnustepUserDirHeaders, c, @"GNUSTEP_USER_DIR_HEADERS");
  ASSIGN_IF_SET(gnustepUserDirDocumentation, c, @"GNUSTEP_USER_DIR_DOCUMENTATION");
  ASSIGN_IF_SET(gnustepUserDirDocumentationMan, c, @"GNUSTEP_USER_DIR_DOCUMENTATION_MAN");
  ASSIGN_IF_SET(gnustepUserDirDocumentationInfo, c, @"GNUSTEP_USER_DIR_DOCUMENTATION_INFO");

  /*
   * The GNUSTEP_EXTRA field may contain a list of extra keys which
   * we permit in the dictionary without generating a warning.
   */
  extra = [c objectForKey: @"GNUSTEP_EXTRA"];
  if (extra != nil)
    {
      NSEnumerator	*enumerator;
      NSString		*key;

      enumerator = [[extra componentsSeparatedByString: @","] objectEnumerator];
      [c removeObjectForKey: @"GNUSTEP_EXTRA"];
      while ((key = [enumerator nextObject]) != nil)
        {
	  key = [key stringByTrimmingSpaces];
	  [c removeObjectForKey: key];
	}
    }

  /*
   * Remove any other dictionary entries we have used.
   */
  [c removeObjectForKey: @"GNUSTEP_USER_CONFIG_FILE"];

  if ([c count] > 0)
    {
      /*
       * The dictionary should be empty ... report problems
       */
      fprintf(stderr, "Configuration contains unknown keys - %s\n",
	[[[c allKeys] description] UTF8String]);
    }
  DESTROY(c);

  /*
   * Set default locations for user files if necessary.
   */
  if (gnustepUserDir == nil)
    {
      ASSIGN(gnustepUserDir, @GNUSTEP_TARGET_USER_DIR);
    }
  if (gnustepUserDefaultsDir == nil)
    {
      ASSIGN(gnustepUserDefaultsDir, @GNUSTEP_TARGET_USER_DEFAULTS_DIR);
    }
  if (gnustepUserDirApps == nil)
    {
      ASSIGN(gnustepUserDirApps, @GNUSTEP_TARGET_USER_DIR_APPS);
    }
  if (gnustepUserDirTools == nil)
    {
      ASSIGN(gnustepUserDirTools, @GNUSTEP_TARGET_USER_DIR_TOOLS);
    }
  if (gnustepUserDirLibrary == nil)
    {
      ASSIGN(gnustepUserDirLibrary, @GNUSTEP_TARGET_USER_DIR_LIBRARY);
    }
  if (gnustepUserDirLibraries == nil)
    {
      ASSIGN(gnustepUserDirLibraries, @GNUSTEP_TARGET_USER_DIR_LIBRARIES);
    }
  if (gnustepUserDirHeaders == nil)
    {
      ASSIGN(gnustepUserDirHeaders, @GNUSTEP_TARGET_USER_DIR_HEADERS);
    }
  if (gnustepUserDirDocumentation == nil)
    {
      ASSIGN(gnustepUserDirDocumentation, 
	     @GNUSTEP_TARGET_USER_DIR_DOCUMENTATION);
    }
  if (gnustepUserDirDocumentationMan == nil)
    {
      ASSIGN(gnustepUserDirDocumentationMan, 
	     @GNUSTEP_TARGET_USER_DIR_DOCUMENTATION_MAN);
    }
  if (gnustepUserDirDocumentationInfo == nil)
    {
      ASSIGN(gnustepUserDirDocumentationInfo, 
	     @GNUSTEP_TARGET_USER_DIR_DOCUMENTATION_INFO);
    }

  /*
   * Set the GNUSTEP_USER_xxx variables from the user home and the
   * GNUSTEP_USER_DIR_xxx variables.
   */
  ASSIGN(gnustepUserRoot,
    [gnustepUserHome stringByAppendingPathComponent: gnustepUserDir]);

  ASSIGN(gnustepUserApps,
    [gnustepUserHome stringByAppendingPathComponent: gnustepUserDirApps]);

  ASSIGN(gnustepUserTools,
    [gnustepUserHome stringByAppendingPathComponent: gnustepUserDirTools]);

  ASSIGN(gnustepUserLibrary,
    [gnustepUserHome stringByAppendingPathComponent: gnustepUserDirLibrary]);

  ASSIGN(gnustepUserLibraries,
    [gnustepUserHome stringByAppendingPathComponent: gnustepUserDirLibraries]);

  ASSIGN(gnustepUserHeaders,
    [gnustepUserHome stringByAppendingPathComponent: gnustepUserDirHeaders]);

  ASSIGN(gnustepUserDocumentation,
    [gnustepUserHome stringByAppendingPathComponent: 
		       gnustepUserDocumentation]);

  ASSIGN(gnustepUserDocumentationMan,
    [gnustepUserHome stringByAppendingPathComponent: 
		       gnustepUserDocumentationMan]);

  ASSIGN(gnustepUserDocumentationInfo,
    [gnustepUserHome stringByAppendingPathComponent: 
		       gnustepUserDocumentationInfo]);

  /*
   * Try to ensure that essential user directories exist.
   * FIXME  ... Check/creation should perhaps be configurable.
   */
  if (1)
    {
      NSFileManager	*manager;
      NSString		*path;
      NSDictionary	*attr;
      BOOL		flag;

      manager = [NSFileManager defaultManager];
      attr = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: 0750]
					 forKey: NSFilePosixPermissions];

      // Make sure library directory exists (to store resources).
      path = gnustepUserLibrary;
      if ([manager fileExistsAtPath: path isDirectory: &flag] == NO
	|| flag == NO)
	{
	  [manager createDirectoryAtPath: path attributes: attr];
	}
    }

  /*
   * Finally set default locations for the essential paths if required.
   */
  ASSIGN_DEFAULT_PATH(gnustepSystemRoot, @GNUSTEP_TARGET_SYSTEM_ROOT);
  ASSIGN_DEFAULT_PATH(gnustepNetworkRoot, @GNUSTEP_TARGET_NETWORK_ROOT);
  ASSIGN_DEFAULT_PATH(gnustepLocalRoot, @GNUSTEP_TARGET_LOCAL_ROOT);

  ASSIGN_DEFAULT_PATH(gnustepSystemApps, @GNUSTEP_TARGET_SYSTEM_APPS);
  ASSIGN_DEFAULT_PATH(gnustepSystemTools, @GNUSTEP_TARGET_SYSTEM_TOOLS);
  ASSIGN_DEFAULT_PATH(gnustepSystemLibrary, @GNUSTEP_TARGET_SYSTEM_LIBRARY);
  ASSIGN_DEFAULT_PATH(gnustepSystemLibraries, @GNUSTEP_TARGET_SYSTEM_LIBRARIES);
  ASSIGN_DEFAULT_PATH(gnustepSystemHeaders, @GNUSTEP_TARGET_SYSTEM_HEADERS);
  ASSIGN_DEFAULT_PATH(gnustepSystemDocumentation, @GNUSTEP_TARGET_SYSTEM_DOCUMENTATION);
  ASSIGN_DEFAULT_PATH(gnustepSystemDocumentationMan, @GNUSTEP_TARGET_SYSTEM_DOCUMENTATION_MAN);
  ASSIGN_DEFAULT_PATH(gnustepSystemDocumentationInfo, @GNUSTEP_TARGET_SYSTEM_DOCUMENTATION_INFO);

  ASSIGN_DEFAULT_PATH(gnustepNetworkApps, @GNUSTEP_TARGET_NETWORK_APPS);
  ASSIGN_DEFAULT_PATH(gnustepNetworkTools, @GNUSTEP_TARGET_NETWORK_TOOLS);
  ASSIGN_DEFAULT_PATH(gnustepNetworkLibrary, @GNUSTEP_TARGET_NETWORK_LIBRARY);
  ASSIGN_DEFAULT_PATH(gnustepNetworkLibraries, @GNUSTEP_TARGET_NETWORK_LIBRARIES);
  ASSIGN_DEFAULT_PATH(gnustepNetworkHeaders, @GNUSTEP_TARGET_NETWORK_HEADERS);
  ASSIGN_DEFAULT_PATH(gnustepNetworkDocumentation, @GNUSTEP_TARGET_NETWORK_DOCUMENTATION);
  ASSIGN_DEFAULT_PATH(gnustepNetworkDocumentationMan, @GNUSTEP_TARGET_NETWORK_DOCUMENTATION_MAN);
  ASSIGN_DEFAULT_PATH(gnustepNetworkDocumentationInfo, @GNUSTEP_TARGET_NETWORK_DOCUMENTATION_INFO);

  ASSIGN_DEFAULT_PATH(gnustepLocalApps, @GNUSTEP_TARGET_LOCAL_APPS);
  ASSIGN_DEFAULT_PATH(gnustepLocalTools, @GNUSTEP_TARGET_LOCAL_TOOLS);
  ASSIGN_DEFAULT_PATH(gnustepLocalLibrary, @GNUSTEP_TARGET_LOCAL_LIBRARY);
  ASSIGN_DEFAULT_PATH(gnustepLocalLibraries, @GNUSTEP_TARGET_LOCAL_LIBRARIES);
  ASSIGN_DEFAULT_PATH(gnustepLocalHeaders, @GNUSTEP_TARGET_LOCAL_HEADERS);
  ASSIGN_DEFAULT_PATH(gnustepLocalDocumentation, @GNUSTEP_TARGET_LOCAL_DOCUMENTATION);
  ASSIGN_DEFAULT_PATH(gnustepLocalDocumentationMan, @GNUSTEP_TARGET_LOCAL_DOCUMENTATION_MAN);
  ASSIGN_DEFAULT_PATH(gnustepLocalDocumentationInfo, @GNUSTEP_TARGET_LOCAL_DOCUMENTATION_INFO);

  ASSIGN_DEFAULT_PATH(gnustepMakefiles, @GNUSTEP_TARGET_MAKEFILES);
}

NSMutableDictionary*
GNUstepConfig(NSDictionary *newConfig)
{
  static NSDictionary	*config = nil;
  NSMutableDictionary	*conf = nil;
  BOOL			changedSystemConfig = NO;

  [gnustep_global_lock lock];
  if (config == nil || (newConfig != nil && [config isEqual: newConfig] == NO))
    {
      NS_DURING
	{
	  if (newConfig == nil)
	    {
	      NSString	*file = nil;
	      BOOL	fromEnvironment = YES;
	      BOOL	bareDirectory = NO;

	      conf = [[NSMutableDictionary alloc] initWithCapacity: 32];

	      /* Now we source the configuration file if it exists */
#if	!OPTION_NO_ENVIRONMENT
	      file = [[[NSProcessInfo processInfo] environment]
		objectForKey: @"GNUSTEP_CONFIG_FILE"];
#endif
	      if (file == nil)
		{
		  fromEnvironment = NO;
		  file = @GNUSTEP_TARGET_CONFIG_FILE;
		}

	      /*
	       * Is the file missing from the path ... if so we won't
	       * be reading it.
	       */
	      if ([file hasSuffix: @"/"] || [file hasSuffix: @"\\"])
		{
		  bareDirectory = YES;
		}

	      /*
	       * Special case ... if the config file location begins './'
	       * then we determine it's actual path by working relative
	       * to the gnustep-base library.
	       */
	      if ([file hasPrefix: @"./"] == YES)
		{
		  Class		c = [NSProcessInfo class];
		  NSString	*path = GSPrivateSymbolPath (c, 0);

		  // Remove library name from path
		  path = [path stringByDeletingLastPathComponent];
		  // Remove ./ prefix from filename
		  file = [file substringFromIndex: 2];
		  // Join the two together
		  file = [path stringByAppendingPathComponent: file];
		}
	      file = [file stringByStandardizingPath];

	      if ([file isAbsolutePath] == NO)
		{
		  if (fromEnvironment ==  YES)
		    {
		      NSLog(@"GNUSTEP_CONFIG_FILE value ('%@') is not "
			@"an absolute path.  Please fix the environment "
			@"variable.", file);
		    }
		  else
		    {
		      NSLog(@"GNUSTEP_CONFIG_FILE value ('%@') is not "
			@"an absolute path.  Please rebuild GNUstep-base "
			@"specifying a valid path to the config file.", file);
		    }
#if	defined(__MINGW32_)
		  if ([file length] > 2)
		    {
		      unichar	buf[3];

		      [file getCharacters: buf range: NSMakeRange(0, 3)];
		      if ((buf[0] == '/' || bug[0] == '\\') && isalpha(buf[1])
			&& (buf[2] == '/' || bug[2] == '\\'))
			{
			  file = [NSString stringWithFormat: @"%c:%@",
			    (char)buf[1], [file substringFromindex: 2]];
			  file = [file stringByReplacingString: @"/"
						    withString: @"\\"];
			  NSLog(@"I am guessing that you meant '%@'", file);
			}
		    }
#endif
		}
	      if (bareDirectory == YES)
		{
		  gnustepConfigPath = RETAIN(file);
		}
	      else
		{
		  gnustepConfigPath
		    = RETAIN([file stringByDeletingLastPathComponent]);
		  ParseConfigurationFile(file, conf, nil);
		}
	    }
	  else
	    {
	      conf = [newConfig mutableCopy];
	    }
	  /* System admins may force the user and defaults paths by
	   * setting GNUSTEP_USER_CONFIG_FILE to be an empty string.
	   * If they simply don't define it at all, we assign a default.
	   */
	  if ([conf objectForKey: @"GNUSTEP_USER_CONFIG_FILE"] == nil)
	    {
	      [conf setObject: @GNUSTEP_TARGET_USER_CONFIG_FILE
		       forKey: @"GNUSTEP_USER_CONFIG_FILE"];
	    }
	  if (config != nil)
	    {
	      changedSystemConfig = YES;
	    }
	  config = [conf copy];
	  DESTROY(conf);
	}
      NS_HANDLER
	{
	  [gnustep_global_lock unlock];
	  config = nil;
	  DESTROY(conf);
	  [localException raise];
	}
      NS_ENDHANDLER
    }
  [gnustep_global_lock unlock];

  if (changedSystemConfig == YES)
    {
      /*
       * The main configuration was changed by passing in a dictionary to
       * this function, so we need to reset the path utilities system to use
       * any new values from the config.
       */
      ShutdownPathUtilities();
      InitialisePathUtilities();
    }

  return AUTORELEASE([config mutableCopy]);
}

void
GNUstepUserConfig(NSMutableDictionary *config, NSString *userName)
{
#ifdef HAVE_GETEUID
  if (userName != nil)
    {
      /*
       * A program which is running setuid cannot be trusted
       * to pick up user specific config, so we clear the userName
       * to force the system configuration to be returned rather
       * than a per-user config.
       */
      if (getuid() != geteuid())
	{
	  userName = nil;
	}
    }
#endif

  if (userName != nil)
    {
      NSString		*file;
      NSString		*home;
      NSString		*path;

      file = RETAIN([config objectForKey: @"GNUSTEP_USER_CONFIG_FILE"]);
      if ([file length] > 0)
	{
	  home = NSHomeDirectoryForUser(userName);
	  path = [home stringByAppendingPathComponent: file];
	  ParseConfigurationFile(path, config, userName);
	}
      /*
       * We don't let the user config file override the GNUSTEP_USER_CONFIG_FILE
       * variable ... that would be silly/pointless.
       */
      [config setObject: file forKey: @"GNUSTEP_USER_CONFIG_FILE"];
      RELEASE(file);
    }
}

/* Initialise all things required by this module */
static void InitialisePathUtilities(void)
{
  if (gnustepMakefiles != nil)
    {
      return;	// Protect from multiple calls
    }

  /* Set up our root paths */
  NS_DURING
    {
      NSString			*userName;
      NSMutableDictionary	*config;

      [gnustep_global_lock lock];
      userName = NSUserName();
      config = GNUstepConfig(nil);
      GNUstepUserConfig(config, userName);
      ASSIGNCOPY(gnustepUserHome, NSHomeDirectoryForUser(userName));
      ExtractValuesFromConfig(config);

      [gnustep_global_lock unlock];
    }
  NS_HANDLER
    {
      /* unlock then re-raise the exception */
      [gnustep_global_lock unlock];
      [localException raise];
    }
  NS_ENDHANDLER
}

/*
 * Close down and release all things allocated.
 */
static void ShutdownPathUtilities(void)
{
  DESTROY(gnustepSystemRoot);
  DESTROY(gnustepNetworkRoot);
  DESTROY(gnustepLocalRoot);
  DESTROY(gnustepUserRoot);

  DESTROY(gnustepUserHome);
  DESTROY(gnustepUserDefaultsDir);

  DESTROY(gnustepMakefiles);

  DESTROY(gnustepSystemApps);
  DESTROY(gnustepSystemTools);
  DESTROY(gnustepSystemLibrary);
  DESTROY(gnustepSystemLibraries);
  DESTROY(gnustepSystemHeaders);
  DESTROY(gnustepSystemDocumentation);
  DESTROY(gnustepSystemDocumentationMan);
  DESTROY(gnustepSystemDocumentationInfo);

  DESTROY(gnustepNetworkApps);
  DESTROY(gnustepNetworkTools);
  DESTROY(gnustepNetworkLibrary);
  DESTROY(gnustepNetworkLibraries);
  DESTROY(gnustepNetworkHeaders);
  DESTROY(gnustepNetworkDocumentation);
  DESTROY(gnustepNetworkDocumentationMan);
  DESTROY(gnustepNetworkDocumentationInfo);

  DESTROY(gnustepLocalApps);
  DESTROY(gnustepLocalTools);
  DESTROY(gnustepLocalLibrary);
  DESTROY(gnustepLocalLibraries);
  DESTROY(gnustepLocalHeaders);
  DESTROY(gnustepLocalDocumentation);
  DESTROY(gnustepLocalDocumentationMan);
  DESTROY(gnustepLocalDocumentationInfo);

  DESTROY(gnustepUserApps);
  DESTROY(gnustepUserTools);
  DESTROY(gnustepUserLibrary);
  DESTROY(gnustepUserLibraries);
  DESTROY(gnustepUserHeaders);
  DESTROY(gnustepUserDocumentation);
  DESTROY(gnustepUserDocumentationMan);
  DESTROY(gnustepUserDocumentationInfo);

  DESTROY(tempDir);
}

/**
 * Reads a file and expects it to be in basic unix "conf" style format with
 * one key = value per line (the format a unix shell can 'source' in order
 * to define shell variables).<br />
 * This attempts to mimic the escape sequence and quoting conventions of
 * the standard bourne shell, so that a config file sourced by the make
 * package will produce the same results as one parsed by this function.<br />
 * Keys, by convention, consiste of uppercase letters, digits,
 * and underscores, and must not begin with a digit.<br />
 * A value may be any quoted string (or an unquoted string containing no
 * white space).<br />
 * Lines beginning with a hash '#' are deemed comment lines and ignored.<br/ >
 * The backslash character may be used as an escape character anywhere
 * in the file  except within a singly quoted string
 * (where it is taken literally).<br />
 * A backslash followed immediately by a newline (except in a singly
 * quoted string) is removed completely along with the newline ... it
 * thus serves to join lines so that they are treated as a single line.<br />
 * NB. Since ms-windows uses backslash characters in paths, it is a good
 * idea to specify path values in the config file as singly quoted
 * strings to avoid having to double all occurrences of the backslash.<br />
 * Returns a dictionary of the (key,value) pairs.<br/ >
 * If the file does not exist,
 * the function makes no changes to dict and returns NO.
 */
static BOOL
ParseConfigurationFile(NSString *fileName, NSMutableDictionary *dict,
  NSString *userName)
{
  NSDictionary	*attributes;
  NSString      *file;
  unsigned	l;
  unichar	*src;
  unichar	*dst;
  unichar	*end;
  unichar	*spos;
  unichar	*dpos;
  BOOL		newLine = YES;
  BOOL		wantKey = YES;
  BOOL		wantVal = NO;
  NSString	*key = nil;

  if ([MGR() isReadableFileAtPath: fileName] == NO)
    {
      return NO;
    }

  attributes = [MGR() fileAttributesAtPath: fileName traverseLink: YES];
  if (userName != nil)
    {
      NSString	*fileOwner = [attributes fileOwnerAccountName];
  
      if ([userName isEqual: fileOwner] == NO)
	{
#if defined(__MINGW32__)
	  fprintf(stderr, "The file '%S' is owned by '%s' but we expect it"
	    " to be the personal config file of '%s'.\nIgnoring it.\n",
	    [fileName fileSystemRepresentation],
	    [fileOwner UTF8String], [userName UTF8String]);
#else
	  fprintf(stderr, "The file '%s' is owned by '%s' but we expect it"
	    " to be the personal config file of '%s'.\nIgnoring it.\n",
	    [fileName fileSystemRepresentation],
	    [fileOwner UTF8String], [userName UTF8String]);
#endif
          return NO;
	}
    }
  if (([attributes filePosixPermissions] & (0022 & ATTRMASK)) != 0)
    {
#if defined(__MINGW32__)
      fprintf(stderr, "The file '%S' is writable by someone other than"
	" its owner (permissions 0%lo).\nIgnoring it.\n",
	[fileName fileSystemRepresentation],
        [attributes filePosixPermissions]);
#else
      fprintf(stderr, "The file '%s' is writable by someone other than"
	" its owner (permissions 0%lo).\nIgnoring it.\n",
	[fileName fileSystemRepresentation],
        [attributes filePosixPermissions]);
#endif
      return NO;
    }

  if (dict == nil)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"No destination dictionary supplied"];
    }

  file = [NSString stringWithContentsOfFile: fileName];
  l = [file length];
  src = (unichar*)NSZoneMalloc(NSDefaultMallocZone(), sizeof(unichar) * l);
  spos = src;
  end = src + l;
  dst = (unichar*)NSZoneMalloc(NSDefaultMallocZone(), sizeof(unichar) * l);
  dpos = dst;
  [file getCharacters: src];

  while (spos < end)
    {
      /*
       * Step past any whitespace ... including blank lines
       */
      while (spos < end)
	{
	  if (*spos == '\\')
	    {
	      spos++;
	      if (spos >= end)
		{
		  break;	// At end of file ... odd but not fatal
		}
	    }
	  if (*spos > ' ')
	    {
	      break;		// OK ... found a non space character.
	    }
	  if (*spos == '\r' || *spos == '\n')
	    {
	      newLine = YES;
	    }
	  spos++;
	}

      /*
       * Handle any comments .. hash on a new line.
       */
      if (newLine == YES)
	{
	  if (wantVal == YES)
	    {
	      /*
	       * On a newline ...so the last key had no value set.
	       * Put an empty value in the dictionary.
	       */
	      [dict setObject: @"" forKey: key];
	      DESTROY(key);
	      wantVal = NO;
	    }
	  if (spos < end && *spos == '#')
	    {
	      // Got a comment ... ignore remainder of line.
	      while (spos < end && *spos != '\n' && *spos != '\r')
		{
		  spos++;
		}
	      continue;	// restart loop ... skip space at start of line
	    }
	  newLine = NO;
	  wantKey = YES;
	}

      if (spos >= end)
	{
	  break;	// At end of file ... odd but not fatal
	}

      if (*spos == '=')
	{
	  if (wantKey == NO)
	    {
	      wantVal = YES;
	    }
	  spos++;
	}
      else if (*spos == '\'')
	{
	  spos++;
	  while (spos < end)
	    {
	      if (*spos == '\'')
		{
		  spos++;
		  break;
		}
	      *dpos++ = *spos++;
	    }
	  if (wantVal == YES)
	    {
	      NSString	*val = [NSString alloc];

	      val = [val initWithCharacters: dst length: dpos - dst];
	      if (val != nil)
		{
		  [dict setObject: val forKey: key];
		  DESTROY(key);
		  DESTROY(val);
		  wantVal = NO;
		}
	    }
	  dpos = dst;	// reset output buffer
	}
      else if (*spos == '"')
	{
	  spos++;
	  while (spos < end)
	    {
	      BOOL	escaped = NO;

	      if (*spos == '\\')
		{
		  spos++;
		  if (spos >= end)
		    {
		      break;	// Unexpected end of file
		    }
		  if (*spos == '\n')
		    {
		      spos++;
		      continue;	// escaped newline is removed.
		    }
		  if (*spos == '\r')
		    {
		      spos++;
		      if (spos < end && *spos == '\n')
			{
			  spos++;
			}
		      continue;	// escaped newline is removed.
		    }
		  escaped = YES;
		}
	      if (*spos == '"' && escaped == NO)
		{
		  spos++;
		  break;
		}
	      *dpos++ = *spos++;
	    }
	  if (wantVal == YES)
	    {
	      NSString	*val = [NSString alloc];

	      val = [val initWithCharacters: dst length: dpos - dst];
	      if (val != nil)
		{
		  [dict setObject: val forKey: key];
		  DESTROY(key);
		  DESTROY(val);
		  wantVal = NO;
		}
	    }
	  dpos = dst;	// reset output buffer
	}
      else
	{
	  while (spos < end)
	    {
	      if (*spos == '\\')
		{
		  spos++;
		  if (spos >= end)
		    {
		      break;	// Unexpected end of file
		    }
		  if (*spos == '\n')
		    {
		      spos++;
		      continue;	// escaped newline is removed.
		    }
		  if (*spos == '\r')
		    {
		      spos++;
		      if (spos < end && *spos == '\n')
			{
			  spos++;
			}
		      continue;	// escaped newline is removed.
		    }
		}
	      if (isspace(*spos) || *spos == '=')
		{
		  break;
		}
	      *dpos++ = *spos++;
	    }

	  if (wantKey == YES)
	    {
	      key = [NSString alloc];
	      key = [key initWithCharacters: dst length: dpos - dst];
	      if (key != nil)
		{
		  wantKey = NO;
		}
	    }
	  else if (wantVal == YES)
	    {
	      NSString	*val = [NSString alloc];

	      val = [val initWithCharacters: dst length: dpos - dst];
	      if (val != nil)
		{
		  [dict setObject: val forKey: key];
		  DESTROY(key);
		  DESTROY(val);
		  wantVal = NO;
		}
	    }
	  dpos = dst;	// reset output buffer
	}
    }
  if (wantVal == YES)
    {
      [dict setObject: @"" forKey: key];
      DESTROY(key);
    }
  NSZoneFree(NSDefaultMallocZone(), src);
  NSZoneFree(NSDefaultMallocZone(), dst);

  return YES;
}


/* See NSPathUtilities.h for description */
void
GSSetUserName(NSString *aName)
{
  NSCParameterAssert([aName length] > 0);

  /*
   * Do nothing if it's not a different user.
   */
  if ([theUserName isEqualToString: aName])
    {
      return;
    }

  /*
   * Release the memory
   */
  [gnustep_global_lock lock];
  ShutdownPathUtilities();

  /*
   * Reset things as new user
   */
  ASSIGN(theUserName, aName);
  DESTROY(theFullUserName);
  InitialisePathUtilities();
  [NSUserDefaults resetStandardUserDefaults];

  [gnustep_global_lock unlock];
}

/**
 * Return the caller's login name as an NSString object.<br/ >
 * Under unix-like systems, the name associated with the current
 * effective user ID is used.<br/ >
 * Under ms-windows, the 'LOGNAME' environment is used, or if that fails, the
 * GetUserName() call is used to find the user name.<br />
 * Raises an exception on failure.
 */
/* NOTE FOR DEVELOPERS.
 * If you change the behavior of this method you must also change
 * user_home.c in the makefiles package to match.
 */
NSString *
NSUserName(void)
{
#if defined(__MINGW32__)
  if (theUserName == nil)
    {
      /* Use the LOGNAME environment variable if set. */
      theUserName = [[[NSProcessInfo processInfo] environment]
	objectForKey: @"LOGNAME"];
      if ([theUserName length] > 0)
	{
	  RETAIN(theUserName);
	}
      else
	{
	  /* The GetUserName function returns the current user name */
	  unichar buf[1024];
	  DWORD n = 1024;

	  if (GetUserNameW(buf, &n) != 0 && buf[0] != '\0')
	    {
	      theUserName = [[NSString alloc] initWithCharacters: buf
							  length: wcslen(buf)];
	    }
	  else
	    {
	      theUserName = nil;
	      [NSException raise: NSInternalInconsistencyException
			  format: @"Unable to determine current user name"];
	    }
	}
    }
#else
  /* Set olduid to some invalid uid that we could never start off running
     as.  */
  static int	olduid = -1;
#ifdef HAVE_GETEUID
  int uid = geteuid();
#else
  int uid = getuid();
#endif /* HAVE_GETEUID */

  if (theUserName == nil || uid != olduid)
    {
      const char *loginName = 0;
#ifdef HAVE_GETPWUID
      struct passwd *pwent = getpwuid (uid);
      loginName = pwent->pw_name;
#endif /* HAVE_GETPWUID */
      olduid = uid;
      if (loginName)
	theUserName = [[NSString alloc] initWithCString: loginName];
      else
	[NSException raise: NSInternalInconsistencyException
		    format: @"Unable to determine current user name"];
    }
#endif
  return theUserName;
}


/**
 * Return the caller's home directory as an NSString object.
 * Calls NSHomeDirectoryForUser() to do this.
 */
NSString *
NSHomeDirectory(void)
{
  return NSHomeDirectoryForUser (NSUserName ());
}

/**
 * Returns loginName's home directory as an NSString object.
 */
/* NOTE FOR DEVELOPERS.
 * If you change the behavior of this method you must also change
 * user_home.c in the makefiles package to match.
 */
NSString *
NSHomeDirectoryForUser(NSString *loginName)
{
  NSString	*s = nil;

#if !defined(__MINGW32__)
  struct passwd *pw;

  [gnustep_global_lock lock];
  pw = getpwnam ([loginName cString]);
  if (pw != 0  && pw->pw_dir != NULL)
    {
      s = [NSString stringWithUTF8String: pw->pw_dir];
    }
  [gnustep_global_lock unlock];
#else
  if ([loginName isEqual: NSUserName()] == YES)
    {
      NSDictionary	*e = [[NSProcessInfo processInfo] environment];

      /*
       * The environment variable HOMEPATH holds the home directory
       * for the user on Windows NT;
       * For OPENSTEP compatibility (and because USERPROFILE is usually
       * unusable because it contains spaces), we use HOMEPATH in
       * preference to USERPROFILE.
       */
      s = [e objectForKey: @"HOMEPATH"];
      if (s != nil && ([s length] < 2 || [s characterAtIndex: 1] != ':'))
        {
          s = [[e objectForKey: @"HOMEDRIVE"] stringByAppendingString: s];
        }
      if (s == nil)
        {
          s = [e objectForKey: @"USERPROFILE"];
        }
      if (s == nil)
        {
          ; // FIXME: Talk to the NET API and get the profile path
        }
    }
  else
    {
      s = nil;
      NSLog(@"Trying to get home for '%@' when user is '%@'",
	loginName, NSUserName());    
      NSLog(@"Can't determine other user home directories in Win32.");    
    }
  
  if ([s length] == 0 && [loginName length] != 1)
    {
      s = nil;
      NSLog(@"NSHomeDirectoryForUser(%@) failed", loginName);
    }
#endif
  return s;
}

NSString *
NSFullUserName(void)
{
  if (theFullUserName == nil)
    {
      NSString	*userName = NSUserName();
#if defined(__MINGW32__)
      struct _USER_INFO_2	*userInfo;

      if (NetUserGetInfo(NULL, (unichar*)[userName cStringUsingEncoding:
	NSUnicodeStringEncoding], 2, (LPBYTE*)&userInfo) == 0)
	{
	  userName = [NSString stringWithCharacters: userInfo->usri2_full_name
	    length: wcslen(userInfo->usri2_full_name)];
	}
#else
#ifdef  HAVE_PWD_H
      struct passwd	*pw;

      pw = getpwnam([NSUserName() cString]);
      userName = [NSString stringWithUTF8String: pw->pw_gecos];
#else
      NSLog(@"Warning: NSFullUserName not implemented\n");
      userName = NSUserName();
#endif /* HAVE_PWD_H */
#endif /* defined(__Win32__) else */
      ASSIGN(theFullUserName, userName);
    }
  return theFullUserName;
}

/**
 * Return the path of the defaults directory for userName.<br />
 * This examines the .GNUsteprc file in the home directory of the
 * user for the GNUSTEP_DEFAULTS_ROOT or the GNUSTEP_USER_ROOT
 * directory definitions, over-riding those in GNUstep.conf.
 */
NSString *
GSDefaultsRootForUser(NSString *userName)
{
  NSString *home;
  NSString *defaultsDir;

  InitialisePathUtilities();
  if ([userName length] == 0)
    {
      userName = NSUserName();
    }
  home = NSHomeDirectoryForUser(userName);
  if ([userName isEqual: NSUserName()])
    {
      defaultsDir = gnustepUserDefaultsDir;
    }
  else
    {
      NSMutableDictionary	*config;

      config = GNUstepConfig(nil);
      GNUstepUserConfig(config, userName);
      defaultsDir = [config objectForKey: @"GNUSTEP_USER_DEFAULTS_DIR"];
      if (defaultsDir == nil)
	{
	  defaultsDir = @GNUSTEP_TARGET_USER_DEFAULTS_DIR;
	}
    }
#if	defined(__MINGW32__)
  if ([defaultsDir rangeOfString: @":REGISTRY:"].length > 0)
    {
      return defaultsDir;	// Just use windows registry.
    }
#endif
  home = [home stringByAppendingPathComponent: defaultsDir];

  return home;
}

NSArray *
NSStandardApplicationPaths(void)
{
  return NSSearchPathForDirectoriesInDomains(NSAllApplicationsDirectory,
                                             NSAllDomainsMask, YES);
}

NSArray *
NSStandardLibraryPaths(void)
{
  return NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory,
                                             NSAllDomainsMask, YES);
}

NSString *
NSTemporaryDirectory(void)
{
  NSFileManager	*manager;
  NSString	*tempDirName;
  NSString	*baseTempDirName = nil;
  NSDictionary	*attr;
  int		perm;
  int		owner;
  BOOL		flag;
#if	!defined(__MINGW32__)
  int		uid;
#else
  unichar buffer[1024];

  if (GetTempPathW(1024, buffer))
    {
      baseTempDirName = [NSString stringWithCharacters: buffer
						length: wcslen(buffer)];
    }
#endif

  /*
   * If the user has supplied a directory name in the TEMP or TMP
   * environment variable, attempt to use that unless we already
   * have a temporary directory specified.
   */
  if (baseTempDirName == nil)
    {
      NSDictionary	*env = [[NSProcessInfo processInfo] environment];

      baseTempDirName = [env objectForKey: @"TEMP"];
      if (baseTempDirName == nil)
	{
	  baseTempDirName = [env objectForKey: @"TMP"];
	  if (baseTempDirName == nil)
	    {
#if	defined(__CYGWIN__)
	      baseTempDirName = @"/cygdrive/c/";
#elif	defined(__MINGW32__)
	      baseTempDirName = @"C:\\";
#else
	      baseTempDirName = @"/tmp";
#endif
	    }
	}
    }

  /*
   * Check that the base directory exists ... if it doesn't we can't
   * go any further.
   */
  tempDirName = baseTempDirName;
  manager = [NSFileManager defaultManager];
  if ([manager fileExistsAtPath: tempDirName isDirectory: &flag] == NO
    || flag == NO)
    {
      [NSException raise: NSGenericException
		  format: @"Temporary directory (%@) does not exist",
			  tempDirName];
      return nil; /* Not reached. */
    }

  /*
   * Check that we are the directory owner, and that we, and nobody else,
   * have access to it. If other people have access, try to create a secure
   * subdirectory.
   */
  attr = [manager fileAttributesAtPath: tempDirName traverseLink: YES];
  owner = [[attr objectForKey: NSFileOwnerAccountID] intValue];
  perm = [[attr objectForKey: NSFilePosixPermissions] intValue];
  perm = perm & 0777;

// Mateu Batle: secure temporary directories don't work in MinGW
#ifndef __MINGW32__

#if	defined(__MINGW32__)
  uid = owner;
#else
#ifdef HAVE_GETEUID
  uid = geteuid();
#else
  uid = getuid();
#endif /* HAVE_GETEUID */
#endif
  if ((perm != 0700 && perm != 0600) || owner != uid)
    {
      NSString	*secure;

      /*
       * The name of the secure subdirectory reflects the user ID rather
       * than the user name, since it is possible to have an account with
       * lots of names on a unix system (ie multiple entries in the password
       * file but a single userid).  The private directory is secure within
       * the account, not to a particular user name.
       */
      secure = [NSString stringWithFormat: @"GNUstepSecure%d", uid];
      tempDirName
	= [baseTempDirName stringByAppendingPathComponent: secure];
      /*
      NSLog(@"Temporary directory (%@) may be insecure ... attempting to "
	@"add secure subdirectory", tempDirName);
      */
      if ([manager fileExistsAtPath: tempDirName] == NO)
	{
	  NSNumber	*p = [NSNumber numberWithInt: 0700];

	  attr = [NSDictionary dictionaryWithObject: p
					     forKey: NSFilePosixPermissions];
	  if ([manager createDirectoryAtPath: tempDirName
				  attributes: attr] == NO)
	    {
	      [NSException raise: NSGenericException
			  format:
		@"Attempt to create a secure temporary directory (%@) failed.",
				  tempDirName];
	      return nil; /* Not reached. */
	    }
	}

      /*
       * Check that the new directory is really secure.
       */
      attr = [manager fileAttributesAtPath: tempDirName traverseLink: YES];
      owner = [[attr objectForKey: NSFileOwnerAccountID] intValue];
      perm = [[attr objectForKey: NSFilePosixPermissions] intValue];
      perm = perm & 0777;
      if ((perm != 0700 && perm != 0600) || owner != uid)
	{
	  [NSException raise: NSGenericException
		      format:
	    @"Attempt to create a secure temporary directory (%@) failed.",
			      tempDirName];
	  return nil; /* Not reached. */
	}
    }
#endif

  if ([manager isWritableFileAtPath: tempDirName] == NO)
    {
      [NSException raise: NSGenericException
		  format: @"Temporary directory (%@) is not writable",
			  tempDirName];
      return nil; /* Not reached. */
    }
  return tempDirName;
}

NSString *
NSOpenStepRootDirectory(void)
{
  NSString	*root;

#if	defined(__CYGWIN__)
  root = @"/cygdrive/c/";
#elif	defined(__MINGW32__)
  root = @"C:\\";
#else
  root = @"/";
#endif
  return root;
}

NSArray *
NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directoryKey,
  NSSearchPathDomainMask domainMask, BOOL expandTilde)
{
  NSMutableArray  *paths = [NSMutableArray new];
  NSString        *path;
  unsigned        i;
  unsigned        count;

  InitialisePathUtilities();

  NSCAssert(gnustepMakefiles!=nil,@"Path utilities without initialisation!");

  /*
   * The order in which we return paths is important - user must come
   * first, followed by local, followed by network, followed by system.
   * The calling code can then loop on the returned paths, and stop as
   * soon as it finds something.  So things in user automatically
   * override things in system etc.
   */

#define ADD_PATH(mask, base_dir, add_dir) \
if (domainMask & mask) \
{ \
  path = [base_dir stringByAppendingPathComponent: add_dir]; \
  if (path != nil && [paths containsObject: path] == NO) \
    [paths addObject: path]; \
}
#define ADD_PLATFORM_PATH(mask, add_dir) \
if (domainMask & mask) \
{ \
  if (add_dir != nil && [paths containsObject: add_dir] == NO) \
    [paths addObject: add_dir]; \
}

  switch (directoryKey)
    {
      case NSAllApplicationsDirectory:
	{
	  /* We don't really have any separation of applications by type,
	   * we put everything in Applications.  So for now no point
	   * in returning anything different and spending time scanning
	   * the disk for non-existing dirs.
	   */
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserApps);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalApps);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkApps);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemApps);
	}
	break;

      case NSApplicationDirectory:
	{
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserApps);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalApps);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkApps);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemApps);
	}
	break;

      case NSDemoApplicationDirectory:
	{
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserApps);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalApps);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkApps);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemApps);

	  /* I imagine if ever wanted a separate Demo directory, the
	   * only way for this to have some meaning across filesystems
	   * would be as a subdirectory of Applications, as follows.
	   */
	  /*
	    ADD_PATH(NSUserDomainMask, gnustepUserApps, @"Demos");
	    ADD_PATH(NSLocalDomainMask, gnustepLocalApps, @"Demos");
	    ADD_PATH(NSNetworkDomainMask, gnustepNetworkApps, @"Demos");
	    ADD_PATH(NSSystemDomainMask, gnustepSystemApps, @"Demos");
	  */
	}
	break;

      case NSCoreServicesDirectory:
	{
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"CoreServices");
	}
	break;

      case NSDesktopDirectory:
	{
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"Desktop");
	}
	break;

      case NSDeveloperApplicationDirectory:
	{
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserApps);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalApps);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkApps);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemApps);

	  /* I imagine if ever wanted a separate Developer directory, the
	   * only way for this to have some meaning across filesystems
	   * would be as a subdirectory of Applications, as follows.
	   */
	  /*
	    ADD_PATH(NSUserDomainMask, gnustepUserApps, @"Developer");
	    ADD_PATH(NSLocalDomainMask, gnustepLocalApps, @"Developer");
	    ADD_PATH(NSNetworkDomainMask, gnustepNetworkApps, @"Developer");
	    ADD_PATH(NSSystemDomainMask, gnustepSystemApps, @"Developer");
	  */
	}
	break;

      case NSAdminApplicationDirectory:
	{
	  /* NSUserDomainMask - users have no Administrator directory */
	  /* ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserApps); */
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalApps);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkApps);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemApps);

	  /* I imagine if ever wanted a separate Administrator directory, the
	   * only way for this to have some meaning across filesystems
	   * would be as a subdirectory of Applications, as follows.
	   */
	  /*
	    ADD_PATH(NSLocalDomainMask, gnustepLocalApps, @"Administrator");
	    ADD_PATH(NSNetworkDomainMask, gnustepNetworkApps, @"Administrator");
	    ADD_PATH(NSSystemDomainMask, gnustepSystemApps, @"Administrator");
	  */
	}
	break;

      case NSAllLibrariesDirectory:
	{
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserLibraries);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalLibraries);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkLibraries);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemLibraries);
	}
	break;

      case NSLibraryDirectory:
	{
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserLibrary);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalLibrary);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkLibrary);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemLibrary);
	}
	break;

      case NSDeveloperDirectory:
	{
	  /* The only way of having a Developer directory is as a
	   * sub-dir of Library.
	   */
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"Developer");
	  ADD_PATH(NSLocalDomainMask, gnustepLocalLibrary, @"Developer");
	  ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibrary, @"Developer");
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"Developer");
	}
	break;

      case NSUserDirectory:
	{
	  if (domainMask & NSUserDomainMask)
	    {
	      [paths addObject: gnustepUserRoot];
	    }
	}
	break;

      case NSDocumentationDirectory:
	{
	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserDocumentation);
	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalDocumentation);
	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkDocumentation);
	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemDocumentation);
	}
	break;

      case NSDocumentDirectory:
	{
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"Document");
	  ADD_PATH(NSLocalDomainMask, gnustepLocalLibrary, @"Document");
	  ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibrary, @"Document");
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"Document");
	}
	break;

      case NSCachesDirectory:
	{
	  /* Uff - at the moment the only place to put Caches seems to
	   * be Library.  Unfortunately under GNU/Linux Library will
	   * end up in /usr/lib/GNUstep which could be mounted
	   * read-only!
	   */
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"Caches");
	  ADD_PATH(NSLocalDomainMask, gnustepLocalLibrary, @"Caches");
	  ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibrary, @"Caches");
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"Caches");
	}
	break;

      case NSApplicationSupportDirectory:
	{
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"ApplicationSupport");
	  ADD_PATH(NSLocalDomainMask, gnustepLocalLibrary, @"ApplicationSupport");
	  ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibrary, @"ApplicationSupport");
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"ApplicationSupport");
	}
	break;

      /* Now the GNUstep additions */
      case GSFrameworksDirectory:
	{
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"Frameworks");
	  ADD_PATH(NSLocalDomainMask, gnustepLocalLibrary, @"Frameworks");
	  ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibrary, @"Frameworks");
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"Frameworks");
	}
	break;

      case GSFontsDirectory:
	{
	  ADD_PATH(NSUserDomainMask, gnustepUserLibrary, @"Fonts");
	  ADD_PATH(NSLocalDomainMask, gnustepLocalLibrary, @"Fonts");
	  ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibrary, @"Fonts");
	  ADD_PATH(NSSystemDomainMask, gnustepSystemLibrary, @"Fonts");
	}
	break;

      case GSLibrariesDirectory:
	{
	  NSString *full = nil;
	  NSString *part = nil;

	  if ([gnustep_is_flattened boolValue] == NO
	    && gnustep_target_cpu != nil && gnustep_target_os != nil)
	    {
	      part = [gnustep_target_cpu stringByAppendingPathComponent:
		gnustep_target_os];
	      if (library_combo != nil)
		{
		  full = [part stringByAppendingPathComponent: library_combo];
		}
	    }

	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserLibraries);
	  if (full) ADD_PATH(NSUserDomainMask, gnustepUserLibraries, full);
	  if (part) ADD_PATH(NSUserDomainMask, gnustepUserLibraries, part);

	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalLibraries);
	  if (full) ADD_PATH(NSLocalDomainMask, gnustepLocalLibraries, full);
	  if (part) ADD_PATH(NSLocalDomainMask, gnustepLocalLibraries, part);

	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkLibraries);
	  if (full) ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibraries, full);
	  if (part) ADD_PATH(NSNetworkDomainMask, gnustepNetworkLibraries, part);

	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemLibraries);
	  if (full) ADD_PATH(NSSystemDomainMask, gnustepSystemLibraries, full);
	  if (part) ADD_PATH(NSSystemDomainMask, gnustepSystemLibraries, part);
	}
	break;

      case GSToolsDirectory:
	{
	  NSString	*full = nil;
	  NSString	*part = nil;

	  if ([gnustep_is_flattened boolValue] == NO
	    && gnustep_target_cpu != nil && gnustep_target_os != nil)
	    {
	      part = [gnustep_target_cpu stringByAppendingPathComponent:
		gnustep_target_os];
	      if (library_combo != nil)
		{
		  full = [part stringByAppendingPathComponent: library_combo];
		}
	    }

	  ADD_PLATFORM_PATH(NSUserDomainMask, gnustepUserTools);
	  if (full) ADD_PATH(NSUserDomainMask, gnustepUserTools, full);
	  if (part) ADD_PATH(NSUserDomainMask, gnustepUserTools, part);

	  ADD_PLATFORM_PATH(NSLocalDomainMask, gnustepLocalTools);
	  if (full) ADD_PATH(NSLocalDomainMask, gnustepLocalTools, full);
	  if (part) ADD_PATH(NSLocalDomainMask, gnustepLocalTools, part);

	  ADD_PLATFORM_PATH(NSNetworkDomainMask, gnustepNetworkTools);
	  if (full) ADD_PATH(NSNetworkDomainMask, gnustepNetworkTools, full);
	  if (part) ADD_PATH(NSNetworkDomainMask, gnustepNetworkTools, part);

	  ADD_PLATFORM_PATH(NSSystemDomainMask, gnustepSystemTools);
	  if (full) ADD_PATH(NSSystemDomainMask, gnustepSystemTools, full);
	  if (part) ADD_PATH(NSSystemDomainMask, gnustepSystemTools, part);
	}
	break;
    }

#undef ADD_PATH
#undef ADD_PLATFORM_PATH

  count = [paths count];
  for (i = 0; i < count; i++)
    {
      path = [paths objectAtIndex: i];

      if (expandTilde == YES)
        {
          [paths replaceObjectAtIndex: i
                           withObject: [path stringByExpandingTildeInPath]];
        }
      else
        {
          [paths replaceObjectAtIndex: i
            withObject: [path stringByAbbreviatingWithTildeInPath]];
        }
    }

  AUTORELEASE (paths);
  return paths;
}
