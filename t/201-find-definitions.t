use v6;

use Perl6::Documentable;
use Perl6::Documentable::Processing;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Test;

plan *;

my $pod = load("t/test-doc/Native/int.pod6")[0];

my $origin = Perl6::Documentable.new(
    :kind("type"), 
    :$pod, 
    :name("int"), 
    :url("/Native/int"),
    :summary("Native"),
    :pod-is-complete,
    :subkinds("class")
);


my @names      := ("ACCEPTS", "any", "mro", "root");
my @subkinds   := ("method" , "sub"               );
my @categories := ("method" , "sub"               );

my @defs;

find-definitions(:$pod, :$origin, :@defs);

subtest {
  is-deeply @names     , @defs».name.sort, "Names detected";
  is-deeply @subkinds  , @defs».subkinds.tree(*.Slip, *.Slip).unique.sort, 
  "Subkinds detected";
  is-deeply @categories, @defs».categories.tree(*.Slip, *.Slip).unique.sort,
  "Categories detected";
}, "All definitions found";


# In Native/int.pod6, all definitions origin must point to the pod source
# except for "method root" that is subparsed and its origin must point
# to "method any"
subtest {
  my @definitions = @defs.grep({.name ne "root"});
  for @definitions -> $d {
    is-deeply $origin, $d.origin, "Correct origin in $d.name()";
  }

  my $root-method = get-def("root");
  my $root-origin     = get-def("any");
  is-deeply $root-method.origin, $root-origin, "Subparsing origin set";
}, "Subparsing structure";

# Correct scope detection is checked converting the entire pod of the 
# definition to String and compare the result
subtest {
    my @definitions = (
       "ACCEPTS", "  (int) method ACCEPTS This should be indexed!",
       "any"    , "  (int) method any This should be indexed and subparsing should be done!     method root Subparsing!",
       "root"   , "  (any) method root Subparsing!",
       "mro"    , "  (int) routine mro At this point the last subparsing should have stopped. Defined as     multi sub    mro(*@list  --> Seq:D)"
    );
    for @definitions -> $name, $str {
      test-scope($name, $str);
    }

}, "Scope set correctly";

#| returns a specific definition
sub get-def($name) {
  @defs.grep({ .name eq $name }).first;
}

sub test-scope($name, $str) {
  is textify-guts(get-def($name).pod),
     $str,
     "Scope detection in $name";
}

done-testing;