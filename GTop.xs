#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <glib.h>
#include <glibtop.h>
#include <glibtop/open.h>
#include <glibtop/close.h>
#include <glibtop/xmalloc.h>
#include <glibtop/parameter.h>
#include <glibtop/union.h>
#include <glibtop/sysdeps.h>

typedef struct {
    glibtop_union data;
    glibtop_sysdeps sysdeps;
} PerlGTop;

typedef PerlGTop * GTop;

#define OffsetOf(structure, field) \
(guint32)(&((structure *)NULL)->field)

#define any_ptr_deref(structure) \
((char *)structure + (int)(long)CvXSUBANY(cv).any_ptr)

#define newGTopXS(name, structure, field) \
    CvXSUBANY(newXS(name, XS_GTop_field, __FILE__)).any_ptr = \
		    (void *)OffsetOf(structure, field);

XS(XS_GTop_field) 
{ 
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    u_int64_t **ptr = (u_int64_t **)any_ptr_deref(s);

    ST(0) = sv_2mortal(newSViv((IV)*ptr));

    XSRETURN(1); 
}

#include "gtop.boot"
#include "gtopxs.boot"

MODULE = GTop   PACKAGE = GTop

PROTOTYPES: disable

BOOT:
    glibtop_init();
    boot_GTop_interface();

INCLUDE: xs.gtop

void
END()

    CODE:
    glibtop_close();

GTop
new(CLASS)
    char *CLASS

    CODE:
    RETVAL = (PerlGTop *)safemalloc(sizeof(*RETVAL));

    OUTPUT:
    RETVAL

void
DESTROY(gtop)
    GTop gtop

    CODE:
    safefree(gtop);
