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

typedef SV * GTop;

#define OffsetOf(structure, field) \
(guint32)(&((structure *)NULL)->field)

#define any_ptr_deref(structure) \
((char *)structure + (int)(long)CvXSUBANY(cv).any_ptr)

#define newGTopXS(name, structure, field, type) \
    CvXSUBANY(newXS(name, XS_GTop_field_##type, __FILE__)).any_ptr = \
		    (void *)OffsetOf(structure, field);

#define newGTopXS_u_int64_t(name, structure, field) \
newGTopXS(name, structure, field, u_int64_t)

#define newGTopXS_char(name, structure, field) \
newGTopXSub(name, structure, field, char)

XS(XS_GTop_field_u_int64_t) 
{ 
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    u_int64_t **ptr = (u_int64_t **)any_ptr_deref(s);

    ST(0) = sv_2mortal(newSViv((IV)*ptr));

    XSRETURN(1); 
}

XS(XS_GTop_field_char) 
{ 
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    char **ptr = (char **)any_ptr_deref(s);

    ST(0) = sv_2mortal(newSVpv((char *)*ptr, 0));

    XSRETURN(1); 
}

XS(XS_GTop_destroy)
{
    dXSARGS; 

    void *s = (void *)SvIV((SV*)SvRV(ST(0)));
    safefree(s);

    XSRETURN_EMPTY;
}

static void boot_GTop_constants(void)
{
    HV *stash = gv_stashpv("GTop", TRUE);
    (void)newCONSTSUB(stash, "MAP_PERM_READ", 
		      newSViv(GLIBTOP_MAP_PERM_READ));
    (void)newCONSTSUB(stash, "MAP_PERM_WRITE", 
		      newSViv(GLIBTOP_MAP_PERM_WRITE));
    (void)newCONSTSUB(stash, "MAP_PERM_EXECUTE", 
		      newSViv(GLIBTOP_MAP_PERM_EXECUTE));
    (void)newCONSTSUB(stash, "MAP_PERM_SHARED", 
		      newSViv(GLIBTOP_MAP_PERM_SHARED));
    (void)newCONSTSUB(stash, "MAP_PERM_PRIVATE", 
		      newSViv(GLIBTOP_MAP_PERM_PRIVATE));
}

#include "gtop.boot"
#include "gtopxs.boot"

MODULE = GTop   PACKAGE = GTop

PROTOTYPES: disable

BOOT:
    glibtop_init();
    boot_GTop_interface();
    boot_GTop_constants();

INCLUDE: xs.gtop

void
END()

    CODE:
    glibtop_close();

GTop
new(CLASS)
    SV *CLASS

    CODE:
    RETVAL = CLASS;

    OUTPUT:
    RETVAL

void
mountlist(gtop, all_fs)
    GTop gtop
    int all_fs

    PREINIT:
    GTop__Mountlist	RETVAL;
    GTop__Mountentry	entry;
    SV *svl, *sve;

    PPCODE:
    RETVAL = (glibtop_mountlist *)safemalloc(sizeof(*RETVAL));
    entry = glibtop_get_mountlist(RETVAL, all_fs);

    svl = sv_newmortal();
    sv_setref_pv(svl, "GTop::Mountlist", (void*)RETVAL);
    XPUSHs(svl);

    if (GIMME_V == G_ARRAY) {
	sve = sv_newmortal();
	sv_setref_pv(sve, "GTop::Mountentry", (void*)entry);
	XPUSHs(sve);
    }

void
proc_map(gtop, pid)
    GTop gtop
    pid_t pid

    PREINIT:
    GTop__ProcMap	RETVAL;
    GTop__MapEntry	entry;
    SV *svl, *sve;

    PPCODE:
    RETVAL = (glibtop_proc_map *)safemalloc(sizeof(*RETVAL));
    entry = glibtop_get_proc_map(RETVAL, pid);

    svl = sv_newmortal();
    sv_setref_pv(svl, "GTop::ProcMap", (void*)RETVAL);
    XPUSHs(svl);

    if (GIMME_V == G_ARRAY) {
	sve = sv_newmortal();
	sv_setref_pv(sve, "GTop::MapEntry", (void*)entry);
	XPUSHs(sve);
    }

MODULE = GTop   PACKAGE = GTop::Mountentry   PREFIX = Mountlist_

void
DESTROY(entries)
    GTop::Mountentry entries

    CODE:
    glibtop_free(entries);

#define Mountlist_devname(entries, idx) entries[idx].devname
#define Mountlist_type(entries, idx) entries[idx].type
#define Mountlist_mountdir(entries, idx) entries[idx].mountdir
#define Mountlist_dev(entries, idx) entries[idx].dev

char *
Mountlist_devname(entries, idx=0)
    GTop::Mountentry entries
    int idx

char *
Mountlist_type(entries, idx=0)
    GTop::Mountentry entries
    int idx

char *
Mountlist_mountdir(entries, idx=0)
    GTop::Mountentry entries
    int idx

u_int64_t
Mountlist_dev(entries, idx=0)
    GTop::Mountentry entries
    int idx

MODULE = GTop   PACKAGE = GTop::MapEntry   PREFIX = MapEntry_

void
DESTROY(entries)
    GTop::MapEntry entries

    CODE:
    glibtop_free(entries);

char *
perm_string(entries, idx)
    GTop::MapEntry entries
    int idx

    PREINIT:
    char perm[6];

    CODE:
    perm[0] = (entries[idx].perm & GLIBTOP_MAP_PERM_READ) ? 'r' : '-';
    perm[1] = (entries[idx].perm & GLIBTOP_MAP_PERM_WRITE) ? 'w' : '-';
    perm[2] = (entries[idx].perm & GLIBTOP_MAP_PERM_EXECUTE) ? 'x' : '-';
    perm[3] = (entries[idx].perm & GLIBTOP_MAP_PERM_SHARED) ? 's' : '-';
    perm[4] = (entries[idx].perm & GLIBTOP_MAP_PERM_PRIVATE) ? 'p' : '-';
    perm[5] = '\0';
    RETVAL = perm;

    OUTPUT:
    RETVAL

#define MapEntry_flags(entries, idx) entries[idx].flags
#define MapEntry_start(entries, idx) entries[idx].start
#define MapEntry_end(entries, idx) entries[idx].end
#define MapEntry_offset(entries, idx) entries[idx].offset
#define MapEntry_perm(entries, idx) entries[idx].perm
#define MapEntry_inode(entries, idx) entries[idx].inode
#define MapEntry_device(entries, idx) entries[idx].device
#define MapEntry_filename(entries, idx) entries[idx].filename
#define MapEntry_has_filename(entries, idx) (entries[idx].flags & (1L << GLIBTOP_MAP_ENTRY_FILENAME))

u_int64_t
MapEntry_flags(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_start(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_end(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_offset(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_perm(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_inode(entries, idx=0)
    GTop::MapEntry entries
    int idx

u_int64_t
MapEntry_device(entries, idx=0)
    GTop::MapEntry entries
    int idx

char *
MapEntry_filename(entries, idx=0)
    GTop::MapEntry entries
    int idx

    CODE:
    if (MapEntry_has_filename(entries, idx)) {
	RETVAL = MapEntry_filename(entries, idx);
    }
    else {
	XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
