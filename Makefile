GAME=Bomb-Jack-II

URL=https://www.worldofspectrum.org/pub/sinclair/games/b/BombJackII.tzx.zip

PNG=$(GAME).png
SCL=$(GAME).scl
SCR=$(GAME).scr
TAP=Bomb\ Jack\ 2.tap
TRD=$(GAME).trd
TZX=Bomb\ Jack\ 2.tzx
ZIP=BombJackII.tzx.zip

HOB_BOOT=boot.$$B
HOB_SCRN=screenz.$$C
HOB_DATA=data.$$C

all: $(SCL) $(PNG)

$(SCL): $(TRD)
	trd2scl '$<' '$@'

$(TRD): $(HOB_BOOT) $(HOB_SCRN) $(HOB_DATA)
	$(eval TMP_FILE=$(shell mktemp))

	createtrd $(TMP_FILE)

# Calculate the total program size in sectors and write it to the first file (offset 13)
# Got to use the the octal notation since it's the only format of binary data POSIX printf understands
# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/printf.html#tag_20_94_13
	total_size=0; \
	for i in $(patsubst %, '%', $+); do \
		size=$$(dd if="$$i" bs=1 skip=14 count=1 2>/dev/null | od -An -t u1); \
		total_size=$$(( total_size + size )); \
		hobeta2trd "$$i" $(TMP_FILE); \
	done; \
	printf "\\$$(printf %o $$total_size)" | dd of=$(TMP_FILE) bs=1 seek=13 conv=notrunc status=none

# Remove remaining files from the catalog (fill the bytes starting at offset 16 with zeroes)
	dd if=/dev/zero of=$(TMP_FILE) bs=1 seek=16 count=$$((($(words $^) - 1) * 16)) conv=notrunc status=none

	mv $(TMP_FILE) '$@'

$(HOB_BOOT): boot.000
	0tohob '$<'

boot.000: boot.tap
	tapto0 -f '$<'

boot.tap: boot.bas
	bas2tap -sboot -a10 '$<' '$@'

boot.bas: src/boot.bas boot.bin
# Replace the __LOADER__ placeholder with the machine codes with bytes represented as {XX}
	sed "s/__LOADER__/$(shell hexdump -ve '1/1 "{%02x}"' boot.bin)/" '$<' > '$@'

boot.bin: src/boot.asm
	pasmo --bin '$<' '$@'

$(HOB_SCRN): screenz.000
	0tohob '$<'

screenz.000: screenz.bin
	binto0 '$<' 3

screenz.bin: $(SCR)
	laser521 -d '$<' '$@'

$(PNG): $(SCR)
	SOURCE_DATE_EPOCH=1970-01-01 convert '$<' -scale 200% '$@'

$(SCR): data-000.bin
	cp '$<' '$@'

$(HOB_DATA): data.000
	0tohob '$<'

data.000: data.bin
	binto0 '$<' 3

data.bin: data-001.bin \
          data-002.bin \
          data-003.bin \
          data-004.bin \
          data-005.bin \
          data-006.bin \
          data-007.bin \
          data-008.bin \
          data-009.bin
	cat $^ > '$@'

data-%.bin: headless.%
	$(eval TMP_DIR=$(shell mktemp -d))
	(cd $(TMP_DIR) && 0tobin $(CURDIR)/$< && mv headless.bin $(CURDIR)/$@)
	rmdir $(TMP_DIR)

headless.000 \
headless.001 \
headless.002 \
headless.003 \
headless.004 \
headless.005 \
headless.006 \
headless.007 \
headless.008 \
headless.009: $(TAP)
# Cannot use the `-f` flag of tapto0 because it will make
# headerless files from the same *.tap override each other
	$(eval TMP_DIR=$(shell mktemp -d))
	(cd $(TMP_DIR) && tapto0 $(CURDIR)/$(TAP) && mv *.00* $(CURDIR))
	rmdir $(TMP_DIR)

$(TAP): $(TZX)
	tzx2tap '$<'

$(TZX): $(ZIP)
	unzip -u '$<' && touch -c '$@'

$(ZIP):
	wget $(URL)

clean:
	rm -f \
		*.00* \
		*.\$$B \
		*.\$$C \
		*.bas \
		*.bin \
		*.scl \
		*.scr \
		*.tap \
		*.trd \
		*.tzx \
		*.zip
