/* A demonstration of writing and reading GNU Objective C objects to a file,
   in human-readable text format.
   Look at the file "textcoding.txt" after running this program to see the
   text archive format.
   */

#include <objects/Archiver.h>
#include <objects/TextCStream.h>
#include <objects/Set.h>
#include <objects/EltNodeCollector.h>
#include <objects/LinkedList.h>
#include <objects/LinkedListEltNode.h>
#include <objects/NSString.h>
#include <Foundation/NSAutoreleasePool.h>

int main()
{
  id set, ll;
  id archiver;
  id name;
  id arp;
  
  arp = [[NSAutoreleasePool alloc] init];

  /* Create a Set of int's
     and a LinkedList of float's */
  set = [[Set alloc] initWithType:@encode(int)];
  ll = [[EltNodeCollector alloc] initWithType:@encode(float)
	nodeCollector:[[LinkedList alloc] init]
	nodeClass:[LinkedListEltNode class]];

  /* Populate the Set and display it */
  [set addElement:1234567];
  [set addElement:2345678];
  [set addElement:3456789];
  [set addElement:4567891];
  [set addElement:5678912];
  [set printForDebugger];

  /* Populate the LinkedList and display it */
  [ll addElement:1.2f];
  [ll addElement:(float)3.4];
  [ll addElement:(float)5.6];
  [ll addElement:(float)7.8];
  [ll addElement:(float)9.0];
  [ll printForDebugger];

  /* Write them to a file */

  /* Create an instances of the Archiver class, specify that we 
     want human-readable "Text"-style, instead of "Binary"-style
     coding. */
  archiver = [[Archiver alloc] initForWritingToFile: @"./textcoding.txt"
	    withCStreamClass: [TextCStream class]];
  [archiver encodeObject:set withName:@"Test Set"];
  [archiver encodeObject:ll withName:@"Test EltNodeCollector LinkedList"];

  /* Release the objects that were coded */
  [set release];
  [ll release];

  /* Close the archiver, (and thus flush the stream); then release it.
     We must separate the idea of "closing" a stream and
     "deallocating" a stream because of delays in deallocation due to
     -autorelease. */
  [archiver closeCoding];
  [archiver release];


  /* Read them back in from the file */

  /* First create the unarchiver */
  archiver = [Unarchiver newReadingFromFile: @"./textcoding.txt"];

  /* Read in the Set */
  [archiver decodeObjectAt:&set withName:&name];
  printf("got object named %@\n", name);

  /* Read in the LinkedList */
  [archiver decodeObjectAt:&ll withName:&name];
  printf("got object named %@\n", name);

  /* Display what we read, to make sure it matches what we wrote */
  [set printForDebugger];
  [ll printForDebugger];

  /* Relase the objects we read */
  [set release];
  [ll release];

  /* Release the unarchiver. */
  [archiver release];

  /* Do the autorelease. */
  [arp release];
  
  exit(0);
}
