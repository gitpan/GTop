use ExtUtils::MakeMaker;

use strict;

my %interface = (
    'cpu' => [qw(flags total user nice sys idle frequency)],
    'mem' => [qw(flags total used free shared buffer cached user locked)],
    'proc_mem'  => [qw(flags size vsize resident share rss rss_rlim)],
    'proc_time' => [qw(flags start_time rtime utime stime cutime cstime
		       timeout it_real_value frequency)],
);

open TYPEMAP, ">typemap.gtop" or die $!;
open BOOTINC, ">gtop.boot" or die $!;
open BOOTXS, ">gtopxs.boot" or die $!;
open XS, ">xs.gtop" or die $!;
open POD, ">GTop.pod" or die $!;
open TEST, ">test.gtop" or die $!;

print BOOTXS "static void boot_GTop_interface(void)\n{\n";

print TEST <<'EOF';
use strict;
use ExtUtils::testlib;
use GTop ();

my $gtop = GTop->new;

EOF

print POD <<EOF;
=head1 NAME

GTop - Perl interface to libgtop

=head1 SYNOPSIS

 use GTop ();
 my \$gtop = GTop->new;

=head1 DESCRIPTION

Perl interface to libgtop:

 http://home-of-linux.org/gnome/libgtop/

=head1 CLASSES

EOF

for my $if (sort keys %interface) {
    local *FH;
    (my $leaf = $if) =~ s/_(.)/uc $1/e;
    my $class = sprintf "GTop::%s", ucfirst $leaf;
    (my $typedef = $class) =~ s/:/_/g;

    print BOOTXS "    boot_GTop_$if();\n";

    print TYPEMAP "$class\tT_PTROBJ\n";

    print BOOTINC "typedef glibtop_$if * $typedef;\n";
    print BOOTINC qq(\#include "$if.boot"\n);

    my(@pid) = ($if =~ /^proc_/) ? 
      (', pid', 'pid_t pid', '($pid)', '($$)') : ('','','','()');
    print XS <<EOF;

$class
$if(gtop$pid[0])
    GTop gtop
    $pid[1]

    CODE:
    glibtop_get_$if(&gtop->data.$if$pid[0]);
    RETVAL = &gtop->data.$if;

    OUTPUT:
    RETVAL

EOF

    print TEST <<EOF;

my \$$if = \$gtop->$if$pid[3];
print "$if\\n";
for (qw(@{ $interface{$if} })) {
    printf "   %s => %d\\n", \$_, \$$if->\$_$pid[3];
}

EOF

    print POD "\n=head2 $class\n\n";
    print POD "\n    my \$$if = \$gtop->$if$pid[2];\n\n";
    print POD "=over 4\n\n";

    open FH, ">$if.boot" or die $!;

    print FH "static void boot_GTop_$if (void)\n{\n";

    for my $field (@{ $interface{$if} }) {
	print FH qq{   newGTopXS("$class\::$field", glibtop_$if, $field);\n};
	print POD "\n=item $field\n\n";
	print POD "    my \$$field = \$$if->$field;\n\n";
    }

    print FH "\n}\n";

    print POD "\n\n=back\n\n";
}

print BOOTXS "\n}\n";
print POD <<EOF;

=head1 AUTHOR

Doug MacEachern

EOF

close TYPEMAP;
close BOOTINC;
close BOOTXS;
close XS;
close POD;
close TEST;

chomp(my $ginc = `glib-config --cflags`);

WriteMakefile(
   NAME => 'GTop',
   VERSION_FROM => 'GTop.pm',
   INC => $ginc,
   LIBS => ["-lgtop -lgtop_sysdeps -lgtop_common -lglib"],
   TYPEMAPS => [qw(typemap.gtop typemap)],
   clean   => {
       FILES => "@{[<*.boot>, <*.gtop>]}",
   },
);
