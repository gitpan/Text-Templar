#!/usr/bin/perl
################################################################################
#
#  Text::Templar
#  $Id: Templar.pm,v 2.47 2004/01/16 20:23:23 deveiant Exp $
#
#  Authors: Michael Granger <ged@FaerieMUD.org>
#  and Dave McCorkhill <scotus@FaerieMUD.org>
#
#  Copyright (c) 1998-2004 Michael Granger and The FaerieMUD Consortium. All
#  rights reserved.
#
#  This module is free software. You may use, modify, and/or redistribute this
#  software under the terms of the Perl Artistic License. (See
#  http://language.perl.com/misc/Artistic.html)
#
#  THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
#  MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#  (POD moved to Templar.pod)
#
################################################################################

package Text::Templar;
use strict;
use warnings;

################################################################################
#	 I N I T I A L I Z A T I O N
################################################################################
BEGIN {
	require 5.006;

	### Package globals
	use vars	qw{$VERSION $RCSID $AUTOLOAD};
	$VERSION	= do { my @r = (q$Revision: 2.47 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
	$RCSID	= q$Id: Templar.pm,v 2.47 2004/01/16 20:23:23 deveiant Exp $;

	### Some constants to make things more human-readable
	use constant	TRUE	=> 1;
	use constant	FALSE	=> ();

	### Prototypes for overridden methods (These don't work now for some strange
	### reason I haven't yet figured out.)
	sub errorOutput;
	sub getDefines;

	### Superclass (with class template)
	use Class::Translucent ({

	  # Configuration attributes
		errorOutput			=> 'stderr',		# Where do errors go when dawn is come?
		maxIncludeDepth		=> 15,				# Maximum INCLUDE depth
		commentOpen			=> '<!-- ',			# Comment open string
		commentClose		=> ' -->',			# Comment close string

		missingMethodIsFatal => 0,				# A call to a non-existant
												# method is fatal
		undefinedValue		=> '',				# The string that gets inserted
												# for undefined values
		cacheSource			=> 1,				# Cache template source?
		cacheTrees			=> 0,				# Cache template syntax tree?

	  # Object attributes
		sourceName			=> undef,			# This object's source file
		syntaxTree			=> [],				# The template's syntax tree
		includePath			=> [],				# An arrayref or ':' delimited searchpath

		queries				=> [],				# Query fields
		metafields			=> {},				# Meta fields

		defines				=> {},				# DEFINEd template variables

	  # 'Protected' attributes
		_Parser				=> undef,			# The Parse::RecDescent parser

		_tailedErrors		=> [],				# Storage for exceptions
		_parsed				=> 0,				# Has the template been parsed yet?
		_errorOutputFh		=> '',				# Error output filehandle

	  # 'Private' attributes
		__closureCount		=> 0,				# Package uniquifier for closure generation
		__ErroutIsInitialized => 0,				# :FIXME: Nasty kluge to make
												# sure error output FH is open
		__VERSION			=> \$VERSION,
		__RCSID				=> \$RCSID,
	});

	### Import the 'blessed' function
	use Scalar::Util		qw{blessed};
	use Data::Dumper		qw{};

	### The Parse::RecDescent parser subclass
	use Text::Templar::Parser;

	### IO classes for handling error output
	use IO::Handle		qw{};
	use IO::File		qw{};

	### Exception-handling functions and class
	use Text::Templar::Exceptions	qw{:syntax};

	### Inheritance
	use base qw{Class::Translucent};
}


### METHOD: undefinedValue( $newValue )
### Get/set the value that is inserted when templar encounters an undefined
### value. Defaults to the empty string.


### METHOD: maxIncludeDepth( $depth )
### Get/set the maximum include depth. If the number of recursive includes for a
### given template exceeds this value, an exception is generated and the
### include will fail. The default value is 15. (Translucent method)


### METHOD: commentOpen( $string )
### Get/set the comment open string used when rendering comments into the
### output. Defaults to 'C<E<lt>!-- >', which is the HTML comment open
### string. (Translucent method)


### METHOD: commentClose( $string )
### Get/set the comment close string used when rendering comments into the
### output. Defaults to 'C< --E<gt>>', which is the HTML comment close
### string.


### METHOD: missingMethodIsFatal( $boolean )
### Get/set the flag that controls what happens when a method is called on the
### template which hasn't been defined in the template file. If this is set
### to a false value (which is the default), the call won't do anything. If
### it is set to a true value, a call to an undefined method will throw an
### exception.


### METHOD: cacheSource( $boolean )
### Get/set the attribute which turns source caching on or off. If this is set
### to a true value, the template source from any file will be cached after
### loading it the first time, and will be reused the next time the template
### is requested. If the file the source is from changes, the caching
### mechanism will notice and abandon the cached source. (Translucent method)


### METHOD: cacheTrees( $boolean )
### Get/set the attribute which turns syntax tree caching on or off. If this is
### set to a true value, the template object's syntax tree will be reused the
### next time it is loaded, skipping the parse phase altogether. (Translucent
### method)


### METHOD: sourceName( $pathname )
### Get/set the path name of the source file the template was/should be loaded
### from. Note that changing this value after loading a template will not
### have any effect on the actual template content. Setting this value
### before calling C<load()> will cause the template source to be loaded
### from the specified file. (Translucent method)


### METHOD: syntaxTree( \@syntaxTree=Text::Templar::node )
### Get/set the syntaxTree that the object uses in rendering. By getting/setting
### this attribute, you can prune elements out of the rendered
### content. (Translucent method)

### METHOD: pushSyntaxTree( @nodes=Text::Templar::node )
### Add the specified nodes on to the end of the syntax tree. Returns the total
### number of nodes after adding. (Translucent method)


### METHOD: popSyntaxTree( undef )
### Remove and return the last element of the syntax tree. (Translucent method)


### METHOD: shiftSyntaxTree( undef )
### Remove and return the first element of the syntax tree. (Translucent method)


### METHOD: unshiftSyntaxTree( @args )
### Add the specified nodes onto the top of the syntax tree. Returns the number
### of nodes in the tree after adding. (Translucent method)


### METHOD: spliceSyntaxTree( $offset, $length, @newnodes=Text::Templar::node )
### Removes the nodes specified by offset and length from the syntax tree,
### replacing them with the new nodes, if specified. This method works
### similarly to Perl's C<splice()>. (Translucent method)


### METHOD: sliceSyntaxTree( @indexes )
### Return the syntax tree nodes specified by the indexes from the syntax tree
### without removing them. (Translucent method)


### METHOD: includePath( \@newPath )
### Get/set the list of directories to check when searching for template
### files. The path is a reference to an array of directories.	(Translucent
### method)


### METHOD: pushIncludePath( @directories )
### Add the specified directories on to the end of the include path. Returns the
### total number of paths after adding. (Translucent method)


### METHOD: popIncludePath( undef )
### Remove and return the last element of the include path. (Translucent method)


### METHOD: shiftIncludePath( undef )
### Remove and return the first element of the template include
### path. (Translucent method)


### METHOD: unshiftIncludePath( @directories )
### Add the specified directories onto the beginning of the include
### path. Returns the number of directories in the tree after
### adding. (Translucent method)


### METHOD: spliceIncludePath( $offset, $length, @newDirs )
### Removes the directories specified by offset and length from the include
### path, replacing them with the new directories, if specified. This method
### works similarly to Perl's C<splice()>. (Translucent method)


### METHOD: sliceIncludePath( @indexes )
### Returns the directories specified by the indexes from the include path
### without removing them from the path. (Translucent method)


### METHOD: queries( \@queryNodes=Text::Templar::QUERY )
### Get/set the array of query nodes for this template. Query nodes are
### generated for C<QUERY> directives in the template. See X<NODE OBJECTS>
### for more about how to use C<QUERY> nodes. (Translucent method)


### METHOD: pushQueries( @nodes=Text::Templar::QUERY )
### Add the specified nodes on to the end of the query list. Returns the total
### number of nodes after adding. (Translucent method)


### METHOD: popQueries( undef )
### Remove and return the last element of the query list. (Translucent method)


### METHOD: shiftQueries( undef )
### Remove and return the first element of the query list. (Translucent method)


### METHOD: unshiftQueries( @queries=Text::Templar::QUERY )
### Add the specified nodes onto the top of the query list. Returns the number
### of nodes in the list after adding. (Translucent method)


### METHOD: spliceQueries( $offset, $length, @newnodes=Text::Templar::QUERY )
### Removes the nodes specified by offset and length from the query list,
### replacing them with the new nodes, if specified. This method works
### similarly to Perl's C<splice()>. (Translucent method)


### METHOD: sliceQueries( @indexes )
### Return the query list nodes specified by the indexes from the query list
### without removing them. (Translucent method)


### METHOD: metafields( \%newFields )
### Get/set the hash of metadata associated with the template. (Translucent
### method)


### METHOD: setMetafields( %fieldPairs )
### Set the value of the metadata field specified to the specified
### value. (Translucent method)


### METHOD: getMetafields( @fieldNames )
### Return the values of the specified metadata fields. (Translucent method)


### METHOD: deleteMetafields( @fieldNames )
### Remove and return the named values from the object's metafields hash.
### (Translucent method)

### METHOD: defines( \%variableDefinitions )
### Get/set the template variables associated with the template. The defines
### hash is a hash of variable name =E<gt> variable value pairs. These
### variables will be visible to any code evaluated in the template's
### scope. If a variable does not have a perl-style variable prefix, it is
### assumed to be a scalar value.  (Translucent method)


### METHOD: setDefines( %variablePairs )
### Set the value of the specified variable pairs in the template definitions
### hash (Translucent method)

### METHOD: deleteDefines( @variableNames )
### Remove and return the specified key-value pairs from the template
### definitions hash. (Translucent method)


### (PROTECTED STATIC) METHOD: _Parser( $newParser=Text::Templar::Parser )
### Get/set the parser object used to generate syntax trees. (Translucent method)


### (PROTECTED) METHOD: _tailedErrors( \@exceptions=Text::Templar::Exception )
### Get/set the array of exception objects to be appended to the end of the
### rendered output. (Translucent method)


### (PROTECTED) METHOD: _pushTailedErrors( @exceptions=Text::Templar::Exception )
### Add the specified exceptions on to the end of the tailed error list. Returns the
### total number of exceptions after adding. (Translucent method)


### (PROTECTED) METHOD: _popTailedErrors( undef )
### Remove and return the last exception from the tailed exception
### list. (Translucent method)


### (PROTECTED) METHOD: _shiftTailedErrors( undef )
### Remove and return the first element of the tailed exception list.
### (Translucent method)


### (PROTECTED) METHOD: _unshiftTailedErrors( @exceptions=Text::Templar::Exception )
### Add the specified exceptions onto the top of the tailed exception
### list. Returns the number of exceptions in the list after adding.
### (Translucent method)


### (PROTECTED) METHOD: _spliceTailedErrors( $offset, $length, @exceptions=Text::Templar::Exception )
### Removes the exceptions specified by offset and length from the tailed
### exceptions list, replacing them with the new exceptions, if
### specified. This method works similarly to Perl's
### C<splice()>. (Translucent method)


### (PROTECTED) METHOD: _sliceTailedErrors( @indexes )
### Return the query list exceptions specified by the indexes from the tailed
### exceptions list without removing them. (Translucent method)


### (PROTECTED) METHOD: _parsed( @args )
### Get/set the flag that designates the template object as parsed. (Translucent
### method)


### (PROTECTED) METHOD: _depth( @args )
### Get/set the current include depth. (Translucent method)


### (PROTECTED) METHOD: _errorOutputFh( @args )
### Get/set the output filehandle that should be used for printing exceptions as
### they occur, if any. See C<errorOutput()> for more info. (Translucent
### method)


### (PRIVATE) METHOD: __closureCount( @args )
### Get/set the number of closures that have been constructed. This is used for
### constructing a unique namespace for each closure. (Translucent method)


### (PRIVATE STATIC) METHOD: __ErroutIsInitialized( @args )
### Get/set the flag that denotes that the error output filehandle has been
### initialized.  (Translucent method)


### (PRIVATE READONLY) METHOD: __VERSION( @args )
### Get the version string for Text::Templar.


### (PRIVATE READONLY) METHOD: __RCSID( @args )
### Get the RCS id string for Text::Templar.




#####################################################################
### P A C K A G E	G L O B A L S
#####################################################################
use vars qw{%CachedSource %CachedTree};

### Cached template contents and syntax trees
%CachedSource	= ();
%CachedTree = ();



###############################################################################
### C O N S T R U C T O R
###############################################################################

### (CONSTRUCTOR) METHOD: new( [ $sourceFileName | \@sourceArray ][, %configHash] )
### Constructs and returns a new template object. If the optional sourceFileName
### or sourceArray argument is specified, the template content is parsed. If
### the optional configHash contains any key-value pairs, the per-object
### attributes specified are set. Throws an exception on any error.
sub new {
	my $proto = shift or throw Text::Templar::Exception::MethodError;
	my $class = ref $proto || $proto;

	#	Shift off the first argument if there's an odd number
	my $source = shift if scalar(@_) % 2;

	#	Create the object
	my $self = $class->SUPER::new( @_ );
	$self->{content} = {};
	$self->{inheritedContent} = {};
	$self->{_depth} = 0;

	# :FIXME: This is a kluge to work around the error output filehandle not
	# being opened if the config isn't specified by the constructor. Better
	# error-handling code would make this unnecessary.
	$class->__InitErrorOutput unless $self->__ErroutIsInitialized;

	#	If we got an argument specifying the base template source, load it
	if ( defined $source && (!ref $source || ref $source eq 'ARRAY') ) {
		$self->load( $source );
	}

	return $self;
}


### METHOD: clear( undef )
### Clear the content from this template.
sub clear {
	my $self = shift		or throw Text::Templar::Exception::MethodError;

	$self->{content} = {};
	$self->{inheritedContent} = {};
	$self->{defines} = {};
	$self->{_tailedErrors} = [];
}


### Work around the warnings about 'method redefined' because we're overriding a
### couple of translucent methods.
OVERRIDE: {
	no warnings "redefine";

	### METHOD: errorOutput( $outputConfig )
	### Get/set the errorOutput attribute. This attribute controls where the output
	### from errors generated in the template object end up. Setting it to
	### 'C<stderr>' (the default) causes errors to be output on STDERR. Setting it
	### to 'C<inline>' renders the errors as comments (see C<commentOpen()> and
	### C<commentClose()>) into the output of the template at the place where they
	### occur. If C<errorOutput()> is 'C<tailed>', the errors will be rendered as
	### more-detailed error stacktraces at the end of the template's output. A value
	### of 'C<both>' means to use both C<inline> and C<tailed> output types. Setting
	### C<errorOutput()> to 'C<ignore>' will cause errors to be ignored
	### silently. Any other value is treated as the filename of some sort of log,
	### and errors are piped to it as they occur. Setting this to a filename which
	### cannot be opened results in a fatal exception being thrown. (Translucent
	### method)
	sub errorOutput {
		my $self = shift		or throw Text::Templar::Exception::MethodError;
		my $errorOutput = shift;

		### If we got a new output config, re-open the error output filehandle if
		### needed
		if ( $errorOutput ) {
			my $ofh;

			### Open the filehandle we need to deal with errors, if any
			if ( lc $errorOutput eq q{stderr} ) {
				$ofh = $self->_getStderrHandle
					or throw Text::Templar::Exception "Unknown error while trying to get STDERR handle";
			} elsif ( lc $errorOutput eq q{inline}
						  || lc $errorOutput eq q{tailed}
							  || lc $errorOutput eq q{both}
								  || lc $errorOutput eq q{ignore} ) {
				$ofh = undef;
			} else {
				$ofh = $self->_getFileHandle( $errorOutput );
			}

			$self->_errorOutputFh( $ofh );
			return $self->SUPER::errorOutput( $errorOutput );
		}

		return $self->SUPER::errorOutput;
	}


	### METHOD: getDefines( @defineNames )
	### Get the evaluated values of the defines specified. Returns the values if
	### called in list context, and the number of defines returned in scalar
	### context. Throw an exception on any error.
	sub getDefines {
		my $self = shift	or throw Text::Templar::Exception::MethodError;
		my @keys = @_		or return ();

		my @rvals = map {
			exists $self->{defines}{$_} && defined $self->{defines}{$_}
				? ref $self->{defines}{$_}
					? $self->{defines}{$_}
						: $self->_getEvaluatedValue( $self->{defines}{$_} )
							: undef
						} @keys;

		return @rvals;
	}
}


### (PROXY) METHOD: AUTOLOAD( @args )
### Handles method calls for the phases we don't have explicit handlers for, and
### client calls to directive methods.
sub AUTOLOAD {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my @args = @_;

	my (
		$method,
		$pattern,
		$content,
	   );

	### Chop off the package part of the method name
	( $method = $AUTOLOAD ) =~ s{.*::}{};

	### Handle missing node handlers as gracefully as we can. This just returns
	### the node in question (ie., no-op).
	return $args[0] if $method =~ m{^(?:preprocess|render)[A-Z]+$};

	### Attempt to get a container for a node by the same name as the method
	### being called
	if ( blessed $self ) {
		$self->addNodeContent( $method, @_ ) if ( @_ );
		return $self->getNodeContent( $method );
	}

	# We apparently don't handle this request
	return '' unless $self->missingMethodIsFatal;
	throw Text::Templar::Exception	"Could not access the '$AUTOLOAD' method.";
}


### METHOD: getNodeContent( $nodeName )
### Get the content given by the user for the specified node, if any. Returns
### the list of content, or throws an exception on any error.
sub getNodeContent {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $nodeName = shift	or throw Text::Templar::Exception::ParamError 1, "node name";

	my $content = [];

	### Get the inherited content first, then clobber it with overidden data if
	### it exists
	$content = $self->{inheritedContent}{$nodeName}
		if exists $self->{inheritedContent}{$nodeName};
	$content = $self->{content}{$nodeName}
		if exists $self->{content}{$nodeName} && @{$self->{content}{$nodeName}};

	return @$content;
}


### METHOD: addNodeContent( $nodeName, @contents )
### Add elements to the contents of the node specified. Returns the number of
### elements after adding the ones given. Throws an exception on any error.
sub addNodeContent {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $nodeName = shift	or throw Text::Templar::Exception::ParamError 1, "node name";

	my @elementsToAdd = @_	or throw Text::Templar::Exception::ParamError "No contents to add.";

	my $content = $self->{content}{$nodeName} || [];
	push @$content, @elementsToAdd;
	$self->{content}{$nodeName} = $content;

	return @$content;
}


### METHOD: setNodeContent( $nodeName, @contents )
### Set the contents of the node specified to the given contents. Returns the
### number of elements after setting. Throws an exception on any error.
sub setNodeContent {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $nodeName = shift	or throw Text::Templar::Exception::ParamError 1, "node name";

	my @elementsToSet = @_; #	or throw Text::Templar::Exception::ParamError "No contents to set.";

	$self->{content}{$nodeName} = \@elementsToSet;
	return @elementsToSet;
}


### METHOD: addContentNode( $nodeName )
### Add a content container for the node specified if it doesn't already
### exist. Returns a true value on success, and throws an exception on any
### error.
sub addContentNode {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $nodeName = shift	or throw Text::Templar::Exception::ParamError 1, "node name";

	$self->{content}{$nodeName} = [] unless exists $self->{content}{$nodeName};
	return 1;
}


### METHOD: addInheritedNode( $nodeName )
### Add an inherited content container for the node specified if it doesn't
### already exist. Returns a true value on success, and throws an exception
### on any error.
sub addInheritedNode {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $nodeName = shift	or throw Text::Templar::Exception::ParamError 1, "node name";

	$self->{inheritedContent}{$nodeName} = [] unless exists $self->{inheritedContent}{$nodeName};
	return 1;
}


### METHOD: propagateContent( \%contentHash )
### Add the key/value pairs from the given hash to this template's content if
### the key has been specified as one that should be inherited. Returns the
### number of content pairs propagated, or throws an exception on any error.
sub propagateContent {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $contentHash = shift or throw Text::Templar::Exception::ParamError 1, "content hash";

	my $count = 0;
	foreach my $key ( keys %{$self->{inheritedContent}} ) {
		$self->{inheritedContent}{ $key } = $contentHash->{$key}
			if exists $contentHash->{$key};
		$count++;
	}

	return $count;
}


### METHOD: getContentHash( undef )
### Returns a hash of content that is the result of merging this template's
### content and any content inherited from containing templates
sub getContentHash {
	my $self = shift		or throw Text::Templar::Exception::MethodError;

	### Return the two hashes merged into a single anonhash
	return { %{$self->{content}}, %{$self->{inheritedContent}} };
}



################################################################################
### I / O	M E T H O D S
################################################################################

### METHOD: load( $sourceFileName | \@sourceArray )
### Load template data from a file or arrayref, parse it, and create the
### object's structure by examining the resulting syntax tree. Returns a
### true value if all goes well, or throws an exception on any error.
sub load {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $source = shift	or throw Text::Templar::Exception::ParamError 1, "source array or filename";

	### If the source looks like a filename, attempt to parse it as such
	if ( not ref $source ) {

		$source = $self->_findFile( $source );
		$self->sourceName( $source );

		### If the source is an array, attempt to parse it
	} elsif ( ref $source eq 'ARRAY' ) {

		$self->sourceName( '{anonymous template}' );

		### Everything else is an error
	} else {
		throw Text::Templar::Exception::TemplateError
			"Illegal source type: Expected a filename or an arrayref, got a '",
				ref $source, "'."
			}

	my $syntaxTree = $self->parse( $source );
	$self->syntaxTree( $syntaxTree );
	$self->_parsed( 1 );

	return scalar @$syntaxTree;
}


### METHOD: parse( $sourcePath | \@sourceArray )
### Given an absolute path to a template, or an arrayref of template content,
### create an initial syntax tree and preprocess it to create the object
### attributes necessary to interact with the template. Returns a processed
### syntax tree.
sub parse {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $source = shift	or throw Text::Templar::Exception::ParamError 1, "template source array or pathname";

	my (
		$syntaxTree,
		$filteredNodes,
	   );

	### Parse the template to create the initial syntax tree
	$syntaxTree = ref $source
		? $self->_parseArray( $source )
			: $self->_parseFile( $source );

	### Process the tree
	$filteredNodes = $self->filterSyntaxTree( $syntaxTree, 'preprocess' );

	### Set the per-object syntax tree and return the number of elements in the
	### kept tree
	return wantarray ? @$filteredNodes : $filteredNodes;
}


### METHOD: render( undef )
### Returns the syntax tree rendered into the final output form.
sub render {
	my $self = shift	or throw Text::Templar::Exception::MethodError;

	my (
		$tree,
		@output,
	   );

	# Get the tree up until the 'STOP' node
	$tree = $self->syntaxTree;

	# Render the AST
	@output = $self->filterSyntaxTree( $tree, 'render' );

	# If we're at the top level, append any tailed errors
	if ( $self->{_depth} == 0 ) {
		#push @output, "<!-- Depth is $self->{_depth} -->";
		push @output, map { $self->_buildComment($_) . "\n\n" } @{$self->_tailedErrors}
			if @{$self->_tailedErrors};
	}

	return wantarray ? @output : join '', @output;
}


### METHOD: filterSyntaxTree( \@nodes, $phaseName )
### Filter the given nodes by calling the appropriate method for each node as
### indicated by the phase name. Returns the filtered nodes, and throws an
### exception on any error.
sub filterSyntaxTree {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $nodes = shift		or throw Text::Templar::Exception::ParamError 1, "nodes";
	my $phaseName = shift	or throw Text::Templar::Exception::ParamError 1, "phase name";

	my $chompNextSubnode = shift || 0;

	### Do error-checking
	throw Text::Templar::Exception::ParamError 1, "Nodes must be a reference to an array not a ".
		( ref $nodes ? ref $nodes : "simple scalar" )
			unless ref $nodes eq 'ARRAY';

	my (
		@rvals,
		@keptNodes,
		$nodeType,
		$method,
		@processedNodes,
		$maxIncludeDepth,
	   );

	$maxIncludeDepth = $self->maxIncludeDepth;

	### Iterate over each node of the syntax tree and send each off to be
	### processed. The processing method can either indicate that we should keep
	### the node by returning it, or discard it, in which case it returns the
	### undefined value.
	@keptNodes = ();
	foreach my $node ( @$nodes ) {

		# Non-object nodes just get stuck into the syntax tree as-is
		push( @keptNodes, $node ), next
			if not blessed $node;

		# Templates (ie., from INCLUDE directives) get rendered in place.
		push( @keptNodes, $self->_getRenderedValues($node) ), next
			if $node->isa( 'Text::Templar' );

		# Exceptions and anything else gets added as-is
		push( @keptNodes, $node ), next
			unless $node->isa( 'Text::Templar::node' );

		# Subnodes have a chance to modify themselves for each phase.
		push( @keptNodes, $node->$phaseName($chompNextSubnode) ), next
			if $node->isa( 'Text::Templar::subnode' );

		### If this is the parse phase, and this node is a 'STOP' directive,
		### stop the traversal
		$nodeType = $node->type;
		last if $phaseName eq 'render' && $nodeType eq 'STOP';

		### Disallow nodes with the same name as methods we already have defined
		### :FIXME: This, I suspect, is a rather expensive operation to do for
		### every node name. I should think there's a better way to do this,
		### or perhaps it's not even necessary.
		if ( $node->name ) {
		  NO_STRICT: {
				no strict 'refs';
				my $test = *{ "Text::Templar::" . $node->name };

				throw Text::Templar::Exception::TemplateError
					"Illegal node name: '", $node->name,
						"' is reserved, as it is a native Templar method."
							if defined &test;
			}
		}

		# Figure out the name of the processing method
		$method = "${phaseName}${nodeType}";

		### Call the processing method, handling any errors we may encounter
		### along the way
		@processedNodes = try {
			if ( ++$self->{_depth} > $maxIncludeDepth ) {
				throw Text::Templar::Exception::RecursionError
					"Too deep recursion ($self->{_depth}) while ${phaseName}ing";
			}
			$self->$method( $node );
		} catch Text::Templar::Exception with {
			my $exception = shift;
			throw $exception if $exception->isa( 'Text::Templar::Exception::RecursionError' );
			$self->_getRenderedValues( $self->_handleException($exception, $phaseName, $nodeType) );
		} finally {
			$self->{_depth}--;
		};

		push @keptNodes, @processedNodes;

	} continue {

		# Check to see if the node will need the newline immediately after it
		# removed.
		$chompNextSubnode = blessed $node && $node->isa( 'Text::Templar::node' )
			? $node->needsChomp
				: 0;

		# If the current node is a 'CUT' node, throw away all the nodes
		# processed so far, including the 'CUT'.
		@keptNodes = () if $node->isa('Text::Templar::CUT');
	}

		return wantarray ? @keptNodes : \@keptNodes;
}




###############################################################################
### P R E P R O C E S S	  N O D E	M E T H O D S
###############################################################################

### METHOD: preprocessMETHOD( $node )
### Process the given 'METHOD' node in the parse phase. Throws an exception on
### any error.
sub preprocessMETHOD {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->name );
	return $node;
}


### METHOD: preprocessDUMP( $node )
### Process the given 'DUMP' node in the parse phase. Throws an exception on
### any error.
sub preprocessDUMP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->name );
	return $node;
}


### METHOD: preprocessMETHODCALL( $node )
### Process the given 'METHODCALL' node in the parse phase. Returns the
### (possibly modified?)  node if it should be kept in the syntax tree, and
### returns the undefined value otherwise. Throws an exception on any error.
sub preprocessMETHODCALL {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->name );
	return $node;
}


### METHOD: preprocessDEFINE( $node )
### Process the given 'DEFINE' node in the parse phase. Throws an exception on
### any error.
sub preprocessDEFINE {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my $val;

	### Get the value that's to be assigned
	if ( $node->quotedArgument ) {
		$val = $node->quotedArgument;
	} elsif ( $node->codeblock ) {
		$val = $self->_getEvaluatedValue( $node->codeblock->content, $self, $node );
	}

	### Figure out which kind of key it is, and assign the value to it in the
	### defines hash
	if ( $node->name ) {
		$self->setDefines( $node->name => $val );
	} elsif ( $node->variable ) {
		$self->setDefines( $node->variable => $val );
	}

	# We don't need the node repeated, so we just return the empty list
	return ();
}


### METHOD: preprocessINHERIT( $node )
### Process the given 'INHERIT' node in the parse phase. Throws an exception on
### any error.
sub preprocessINHERIT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	#$self->addContentNode( $node->name );
	$self->addInheritedNode( $node->name );
	return ();
}


### METHOD: preprocessCUT( $node )
### Process the given 'CUT' node in the parse phase.
sub preprocessCUT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	return $node;
}

### METHOD: preprocessSTOP( $node )
### Process the given 'STOP' node in the parse phase. Since an end node is only
### meaningful in the render phase, this method just returns the specified
### node. Throws an exception on any error.
sub preprocessSTOP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	return $node;
}


### METHOD: preprocessEVAL( $node )
### Process the given 'EVAL' node in the parse phase. Returns the result of
### evaluating the codeblock or variable specified in the node. Throws an
### exception on any error.
sub preprocessEVAL {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	### Delay evals until render time
	return $node;
}


### METHOD: preprocessINCLUDE( $node )
### Process the given 'INCLUDE' node in the parse phase. Throws an exception on
### any error.
sub preprocessINCLUDE {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my $subTemplate = $self->new();
	$subTemplate->includePath([ $self->includePath ]);
	$subTemplate->load( $node->path );

	return $subTemplate;
}


### METHOD: preprocessQUERY( $node )
### Process the given 'QUERY' node in the parse phase. Throws an exception on
### any error.
sub preprocessQUERY {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->pushQueries( $node );
	$self->addContentNode( $node->name );
	return bless $node, 'Text::Templar::METHOD';
}


### METHOD: preprocessENV( $node )
### Process the given 'ENV' node in the parse phase. Throws an exception on
### any error.
sub preprocessENV {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	# Delay ENV directives until render time
	return $node;
}


### METHOD: preprocessMETA( $node )
### Process the given 'META' node in the parse phase. Throws an exception on
### any error.
sub preprocessMETA {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->setMetafields( $node->name => $node->argument );
	return ();
}


### METHOD: preprocessELSE( $node )
### Process the given 'ELSE' node in the parse phase. The else node doesn't
### require any preprocessing, so we just return it to its native habitat
### unharmed. 'Say, Terri. Look at that deadly poisonous ELSE directive:
### what a beautiful animal.'
sub preprocessELSE {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	return $node;
}


### METHOD: preprocessELSIF( $node )
### Process the given 'ELSIF' node in the parse phase.
sub preprocessELSIF {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	### If the node contains either a name or an object node, add a content node
	### to the template object to contain their content
	if ( $node->name ) {
		$self->addContentNode( $node->name );
	} elsif ( $node->object ) {
		$self->addContentNode( $node->object );
	}

	return $node;
}




### Container tags

### METHOD: preprocessFOREACH( $node )
### Process the given 'FOREACH' node in the parse phase. Throws an exception on
### any error.
sub preprocessFOREACH {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->object || $node->name );
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );

	$node->subnodes( @filteredNodes );
	return $node;
}


### METHOD: preprocessIF( $node )
### Process the given 'IF' node in the parse phase. Throws an exception on
### any error.
sub preprocessIF {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	### If the node contains either a name or an object node, add a content node
	### to the template object to contain their content
	if ( $node->name ) {
		$self->addContentNode( $node->name );
	} elsif ( $node->object ) {
		$self->addContentNode( $node->object );
	}

	### Now filter the parts that were in the positive parts of the condition (if any).
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );
	$node->subnodes( @filteredNodes );
	return $node;
}


### METHOD: preprocessGREP( $node )
### Process the given 'GREP' node in the parse phase. Throws an exception on
### any error.
sub preprocessGREP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->object || $node->name );
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );

	$node->subnodes( @filteredNodes );
	return $node;
}


### METHOD: preprocessMAP( $node )
### Process the given 'MAP' node in the parse phase. Throws an exception on
### any error.
sub preprocessMAP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->object || $node->name );
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );

	$node->subnodes( @filteredNodes );
	return $node;
}


### METHOD: preprocessSORT( $node )
### Process the given 'SORT' node in the parse phase. Throws an exception on
### any error.
sub preprocessSORT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->object || $node->name );
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );

	$node->subnodes( @filteredNodes );
	return $node;
}


### METHOD: preprocessJOIN( $node )
### Process the given 'JOIN' node in the parse phase. Throws an exception on
### any error.
sub preprocessJOIN {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	$self->addContentNode( $node->object || $node->name );
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );

	$node->subnodes( @filteredNodes );
	return $node;
}


### METHOD: preprocessTRIM( $node )
### Process the given 'TRIM' node in the parse phase. Just returns the
### node. Throws an exception on any error.
sub preprocessTRIM {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	### If the node contains either a name or an object node, add a content node
	### to the template object to contain their content
	if ( $node->name ) {
		$self->addContentNode( $node->name );
	} elsif ( $node->object ) {
		$self->addContentNode( $node->object );
	}

	### Filter the subnodes
	my @filteredNodes = $self->filterSyntaxTree( $node->subnodes, 'preprocess', 1 );
	$node->subnodes( @filteredNodes );
	return $node;
}

### Alias the MAXLENGTH handler to the TRIM handler
*Text::Templar::preprocessMAXLENGTH = *Text::Templar::preprocessTRIM;


### METHOD: preprocessCOMMENT( $node )
### Process the given 'COMMENT' node in the parse phase. Throws an exception on
### any error.
sub preprocessCOMMENT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	### Discard everything in a comment block
	return ();
}


### METHOD: preprocessDELAYED( $node )
### Process the given 'DELAYED' node in the parse phase. The DELAYED tag just
### delays the processing of the nodes it contains until the next phase, so
### this method just returns the DELAYED node's subnodes. Throws an
### exception on any error.
sub preprocessDELAYED {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	warn "Deprecated tag DELAYED used in ", $self->sourceName;

	return @{$node->subnodes};
}






###############################################################################
### R E N D E R	  N O D E	M E T H O D S
###############################################################################

### METHOD: renderMETHOD( $node )
### Process the given 'METHOD' node in the render phase. Returns the content
### that should be placed in the position occupied by the METHOD tag. Throws
### an exception on any error.
sub renderMETHOD {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		@nodeContent,
		$codeblock,
		$format,
	   );

	### If the METHOD has a codeblock, filter each content item through it first
	if (( $node->codeblock )) {
		@nodeContent = map {
			$self->_getRenderedEvaluatedValue( $node->codeblock->content, $self, $node, $_ );
		} $self->getNodeContent( $node->name );
	}

	### If the METHOD has a format, filter each content item through sprintf first
	elsif (( $format = $node->format )) {
		@nodeContent = map {
			$self->_getRenderedValues( sprintf $format, $_ );
		} $self->getNodeContent( $node->name );
	} else {
		@nodeContent = $self->_getRenderedValues($self->getNodeContent( $node->name ));
	}

	return @nodeContent;
}


### METHOD: renderDUMP( $node )
### Process the given 'DUMP' node in the render phase. Returns the content
### that should be placed in the position occupied by the DUMP tag. Throws
### an exception on any error.
sub renderDUMP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my @content = $self->getNodeContent( $node->name );
	return Data::Dumper->Dumpxs( \@content, [$node->name] );
}


### METHOD: renderMETHODCALL( $node )
### Process the given 'METHODCALL' node in the render phase. Returns the content
### that should be placed in the position occupied by the METHODCALL
### tag. Throws an exception on any error.
sub renderMETHODCALL {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		@rvals,
		@objects,
	   );

	### Get the list of objects to which we will be applying the method chain
	@objects = $self->getNodeContent( $node->name );
	return '' unless @objects;

	### Iterate over the objects, calling the method chain on each one
  OBJECT: foreach my $object ( @objects ) {
		push @rvals, $self->_traverseMethodChain( $object, $node->methodchain );
	}

	return $self->_getRenderedValues( @rvals );
}


### METHOD: renderDEFINE( $node )
### Process the given 'DEFINE' node in the render phase. Throws an exception on
### any error.
sub renderDEFINE {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	if ( $node->name ) {
		$self->setDefines( $node->name => $node->quotedArgument );
	} elsif ( $node->variable ) {
		$self->setDefines( $node->variable => $node->quotedArgument );
	}

	# A define doesn't show up in the rendered output, so we return the empty list
	return ();
}


### METHOD: renderINHERIT( $node )
### Process the given 'INHERIT' node in the render phase. Since inheritance
### happens before the parse phase, this generates an exception.
sub renderINHERIT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	throw Text::Templar::Exception::TemplateError
		"Too late for inheritance of '", $node->name, "' in parse phase.";
}


### METHOD: renderCUT( $node )
### Process the given 'CUT' node in the render phase.
sub renderCUT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	return $node;
}


### METHOD: renderSTOP( $node )
### Process the given 'STOP' node in the render phase.	Since an end node indicates
### the end of the syntax tree while in the parse phase, we shouldn't ever
### reach this method, and all this method does is throw an exception with a
### message to that effect.
sub renderSTOP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;

	### Something's gone horribly wrong if we see an end while rendering
	throw Text::Templar::Exception::TemplateError "STOP node encountered while rendering.";
}


### METHOD: renderEVAL( $node )
### Process the given 'EVAL' node in the render phase. Returns the result of
### evaluating the codeblock or variable specified in the node. Throws an
### exception on any error.
sub renderEVAL {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		$rval,
		$format,
	   );

	### Codeblock eval
	if ( $node->codeblock ) {
		$rval = $self->_getRenderedEvaluatedValue( $node->codeblock->content );

		if (( $format = $node->format )) {
			$rval = sprintf $format, $rval;
		}
	}

	### Variable eval
	elsif ( $node->variable ) {
		$rval = $self->_getRenderedEvaluatedValue( $node->variable );

		if (( $format = $node->format )) {
			$rval = sprintf $format, $rval;
		}
	}

	return $rval;
}


### METHOD: renderINCLUDE( $node )
### Process the given 'INCLUDE' node in the render phase. Throws an exception on
### any error.
sub renderINCLUDE {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		$templatePath,
		$subTree,
		$renderedSubTree,
	   );

	$templatePath = $self->_findFile( $node->path );

	$subTree = $self->parse( $templatePath );
	$renderedSubTree = $self->filterSyntaxTree( $subTree, 'render' );

	return wantarray ? @$renderedSubTree : join '', @$renderedSubTree;
}


### METHOD: renderQUERY( $node )
### Process the given 'QUERY' node in the render phase. Since queries are really
### only useful before the render phase, this method just returns the empty
### list. Throws an exception on any error.
sub renderQUERY {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	return ();
}


### METHOD: renderENV( $node )
### Process the given 'ENV' node in the render phase. Throws an exception on
### any error.
sub renderENV {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		$rval,
		$format,
	   );

	### If the ENV has a format, use it
	if (( $format = $node->format )) {
		$rval = sprintf $format, $ENV{$node->name} || $self->undefinedValue;
	}

	### Otherwise just use the value
	else {
		$rval = $ENV{$node->name} || $self->undefinedValue;
	}

	return $self->_getRenderedValues( $rval );
}


### METHOD: renderMETA( $node )
### Process the given 'META' node in the render phase. Since metafields are
### really only useful before the render phase, this method just returns
### the empty list. Throws an exception on any error.
sub renderMETA {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	return ();
}


### METHOD: renderELSE( $node )
### Process the given 'ELSE' node in the parse phase. Rendering an ELSE
### outside of an enclosing IF is an error, so this method just generates an
### exception with a message to that effect.
sub renderELSE {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	throw Text::Templar::Exception::TemplateError "ELSE tag encountered outside of enclosing IF block.";
}


### METHOD: renderELSIF( $node )
### Process the given 'ELSIF' node in the parse phase.	Rendering an ELSIF
### outside of an enclosing IF is an error, so this method just generates an
### exception with a message to that effect.
sub renderELSIF {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	throw Text::Templar::Exception::TemplateError "ELSIF tag encountered outside of enclosing IF block.";
}


### METHOD: renderFOREACH( $node )
### Process the given 'FOREACH' node in the render phase. Throws an exception on
### any error.
sub renderFOREACH {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my @iteratedNodes = $self->_renderIteratedContent( $node );
	return $self->_getRenderedValues( @iteratedNodes );
}


### METHOD: renderIF( $node )
### Process the given 'IF' node in the render phase. Throws an exception on
### any error.
sub renderIF {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		$condition,
		$matchSpec,
		$haveSeenPositiveCondition,
		@keptNodes,
		@filteredNodes,
	   );

	@keptNodes = ();
	$haveSeenPositiveCondition = 0;

	### Test the condition in the IF node, setting the condition to a true value
	### if it evaluates to true.
	$condition = $haveSeenPositiveCondition = 1
		if $self->_evaluateCondition( $node );

	### Iterate over each subnode, looking for parts of the condition.
	foreach my $subNode ( @{$node->subnodes} ) {

		### ELSE node turns the condition true if we're in a negative condition,
		### and we haven't yet seen a positive condition
		if ( $subNode->isa('Text::Templar::ELSE')  ) {
			$condition = 1 - $haveSeenPositiveCondition;
			next;
		}

		### ELSIF node turns the condition true if we haven't yet seen a
		### positive condition, and the test is true
		elsif ( $subNode->isa('Text::Templar::ELSIF') ) {

			### Abort if we've already seen a positive
			if ( $haveSeenPositiveCondition ) {
				$condition = 0;
			}

			### Evaluate the subnode condition
			else {
				$condition = $haveSeenPositiveCondition = 1
					if $self->_evaluateCondition( $subNode );
			}

			next;
		}

		next unless $condition;
		push @keptNodes, $subNode;
	}

	### Now filter the parts that were in the positive parts of the condition (if any).
	@filteredNodes = $self->filterSyntaxTree( \@keptNodes, 'render' );

	return @filteredNodes;
}


### METHOD: renderGREP( $node )
### Process the given 'GREP' node in the render phase. Throws an exception on
### any error.
sub renderGREP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		@realContainer,
		@iteratedContent,
		$realDefine,
		$subTree,
		$filterFunc,
		$iteratorDefine,
		@filteredContents,
		@renderedTree,
	   );

	### Make a copy of the real contents and define so we can restore them later
	@realContainer = $self->getNodeContent( $node->name );
	( $realDefine ) = $self->getDefines( $node->name );

	### Get the node's subnodes
	$subTree = $node->subnodes;

	### If the node has a methodchain, use it to retrieve aggregates
	if (( my $chain = $node->methodchain )) {

		### Iterate over the objects, calling the method chain on each one
		foreach my $object ( $self->getNodeContent($node->object) ) {
			push @iteratedContent, $self->_traverseMethodChain( $object, $chain );
		}
	}

	### If there's no methodchain, just use the contents of the normal container
	else {
		@iteratedContent = @realContainer;
	}

	### Get the filter function by generating a closure out of the node's codeblock
	$filterFunc = $self->_buildClosure( $node->codeblock->content );

	### Filter the node's content using the filter function
	@filteredContents = grep {
		$filterFunc->( $_, $self, $node )
	} @iteratedContent;

	### Build a shortcut for accessing the iterator. This will show up in the
	### evaluation environment of anything that requires an eval in the
	### rendering of the subtree
	$iteratorDefine = sprintf q{$self->getNodeContent( '%s' );}, $node->name;

	### Iterate over each element of the content array, overriding the real
	### content of the node with the iterated value, and rendering the subtree
	### inside the foreach.
	$self->setNodeContent( $node->name, @filteredContents );
	$self->setDefines( $node->name, $iteratorDefine );

	### Now render the node's subtree with the changes contents and define
	@renderedTree = $self->filterSyntaxTree( $subTree, 'render' );

	### Restore the real contents and define
	$self->setNodeContent( $node->name => @realContainer );
	$self->setDefines( $node->name => $realDefine );

	return @renderedTree;
}


### METHOD: renderMAP( $node )
### Process the given 'MAP' node in the render phase. Throws an exception on
### any error.
sub renderMAP {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		@realContainer,
		@iteratedContent,
		$realDefine,
		$subTree,
		$transformFunc,
		$iteratorDefine,
		@transformedContents,
		@renderedTree,
	   );

	### Make a copy of the real contents and define so we can restore them later
	@realContainer = $self->getNodeContent( $node->name );
	( $realDefine ) = $self->getDefines( $node->name );

	### If the node has a methodchain, use it to retrieve aggregates
	if (( my $methodChain = $node->methodchain )) {

		### Iterate over the objects, calling the method chain on each one
		foreach my $object ( $self->getNodeContent($node->object) ) {
			push @iteratedContent, $self->_traverseMethodChain( $object, $methodChain );
		}
	}

	### If there's no methodchain, just use the contents of the normal container
	else {
		@iteratedContent = @realContainer;
	}

	### Get the node's subnodes
	$subTree = $node->subnodes;

	### Get the transform function by generating a closure out of the node's codeblock
	$transformFunc = $self->_buildClosure( $node->codeblock->content );

	### Transform the node's content using the transform function
	@transformedContents = map {
		$transformFunc->( $_, $self, $node )
	} @iteratedContent;

	### Build a shortcut for accessing the iterator. This will show up in the
	### evaluation environment of anything that requires an eval in the
	### rendering of the subtree
	$iteratorDefine = sprintf q{$self->getNodeContent( '%s' );}, $node->name;

	### Iterate over each element of the content array, overriding the real
	### content of the node with the iterated value, and rendering the subtree
	### inside the foreach.
	$self->setNodeContent( $node->name, @transformedContents );
	$self->setDefines( $node->name, $iteratorDefine );

	### Now render the node's subtree with the changed contents and define
	@renderedTree = $self->filterSyntaxTree( $subTree, 'render' );

	### Restore the real contents and define
	$self->setNodeContent( $node->name => @realContainer );
	$self->setDefines( $node->name => $realDefine );

	return @renderedTree;
}


### METHOD: renderSORT( $node )
### Process the given 'SORT' node in the render phase. Throws an exception on
### any error.
sub renderSORT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		@realContainer,
		@iteratedContent,
		$realDefine,
		$aDefine,
		$bDefine,
		$subTree,
		$sortFunc,
		$iteratorDefine,
		@sortedContents,
		@renderedTree,
	   );

	### Make a copy of the real contents and define so we can restore them later
	@realContainer = $self->getNodeContent( $node->name );
	( $realDefine, $aDefine, $bDefine ) = $self->getDefines( $node->name, 'a', 'b' );

	### If the node has a methodchain, use it to retrieve aggregates
	if (( my $methodChain = $node->methodchain )) {
		### Iterate over the objects, calling the method chain on each one
		foreach my $object ( $self->getNodeContent($node->object) ) {
			push @iteratedContent, $self->_traverseMethodChain( $object, $methodChain );
		}
	}

	### If there's no methodchain, just use the contents of the normal container
	else {
		@iteratedContent = @realContainer;
	}

	### Get the node's subnodes
	$subTree = $node->subnodes;

	### Get the sort function by generating a closure out of the node's codeblock
	$self->setDefines( a => '$_[0]', b => '$_[1]' );
	$sortFunc = $self->_buildClosure( $node->codeblock->content );

	### Sort the node's content using the sort function
	@sortedContents = sort {
		$sortFunc->( $a, $b, $self, $node );
	} @iteratedContent;

	### Build a shortcut for accessing the iterator. This will show up in the
	### evaluation environment of anything that requires an eval in the
	### rendering of the subtree
	$iteratorDefine = sprintf q{$self->getNodeContent( '%s' );}, $node->name;

	### Iterate over each element of the content array, overriding the real
	### content of the node with the iterated value, and rendering the subtree
	### inside the foreach.
	$self->setNodeContent( $node->name, @sortedContents );
	$self->setDefines( $node->name, $iteratorDefine );

	### Now render the node's subtree with the changes contents and define
	@renderedTree = $self->filterSyntaxTree( $subTree, 'render' );

	### Restore the real contents and define
	$self->setNodeContent( $node->name => @realContainer );
	$self->setDefines( $node->name => $realDefine, a => $aDefine, b => $bDefine );

	return @renderedTree;
}


### METHOD: renderJOIN( $node )
### Process the given 'JOIN' node in the render phase. Throws an exception on
### any error.
sub renderJOIN {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my @iteratedNodes = $self->_renderIteratedContent( $node );
	my $separator = $self->_getEvaluatedValue( $node->quotedArgument );
	return join $separator, @iteratedNodes;
}


### METHOD: renderTRIM( $node )
### Process the given 'TRIM' node in the render phase. Throws an exception on
### any error.
sub renderTRIM {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		$length,
		$content,
	   );

	### If the length is to be determined from the results of a methodchain
	if ( $node->object && $node->methodchain ) {
		my $object = ($self->getNodeContent($node->object))[-1];
		( $length ) = $self->_traverseMethodChain( $object, $node->methodchain );
		$length = $length;
	}

	### If the node value is just a simple integer
	elsif ( $node->integer ) {
		$length = $node->integer;
	}

	### If the node is a targeted value
	elsif ( $node->name ) {
		( $length ) = $self->getNodeContent( $node->name );
	}

	### If the node is derived from evaluating a codeblock
	elsif ( $node->codeblock ) {
		$length = $self->_getEvaluatedValue( $node->codeblock->content );
	}

	### If the node is in a defined variable
	elsif ( $node->variable ) {
		$length = $self->_getEvaluatedValue( $node->variable );
	} else {
		$length = 0;
	}

	$length = int $length;

	# No sense in rendering the rest if we're not going to display it... or is there?
	#return () unless $length > 0;

	$content = join '', $self->filterSyntaxTree( $node->subnodes, 'render' );
	return substr $content, 0, $length;
}

### Alias the MAXLENGTH handler to the TRIM handler
*Text::Templar::renderMAXLENGTH = *Text::Templar::renderTRIM;


### METHOD: renderCOMMENT( $node )
### Process the given 'COMMENT' node in the render phase. Throws an exception on
### any error.
sub renderCOMMENT {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	### Discard everything in a comment block
	return ();
}


### METHOD: renderDELAYED( $node )
### Process the given 'DELAYED' node in the render phase. Since the DELAY is
### supposed to postpone processing until the render phase, encountering a
### DELAY node here is an error, so all this method does is generate an
### exception with a message to that effect.
sub renderDELAYED {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	throw Text::Templar::Exception::TemplateError "DELAY node encountered in render phase.";
}





###############################################################################
### P R I V A T E / P R O T E C T E D	M E T H O D S
###############################################################################

### (PROTECTED CLASS) METHOD: _GetParser( undef )
### Get the parser object for parsing templar templates. Constructs a new parser
### if necessary. Return the parser object, and throws an exception on any
### error.
sub _GetParser {
	my $class = shift	or throw Text::Templar::Exception::MethodError;

	my $parser;
	unless (( $parser = $class->_Parser )) {
		$parser = new Text::Templar::Parser;
		$class->_Parser( $parser );
	}

	return $parser;
}


### (PROTECTED) METHOD: _renderIteratedContent( $node )
### Build an iterator over the subnodes of the specified node using the node's
### content.
sub _renderIteratedContent {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node object";

	my (
		@realContainer,
		@iteratedContent,
		$realDefine,
		$realIteration,
		$realLastIteration,
		$subTree,
		$renderedSubtree,
		$iteratorDefine,
		@iteratedNodes,
		$nodeName,
	   );

	### Get the defaults so we can restore 'em later
	@realContainer = $self->getNodeContent( $node->name );
	( $realDefine, $realIteration, $realLastIteration )
		= $self->getDefines( $node->name, '$ITERATION', '$LAST_ITERATION' );

	### Get the subnodes for this container
	$subTree = $node->subnodes;
	@iteratedContent = $self->_buildIteratedContent( $node );
	@iteratedNodes = ();

	### Build a shortcut for accessing the iterator. This will show up in the
	### evaluation environment of anything that requires an eval in the
	### rendering of the subtree
	$iteratorDefine = sprintf q{$self->getNodeContent( '%s' );}, $node->name;

	### Iterate over each element of the content array, overriding the real
	### content of the node with the iterated value, and rendering the subtree
	### inside the foreach.
	$nodeName = $node->name || $node->object;
	$self->setDefines( '$LAST_ITERATION' => 0 );
	for ( my $i = 0; $i <= $#iteratedContent ; $i++ ) {
		$self->setNodeContent( $nodeName => $iteratedContent[$i] );
		$self->setDefines( $nodeName => $iteratorDefine );
		$self->setDefines( '$LAST_ITERATION' => ($i == $#iteratedContent ? 1 : 0) );
		$self->setDefines( '$ITERATION' => $i + 1 );

		$renderedSubtree = $self->filterSyntaxTree( $subTree, 'render' );
		push @iteratedNodes, join( '', @$renderedSubtree );
	}

	### Restore the real contents and define
	$self->setNodeContent( $node->name => @realContainer );
	$self->setDefines( '$ITERATION' => $realIteration || "''" );
	$self->setDefines( '$LAST_ITERATION' => $realLastIteration || "''" );
	$self->setDefines( $node->name => $realDefine );

	return @iteratedNodes;
}


### (PROTECTED) METHOD: _buildIteratedContent( $node )
### Build a list of content that will be iterated over out of the given I<node>.
sub _buildIteratedContent {
	my $self	= shift		or throw Text::Templar::Exception::MethodError;
	my $node	= shift		or throw Text::Templar::Exception::ParamError 1, "node";

	my @iteratedContent = ();

	### If the foreach has an object and a methodchain, build the iterated list
	### out of the results of calling the method chain on the object/s
	if ( $node->object && $node->methodchain ) {

		### Iterate over the objects, calling the method chain on each one
		foreach my $object ( $self->getNodeContent($node->object) ) {
			my @results = $self->_traverseMethodChain( $object, $node->methodchain );

			# Debugging simplified deref in the grammar
			# printf STDERR ( "Deref for '%s' is: '%s'\n",
			#			$node->name,
			#			(defined $node->deref ? $node->deref : '(undef)') );
			# STDERR->flush;

			# If the node's a hash iterator, build the iterated content
			if ( $node->pair ) {
				push @iteratedContent,
					$self->_buildHashIteratedContent( $node, @results );
			}

			# ...or if it's a deref operation, deref it
			elsif ( $node->deref ) {
				foreach my $result ( @results ) {
					push @iteratedContent, $self->_deref( $result );
				}
			}

			# ...otherwise, we don't have anything else to do
			else {
				push @iteratedContent, @results;
			}
		}

	}

	### If the foreach is a dereference, figure out how to dereference the
	### argument and set the iterated content to that.
	elsif ( $node->object && $node->deref ) {
		foreach my $reference ( $self->getNodeContent($node->object) ) {
			push @iteratedContent, $self->_deref( $reference );
		}
	}

	### It's either plain content or a hash iterator
	else {
		@iteratedContent = $self->getNodeContent( $node->object || $node->name );
		@iteratedContent = $self->_buildHashIteratedContent( $node, @iteratedContent )
			if $node->pair;
	}

	return @iteratedContent;
}


### (PROTECTED) METHOD: _buildHashIteratedContent( $node, @content )
### Attempt to build a list of hashrefs with key and value pairs for hash
### iterators.
sub _buildHashIteratedContent {
	my $self	= shift		or throw Text::Templar::Exception::MethodError;
	my $node	= shift		or throw Text::Templar::Exception::ParamError 1, "node";
	my @content = @_;

	throw Text::Templar::Exception::ParamError "node", ["Text::Templar::Node"], $node
		unless blessed $node && $node->isa( "Text::Templar::node" );

	my @iteratedContent = ();

	# If we got one result and it's a hashref, map the single hash
	# into a list of hashrefs with key and value pairs
	if ( @content == 1 && ref $content[0] eq 'HASH' ) {
		@iteratedContent = map {{ key => $_, value => $content[0]{$_} }} keys %{$content[0]};
	}

	# If we got an even array of content, it must be a regular
	# hash, so shift 'em off two at a time to build our hashrefs
	elsif ( @content % 2 == 0 ) {
		while ( @content ) {
			push @iteratedContent, {
				key => shift @content,
				value => shift @content,
			};
		}
	}

	# ...otherwise, something funky happened, so throw an exception.
	else {
		my $nodeName = $node->name;
		throw Text::Templar::Exception
			"Cannot do hash iteration: Pair value for '$nodeName' is neither hash nor hashref.";
	}

	# Handle sorted hash iterations
	if ( my $sortNode = $node->hashpairsort ) {
		my ( $realDefine, $aDefine, $bDefine ) = $self->getDefines( $node->name, 'a', 'b' );

		$self->setDefines( a => '$_[0]', b => '$_[1]' );
		my $sortFunc = $self->_buildClosure( $sortNode->content );
		@iteratedContent = sort {
			$sortFunc->( $a, $b, $self, $sortNode );
		} @iteratedContent;
		$self->setDefines( $node->name => $realDefine, a => $aDefine, b => $bDefine );
	}


	return @iteratedContent;
}


### (PROTECTED) METHOD: _parseTemplateSource( \@source, $sourceName )
### Parse the given source and return a syntax tree
sub _parseTemplateSource {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $source = shift		or throw Text::Templar::Exception::ParamError 1, "source arrayref";
	my $sourceName = shift	or throw Text::Templar::Exception::ParamError 2, "source name";

	throw Text::Templar::Exception::ParamError "Source must be an array reference, not a ",
		ref $source ? ref $source : 'simple scalar', "."
			unless ref $source eq 'ARRAY';

	$source = join '', @$source if ref $source;

	my (
		$parser,
		$tree,
	   );

	$parser = $self->_GetParser;
	$parser->{local}{source} = $sourceName;

  LOCALIZE: {
		local ( $::RD_ERRORS, $::RD_CHECK, $::RD_WARN );
		undef $::RD_ERRORS;
		undef $::RD_CHECK;
		undef $::RD_WARN;

		$tree = $parser->parse( $source );
	}

	### If the parse failed somehow, build an error message and throw it
	unless ( $tree ) {
		my $parseError = _buildParseError( $parser->{errors} )
			|| "(Unknown error)";

		throw Text::Templar::Exception::TemplateError $parseError;
	}

	return wantarray ? @$tree : $tree;
}


### (PROTECTED) METHOD: _parseFile( $filename )
### Load and parse a file, returning the resultant syntax tree. Throws an
### exception on any error.
sub _parseFile {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $filename = shift	or throw Text::Templar::Exception::ParamError 1, "filename";

	my (
		$source,
		$includePath,
		$tree,
	   );


	### If we already have a syntax tree cached for this filename, we're allowed
	### to use it, and the source from which the tree was parsed hasn't been
	### modified since it was loaded, use the cached tree.
	### :TODO: Maybe add some kind of time threshold so we only stat() the file
	### every so often?
	if ( exists $CachedTree{$filename}
			 && $self->cacheTrees
				 && $CachedTree{$filename}{mtime} >= (stat $filename)[9] ) {
		$self->sourceName( "$filename (cached tree)" );
		return wantarray ? @{$CachedTree{$filename}{tree}} : [@{$CachedTree{$filename}{tree}}];
	}

	### Get the source from the file
	$source = $self->_loadFile( $filename )
		or throw Text::Templar::Exception::TemplateError "Failed to parse file: No template content.";

	# Parse and cache the tree if we're allowed
	$tree = $self->_parseTemplateSource( $source, $filename );
	$CachedTree{$filename} = { tree => $tree, mtime => time() }
		if $self->cacheTrees;

	return wantarray ? @$tree : $tree;
}


### (PROTECTED) METHOD: _parseArray( \@contentArray )
### Parse an array reference of template source, returning the
### resultant syntax tree. Throws an exception on any error.
sub _parseArray {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $content = shift or throw Text::Templar::Exception::ParamError 1, "content array";

	return $self->_parseTemplateSource( $content, '[Anonymous Template]' );
}


### (PROTECTED) METHOD: _loadFile( $path )
### Load the file specified by path and return its contents as an array (list
### context) or arrayref (scalar context). Throws an exception on any error.
sub _loadFile {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $path = shift	or throw Text::Templar::Exception::ParamError 1, "filename";

	my (
		$fh,					# The filehandle
		@source,				# The file content
	   );

	throw Text::Templar::Exception::IOError::File "File '$path' is either unreadable or non-existant."
		unless -r $path;

	### If we've already loaded this file, we're allowed to use the cached
	### version, and the cached source is up to date, use it instead of loading
	### it again
	### :TODO: Maybe add some kind of time threshold so we only stat() the file
	### every so often?
	if ( exists $CachedSource{$path}
			 && $self->cacheSource
				 && $CachedSource{$path}{mtime} >= (stat $path)[9] ) {
		$self->sourceName( "$path (cached source)" );
		return wantarray
			? @{$CachedSource{$path}{source}}
				: [ @{$CachedSource{$path}{source}} ];
	}

	### Read the whole file in and close the filehandle
	$fh = new IO::File "$path", "r"
		or throw Text::Templar::Exception::IOError::File "open: '$path': $!";
	@source = $fh->getlines;
	$CachedSource{$path} = {
		mtime	=> ($fh->stat)[9],
		source	=> \@source,
	};
	undef $fh;


	return wantarray ? @source : \@source;
}


### (PROTECTED) METHOD: _findFile( $filename )
### Given a possibly relative filename, attempt to figure out an absolute one
### and return it.
sub _findFile {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $filename = shift	or throw Text::Templar::Exception::ParamError 1, "filename";

	my (
		$includePath,			# The arrayref or string include path
		$path,					# The returned path
		@pathsToCheck,			# The array of directories to check for the file
	   );

	$filename =~ s{^(["'])(.+)(\1)$}{$1};

	### If they passed an absolute path, test for readability.
	if ( $filename =~ m{^/} ) {

		# Test the path
		throw Text::Templar::Exception "Could not find '$filename' (absolute path)"
			unless -r $filename;
		$path = $filename;
	}

	### Otherwise, figure out which kind of includepath we've got, and make a
	### path array. Look for the file at the end of each path.
	else {
		$includePath = $self->includePath;
		throw Text::Templar::Exception::TemplateError
			"Failed to open file '$filename': Invalid include path '$includePath'."
				unless ref $includePath eq 'ARRAY' || not ref $includePath;

		@pathsToCheck = ref $includePath
			? @{$includePath}
				: split m{[:;]}, $includePath;

		# Check each path for the file
		foreach my $pathToCheck ( @pathsToCheck ) {

			# Test the path, and break out if it's readable
			$path = "$pathToCheck/$filename", last
				if -r "$pathToCheck/$filename";
		}

		throw Text::Templar::Exception "Could not find '$filename' in include path (",
			join(':', @pathsToCheck), ")"
				unless defined $path && $path ne '';
	}


	return $path;
}


### (PROTECTED) METHOD: _evaluateCondition( $node )
### Evaluate the matchSpec associated with the given node with the node's
### content, returning '1' if the condition is true, and the empty list if
### it is not.
sub _evaluateCondition {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $node = shift	or throw Text::Templar::Exception::ParamError 1, "node";

	my (
		$matchSpec,
		$object,
	   );

	### Figure out which kind of eval needs to be done for the condition, and
	### evaluate it
	if ( $node->name ) {
		if (( $matchSpec = $node->matchspec )) {
			return 1 if $matchSpec->matches( $self->getNodeContent($node->name) );
		} else {
			return 1 if ($self->getNodeContent( $node->name ))[-1];
		}
	}

	### Methodcall
	elsif ( $node->object && $node->methodchain ) {

		### Fetch the last object to be added to the content array, and traverse
		### the specified method chain on it. A positive value causes the
		### condition to succeed.
		$object = ($self->getNodeContent( $node->object ))[-1]
			or return 0;
		my @results = $self->_traverseMethodChain( $object, $node->methodchain );

		# If there's a deref in the conditional node, deref each item in the results
		if ( $node->deref ) {
			my @derefResults = ();
			foreach my $result ( @results ) {
				push @derefResults, $self->_deref( $result );
			}
			@results = @derefResults;
		}

		if (( $matchSpec = $node->matchspec )) {
			return 1 if $matchSpec->matches( @results );
		} else {
			return 1 if scalar grep { $_ } @results;
		}
	}

	### Perl variable
	elsif ( $node->variable ) {
		if (( $matchSpec = $node->matchspec )) {
			return 1 if $matchSpec->matches( $self->_getEvaluatedValue($node->variable) );
		} else {
			return 1 if $self->_getEvaluatedValue( $node->variable );
		}
	}

	### Codeblock
	elsif ( $node->codeblock ) {
		return 1 if $self->_getEvaluatedValue( $node->codeblock->content );
	}

	return 0;
}


### (PROTECTED) METHOD: _deref( $value )
### Handle dereference of a target value for METHODCALL DEREF <name>, FOREACH
### DEREF <name>, etc.
sub _deref {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $value = shift	or throw Text::Templar::Exception::ParamError 1, "value";

	# If it's not a reference, return an exception
	return new Text::Templar::Exception "Cannot deref non-reference '$value'"
		unless ref $value;

	### Return values if the reference is one we understand
	return @$value		if ref $value eq 'ARRAY';
	return keys %$value		if ref $value eq 'HASH';
	return $$value		if ref $value eq 'SCALAR';

	# Return an exception if it's a CODE or a GLOB or something
	return new Text::Templar::Exception "Cannot deref a '", ref $value, "' reference (yet).";
}


### (PROTECTED) METHOD: _traverseMethodChain( $object, \@methodChain=Text::Templar::method )
### Traverse each element in a methodchain, calling a method or fetching a value
### from a reference for each one.
sub _traverseMethodChain {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $object = shift		or throw Text::Templar::Exception::ParamError 1, "object";
	my $methodchain = shift or throw Text::Templar::Exception::ParamError 2, "methodchain";

	my (
		@results,				# The results of traversing the methodchain
		$lastValue,				# The result of the last "method call", which
		# serves as the next thing to use as the
		# receiver of the next method in the chain
		$chainProgress,			# Diagnostic to keep track of what methods we've
		# called already
		$action,				# Diagnostic for building a description of the
		# current "call"
		$call,					# The "call" code fragment that's currently up
		# for evaluation
		$code,					# The assembled code to be evaled
	   );

	# Initialize variables
	@results = ();
	$lastValue = $object;
	$chainProgress = ref $object ? "$object" : "'$object'";

	### Iterate over each method in the methodchain, building each one
  METHOD: foreach my $method ( @$methodchain ) {

		### If it's a hash, use the hash chain
		if ( ref $lastValue eq 'HASH' ) {
			$action = "fetching value";
			$call = $method->buildHash;
		}

		### If it's an array, or the next link in the chain looks like a
		### arrayindex, use the array chain
		elsif ( ref $lastValue eq 'ARRAY' || $method->name =~ m{^\d+$} ) {
			unless ( $method->name =~ m{^\d+$} ) {
				my $errmsg = sprintf( q{Error in methodchain: %s: Can't use '%s' as an array index},
									  $chainProgress, $method->name );
				throw Text::Templar::Exception::EvalError $errmsg;
			}

			$lastValue = [ @results ] unless ref $lastValue eq 'ARRAY';
			$action = "fetching index";
			$call = $method->buildArray;
		}

		### Handle case of illegal method names so we get a sensible error message.
		elsif ( $method->name !~ m{^[a-zA-Z_]} ) {
			my $errmsg = sprintf( q{Error in methodchain: %s: Can't use '%s' as a method name},
								  $chainProgress, $method->name );
			throw Text::Templar::Exception::EvalError $errmsg;
		}

		### Consider anything else an object. It could be a scalar, but then we
		### can't really tell a simple scalar from a package name, so we just
		### let Perl generate an appropriate error message when we call the
		### method on it if it's not something a method can be called on.
		else {
			$action = "calling";
			$call = $method->build;
		}

		### Evaluate the call
		$code = '$lastValue' . $call;
		@results = eval $code;

		if ( $@ ) {
			my $errmsg = sprintf( 'Error in methodchain: %s %s on %s: %s',
								  $action,
								  $call,
								  $chainProgress,
								  $@ );

			throw Text::Templar::Exception::EvalError $errmsg;
		}

		# Add the last call onto the chain progress string
		$chainProgress .= $call;

	} continue {
		$lastValue = $results[ -1 ];
	}

		return @results;
}


### (PROTECTED) METHOD: _getEvaluatedValue( $code )
### Evaluates the specified code inside a private environment and returns the
### result. Throws an exception if the code to be evaluated produces an
### error, and on any other error.
sub _getEvaluatedValue {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $code = shift;
	return $code unless $code;
	my @args = @_;

	my $func = $self->_buildClosure( $code );

	# Render the result
	return $func unless ref $func eq 'CODE';
	return $func->( @_ );
}


### (PROTECTED) METHOD: _buildClosure( $code )
### Builds a returns a closure with the code specified.
sub _buildClosure {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $code = shift	or throw Text::Templar::Exception::ParamError 1, "code";

	my (
		$evalheader,
		$func,
		%defines,
		@header,
		$line,
	   );

	### Build the code header (variable declarations, package statement, etc.)
	@header = ();
	push @header, qq{package __template_}, $self->__closureCount, qq{;\n};
	$self->__closureCount( $self->__closureCount + 1 );

	### Set up a variable for each of our defines
	%defines = %{$self->defines};
	for my $varname ( keys %defines ) {
		if ( $varname =~ m{^[\$\%\@]} ) {
			if ( ref $defines{$varname} ) {
				$line = sprintf( "my %s;\n",
								 Data::Dumper->Dumpxs([$defines{$varname}],
													  [$varname]) );
			} else {
				$line = sprintf( "my %s = %s;\n",
								 $varname,
								 $defines{$varname} );
			}
		} else {
			if ( ref $defines{$varname} ) {
				$line = sprintf( "my %s;\n",
								 Data::Dumper->Dumpxs([$defines{$varname}],
													  [$varname]) );
			} else {
				$line = sprintf( "my (\$%s) = %s;\n",
								 $varname,
								 defined $defines{$varname}
									 ? $defines{$varname}
										 : 'undef' );
			}
		}
		push @header, $line;
	}

	### Add some variables
	push @header, sprintf( "my \$TEMPLATE_PATH = '%s';\n",
						   ( $self->sourceName ? $self->sourceName : '(anonymous)' ) );
	push @header, "my \$TEMPLATE_OBJECT = \$self;\n";
	push @header, "my \$TEMPLAR_VERSION = '$VERSION';\n";
	push @header, "my \$TEMPLAR_RCSID = '$RCSID';\n";
	push @header, "my \$TEMPLATE_CONTENT = \$self->{content};\n";
	push @header, "my \$TEMPLATE_INHERITEDCONTENT = \$self->{inheritedContent};\n";
	$evalheader = join "", @header;

	### Eval the code after turning on pedantic checks (-w)
	local $^W = 1;
	$code = qq{
	sub {
		no strict;
		no warnings;
		$evalheader
		$code
	}
	};

	# For debugging closures:
	#print STDERR "Built closure: \n", '-' x 72, "\n$code\n", '-' x 72, "\n\n";

	# Now evaluate the function code to get the closure
	$func = eval $code;

	# If there was an error while evaluting, generate an exception
	throw Text::Templar::Exception::EvalError $code, $@ if $@;

	return $func;
}

### (PROTECTED) METHOD: _getRenderedEvaluatedValue( $code )
### Evaluates the specified code inside a private environment, renders it, and
### returns the result. Handles exceptions generated by the specified code
### by rendering them according to the errorOutput configuration. Throws an
### exception on any error.
sub _getRenderedEvaluatedValue {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $code = shift	or throw Text::Templar::Exception::ParamError 1, "code";
	my @args = @_;

	### Wrap the call to evaluate the code in a try block, using the exception
	### as the result if one is generated
	my @results = try {
		$self->_getEvaluatedValue( $code, @args );
	} catch Text::Templar::Exception with {
		my $exception = shift;
		return ( $exception );
	};

	# Render the result and return the rendered value
	return $self->_getRenderedValues( @results );
}


### (PROTECTED) METHOD: _handleException( $exception=Text::Templar::Exception, $mode )
### Take action on an exception that occurs in a template. The action taken is
### configured via the errorOutput() configuration method. Returns a handled
### version of the exception (either the exception object or the empty list
### if the exception object should be ignored at the current point of
### execution).
sub _handleException {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $exception = shift	or throw Text::Templar::Exception::ParamError 1, "exception object";
	my $mode = shift		or throw Text::Templar::Exception::ParamError 2, "mode";

	my $output = lc $self->errorOutput;

	return () if $output eq 'ignore';

	if ( $output eq 'inline' ) {
		# Add the error to the list of tailed errors? Perhaps this was meant to
		# add them in case the setting changed after handling?
		#$self->_pushTailedErrors( $exception->stringify );
		return ( $exception );
	} elsif ( $output eq 'tailed' ) {
		$self->_pushTailedErrors( $exception->stringify );
		return ();
	} elsif ( $output eq 'both' ) {
		$self->_pushTailedErrors( $exception->stringify );
		return ( $exception );
	} else {
		my $ofh = $self->_errorOutputFh
			or throw Text::Templar::Exception::TemplateError
				"Couldn't get '$output' output filehandle for '$mode' mode.";
		$ofh->print( "Exception while in $mode mode: ", $exception->stringify );
		return ();
	}
}


### (PROTECTED) METHOD: _getStderrHandle( undef )
### Opens and returns an IO object opened write-only on STDERR.
sub _getStderrHandle {
	my $self = shift or throw Text::Templar::Exception::MethodError;

	my $fh = IO::Handle->new_from_fd(fileno( STDERR ), "w")
		or throw Text::Templar::Exception::IOError "Failed dup on STDERR: $!";

	return $fh;
}


### (PROTECTED) METHOD: _getFileHandle( $filename )
### Opens and returns an IO object opened to the file specified.
sub _getFileHandle {
	my $self = shift		or throw Text::Templar::Exception::MethodError;
	my $filename = shift	or throw Text::Templar::Exception::ParamError 1, "filename";

	my $fh = new IO::File ">>$filename"
		or throw Text::Templar::Exception::IOError::File "append: $filename: $!";

	return $fh;
}


### (PROTECTED) METHOD: _buildComment( $message )
### Builds and returns a comment in the manner defined by the object's
### commentOpen and commentClose attributes. Throws an exception on any
### error.
sub _buildComment {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my $message = shift or throw Text::Templar::Exception::ParamError 1, "message";

	# Remove double-hypens so they don't muck with HTML comments. This really
	# should be a feature of the comment-building mechanism, but that'll take a
	# fairly heavy-handed reworking of the comment code.
	$message =~ s{--}{-}g;

	return sprintf( '%s %s %s',
					$self->commentOpen,
					$message,
					$self->commentClose );
}


### (PROTECTED) METHOD: _getRenderedValues( @values )
### Render each value into a suitable string for output. Handles simple scalar
### values, array references, hash references, templar objects, exceptions,
### and other objects of a class that defines a C<stringify()>,
### C<as_string>, C<asString>, or C<render> method. Returns an array of
### rendered values if called in list context, or the rendered values joined
### together in a a single string if called in scalar context. Throws an
### exception on any error.
sub _getRenderedValues {
	my $self = shift	or throw Text::Templar::Exception::MethodError;
	my @args = @_ or return ();

	my @renderedValues = ();
	foreach my $value ( @args ) {

		### Undefined values
		push( @renderedValues, $self->undefinedValue ), next unless defined $value;

		### Simple scalars
		push( @renderedValues, $value ), next if not ref $value;

		### Array references
		push( @renderedValues, join(', ', $self->_getRenderedValues( @$value )) ), next
			if ref $value eq 'ARRAY';

		### Templar objects
		if ( blessed $value && $value->isa('Text::Templar') ) {
			$value->propagateContent( $self->getContentHash );
			push( @renderedValues, $value->render );
			next;
		}

		### Hash references
		elsif ( ref $value eq 'HASH' ) {

			### Render each pair as a string like <key> => <value>, with the
			### <value> part being rendered as well
			my @renderedPairs = map {
				sprintf( "%s => '%s', ",
						 $_,
						 $self->_getRenderedValues($value->{$_}) )
			} keys %$value;

			push @renderedValues, @renderedPairs;
		}

		### Exceptions
		elsif ( blessed $value && $value->isa('Text::Templar::Exception') ) {

			### Check to see how we're handling exceptions. If we're inlining
			### them, build a comment out of the exception's message
			push @renderedValues, $self->_buildComment( $value->message )
				if $self->errorOutput eq 'inline';

		}

		### Other blessed references
		elsif ( blessed $value ) {

			### Try to look up a method to stringify the object.
			my $method =
				$value->can( 'stringify' )
					|| $value->can( 'as_string' )
						|| $value->can( 'asString' )
							|| $value->can( 'render' );

			### Call the method if we found one
			if ( defined $method ) {
				push @renderedValues, $self->_getRenderedValues( $method->($value) );
			} else {
				push @renderedValues, sprintf( '[ %s object ]', blessed $value );
			}
		}

		### Any other kind of thing
		else {
			push @renderedValues, sprintf( 'A %s reference', ref $value );
		}
	}

	return wantarray ? @renderedValues : join '', @renderedValues;
}


### (PRIVATE STATIC) METHOD: __InitErrorOutput( undef )
### Nasty kluge to assure that error output is initialized in the case that it's
### not explicitly configured either before or during the first constructor
### call.
sub __InitErrorOutput {
	my $class = shift	or throw Text::Templar::Exception::MethodError;
	return 1 if $class->__ErroutIsInitialized;

	my $ofh = $class->_getStderrHandle;
	$class->_errorOutputFh( $ofh );
	$class->__ErroutIsInitialized( 1 );

	return 1;
}


###############################################################################
### P R I V A T E / P R O T E C T E D	F U N C T I O N S
###############################################################################


### (PROTECTED) FUNCTION: _buildParseError( \@errors )
### Given an array of parser errors, return a formatted error message composed
### of all of them.
sub _buildParseError {
	my $errorArray = shift or throw Text::Templar::Exception::ParamError 1, "errorArray";
	throw Text::Templar::Exception::ParamError 1, "errorArray"
		unless ref $errorArray eq 'ARRAY';

	my @messages = ();
	my $line;

	foreach my $error ( reverse @$errorArray ) {
		push @messages, $error->[0];
		$line = $error->[1];
	}


	$messages[ $#messages ] .= " at line $line.";
	return join ': ', @messages;
}



### Global package destructor
END		{}
DESTROY		{}



###############################################################################
### T R I V I A L	N O D E	  C L A S S E S
###############################################################################

### Turn off redefined warnings for the node classes, as under mod_perl they all
### warn. I still don't know why, as they're in completely different packages,
### right?
#no warnings 'redefine';

### These classes are used by the parser to construct a node-tree representation
### of the parsed template content. Each node is represented by an object, all
### of which inherit from Text::Templar::node.

### Regular (unitag) node base class
{
	package Text::Templar::node;
	use vars qw{$AUTOLOAD};

	sub new {bless {}, shift}
	sub AUTOLOAD {
		my $self = shift or return undef;
		( my $method = $AUTOLOAD ) =~ s{.*::}{};

		if ( @_ ) {
			eval { $self->{$method} = shift };
			throw Text::Templar::Exception "Proxy method 'set' failed for $AUTOLOAD: $@"
				if $@;
		}

		my $rval = eval { $self->{$method} };
		throw Text::Templar::Exception "Proxy method 'get' failed for $AUTOLOAD: $@"
			if $@;
		return $rval;
	}
	sub type {
		my $self = shift or return undef;
		( my $type = ref $self ) =~ s{.*::}{};

		return $type;
	}
	sub needsChomp {return 0}

	DESTROY {}
		END {}
}

### Chomped node class (nodes which shouldn't leave blank lines in the output when
### they are followed directly by a newline
{
	package Text::Templar::chompednode;
	our @ISA = qw{Text::Templar::node};

	sub needsChomp { return 1 }
}


### Container node base class
{
	package Text::Templar::containernode;
	our @ISA = qw{Text::Templar::chompednode};
	use vars qw{$AUTOLOAD};

	sub new {bless [{},[]], shift}
	sub AUTOLOAD {
		my $self = shift or return undef;
		( my $method = $AUTOLOAD ) =~ s{.*::}{};

		if ( @_ ) {
			$self->[0]{$method} = shift;
		}

		return $self->[0]{$method};
	}
	sub subnodes {
		my $self = shift or return ();
		if ( @_ ) {
			@$self = ( $self->[0], [ @_ ] );
		}
		return @{$self}[1..$#$self];
	}
	sub deref {
		my $self = shift or return ();
		return 1 if exists $self->[0]{deref}
			&& defined $self->[0]{deref}
				&& ref $self->[0]{deref} eq 'ARRAY'
					&& scalar @{$self->[0]{deref}};
	}

}

### Chomped node class (nodes which shouldn't leave blank lines in the output when
### they are followed directly by a newline
{
	package Text::Templar::conditionalnode;
	our @ISA = qw{Text::Templar::containernode};

}


### Subnode (tag arguments, literals, etc.) base class
{
	package Text::Templar::subnode;
	our @ISA = qw{Text::Templar::node};

	sub content {
		my $self = shift or return undef;
		throw Text::Templar::Exception "Unimplemented content() method in the ", ref $self, " class.";
	}

	sub render {
		my $self = shift or return undef;
		my $needsChomp = shift || 0;
		return $self->content( $needsChomp );
	}

	sub preprocess { return shift }
}

### Matchnode (Matchspec) abstract class
{
	package Text::Templar::matchnode;
	our @ISA = qw{Text::Templar::subnode};

	sub matches {
		my $self = shift or return undef;
		throw Text::Templar::Exception "Unimplemented matches() method in the ", ref $self, " class.";
	}
}

### Directive node child classes
{	package Text::Templar::METHODCALL;	our @ISA = qw{Text::Templar::node}}
{	package Text::Templar::METHOD;	our @ISA = qw{Text::Templar::node}}
{	package Text::Templar::DUMP;	our @ISA = qw{Text::Templar::node}}
{	package Text::Templar::DEFINE;	our @ISA = qw{Text::Templar::chompednode}}
{	package Text::Templar::STOP;	our @ISA = qw{Text::Templar::chompednode}}
{	package Text::Templar::EVAL;	our @ISA = qw{Text::Templar::node}}
{	package Text::Templar::INCLUDE; our @ISA = qw{Text::Templar::chompednode}}
{	package Text::Templar::QUERY;	our @ISA = qw{Text::Templar::node}}
{	package Text::Templar::ENV;		our @ISA = qw{Text::Templar::node}}
{	package Text::Templar::META;	our @ISA = qw{Text::Templar::chompednode}}
{	package Text::Templar::INHERIT; our @ISA = qw{Text::Templar::chompednode}}
{	package Text::Templar::CUT;		our @ISA = qw{Text::Templar::chompednode}}

### Container node child classes
{	package Text::Templar::FOREACH; our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::GREP;	our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::MAP;		our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::SORT;	our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::JOIN;	our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::COMMENT; our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::TRIM;	our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::MAXLENGTH;	our @ISA = qw{Text::Templar::containernode}}
{	package Text::Templar::DELAYED; our @ISA = qw{Text::Templar::containernode}}

### Conditional and sub-conditional child classes
{	package Text::Templar::IF;		our @ISA = qw{Text::Templar::conditionalnode}}
{	package Text::Templar::ELSE;	our @ISA = qw{Text::Templar::conditionalnode}}
{	package Text::Templar::ELSIF;	our @ISA = qw{Text::Templar::conditionalnode}}


### Subnode child classes

# Literal content
{
	package Text::Templar::literal;
	our @ISA = qw{Text::Templar::subnode};
	sub content {
		my $self = shift or return undef;
		my $needsChomp = shift || 0;

		my $rval = $$self;
		#$rval =~ s{^\n}{} if $needsChomp; # <- This leads to double-chomping?
		return $rval;
	}
	sub preprocess {
		my $self = shift or return undef;
		my $needsChomp = shift || 0;

		$$self =~ s{^\n}{} if $needsChomp;
		return $self;
	}
}

# Code block
{
	package Text::Templar::codeblock;
	our @ISA = qw{Text::Templar::subnode};
	sub execute {
		my $self = shift or return undef;
		my @args = @_;

		unless ( defined $self->{func} && ref $self->{func} eq 'CODE' ) {
			my $code = "sub { $self->{code} }";
			$self->{func} = eval $code;
			throw Text::Templar::Exception::EvalError $code, $@
				if $@;
		}

		return $self->{func}( @args );
	}
	sub content {
		my $self = shift or return '';
		(my $munged = $self->{code} ) =~ s{^{(.*)}$}{$1}g;
		return $munged;
	}
}

# Hash-pair sort code block
{
	package Text::Templar::hashpairsort;
	our @ISA = qw{Text::Templar::codeblock};
}


# Array argument
{
	package Text::Templar::array;
	our @ISA = qw{Text::Templar::matchnode};

	sub content {
		my $self = shift or return undef;
		return @$self;
	}

	sub matches {
		my $self = shift or return undef;
		my @args = @_ or return undef;

		foreach my $arg ( @args ) {
			my @content = $self->content;
			return () unless grep { $_ eq $arg } @content;
		}

		return @args;
	}
}

# Hash argument
{
	package Text::Templar::hash;
	our @ISA = qw{Text::Templar::matchnode};

	sub content {
		my $self = shift or return undef;
		return %$self;
	}

	sub matches {
		my $self = shift or return undef;
		my @args = @_ or return undef;
		my @rvals = ();

		foreach my $arg ( @args ) {
			push @rvals, $self->{$arg}
				if exists $self->{$arg};
		}

		return @rvals;
	}
}

# Regexp argument
{
	package Text::Templar::regexp;
	our @ISA = qw{Text::Templar::matchnode};

	sub content { return shift() }

	sub matches {
		my $self = shift or return undef;
		my @args = @_ or return undef;

		return grep { $_ =~ $self } @args;
	}
}

# Method call
{
	package Text::Templar::method;
	our @ISA = qw{Text::Templar::subnode};

	sub build {
		my $self = shift;
		return sprintf( '->%s(%s)',
						$self->name,
						defined $self->arglist
							? join(q{, }, @{$self->arglist})
							: '' );
	}

	sub buildHash {
		my $self = shift;
		return sprintf( '->{%s}', $self->name );
	}

	sub buildArray {
		my $self = shift;
		return sprintf( '->[%s]', $self->name );
	}
}

### Return success when loading
1;
### AUTOGENERATED DOCUMENTATION FOLLOWS
