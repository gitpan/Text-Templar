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

sub testArrayMethod {
	my $self = shift;
	return ['one', $self->{value}, 'three'];
}


package hashTestObject;
sub new {
	my ( $class, $hash ) = @_;
	return bless { hash => $hash }, $class;
}

sub hashref { shift()->{hash} }
sub hash { %{shift()->{hash}} }


package foreachTest;
BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

$SIG{__DIE__} = sub { my $e = shift; print STDERR $e->stringify if ref $e };

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 11;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("foreachtest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

my @testList = (qw{one two three four});
my %testHash = (one => 1, two => 2, three => 3, four => 4);
my $hashTestObj = new hashTestObject \%testHash;

### 2: Add plain foreach content
Test( $t->testList(@testList) );

### 3: Add syntactic sugar foreach content
Test( $t->testSugarList(@testList) );

my @testMethodList = ();
for my $num ( 0 .. 4 ) {
	push @testMethodList, new testObject "testValue #$num";
}

### 4: Add methodcall iterator
Test( $t->testMethodList(@testMethodList) );

### 5: Add deref iterator
Test( $t->derefList(\@testList) );

### 6: Add deref methodchain
Test( $t->testDerefObject( @testMethodList ) );

### 7: Add hash iterator
Test( $t->testHashIter( %testHash ) );

### 8: Add hashref iterator
Test( $t->testHashrefIter( \%testHash ) );

### 9: Add hash object
Test( $t->testHashIterObject( $hashTestObj ) );

### 10: Add hashref object
Test( $t->testHashrefIterObject( $hashTestObj ) );

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

List start:
----------------------------------------------------------------------

	>>> one
	>>> two
	>>> three
	>>> four

----------------------------------------------------------------------
List end.

Syntactic sugar start:
----------------------------------------------------------------------


	>>> [EVEN] one



	>>> [ODD] two



	>>> [EVEN] three



	>>> [ODD] four

----------------------------------------------------------------------
Syntactic sugar end.

Method list start:
----------------------------------------------------------------------
	>>> testValue #4
----------------------------------------------------------------------
Method list end.

Deref list start:
----------------------------------------------------------------------
	>>> one
	>>> two
	>>> three
	>>> four
----------------------------------------------------------------------
Deref list end.

Deref methodchain start:
----------------------------------------------------------------------
	>>> one
	>>> testValue #0
	>>> three
	>>> one
	>>> testValue #1
	>>> three
	>>> one
	>>> testValue #2
	>>> three
	>>> one
	>>> testValue #3
	>>> three
	>>> one
	>>> testValue #4
	>>> three
----------------------------------------------------------------------
Deref methodchain end.

Hash iterator (hash) start:
----------------------------------------------------------------------
    >>> one => 1
    >>> three => 3
    >>> two => 2
    >>> four => 4
----------------------------------------------------------------------
Hash iterator (hash) end.

Hash iterator (hashref) start:
----------------------------------------------------------------------
    >>> one => 1
    >>> three => 3
    >>> two => 2
    >>> four => 4
----------------------------------------------------------------------
Hash iterator (hashref) end.

Hash iterator (hash) from methodChain start:
----------------------------------------------------------------------
    >>> one => 1
    >>> three => 3
    >>> two => 2
    >>> four => 4
----------------------------------------------------------------------
Hash iterator (hash) from methodChain end.

Hash iterator (hashref) from methodChain start:
----------------------------------------------------------------------
    >>> one => 1
    >>> three => 3
    >>> two => 2
    >>> four => 4
----------------------------------------------------------------------
Hash iterator (hashref) from methodChain end.
EOF
}
