html: assets
	perl6 -Ilib bin/documentable -v -c

assets:
	./app.pl assets

run:
	@echo "Starting local server…"
	./app-start

init-highlights:
	ATOMDIR="./highlights/atom-language-perl6";  \
	if [ -d "$$ATOMDIR" ]; then (cd "$$ATOMDIR" && git pull); \
	else git clone https://github.com/perl6/atom-language-perl6 "$$ATOMDIR"; \
	fi; cd highlights; npm install .; npm rebuild