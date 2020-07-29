use Documentable;
use Test;

plan *;

=begin pod

Some pod


=end pod

my $doc1 = Documentable.new(
  pod        => $=pod[0],
  kind       => Kind::Type,
  name       => "testing",
  subkinds   => ["type"],
  categories => ["operator"]
);

my $doc2 = Documentable.new(
  pod      => $=pod[0],
  kind     => Kind::Language,
  name     => "testing2",
);

my $doc3 = Documentable.new(
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

subtest 'good-name' => {
  is good-name("/")  , '$SOLIDUS'          , "/ replaced";
  is good-name("%")  , '$PERCENT_SIGN'     , "% replaced";
  is good-name("^")  , '$CIRCUMFLEX_ACCENT', "^ replaced";
  is good-name("")   , ""                  , "nothing replaced";
  is good-name("%20"), "%20"               , "no escape %xx";
}

subtest 'rewrite-url' => {
  is rewrite-url('https://thor') , 'https://thor'          , "external links invariant";
  is rewrite-url('#thor')        , '#thor'                 , "internal links invariant";
  is rewrite-url('irc://thor')   , 'irc://thor'            , "irc      links invariant";
  is rewrite-url("/good/link")   , '/good/link'            , "good link";
  is rewrite-url("/simple")      , '/simple'               , "simple link (1)";
  is rewrite-url("simple")       , '/simple'               , "simple link (2)";
  is rewrite-url('/a/^')         , '/a/$CIRCUMFLEX_ACCENT' , "^ replaced";
  is rewrite-url('/a/%')         , '/a/$PERCENT_SIGN'      , "% replaced";
  is rewrite-url('/a/b#internal'), '/a/b#internal'         , 'not change internals';
  is rewrite-url("/a", "p")      , '/p/a'                  , "prefix (1)";
  is rewrite-url("a", "p")       , '/p/a'                  , "prefix (2)";
  is rewrite-url(".")            , '/..html'               , "Final dot, see #72";

}


done-testing;