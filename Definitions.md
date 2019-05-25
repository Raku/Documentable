# How is generated the documentation?

## Doc dir processing

How are processed all pod files in the doc directory? These are the main steps:

1. A `Perl6::Documentable::Registry` object is created (called `$*DR`).
2. `process-pod-dir` is called (one per dir: Programs, Language, Type, Native):
   1. Pod files are read and sorted by `:&sorted-by` (cmp by default).
   2. Each pod file is extracted and `process-pod-source` is called.

## Pod file processing

For each pod file a `Perl6::Documentable` object is created with the following
attributes:

- `$kind` => name of the dir (Programs, Language, Type, Native).
- `$name` => the text following =TITLE or, if `$kind==type`, the last word in the text following =TITLE.
- `$summary` => the text following =SUBTITLE.
- `$pod` => extracted pod.
- `$url` => `/$kind/ ~ $rest`. `$rest` is set to the config value `link`. If none is passed then is set to the filename without the extension.
- `$pod-is-complete`: `True` by default.
- `$subkinds` => `$kind` (for now).
- `%type-info` => Only applied to pod files in the Type dir. Map containing two keys:
  - `subkinds`: one the following values: `class`, `role` or `enum`.
  - `categories`: one of the following values: `basic`, `composite`, `domain-specific`,`exceptions`,`metamodel` or `core`.

## What is considered a definition:

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
