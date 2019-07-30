## Perl6::Documentable::File is Perl6::Documentable

Main documented piece. Each and every one fo these objects correspond to an entire pod file.

You can create one by typing:

```perl6
use Pod::Load;
use Perl6::TypeGraph;
use Perl6::Documentable::File;

my $tg  = Perl6::TypeGraph.new-from-file;
my $pod = load("Type/int.pod6")[0];
my $doc = Perl6::Documentable::File.new(
    dir      => "Type", # used to determine the kind
    filename => "int" , # Type/int.pod6 => int
    tg       => $tg   , # to complete the information about Type pods
    pod      => $pod  , # the pod
);
```

Now you have your object initialized (`kind`, `subkind`, etc.). But if you want to get more information, like the definitions inside that pod, you need to call `.process()`

```perl6
$doc.process();

# and you already can use the definitions!
say $doc.defs.map({.name})
```

### Attributes

#### Str summary

A brief description of the pod content. It comes from `=SUBTITLE` element.

#### Str \$.url

Path where the HTML page of this object will be written. The URL assigned is `/$.kind.gist/$.name`.

#### Perl6::Documentable::Derived @.defs

Array containing all definitions found in the entire pod. Each and every one of the definitions is represented with a `Perl6::Documentable::Derived` object.

#### Perl6::Documentable::Index @.refs

Array containing all references found in the entire pod. Each and every one of the definitions is represented with a `Perl6::Documentable::Index` object.

### Methods

#### method process

```perl6
method process (
) return Mu;
```

This method simply call `find-definitions`. If you want to process more anything else, you should add it here.

#### method parse-definition-header

```perl6
sub parse-definition-header(
    Pod::Heading :$heading
) return Hash
```

This method takes a `Pod::Heading` object and return a non-empty hash if it's a definition. This hash is something like this:

```perl6
%(
    name       => ...
    kind       => ...
    subkinds   => ...
    categories => ...
)
```

The value of these parameters depends on the definition found, these are the four different types you will find:

```perl6
=head2 The <name> <subkind>
Example:
=head2 The C<my> declarator
```

```perl6
=head2 <subkind> <name>
Example:
=head2 sub USAGE
```

```perl6
=head X<<name>|<subkind>>
```

First two types are parsed by [Perl6::Documentable::Processing::Grammar](lib/Perl6/Documentable/Processing/Grammar.pm6) and the last one does not need to be parsed because it will be considered a valid definition no matter what you type inside.

#### method find-definitions

```perl6
method find-definitions(
        :$pod,
    Int :$min-level = -1, # do not used this
) return Int
```

This function takes `$.pod` and initializes `@.defs` with all definitions found in the pod. It runs through the pod content and looks for valid headings.

When we find a new definition, a new `Perl6::Documentable::Derived` object is created and initialized to:

- `$origin`: to `$origin`.
- `$pod`: It will be populated with the pod section corresponding to the definition and its subdefinitions (all valid headers with a greater level until one with the same or lower level is found).
- `$pod-is-complete`: to `false` beacuse it's a definition.
- `name`, `kind`, `subkinds` and `categories` to the output of [parse-definition-header](#sub-parse-definition-header).

Example:

```perl6
use Pod::Load;
use Perl6::TypeGraph;

my $pod = load("type/Any.pod6").first;
my $tg  = Perl6::TypeGraph.new-from-file;

my $origin = Perl6::Documentable::File.new(
    dir      => "Type", # used to determine the kind
    filename => "Any" , # Type/int.pod6 => int
    tg       => $tg   , # to complete the information about Type pods
    pod      => $pod  , # the pod
);

$origin.find-definitions(
    :$pod
)

# this array contains the names of all
# definitions found
say $origin.defs.map({.name});
```

#### method find-references

```perl6
method find-references(
        :$pod,
) return Mu
```

This function takes `$.pod` and initializes `@.refs` with all references found in the pod.

Example:

```perl6
use Pod::Load;
use Perl6::TypeGraph;

my $pod = load("type/Any.pod6").first;
my $tg  = Perl6::TypeGraph.new-from-file;

my $origin = Perl6::Documentable::File.new(
    dir      => "Type", # used to determine the kind
    filename => "Any" , # Type/int.pod6 => int
    tg       => $tg   , # to complete the information about Type pods
    pod      => $pod  , # the pod
);

$origin.find-references(
    :$pod
)

# this array contains the names of all
# references found
say $origin.refs.map({.name});
```

#### method url

```perl6
method url(
) return Str;
```

It simply returns `/$.kind/$.name`.

For instance, for the previous Documentable it would return:

```perl6
$doc.url # output: /type/Any
```
