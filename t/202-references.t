use Documentable::Primary;
use Documentable::Index;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;

use Test;

plan *;

subtest "Reference detection" => {
    my $source-path = "t/test-doc/Programs/02-reading-docs.pod6";
    my $origin = Documentable::Primary.new(
        pod         => load($source-path).first,
        filename    => "test",
        :$source-path
    );
    my @names := ("url", "meta (multi)", "part", "nometa");
    for $origin.refs -> $ref {
        ok $ref.name ∈ @names, "$ref.name() detected";
    }
}

subtest "leading whitespace references" => {
    my $reference = ref("X<|meta, meta1>");
    my @references = Documentable::Index.new(
        pod    => $reference,
        origin => Documentable::Primary,
        meta   => [["meta", " meta1"]]
    );
    for @references -> $ref {
        nok $ref.name.starts-with(" "), "Leading whitespace";
    }
}

sub ref($ref) {
    my $pod = load(qq{
    =begin pod
    $ref
    =end pod
    });
    return $pod[0].contents[0].contents[0];
}

done-testing;