#!/usr/bin/perl -w
use strict;

package testObject;
sub new {
	my $class = shift;
	my $value = shift;
	return bless { value => $value	}, $class
}

sub testArrayMethod {
	my $self = shift;
	return ( $self->{value} ) x 4;
}

sub testArrayRefMethod {
	my $self = shift;
	return ['one', $self->{value}, 'three'];
}

sub value { $_[0]->{value} }


package hashTestObject;
sub new {
	my ( $class, $hash ) = @_;
	return bless { hash => $hash }, $class;
}

sub hashref { shift()->{hash} }
sub hash { %{shift()->{hash}} }


package foreachTest;
BEGIN {
	select(STDERR); $| = 1; # make unbuffered
	select(STDOUT); $| = 1; # make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

$SIG{__DIE__} = sub { my $e = shift; print STDERR $e->stringify if ref $e };

my $t = new Text::Templar
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 25;
my $numTest = 0;

print "1..$numTests\n";

### 1: Load template
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

my @testObjects = ();
for my $num ( 0 .. 4 ) {
	push @testObjects, new testObject "testValue #$num";
}

my @testObjectArrays = ();
for my $num ( 0 .. 3 ) {
	push @testObjectArrays, \@testObjects;
}

### 4: Add an object to test the methodchain iterator
Test( $t->testMethodChain($testObjects[2]) );

### 5: Add deref iterator
Test( $t->derefList(\@testList) );

### 6: Add deref methodchain
Test( $t->testDerefObject( @testObjects ) );

### 7: Add hash iterator
Test( $t->testHashIter( %testHash ) );

### 8: Add key-sorted hash iterator
Test( $t->testKeySortedHashIter( %testHash ) );

### 9: Add value-sorted hash iterator
Test( $t->testValueSortedHashIter( %testHash ) );

### 10: Add custom-sorted hash iterator
Test( $t->testCustomSortedHashIter( %testHash ) );

### 11: Add hashref iterator
Test( $t->testHashrefIter( \%testHash ) );

### 12: Add key-sorted hashref iterator
Test( $t->testKeySortedHashrefIter( \%testHash ) );

### 13: Add value-sorted hashref iterator
Test( $t->testValueSortedHashrefIter( \%testHash ) );

### 14: Add custom-sorted hashref iterator
Test( $t->testCustomSortedHashrefIter( \%testHash ) );

### 15: Add hash object
Test( $t->testHashIterObject( $hashTestObj ) );

### 16: Add key-sorted hash object iterator
Test( $t->testKeySortedHashIterObject( $hashTestObj ) );

### 17: Add value-sorted hash iterator
Test( $t->testValueSortedHashIterObject( $hashTestObj ) );

### 18: Add custom-sorted hash iterator
Test( $t->testCustomSortedHashIterObject( $hashTestObj ) );

### 19: Add hashref object
Test( $t->testHashrefIterObject( $hashTestObj ) );

### 20: Add key-sorted hash object iterator
Test( $t->testKeySortedHashrefIterObject( $hashTestObj ) );

### 21: Add value-sorted hash iterator
Test( $t->testValueSortedHashrefIterObject( $hashTestObj ) );

### 22: Add custom-sorted hash iterator
Test( $t->testCustomSortedHashrefIterObject( $hashTestObj ) );

### 23: Test localized interator variable
Test( $t->testLocalizedIterator(@testObjects) );

### 24: Nested iterators' $ITERATION
Test( $t->testNestedIterator(@testObjectArrays) );

#print STDERR $t->render;

### 25: Render
my $resultPattern = ResultPattern();
Test( $t->render =~ $resultPattern );




sub Test {
	my $result = shift;
	printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
	$result;
}

sub ResultPattern {qr{List start:
----------------------------------------------------------------------
\s+>>> one
\s+>>> two
\s+>>> three
\s+>>> four
----------------------------------------------------------------------
List end\.

Syntactic sugar start:
----------------------------------------------------------------------
\s+>>> \[EVEN\] one
\s+>>> \[ODD\] two
\s+>>> \[EVEN\] three
\s+>>> \[ODD\] four
----------------------------------------------------------------------
Syntactic sugar end\.

Deref list start:
----------------------------------------------------------------------
\s+>>> one
\s+>>> two
\s+>>> three
\s+>>> four
----------------------------------------------------------------------
Deref list end\.

Methodchain start:
----------------------------------------------------------------------
\s+>>> testValue #2
\s+>>> testValue #2
\s+>>> testValue #2
\s+>>> testValue #2
----------------------------------------------------------------------
Methodchain end\.

Deref methodchain start:
----------------------------------------------------------------------
\s+>>> one
\s+>>> testValue #0
\s+>>> three
\s+>>> one
\s+>>> testValue #1
\s+>>> three
\s+>>> one
\s+>>> testValue #2
\s+>>> three
\s+>>> one
\s+>>> testValue #3
\s+>>> three
\s+>>> one
\s+>>> testValue #4
\s+>>> three
----------------------------------------------------------------------
Deref methodchain end\.

Hash iterator \(hash\) start:
----------------------------------------------------------------------
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
----------------------------------------------------------------------
Hash iterator \(hash\) end\.

Key-sorted hash iterator \(hash\) start:
----------------------------------------------------------------------
\s+>>> four => 4
\s+>>> one => 1
\s+>>> three => 3
\s+>>> two => 2
----------------------------------------------------------------------
Key-sorted hash iterator \(hash\) end\.

Value-sorted hash iterator \(hash\) start:
----------------------------------------------------------------------
\s+>>> one => 1
\s+>>> two => 2
\s+>>> three => 3
\s+>>> four => 4
----------------------------------------------------------------------
Value-sorted hash iterator \(hash\) end\.

Custom-sorted \(by second letter of key\) hash iterator \(hash\) start:
----------------------------------------------------------------------
\s+>>> three => 3
\s+>>> one => 1
\s+>>> four => 4
\s+>>> two => 2
----------------------------------------------------------------------
Custom-sorted iterator \(hash\) end\.

Hash iterator \(hashref\) start:
----------------------------------------------------------------------
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
----------------------------------------------------------------------
Hash iterator \(hashref\) end\.

Key-sorted hash iterator \(hashref\) start:
----------------------------------------------------------------------
\s+>>> four => 4
\s+>>> one => 1
\s+>>> three => 3
\s+>>> two => 2
----------------------------------------------------------------------
Key-sorted hash iterator \(hashref\) end\.

Value-sorted hash iterator \(hashref\) start:
----------------------------------------------------------------------
\s+>>> one => 1
\s+>>> two => 2
\s+>>> three => 3
\s+>>> four => 4
----------------------------------------------------------------------
Value-sorted hash iterator \(hashref\) end\.

Custom-sorted \(by reverse key\) hash iterator \(hashref\) start:
----------------------------------------------------------------------
\s+>>> three => 3
\s+>>> one => 1
\s+>>> two => 2
\s+>>> four => 4
----------------------------------------------------------------------
Custom-sorted hash iterator \(hashref\) end\.

Hash iterator \(hash\) from methodChain start:
----------------------------------------------------------------------
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
----------------------------------------------------------------------
Hash iterator \(hash\) from methodChain end\.

Key-sorted hash iterator from methodChain start:
----------------------------------------------------------------------
\s+>>> four => 4
\s+>>> one => 1
\s+>>> three => 3
\s+>>> two => 2
----------------------------------------------------------------------
Key-sorted hash iterator from methodChain end\.

Value-sorted hash iterator from methodChain start:
----------------------------------------------------------------------
\s+>>> one => 1
\s+>>> two => 2
\s+>>> three => 3
\s+>>> four => 4
----------------------------------------------------------------------
Value-sorted hash iterator from methodChain end\.

Custom-sorted \(by-value\) hash iterator from methodChain start:
----------------------------------------------------------------------
\s+>>> one => 1
\s+>>> two => 2
\s+>>> three => 3
\s+>>> four => 4
----------------------------------------------------------------------
Custom-sorted hash iterator from methodChain end\.

Hash iterator \(hashref\) from methodChain start:
----------------------------------------------------------------------
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
\s+>>> (one|two|three|four) => [1-4]
----------------------------------------------------------------------
Hash iterator \(hashref\) from methodChain end\.

Key-sorted hash iterator \(hashref\) from methodChain start:
----------------------------------------------------------------------
\s+>>> four => 4
\s+>>> one => 1
\s+>>> three => 3
\s+>>> two => 2
----------------------------------------------------------------------
Key-sorted hash iterator \(hashref\) from methodChain end\.

Value-sorted hash iterator \(hashref\) from methodChain start:
----------------------------------------------------------------------
\s+>>> one => 1
\s+>>> two => 2
\s+>>> three => 3
\s+>>> four => 4
----------------------------------------------------------------------
Value-sorted hash iterator \(hashref\) from methodChain end\.

Custom-sorted \(reverse by-value\) hash iterator \(hashref\) from methodChain start:
----------------------------------------------------------------------
\s+>>> four => 4
\s+>>> three => 3
\s+>>> two => 2
\s+>>> one => 1
----------------------------------------------------------------------
Custom-sorted hash iterator \(hashref\) from methodChain end\.

Iterator local variable bug test:
----------------------------------------------------------------------
\s+>>> testValue #2
\s+>>> testValue #4
----------------------------------------------------------------------
Iterator local variable bug test end\.

Nested iterator \$ITERATOR bug:
----------------------------------------------------------------------
outer>>> 1
\s+inner>>> 1
\s+inner>>> 2
\s+inner>>> 3
\s+inner>>> 4
\s+inner>>> 5
outer<<< 1
outer>>> 2
\s+inner>>> 1
\s+inner>>> 2
\s+inner>>> 3
\s+inner>>> 4
\s+inner>>> 5
outer<<< 2
outer>>> 3
\s+inner>>> 1
\s+inner>>> 2
\s+inner>>> 3
\s+inner>>> 4
\s+inner>>> 5
outer<<< 3
outer>>> 4
\s+inner>>> 1
\s+inner>>> 2
\s+inner>>> 3
\s+inner>>> 4
\s+inner>>> 5
outer<<< 4
----------------------------------------------------------------------
Nested iterator \$ITERATOR bug test end\.}s

}
