use v6;

use Perl6::Documentable;
use Pod::Load;
use Test;
use Perl6::Utils;
plan *;

my $pod = load("t/Any.pod6")[0];

my $doc = Perl6::Documentable.new(:kind("Type"), 
                                  :$pod, 
                                  :name("pod-test"), 
                                  :url("/Type/test"),
                                  :summary(""),
                                  :pod-is-complete,
                                  :subkinds("Type")
                                );


$doc.find-definitions(:pod($pod), :origin($doc));

# for $doc.defs -> $d {
#   say "----";
#   say $d.categories ~ " " ~ $d.name;
# }

# #TODO: tests for all definitions found
# subtest {

# }, "All definitions found";

# #TODO: tests for a correct subparsing structure
# subtest {

# }, "Subparsing structure"

# #TODO: test scope detection of every definition
# subtest {

# }, "Scope set correctly";

#TODO: new head set
# subtest {

# }, "New headings set";

done-testing;