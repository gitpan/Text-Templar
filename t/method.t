#!/usr/bin/perl -w
use strict;

BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;
my $numTests = 5;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("methodtest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);


###	2: Simple method
Test( $t->simpleMethod('test 1') );

###	3: Method with printf format
Test( $t->formattedMethod(2.0) );

### 4: Method with codeblock
Test( $t->codeblockMethod('test 3') );

### 5: Rendered output
Test( scalar $t->render eq test5results() );


sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub test5results {
	return <<"EOF";
Test 1: test 1
Test 2: 0002
Test 3: 3 tset


EOF
}
