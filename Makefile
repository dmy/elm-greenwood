static := web/static

all: server app hash

server:
	cargo build --release

app:
	cd web && elm make --optimize --output=static/elm.js src/Main.elm
	elm-minify web/static/elm.js --overwrite

hash:
	@rm -f $(static)/*.*.js
	@rm -f $(static)/*.*.css
	@for i in $(static)/*.js $(static)/*.css; do \
		md5=$$(md5sum $$i | cut -c1-8); \
		ext=$${i##*.}; \
		filename=$${i%$$ext}; \
		basename=$$(basename $$filename); \
		echo "Creating $$filename$$md5.$$ext"; \
		ln -sfr $$i $$filename$$md5.$$ext; \
		sed -i "s/$$basename[0-9a-z]*.$$ext/$$basename$$md5.$$ext/" $(static)/index.html; \
	done

clean:
	rm -f $(static)/*.js
	rm -f $(static)/*.*.js
	rm -f $(static)/*.*.css
