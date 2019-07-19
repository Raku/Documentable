use v6;

use Perl6::Documentable;
use Test;

plan *;

=begin pod

Some pod

=end pod

my $doc1 = Perl6::Documentable.new(
  :pod($=pod[0]),
  :kind("language"),
  :name("testing"),
  :subkinds("type")
);

my $doc2 = Perl6::Documentable.new(
  :pod($=pod[0]),
  :kind("operator"),
  :name("doc1"),
  :categories("operator")
  :subkinds("type")
);

my $doc3 = Perl6::Documentable.new(
  :pod($=pod[0]),
  :kind("random"),
  :name("doc2")
  :categories("nooperator")
  :subkinds(["even", "more"])
);


subtest "human-kind method" => {
    is $doc1.human-kind, "language documentation", "Language";
    is $doc2.human-kind, "type operator"         , "Operator";
    is $doc3.human-kind, "even and more"         , "No operator case";
}

subtest "url method" => {
    is $doc2.url, "/language/operators#type_doc1", "Url case #1";
    is $doc1.url, "/language/testing", "Url case #2";
}

done-testing;