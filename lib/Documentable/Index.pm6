use Documentable;
use Documentable::Utils::Text;
use Pod::Utilities;
use Pod::Utilities::Build;
use URI::Escape;

unit class Documentable::Index is Documentable;

has $.origin;
has @.meta;

method new(
    :$pod!,
    :$meta!,
    :$origin!
) {
    my ($name, $category);
    if $meta.elems == 2 {
        $category = $meta[0];
        $name = $meta[1];
    } else {
        warn "At $origin.url() $meta.raku() is not formatted properly, must have 2 elements (category, term)";
    }

    nextwith(
        kind     => Kind::Reference,
        categories => [$category.?trim],
        subkinds => ['reference'],
        name     => $name.?trim,
        :$pod,
        :$origin,
        :$meta
    );
}

method url() {
    my @indices    = $.pod.meta;
    # meta is by default a list of lists, so take the first element
    # and then take `foo` part of `X<Text?|Category,foo>`.
    my $index-entry-text = @indices[0][1];
    my $fragment = "index-entry-$index-entry-text";
    # don't forget to properly HTML escape the fragment, as it might
    # contain various special characters
    return $.origin.url ~ "#" ~ uri-escape($fragment);
}

# vim: expandtab shiftwidth=4 ft=perl6
