#!/usr/bin/perl
#
#	Perl Makefile for Text::Templar
#	$Id: Makefile.PL,v 2.8 2001/12/31 22:17:50 deveiant Exp $
#
#	Invoke with 'perl Makefile.PL'
#
#	See ExtUtils::MakeMaker (3) for more information on how to influence
#	 the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;
require v5.6;

sub MY::postamble {q{
lib/Text/Templar/Parser.pm: grammar
	$(PERL) -s -MParse::RecDescent - grammar Text::Templar::Parser
	$(NOECHO)mv Parser.pm $@

}}

WriteMakefile(
    NAME					=> 'Text::Templar',
    VERSION_FROM			=> 'lib/Text/Templar.pm', # finds $VERSION
	PREREQ_PM	=> {
		Parse::RecDescent	=> 0,
		Class::Translucent	=> 1.16,
		Scalar::Util		=> 0,
		Data::Dumper		=> 0,
		IO::Handle			=> 0,
		IO::File			=> 0,
	},
	MAN3PODS	=> {
		"pod/Templar.pod"	=> '$(INST_MAN3DIR)/Text::Templar.3',
		"pod/Parser.pod"	=> '$(INST_MAN3DIR)/Text::Templar::Parser.3',
	},
	PM	=> {
		'lib/Text/Templar.pm'	=> '$(INST_LIBDIR)/Templar.pm',
		'lib/Text/Templar/Exceptions.pm' => '$(INST_LIBDIR)/Templar/Exceptions.pm',
		'lib/Text/Templar/Parser.pm' => '$(INST_LIBDIR)/Templar/Parser.pm',
	},
	dist		=> {
		TARFLAGS			=> 'cvf',
		COMPRESS			=> 'gzip',
		SUFFIX				=> '.gz',
		DIST_CP				=> 'ln',
		DIST_DEFAULT		=> 'tardist',
	},
	clean		=> {
		FILES				=> "lib/Text/Templar/Parser.pm",
	},
);
