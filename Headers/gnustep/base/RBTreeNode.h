/* Interface for Objective-C RBTreeNode object
   Copyright (C) 1993,1994 Free Software Foundation, Inc.

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

#ifndef __RBTreeNode_h_GNUSTEP_BASE_INCLUDE
#define __RBTreeNode_h_GNUSTEP_BASE_INCLUDE

#include <base/preface.h>
#include <base/BinaryTreeNode.h>
#include <base/RBTree.h>

@interface RBTreeNode : BinaryTreeNode <RBTreeComprising>
{
  BOOL _red;
}
@end

#endif /* __RBTreeNode_h_GNUSTEP_BASE_INCLUDE */
