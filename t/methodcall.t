#!/usr/bin/perl -w
use strict;

package testObject;
sub new {
	my $class = shift;
	my $value = shift;
	return bless { value => $value  }, $class
}

sub obj { $_[0] }

sub testMethod {
	my $self = shift;
	return $self->{value};
}

sub testMethod2 {
	my $self = shift;
	return $self->{value};
}

package methodcall_test;

BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $obj1 = new testObject 'object 1';
my $obj2 = new testObject 'object 2';
my $obj3 = new testObject $obj2;

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 7;
my $numTest = 0;

print "1..$numTests\n";


### 1: Load template
Test(
	 try {
		 $t->load("methodcalltest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

### 2: Methodcall
Test( $t->test2($obj1) );

### 3: Methodcall with format
Test( $t->test3($obj2) );

### 4: Hash lookup
my $objectHash = { one => $obj1, two => $obj2 };
Test( $t->test4($objectHash) );

### 5: Array lookup
my $arrayRef = [ "first", "second" ];
Test( $t->test5($arrayRef) );

### 6: Methodchain
Test( $t->test6($obj3) );

#print STDERR $t->render;

my $outputRe = resultsPattern();
Test( $t->render =~ $outputRe );

sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub resultsPattern {
	my $pat = quotemeta(<<"EOF");
Test 2: object 1
Test 3: object 2

Test 4: object 1

Test 5: first
Test 5: second

Test 6: object 2
Test 6: object 2
Test 6: object 2
Test 6: object 2
EOF

	return qr{$pat};
}
