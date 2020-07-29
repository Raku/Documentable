# Changelog

## [Unreleased](https://github.com/Raku/Documentable/tree/HEAD)

[Full Changelog](https://github.com/Raku/Documentable/compare/v1.2.7...HEAD)

**Fixed bugs:**

- Documentable uses the default template instead of the template that's in the current directory. [\#102](https://github.com/Raku/Documentable/issues/102)
- Pod::To::HTML version [\#100](https://github.com/Raku/Documentable/issues/100)
- Classes with colons on the middle do not have the GitHub URL right [\#87](https://github.com/Raku/Documentable/issues/87)
- Some web pages in this site do not seem to be rendered [\#76](https://github.com/Raku/Documentable/issues/76)

**Closed issues:**

- Inspect the documentation of this repo and fix typos [\#77](https://github.com/Raku/Documentable/issues/77)
- Either make config required in Documentable::To::HTML::Wrapper or add reasonable defaults [\#66](https://github.com/Raku/Documentable/issues/66)
- Homepage menu generation is hardcoded [\#63](https://github.com/Raku/Documentable/issues/63)
- Give config.json a less generic name [\#62](https://github.com/Raku/Documentable/issues/62)
- New options to work with the default cache [\#34](https://github.com/Raku/Documentable/issues/34)
- Documentable freezes when node is not present [\#27](https://github.com/Raku/Documentable/issues/27)
- Use a real templating engine [\#19](https://github.com/Raku/Documentable/issues/19)
- Index pages descriptions [\#6](https://github.com/Raku/Documentable/issues/6)
- You can either install the `sass` command... [\#4](https://github.com/Raku/Documentable/issues/4)

**Merged pull requests:**

- Fix name of `template` directory [\#124](https://github.com/Raku/Documentable/pull/124) ([paultcochrane](https://github.com/paultcochrane))
- Replace wget -\> curl in README [\#122](https://github.com/Raku/Documentable/pull/122) ([paultcochrane](https://github.com/paultcochrane))
- Remove trailing whitespace [\#121](https://github.com/Raku/Documentable/pull/121) ([paultcochrane](https://github.com/paultcochrane))
- Version 1.3.1 [\#105](https://github.com/Raku/Documentable/pull/105) ([antoniogamiz](https://github.com/antoniogamiz))
- New version, 1.3.0 [\#101](https://github.com/Raku/Documentable/pull/101) ([antoniogamiz](https://github.com/antoniogamiz))

## [v1.2.7](https://github.com/Raku/Documentable/tree/v1.2.7) (2020-06-27)

[Full Changelog](https://github.com/Raku/Documentable/compare/v1.2.5...v1.2.7)

**Fixed bugs:**

- Executable file "documentable" needs to respond with no args [\#94](https://github.com/Raku/Documentable/issues/94)
- Can't install Documentable because of a test failure [\#92](https://github.com/Raku/Documentable/issues/92)
- Documentable freezes on setup [\#90](https://github.com/Raku/Documentable/issues/90)
- Test 305 hangs up [\#84](https://github.com/Raku/Documentable/issues/84)
- Documentable fails with 2020.02 [\#79](https://github.com/Raku/Documentable/issues/79)

**Closed issues:**

- Include native dependencies in META6.json [\#96](https://github.com/Raku/Documentable/issues/96)
- @files check could probably be moved up [\#91](https://github.com/Raku/Documentable/issues/91)
- $c flag is not used [\#89](https://github.com/Raku/Documentable/issues/89)
- Create a function for initialization of cache [\#83](https://github.com/Raku/Documentable/issues/83)
- Add function to delete cache [\#81](https://github.com/Raku/Documentable/issues/81)
- Auto-deploy of Documentable docker container [\#75](https://github.com/Raku/Documentable/issues/75)
- Change all pointers to this new repo [\#74](https://github.com/Raku/Documentable/issues/74)
- DISTRIBUTION has disappeared, making this error with 2019.11 [\#71](https://github.com/Raku/Documentable/issues/71)
- It would be nice to read, by default, a config.json in the same directory as the documentation [\#61](https://github.com/Raku/Documentable/issues/61)
- dir "html" is present in the repo dir after installation but is not needed then [\#45](https://github.com/Raku/Documentable/issues/45)
- Add AppVeyor/Windows CI checks [\#39](https://github.com/Raku/Documentable/issues/39)
- missing three files with "setup" command [\#33](https://github.com/Raku/Documentable/issues/33)

**Merged pull requests:**

- Develop [\#99](https://github.com/Raku/Documentable/pull/99) ([antoniogamiz](https://github.com/antoniogamiz))
- Windows: get tests to pass [\#98](https://github.com/Raku/Documentable/pull/98) ([softmoth](https://github.com/softmoth))
- New version, 1.2.6 [\#97](https://github.com/Raku/Documentable/pull/97) ([antoniogamiz](https://github.com/antoniogamiz))
- Resolve paths before comparing them in t/100-utils.t [\#93](https://github.com/Raku/Documentable/pull/93) ([Prince213](https://github.com/Prince213))
- Ignore and remove comma config files [\#88](https://github.com/Raku/Documentable/pull/88) ([stoned](https://github.com/stoned))
- Remove verbose hanging Registry [\#86](https://github.com/Raku/Documentable/pull/86) ([tinmarino](https://github.com/tinmarino))

## [v1.2.5](https://github.com/Raku/Documentable/tree/v1.2.5) (2019-12-01)

[Full Changelog](https://github.com/Raku/Documentable/compare/v1.0.1...v1.2.5)

**Closed issues:**

- Create a string-to-kind mapping [\#69](https://github.com/Raku/Documentable/issues/69)
- Documentable::Config is not tested [\#68](https://github.com/Raku/Documentable/issues/68)
- search\_template.js of the local directory is not used [\#67](https://github.com/Raku/Documentable/issues/67)
- Tests are failing using "old" template configuration...  [\#64](https://github.com/Raku/Documentable/issues/64)
- Add documentation about config file [\#60](https://github.com/Raku/Documentable/issues/60)
- Add a new NEWURL template to use for the old documentation [\#56](https://github.com/Raku/Documentable/issues/56)
- Transition to Raku [\#54](https://github.com/Raku/Documentable/issues/54)
- Local templates are not used [\#53](https://github.com/Raku/Documentable/issues/53)
- Verbose and version \(documentable -V\) does not work "correctly" [\#49](https://github.com/Raku/Documentable/issues/49)
- Adapt document URLs [\#46](https://github.com/Raku/Documentable/issues/46)
- Lots of pages don't get PODPATH substituted [\#44](https://github.com/Raku/Documentable/issues/44)
- master fails testing [\#41](https://github.com/Raku/Documentable/issues/41)
- typo in update messsage [\#38](https://github.com/Raku/Documentable/issues/38)
- Need a short version of option '--version' for 'documentable' [\#36](https://github.com/Raku/Documentable/issues/36)
- Assets are still downloaded from the old repo [\#35](https://github.com/Raku/Documentable/issues/35)
- Progress bars do no reach the end in routine and syntax files [\#30](https://github.com/Raku/Documentable/issues/30)
- Can't install module [\#29](https://github.com/Raku/Documentable/issues/29)
- Add test for documentable not changing URLs in documents [\#28](https://github.com/Raku/Documentable/issues/28)
- Inconsistent index escaping [\#26](https://github.com/Raku/Documentable/issues/26)
- IRC chat link missing [\#25](https://github.com/Raku/Documentable/issues/25)
- Some pages are regenerated always [\#24](https://github.com/Raku/Documentable/issues/24)
- Error \(possibly\) when updating homepage.pod6 [\#23](https://github.com/Raku/Documentable/issues/23)
- Make progress bars optional [\#22](https://github.com/Raku/Documentable/issues/22)
- documentable update is not working [\#20](https://github.com/Raku/Documentable/issues/20)
- type-graph.txt can't be in the main directory [\#12](https://github.com/Raku/Documentable/issues/12)

**Merged pull requests:**

- Fix primary name construction [\#59](https://github.com/Raku/Documentable/pull/59) ([stoned](https://github.com/stoned))
- Fix typos [\#58](https://github.com/Raku/Documentable/pull/58) ([stoned](https://github.com/stoned))
- Fix -a/--all option description [\#57](https://github.com/Raku/Documentable/pull/57) ([stoned](https://github.com/stoned))
- Fix verbose option in tests and -V option, fix \#49 [\#50](https://github.com/Raku/Documentable/pull/50) ([antoniogamiz](https://github.com/antoniogamiz))
- Adapt document URL, close \#46 [\#48](https://github.com/Raku/Documentable/pull/48) ([antoniogamiz](https://github.com/antoniogamiz))
- add missing doc category [\#43](https://github.com/Raku/Documentable/pull/43) ([tbrowder](https://github.com/tbrowder))
- add sort to ensure order of file names is correct [\#40](https://github.com/Raku/Documentable/pull/40) ([tbrowder](https://github.com/tbrowder))
- it's hex, not just dec [\#32](https://github.com/Raku/Documentable/pull/32) ([shintakezou](https://github.com/shintakezou))
- tweak grammar [\#31](https://github.com/Raku/Documentable/pull/31) ([tbrowder](https://github.com/tbrowder))

## [v1.0.1](https://github.com/Raku/Documentable/tree/v1.0.1) (2019-08-29)

[Full Changelog](https://github.com/Raku/Documentable/compare/925a4d1a39e6cc9dc757a08d8ba891932ea99100...v1.0.1)

**Closed issues:**

- CONTENT\_CLASS is not substituted in HTML [\#17](https://github.com/Raku/Documentable/issues/17)
- Terminal::Spinners is not added to dependencies [\#15](https://github.com/Raku/Documentable/issues/15)
- `documentable update` does not find new files [\#14](https://github.com/Raku/Documentable/issues/14)
- Strip out Perl6:: [\#11](https://github.com/Raku/Documentable/issues/11)
- Documentable start should show a progress bar or something [\#2](https://github.com/Raku/Documentable/issues/2)
- documentable should have a --version  [\#1](https://github.com/Raku/Documentable/issues/1)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
