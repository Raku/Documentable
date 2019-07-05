use v6.c;

use Perl6::Documentable;
use Perl6::Utils;
use Pod::Load;
use Pod::Utilities;
use Pod::Utilities::Build;
use Perl6::TypeGraph;
use Pod::To::Cached;
use URI::Escape;
unit class Perl6::Documentable::Registry:ver<0.0.1>;


=begin pod

=head1 NAME

Perl6::Documentable::Registry

=head1 SYNOPSIS

=begin code :lang<perl6>

use Perl6::Documentable::Registry;

=end code

=head1 DESCRIPTION

Perl6::Documentable::Registry collects pieces of Perl 6 documentation
in the form of Perl6::Documentable objects, and enables
lookups of these pieces of documentation.

The general usage pattern is:

* create an instance with .new();
* add lots of documentation sections with `add-new`
* call .compose
* query the registry with .lookup, .get-kinds and .grouped-by

=head1 AUTHOR

Antonio <antoniogamiz10@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Antonio

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

has @.documentables;
has Bool $.composed = False;
has %!cache;
has %!grouped-by;
has @!kinds;
has $.tg;
has %!routines-by-type;

has $.pod-cache;
has $.use-cache = False;
has Bool $.verbose;

# setup

submethod BUILD (:$use-cache?, :$verbose?, :$topdir? = "doc") {
    $!verbose = $verbose || False;
    $!tg = Perl6::TypeGraph.new-from-file;
    if ($use-cache) {
        $!use-cache = True;
        $!pod-cache = Pod::To::Cached.new(:source($topdir), :path(".pod-cache"), :$verbose);
        $!pod-cache.update-cache;
    }
}

method add-new(*%args) {
    die "Cannot add something to a composed registry" if $.composed;
    @!documentables.append: my $d = Perl6::Documentable.new(|%args);
    $d;
}

method load($path) {
    if ($!use-cache) {
        # set path to Pod::To::Cached format
        my $new-path = $path.subst(/doc\//, "")
                       .subst(/\.pod6/, "").lc;
        $!pod-cache.pod( $new-path )[0];
    } else {
        load($path)[0];
    }
}

# consulting logic

method compose() {
    my @new-docs = [ ($_.defs.Slip, $_.refs.Slip).Slip for @!documentables ];
    @!documentables = flat @!documentables, @new-docs;
    @!kinds = @.documentables>>.kind.unique;

    #| this needs to be first because is used by compose-type
    %!routines-by-type = self.lookup("routine", :by<kind>)
    .classify({.origin ?? .origin.name !! .name});

    # compose types
    for self.lookup("type", :by<kind>).list -> $doc {
        self.compose-type($doc);
    }

    $!composed = True;
}

method grouped-by(Str $what) {
    die "You need to compose this registry first" unless $.composed;
    %!grouped-by{$what} ||= @!documentables.classify(*."$what"());
}

method lookup(Str $what, Str :$by!) {
    unless %!cache{$by}:exists {
        for @!documentables -> $d {
            %!cache{$by}{$d."$by"()}.append: $d;
        }
    }
    %!cache{$by}{$what} // [];
}

method get-kinds() {
    die "You need to compose this registry first" unless $.composed;
    @!kinds;
}

# =================================================================================
# processing logic
# =================================================================================

method process-pod-source(:$kind, :$pod, :$filename) {
    my Str $link = $pod.config<link> // $filename;

    # set proper name ($filename by default)
    my $name = recurse-until-str(first-title($pod.contents)) || $filename;
    $name = $name.split(/\s+/)[*-1] if $kind eq "type";
    note "$filename does not have a =TITLE" unless $name;

    # summary is obtained from =SUBTITLE
    my $summary = recurse-until-str(first-subtitle($pod.contents)) || '';
    note "$filename does not have a =SUBTITLE" unless $summary;

    # type-graph sets the correct subkind and categories
    my %type-info;
    if $kind eq "type" {
        if $!tg.types{$name} -> $type {
            %type-info = :subkinds($type.packagetype), :categories($type.categories);
        }
        else {
            %type-info = :subkinds<class>;
        }
    }

    my $origin = self.add-new(
        :$kind,
        :$name,
        :$pod,
        :url("/$kind/$link"),
        :$summary,
        :pod-is-complete(True),
        :subkinds($kind),
        |%type-info
    );

    $origin.find-definitions();
    $origin.find-references();

    # Special handling for 5to6-perlfunc
    if $link.contains('5to6-perlfunc') {
      find-p5to6-functions(:$pod, :$origin, :url("/$kind/$link"));
    }

    return $origin;
}

method process-pod-dir(:$topdir, :$dir) {
    my @pod-sources = get-pod-names(:$topdir, :$dir);

    my $kind  = $dir.lc;
    $kind = 'type' if $kind eq 'native';

    for @pod-sources.kv -> $num, (:key($filename), :value($file)) {
        printf "% 4d/%d: % -40s => %s\n", $num+1, +@pod-sources, $file.path, "$kind/$filename" if $!verbose;
        my $pod = self.load($file.path);
        self.process-pod-source(:$kind, :$pod, :$filename);
    }
}

# =================================================================================
# Composing types logic
# =================================================================================

#| Completes a type pod with inherited routines
method compose-type($doc) {
    sub href_escape($ref) {
        # only valid for things preceded by a protocol, slash, or hash
        return uri_escape($ref).subst('%3A%3A', '::', :g);
    }    

    my $pod     = $doc.pod;
    my $podname = $doc.name;
    my $type    = $!tg.types{$podname};
    
    {return;} unless $type;

    $pod.contents.append: self.typegraph-fragment($podname);

    my @roles-todo = $type.roles;
    my %roles-seen;
    while @roles-todo.shift -> $role {
        next unless %!routines-by-type{$role.name};
        next if %roles-seen{$role.name}++;
        @roles-todo.append: $role.roles;
        $pod.contents.append:
            pod-heading("Routines supplied by role $role"),
            pod-block(
                "$podname does role ",
                pod-link($role.name, "/type/{href_escape ~$role.name}"),
                ", which provides the following routines:",
            ),
            %!routines-by-type{$role.name}.list.map({.pod}),
        ;
    }

    for $type.mro.skip -> $class {
        if $type.name ne "Any" {
            next if $class.name ~~ "Any" | "Mu";
        }
        next unless %!routines-by-type{$class.name};
        $pod.contents.append:
            pod-heading("Routines supplied by class $class"),
            pod-block(
                "$podname inherits from class ",
                pod-link($class.name, "/type/{href_escape ~$class}"),
                ", which provides the following routines:",
            ),
            %!routines-by-type{$class.name}.list.map({.pod}),
        ;
        for $class.roles -> $role {
            next unless %!routines-by-type{$role.name};
            $pod.contents.append:
                pod-heading("Routines supplied by role $role"),
                pod-block(
                    "$podname inherits from class ",
                    pod-link($class.name, "/type/{href_escape ~$class}"),
                    ", which does role ",
                    pod-link($role.name, "/type/{href_escape ~$role}"),
                    ", which provides the following routines:",
                ),
                %!routines-by-type{$role.name}.list.map({.pod}),
            ;
        }
    }

}

#| Returns the fragment to show the typegraph image
method typegraph-fragment($podname) {
    state $template = slurp "template/tg-fragment.html";
    my $svg-path;
    if ("html/images/type-graph-$podname.svg".IO.e) {
        $svg-path = "html/images/type-graph-$podname.svg";
    } else {
        $svg-path = "html/images/404.svg";
    }
    my $figure = $template.subst("PATH", $podname)
                          .subst("ESC_PATH", uri_escape($podname))
                          .subst("SVG", svg-for-file($svg-path)); 
    
    return [pod-heading("Type Graph"), 
            Pod::Raw.new: :target<html>, contents => [$figure]]
} 

# =================================================================================
# Indexing logic
# =================================================================================

method programs-index() {
    self.lookup("programs", :by<kind>).map({%(
        name    => .name, 
        url     => .url, 
        summary => .summary 
    )});
}

method language-index() {
    self.lookup("language", :by<kind>).map({%(
        name    => .name, 
        url     => .url, 
        summary => .summary
    )});
}

method type-index() {
    [
        self.lookup("type", :by<kind>)\
        .categorize(*.name).sort(*.key)>>.value
        .map({%(
            name     => .[0].name, 
            url      => .[0].url,
            subkinds => .map({.subkinds // Nil}).flat.unique.List,
            summary  => .[0].summary,
            subkind  => .[0].subkinds[0]
        )}).cache.Slip
    ].flat
}

method type-subindex(:$category) {
    self.lookup("type", :by<kind>)\
    .grep({$category ⊆ .categories})\ # XXX
    .categorize(*.name).sort(*.key)>>.value
    .map({%(
        name     => .[0].name, 
        url      => .[0].url,
        subkinds => .map({slip .subkinds // Nil}).unique.List,
        summary  => .[0].summary,
        subkind  => .[0].subkinds[0]
    )})
}

method routine-index {
    [
        self.lookup("routine", :by<kind>)\
        .categorize(*.name).sort(*.key)>>.value
        .map({%(
            name     => .[0].name,
            url      => .[0].url,
            subkinds =>.map({.subkinds // Nil}).flat.unique.List,
            origins  => $_>>.origin.map({.name, .url}).List
        )}).cache.Slip
    ].flat   
}

method routine-subindex(:$category) {
    self.lookup("routine", :by<kind>)\
    .grep({$category ⊆ .categories})\ # XXX
    .categorize(*.name).sort(*.key)>>.value
    .map({%(
        subkinds => .map({slip .subkinds // Nil}).unique.List,
        name     => .[0].name, 
        url      => .[0].url,
        origins  => $_>>.origin.map({.name, .url}).List
    )})
}

# =================================================================================
# search index logic
# =================================================================================

#| workaround for 5to6-perlfunc
my %p5to6-functions;
sub find-p5to6-functions(:$pod!, :$url, :$origin) {
  if $pod ~~ Pod::Heading && $pod.level == 2  {
      # Add =head2 function names to hash
      my $func-name = ~$pod.contents[0].contents;
      %p5to6-functions{$func-name} = 1;
  }
  elsif $pod.?contents {
      for $pod.contents -> $sub-pod {
          find-p5to6-functions(:pod($sub-pod), :$url, :$origin) if $sub-pod ~~ Pod::Block;
      }
  }
}

method generate-search-index() {
    sub escape(Str $s) {
        $s.trans([</ \\ ">] => [<\\/ \\\\ \\">]);
    }

    my @items = self.get-kinds.map(-> $kind {
        self.lookup($kind, :by<kind>).categorize({escape .name})\
            .pairs.sort({.key}).map: -> (:key($name), :value(@docs)) {
                qq[[\{ category: "{( @docs > 1 ?? $kind !! @docs.[0].subkinds[0] ).wordcase}", value: "$name", url: " {rewrite-url(@docs.[0].url).subst(｢\｣, ｢%5c｣, :g).subst('"', '\"', :g).subst(｢?｣, ｢%3F｣, :g) }" \}\n]]
            }
    }).flat;

    # Add p5to6 functions to JavaScript search index
    @items.append: %p5to6-functions.keys.map( {
      my $url = "/language/5to6-perlfunc#" ~ $_.subst(' ', '_', :g);
        qq[[\{ category: "5to6-perlfunc", value: "{$_}", url: "{$url}" \}\n]]
    });

    return @items;
}