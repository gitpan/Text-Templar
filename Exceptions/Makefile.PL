use ExtUtils::MakeMaker;

require v5.6;

WriteMakefile(
    NAME					=> 'Text::Templar::Exceptions',
    VERSION_FROM			=> 'Exceptions.pm', # finds $VERSION
);
