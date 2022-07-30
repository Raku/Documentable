use Documentable::Primary;
use Documentable::Index;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Test::Output;

use Test;

plan *;

my $pod = load("t/test-doc/Programs/02-reading-docs.pod6")[0];

my $origin;

output-like {
    $origin = Documentable::Primary.new(
        pod => $pod,
        filename => "test",
        source-path => "t/test-doc/Programs/02-reading-docs.pod6"
    );
}, /'At /programs/test "foo"' .+? 'At /programs/test "item,item2,item3"' /,
    'detects wrong format of references';

my @names := ("url", "meta", "part", "nometa");
my %urls =
    "url"           => "/programs/test#index-entry-url",
    "meta"          => "/programs/test#index-entry-%20meta",
    "part"          => "/programs/test#index-entry-%20meta",
    "nometa"        => "/programs/test#index-entry-nometa";

subtest "Reference detection" => {
    for $origin.refs -> $ref {
        # we skip references without a name, as we have
        # bogus syntax references in the test file to test out we can detect it
        next unless $ref.name;
        is $ref.name ∈ @names, True, "$ref.name() detected";
    }
}

subtest "URL handling" => {
    for $origin.refs -> $ref {
        next unless $ref.name;
        is $ref.url, %urls{$ref.name()}, "$ref.name() url";
    }
}

subtest "leading whitespace references" => {
    my $reference = Pod::FormattingCode.new(
        type     => 'X',
        meta => [["meta", " meta1"]],
    );
    my @references = Documentable::Index.new(
        pod    => $reference,
        origin => Documentable::Primary,
        meta   => [["meta", " meta1"]]
    );
    for @references -> $ref {
        is $ref.name.starts-with(" "), False, "leading whitespace";
    }
}

done-testing;
