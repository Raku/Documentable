use Documentable;
use Documentable::Primary;
use Documentable::Utils::Text;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Test;

plan *;

my $pod = load("t/test-doc/Native/int.pod6")[0];

my $doc = Documentable::Primary.new(
    :$pod,
    :filename("int")
);

my @names      := ("ACCEPTS", "any", "mro", "root");
my @subkinds   := ("method" , "routine"           );
my @categories := ("method" , "routine"           );

my @defs;


subtest "All definitions found" => {
  is-deeply $doc.defs».name.sort                                  , @names     , "Names detected";
  is-deeply $doc.defs».subkinds.tree(*.Slip, *.Slip).unique.sort  , @subkinds  , "Subkinds detected";
  is-deeply $doc.defs».categories.tree(*.Slip, *.Slip).unique.sort, @categories, "Categories detected";
}

# In Native/int.pod6, origin att all definitions must point to the pod source
# except for "method root" that is subparsed and its origin must point
# to "method any"
subtest "Subparsing structure" => {
  my @definitions = $doc.defs.grep({.name ne "root"});
  for @definitions -> $d {
    is-deeply $d.origin, $doc, "Correct origin in $d.name()";
  }
}

# Correct scope detection is checked converting the entire pod of the
# definition to Str and compare the result
subtest "Scope set correctly" => {
    my @definitions = (
       "ACCEPTS", "  (int) method ACCEPTS This should be indexed!",
       "any"    , "  (int) method any This should be indexed and subparsing should be done!     method root Subparsing!",
       "root"   , "  (int) method root Subparsing!",
       "mro"    , "  (int) routine mro At this point the last subparsing should have stopped. Defined as     multi sub    mro(*@list  --> Seq:D)"
    );

    for @definitions -> $name, $str {
      test-scope($name, $str);
      test-scope-with-textify-pod($name, $str);
    }
}

subtest "Formats code ignored except X" => {
    my @formatting-codes = <B C E I K L N P R T U>;
    my @headings = @formatting-codes.map({
        pod-heading(
            Pod::FormattingCode.new(
                type     => $_,
                contents => ["heading"]
            )
        )
    });

    for @headings -> $heading {
        is so $doc.parse-definition-header(:heading($heading)), ["False"],
           $heading.contents[0].contents[0].type ~ " format code ignored";
    }
}

my $head = pod-heading(
            Pod::FormattingCode.new(
                type     => "X",
                contents => ["INTRODUCTION"],
                meta     => ["p6doc"]
            )
);

subtest "Index X<> heading" => {
    test-index($head, "INTRODUCTION", "p6doc"        , "p6doc"        );
}

# check exceptions

=begin pod :kind("Type") :subkind(" ") :category(" ")

Test

=end pod

=begin pod :kind("Type") :subkind(" ") :category(" ")

=TITLE test

=end pod

=begin pod :kind("Type") :subkind(" ") :category(" ")

=SUBTITLE test

=end pod

subtest '=TITLE =SUBTITLE compulsory' => {
  test-exception($=pod[0], "=TITLE and =SUBTITLE");
  test-exception($=pod[1], "=TITLE");
  test-exception($=pod[2], "=SUBTITLE");
}

# ======== auxliar functions ===============

sub test-index($heading, $name, $subkinds, $categories) {
    my %attr = $doc.parse-definition-header(:$heading);
    subtest {
        is %attr<name>      , $name       , "name correct";
        is %attr<kind>      , Kind::Syntax, "kind correct";
        is %attr<subkinds>  , $subkinds   , "subkinds correct";
        is %attr<categories>, $categories , "classified correctly";
    }, "$subkinds index";
}

#| returns a specific definition
sub get-def($name) {
  $doc.defs.grep({ .name eq $name }).first;
}

sub test-scope($name, $str) {
  is textify-guts(get-def($name).pod),
     $str,
     "Scope detection in $name";
}

sub test-scope-with-textify-pod($name, $str) {
  is textify-pod(get-def($name).pod),
     $str,
     "Scope detection in $name with textify-pod";
}

sub test-exception($pod, $msg) {
  dies-ok { Documentable::Primary.new(
              :$pod,
              :filename("int")
  )}, $msg;
}

done-testing;
