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
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 13;
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

### 10: name MATCHES /regexp/ match
Test( $t->matchConditional( 'yep...' ) );

my $o = new testObject 'yep';

### 11: Methodcall conditional
Test( $t->conditionalObject($o) );

my $o2 = new testObject ['yep'];

### 12: Methodcall w/deref conditional
Test( $t->conditionalDerefObject($o2) );

#print STDERR $t->render;

### 13: Render
my $resultsRe = renderResults();
Test( $t->render =~ /$resultsRe/  );



sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return quotemeta(<<"EOF");
Simple conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Compound conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Match conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Negative match conditional test:
--------------------------------------------------
--------------------------------------------------

Match conditional test 2:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Negative match conditional test 2:
--------------------------------------------------
--------------------------------------------------

Complex conditional test:
--------------------------------------------------
    Other condition passed.
--------------------------------------------------

Complex match conditional test:
--------------------------------------------------
    Condition matched.
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

Methodcall + Hash matchspec conditional test:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Methodcall + Hash matchspec conditional failure test:
--------------------------------------------------
--------------------------------------------------

Match methodcall with deref:
--------------------------------------------------
    Condition passed.
--------------------------------------------------

Match methodcall with deref2:
--------------------------------------------------
--------------------------------------------------
EOF
}
