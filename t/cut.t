#!/usr/bin/perl -w
use strict;

BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
	use Scalar::Util	qw{blessed};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;
my $numTests = 4;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("cuttest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

# 2: Make sure the method above the cut can still be called
Test( $t->this('above') );

# 3: Make sure it still can hold a value
Test( $t->getNodeContent('this') );

$t->that('below.');
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
This is below the cut.

below.

EOF
}
