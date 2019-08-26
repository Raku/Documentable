unit module Perl6::Documentable::DocPage::Primary;

use Perl6::Documentable::Utils::IO;
use URI::Escape;
use Pod::Utilities::Build;
use Perl6::Documentable;

class X::Documentable::TypeNotFound is Exception {
    has $.type;
    method message() {
        "$.type entry not found in type-graph.txt file."
    }
}

class Perl6::Documentable::DocPage::Primary::Language
    does Perl6::Documentable::DocPage {

    method render($registry, $name) {
        state @docs = $registry.documentables.grep({.kind eq Kind::Language});
        my $doc = @docs.grep({.name eq $name})[0];
        my $pod-path = pod-path-from-url($doc.url);
        return %(
            document => $doc.pod,
            url      => $doc.url
        );
    }
}

class Perl6::Documentable::DocPage::Primary::Programs
    does Perl6::Documentable::DocPage {

    method render($registry, $name) {
        state @docs = $registry.documentables.grep({.kind eq Kind::Programs});
        my $doc = @docs.grep({.name eq $name})[0];
        my $pod-path = pod-path-from-url($doc.url);
        return %(
            document => $doc.pod,
            url      => $doc.url
        );
    }

}

class Perl6::Documentable::DocPage::Primary::Type
    does Perl6::Documentable::DocPage {

    method typegraph-fragment($podname is copy) {
        # zef relative paths to resources
        my $filename = "resources/template/tg-fragment.html".IO.e   ??
                       "resources/template/tg-fragment.html"        !!
                       %?RESOURCES<template/tg-fragment.html>;
        state $template = slurp $filename;
        my $svg;
        if ("html/images/type-graph-$podname.svg".IO.e) {
            $svg = svg-for-file(
                zef-path("html/images/type-graph-$podname.svg")
            );
        } else {
            $svg = "<svg></svg>";
            $podname  = "404";
        }
        my $figure = $template.subst("PATH", $podname)
                            .subst("ESC_PATH", uri_escape($podname))
                            .subst("SVG", $svg);

        return [
            pod-heading("Type Graph"),
            Pod::Raw.new: :target<html>,
            contents => [$figure]
        ]
    }

    method roles-done-by-type($registry, $doc) {
        my $type       = $registry.tg.types{$doc.name};
        my @roles-todo = $type.roles;
        my %roles-seen;
        while @roles-todo.shift -> $role {
            next unless $registry.routines-by-type{$role.name};
            next if %roles-seen{$role.name}++;
            @roles-todo.append: $role.roles;
            $doc.pod.contents.append:
                pod-heading("Routines supplied by role $role"),
                pod-block(
                    "{$doc.name} does role ",
                    pod-link($role.name, "/type/{$role.name}"),
                    ", which provides the following routines:",
                ),
                $registry.routines-by-type{$role.name}.list.map({.pod}),
            ;
        }
    }

    method parent-class($registry, $doc) {
        my $type    = $registry.tg.types{$doc.name};
        for $type.mro.skip -> $class {
            if $type.name ne "Any" {
                next if $class.name ~~ "Any" | "Mu";
            }
            next unless $registry.routines-by-type{$class.name};
            $doc.pod.contents.append:
                pod-heading("Routines supplied by class $class"),
                pod-block(
                    "{$doc.name} inherits from class ",
                    pod-link($class.name, "/type/{$class}"),
                    ", which provides the following routines:",
                ),
                $registry.routines-by-type{$class.name}.list.map({.pod}),
            ;
        }
    }

    method roles-done-by-parent-class($registry, $doc) {
        my $type    = $registry.tg.types{$doc.name};
        for $type.mro.skip -> $class {
            for $class.roles -> $role {
                next unless $registry.routines-by-type{$role.name};
                $doc.pod.contents.append:
                    pod-heading("Routines supplied by role $role"),
                    pod-block(
                        "{$doc.name} inherits from class ",
                        pod-link($class.name, "/type/{$class}"),
                        ", which does role ",
                        pod-link($role.name, "/type/{$role}"),
                        ", which provides the following routines:",
                    ),
                    $registry.routines-by-type{$role.name}.list.map({.pod}),
                ;
            }
        }
    }

    #| Completes a type pod with inherited routines
    method compose-type($registry, $doc) {

        die X::Documentable::TypeNotFound.new(:type("$doc.name"))
        unless $registry.tg.types{$doc.name};

        $doc.pod.contents.append: self.typegraph-fragment($doc.name);

        # supply all routines
        self.roles-done-by-type($registry, $doc);
        self.parent-class($registry, $doc);
        self.roles-done-by-parent-class($registry, $doc);

        # doc is already prepared
        $doc;
    }

    method render($registry, $name) {
        state @docs = $registry.documentables.grep({.kind eq Kind::Type});
        # we should never modify an element of the registry because it could
        # be used by other part of the system
        my $doc = @docs.grep({.name eq $name})[0].clone;
        self.compose-type($registry, $doc);
        my $pod-path = pod-path-from-url($doc.url);
        return %(
            document => $doc.pod,
            url      => $doc.url
        );
    }

}