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

package joinTest;
BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 5;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("jointest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

my @testList = (qw{one two three four});

### 2: Plain array
Test( $t->testList(@testList) );

### 3: Syntactic sugar
Test( $t->sugarList(@testList) );

my $testObj = new testObject ( qw{one two three four} );

### 4: Add methodcall iterator
Test( $t->testObject($testObj) );

#print STDERR $t->render;

### 5: Render
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
'one', 'two', 'three', 'four'
----------------------------------------------------------------------
List end.

Sugar list start:
----------------------------------------------------------------------
'one', 'two', 'three', 'four'
----------------------------------------------------------------------
List end.

Method list start:
----------------------------------------------------------------------
'one', 'two', 'three', 'four'
----------------------------------------------------------------------
Method list end.
EOF
}
