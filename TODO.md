# To do some issues

- [ ] name and compose-name should maybe use a better token, like for instance perl6 identifier. (also better composite-name or something like that). Maybe def1,def2,def3 should be called something different.

_Status:_ I'm working hard on this one. Think of good names is the hardest thing in programming I think.

- [ ] find-references and create references should better be spun off to a new module so that they can be properly defined and tested. Probably change the ifs to multiple dispatch instead, much clearer that way.

_Status:_ This logic is currently disabled. First I want to get working all the others URLs. After that, I will add this part following the given feedback.

- [ ] Perl6::Utils is too generic. Move it down to Perl6::Documentable::Utils or spin it off somewhere else.

_Status:_ this will be handled when the url problem is solved.

- [ ] Not clear syntax is exhaustive. For instance, "do" as a prefix and other statement prefixes are not in the "language" area.

_Status:_ discussing with @JJ.

- [ ] compose-type is too long, and should probably be split in several subroutines.

_Status:_

- [ ] Do you need to run Pod::To::Cached as an external program? You can capture output of anything (or request specific functionality)

_Status:_ Discussing with Richard in [this issue](https://github.com/finanalyst/pod-cached/issues/16).

- [x] Also, not clear what those functions do. Some, like print-time, look a bit useless. There are two type of functions: IO and URL. Maybe create two different modules. In general, try and refactor because some of them might better belong as a method.

_Status:_ That function prints the time (...) a specific part of the generation process has took. It has been moved to CLI, the only place it's used. I do not delete it because I think is important to know how much time each part of the process takes.

As for the URL, the status is the same than the previous one.

- [x] process-pod-source might better be the BUILD or `new` method for Perl6::Documentable.

_Status:_ completed. See `Perl6::Documentable::File`.

- [x] Maybe there should be a Perl6::Documentable::Collection. Many variables like cache and others are handed around and it would be better if they would be encapsulated.

_Status:_ This was done since the beginning, it is called `Perl6::Documentable::Registry`.

- [x] Many of the other routines in Processing would better be in Perl6::Documentable. parse-definition-header, for example, is better used there.

_Status:_ completed. See `Perl6::Documentable::File`

_Status:_

- [x] \$pod-cache is a package lexical. It should be part of a class. global variables → action at a distance → bad

_Status:_ completed. See `Perl6::Documnetable::Registry`.

- [x] Improve synopsis for all modules. _Status:_ To avoid overload the code files, I have a better documentation under doc/ dir. It contains more examples and explanations about "why do that" rather than "what does that".

- [x] Grammars are classes, need to be documented and tested too.

_Status:_ completed. [Tests](https://github.com/antoniogamiz/Perl6-Documentable/blob/master/t/204-grammar.t) and [documentation](https://github.com/antoniogamiz/Perl6-Documentable/blob/master/docs/reference/perl6-documentable-heading-grammar.md).

- [x] def1 is capturing the (t|t)

_Status:_ Solved.

- [x] Also, Perl6::Documentable::Processing::Grammar is less than awesome (LTA). Pod::Documentable::Heading::Grammar maybe, or PodUnit Grammar, or something like that.

- [x] Update should probably not be a class, and again, this should actually just be part of a Pod::Documentable. \$topdir is what we are hauling back and forth, and also the registry. So maybe this should be part of a Perl6::Documentable::Collection class.

_Status:_ That module has been deleted because the previous refactor has made possible to reduced the necessary logic to replicate the same functionality in CLI. Also, I do not think move it to Perl6::Documentable is a good idea because Perl6::Documentable knwos nothing about how to generate it HTML documents.

- [x] Maybe we should parallelize writing files? They are independent of each other, we might get a small improvement...

_Status:_ I have tried to parallelize everything. Two problems:

- `pod2html` cannot be parallelized. See [this issue](https://github.com/perl6/Pod-To-HTML/issues/63).
- Write the file only takes around 10 seconds. I have tried to parallelize it but the results are even slower.

- [x] Remember to set the authorship documentation of every section correctly.

_Status:_ All authors are included in the main README.md.

- [x] is type-graph cached?

_Status:_ Yes, it is.

- [x] All text that mentions Perl 6 and somesuch should probably be left to specific modules for the documentation. If we keep it that way, it can't be too generic.

_Status:_ See new docs.

- [x] The wrapper also needs git, because it calls it. I'm not sure that's specified anywhere, and it might also too specific. Wrapper should go, probably.

_Status:_ Clarified in the dependencies section. This wrapper is needed because each and every one of the pages has this part in common. As it uses templates, the user can specify the ones he wants.

- [x] CLI uses also wget. This might not work for Windows; or tar or anything. Not clear what those assets are, also? If it's run from the actual documentation dir, they might want to have their own assets...

_Status:_ Clarified everything in the README.

- [x] rm -rf is very dangerous. There might be production-only stuff in html. Keep track of what you've created, and delete only that.

_Status:_ I have added a warning in the documentation of that option.
