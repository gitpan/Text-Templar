#!/usr/bin/perl
use strict;

BEGIN {
	use Text::Templar				qw{};
	use Text::Templar::Exceptions	qw{:syntax};
}

my $numTests = 5;
my $numTest = 0;

print "1..$numTests\n";


my $t1 = new Text::Templar
	'cachetest.tmpl',
	includePath => [ './t/templates' ],
	cacheSource => 1,
	cacheTrees => 1;

### Initial load isn't cached
Test( $t1->sourceName !~ m{cached} );

my $t2 = new Text::Templar
	'cachetest.tmpl',
	includePath => [ './t/templates' ],
	cacheSource => 1,
	cacheTrees => 1;

### Second load caches tree
Test( $t2->sourceName =~ m{cached tree} );

### Kluge to assure that the template mtime is later than the cached source/tree
sleep 1;


utime time, time, './t/templates/cachetest.tmpl'
	or die "Failed to touch './t/templates/cachetest.tmpl': $!";

my $t3 = new Text::Templar
	'cachetest.tmpl',
	includePath => [ './t/templates' ],
	cacheSource => 1,
	cacheTrees => 1;

### Load after change isn't cached
Test( $t3->sourceName !~ m{cached} );

my $t4 = new Text::Templar
	'cachetest.tmpl',
	includePath => [ './t/templates' ],
	cacheSource => 1,
	cacheTrees => 0;

### Trees turned off, uses cached source
Test( $t4->sourceName =~ m{cached source} );


my $t5 = new Text::Templar
	'cachetest.tmpl',
	includePath => [ './t/templates' ],
	cacheSource => 0,
	cacheTrees => 0;

### Caching turned off, isn't cached
Test( $t5->sourceName !~ m{cached} );




sub Test {
    my $result = shift;
    printf("%sok %d\n", ($result ? "" : "not "), ++$numTest);
    $result;
}



