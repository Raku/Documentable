use Perl6::Documentable;
use Pod::Utilities;
use Pod::Utilities::Build;

unit class Perl6::Documentable::Derived is Perl6::Documentable;

has $.origin;

method new(
    :$kind!,
    :$name!,
    :@subkinds,
    :@categories,
    :$pod!,
    :$origin
) {
    nextwith(
        :$kind,
        :$name,
        :@subkinds,
        :@categories,
        :$pod,
        :$origin
    );
}

method compose(:$level, :@content) {
    # (sth) infix foo
    my $title = "($.origin.name()) @.subkinds[] $.name()";

    my $new-head = Pod::Heading.new(
        :$level,
        contents => [ pod-link($title, self.url) ]
    );

    my @chunk = flat $new-head, @content;
    @chunk = pod-lower-headings(
            @chunk,
            to => ($.kind eq Kind::Type) ?? 0 !! 2,
    );

    if @.subkinds eq 'routine' {
        my @sk = self.determine-subkinds(first-code-block(@chunk));
        @.subkinds   = @sk;
        @.categories = @sk;
    }

    $.pod.append: @chunk;
}

method determine-subkinds(Str $code --> Array) {
    my Str @subkinds = $code\
        .match(:g, /:s (sub|method)»/)\
        .>>[0]>>.Str.unique;

    note "The subkinds of routine $.name in $!origin.name()"
         ~ " cannot be determined. Are you sure that routine is"
         ~ " actually defined in $!origin.name() 's file?"
        unless @subkinds;

    return @subkinds;
}

method url() {
    $!origin.url ~
    "#$!origin.human-kind() $!origin.name()".subst(:g, /\s+/, '_');
}

# vim: expandtab shiftwidth=4 ft=perl6