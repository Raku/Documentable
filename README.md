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

### Bool \$.section

To breakdown a Language doc list by sections. Currently, in the official doc, is always set to [False](https://github.com/perl6/doc/blob/f328984196e33e4aec2d4c0a94e973a04447689f/htmlify.p6#L318) because there is not any Pod with that config.

To set it to True you have to create a Pod like this:

```perl6
=begin pod :class<section-start>

...

=end pod

```

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
