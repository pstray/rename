use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'rename',
	      LICENSE => 'Perl_5',
	      ABSTRACT_FROM => 'bin/rename.PL',
	      AUTHOR => 'Peder Stray <peder.stray@gmail.com>',
	      VERSION_FROM => 'lib/App/rename.pm',
	      PL_FILES => { 'bin/rename.PL' => 'bin/rename' },
	      EXE_FILES => [ 'bin/rename' ],
	      dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
