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

package trimTest;
BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
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
		 $t->load("trimtest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

my $content = 'X' x 100;

### 2: Add plain trim content
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

Trim test (50):
--------------------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
--------------------------------------------------

Trim test (40):
----------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
----------------------------------------

Trim test (30):
------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 
------------------------------

Trim test (20):
--------------------
XXXXXXXXXXXXXXXXXXXX 
--------------------

Maxlength (backwards-compat) test (20):
--------------------
XXXXXXXXXXXXXXXXXXXX 
--------------------
EOF
}
