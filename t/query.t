#!/usr/bin/perl -w
use strict;

BEGIN {
    select(STDERR); $| = 1;	# make unbuffered
    select(STDOUT); $| = 1;	# make unbuffered
	use Text::Templar	qw{};
	use Text::Templar::Exceptions		qw{:syntax};
}

#$Text::Templar::Debug = Text::Templar::DEBUG_ALL;

my $t = new Text::Templar 
	includePath => [ './t/templates' ]
	or print( "1..0\n" ), exit 0;

my $numTests = 8;
my $numTest = 0;

print "1..$numTests\n";

###	1: Load template
Test(
	 try {
		 $t->load("querytest.tmpl")
	 } catch Text::Templar::Exception with {
		 my $e = shift;
		 print STDERR $e->stringify;
		 return undef;
	 }
);

my @queries = $t->queries;

### 2: Query 1
Test( $queries[0]->name eq 'knightName'
	  && $queries[0]->question eq 'What is your name?'
	  && $queries[0]->matchspec->matches( 'Arthur' )
	);

### 3: Query 2
Test( $queries[1]->name eq 'knightQuest'
	  && $queries[1]->question eq 'What is your quest?'
	  && $queries[1]->matchspec->matches( 'I seek the holy grail.' )
	);

### 4: Query 3
Test( $queries[2]->name eq 'knightSillyQuestion'
	  && $queries[2]->question eq 'What is the air-speed velocity of an unladen swallow?'
	  && $queries[2]->matchspec->matches( 'African' )
	);


### 5: Query 1 answer method
Test( $t->knightName('Arthur')	);

### 6: Query 2 answer method
Test( $t->knightQuest('I seek the holy grail.') );

### 7: Query 3 answer method
Test( $t->knightSillyQuestion('African') );

#print STDERR $t->render;

### 8: Render
Test( $t->render eq renderResults() );



sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}

sub renderResults {
	return <<"EOF";
Arthur

I seek the holy grail.

African

EOF
}
