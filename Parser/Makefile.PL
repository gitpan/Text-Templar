use ExtUtils::MakeMaker;

sub MY::postamble {q{
Parser.pm: grammar
	$(PERL) -s -MParse::RecDescent - -RD_ERRORS -RD_HINT grammar $(NAME)


}}


WriteMakefile(
    NAME			=> 'Text::Templar::Parser',
    VERSION_FROM	=> 'grammar', # finds $VERSION

	PM => {
		'Parser.pm'	=> '$(INST_LIB)/Text/Templar/Parser.pm',
	},

	MAN3PODS => {
		'Parser.pod'	=> '$(INST_MAN3DIR)/Text::Templar::Parser.3',
	},

	clean => {
		FILES	=> '*.pm',
	},

	dist => {
		TARFLAGS		=> 'cvf',
		COMPRESS		=> 'gzip',
		SUFFIX			=> '.gz',
		DIST_CP			=> 'ln',
		DIST_DEFAULT	=> 'tardist',
	},
);
