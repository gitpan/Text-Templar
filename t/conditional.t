#!/usr/bin/perl -w
use strict;

package testObject;
sub new {
	my $class = shift;
	my $value = shift;
	return bless { value => $value  }, $class
}

sub testMethod {
	my $self = shift;
	return $self->{value};
}

package conditionalTest;
BEGIN {
	$| = 1;
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 11;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("conditionaltest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

### 2: Simple conditional
Test( $t->condition(1) );

### 3: Compound conditional
Test( $t->compoundConditional(undef) || 1 );

### 4,5: Complex conditionals
Test( $t->complexConditional(0) || 1 );
Test( $t->otherComplexConditional(1) );

### 6,7: Nested conditional
Test( $t->outerConditional(1) );
Test( $t->innerConditional(0) || 1 );

### 8,9: Nested conditional
Test( $t->unreachedOuterConditional(0) || 1 );
Test( $t->unreachedInnerConditional(1) );

my $o = new testObject 'yep';

### 10: Methodcall conditional
Test( $t->conditionalObject($o) );

#print STDERR $t->render;

### 11: Render
Test( $t->render eq renderResults() );



sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return <<"EOF";

Simple conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Compound conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Complex conditional test:
--------------------------------------------------
    Other condition passed.
--------------------------------------------------

Reached nested conditional test:
--------------------------------------------------
    Outer condition passed.
            Inner conditional passed.
    --------------------------------------------------

Unreached nested conditional test:
--------------------------------------------------
--------------------------------------------------

Methodcall conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Methodcall + Regexp matchspec conditional test:
--------------------------------------------------
    Regexp condition passed.
--------------------------------------------------

Methodcall + Regexp matchspec conditional failure test:
--------------------------------------------------
--------------------------------------------------

Methodcall + Array matchspec conditional test:
--------------------------------------------------
    Array condition passed.
--------------------------------------------------

Methodcall + Array matchspec conditional failure test:
--------------------------------------------------
--------------------------------------------------

Methodcall + Hash matchspec conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Methodcall + Hash matchspec conditional failure test:
--------------------------------------------------
--------------------------------------------------

EOF
}
