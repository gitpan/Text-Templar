#!/usr/bin/perl -w
use strict;

BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $pt = new Text::Templar
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;
my $ct = new Text::Templar
	includePath => [ './t/templates' ];
my $gct = new Text::Templar
	includePath => [ './t/templates' ];

my $numTests = 3;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load templates
Test(
	 try {
		 $pt->load("inheritParent.tmpl");
		 $ct->load("inheritChild.tmpl");
		 $gct->load("inheritGrandchild.tmpl");
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

$gct->overiddenValue( "overidden (grandchild)" );

$ct->overiddenValue( "overidden (child)" );
$ct->grandchild( $gct );

$pt->childTemplate( $ct );
Test( exists $ct->{inheritedContent}{overiddenValue} );

#print STDERR $pt->render;

### 3: Rendered output
my $regex = makeResultsPattern();
Test( $pt->render =~ $regex );


sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub makeResultsPattern {
	return qr{
Parent inherited value:
--------------------------------------------------
should be inherited
--------------------------------------------------

Parent overridden value:
--------------------------------------------------
overidden \(parent\)
--------------------------------------------------

Parent non-inherited value:
--------------------------------------------------
should not be inherited
--------------------------------------------------

Child template:
--------------------------------------------------

\s+Child inherited value:
\s+--------------------------------------------------
\s+should be inherited
\s+--------------------------------------------------

\s+Child overridden value:
\s+--------------------------------------------------
\s+overidden \(child\)
\s+--------------------------------------------------

\s+Child non-inherited value:
\s+--------------------------------------------------
\s+
\s+--------------------------------------------------

\s+Grandchild template:
\s+--------------------------------------------------
\s*
\s+Grandchild inherited value:
\s+--------------------------------------------------
\s+should be inherited
\s+--------------------------------------------------

\s+Grandchild overridden value:
\s+--------------------------------------------------
\s+overidden \(grandchild\)
\s+--------------------------------------------------

\s+Grandchild non-inherited value:
\s+--------------------------------------------------
\s+
\s+--------------------------------------------------

\s+--------------------------------------------------

--------------------------------------------------
}s;
}
