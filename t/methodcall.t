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


package methodcall_test;

BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $obj1 = new testObject 'object 1';
my $obj2 = new testObject 'object 2';

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 5;
my $numTest = 0;

print "1..$numTests\n";


###	1: Load template
Test(
	 try {
		 $t->load("methodcalltest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

Test( $t->test1($obj1) );

Test( $t->test2($obj2) );

my $objectHash = { one => $obj1, two => $obj2 };

Test( $t->test3($objectHash) );

#print STDERR $t->render;

Test( $t->render eq test4results() );

sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub test4results {
	return <<"EOF";
Test 1: object 1
Test 2: object 2

Test 3: object 1
EOF
}
