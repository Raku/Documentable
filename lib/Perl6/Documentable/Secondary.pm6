use Perl6::Documentable;
use Pod::Utilities;
use Pod::Utilities::Build;

unit class Perl6::Documentable::Secondary is Perl6::Documentable;

has $.origin;
has Str $.url;
has Str $.url-in-origin;
method new(
    :$kind!,
    :$name!,
    :@subkinds,
    :@categories,
    :$pod!,
    :$origin
) {
    my $newpod = self.compose(
        $origin,
        @subkinds,
        $name,
        $pod
    );

    my $url = "/{$kind.Str.lc}/{good-name($name)}";
    my $url-in-origin = $origin.url ~ "#" ~textify-guts($pod[0]).trim.subst(/\s+/, '_', :g);

    nextwith(
        :$kind,
        :$name,
        :@subkinds,
        :@categories,
        :pod($newpod),
        :$origin,
        :$url,
        :$url-in-origin
    );
}

method compose($orig, @subkinds, $name, $pod) {
    # (sth) infix foo
    my $title = "($orig.name()) @subkinds[] $name";

    my $url = $orig.url ~ "#" ~textify-guts($pod[0]).trim.subst(/\s+/, '_', :g);
    my $new-head = Pod::Heading.new(
        level    => 2,
        contents => [ pod-link($title, $url) ]
    );

    my @chunk = flat $new-head, $pod[1..*-1];
    @chunk = pod-lower-headings( @chunk, :to(2) );

    return @chunk;
}

# vim: expandtab shiftwidth=4 ft=perl6