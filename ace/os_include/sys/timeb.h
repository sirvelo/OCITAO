// -*- C++ -*-

//=============================================================================
/**
 *  @file    timeb.h
 *
 *  additional definitions for date and time
 *
 *  $Id$
 *
 *  @author Don Hinton <dhinton@ieee.org>
 *  @author This code was originally in various places including ace/OS.h.
 */
//=============================================================================

#ifndef ACE_OS_INCLUDE_SYS_TIMEB_H
#define ACE_OS_INCLUDE_SYS_TIMEB_H

#include "ace/pre.h"

#include "ace/config-all.h"

#if !defined (ACE_LACKS_PRAGMA_ONCE)
# pragma once
#endif /* ACE_LACKS_PRAGMA_ONCE */

#include "ace/os_include/sys/types.h"

#if !defined (ACE_LACKS_SYS_TIMEB_H)
# include /**/ <sys/timeb.h>
#endif /* !ACE_LACKS_SYS_TIMEB_H */

#   if defined (__BORLANDC__)
#     define _ftime ftime
#     define _timeb timeb
#   endif /* __BORLANDC__ */

#include "ace/post.h"
#endif /* ACE_OS_INCLUDE_TIMEB_H */
