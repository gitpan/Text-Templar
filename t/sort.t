#!/usr/bin/perl -w
use strict;
package testObject;
sub new {
	my $class = shift;
	my @values = @_;
	return bless { values => \@values }, $class
}

sub values {
	my $self = shift;
	return @{$self->{values}};
}

package sortTest;
BEGIN {
	$| = 1;
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
		 $t->load("sorttest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

my @testList = (qw{one two three four});

### 2: Define after STOP
Test( $t->testList(@testList) );

my $testObj = new testObject ( qw{one two three four} );

### 3: Add methodcall iterator
Test( $t->testObject($testObj) );

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

List start:
----------------------------------------------------------------------
	>>> fouronethreetwo
----------------------------------------------------------------------
List end.

Methodcall list start:
----------------------------------------------------------------------
	>>> twothreeonefour
----------------------------------------------------------------------
Methodcall list end.
EOF
}
