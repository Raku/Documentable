# To do some issues

* Perl6::Utils is too generic. Move it down to Perl6::Documentable::Utils or spin it off somewhere else.

* Also, not clear what those functions do. Some, like print-time, look a bit useless.

* There are two type of functions: IO and URL. Maybe create two different modules. In general, try and refactor because some of them might better belong as a method.

* process-pod-source might better be the BUILD or `new` method for Pod::Documentable.

* Maybe there should be a Perl6::Documentable::Collection. Many variables like cache and others are handed around and it would be better if they would be encapsulated.

* Many of the other routines in Processing would better be in Pod::Documentable. parse-definition-header, for example, is better used there.

* find-references and create references should better be spun off to a new module so that they can be properly defined and tested. Probably change the ifs to multiple dispatch instead, much clearer that way.

* $pod-cache is a package lexical. It should be part of a class. global variables → action at a distance → bad

* Improve synopsis for all modules.

* Grammars are classes, need to be documented and tested too.

* name and compose-name should maybe use a better token, like for instance perl6 identifier. (also better composite-name or something like that)

* def1 is capturing the (t|t)

* Maybe def1,def2,def3 should be called something different.

* Not clear syntax is exhaustive. For instance, "do" as a prefix and other statement prefixes are not in the "language" area.

* Also, Perl6::Documentable::Processing::Grammar is less than awesome (LTA). Pod::Documentable::Heading::Grammar maybe, or PodUnit Grammar, or something like that.

* Update should probably not be a class, and again, this should actually just be part of a Pod::Documentable. $topdir is what we are hauling back and forth, and also the registry. So maybe this should be part of a Perl6::Documentable::Collection class.

* Maybe we should parallelize writing files? They are independent of each other, we might get a small improvement...

* Remember to set the authorship documentation of every section correctly.

* compose-type is too long, and should probably be split in several subroutines.

* is type-graph cached?

* Did you take something from Pod::Htmlify?

* All text that mentions Perl 6 and somesuch should probably be left to specific modules for the documentation. If we keep it that way, it can't be too generic.

* The wrapper also needs git, because it calls it. I'm not sure that's specified anywhere, and it might also too specific. Wrapper should go, probably.

* CLI uses also wget. This might not work for Windows; or tar or anything. Not clear what those assets are, also? If it's run from the actual documentation dir, they might want to have their own assets... 

* Do you need to run Pod::To::Cached as an external program? You can capture output of anything (or request specific functionality)

* rm -rf is very dangerous. There might be production-only stuff in html. Keep track of what you've created, and delete only that.