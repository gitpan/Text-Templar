#!/usr/bin/perl -w
use strict;

### Array test object
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

### Hash test object
package hashTestObject;
sub new {
	my ( $class, $hash ) = @_;
	return bless { hash => $hash }, $class;
}

sub hashref { shift()->{hash} }
sub hash { %{shift()->{hash}} }


### Test package
package joinTest;
BEGIN {
	$| = 1;

	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 8;
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
my %testHash = (one => 1, two => 2, three => 3, four => 4);
my $testObj = new testObject ( qw{one two three four} );
my $hashTestObject = new hashTestObject \%testHash;


### 2: Plain array
Test( $t->testList(@testList) );

### 3: Syntactic sugar
Test( $t->sugarList(@testList) );

### 4: Add methodcall iterator
Test( $t->testObject($testObj) );

### 5: Hash iterator
Test( $t->testHashIter(%testHash) );

### 6: Hashref iterator
Test( $t->testHashrefIter(\%testHash) );

### 7: Hashref iterator
Test( $t->testHashIterObject($hashTestObject) );

#print STDERR $t->render;

### 8: Render
my $expectedPattern = renderResults();
Test( $t->render =~ $expectedPattern );



sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return qr{
List start:
----------------------------------------------------------------------
'one', 'two', 'three', 'four'
----------------------------------------------------------------------
List end\.

Sugar list start:
----------------------------------------------------------------------
'one', 'two', 'three', 'four'
----------------------------------------------------------------------
List end\.

Method list start:
----------------------------------------------------------------------
'one', 'two', 'three', 'four'
----------------------------------------------------------------------
Method list end\.


== Hash Iterators ====================================================

Hash iterator start:
----------------------------------------------------------------------
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]' 
----------------------------------------------------------------------
Hash iterator end\.

Key-sorted hash iterator start:
----------------------------------------------------------------------
	four => '4',
	one => '1',
	three => '3',
	two => '2' 
----------------------------------------------------------------------
Key-sorted hash iterator end\.

Value-sorted hash iterator start:
----------------------------------------------------------------------
	one => '1',
	two => '2',
	three => '3',
	four => '4' 
----------------------------------------------------------------------
Value-sorted hash iterator end\.

Custom-sorted \(by second letter of key\) hash iterator start:
----------------------------------------------------------------------
	three => '3',
	one => '1',
	four => '4',
	two => '2' 
----------------------------------------------------------------------
Custom-sorted \(by second letter of key\) hash iterator end\.


== Hashref Iterators =================================================

Hashref iterator start:
----------------------------------------------------------------------
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]' 
----------------------------------------------------------------------
Hashref iterator end\.

Key-sorted hashref iterator start:
----------------------------------------------------------------------
	four => '4',
	one => '1',
	three => '3',
	two => '2' 
----------------------------------------------------------------------
Key-sorted hashref iterator end\.

Value-sorted hashref iterator start:
----------------------------------------------------------------------
	one => '1',
	two => '2',
	three => '3',
	four => '4' 
----------------------------------------------------------------------
Value-sorted hashref iterator end\.

Custom-sorted \(by reverse key\) hashref iterator start:
----------------------------------------------------------------------
	three => '3',
	one => '1',
	two => '2',
	four => '4' 
----------------------------------------------------------------------
Custom-sorted \(by reverse key\) hashref iterator end\.


=== Hash from MethodChain Iterator ===================================

Hash From Methodchain iterator start:
----------------------------------------------------------------------
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]',
	(one|two|three|four) => '[1-4]' 
----------------------------------------------------------------------
Hash From Methodchain iterator end\.

Key-sorted hash from methodchain iterator start:
----------------------------------------------------------------------
	four => '4',
	one => '1',
	three => '3',
	two => '2' 
----------------------------------------------------------------------
Key-sorted hash from methodchain iterator end\.

Value-sorted hash from methodchain iterator start:
----------------------------------------------------------------------
	one => '1',
	two => '2',
	three => '3',
	four => '4' 
----------------------------------------------------------------------
Value-sorted hash from methodchain iterator end\.

Custom-sorted \(reverse by-value\) hash from methodchain iterator start:
----------------------------------------------------------------------
	four => '4',
	three => '3',
	two => '2',
	one => '1' 
----------------------------------------------------------------------
Custom-sorted \(reverse by-value\) hash from methodchain iterator end\.

}s
}
