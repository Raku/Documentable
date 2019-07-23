## Grammar and Actions

In [Perl6::Documentable](/docs/reference/perl6-documentable.md) you that `Syntax` and `Routine` kinds are set depending on the situation.

As you may know from [Perl6::Documentable::Derived](/docs/reference/perl6-documentable-derived.md), we process certain headers as definitions. That definitions are used to generate pages like [this one](https://docs.perl6.org/routine/ff). If you take a look you will see that jusst above each heading appears `From *`. What that means is that piece of documentation has come from a complete pod (one of `Type`, `Language` or `Programs`).

You can also see that in some places appears `(Operators)` or terms like that. We use `subkinds` and `categories` attributes to set those values.

But whow tells you what subkinds a definition has? `Perl6::Documentable::Heading::Grammar` and `Perl6::Documentable::Heading::Action` do. So, if you want to know the metadata of a heading, you only need to pass the content of the heading to the grammar. Here an example:

```perl6
use Perl6::Documentable::File;

=begin pod

=head2 The @ infix

=end pod


my %metadata = Perl6::Documentable::File.parse-definition-header(
    heading => $=pod[0].contents[0]
);

say %metadada;

# OUTPUT: {categories => (operator), kind => Routine, name => @, subkinds => (infix)}
```

See [parse-definition-header](/docs/reference/perl6-documentable-file.md#method-parse-definition-header) to learn more.
