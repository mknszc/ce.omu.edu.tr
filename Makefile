# ==============================================================================
# Bölüm sitesinde statik olarak üretilecek dosyalar için kurallar
# FIXME Dizin/dosya isimlerine fazla bağımlı.  Bunu yeniden yazmak lazım.
# ==============================================================================

# İnşa dizini kökü.
BUILDDIR       ?= static
# Test amaçlı olarak bir başka dizine örneğin '/tmp'e üretmek için şu şekilde
# çağırın:
# 	BUILDDIR=/tmp make

# Bu projeye özel tüm betikler
PATH           := $(CURDIR)/bin:$(PATH)
export PATH

# Öntanımlı olarak inşa edilmesi gereken herşeyi inşa et.
.DEFAULT_GOAL  := build

# ------------------------------------------------------------------------------
# Ders listeleri
# ------------------------------------------------------------------------------

COURSEINDIR    := data/ders
COURSEOUTDIR   := $(BUILDDIR)/ders
COURSETEMPLATE := template/ders.html
COURSEIN       := $(wildcard $(COURSEINDIR)/*.yaml)
COURSEOUT      := $(patsubst $(COURSEINDIR)/%.yaml, $(COURSEOUTDIR)/%/index.html, $(COURSEIN))

# Dersler için derleme kuralı.
$(COURSEOUTDIR)/%/index.html: $(COURSEINDIR)/%.yaml $(COURSETEMPLATE)
	@printf "\t$< => $@" && \
	mkdir -p $(dir $@) && \
	yaml-to-html $< $(COURSETEMPLATE) >$@ || { \
		rm -rf $@; \
		echo >&2 "Olmadı!"; \
		exit 1; \
	} && \
	printf "\t[ok]\n"

# İnşa edileceklere ekle.
BUILT+=$(COURSEOUT)
# Hangi dosya hangi dosyadan üretilecek?
$(COURSEOUT): %: $(COURSEIN)

# İnşa hedefi.
.PHONY: build
build: $(BUILT)

# Temizlik hedefi.
.PHONY: clean
clean:
	# inşa edilenleri sil
	rm -f $(BUILT)
