use ExtUtils::MakeMaker;
 
WriteMakefile(
              'NAME' => 'rename',
              'VERSION_FROM' => 'bin/rename.PL',
              'PL_FILES' => { "bin/rename.PL" => "bin/rename" },
              'EXE_FILES' => [ "bin/rename" ],
              'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
