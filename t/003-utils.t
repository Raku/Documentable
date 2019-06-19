use v6;

use Perl6::Utils;
use Pod::Load;
use Test;

plan *;

my @pod = load("t/pod-test-utils.pod6")[0];

subtest {
    
    is first-code-block(@pod[0].contents), 
    "    say \"Some code\";\n", "First code block detected";

    my @new-headings = pod-lower-headings(@pod[0].contents);
    my @new-levels = @new-headings.grep( * ~~ Pod::Heading ).map( *.level );
    is-deeply @new-levels, [1,1,2,1,3], "Headings levels lowered";
    is-deeply pod-lower-headings(@pod[0].contents, :to(3)), @pod[0].contents,
    "Does not change if heading cannot be lowered";

}, "Pod utilities";




done-testing;
