use v6;

use Perl6::Documentable;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Test;

plan *;

my $pod = load("t/pod-test-defs.pod6")[0];

my $doc = Perl6::Documentable.new(:kind("Type"), 
                                  :$pod, 
                                  :name("testing"), 
                                  :url("/Type/test"),
                                  :summary(""),
                                  :pod-is-complete,
                                  :subkinds("Type")
                                );

$doc.find-definitions();

my @names      := ("ACCEPTS", "any", "mro", "root");
my @subkinds   := ("method" , "sub"               );
my @categories := ("method" , "sub"               );

subtest {
  is-deeply @names     , $doc.defs».name.sort, "Names detected";
  is-deeply @subkinds  , $doc.defs».subkinds.tree(*.Slip, *.Slip).unique.sort, 
  "Subkinds detected";
  is-deeply @categories, $doc.defs».categories.tree(*.Slip, *.Slip).unique.sort,
  "Categories detected";
}, "All definitions found";


# In pod-test-defs, all definitions origin must point to the pod source
# except for "method root" that is subparsed and its origin must point
# to "method any"
subtest {
  my @defs = $doc.defs.grep({.name ne "root"});
  for @defs -> $d {
    is-deeply $doc, $d.origin, "Correct origin in $d.name()";
  }

  my $rootmethod = get-def("root");
  my $origin     = get-def("any");
  is-deeply $rootmethod.origin, $origin, "Subparsing origin set";
}, "Subparsing structure";

# Correct scope detection is checked converting the entire pod of the 
# definition to String and compare the result
subtest {
    my @definitions = (
       "ACCEPTS", "  (testing) method ACCEPTS This should be indexed!",
       "any"    , "  (testing) method any This should be indexed and subparsing should be done!     method root Subparsing!",
       "root"   , "  (any) method root Subparsing!",
       "mro"    , "  (testing) routine mro At this point the last subparsing should have stopped. Defined as     multi sub    mro(*@list  --> Seq:D)"
    );
    for @definitions -> $name, $str {
      test-scope($name, $str);
    }

}, "Scope set correctly";

#| returns a specific definition
sub get-def($name) {
  $doc.defs.grep({ .name eq $name }).first;
}

sub test-scope($name, $str) {
  is textify-guts(get-def($name).pod),
     $str,
     "Scope detection in $name";
}

done-testing;