#!/usr/bin/perl -w
use strict;

BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 4;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("metatest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

### 2,3: Fetch meta field values
Test( ($t->getMetafields('test1'))[0] eq 'A test' );
Test( ($t->getMetafields('test2'))[0] eq 'Another test' );

#print STDERR $t->render;

### 4: Render
Test( $t->render eq renderResults() );



sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return <<"EOF";
EOF
}
