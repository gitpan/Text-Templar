#!/usr/bin/perl -w
use strict;

BEGIN {
	$| = 1;
	use vars qw{$WarningGiven};

	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
	use Scalar::Util	qw{blessed};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;
$SIG{__WARN__} = sub { $WarningGiven = 1; };

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;
my $numTests = 5;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("delaytest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

### 2: Warning issued?
Test( $WarningGiven );

###	2: One-line define
Test( grep { blessed $_ && $_->type eq 'ENV' } @{$t->syntaxTree} );

###	3: Multi-line define
Test( grep { blessed $_ && $_->type eq 'EVAL' } @{$t->syntaxTree} );

#print STDERR $t->render;

### 4: Render
Test( $t->render eq renderedOutput() );


sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderedOutput {
	return <<"EOF";

256
$ENV{PATH}
EOF
}
