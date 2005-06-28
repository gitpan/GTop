/* $Id: version.c 1020 2005-04-25 20:37:15Z stas $ */

/* Copyright (C) 1998-99 Martin Baulig
   This file is part of LibGTop 1.0.

   Contributed by Martin Baulig <martin@home-of-linux.org>, April 1998.

   LibGTop is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License,
   or (at your option) any later version.

   LibGTop is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with LibGTop; see the file COPYING. If not, write to the
   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.
*/

#include <glibtop.h>
#include <glibtop/command.h>
#include <glibtop/error.h>
#include <glibtop/version.h>

#if 0
#ifdef LIBGTOP_SERVER_VERSION
# undef LIBGTOP_SERVER_VERSION
# define LIBGTOP_SERVER_VERSION "50"
# define LIBGTOP_VERSION "1.1.2"
#endif
#endif

#ifndef LIBGTOP_VERSION
#define LIBGTOP_VERSION "1.0.2"
#endif

#ifndef LIBGTOP_SERVER_VERSION
#define LIBGTOP_SERVER_VERSION "5"
#endif

void
glibtop_send_version (glibtop *server, int fd)
{
	char buffer [BUFSIZ];
	size_t size;

	sprintf (buffer, LIBGTOP_VERSION_STRING,
		 LIBGTOP_VERSION, LIBGTOP_SERVER_VERSION,
		 sizeof (glibtop_command),
		 sizeof (glibtop_response),
		 sizeof (glibtop_union),
		 sizeof (glibtop_sysdeps));
	
	size = strlen (buffer) + 1;

#ifdef DEBUG
	fprintf (stderr, "SERVER ID: |%s|\n", buffer);
#endif

	if (fd == 0) {
		if (write (1, (const void *) &size, sizeof (size)) < 0)
			glibtop_warn_io_r (server, "write");
	} else {
		if (send (fd, (const void *) &size, sizeof (size), 0) < 0)
			glibtop_warn_io_r (server, "send");
	}

	if (fd == 0) {
		if (write (1, (const void *) buffer, size) < 0)
			glibtop_warn_io_r (server, "write");
	} else {
		if (send (fd, (const void *) buffer, size, 0) < 0)
			glibtop_warn_io_r (server, "send");
	}
}