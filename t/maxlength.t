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

package maxlengthTest;
BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

$SIG{__DIE__} = sub { my $e = shift; print STDERR $e->stringify if ref $e };

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 3;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("maxlengthtest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

my $content = 'X' x 100;

### 2: Add plain maxlength content
Test( $t->content($content) );

#print STDERR $t->render;

### 3: Render
Test( $t->render eq renderResults() );



sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return <<"EOF";

Maxlength test (50):
--------------------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
--------------------------------------------------

Maxlength test (40):
----------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
----------------------------------------

Maxlength test (30):
------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
------------------------------

Maxlength test (20):
--------------------
XXXXXXXXXXXXXXXXXXXX 
--------------------
EOF
}
