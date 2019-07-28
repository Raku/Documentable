## Perl6::Documentable::Registry

This class is our source of information. It contains all we need to know to generate the documentation. Whatever you want to generate, you should an instance of this object.

You can create one easily with:

```perl6
use Perl6::Documentable::Registry;

my $registry = Perl6::Documentable::Registry.new(
    topdir    => "doc",                # doc containing the pod collection
    dirs      => ["Type", "Language"], # dirs to process
    verbose   => True,
    use-cache => True                  # recommended
);

# to complete the processing and initialize some attributes
$registry.compose;
```

### Attributes

#### Perl6::Documentable::File @.documentables

One per pod file found in every specified `dir` of `topdir`.

#### Perl6::Documentable::Derived @.definitions

**All** definitions found in every pod file.

`.compose` needs to be executed before use this attribute.

#### Perl6::Documentable::Index @.references

**All** references found in every pod file.

`.compose` needs to be executed before use this attribute.

#### Bool \$.composed

Flag to indicate if the registry is composed. Once it's composed, you should not edite it.

#### \$.tg

Instance of `Perl6::TypeGraph` class.

#### %.routines-by-type

Every key in this Hash is a name of a Type and its value is all routines (`Perl6::Documentable::Derived` with kind set to Kind::Routine) found in that type.

`.compose` needs to be executed before use this attribute.

#### Pod::To::Cached %.cache

Cache from `Pod::To::Cached`.

#### Bool \$.use-cache

Flag to enable the use of a cache.

#### Bool \$.verbose

Prints progress information.

#### Str \$.topdir

Dir containing the whole pod collection.

### Methods

#### method add-new

```perl6
method add-new(
    Perl6::Documentable::File :$doc
) return Perl6::Documentable::File
```

Adds a new `Perl6::Documentable::File` object to `@.documentbles` and returns it.

#### method load

```perl6
method load(
    Str :$path
) return Pod::Block::Named
```

Loads a pod. If `$.use-cache` is set to True, the pod will be loaded from there.

#### method process-pod-dir

```perl6
method process-pod-dir(
    Str :$dir
) return Array
```

Read all pods from `$.topdir` and create a `Perl6::Documentable::File` for each one and add them to `@.documentables`.

#### method compose

```perl6
method compose(
) return Bool
```

Initialize `@.definitions` and `%.routines-by-type`.

#### method lookup

```perl6
method lookup(
    Str $what,
    Str $by
) return Hash
```

This is your best friend, `lookup` will give you everything you want to know. This method classify all the content in `@.defs` and `@.definitions`. How is that done? By `$by` (pun intended). Once is classified, you must specify what value of `$by` the returned objects must have.

_Important:_ you must execute `.compose` before using this method.

Let's see an example:

```
# suppose we have a registry ready
my $registry = Perl6::Documentable::Registry.new(...);

# query all Documentables with kind set to Routine
$registry.lookup(Kind::Routine, :by<kind>);

# query all Documentables with kind set to Type
$registry.lookup(Kind::Type, :by<kind>);
```
