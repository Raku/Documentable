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

method url() { '#' }

# vim: expandtab shiftwidth=4 ft=perl6