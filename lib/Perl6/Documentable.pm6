unit module Perl6::Documentable;

#| Enum to classify all "kinds" of Perl6::Documentable
enum Kind is export <Type Language Programs Syntax Reference Routine>;

#| List of the subdirectories that contain indexable pods by default
constant DOCUMENTABLE-DIRS is export = ["Language", "Type", "Programs", "Native"];

#| Everything documented inherits from this class
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
    my @badchars  = ["/", "^", "%"];
    my @goodchars = @badchars
                    .map({ '$' ~ .uniname      })
                    .map({ .subst(' ', '_', :g)});

    $name = $name.subst(@badchars[0], @goodchars[0], :g);
    $name = $name.subst(@badchars[1], @goodchars[1], :g);

    # if it contains escaped sequences (like %20) we do not
    # escape %
    if ( ! ($name ~~ /\%\d\d/) ) {
        $name = $name.subst(@badchars[2], @goodchars[2], :g);
    }

    return $name;
}

sub rewrite-url($s) is export {
    given $s {
        when {.starts-with: 'http' or
              .starts-with: '#'    or
              .starts-with: 'irc'     } { $s }
        default {
            my @parts   = $s.split: '/';
            my $name    = good-name(@parts[*-1]);
            my $new-url = @parts[0..*-2].join('/') ~ '/' ~ $name;
            $new-url;
        }
    }
}

# vim: expandtab shiftwidth=4 ft=perl6
