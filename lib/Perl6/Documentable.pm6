unit module Perl6::Documentable;

#| Enum to classify all "kinds" of Perl6::Documentable
enum Kind is export <Type Language Programs Syntax Reference Routine>;

#| Everything documented inherits from this classed
class Perl6::Documentable {

    has Str  $.name;
    has      $.pod;
    has      $.kind;
    has      @.subkinds   = [];
    has      @.categories = [];

    submethod BUILD (
        :$!name,
        :$!kind!,
        :@!subkinds,
        :@!categories,
        :$!pod!,
    ) {}

    method english-list () {
        return '' unless @!subkinds.elems;
        @@!subkinds > 1
                    ?? @!subkinds[0..*-2].join(", ") ~ " and @!subkinds[*-1]"
                    !! @!subkinds[0]
    }

    method human-kind() {
        $!kind eq Kind::Language
            ?? 'language documentation'
            !! @!categories eq 'operator'
            ?? "@!subkinds[] operator"
            !! self.english-list // $!kind;
    }

    method categories() {
        return @!categories if @!categories;
        return @!subkinds;
    }
}

#| Every type of page generated, must implements this role
role Perl6::Documentable::DocPage {
    method render (| --> Hash) { ... }
    method url    (| --> Str ) { ... }
}

# these chars cannot appear in a unix filesystem path
sub good-name($name is copy --> Str) is export {
    # / => $SOLIDUS
    # % => $PERCENT_SIGN
    # ^ => $CIRCUMFLEX_ACCENT
    my @badchars  = ["/", "%", "^"];
    my @goodchars = @badchars
                    .map({ '$' ~ .uniname      })
                    .map({ .subst(' ', '_', :g)});

    loop (my int $i = 0; $i < 3; $i++) {
        $name = $name.subst(@badchars[$i], @goodchars[$i], :g)
    }

    return $name;
}

# vim: expandtab shiftwidth=4 ft=perl6
