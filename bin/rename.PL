use Config;
use File::Basename qw(basename dirname);

($VERSION)=' $Id: rename.PL,v 1.2 2000/01/26 12:46:45 pederst Exp $ '=~/v\s*(\d+(?:\.\d+)+)/;

chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($Config{'osname'} eq 'VMS' or
            $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file\n";

print OUT <<"!DO!SUBST!";
$Config{'startperl'}

#line 18

use Getopt::Long 2.17;
use Text::Abbrev;

\$VERSION = '$VERSION';

!DO!SUBST!

print OUT<<'!NO!SUBST!';
Getopt::Long::config(qw(bundling));
$Getopt::Long::prefix = '--';

($ME = $0) =~ s!.*/!!;
$| = 1;

$nothing         = 0;
$backup          = 0;
$force           = 0;
$interactive     = 0;
$verbose         = 0;
$help            = 0;
$version         = 0;
$linkonly        = 0;
$backup_suffix   = $ENV{SIMPLE_BACKUP_SUFFIX} || '~';
$version_control = $ENV{VERSION_CONTROL} || 'existing';

sub error {
    my($ERROR) = @_;
    print "$ME: $ERROR\n";
    print "try: `$ME --help' for more information.\n";
    exit 1;
}

{
    local $SIG{__WARN__} = sub {
	if ($_[0] =~ /^Unknown option: (\S+)/) {
	    error("unrecognized option `--$1'");
	} else {
	    print @_;
	}
    };
    GetOptions(
	       'b|backup'             => \$backup,
	       'f|force'              => \$force,
	       'i|interactive'        => \$interactive,
	       'v|verbose'            => \$verbose,
	       'S|suffix=s'           => \$backup_suffix,
	       'V|version-control=s'  => \$version_control,
	       'n|just-print|dry-run' => \$nothing,
               'l|link-only'          => \$linkonly,
	       'help'                 => \$help,
	       'version'              => \$version,
	      );
}

if ($version) {
    print "rename $VERSION\n";
    exit 0;
}

if ($help) {
    print<<HELP;
Usage: rename [OPTION]... PERLEXPR FILE...
Rename FILE(s) using PERLEXPR on each filename.

  -b, --backup                 make backup before removal
  -f, --force                  remove existing destinations, never prompt
  -i, --interactive            prompt before overwrite
  -S, --suffix=SUFFIX          override the usual backup suffix
  -v, --verbose                explain what is being done
  -V, --version-control=WORD   override the usual version control
  -n, --just-print, --dry-run  don't rename, implies --verbose
  -l, --link-only              link file instead of reame
      --help                   display this help and exit
      --version                output version information and exit

The backup suffix is ~, unless set with SIMPLE_BACKUP_SUFFIX.  The
version control may be set with VERSION_CONTROL, values are:

  t, numbered     make numbered backups
  nil, existing   numbered if numbered backups exist, simple otherwise
  never, simple   always make simple backups

Report bugs to pederst\@cpan.org
HELP
    exit 0; #'
}

sub VCM_TEST     { 0x0001 }
sub VCM_NUMBERED { 0x0002 }

if ($backup) {
    $vcm = ${abbrev qw(nil existing t numbered never simple)}{$version_control};
    error("invalid version contol type `$version_control'") unless $vcm;
    $vcm = ${{ nil      => VCM_TEST,
	       existing => VCM_TEST,
	       t        => VCM_NUMBERED,
	       numbered => VCM_NUMBERED,
	       never    => 0,
	       simple   => 0,
	   }}{$vcm};
}

$op = shift
    or error('missing arguments');

if (!@ARGV) {
    @ARGV = <STDIN>;
    chomp(@ARGV);
}

for (@ARGV) {
    $was = $_;
    eval $op;
    die $@ if $@;
    next if $was eq $_;
    if (-e $_) {
        unless ($force) {
	    if (! -w && -t) {
		printf "%s: overwrite `%s', overriding mode 0%03o? ",
                       $ME, $_, (stat _)[2]&0777;
		next unless <STDIN> =~ /^y/i;
	    } elsif ($interactive) {
		print "$ME: replace `$_'? ";
		next unless <STDIN> =~ /^y/i;
	    }
	}
	if ($backup) {
	    if ($vcm) {
		@old = sort {($a=~/~(\d*)~/)[0] <=> ($b=~/~(\d*)~/)[0]} <$_.~*~>;
		($old = $old[-1]) =~ s/~(\d*)~$/'~'.($1+1).'~'/e;
		if ($vcm & VCM_TEST) {
		    $old ||= "$_$backup_suffix";
		} elsif ($vcm & VCM_NUMBERED) {
		    $old ||= "$_.~1~";
		}
	    } else {
		$old = "$_$backup_suffix";
	    }
            print "backup: $_ -> $old\n" if $verbose && $nothing;
        }
    }
    print "$was -> $_\n" if $verbose || $nothing;
    unless ($nothing) {
        rename($_,$old) if $backup;
        if ($linkonly) {
	    link($was,$_);
        } else {
            rename($was,$_);
	}
    }
}

__END__

=head1 NAME

rename - renames multiple files

=head1 SYNOPSIS

B<rename>
[B<-bfivnl>]
[B<-S> I<backup-suffix>]
[B<-V> {I<numbered>,I<existing>,I<simple>}]
[B<--backup>]
[B<--force>]
[B<--interactive>]
[B<--verbose>]
[B<--suffix=>I<backup-suffix>]
[B<--version-control=>{I<numbered>,I<existing>,I<simple>}]
[B<--dry-run>]
[B<--just-print>]
[B<--link-only>]
[B<--help>]
[B<--version>]
I<perlexpr>
[I<files>]...

=head1 DESCRIPTION

I<Rename> renames the filenames supplied according to the rule
specified as the first argument.  The argument is a Perl expression
which is expected to modify the $_ string for at least some of the
filenames specified.  If a given filename is not modified by the
expression, it will not be renamed.  If no filenames are given on the
command line, filenames will be read via standard input.

If a destination file is unwritable, the standard input is a tty, and
the B<-f> or B<--force> option is not given, mv prompts the user for
whether to overwrite the file.  If the response does not begin with
`y' or `Y', the file is skipped.

=head1 OPTIONS

=over 4

=item B<-b>, B<--backup>

Make backups of files that are about to be removed.

=item B<-f>, B<--force>

Remove existing destination files and never prompt the user.

=item B<-i>, B<--interactive>

Prompt whether to overwrite each destination file that already exists.
If the response does not begin with `y' or `Y', the file is skipped.

=item B<-v>, B<--verbose>

Print the name of each file before renaming it.

=item B<-n>, B<--just-print>, B<--dry-run>

Do everything but the actual renaming, insted just print the name of
each file that would be renamed. When used together with B<--verbose>,
also print names of backups.

=item B<-l>, B<--link-only>

Link files to the new names instead of renaming them. This will keep
the original files.

=item B<--help>

Print a usage message on standard output and exit.

=item B<--version>

Print version information on standard output then exit successfully.

=item B<-S>, B<--suffix> I<backup-suffix>

The suffix used for making simple backup files can be set with the
B<SIMPLE_BACKUP_SUFFIX> environment variable, which can be overridden by
this option. If neither of those is given, the default is `~', as it
is in Emacs.

=item B<-V>, B<--version-control> {I<numbered>,I<existing>,I<simple>}

The type of backups made can be set with the B<VERSION_CONTROL>
environment variable, which can be overridden by this option.  If
B<VERSION_CONTROL> is not set and this option is not given, the
default backup type is `existing'.  The value of the
B<VERSION_CONTROL> environment variable and the argument to this
option are like the GNU Emacs `version-control' variable; they also
recognize synonyms that are more descriptive.  The valid values are
(unique abbreviations are accepted):

`t' or `numbered'

	Always make numbered backups.

`nil' or `existing'

	Make numbered backups of files that already
 	have them, simple backups of the others.

`never' or `simple'

	Always make simple backups.

=back

=head1 EXAMPLES

To rename all files matching *.bak to strip the extension, you might
say

    rename 's/\e.bak$//' *.bak

To translate uppercase names to lower, you'd use

    rename 'y/A-Z/a-z/' *

More examples:

    rename 's/\.flip$/.flop/'       # rename *.flip to *.flop
    rename s/flip/flop/             # rename *flip* to *flop*
    rename 's/^s\.(.*)/$1.X/'       # switch sccs filenames around
    rename 's/$/.orig/ */*.[ch]'    # add .orig to source files in */
    rename 'y/A-Z/a-z/'             # lowercase all filenames in .
    rename 'y/A-Z/a-z/ if -B'       # same, but just binaries!
or even
    rename chop *~                  # restore all ~ backup files

=head1 ENVIRONMENT

Two environment variables are used, B<SIMPLE_BACKUP_SUFFIX> and
B<VERSION_CONTROL>.  See L</OPTIONS>.

=head1 SEE ALSO

mv(1) and perl(1)

=head1 DIAGNOSTICS

If you give an invalid Perl expression you'll get a syntax error.

=head1 AUTHOR

Peder Stray <pederst@cpan.org>, original script from Larry Wall.

=cut
!NO!SUBST!
