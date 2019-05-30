# How is the documentation generated?

## Doc dir processing

How are processed all pod files in the doc directory? These are the main steps:

1. A `Perl6::Documentable::Registry` object is created (called `$*DR`).
2. `process-pod-dir` is called (one per dir: Programs, Language, Type, Native):
   1. Pod files are read and sorted by `:&sorted-by` (cmp by default): ([line](https://github.com/perl6/doc/blob/9f36dae596fb672b1eb8b5901a1c99a5cc9b4567/htmlify.p6#L200)) `sorted-by` is a hash 
   where every key is the name of a Perl6 Type and its value is a number. The names are taken from the
   type-graph file and sorted alphabetically. An example can be found [here](https://gist.github.com/antoniogamiz/b11c504439901a82c7497fe6363bbef2).
   2. Each pod file is extracted and `process-pod-source` is called.

## Pod file processing

For each pod file a `Perl6::Documentable` object is created with the following
attributes:

- `$kind` => name of the dir (Programs, Language, Type, Native).
- `$name` => the text following =TITLE or, if `$kind==type`, the last word in the text following =TITLE.
- `$summary` => the text following =SUBTITLE.
- `$pod` => extracted pod.
- `$url` => `/$kind/ ~ $rest`. `$rest` is set to the config value `link` (you have to set it in the pod configuration:
 `=begin pod :link<url>`). If none is passed then is set to the filename without the extension.
- `$pod-is-complete`: `True` by default.
- `$subkinds` => `$kind` (for now).
- `%type-info` => Only applied to pod files in the Type dir. Map containing two keys:
  - `subkinds`: one the following values: `class`, `role` or `enum`.
  - `categories`: one of the following values: `basic`, `composite`, `domain-specific`,`exceptions`,`metamodel` or `core`.

## What is indexed:

Currently there are 8 different candidates of definitions to be indexed, all of them made through a `Pod::Heading` element.
The level of the heading does not affect.

### Definition candidates

This is done by the method `parseDefinitionHeader` in the class `Perl6::Documentable`.
It returns: `[ $subking, $name, $unambiguous ]`.

#### Type 1

If the `Pod::Heading` object is a `Pod::FormattingCode`.

```perl6

=head2 L<Debugger::UI::CommandLine|https://modules.perl6.org/repo/Debugger::UI::CommandLine>

That will be ignored because is not a X Pod::FormatingCode type.

=head3 X<C<v6>|v6 (Basics)>

This will be indexed.

```

Then the processed definition would be: `[v6 (Basics) v6]`.

In addition, `$unambiguous` will be set to `True`, that's to say, it will be indexed (read below).

**Note: ** If the meta info is omitted (`X<meta|name>`) then the element
will be indexed only as a category (see `$unambiguous` case).

#### Type 2

If the `Pod::Heading` object is a string like `The something something2`. Something2 is interpreted as
the subkind and something as the name.

```perl6


=head2 The arrow operator

Definition: [operator arrow]

=head1 The Q lang

Definition: [lang Q]

```

#### Type 2.1

If the `Pod::Heading` object is a string like `The Pod::FormattingCode{something} something2`. Something2 is interpreted as the subkind and something as the name.

```perl6


=head2 The C<anon> declarator

Definition: [declarator anon]

```

#### Type 3

If the `Pod::Heading` object is a string like `something something2`. Something is interpreted as
the subkind and something2 as the name.

```perl6

=head1 Block phasers

Definition: [Block phasers]

```

#### Type 3.1

If the `Pod::Heading` object is a string like `something Pod::FormattingCode{something2}`. Something is interpreted as the subkind and something2 as the name.

```perl6

=head2 postcircumfix C«( )»

Definition: [postcircumfix ( )]

```

#### Type 4

If the `Pod::Heading` object is a string like `trait something something2`. `trait` is interpreted as
the subkind a `something something2` as the name.

```perl6

=head2 trait is export

Definition: [trait is export]. This example in particular could be troublesome because this header
is repeated in Mu.pod6 and Routine.pod6 (check it).

```

Whatever Pod::Heading object not included in one of these types is ignored.

Maybe is helpful to know what is being ignored at this momemnt: [gist](https://gist.github.com/antoniogamiz/85bd5d4d5b57e6b91ae1a90a4a4f5395).

Once we have our definition candidate, it still has to pass another test: it has to be one of the
following cases:

```perl6
    given $subkinds {
        when / ^ [in | pre | post | circum | postcircum ] fix | listop / {
            %attr = :kind<routine>,:categories<operator>;
        }
        when 'sub'|'method'|'term'|'routine'|'trait'|'submethod' {
            %attr = :kind<routine>, :categories($subkinds);
        }
        when 'constant'|'variable'|'twigil'|'declarator'|'quote' {
            %attr = :kind<syntax>, :categories($subkinds);
        }
        when $unambiguous {
            %attr = :kind<syntax>, :categories($subkinds);
        }
        default {
            next;
        }
    }
```

At this point, we have found a valid definition to be indexed, so we add it as a new `Perl6::Documentable` object
to `$*DR` (that is done [here](https://github.com/perl6/doc/blob/9f36dae596fb672b1eb8b5901a1c99a5cc9b4567/htmlify.p6#L668)).

`%attr` is a hash passed (flatten) to the `Perl6::Documentable` constructor to initialize the `$kind`
and `$categories` attribute.

Maybe is helpful to know all categories that are being considered [gist](https://gist.github.com/antoniogamiz/ec29efff3a8928ec48f06185a38460d2).

Before continuing with the process of THIS definition, we need to keep searching for more definitions: How? We
call again the same function (`find-definitions`) with the same \$pod but with the current value of `$i`. Doing so,
the new call will start searching from where we stopped. That is done [here](https://github.com/perl6/doc/blob/9f36dae596fb672b1eb8b5901a1c99a5cc9b4567/htmlify.p6#L679).

So, now we have to really process the definition:

1. Create a new `Pod::Heading` with the content of the definition.
   1. We assign it the url [here](https://github.com/perl6/doc/blob/9f36dae596fb672b1eb8b5901a1c99a5cc9b4567/htmlify.p6#L690) (I am taking note of this to keep track of where urls are assigned to fix the problem related).
2. The subkinds and categories of this definition are "fixed" or "updated". (#TODO: explain more)
3. The definition is added to `%routines-by-type`, a hash where all definitions will be stored (every key is a
   name of one pod file).

And that is all as for definitions!
