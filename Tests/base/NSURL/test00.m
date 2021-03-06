#import <Foundation/Foundation.h>
#import "Testing.h"
#import "ObjectTesting.h"


int main()
{
#if     GNUSTEP
  NSAutoreleasePool   *arp = [NSAutoreleasePool new];
  unsigned		i, j;
  NSURL			*url;
  NSURL			*u;
  NSData		*data;
  NSMutableData		*resp;
  NSData		*cont;
  NSString		*str;
  NSMutableString	*m;
  NSTask		*t;
  NSString		*helpers;
  NSString		*capture;
  NSString		*respond;
  
  helpers = [[NSFileManager defaultManager] currentDirectoryPath];
  helpers = [helpers stringByAppendingPathComponent: @"Helpers"];
  helpers = [helpers stringByAppendingPathComponent: @"obj"];
  capture = [helpers stringByAppendingPathComponent: @"capture"];
  respond = [helpers stringByAppendingPathComponent: @"respond"];

  url = [NSURL URLWithString: @"http://localhost:54321/"];

  /* Ask the 'respond' helper to send back a response containing
   * 'hello' and to shrink the write buffer size it uses on each
   * request.  We do as many requests as the total response size
   * so that on the last one, the 'respond' program writes data
   * a byte at a time.
   * This tests that the URL loading code can handle a request
   * that arrives fragmented rather than in a single read.
   */
  m = [NSMutableString stringWithCapacity: 2048];
  for (i = 0; i < 128; i++)
    {
      [m appendFormat: @"Hello %d\r\n", i];
    }
  cont = [m dataUsingEncoding: NSASCIIStringEncoding];
  resp = AUTORELEASE([[@"HTTP/1.0 200\r\n\r\n"
    dataUsingEncoding: NSASCIIStringEncoding] mutableCopy]);
  [resp appendData: cont];
  [resp writeToFile: @"SimpleResponse.dat" atomically: YES];

  str = [NSString stringWithFormat: @"%u", [resp length]];
  t = [NSTask launchedTaskWithLaunchPath: respond
    arguments: [NSArray arrayWithObjects:
    @"-FileName", @"SimpleResponse.dat",
    @"-Shrink", @"YES",
    @"-Count", str,
    nil]];
  if (t != nil)
    {
      // Pause to allow server subtask to set up.
      [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
      i = [resp length];
      while (i-- > 0)
        {
	  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
	  char	buf[128];

	  /* Just to test caching of url handles, we use eighteen
	   * different URLs (we know the cache size is 16) to ensure
	   * that loads work when handles are flushed from the cache.
	   */
	  u = [NSURL URLWithString: [NSString stringWithFormat:
	    @"http://localhost:54321/%d", i % 18]];
          // Talk to server.
          data = [u resourceDataUsingCache: NO];
          // Get status code
          str = [u propertyForKey: NSHTTPPropertyStatusCodeKey];
	  sprintf(buf, "respond test %d OK", i);
	  PASS([data isEqual: cont], "%s", buf)
	  [pool release];
	}
      // Wait for server termination
      [t terminate];
      [t waitUntilExit];
    }
  
  /* Now build a response which pretends to be an HTTP1.1 server and should
   * support connection keepalive ... so we can test that the keeplive code
   * correctly handles the case where the remote end drops the connection.
   */
  cont = [@"hello" dataUsingEncoding: NSASCIIStringEncoding];
  resp = AUTORELEASE([[@"HTTP/1.1 200\r\nContent-Length: 5\r\n\r\n"
    dataUsingEncoding: NSASCIIStringEncoding] mutableCopy]);
  [resp appendData: cont];
  [resp writeToFile: @"SimpleResponse.dat" atomically: YES];

  str = [NSString stringWithFormat: @"%u", [resp length]];

  for (j = 0; j < 13 ; j += 4)
    {
      NSString *delay = [NSString stringWithFormat: @"%u", j];

      t = [NSTask launchedTaskWithLaunchPath: respond
         arguments: [NSArray arrayWithObjects:
	         @"-FileName", @"SimpleResponse.dat",
		 @"-Count", @"2", @"-Pause", delay,
		 nil]];      
      if (t != nil)
        {
          // Pause to allow server subtask to set up.
          [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]];
          for (i = 0; i < 2; i++)
            {
	      NSAutoreleasePool	*pool = [NSAutoreleasePool new];
	      char	buf[128];

              // Talk to server.
              data = [url resourceDataUsingCache: NO];
              // Get status code
              str = [url propertyForKey: NSHTTPPropertyStatusCodeKey];
	      sprintf(buf, "respond with keepalive %d (pause %d) OK", i, j);
	      PASS([data isEqual: cont], "%s", buf)
	      [pool release];
	      /* Allow remote end time to close socket.
	       */
              [NSThread sleepUntilDate:
	        [NSDate dateWithTimeIntervalSinceNow: 0.1]];
	    }
          /* Kill helper task and wait for it to finish */
          [t terminate];
          [t waitUntilExit];
        }
    }
  [arp release]; arp = nil;
#endif
  return 0;
}
