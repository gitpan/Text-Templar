#!/usr/bin/perl -w
use strict;

BEGIN {
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $pt = new Text::Templar
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;
my $ct = new Text::Templar
	includePath => [ './t/templates' ];
my $numTests = 3;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load templates
Test(
	 try {
		 $pt->load("inheritParent.tmpl");
		 $ct->load("inheritChild.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);


### 2: Set explicit values
$pt->inheritedValue( "should be inherited" );
$pt->overiddenValue( "overidden (parent)" );
$pt->nonInheritedValue( "should not be inherited" );

$ct->overiddenValue( "overidden (child)" );
$pt->childTemplate( $ct );
Test( exists $ct->{inheritedContent}{overiddenValue} );

#print STDERR $pt->render;

### 3: Rendered output
Test( $pt->render eq test4results() );


sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub test4results {
	return <<"EOF";

Parent inherited value:
--------------------------------------------------
should be inherited
--------------------------------------------------

Parent overridden value:
--------------------------------------------------
overidden (parent)
--------------------------------------------------

Parent non-inherited value:
--------------------------------------------------
should not be inherited
--------------------------------------------------

Child template:
--------------------------------------------------

	Child inherited value:
	--------------------------------------------------
	should be inherited
	--------------------------------------------------

	Child overridden value:
	--------------------------------------------------
	overidden (child)
	--------------------------------------------------

	Child non-inherited value:
	--------------------------------------------------
	
	--------------------------------------------------

--------------------------------------------------



EOF
}
