/* NSUrl.m - Class NSURL
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by: 	Manuel Guesdon <mguesdon@sbuilders.com>
   Date: 		Jan 1999
   
   This file is part of the GNUstep Library.
   
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

/*
Note from Manuel Guesdon: 
* I've made some test to compare apple NSURL results 
and GNUstep NSURL results but as there this class is not very documented, some
function may be incorrect
* I've put 2 functions to make tests. You can add your own tests
* Some functions are not implemented
*/
#include <config.h>
#include <base/behavior.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSConcreteNumber.h>
#include <Foundation/NSURLHandle.h>
#include <Foundation/NSURL.h>

NSString* NSURLFileScheme=@"file";

NSString* NSURLPartKey_host=@"host";
NSString* NSURLPartKey_port=@"port";
NSString* NSURLPartKey_user=@"user";
NSString* NSURLPartKey_password=@"password";
NSString* NSURLPartKey_path=@"path";
NSString* NSURLPartKey_fragment=@"fragment";
NSString* NSURLPartKey_parameterString=@"parameterString";
NSString* NSURLPartKey_query=@"query";

//=============================================================================
@implementation NSURL

//-----------------------------------------------------------------------------
+ (id) fileURLWithPath: (NSString*)_path
{
  return AUTORELEASE([[NSURL alloc] initFileURLWithPath: _path]);
}

//-----------------------------------------------------------------------------
+ (id)URLWithString: (NSString*)_urlString
{
  return AUTORELEASE([[NSURL alloc] initWithString: _urlString]);
}

//-----------------------------------------------------------------------------
+ (id)URLWithString: (NSString*)_urlString
	 relativeToURL: (NSURL*)_baseURL
{
  return AUTORELEASE([[NSURL alloc] initWithString: _urlString
				     relativeToURL: _baseURL]);
}

//-----------------------------------------------------------------------------
- (id) initWithScheme: (NSString*)_scheme
			   host: (NSString*)_host
			   path: (NSString*)_path
{
  NSString* _urlString=nil;
  if (_host)
	_urlString=[NSString stringWithFormat: @"%@: //%@",_scheme,_host];
  else
	_urlString=[NSString stringWithFormat: @"%@: ",_scheme];
  if (_path)
	_urlString=[_urlString stringByAppendingString: _path];
  self=[self initWithString: _urlString];
  return self;
}

//-----------------------------------------------------------------------------
//Non Standard Function
- (id) initWithScheme: (NSString*)_scheme
			   host: (NSString*)_host
			   port: (NSNumber*)_port
			   path: (NSString*)_path
{
  NSString* tmpHost=nil;
  if (_port)
	tmpHost=[NSString stringWithFormat: @"%@: %@",_host,_port];
  else
	tmpHost=_host;
  self=[self initWithScheme: _scheme
			 host: tmpHost
			 path: _path];
  return self;
}

//-----------------------------------------------------------------------------
//Do a initWithScheme: NSFileScheme host: nil path: _path
- (id) initFileURLWithPath: (NSString*)_path
{
  self=[self initWithScheme: NSURLFileScheme
			 host: nil
			 path: _path];
  return self;
}

//-----------------------------------------------------------------------------
// urlString is escaped
- (id) initWithString: (NSString*)_urlString
{
  self=[self init];
  ASSIGNCOPY(urlString,_urlString);
  return self;
}

//-----------------------------------------------------------------------------
//urlString!=nil 
// urlString is escaped
- (id) initWithString: (NSString*)_urlString
	  relativeToURL: (NSURL*)_baseURL
{
  self=[self init];
  ASSIGNCOPY(urlString,_urlString);
  ASSIGNCOPY(baseURL,_baseURL);
  return self;
}

//-----------------------------------------------------------------------------
- (void) dealloc
{
  DESTROY(urlString);
  DESTROY(baseURL);
  [super dealloc];
}

//-----------------------------------------------------------------------------
- (id) copyWithZone: (NSZone*)zone
{
  if (NSShouldRetainWithZone(self, zone) == NO)
    return [[isa allocWithZone: zone] initWithString: urlString
									  relativeToURL: baseURL];
  else
    return RETAIN(self);
}

//-----------------------------------------------------------------------------
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeObject: urlString];
  [aCoder encodeObject: baseURL];
  //FIXME? clients ?
}

//-----------------------------------------------------------------------------
- (id) initWithCoder: (NSCoder*)aCoder
{
  self = [super initWithCoder: aCoder];
  [aCoder decodeValueOfObjCType: @encode(id) at: &urlString];
  [aCoder decodeValueOfObjCType: @encode(id) at: &baseURL];
  //FIXME? clients ?
  return self;
}


//-----------------------------------------------------------------------------
- (NSString*) description
{
  NSString* dscr=urlString;
  if (baseURL)
	dscr=[dscr stringByAppendingFormat: @" -- %@",baseURL];
  return dscr;
}

//-----------------------------------------------------------------------------
// Non Standard Function
- (NSString*) baseURLAbsolutePart
{
  if (baseURL)
	{
	  NSString* suffix=[baseURL path];
	  NSString* tmp=nil;
	  if ([baseURL query])
		suffix=[suffix stringByAppendingFormat: @"?%@",[baseURL query]];
	  // /test?aa=bb&cc=dd -- http: //user: passwd@www.gnustep.org: 80/apache
	  //    ==> http: //user: passwd@www.gnustep.org: 80/
	  tmp=[[baseURL absoluteString]stringWithoutSuffix: suffix];

	  //    ==> http: //user: passwd@www.gnustep.org: 80
	  if ([tmp hasSuffix: @"/"])
		tmp=[tmp stringWithoutSuffix: @"/"];
	  return tmp;
	}
  else
	return @"";
}


//-----------------------------------------------------------------------------
- (NSString*) absoluteString
{
  NSString* absString=nil;
  if (baseURL)
	{
	  // /test?aa=bb&cc=dd -- http: //user: passwd@www.gnustep.org: 80/apache
	  //    ==> http: //user: passwd@www.gnustep.org: 80
	  absString=[self baseURLAbsolutePart];

	  if ([urlString hasPrefix: @"/"])
		absString=[absString stringByAppendingString: urlString];
	  else
		absString=[absString stringByAppendingFormat: @"/%@",urlString];
	}
  else
	absString=urlString;
  return absString;
}

//-----------------------------------------------------------------------------
- (NSString*) relativeString
{
  return urlString;
}

//-----------------------------------------------------------------------------
- (NSURL*) baseURL
{
  return baseURL;
}

//-----------------------------------------------------------------------------
- (NSURL*) absoluteURL
{
  if (!baseURL)
	return self;
  else
	  return [NSURL URLWithString: [self absoluteString]];
}

//-----------------------------------------------------------------------------
- (NSString*) scheme
{
  NSString* scheme=nil;
  NSString* absoluteString=[self absoluteString];
  NSRange range=[absoluteString rangeOfString: @": //"];
  if (range.length>0)
	scheme=[absoluteString substringToIndex: range.location];
  return scheme;
}

//-----------------------------------------------------------------------------
- (NSString*) resourceSpecifier
{
  NSString* absoluteString=[self absoluteString];
  NSRange range=[absoluteString rangeOfString: @": //"];
  if (range.length>0)
	return [absoluteString substringFromIndex: range.location+1];
  else
	return absoluteString;
}

//-----------------------------------------------------------------------------
//Non Standard Function
- (NSDictionary*) explode
{
  NSMutableDictionary* elements=nil;
  NSString* resourceSpecifier=[self resourceSpecifier];
  if ([resourceSpecifier hasPrefix: @"//"])
	{
	  int index=2;
	  NSRange range;
	  elements = [NSMutableDictionary dictionaryWithCapacity: 0];
	  if (![[self scheme] isEqualToString: NSURLFileScheme])
		{
		  range=[resourceSpecifier rangeOfString: @"/"
								   options: 0
								   range: NSMakeRange(index,[resourceSpecifier length]-index)];
		  if (range.length>0)
			{
			  NSString* userPasswordHostPort=[resourceSpecifier substringWithRange: NSMakeRange(index,range.location-index)];
			  NSString* userPassword=nil;
			  NSString* hostPort=nil;
			  index=range.location;
			  range=[userPasswordHostPort rangeOfString: @"@"];
			  if (range.length>0)
				{
				  if (range.location>0)
					userPassword=[userPasswordHostPort substringToIndex: range.location];
				  if (range.location+1<[userPasswordHostPort length])
					hostPort=[userPasswordHostPort substringFromIndex: range.location+1];
				}
			  else
				hostPort=userPasswordHostPort;
			  if (userPassword)
				{
				  range=[userPassword rangeOfString: @": "];
				  if (range.length>0)
					{
					  if (range.location>0)
						[elements setObject: [userPassword substringToIndex: range.location]
								  forKey: NSURLPartKey_user];
					  if (range.location+1<[userPassword length])
						[elements setObject: [userPassword substringFromIndex: range.location+1]
								  forKey: NSURLPartKey_password];
					}
				  else
					[elements setObject: userPassword
							  forKey: NSURLPartKey_user];
				}

			  if (hostPort)
				{
				  range=[hostPort rangeOfString: @": "];
				  if (range.length>0)
					{
					  if (range.location>0)
						[elements setObject: [hostPort substringToIndex: range.location]
								  forKey: NSURLPartKey_host];
					  if (range.location+1<[hostPort length])
						[elements setObject: [NSNumber valueFromString: 
														[hostPort substringFromIndex: range.location+1]]
								  forKey: NSURLPartKey_port];
					}
				  else
					[elements setObject: hostPort
							  forKey: NSURLPartKey_host];
				};		  
			}
		}
	  else
		index--; //To Take a /
	  range=[resourceSpecifier rangeOfString: @"?"
							   options: 0
							   range: NSMakeRange(index,[resourceSpecifier length]-index)];
	  if (range.length>0)
		{
		  if (range.location>0)
			[elements setObject: [resourceSpecifier substringWithRange: NSMakeRange(index,range.location-index)]
					  forKey: NSURLPartKey_path];
		  if (range.location+1<[resourceSpecifier length])
			[elements setObject: [resourceSpecifier substringFromIndex: range.location+1]
					  forKey: NSURLPartKey_query];
		}
	  else
		[elements setObject: [resourceSpecifier substringFromIndex: index]
				  forKey: NSURLPartKey_path];
	}
  else
	{
	  [NSException raise: NSGenericException
				   format: @"'%@' is a bad URL",self];
	}
  return elements;
}

//-----------------------------------------------------------------------------
- (NSString*) host
{
  return [[self explode] objectForKey: NSURLPartKey_host];
}

//-----------------------------------------------------------------------------
- (NSNumber*) port;
{
  return [[self explode] objectForKey: NSURLPartKey_port];
}

//-----------------------------------------------------------------------------
- (NSString*) user;
{
  return [[self explode] objectForKey: NSURLPartKey_user];
}

//-----------------------------------------------------------------------------
- (NSString*) password;
{
  return [[self explode] objectForKey: NSURLPartKey_password];
}

//-----------------------------------------------------------------------------
- (NSString*) path;
{
  return [[self explode] objectForKey: NSURLPartKey_path];
}

//-----------------------------------------------------------------------------
- (NSString*) fragment;
{
  return [[self explode] objectForKey: NSURLPartKey_fragment];
}

//-----------------------------------------------------------------------------
- (NSString*) parameterString;
{
  return [[self explode] objectForKey: NSURLPartKey_parameterString];
}

//-----------------------------------------------------------------------------
- (NSString*) query;
{
  return [[self explode] objectForKey: NSURLPartKey_query];
}

//-----------------------------------------------------------------------------
- (NSString*) relativePath
{
  //FIXME?
  return [self path];
}

//-----------------------------------------------------------------------------
- (BOOL) isFileURL
{
  return [[self scheme] isEqualToString: NSURLFileScheme];
}

//-----------------------------------------------------------------------------
- (NSURL*) standardizedURL
{
  //FIXME
  [self notImplemented: _cmd];
  return nil;
}

//-----------------------------------------------------------------------------
- (void)					URLHandle: (NSURLHandle*)sender
   resourceDataDidBecomeAvailable: (NSData*)newData
{
  //FIXME
  [self notImplemented: _cmd];
}

//-----------------------------------------------------------------------------
- (void)URLHandleResourceDidBeginLoading: (NSURLHandle*)sender
{
  //FIXME
  [self notImplemented: _cmd];
}

//-----------------------------------------------------------------------------
- (void)URLHandleResourceDidFinishLoading: (NSURLHandle*)sender
{
  //FIXME
  [self notImplemented: _cmd];
}

//-----------------------------------------------------------------------------
- (void)URLHandleResourceDidCancelLoading: (NSURLHandle*)sender
{
  //FIXME
  [self notImplemented: _cmd];
}

//-----------------------------------------------------------------------------
- (void)						URLHandle: (NSURLHandle*)sender
	 resourceDidFailLoadingWithReason: (NSString*)reason
{
  //FIXME
  [self notImplemented: _cmd];
}

//-----------------------------------------------------------------------------
//FIXME: delete these fn when NSURL will be validated
+ (void) test
{
  NSURL* url2;
  NSURL* url3;
  NSURL* url=[NSURL URLWithString: @"http: //user: passwd@www.gnustep.org: 80/apache"];
  url2=[NSURL URLWithString: @"/test?aa=bb&cc=dd" relativeToURL: url];
  url3=[NSURL URLWithString: @"test?aa=bb&cc=dd" relativeToURL: url];
  NSLog(@"===url===");
  [NSURL testPrint: url];
  NSLog(@"===url2===");
  [NSURL testPrint: url2];
  NSLog(@"===url3===");
  [NSURL testPrint: url3];
}

+ (void) testPrint: (NSURL*)url
{
  id _baseURL=nil;
  id _urlString=nil;
  void* _clients=0;
  GSGetInstanceVariable(url,@"baseURL",&_baseURL);
  GSGetInstanceVariable(url,@"urlString",&_urlString);
  GSGetInstanceVariable(url,@"clients",&_clients);
  NSLog(@"*BaseURL: %ld",(long)_baseURL);
  NSLog(@"*BaseURL: %@",[_baseURL description]);
  NSLog(@"*urlString: %@",_urlString);
  NSLog(@"*clients: %ld",(long)_clients);
  NSLog(@"*host: %@",[url host]);
  NSLog(@"*port: %@",[url port]);
  NSLog(@"*user: %@",[url user]);
  NSLog(@"*password: %@",[url password]);
  NSLog(@"*path: %@",[url path]);
  NSLog(@"*fragment: %@",[url fragment]);
  NSLog(@"*parameterString: %@",[url parameterString]);
  NSLog(@"*query: %@",[url query]);
  NSLog(@"*relativePath: %@",[url relativePath]);
  NSLog(@"*absoluteString: %@",[url absoluteString]);
  NSLog(@"*relativeString: %@",[url relativeString]);
  NSLog(@"*baseURL: %@",[[url baseURL] description]);
  NSLog(@"*absoluteURL: %@",[[url absoluteURL] description]);
  NSLog(@"*scheme: %@",[url scheme]);
  NSLog(@"*resourceSpecifier: %@",[url resourceSpecifier]);
  NSLog(@"*description: %@",[url description]);
}
@end

//=============================================================================
@implementation NSURL (NSURLLoading)

//-----------------------------------------------------------------------------
- (NSData*) resourceDataUsingCache: (BOOL)shouldUseCache
{
  //FIXME
  [self notImplemented: _cmd];
  return nil;
}

//-----------------------------------------------------------------------------
- (void) loadResourceDataNotifyingClient: (id)client
							usingCache: (BOOL)shouldUseCache
{
  //FIXME
  [self notImplemented: _cmd];
}

//-----------------------------------------------------------------------------
- (NSURLHandle*)URLHandleUsingCache: (BOOL)shouldUseCache
{
  //FIXME
  [self notImplemented: _cmd];
  return nil;
}

//-----------------------------------------------------------------------------
- (BOOL) setResourceData: (NSData*)data
{
  //FIXME
  [self notImplemented: _cmd];
  return NO;
}

//-----------------------------------------------------------------------------
- (id) propertyForKey: (NSString*)propertyKey
{
  //FIXME
  [self notImplemented: _cmd];
  return nil;
}

//-----------------------------------------------------------------------------
- (BOOL) setProperty: (id)property
	      forKey: (NSString*)propertyKey;
{
  //FIXME
  [self notImplemented: _cmd];
  return NO;
}

@end

//=============================================================================
@implementation NSObject (NSURLClient)

//-----------------------------------------------------------------------------
- (void) URL: (NSURL*)sender
	 resourceDataDidBecomeAvailable: (NSData*)newBytes
{
  //FIXME
  [self notImplemented: _cmd];

}

//-----------------------------------------------------------------------------
- (void) URLResourceDidFinishLoading: (NSURL*)sender
{
  //FIXME
  [self notImplemented: _cmd];

}

//-----------------------------------------------------------------------------
- (void) URLResourceDidCancelLoading: (NSURL*)sender
{
  //FIXME
  [self notImplemented: _cmd];

}

//-----------------------------------------------------------------------------
- (void) URL: (NSURL*)sender
   resourceDidFailLoadingWithReason: (NSString*)reason
{
  //FIXME
  [self notImplemented: _cmd];
}

@end
