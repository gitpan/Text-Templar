#!/usr/bin/perl -w
use strict;

BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 2;
my $numTest = 0;

$ENV{TEST2} = 2.1;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("envtest.tmpl")
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
$ENV{PATH}
{-- $ENV{PATH} --}
EOF
}
