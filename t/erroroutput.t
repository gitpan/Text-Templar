#!/usr/bin/perl
package ErrObj;
use strict;

sub new {return bless {}, __PACKAGE__}
sub throwError { die "Dying from throwError" }

package main;
use strict;

BEGIN {
	unshift @INC, qw{blib/lib blib/arch};

	use vars qw{$Logfile};
	$Logfile = "erroroutput.log";

	use Text::Templar				qw{};
	use Text::Templar::Exceptions	qw{:syntax};
}

INIT {
	close STDERR;
	open STDERR, ">$Logfile"
		or die "Couldn't reopen STDERR to '$Logfile': $!";
}

END {
	unlink $Logfile if -e $Logfile;
}


my $numTests = 3;
my $numTest = 0;
my $output;

print "1..$numTests\n";

my $errObj = new ErrObj;
my $oneDimArray = [ 'single', 'dim', 'array' ];

# Test STDERR output (can't really make sure it goes to STDERR, as Test::Harness
# mucks with that...
my $t1 = new Text::Templar
	'erroroutput.tmpl',
	includePath => [ './t/templates' ],
	errorOutput => 'stderr';
$t1->errorObj( $errObj );
$t1->oneDimArray( $oneDimArray );
$output = $t1->render;
#print STDERR "STDERR:\n", $output, "\n";

Test( $output =~ StderrOutput() );


# Test inline output
my $t2 = new Text::Templar
	'erroroutput.tmpl',
	includePath => [ './t/templates' ],
	errorOutput => 'inline';
$t2->errorObj( $errObj );
$t2->oneDimArray( $oneDimArray );
$output = $t2->render;
#print STDERR "Inline:\n", $output, "\n";

Test( $output =~ InlineOutput() );


# Test tail output
my $t3 = new Text::Templar
	'erroroutput.tmpl',
	includePath => [ './t/templates' ],
	errorOutput => 'tailed';
$t3->errorObj( $errObj );
$t3->oneDimArray( $oneDimArray );
$output = $t3->render;
#print STDERR "Tailed:\n", $output, "\n";

Test( $output =~ TailOutput() );





sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub StderrOutput {qr{Method:


Illegal methodcall:


Illegal array index:


Method on string after one chain:


Some other stuff.

--END--
}}

sub InlineOutput {qr{Method:
<!--  Error in methodchain: calling ->throwError\(\) on ErrObj=HASH\(0x\w+\): Dying from throwError at t/erroroutput.t line \d+\.  -->

Illegal methodcall:
<!--  Error in methodchain: ErrObj=HASH\(0x\w+\): Can't use '1something' as a method name  -->

Illegal array index:
<!--  Error in methodchain: ARRAY\(0x\w+\): Can't use 'something' as an array index  -->

Method on string after one chain:
<!--  Error in methodchain: calling ->something\(\) on ARRAY\(0x\w+\)->\[1\]: Can't locate object method "something" via package "dim" \(perhaps you forgot to load "dim"\?\) at \(eval \d+\) line \d+\.  -->

Some other stuff.

--END--
}}

sub TailOutput {qr{Method:


Illegal methodcall:


Illegal array index:


Method on string after one chain:


Some other stuff.

--END--
<!--  A evaluation error 'Error in methodchain: calling ->throwError\(\) on ErrObj=HASH\(0x\w+\): Dying from throwError at t/erroroutput.t line \d+\.' occurred([^-]+|-(?!->))+-->

<!--  A evaluation error 'Error in methodchain: ErrObj=HASH\(0x\w+\): Can't use '1something' as a method name' occurred([^-]+|-(?!->))+-->

<!--  A evaluation error 'Error in methodchain: ARRAY\(0x\w+\): Can't use 'something' as an array index' occurred([^-]+|-(?!->))+-->

<!--  A evaluation error 'Error in methodchain: calling ->something\(\) on ARRAY\(0x\w+\)->\[1\]: Can't locate object method "something" via package "dim" \(perhaps you forgot to load "dim"\?\) at \(eval \d+\) line \d+\.' occurred([^-]+|-(?!->))+-->}s}

