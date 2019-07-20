## Perl6::Documentable

`Perl6::Documentable` represents a piece of Perl 6 that is documented.

This class is the base for `Perl6::Documentable::File` and `Perl6::Documentable::Derived`. You should use both of them instead, since this one only represents what every documented piece must have.

### Attributes

#### Str name

Identifier of the object (it does not to be unique).

#### Pod pod

The pod representing the documented piece. It does not have to be the whole file, it could be only a piece of one (if it's a `Perl6::Documentable::Derived`,for instance).

#### enum kind

Enum taking one of the following values: `<Type Language Programs Syntax Reference Routine>`.

This atributte tells you where the documented piece comes from:

- `Type`: from Type dir.
- `Language`: from Language dir.
- `Programs`: from Program dir.
- `Syntax`: section of a pod file.
- `Routine`: section of a pod file.
- `Reference`: from a `X<> element.

#### Str @subkinds

Inside the same kind, there's more than one type. For instance, those documented pieces whose `kind` is set to `Routine`, can be either a `sub`, or a `method` or both.

#### Str @categories

Quite similar to the previous one, mostly used for types, to classify then in `basic`, `composite`, etc.

### Methods

#### english-list

This should be a external function because it only transfrom `@!subkinds` into a "readable` string.

Example:

```perl6
my $doc = Perl6::Documentable.new(
    kind     => Kind::Routine,
    subkinds => ["sub", "method"]
);

$doc.english-list # output: sub and method
```

#### human-kind

Similar to the previous none, tries to give you a Str describing a bit the documented piece (to use in a title or something like that).

```perl6
my $doc = Perl6::Documentable.new(
    kind       => Kind::Routine,
    categories => ["operator"],
    subkinds   => ["ternary"]
);

$doc.human-kind() # output: ternary operator
```
