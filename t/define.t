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
my $numTests = 7;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("definetest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);


###	2: One-line define
Test( ($t->getDefines('testVariable'))[0] == 1 );

###	3: Multi-line define
Test( ($t->getDefines('$testVariable2'))[0] == 1 );

### 4: Method define
Test(
	 try {
		 $t->_getEvaluatedValue('$testVariable2') 
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

### 5: Codeblock define
Test( ($t->getDefines('year'))[0] == (localtime)[5] + 1900 );

### 6: Codeblock define
Test( ($t->getDefines('time_t'))[0]->[5] == (localtime)[5] );

#print STDERR $t->render;

### 7: Rendered output
Test( $t->render eq test4results() );


sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub test4results {
	return <<"EOF";
EOF
}
