#!/usr/bin/perl
##############################################################################

=head1 NAME

checkparser - Parse a template, outputting lots of Parse::RecDescent debugging

=head1 SYNOPSIS

  $ checkparser -h
  $ checkparser -V
  $ checkparser OPTIONS GRAMMAR
  $ checkparser OPTIONS GRAMMAR TARGETFILE

=head1 GRAMMAR

A Parse::RecDescent grammar.

=head1 TARGETFILE

A file that should be parsed by the parser generated from the specified I<GRAMMAR>.

=head1 OPTIONS

=over 4

=item -h, --help

Output a help message and exit.

=item -V, --version

Output version information and exit.

=item -d, --debug

Turn on debugging information for checkparser itself. May be specified more than
once for (potentially) increased levels of debugging.

=item -w, --warn=<level>

Turn on RD_WARN warnings at the specified level (1-3), 1 being the most verbose,
and 3 being the least. Defaults to '3' (only the most serious warnings).

=item -h, --hints

Turn on RD_HINT, which causes the parser generator to offer more detailed
analyses and hints on both errors and warnings. Note that Parse::RecDescent
automatically sets RD_WARN to 1 when this is turned on, regardless of the C<-w>
setting.

=item -p, --ptrace

Turn on tracing if the parser generator via RD_TRACE.

=item -t, --trace

Turn on tracing of the parser via RD_TRACE.

=item -r, --rule=<rulename>

Specify a rule to start the parse from. This defaults to the first rule in the
grammar.

=item -e, --tree

Print the abstract syntax tree parsed from the specified target file using the
given grammar.

=back

=head1 REQUIRES

I<Token requires line>

=head1 DESCRIPTION

None yet.

=head1 AUTHOR

Michael Granger <ged@FaerieMUD.org>

Copyright (c) 2002 The FaerieMUD Consortium. All rights reserved.

This program is Open Source software. You may use, modify, and/or redistribute
this software under the terms of the Perl Artistic License. (See
http://language.perl.com/misc/Artistic.html)

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND
FITNESS FOR A PARTICULAR PURPOSE.

=cut

##############################################################################
package checkparser;
use strict;
use warnings qw{all};


###############################################################################
###  I N I T I A L I Z A T I O N
###############################################################################
BEGIN {

	# Turn STDOUT buffering off
	$| = 1;

	### Versioning stuff and custom includes
	use vars qw{$VERSION $RCSID};
	$VERSION	= do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
	$RCSID		= q$Id: checkparser.pl,v 1.2 2002/08/29 17:51:54 deveiant Exp $;

	### Define some constants
	use constant TRUE	=> 1;
	use constant FALSE	=> 0;

	### Modules
	use Getopt::Long		qw{GetOptions};
	use Pod::Usage			qw{pod2usage};
	use Term::Prompter		qw{};
	use Parse::RecDescent	qw{};

	### Turn on option bundling (-vid)
	Getopt::Long::Configure( "bundling" );
}


###############################################################################
###	C O N F I G U R A T I O N   G L O B A L S
###############################################################################
our ( $Prompter );

$Prompter		= new Term::Prompter;

$::RD_WARN		= 3;
$::RD_HINT		= 0;


### Main body
MAIN: {
	my (
		$debugLevel,			# The level of debugging
		$helpFlag,				# User requested help?
		$versionFlag,			# User requested version info?
		$warnLevel,				# RD_WARN
		$hintsFlag,				# Turn on RD_HINT?
		$traceGrammarFlag,		# Turn on RD_TRACE for the parser generator?
		$traceFlag,				# Turn on RD_TRACE for the parser?
		$grammar,				# The path to the grammar to test
		$target,				# The path to the target file
		$parser,				# The parser generated from the grammar
		$toprule,				# The top-most rule to parse from
		$printTreeFlag,			# Print the AST for the target?
		$tree,					# The tree parsed from the target
	   );

	# Print the program header and read in command line options
	GetOptions(
		'd|debug+'		=> \$debugLevel,
		'h|help'		=> \$helpFlag,
		'V|version'		=> \$versionFlag,
		'w|warn=i'		=> \$warnLevel,
		'h|hints'		=> \$hintsFlag,
		'p|ptrace'		=> \$traceGrammarFlag,
		't|trace'		=> \$traceFlag,
		'r|rule=s'		=> \$toprule,
		'e|tree'		=> \$printTreeFlag,
	   ) or abortWithUsage();

	# If the -h flag or -V flag was given, just show the help or version,
	# respectively, and exit.
	helpMode() and exit if $helpFlag;
	versionMode() and exit if $versionFlag;

	# Propagate option settings
	$Prompter->debugLevel( $debugLevel );
	$warnLevel ||= 3;

	# Get the command-line args, aborting if there isn't at least one
	( $grammar, $target ) = @ARGV
		or abortWithUsage( "You must specify at least a grammar file." );

	# Check for other error conditions
	abort( "--trace requires a target file to be specified." )
		if $traceFlag && !$target;
	abort( "--tree requires a target file to be specified." )
		if $printTreeFlag && !$target;
	abortWithUsage( "The 'warn' level must be a number between 1 and 3." )
		unless ( $warnLevel >= 1 && $warnLevel <= 3 );


	$::RD_WARN = $warnLevel;
	$::RD_HINT = $hintsFlag ? 1 : 0;

	# Load the specified grammar file
	$parser = loadGrammar( $grammar, $traceGrammarFlag );

	# Now parser the target file, if one was specified.
	$tree = parseTarget( $parser, $target, $traceFlag, $toprule ) if $target;

	if ( $tree ) {
		$Prompter->message( "Parse succeeded." );

		# Print the parse tree, if such was requested
		$Prompter->message( "Parse tree: \n%s", Data::Dumper->Dumpxs([$tree], [$toprule]) )
			if $printTreeFlag;
	} else {
		$Prompter->errorMsg( "Parse failed." );
	}

	exit;
}


### FUNCTION: loadGrammar( $grammarFile, $traceFlag )
### Load the grammar in the specified I<grammarFile>, tracing the parser
### generator if the I<traceFlag> is set.
sub loadGrammar {
	my ( $grammarFile, $traceFlag ) = @_;

	$Prompter->header( "Loading grammar from '$grammarFile'" );
	if ( $traceFlag ) {
		$::RD_TRACE = 1;
	} else {
		undef $::RD_TRACE;
	}

	my $grammar = readFile( $grammarFile );

	my $parser = new Parse::RecDescent ($grammar);
	$Prompter->message( "Grammar loaded successfully." );

	return $parser;
}


### FUNCTION: parseTarget( $parser=Parse::RecDescent, $targetFile, $traceFlag, $topRule )
### Attempt to parse the contents of the specified I<targetFile> with the
### specified I<parser>, optionally outputting trace information if I<traceFlag>
### is set. The parse will be started from the given I<topRule>, or from the
### first rule in the parser's grammar if I<topRule> isn't specified.
sub parseTarget {
	my ( $parser, $targetFile, $traceFlag, $topRule ) = @_;

	$topRule ||= getTopRule( $parser );
	if ( $traceFlag ) {
		$::RD_TRACE = 1;
	} else {
		undef $::RD_TRACE;
	}

	my $target = readFile( $targetFile );

	$Prompter->header( "Starting parse with '%s' rule.", $topRule );
	my $tree = $parser->$topRule( $target );

	return $tree;
}


### FUNCTION: readFile( $file )
### Read the contents from the specified I<file> and return them as a scalar.
sub readFile {
	my $file = shift or return '';

	$Prompter->debugMsg( 2, "Reading file '$file'." );

	open my $ifh, "<$file"
			or die "open: $file: $!";

	local $/ = undef;
	my $content = <$ifh>;

	$Prompter->debugMsg( 3, "Read %d bytes.", length $content );
	return $content;
}


### FUNCTION: getTopRule( $parser=Parse::RecDescent )
### Return the name of the topmost rule in the grammar the given parser was
### built from.
sub getTopRule {
	my $parser = shift or return ();

	my $topRule = '';
	my $minLine = 0;

	# Violates encapsulation, but what can you do when there's no method to get
	# what you need?
	foreach my $rule ( keys %{$parser->{rules}} ) {
		my $line = $parser->{rules}{$rule}{line};
		$topRule = $rule, $minLine = $line
			if !$topRule || $line < $minLine;
	}

	return $topRule;
}


### FUNCTION: helpMode()
### Exit normally after printing the usage message
sub helpMode {
	pod2usage( -verbose => 1, -exitval => 0 );
}


### FUNCTION: versionMode()
### Exit normally after printing version information
sub versionMode {
	$Prompter->message( "checkparser $VERSION" );
	exit;
}


### FUNCTION: abortWithUsage()
### Abort the program showing usage message.
sub abortWithUsage {
	if ( @_ ) {
		pod2usage( -verbose => 1, -exitval => 1, -msg => join('', @_) );
	} else {
		pod2usage( -verbose => 1, -exitval => 1 );
	}
}


### FUNCTION: abort( @messages )
###	Print the specified messages to the terminal and exit with a non-zero status.
sub abort {
	my $msg = @_ ? join '', @_ : "unknown error";

	$Prompter->abortMsg( $msg );

	exit 1;
}


