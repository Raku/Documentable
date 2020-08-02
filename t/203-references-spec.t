use Documentable;
use Documentable::Primary;
use Documentable::Index;
use Pod::Load;

use Test;

plan *;

#==========================================================================
# ======================= HEADER SPPECIFICATION ===========================
#==========================================================================

subtest "Operators category" => {
    constant @operator = <infix prefix postfix circumfix postcircumfix listop>;
    for @operator -> $operator {
        is parse-header("=head2 The name $operator"),
        {
            uri => ("/routine/name"),
            name => "name",
            categories => ['operator'],
            subkinds => [$operator],
            kind => Kind::Routine
        }, "=head2 The name $operator";

        is parse-header("=head2 $operator name"),
        {
            uri => ("/routine/name"),
            name => "name",
            categories => ['operator'],
            subkinds => [$operator],
            kind => Kind::Routine
        }, "=head2 $operator name";
    }
}

subtest "Routine category" => {
    constant @routine = <sub method term routine submethod trait>;
    for @routine -> $routine {
        is parse-header("=head2 The name $routine"),
        {
            uri => ("/routine/name"),
            name => "name",
            categories => [$routine],
            subkinds => [$routine],
            kind => Kind::Routine
        }, "=head2 The name $routine";

        is parse-header("=head2 $routine name"),
        {
            uri => ("/routine/name"),
            name => "name",
            categories => [$routine],
            subkinds => [$routine],
            kind => Kind::Routine
        }, "=head2 $routine name";
    }
}

subtest "Syntax category" => {
    constant @syntax = <twigil constant variable quote declarator>;
    for @syntax -> $syntax {
        is parse-header("=head2 The name $syntax"),
        {
            uri => ("/syntax/name"),
            name => "name",
            categories => [$syntax],
            subkinds => [$syntax],
            kind => Kind::Syntax
        }, "=head2 The name $syntax";

        is parse-header("=head2 $syntax name"),
        {
            uri => ("/syntax/name"),
            name => "name",
            categories => [$syntax],
            subkinds => [$syntax],
            kind => Kind::Syntax
        }, "=head2 $syntax name";
    }
}

subtest "Special headers =headn X<>" => {
        is parse-header("=head2 X<text>"),
        {
            uri => ("/syntax/text"),
            name => "text",
            categories => [],
            subkinds => [],
            kind => Kind::Syntax
        }, "=head2 X<text>";

        is parse-header("=head2 X<text|a>"),
        {
            uri => ("/syntax/text"),
            name => "text",
            categories => ["a"],
            subkinds => ["a"],
            kind => Kind::Syntax
        }, "=head2 X<text|a>";

        is parse-header("=head2 X<text|a,b>"),
        {
            uri => ("/syntax/b"),
            name => "b",
            categories => ["a", "b"],
            subkinds => ["a", "b"],
            kind => Kind::Syntax
        }, "=head2 X<text|a,b>";

        is parse-header("=head2 X<text|a,b;c>"),
        {
            uri => ("/syntax/b"),
            name => "b",
            categories => ["a", "b"],
            subkinds => ["a", "b"],
            kind => Kind::Syntax
        }, "=head2 X<text|a,b;c>";

        is parse-header("=head2 X<text|a,b;c,d>"),
        {
            uri => ("/syntax/b"),
            name => "b",
            categories => ["a", "b"],
            subkinds => ["a", "b"],
            kind => Kind::Syntax
        }, "=head2 X<text|a,b;c,d>";

        is parse-header("=head2 X<|a>"),
        {
            uri => ("/syntax/"),
            name => "",
            categories => ["a"],
            subkinds => ["a"],
            kind => Kind::Syntax
        }, "=head2 X<|a>";

        is parse-header("=head2 X<|a,b>"),
        {
            uri => ("/syntax/b"),
            name => "b",
            categories => ["a", "b"],
            subkinds => ["a", "b"],
            kind => Kind::Syntax
        }, "=head2 X<|a,b>";

        is parse-header("=head2 X<|a,b;c>"),
        {
            uri => ("/syntax/b"),
            name => "b",
            categories => ["a", "b"],
            subkinds => ["a", "b"],
            kind => Kind::Syntax
        }, "=head2 X<|a,b;c>";

        is parse-header("=head2 X<|a,b;c,d>"),
        {
            uri => ("/syntax/b"),
            name => "b",
            categories => ["a", "b"],
            subkinds => ["a", "b"],
            kind => Kind::Syntax
        }, "=head2 X<|a,b;c,d>";
}

#==========================================================================
# ===================== REFERENCE SPPECIFICATION ==========================
#==========================================================================

is parse-ref("X<onlytext>"),
    {
        uri => ("/type/avoid#index-entry-onlytext"),
        name => ("onlytext"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "Only text reference";

is parse-ref("X<text|word>"),
    {
        uri => ("/type/avoid#index-entry-word-text"),
        name => ("word"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "Text and single meta-group with one value";

is parse-ref("X<text|a, b>"),
    {
        uri => ("/type/avoid#index-entry-a__b-text"),
        name => ("b (a)"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "Text and single meta-group with two values separated by ', '";

is parse-ref("X<text|a,b>"),
    {
        uri => ("/type/avoid#index-entry-a_b-text"),
        name => ("b (a)"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "Text and single meta-group with two values separated by ','";

is parse-ref("X<text|a,b,c>"),
    {
        uri => ("/type/avoid#index-entry-a_b_c-text"),
        name => ("c (a b)"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "Text and single meta-group with more than two values";

subtest "Text and two meta-groups with one value each" => {
    is parse-ref("X<text|a;b>")[0],
        {
            uri => ("/type/avoid#index-entry-a-b-text"),
            name => ("a"),
            categories => ['reference'],
            subkinds => ['reference'],
            kind => (Kind::Reference)
        }, "First meta-group interpreted as X<text|a>";

    is parse-ref("X<text|a;b>")[1],
        {
            uri => ("/type/avoid#index-entry-a-b-text"),
            name => ("b"),
            categories => ['reference'],
            subkinds => ['reference'],
            kind => (Kind::Reference)
        }, "Second meta-group interpreted as X<text|b>";
}

is parse-ref("X<|onlymeta>"),
    {
        uri => ("/type/avoid#index-entry-onlymeta"),
        name => ("onlymeta"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "Only meta reference";

is parse-ref("X<|a, b>"),
    {
        uri => ("/type/avoid#index-entry-a__b"),
        name => ("b (a)"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "No text and single meta-group with two values separated by ', '";

is parse-ref("X<|a,b>"),
    {
        uri => ("/type/avoid#index-entry-a_b"),
        name => ("b (a)"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "No text and single meta-group with two values separated by ','";

is parse-ref("X<|a,b,c>"),
    {
        uri => ("/type/avoid#index-entry-a_b_c"),
        name => ("c (a b)"),
        categories => ['reference'],
        subkinds => ['reference'],
        kind => (Kind::Reference)
    }, "No text and single meta-group with more than two values";

subtest "No text and two meta-groups with one value each" => {
    is parse-ref("X<|a;b>")[0],
        {
            uri => ("/type/avoid#index-entry-a-b"),
            name => ("a"),
            categories => ['reference'],
            subkinds => ['reference'],
            kind => (Kind::Reference)
        }, "First meta-group interpreted as X<|a>";

    is parse-ref("X<|a;b>")[1],
        {
            uri => ("/type/avoid#index-entry-a-b"),
            name => ("b"),
            categories => ['reference'],
            subkinds => ['reference'],
            kind => (Kind::Reference)
        }, "Second meta-group interpreted as X<|b>";
}

#==========================================================================
# This functions are helpers to get the expected results providing only a
# simple string with the reference
#==========================================================================

sub parse-ref($ref) {
    my $pod = pod($ref);
    my $primary = Documentable::Primary.new(:filename(""), :source-path(""), :$pod);
    my @got = [];
    for $primary.refs -> $index {
        @got.push(
            %(
                uri        => $index.url,
                name       => $index.name,
                categories => $index.categories,
                subkinds   => $index.subkinds,
                kind       => $index.kind
            )
        )
    }
    return @got;
}

sub parse-header($header) {
    my $pod = pod($header);
    my $primary = Documentable::Primary.new(:filename(""), :source-path(""), :$pod);
    my @got = [];
    for $primary.defs -> $def {
        @got.push(
            %(
                uri        => $def.url,
                name       => $def.name,
                categories => $def.categories,
                subkinds   => $def.subkinds,
                kind       => $def.kind
            )
        )
    }
    return @got;
}

sub pod($pod-string) {
    my $pod = load(qq{
    =begin pod :kind("type") :subkind("") :category("")

    =TITLE Random text to avoid

    =SUBTITLE documentable dying

    $pod-string

    =end pod
    });

    return $pod[0];
}

done-testing;