#!/usr/bin/perl -w
use strict;

BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 2;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("evaltest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

#print STDERR $t->render;

### 2: Render
Test( $t->render eq renderResults() );


sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return <<"EOF";
Test 1: The test value
Test 2: -- The test value --
Test 3: ecnetnes siht tset
Test 4: 000000004

EOF
}
