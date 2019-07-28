use Perl6::Documentable;
use Test;

plan *;

=begin pod

Some pod

=end pod

my $doc1 = Perl6::Documentable.new(
  pod        => $=pod[0],
  kind       => Kind::Type,
  name       => "testing",
  subkinds   => ["type"],
  categories => ["operator"]
);

my $doc2 = Perl6::Documentable.new(
  pod      => $=pod[0],
  kind     => Kind::Language,
  name     => "testing2",
);

my $doc3 = Perl6::Documentable.new(
  pod      => $=pod[0],
  kind     => Kind::Programs,
  name     => "testing3",
  subkinds => ["method", "sub"]
);

subtest 'english-list' => {
  is $doc2.english-list, "", "no subkinds";
  is $doc3.english-list, "method and sub", "multiple subkinds";
  is $doc1.english-list, "type", "single subkind";
}

subtest 'human-kind' => {
  is $doc2.human-kind(), "language documentation", "first  case";
  is $doc1.human-kind(), "type operator"         , "second case";
  is $doc3.human-kind(), "method and sub"        , "third  case";
}

subtest 'categories' => {
  is-deeply $doc3.categories(), ["method", "sub"], "categories eq to sk";
}

done-testing;