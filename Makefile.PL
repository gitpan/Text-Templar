#!/usr/bin/perl
#
#	Perl Makefile for Text::Templar
#	$Id: Makefile.PL,v 2.4 2001/06/06 15:40:54 deveiant Exp $
#
#	Invoke with 'perl Makefile.PL'
#
#	See ExtUtils::MakeMaker (3) for more information on how to influence
#	 the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;
require v5.6;
WriteMakefile(
    NAME					=> 'Text::Templar',
    VERSION_FROM			=> 'Templar.pm', # finds $VERSION
	PREREQ_PM	=> {
		Parse::RecDescent	=> 0,
		Class::Translucent	=> 1.16,
		Scalar::Util		=> 0,
		Data::Dumper		=> 0,
		IO::Handle			=> 0,
		IO::File			=> 0,
	},
	dist		=> {
		TARFLAGS			=> 'cvf',
		COMPRESS			=> 'gzip',
		SUFFIX				=> '.gz',
		DIST_CP				=> 'ln',
		DIST_DEFAULT		=> 'tardist',
	},
);
