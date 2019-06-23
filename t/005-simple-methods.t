use v6;

use Perl6::Documentable;
use Test;

plan *;

my $doc1 = Perl6::Documentable.new(:kind("language"), 
                                  :name("testing"), 
                                  :subkinds("type")
                                );

my $doc2 = Perl6::Documentable.new(:kind("operator"),
                                   :name("doc2"),
                                   :categories("operator")
                                   :subkinds("type")
                                 );

my $doc3 = Perl6::Documentable.new(:kind("random"), 
                                   :categories("nooperator")
                                   :subkinds(["even", "more"])
                                 );


subtest {
    is $doc1.human-kind, "language documentation", "Language";
    is $doc2.human-kind, "type operator"         , "Operator";
    is $doc3.human-kind, "even and more"         , "No operator case";
}, "human-kind method";

subtest {
    is $doc2.url, "/language/operators#type_doc2", "Url case #1";
    is $doc1.url, "/language/testing", "Url case #2";
}, "url method";

done-testing;