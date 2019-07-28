use Perl6::Documentable;
use Pod::Utilities;
use Pod::Utilities::Build;

unit class Perl6::Documentable::Index is Perl6::Documentable;

has $.origin;
has $.meta;

method new(
    :$pod!,
    :$meta!,
    :$origin!
) {

    my $name;
    if $meta.elems > 1 {
        my $last = textify-guts $meta[*-1];
        my $rest = $meta[0..*-2];
        $name = "$last ($rest)";
    } else {
        $name = textify-guts $meta;
    }

    nextwith(
        kind     => Kind::Reference,
        subkinds => ['reference'],
        name     => $name.trim,
        :$pod,
        :$origin,
        :$meta
    );
}

method url() {
    my $index-text = recurse-until-str($.pod).join;
    my @indices    = $.pod.meta;
    my $fragment = qq[index-entry{@indices ?? '-' !! ''}{@indices.join('-')}{$index-text ?? '-' !! ''}$index-text]
                 .subst('_', '__', :g).subst(' ', '_', :g).subst('%', '%25', :g).subst("#", '%23', :g);

    return $.origin.url ~ "#" ~ $fragment;
}

# vim: expandtab shiftwidth=4 ft=perl6