CONFIG_SUB_REV = 3d5db9ebe860
BINUTILS_VER   = 2.32
GCC_VER        = ss-9-20190831
MUSL_VER       = git-6ad514e4e278f0c3b18eb2db1d45638c9af1c07f
GMP_VER        = 6.1.2
MPC_VER        = 1.1.0
MPFR_VER       = 4.0.2
LINUX_VER      = 4.4.190

GNU_SITE      = https://ftp.gnu.org/pub/gnu
GCC_SITE      = $(GNU_SITE)/gcc
BINUTILS_SITE = $(GNU_SITE)/binutils
GMP_SITE      = $(GNU_SITE)/gmp
MPC_SITE      = $(GNU_SITE)/mpc
MPFR_SITE     = $(GNU_SITE)/mpfr
ISL_SITE      = http://isl.gforge.inria.fr/
MUSL_SITE     = https://www.musl-libc.org/releases
LINUX_SITE    = https://cdn.kernel.org/pub/linux/kernel

DL_CMD = curl -fsSL --retry 10 --retry-connrefused -o

SOURCES   = sources
HOST      = $(if $(NATIVE),$(TARGET))
BUILD_DIR = build/$(if $(HOST),$(HOST),local)/$(TARGET)
OUTPUT    = $(CURDIR)/output$(if $(HOST),-$(HOST))
REL_TOP   = ../../..

-include config.mak

SRC_DIRS = gcc-$(GCC_VER) binutils-$(BINUTILS_VER) musl-$(MUSL_VER) \
	$(if $(GMP_VER),gmp-$(GMP_VER)) \
	$(if $(MPC_VER),mpc-$(MPC_VER)) \
	$(if $(MPFR_VER),mpfr-$(MPFR_VER)) \
	$(if $(ISL_VER),isl-$(ISL_VER)) \
	$(if $(LINUX_VER),linux-$(LINUX_VER))

all:

clean:
	rm -rf gcc-* binutils-* musl-* gmp-* mpc-* mpfr-* isl-* build build-* linux-*

distclean: clean
	rm -rf sources

# Rules for downloading and verifying sources. Treat an external SOURCES path as
# immutable and do not try to download anything into it.

ifeq ($(SOURCES),sources)

$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gmp*)): SITE = $(GMP_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpc*)): SITE = $(MPC_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpfr*)): SITE = $(MPFR_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/isl*)): SITE = $(ISL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/binutils*)): SITE = $(BINUTILS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gcc*)): SITE = $(GCC_SITE)/$(basename $(basename $(notdir $@)))
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/musl*)): SITE = $(MUSL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-4*)): SITE = $(LINUX_SITE)/v4.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-3*)): SITE = $(LINUX_SITE)/v3.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-2.6*)): SITE = $(LINUX_SITE)/v2.6

$(SOURCES):
	mkdir -p $@

$(SOURCES)/config.sub: | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) \
		"http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=$(CONFIG_SUB_REV)"
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && sha1sum -c $(CURDIR)/hashes/$(notdir $@).$(CONFIG_SUB_REV).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

$(SOURCES)/%: hashes/%.sha1 | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) $(SITE)/$(notdir $@)
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && sha1sum -c $(CURDIR)/hashes/$(notdir $@).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

endif

# Rules for extracting and patching sources, or checking them out from git.

gcc-ss-%:
	rm -rf $@.tmp
	mkdir $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@).tar.xz \
		"https://gcc.gnu.org/pub/gcc/snapshots/$(subst gcc-ss-,,$(notdir $@))/$(subst ss-,,$(notdir $@)).tar.xz"
	cd $@.tmp && sha1sum -c $(CURDIR)/hashes/$(notdir $@).tar.xz.sha1
	tar -xf $@.tmp/$(notdir $@).tar.xz
	mv $(subst ss-,,$(notdir $@)) $(notdir $@)
	touch $(notdir $@)
	rm -rf $@.tmp

musl-git-%:
	rm -rf $@.tmp
	mkdir $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@).tar.gz \
		"https://git.musl-libc.org/cgit/musl/snapshot/$(subst git-,,$(notdir $@)).tar.gz"
	cd $@.tmp && sha1sum -c $(CURDIR)/hashes/$(notdir $@).tar.gz.sha1
	tar -xf $@.tmp/$(notdir $@).tar.gz
	mv $(subst git-,,$(notdir $@)) $(notdir $@)
	touch $(notdir $@)
	rm -rf $@.tmp

%: $(SOURCES)/%.tar.gz | $(SOURCES)/config.sub
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar zxf - ) < $<
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp/$@ && patch -p1 )
	test ! -f $@.tmp/$@/config.sub || cp -f $(SOURCES)/config.sub $@.tmp/$@
	rm -rf $@
	touch $@.tmp/$@
	mv $@.tmp/$@ $@
	rm -rf $@.tmp

%: $(SOURCES)/%.tar.bz2 | $(SOURCES)/config.sub
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar jxf - ) < $<
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp/$@ && patch -p1 )
	test ! -f $@.tmp/$@/config.sub || cp -f $(SOURCES)/config.sub $@.tmp/$@
	rm -rf $@
	touch $@.tmp/$@
	mv $@.tmp/$@ $@
	rm -rf $@.tmp

%: $(SOURCES)/%.tar.xz | $(SOURCES)/config.sub
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar Jxf - ) < $<
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp/$@ && patch -p1 )
	test ! -f $@.tmp/$@/config.sub || cp -f $(SOURCES)/config.sub $@.tmp/$@
	rm -rf $@
	touch $@.tmp/$@
	mv $@.tmp/$@ $@
	rm -rf $@.tmp

extract_all: | $(SRC_DIRS)

# Rules for building.

ifeq ($(TARGET),)

all:
	@echo TARGET must be set via config.mak or command line.
	@exit 1

else

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/Makefile: | $(BUILD_DIR)
	ln -sf $(REL_TOP)/litecross/Makefile $@

$(BUILD_DIR)/config.mak: | $(BUILD_DIR)
	printf >$@ '%s\n' \
	"TARGET = $(TARGET)" \
	"HOST = $(HOST)" \
	"MUSL_SRCDIR = $(REL_TOP)/musl-$(MUSL_VER)" \
	"GCC_SRCDIR = $(REL_TOP)/gcc-$(GCC_VER)" \
	"BINUTILS_SRCDIR = $(REL_TOP)/binutils-$(BINUTILS_VER)" \
	$(if $(GMP_VER),"GMP_SRCDIR = $(REL_TOP)/gmp-$(GMP_VER)") \
	$(if $(MPC_VER),"MPC_SRCDIR = $(REL_TOP)/mpc-$(MPC_VER)") \
	$(if $(MPFR_VER),"MPFR_SRCDIR = $(REL_TOP)/mpfr-$(MPFR_VER)") \
	$(if $(ISL_VER),"ISL_SRCDIR = $(REL_TOP)/isl-$(ISL_VER)") \
	$(if $(LINUX_VER),"LINUX_SRCDIR = $(REL_TOP)/linux-$(LINUX_VER)") \
	"-include $(REL_TOP)/config.mak"

all: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) $@

install: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) OUTPUT=$(OUTPUT) $@

endif
