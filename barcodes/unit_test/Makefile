OPENSCAD=openscad
OPENSCAD_options=--viewall --projection=ortho --colorscheme=Cornfield --autocenter
RESULTDIR=results
TMPDIR=$(RESULTDIR)/.tmp

ALL_testcases:=$(wildcard *.scad)
UPCA_testcases:=$(wildcard upca_*.scad)
EAN13_testcases:=$(wildcard ean13_*.scad)
UPC_testcases=$(UPCA_testcases) $(EAN13_testcases)
CODE128_testcases:=$(wildcard code128_*.scad)
CODE39_testcases:=$(wildcard code39_*.scad)
DM_testcases:=$(wildcard dm_*.scad)
QR_testcases:=$(wildcard qr_*.scad)

define expand_png_list
	$(sort $(1:%.scad=$(RESULTDIR)/%a.png) $(1:%.scad=$(RESULTDIR)/%b.png) $(1:%.scad=$(RESULTDIR)/%c.png) $(1:%.scad=$(RESULTDIR)/%d.png))
endef


.PHONY: all clean
all: $(call expand_png_list, $(ALL_testcases))

clean:
	rm -f $(RESULTDIR)/*.png
	rm -f $(TMPDIR)/*.d

.PHONY: upc upca ean13 code128 code39 datamatrix dm quick_response qr
upc: $(call expand_png_list, $(UPC_testcases))

upca: $(call expand_png_list, $(UPCA_testcases))

ean13: $(call expand_png_list, $(EAN13_testcases))

code128: $(call expand_png_list, $(CODE128_testcases))

code39: $(call expand_png_list, $(CODE39_testcases))

datamatrix: $(call expand_png_list, $(DM_testcases))
dm: datamatrix

quick_response: $(call expand_png_list, $(QR_testcases))
qr: quick_response

# include generated dependency files
include $(wildcard $(TMPDIR)/*.d)

results/%a.png: %.scad | $(RESULTDIR) $(TMPDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d -o $@ $<
results/%b.png: %.scad | $(RESULTDIR) $(TMPDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d --camera=0,0,100,0,0,0 -o $@ $<
results/%c.png: %.scad | $(RESULTDIR) $(TMPDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d --render -o $@ $<
results/%d.png: %.scad | $(RESULTDIR) $(TMPDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d --camera=0,0,100,0,0,0 --render -o $@ $<

$(RESULTDIR) $(TMPDIR):
	mkdir -p $@
