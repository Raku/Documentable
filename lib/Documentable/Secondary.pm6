use Documentable;
use Documentable::Utils::Text;
use Pod::Utilities;
use Pod::Utilities::Build;
use URI::Escape;

class Documentable::Secondary is Documentable {

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

        my $url = "/{$kind.Str.lc}/{uri-escape($name)}";
        my $url-in-origin = $origin.url ~ "#" ~textify-pod($pod[0]).trim.subst(/\s+/, '_', :g);

        # normalize the pod
        my $title = "($origin.name()) @subkinds[] $name";
        my $new-head = Pod::Heading.new(
            level    => 2,
            contents => [ pod-link($title, $url-in-origin) ]
        );
        my @chunk = flat $new-head, $pod[1..*-1];
        @chunk = pod-lower-headings( @chunk, :to(2) );

        nextwith(
            :$kind,
            :$name,
            :@subkinds,
            :@categories,
            :pod(@chunk),
            :$origin,
            :$url,
            :$url-in-origin
        );
    }

}

# vim: expandtab shiftwidth=4 ft=perl6
