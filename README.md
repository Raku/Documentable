# Perl6 Doc Tools [![Build Status](https://travis-ci.org/antoniogamiz/Perl6-Documentable.svg?branch=master)](https://travis-ci.org/antoniogamiz/Perl6-Documentable) [![artistic](https://img.shields.io/badge/license-Artistic%202.0-blue.svg?style=flat)](https://opensource.org/licenses/Artistic-2.0)

In this repository you can find all logic responsible of generate the [official documentation of Perl6](https://docs.perl6.org/).

## Table of contents

- [Installation](#installation)
- [Usage](#usage)
- [Perl6::Documentable](#perl6documentable)
- [Perl6::Documentable::Registry](#perl6documentableregistry)
  - [Consulting methods](#consulting-methods)
  - [Processing methods](#processing-methods)
  - [Indexing methods](#indexing-methods)
- [Perl6::Documentable::To::HTML](#perl6documentabletohtml)
- [Perl6::Utils](#perl6utils)
- [Resources](#resources)
  - [Templates](#templates)
  - [HTML](#html)
- [Authors](#authors)

## Installation

```
$ zef install Perl6::Documentable
```

## Usage

```
bin/documentable [--topdir=<Str>] [-v|--verbose] [-c|--cache] [-p|--pods] [-s|--search-index] [-i|--indexes] [-a|--all]
```

#### --topdir <Str>

Directory where the pod files are stored. Set to `doc` by default.

#### -v, --verbose

Be more verbose/talkative during the operation. Useful for debugging
and seeing what's going on "under the hood".

#### -c, --cache

Usage of a cache of pod ([cached used](https://github.com/finanalyst/pod-cached)). Set to `True`
by default.

#### -p, --pods

Generate one HTML page for every pod file.

#### -s, --search-index

Generate the search file `search.js`.

#### -i, --indexes

Generate all index files.

#### -a, --all

Equivalent to `-p -s -i`.

## Perl6::Documentable

### SYNOPSIS

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

### DESCRIPTION

Perl6::Documentable Represents a piece of Perl 6 that is documented. It contains meta data about what is documented (for example (kind => 'type', subkinds => ['class'], name => 'Code') and in \$.pod a reference to the actual documentation.

### Perl6::Documentable

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

    has @.defs;
    has @.refs;
```

#### Str \$.kind

One of the following values: `language`, `programs` or `type`.

#### Str @.subkinds

Can take one of the following values: `<infix prefix postfix circumfix postcircumfix listop sub method term routine trait submethod constant variable twigil declarator quote>`. In addition, it can take the value of the
meta part in a `X<>` definition, which is unambiguous.

#### Str @.categories

It is assigned with what `classify-index` returns. Its value will be one of the following (\$subkind
is obtained using `parse-definition`):

If `$subkind` is one of `<infix prefix postfix circumfix postcircumfix listop>`, `@categories` will be set to `operator`. Otherwise, it will be set to `$subkind`.

#### Str \$.name

Name of the Pod. Usually is set to the filename without the file extension `.pod6`.

If it's a definition, it will be set to the value correspondent to `$name` returned by `parse-definition-header`.

#### Str \$.url

Static url to the processed file. Its value can be specified in the Pod configuration as follows:

```perl6
=begin pod :link<some-link>

...

=end pod
```

It will be set to `/$kind/$link`. By default `$link=$filename`.

#### \$.pod

Perl6 Pod Structure (obtained using `Pod::Load` module).

### Bool \$.pod-is-complete

Indicates if the Pod represented by the `Perl6::Documentable` object is completed. A Pod is completed if
represents the whole pod source, that's to say, the `$.pod` attribute contains an entire pod file.

It will be considered incomplete if the `Perl6::Documentable` object represents a definition. In that case
the `$.pod` attribute will only contain the part corresponding to the definition.

#### Str \$.summary

Subtitle of the pod.

```perl6
=begin pod :tag<tutorial>

=TITLE  Perl 6 by example

=SUBTITLE A basic introductory example of a Perl 6 program

...

=end pod

```

In this case `$summary="A basic introductory example of a Perl 6 program"`.

#### \$.origin

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

#### Array @.defs

This is one of the most important attributes of a `Perl6::Documentable` object. It contains all definitions
found and processed corresponding to the pod of `$.origin` stored in more `Perl6::Documentable` objects. In
general, all of them will have `pod-is-complete` set to `false`.

#### Array @.refs

It contains all references found and processed corresponding to pod `$.origin`, stored in more `Perl6::Documentable` objects. In
general, all of them will have `pod-is-complete` set to `false`.

#### method human-kind

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

#### method url

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

#### method categories

```perl6
method categories (
) return Array
```

Returns `@.categories`. If `@.categories` if it's not defined, sets `@.categories` to the same value
as `@.subkinds`.

#### method parseDefinitionHeader

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

#### method classifyIndex

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

#### method find-definitions

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

#### method find-references

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

#### method register-reference

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

#### method get-documentables

```perl6
method get-documentables (
) Returns Array
```

Returns all `Documentable` objects (`@.defs`+`@.refs`).

## Perl6::Documentable::Registry

```perl6
    has @.documentables;
    has Bool $.composed = False;
    has %!cache;
    has %!grouped-by;
    has @!kinds;
    has $.tg;

    has $.pod-cache;
    has $.use-cache = False;

    has Bool $.verbose;
```

#### @.documentables

If it's not composed, it will contain only `Documentable` objects with `pod-is-complete` set to true. After being composed, it will contain all `Documentable` objects obtained from processing the previous ones.

#### Bool \$.composed

Boolean showing if the registry is composed.

#### %!cache

This Hash object works as a cache for `lookup` method. When you call the first time that method, using a `$by` Str, a `$by` key is created and all `Documentables` object are classified by that attribute in another Hash (that another Hash is the value associated to the key `$by`).

#### %!grouped-by

This is quite similar to the previous one. It stores all documentables objects classified by theirs attributes, but it only returns groups of them (the other one was a two layer hash structure).

#### @!kinds

Array containing all different types of `$kinds` found in every `Documentable`. Set when `compose` is called.

#### \$.tg

Instance of a Perl6::TypeGraph object (from this [module](https://github.com/antoniogamiz/Perl6-TypeGraph)).

This object is responsible of give us the correct categories and subkinds of a type. For instance, it sets the category of a type to `domain-specific`, `exception`, etc., which is used in the index generation.

#### \$.pod-cache

Cache of pod files. Object from [Pod::To::Cached](https://github.com/finanalyst/pod-cached).

#### submethod BUILD

In this method the attribute `$.tg` is configured as specified in the [documentation module](https://github.com/antoniogamiz/Perl6-TypeGraph).

In addition, if `$.use-cache` is set to `True`, then a cache will be created and updated.

### Processing methods

#### method add-new

```perl6
method add-new(
    *%args
) return Perl6::Documentable;
```

Creates a `Documentable` object passing `|%args` to the constructor and returns the new object.

#### method load

```perl6
method load(
    Str $path
) return Pod::Named;
```

Loads a pod from a file. If `$.use-cache` is set to `True`, `Pod::Cached` will be used. Otherwise, `Pod::Load`.

#### method compose

```perl6
method compose (
) return Boolean;
```

Initialize `@!kinds` and join all `Documentable` objects found in every element of `@!documentables`.

After that, sets `$!composed` to True and returns it.

#### method process-pod-source

```perl6
method process-pod-source(
    Str        :$kind,
    Pod::Block :$pod,
    Str        :$filename
) return Perl6::Documentable;
```

This method takes a pod source, initializes `Perl6::Documentable` object with it and add
it to the registry. Returns the `Documentable` created.

How it is initialized?

- `$name` is set to `$filename` by default. If a `=TITLE` element is found, then it is set to its contents. In addition, if `$kind` is `type`, `$name` will be set to the last word of the content.
- `$summary` is set to the content of the first `=SUBTITLE` element.
- `$pod-is-complete` is set to `True` (becuase it's a complete pod).
- `$url` is set to `/$kind/$link`, where `$link` is set to `$filename` is a `link` value is not set in the pod configuration.
- `$kind` and `$subkinds` are set to `$kind`.

#### method process-pod-source

```perl6
method process-pod-source(
    Str     :$topdir,
    Str     :$dir,
    Boolean :$output
) return Mu;
```

Reads all pod files in `$topdir/$dir/` and calls `process-pod-source` (with `$kind=$dir`) once for each file.

If `$output` is set to `True`, then a progress message will be printed every time a new file is processed.

### Consulting methods

#### method get-kinds

```perl6
method get-kinds(
) return Array
```

Returns an array containing all `kind` values after processing the pod collection. Currently there are only 6 different values: `[language programs type syntax reference routine]`.

#### method grouped-by

```perl6
method grouped-by(
    Str $what
) returns Array[Documentable];
```

The first time it is called it initializes a key `$what`, with the result of classifying `@!documentables` by `$what`. `$what` needs to be the name of an attribute of a `Documentable` object, `kind`, for instance.

This result is stored in `%!grouped-by` so the next time it's called it will be faster.

#### method lookup

```perl6
method lookup(
    Str $what,
    Str $by
) returns Array[Documentable];
```

This method uses `%!cache`, which is a two-layer Hash object. That means you first consult it with one key, `$by`, and that returns another Hash which is consulted with the key `$what`.

So, `$by` has to be the name of an attribute of `Documentable`. Elements in `@!documentables` will be classified following that attribute. Then, `$what` must be one of the possible values that the attribute `$by` can take.

In this setting, `lookup` will return the `Documentable` objects in `@!documentables` whose attribute `$by` is equal to `$what`.

This result is stored in `%!grouped-by` so the next time it's called it will be faster.

### Indexing methods

All `*-index` methods are used to generate the main index in the doc site ([Language](https://docs.perl6.org/language.html), [Types](https://docs.perl6.org/types.html), ...).

#### method programs-index

```perl6
method programs-index (
) return Array[Hash];
```

It takes all `Documentable` objects in the `Registry` with `kind` set to `programs`.
After that it makes a `map` and creates the follwing `Hash` for each one:

```
%(
    name    => ...
    url     => ...
    summary => ...
)
```

Note: `...` means that is the attribute of the Documentable.

#### method language-index

```perl6
method language-index (
) return Array[Hash];
```

It takes all `Documentable` objects in the `Registry` with `kind` set to `language`.
After that it makes a `map` and creates the following `Hash` for each one:

```
%(
    name    => ...
    url     => ...
    summary => ...
)
```

Note: `...` it means that is the attribute of the Documentable.

#### method type-index

```perl6
method type-index (
) return Array[Hash];
```

It takes all `Documentable` objects in the `Registry` with `kind` set to `type`.
After that it makes a `map` and creates the follwing `Hash` for each one:

```
%(
    name     => ...
    url      => ...
    subkinds => ...
    summary  => ...
    subkind  => first subkind
)
```

Note: `...` means that is the attribute of the Documentable.

#### method type-subindex

```perl6
method type-subindex (
  Str :$category
) return Array[Hash];
```

Same as `type-index` but you can filter by `$category`. You can pass one of the following
categories: `<basic composite domain-specific exceptions>`.

#### method routine-index

```perl6
method routine-index (
) return Array;
```

It takes all `Documentable` objects in the `Registry` with `kind` set to `routine`.
After that it makes a `map` and creates the following `Hash` for each one:

```
%(
    name     => ...
    url      => ...
    subkinds => ...
    origins  => $from
)
```

Where `$from` is an array of `[$name, $url]` containing the names and urls of the `Documentable`
objects where the routine was found.

Note: `...` means that is the attribute of the Documentable.

#### method routine-subindex

```perl6
method routine-subindex (
  Str :$category
) return Array[Hash];
```

Same as `routine-index` but you can filter by `$category`. You can pass one of the following
categories: `<sub method term operator trait submethod>`.

#### method generate-search-index

```perl6
method generate-search-index (
) return Array[Str];
```

Returns an array whose items are in the following format: `{category: "", value: "", url: ""}`.

This array is initialized calling `lookup` with every possible value of `kind` (see `get-kinds`). `category`
is set to `kind` or to `subkind` if `lookup` returns more than one `Documentable` object. `value` is set to the
name of the `Documentable` and `url` too.

You can see the current search index [here](https://gist.github.com/antoniogamiz/05971277d081c4806c7cc3867a66b1b4).

## Perl6::Documentable::To::HTML

#### sub header-html

```perl6
sub header-html (
    Str $current-selection,
    Str $pod-path
) return Str;
```

Returns the HTML header for every page. `$current-selection` has to be set to one element of the menu. If that element has a submenu, it will be created too.

`$pod-path` is the path relative to `doc` with the extension `.pod6`. Used to the edit buttom url.

#### sub footer-html

```perl6
sub footer-html (
    Str $pod-path
) return Str;
```

Returns the HTML footer for every page. `$pod-path` is the path relative to `doc` with the extension `.pod6`. Used to the edit buttom url.

## Perl6::Utils

Some auxiliar functions to ease the job.

#### sub recursive-dir

```perl6
sub recursive-dir (
    Str :$dir
) return Array;
```

This function returns a List of IO objects. Each IO object is one file in `$dir`.

#### sub get-pod-names

```perl6
sub get-pod-names (
    Str :$topdir
    Str :$dir
) return Array;
```

What does the following array look like? An array of sorted pairs

- the sort key defaults to the base filename stripped of '.pod6'.
- any other sort order has to be processed separately as in 'Language'.

The sorted pairs (regardless of how they are sorted) must consist of:

- key: base filename stripped of its ending .pod6
- value: filename relative to the "$topdir/$dir" directory

#### sub pod-path-from-url

```perl6
sub pod-path-from-url (
    Str $url
) return Str;
```

Determine the path to source POD from the POD object's url attribute.

#### sub svg-for-file

```perl6
sub svg-for-file (
    Str $file
) return Str;
```

Return the SVG for the given file, without its XML header

For instance, given: `t/html/basic.svg`, it will return `t/html/basic-without-xml.svg`.

#### URL logic

This one is quite a mess, it will be a todo for now.

## Resources

### Templates

#### [head.html](template/head.html)

Some meta info and stylesheet for every page in the doc site.

#### [header.html](template/header.html)

Header of every HTML page in the doc site. `MENU` will be replaced by `Perl6::Documentable::To::HTML` with the
generated menu.

#### [footer.html](template/footer.html)

Footer for every page in the site. `SOURCEURL`, `SOURCECOMMIT` and `DATETIME` will be replaced by `Perl6::Documentable::To::HTML`.

#### [search_template.js](template/search_template.js)

Search funtion for the doc site. It uses [Sift 4](https://siderite.blogspot.com/2014/11/super-fast-and-accurate-string-distance.html) algorithm for strings comparison.

### HTML

In this directory you can find the CSS files used by the site, the images (graphs generated by `Perl6::TypeGraph`) will be here too. All HTML generated files will be also stored in here.

In addition, there is a `.htaccess` file used by the server (#TODO: document it).

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

Copyright 2019 Perl6 Team

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
