#!/usr/bin/perl
#
#	Perl Makefile for Text::Templar
#	$Id: Makefile.PL,v 2.14 2004/01/16 20:26:35 deveiant Exp $
#
#	Invocation:
#		$ perl Makefile.PL                  # interactive behaviour
#		$ perl Makefile.PL --defaultdeps    # accept default value on prompts
#		$ perl Makefile.PL --checkdeps      # check only, no Makefile produced
#		$ perl Makefile.PL --skipdeps       # ignores all dependencies
#		$ perl Makefile.PL --testonly       # don't write installation targets
#
#	Then, to build:
#		$ make [all|test|install]           # install dependencies first
#		$ make checkdeps                    # same as the --checkdeps above
#		$ make installdeps                  # install dependencies only
#

# ExtUtils::AutoInstall Bootstrap Code, version 5.
BEGIN{my$p='ExtUtils::AutoInstall';my$v=0.40;eval"use $p $v;1
"or do{my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};(!defined($e)||$e
!~m/--(?:default|skip|testonly)/and-t STDIN or eval"use Ext".
"Utils::MakeMaker;WriteMakefile('PREREQ_PM'=>{'$p',$v});1"and
exit)and print"==> $p $v required. Install it from CPAN? [Y".
"/n] "and<STDIN>!~/^n/i and print"*** Installing $p\n"and do{
eval{require CPANPLUS;CPANPLUS::install $p};eval"use $p $v;1"
or eval{require CPAN;CPAN::install$p};eval"use $p $v;1"or die
"*** Please install $p $v manually from cpan.org first.\n"}}}

# the above handlers must be declared before the 'use' statement
use ExtUtils::AutoInstall (

	# required AutoInstall version
	-version        => '0.40',

	# core modules; may also be 'all'
	-core           => {
		Parse::RecDescent	=> 0,
		Class::Translucent	=> 1.18,
		Scalar::Util		=> 0,
		Data::Dumper		=> 0,
		IO::Handle			=> 0,
		IO::File			=> 0,
	},

	'Grammar Test Tool' => {
		Term::Prompter		=> 0,
	},

   );



sub MY::postamble {
	( my $aipost = <<'		EOF' ) =~ s{^\t\t}{}gm;
		lib/Text/Templar/Parser.pm: grammar
			$(PERL) -s -MParse::RecDescent - grammar Text::Templar::Parser
			$(NOECHO)mv Parser.pm $@
		EOF

	if ( grep /dev/, @ARGV ) {
		(my $addendum =<<'		EOF') =~ s{^\t\t\t}{}gm;

			CVS2CL := $(if $(shell which cvs2cl),$(shell which cvs2cl),"cvs2cl")
			CVSROOT := $(shell cat CVS/Root)

			requires:
				@for module in `find lib -name "*.pm"`; do \
				requiremaker.pl $$module ;\
				rm -f $$module.bak ;\
				done

			ChangeLog: changelog

			changelog: $(CVS2CL)
				rm -f ChangeLog
				$(CVS2CL) -P -I '(MANIFEST|\\.cvsignore)' -S \
					--tags --branches --revisions \
					--usermap $(CVSROOT)/CVSROOT/users \
					--day-of-week

		EOF
		$aipost .= $addendum;
	}

	return $aipost . ExtUtils::AutoInstall::postamble();
}


WriteMakefile(
    NAME					=> 'Text::Templar',
	DISTNAME				=> 'Text-Templar',
    VERSION					=> '2.43', # finds $VERSION
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
		CI					=> "cvs commit",
		RCS_LABEL			=> 'cvs tag release_$(VERSION_SYM)',
	},
	clean		=> {
		FILES				=> "lib/Text/Templar/Parser.pm",
	},
);
