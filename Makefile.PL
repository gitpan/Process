
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION' => 1.1,
	'NAME'	  => 'Process',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	);

