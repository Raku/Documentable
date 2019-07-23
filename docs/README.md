## Introduction

As you may have noticed, this is a little complex. There are a lot of things going on but believe me, it's very easy once you see the big picture.

All the process is splitted in two parts:

- Gather all the necessary information to generate the site.
- Actually generate the site.

Let's see each one of these steps:

## Gather the information

We have a big directory full of pod files waiting for us to recollect all its data. To do that, we use [Perl6::Documentable](/perl6-documentable.md), the parent class for everything documented. But there are different type of things that can be documented, every is represented by the same class? Nop, there are two different subclasses at the moment:

- [Perl6::Documentable::File](/perl6-documentable-file.md)
- [Perl6::Documentable::Derived](/perl6-documentable-derived.md)

Please read those pages before continuing.

So we have one `Perl6::Documentable::File` object per file, and that object is full of `Perl6::Documentable::Derived` instances. But there are almost 400 files in the directory, how we handle with all that info? Do not worry! [Perl6::Documentable::Registry](/perl6-documentable-registry.md) is here to resolve all your problems.

As you may have guessed, this class stores every `Perl6::Documentable::File` object and its definitions. I recommend you to read its page to know what goodies it has for you.

## Generate the site

Once we have a `Perl6::Documentable::Registry` correctly initialized it's time to generate some HTML documents.

Every type of generated document does the `Perl6::Documentable::DocPage` role (defined in `Perl6::Documentable`, see [Perl6::Documentable](/perl6-documentable.md)).

To generate a specific page you only to need a `Perl6::Documentable::Registry` and create one of those objects and call `render` method with the specified arguments.

See [Perl6::Documentable::DocPage](/perl6-documentable-docpage) to get more information.
