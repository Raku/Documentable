[![Build Status](https://travis-ci.org/antoniogamiz/Perl6-Documentable.svg?branch=master)](https://travis-ci.org/antoniogamiz/Perl6-Documentable)

# NAME

Perl6::Documentable

# SYNOPSIS

```perl6
use Perl6::Documentable;
```

# DESCRIPTION

Perl6::Documentable Represents a piece of Perl 6 that is documented. It contains meta data about what is documented (for example (kind => 'type', subkinds => ['class'], name => 'Code') and in \$.pod a reference to the actual documentation.

## Perl6::Documentable

```perl6
    has Str $.kind;
    has Bool $.section;
    has Str @.subkinds;
    has Str @.categories;

    has Str $.name;
    has Str $.url;
    has     $.pod;
    has Bool $.pod-is-complete;
    has Str $.summary = '';

    has $.origin;
```

### Str \$.kind

One of the following values: `language`, `programs` or `type`.

### Str @.subkinds

Can take one of the following values: `class`,`role`,`enum`,`prefix`,`infix`, etc. Currently, in the official doc, is always set to the same value as [`$kind`](https://github.com/perl6/doc/blob/f328984196e33e4aec2d4c0a94e973a04447689f/htmlify.p6#L363).

### Str @.categories

Not used

### Str \$.name

Name of the Pod. Usually is set to the filename without the file extension `.pod6`.

### Str \$.url

Static url to the processed file. Its value can be specified in the Pod configuration as follows:

```perl6
=begin pod :link<some-link>

...

=end pod
```

It will be set to `/$kind/$link`. By default `$link=$filename`.

### \$.pod

Perl6 Pod Structure.

### Bool \$.pod-is-complete

Indicates if the Pod is complete (in the official doc generation is always set to [True](https://github.com/perl6/doc/blob/f328984196e33e4aec2d4c0a94e973a04447689f/htmlify.p6#L303)).

### Str \$.summary

Subtitle of the pod.

```perl6
=begin pod :tag<tutorial>

=TITLE  Perl 6 by example

=SUBTITLE A basic introductory example of a Perl 6 program

...

=end pod

```

In this case `$summary="A basic introductory example of a Perl 6 program"`.

### \$.origin

Documentable object that this one was extracted from, if any. Not used.

### method parseDefinitionHeader

```perl6
method parseDefinitionHeader (
    Pod::Heading :$heading
) return [$subkind, $name, $unambiguous]
```

This method takes a `Pod::Heading` object and parse a possible definition. If found,
it returns the `$subkind`, `$name` and a boolean value indicating if the definion is
unambiguous.

- What headings are considered a definition?
  - `X<$name|$subkind>`: this is considered an `unambiguous` definition, that's to say, no matter what appers inside the `X<>` it will be indexed. `$unambiguous` will be set to to `true` in this case, `false` otherwise.
  - `The Foo Infix`: `Foo` will be considered as `$name` and `Infix` as the `$subkind`. `Foo` can be written using `C<Foo>` or other format code.
  - `Infix Foo`: `Foo` will be considered as `$name` and `Infix` as the `$subkind`. `Foo` can be written using `C<Foo>` or other format code.
  - `trait Infix Foo`: `Infix Foo` will be considered as `$name` and `trait` as the `$subkind`.

### method classifyIndex

```perl6
method classifyIndex (
    Str  :$sk,
    Bool :$unambiguous
) return Hash
```

Given a subkind `$sk` (obtained with `parseDefinitionHeader`), it will return a `Hash` object
containing the `kind` and the `categories` of the definition, if any.

If `$subkind` takes one of the following values `<infix prefix postfix circumfix postcircumfix listop sub method term routine trait submethod>`, `$kind` will be set to `routine`. If it is one of `<constant variable twigil declarator quote>` or `$unambiguous` is true, `$kind` will be set to `syntax`.

If `$subkind` is one of `<infix prefix postfix circumfix postcircumfix listop>`, `$categories` will be set to `operator`. Otherwise, it will be set to `$subkind`.

# AUTHOR

Moritz Lenz <@moritz>
Jonathan Worthington <@jnthn>
Richard <@finanalyst>
Will Coleda <@coke>
Aleks-Daniel <@AlexDaniel>
Sam S <@smls>
Alexander Moquin <@Mouq>
Antonio <antoniogamiz10@gmail.com>

# COPYRIGHT AND LICENSE

Copyright 2019 Antonio

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
