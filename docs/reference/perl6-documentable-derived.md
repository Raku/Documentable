## Perl6::Documentable::Derived

Each and every one of these objects represent a piece of one pod file. To be more precise, it contains what we consider a "definition". Like the documentation of `method of`, for instance.

All this objects are created from `find-definitions` in `Perl6::Documentable::File`. You need two things to create one of this, the level of the definition, that's to say, of the heading and its content.

```perl6
use Perl6::Documentable::File;
use Perl6::Documentable::Derived;

my $doc = Perl6::Documentable::File.new(
    ...
)

my $definition = Perl6::Documentable::Derived.new(
    :origin($doc),      # pod where the definition comes from
    :pod[],             # before being populated, it's empty
    :@subkinds,         # metada of the definition
    :@categories
    :kind(Kind::Syntax) # Kind::Syntax or Kind::Routine
)
```

### Attributes

#### Perl6::Documentable::File origin

Documentable representing the file where this definition was found.

### Methods

#### method compose

```perl6
method compose(
    Int :$level,
    :@contents
) return Mu
```

When we know how far a definition extends, we can take all that content and transform it to a standard format.

For instance, imagine with have a huge pod containing the following:

```perl6
=begin pod

(...)

=head3 sub potato

=head4 carrot infix

=head4 watermelon operator

=head3 whatever # <= at this point the definition of
                # sub potato has finished

(...)

=end pod
```

We only need to take (to process that definition):

```perl6
=head3 sub potato

=head4 carrot infix

=head4 watermelon operator
```

But this is tasteless, so we add a bit of flavour with `.compose`, which sets a commond heading (containing a link to the definition) and the previous pod with uniformed headings.

This would be the result for the previous definition (suppose the name of the big pod is `Operator`):

```perl6
=head2 Pod::FormattingCode{link => ..., content => ["(Operator) sub potato"]}

=head3 carrot infix

=head3 watermelon operator
```

#### method determine-subkinds

```perl6
method determine-subkinds(
    Str $code
) return Array
```

If the subkind of the definition is `routine`, it means it could be declarated like:

```perl6
multi method map(Hash:D \hash) multi method map(Iterable:D \iterable)
multi method map(|c) multi method map(\SELF: &block;; :$label, :$item)
multi sub map(&code, +values)
```

So its subkinds should be `["sub", "method"]`. And that's what this method returns, the proper subkinds of a routine.

#### method url

```perl6
method url(
) return Str
```

Url of this definition. Work in progress.
