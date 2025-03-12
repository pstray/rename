# rename

Rename renames the filenames supplied according to the rule specified as
the first argument. The argument is a Perl expression which is expected
to modify the $_ string for at least some of the filenames specified.

# History

This script has been on CPAN since sometime in the late 1990's.  It is
based on the original script written by Larry Wall, but has gotten
additional feaures over the years.  I was left out the index for a lot
of years, but is visible again under the App::rename listing.

# Features

- Rename files based on perl expressions manipulating $_.
- Verbosity, dry-run and interactive mode.
- Linking, copying or using a custom command instead of rename.  Special
  option for working within git repos.
- Uses the same options and environment variables for file backup contol
  as coreutils `cp` and `mv`.
- Creation of target directories when modifying file paths.
- Additional error checking, notably testing for 0-bytes in resulting
  file names.
- Parameter tab completion support for bash and zsh.

