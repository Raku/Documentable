use Test;

use Documentable::Registry;
use Documentable::Config;
use Documentable::DocPage::Factory;

plan *;

my $registry = Documentable::Registry.new(
    :topdir("t/test-doc"),
    :dirs(["Type", "Native"]),
    :typegraph-file("t/test-doc/type-graph.txt"),
    :!verbose
);

$registry.compose;
my $config = Documentable::Config.new(filename => "t/good-config.json");

my $factory = Documentable::DocPage::Factory.new(:$config, :$registry);
isa-ok $factory, Documentable::DocPage::Factory, "Class created";

my %spawn = $factory.generate-home-page();
like %spawn<document>, /Raku/, "Home page generated correctly";

%spawn = $factory.generate-error-page() ;
like %spawn<document>, /Raku/, "Error page generated correctly";

%spawn = $factory.generate-search-file() ;
like %spawn<document>, /raku/, "Search script generated correctly";

subtest "pod-path in multi-class files" => {
    my Documentable::Primary $multi-doc1 = $registry.docs-for("pod1")[0];
    my Documentable::Primary $multi-doc2 = $registry.docs-for("pod2")[0];
    my $html = $factory.generate-primary($multi-doc1)<document>;
    ok $html.contains("master/docs/Native/multi-class.pod6"), "Same pod-path for multi-class pod (1)";
    $html = $factory.generate-primary($multi-doc2)<document>;
    ok $html.contains("master/docs/Native/multi-class.pod6"), "Same pod-path for multi-class pod (2)";


}
done-testing;