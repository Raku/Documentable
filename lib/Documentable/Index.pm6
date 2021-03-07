use Documentable;
use Documentable::Utils::Text;
use Pod::Utilities;
use Pod::Utilities::Build;

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
        warn "At $origin.url() $meta.raku() is not formatted properly";
    }

    nextwith(
        kind     => Kind::Reference,
        categories => [$category.trim],
        subkinds => ['reference'],
        name     => $name.trim,
        :$pod,
        :$origin,
        :$meta
    );
}

method url() {
    my $index-text = recurse-until-str($.pod).join;
    my $indices    = $.pod.meta[0];
    my $fragment = qq[index-entry{$indices ?? "-$indices[1]" !! ''}{$index-text ?? '-' !! ''}$index-text]
                 .subst('_', '__', :g).subst(' ', '_', :g);

    return $.origin.url ~ "#" ~ good-name($fragment);
}

# vim: expandtab shiftwidth=4 ft=perl6
