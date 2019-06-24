[![Build Status](https://travis-ci.org/antoniogamiz/Perl6-Documentable.svg?branch=master)](https://travis-ci.org/antoniogamiz/Perl6-Documentable)

# NAME

Perl6::Documentable

# SYNOPSIS

```perl6
use Perl6::Documentable;
use Pod::Load;

# get a pod source
my $pod = load("some-amaizing-pod-file.pod6")[0];

# create the first Documentable object from a pod
my $doc = Perl6::Documentable.new(:kind("Type"),
                                  :$pod,
                                  :name("testing"),
                                  :url("/Type/test"),
                                  :summary(""),
                                  :pod-is-complete,
                                  :subkinds("Type")
                                );

# process it!
$doc.find-definitions();

# and use it!
$doc.defs;
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

Can take one of the following values: `<infix prefix postfix circumfix postcircumfix listop sub method term routine trait submethod constant variable twigil declarator quote>`. In addition, it can take the value of the
meta part in a `X<>` definition, which is unambiguous.

### Str @.categories

It is assigned with what `classify-index` returns. Its value will be one of the following (\$subkind
is obtained using `parse-definition`):

If `$subkind` is one of `<infix prefix postfix circumfix postcircumfix listop>`, `@categories` will be set to `operator`. Otherwise, it will be set to `$subkind`.

### Str \$.name

Name of the Pod. Usually is set to the filename without the file extension `.pod6`.

If it's a definition, it will be set to the value correspondent to `$name` returned by `parse-definition-header`.

### Str \$.url

Static url to the processed file. Its value can be specified in the Pod configuration as follows:

```perl6
=begin pod :link<some-link>

...

=end pod
```

It will be set to `/$kind/$link`. By default `$link=$filename`.

### \$.pod

Perl6 Pod Structure (obtained using `Pod::Load` module).

### Bool \$.pod-is-complete

Indicates if the Pod represented by the `Perl6::Documentable` object is completed. A Pod is completed if
represents the whole pod source, that's to say, the `$.pod` attribute contains an entire pod file.

It will be considered incomplete if the `Perl6::Documentable` object represents a definition. In that case
the `$.pod` attribute will only contain the part corresponding to the definition.

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

Documentable object that this one was extracted from, if any. This is used for nested
definitions. Let's see an example:

```perl6
=begin pod

Every one of this valid definitions is represented by a Perl6::Documentable object
after have been processed.

=head1 method a

=head2 method b

    In both cases $origin points to the Documentable object representing
    the method a.

=head2 method c

=head1 method d

    $origin in this case points to the Perl6::Documentable object
    containing the pod source.
=end pod

```

Two or more definitions are nested if they appears one after another and if the first one
has a greater heading level than the second one.

### Array @.defs

This is one of the most important attributes of a `Perl6::Documentable` object. It contains all definitions
found and processed corresponding to the pod of `$.origin` stored in more `Perl6::Documentable` objects. In
general, all of them will have `pod-is-complete` set to `false`.

### method human-kind

```perl6
method human-kind (
) return Str
```

Returns the transformation of `$.kind` to a "more human" version. That means:

- If `$.kind` is equal to `language` then it returns `language documentation`.
- Otherwise, if `@.categories` is equal to `operator` then is set to `@.subkinds operator`. If not, it's set to the result of calling `english-list` with `@.subkinds` or `$.kind` if the previous one is not defined.

Examples:

```
declarator
do (statement prefix)
```

Note: `english-list` is a helper function which join a list using commas and add a final "and" word:

```
my @a = ["a","b","c"];
english-list(@a) # OUTPUT: a, b and c
```

### method url

```perl6
method url (
) return Str
```

Sets `$.url` to:

- If `$.kind` is equal to `operator` then will be set to the concatenation of:
  - `/language/operators#`
  - `@.subkinds $.name` (replacing the spaces with an underscores).

Examples

```
/language/101-basics#index-entry-v6_(Basics)-v6
/language/101-basics#index-entry-statement_(Basics)-statement
/language/101-basics#index-entry-lexical
```

- Otherwise, it will be set to the concatenation (separator="/") of `$.kind` and `$.name`.

Examples

```
/syntax/block
/syntax/stable%20sort
```

`uri_escape` routine from `URI::Escape` is applied every time an attribute is used.

### method categories

```perl6
method categories (
) return Array
```

Returns `@.categories`. If `@.categories` if it's not defined, sets `@.categories` to the same value
as `@.subkinds`.

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

### method find-definitions

```perl6
method find-definitions (
    Array               $pod       = self.pod,
    Perl6::Documentable $origin    = self,
    Int                 $min-level = -1
) Int
```

It is a recursive function used to populate `@.defs`. It runs through the pod content
and looks for headings. If is a heading is a definition, like `=head2 method mro`. Then
processes it and gives the rest of the pod to find-definitions again, which will return
how far the definition of `head2 method mro` extends. We then continue parsing from after
that point.

When we find a new definition, a new `Perl6::Documentable` object is created and initialized to:

- `$origin`: to `$origin`.
- `$pod`: It will be populated with the pod section corresponding to the definition and its subdefinitions (all valid headers with a greater level until one with the same or lower level is found).
- `$pod-is-complete`: to `false` beacuse it's a definition.
- `name`: To `$name` obtained with `parse-definition-header`.
- `subkind`: To `$subkind` obtained with `parse-definition-header`.
- `kind` and `categories`: to the return value of `classify-index`. If `$subkind` is `routine`, then it will be overwritten (TODO: resolve this).

### method find-references

```perl6
method find-references (
    :$pod    = self.pod,
    :$url    = self.url,
    :$origin = self
) returns Mu;
```

It goes through all the pod tree recursively searching for `X<>` elements (`Pod::FormattingCode`). When one is found, `register-reference` is called with the pod fragment associated to that element, the same origin and the next url:

```
$url ~ '#' ~ index-entry-$pod.meta-$index-text
```

Where `$pod.meta` could be an Arrray. In that case all its elements will be joined using `-`. `$index-text` is the result of calling `recurse-until-str` with the pod fragment. Normally, it always returns the left part of the `X<>` element.

Examples:

```
/Type/test#index-entry-url-new_reference
/Type/test#index-entry-meta_part-no_meta_part
```

Note: all "\_" are replaced by two underscores and all " " are replaced by an underscore.

### method register-reference

```perl6
method register-reference (
    :$pod!
    :$origin
    :$url
) returns Mu;
```

Every time it's called it adds a new `Documentable` object to `@.refs`, with `$kind` and `$subkinds` set to references. Name attr, is taken from the meta part: the last element becomes the first and the rest are written just after.

Example:

```
Given the meta ["some", "reference"], the name would be: "reference (some)"
```

That's done for every element in meta, that means, if meta has 2 elements, then 2 `Documentable` objetcs will be added (you can specify several elements in a `X<>` using `;`).

If there is not meta, then the pod content is taken as name.

# AUTHORS

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
