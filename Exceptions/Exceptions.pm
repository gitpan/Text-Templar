#!/usr/bin/perl
################################################################################

=head1 NAME

Text::Templar::Exceptions - runtime exception classes for Text::Templar

=head1 SYNOPSIS

  use Text::Templar::Exceptions qw{:syntax};

  my $result = try {
    $t = Text::Templar->new( "main.tmpl" );
  } catch Text::Templar::Exception with {
    my $e = shift;
    print STDERR "Failed to load template 'main.tmpl': $e";
  };

=head1 EXPORTS

Nothing by default.

If used with the :syntax tag, the functions C<try()>, C<with()>, C<finally()>,
C<except()>, and C<otherwise()> will be imported into your package. See
B<PROCEDURAL INTERFACE> for more about what they do and how to use them.

=head1 REQUIRES

Perl 5.6, L<Carp>, L<Exporter>

=head1 DESCRIPTION

This module provides runtime exception classes for Text::Templar, and also
provides methods and syntax for handling them which can be imported in your own
classes.

This code is mostly a hacked-up version of the Error.pm module by Graham Barr
E<lt>gbarr@ti.comE<gt>. Sections which have been copied from or are modified
versions of synonymous sections of that module are annotated accordingly.

=head1 RCSID

$Id: Exceptions.pm,v 1.3 2001/09/24 23:12:12 deveiant Exp $

=head1 AUTHOR

Michael Granger E<lt>ged@FaerieMUD.orgE<gt>

Copyright (c) 1999-2001 The FaerieMUD Consortium. All rights reserved.

This module is free software. You may use, modify, and/or
redistribute this software under the terms of the Perl Artistic
License. (See http://language.perl.com/misc/Artistic.html)

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

Portions of this file are also borrowed from Error.pm, which has the following
copyright information:

	Copyright (c) 1997-8 Graham Barr <gbarr@ti.com>. All rights reserved.  This
	program is free software; you can redistribute it and/or modify it under the
	same terms as Perl itself.

=head1 SEE ALSO

Error.pm by Graham Barr

=cut

################################################################################
package Text::Templar::Exceptions;
use strict;

BEGIN {
	require 5.6.0;
	use base qw{Exporter};
}

### Delegate all exported stuff to the real base exception class
sub import {
	my @args = @_;
	return Text::Templar::Exception->export_to_level( 1, @args );
}


###############################################################################
###	B A S E   E X C E P T I O N   C L A S S
###############################################################################
package Text::Templar::Exception;
use strict;

BEGIN {
	require 5.6.0;

	### Package constants
	use vars		qw{$VERSION $RCSID @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD};
	$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
	$RCSID			= q$Id: Exceptions.pm,v 1.3 2001/09/24 23:12:12 deveiant Exp $;

	### Superclass
	use base		qw{Exporter};

	### Exporter stuff
	@EXPORT			= qw{};
	@EXPORT_OK		= qw{try with finally except otherwise};
	%EXPORT_TAGS	= ( 'syntax'	=> \@EXPORT_OK );

	### Required modules
	use Carp		qw{carp croak confess};

	###	Overload some operations
	use overload (
		'""'		=> 'stringify',
		'@{}'		=> sub { return shift()->{stacktrace} },
		'fallback'	=> 1,
	);

}

###############################################################################
###	C L A S S   V A R I A B L E S
###############################################################################
our ( $Depth, $ErrorType, $Debug );

$ErrorType	= "System";
$Depth		= 1;
$Debug		= 0;


###############################################################################
###	P U B L I C   M E T H O D S
###############################################################################

### (CONSTRUCTOR) METHOD: new( [@errorMessage] )
### Returns a new Text::Templar::Exception object with the error message
###		specified, or 'Unspecified error' if none is specified.
sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $message = ( @_ ? join '', @_ : "Unspecified error" );

	my (
		@stacktrace,
		@calleritems,
		$frame,
		$package,
		$filename,
		$line,
		$context,
		$errtype,
	   );

	print STDERR "Creating an exception of type '$class' with message '$message'.\n" if $Debug;

	### Get the name of the error being thrown from the calling class
  NO_STRICT_REFS: {
		no strict 'refs';
		$errtype = ${"${class}::ErrorType"} || $ErrorType;
	}

	### Build a stacktrace back to the first driver call for this error
	$frame = 0 + $Depth;
  FRAME: while ( @calleritems = caller($frame++) ) {

		### Define the exception's variables if the sub is our constructor or
		###		one of the syntax methods
		if ( not defined $package ) {
			( $package, $filename, $line, undef, undef, $context ) = @calleritems;
			next FRAME;
		}

		### :FIXME: Should we trim frames off the stacktrace if they are frames
		### inside the Exception class or one of its children?
		#last FRAME if $calleritems[3] =~ m{^Text::Templar::Exception::};

		push @stacktrace, {
			'package'		=> $calleritems[0],
			'filename'		=> $calleritems[1],
			'line'			=> $calleritems[2],
			'subroutine'	=> $calleritems[3],
			'hasargs'		=> $calleritems[4],
			'wantarray'		=> $calleritems[5],
			'evaltext'		=> $calleritems[6],
			'is_require'	=> $calleritems[7],
		};
	}

	return bless {
	  	'message'			=> $message,
	  	'type'				=> $errtype,
	  	'stacktrace'		=> \@stacktrace,
	  	'timestamp'			=> time(),
		'package'			=> $package,
		'filename'			=> $filename,
		'line'				=> $line,
		'context'			=> $context,
	}, $class;
}


### METHOD: throw( $errmsg )
### Create a new C<Exception> object with I<errmsg> and C<die> with it. This
###		will be caught by any enclosing C<try()> blocks. If not enclosed by a
###		C<try()>, calling this method will cause a fatal exception.
### This method is a modified version of the synonymous one in Error.pm.
sub throw {
	my $self = shift;

	print STDERR "Throwing a '", ref $self || $self, "' thingie.\n" if $Debug;

	# if we are not rethrow-ing then create the object to throw
	local $Depth = $Depth + 1;
	$self = $self->new(@_) unless ref $self;

	### Throw ourself as the exception
	print STDERR "Dying with exception '$self'.\n" if $Debug;
	CORE::die $self;
}


### (AUTOLOADED) METHOD: message()
### Get/set the error message.

### (AUTOLOADED) METHOD: type()
### Get/set the error type.
sub AUTOLOAD {
	my $self = shift;
	my $type = ref( $self ) || croak "AUTOLOAD: Cannot call proxy method in non-object '$self'.";

	( my $name = $AUTOLOAD ) =~ s{^.*::}{};

	### If we have an attribute with the same name as the method called, act as
	### an accessor
	if ( exists $self->{$name} ) {
		$self->{ $name } = shift if @_;
		return $self->{ $name };
	}

	### If there's not like-named attribute, try to call the method in our
	### superclass
	else {
		my $method = "SUPER::${name}";
		return $self->$method( @_ );
	}
}


### METHOD: stackframe( $frameNumber )
### Returns the stack frame from frameNumber levels deep in the call stack. The
###		frame is a hash (or hashref if called in scalar context) of the form:
###
###	    'package'       => The caller's package
###	    'filename'      => The filename of the code being executed
###	    'line'          => The line number being executed
###	    'subroutine'    => The name of the function or method being executed
###	    'hasargs'       => True if the sub was passed arguments from its caller
###	    'wantarray'     => True if the sub was called in a list context
###	    'evaltext'      => If 'subroutine' is '(eval)', this is the EXPR
###	                        of the eval block
###	    'is_require'    => True if the frame was created from a 'require' or 'use'
sub stackframe {
	my $self = shift;
	my $frame = shift || 0;

	return undef unless $#{$self->{'stacktrace'}} >= $frame;
	return wantarray
		? %{ $self->{'stacktrace'}[$frame] }
		: $self->{'stacktrace'}[$frame];
}


### METHOD: stacktrace()
### Returns an array of stack frames of the format returned by C<stackframe()>
###		that describe the stack trace at the moment the exception was thrown.
sub stacktrace {
	my $self = shift;
	return @{$self->{'stacktrace'}};
}


### METHOD: as_string( undef )
### A wrapper for stringify()
sub as_string { stringify(@_) }


###	METHOD: stringify()
###	Returns the stacktrace and error message or the exception as a human-readable string.
sub stringify {
	my $self = shift;
	my $rval;

	$rval = sprintf( "A %s error '%s' occurred\n\tin %s (%s) line %d\n\t(%s).\n",
					 $self->type(),
					 $self->message(),
					 $self->package(),
					 $self->filename(),
					 $self->line(),
					 scalar localtime($self->timestamp()) );
	$rval .= "-" x 80 . "\n";

	for my $traceref ( @{$self->{'stacktrace'}} ) {
		$rval .= sprintf( "%s (%s)\n\tline %s called %s.\n",
						  $$traceref{'package'},
						  $$traceref{'filename'},
						  $$traceref{'line'},
						  $$traceref{'subroutine'} );
	}

	return $rval;
}


###############################################################################
###	S Y N T A X   F U N C T I O N S
###############################################################################

### Note: Most of this code is from Error.pm by Graham Barr <gbarr@ti.com>, with
###		a few aesthetic and functional modifications for the FaerieMUD system by
###		Michael Granger <ged@FaerieMUD.org>. All comments are also mine, so
###		blame me for any mistakes =:)

### FUNCTION: try( \&codeblock, \%handlerClauses )
### The I<codeblock> will be evaluated and if no error condition arises, this
###		function returns the result. I<handlerClauses> is a hash of code
###		references that describe what actions to take if a error occurs. It is
###		typically built by appending one or more X<catch>, X<otherwise>, or
###		X<finally> clauses.
sub try (&;$) {
	my $try			= shift;				# The try block as a CODE ref
	my $clauses		= @_ ? shift : {};		# The handler clauses

	my (
		$ok,
		$error,
		@results,
		$wantarray,
		$handlerCode,
	   );

	$wantarray = wantarray;

	###	Execute the try block
	do {
		no warnings;

		### Localize the depth counter and temporarily unset the die handler
		local $Depth = 1;
		local $SIG{__DIE__} = undef;

		###	Wrap a call to the try block in an eval
		$ok = eval {
			if ( $wantarray ) {
				@results = $try->();
			} else {
				$results[0] = $try->();
			}
			1;	# Indicate success
		};

		# Set the error message and set ok to false if there's an eval error
		$error = $@, $ok = undef if $@;
	};

	### If the try block didn't return an ok status, handle the error
	if ( $error ) {

		###	If the error was just a $@, wrap it in a Exception
		$error = __PACKAGE__->new( "Untrapped exception in try block: $error" ) unless ref $error;

		CATCH: {
			my (
				$catchClauses,			# Catch clauses (coderefs)
				$owise,			# Otherwise clause (coderef)
				$i,				# Iterator
				$pkg,			# The package to match for catch clauses
				$keepTrying,	# The 'keep trying' flag passed (by reference) to each catch block
				$ok,			# Eval result
			);

			# Do the catch clauses (if any are defined)
			if (defined( $catchClauses = $clauses->{'catch'} )) {

				# Iterate over each catch clause package + coderef
				CATCHLOOP: for( $i = 0; $i < @$catchClauses; $i += 2) {

					###	Get the name of the package we're looking for
					$pkg = $catchClauses->[$i];

					###	If there wasn't a package name, then it must be an except block,
					###	 so splice the hash returned by it into the catch handlers and
					###	 decrement the counter to point to the first new handler
					unless (defined $pkg) {

						splice( @$catchClauses, $i, 2, $catchClauses->[$i+1]->() );
						$i -= 2;
						redo CATCH;
					}

					###	Otherwise, check to see if the error's one of the ones we should catch
					elsif ( $error->isa($pkg) ) {

						###	Get the coderef to the handler
						$handlerCode = $catchClauses->[$i+1];
						$keepTrying = 0;

						###	Wrap the catch handler in an eval
						$ok = eval {
							if ( $wantarray ) {
								@results = $handlerCode->( $error, \$keepTrying );
							} elsif ( defined($wantarray) ) {
								$results[0] = $handlerCode->( $error, \$keepTrying );
							} else {
								$handlerCode->( $error, \$keepTrying );
							}
							1;	# Indicate success
						};

						### If the handler executed successfully, either keep
						###	 trying (if the handler said to do so), or consider
						###	 it handled and quit doing catches
						if ( $ok ) {
							next CATCHLOOP if $keepTrying;
							undef $error;
						} elsif ( $@ ) {
							$error = $@;
							$error = __PACKAGE__->new( "Exception in catch block: $error" ) unless ref $error;
						} else {
							$error = __PACKAGE__->new( "Mysterious error in catch block." );
						}
						last CATCH;
					}
				}
			}

			# Otherwise clause
			if (defined( $owise = $clauses->{'otherwise'} )) {

				###	Wrap the otherwise handler in an eval
				my $ok = eval {
					if ( $wantarray ) {
						@results = $owise->( $error );
					} elsif (defined( $wantarray )) {
						$results[0] = $owise->( $error );
					} else {
						$owise->( $error );
					}
					1;	# Indicate success
				};

				if ( $ok ) {
					undef $error;
				} elsif ( $@ ) {
					$error = $@;
					$error = __PACKAGE__->new( "Exception in otherwise block: $error" ) unless ref $error;
				} else {
					$error = __PACKAGE__->new( "Mysterious error in otherwise block." );
				}
			}
		}
	}

	###	Finally clause
	$clauses->{finally}->() if exists $clauses->{finally} && defined $clauses->{finally};

	###	Propagate the error if it's still defined
	$error->throw if defined $error;

	###	Return the results
	return $wantarray ? @results : $results[0];
}


### METHOD: catch( $packageName, \&handlerCode[, \%clauses] )
### Adds a catch clause with the specified handler code for the specified
###		package onto the array of 'catch' clauses in the clauses given. If the
###		clauses hashref is omitted, one is created. Returns the new or given
###		clauses hashref with the new catch clause added.
sub catch {
	my $pkg		= shift;
	my $code	= shift;
	my $clauses	= shift || {};

	$clauses->{catch} ||= [];

	unshift @{$clauses->{catch}}, $pkg, $code;
	return $clauses;
}


sub with (&;$) {
	return @_;		# Does nothing except pass the clauses hash on
}

sub finally (&) {
	my $code = shift;
	my $clauses = { 'finally' => $code };
	return $clauses;
}

###	The except clause is a block which returns a hashref or a list of
###		key-value pairs, where the keys are the classes and the values are subs.
sub except (&;$) {
	my $code	= shift;
	my $clauses	= shift || {};

	$clauses->{catch} ||= [];

	###	Build the coderef that'll return the hash of handlers
	my $handler = sub {
		my $arg = shift;

		my $handlers;
		my ( @array ) = $code->( $arg );

		if ( @array == 1 && ref $array[0] ) {
			$handlers = $array[0];
			$handlers = [ %$handlers ] if ref $handlers eq 'HASH';
		} else {
			$handlers = \@array;
		}

		return @$handlers;
	};

	###	Stick the handler onto the front of the listref with an undef as the package
	###		to alert the try function that this is an except block
	unshift @{$clauses->{catch}}, undef, $code;

	###	Pass the clauses on
	return $clauses;
}

sub otherwise (&;$) {
	my $code = shift;
	my $clauses = shift || {};

	croak "Multiple otherwise clauses" if exists $clauses->{'otherwise'};
	$clauses->{otherwise} = $code;

	return $clauses;
}

END			{}
DESTROY		{}


###############################################################################
###	D E R I V E D   E X C E P T I O N   C L A S S E S
###############################################################################

### MethodError
package Text::Templar::Exception::MethodError;
use strict;
use base 'Text::Templar::Exception';
our $ErrorType = 'method invocation';

### FileIOError
package Text::Templar::Exception::FileIOError;
use strict;
use base 'Text::Templar::Exception';
our $ErrorType = 'file I/O';

### EvalError
package Text::Templar::Exception::EvalError;
use strict;
use base 'Text::Templar::Exception';
our $ErrorType = 'evaluation';

### RecursionError
package Text::Templar::Exception::RecursionError;
use strict;
use base 'Text::Templar::Exception';
our $ErrorType = 'recursion';

### TemplateError
package Text::Templar::Exception::TemplateError;
use strict;
use base 'Text::Templar::Exception';
our $ErrorType = 'template';

### ParamError
package Text::Templar::Exception::ParamError;
use strict;
use base 'Text::Templar::Exception';
our $ErrorType = 'parameter';

sub new {
	my $proto = shift;

	my (
		$errmsg,				# The error message
	   );

	### Two-arg syntax when the first arg's a number indicates a missing or
	### undefined parameter.
	if ( @_ == 2 && $_[0] =~ m{^[0-9]+$} ) {
		my ( $position, $paramName ) = @_;

		$errmsg = sprintf( 'Missing or undefined argument %s: %s',
						   $position,
						   ucfirst $paramName );
	}

	else {
		$errmsg = @_ ? join( '', @_ ) : 'Illegal parameter';
		$errmsg = ucfirst $errmsg;
	}

	return $proto->SUPER::new( $errmsg );
}


### Module require return value
1;




