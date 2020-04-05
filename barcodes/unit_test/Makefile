OPENSCAD=openscad
OPENSCAD_options=--viewall --projection=ortho --colorscheme=Cornfield --autocenter
RESULTDIR=results
TMPDIR=$(RESULTDIR)/.tmp

ALL_testcases:=$(wildcard *.scad)
UPCA_testcases:=$(wildcard upca_*.scad)
EAN13_testcases:=$(wildcard ean13_*.scad)
UPC_testcases=$(UPCA_testcases) $(EAN13_testcases)


define expand_png_list
	$(sort $(1:%.scad=$(RESULTDIR)/%a.png) $(1:%.scad=$(RESULTDIR)/%b.png) $(1:%.scad=$(RESULTDIR)/%c.png) $(1:%.scad=$(RESULTDIR)/%d.png))
endef


.PHONY: all upc upca clean
all: $(call expand_png_list, $(ALL_testcases))

upc: $(call expand_png_list, $(UPC_testcases))

upca: $(call expand_png_list, $(UPCA_testcases))

ean13: $(call expand_png_list, $(EAN13_testcases))

clean:
	rm -f $(RESULTDIR)/*.png
	rm -f $(TMPDIR)/*.d


# include generated dependency files
include $(wildcard $(TMPDIR)/*.d)

results/%a.png: %.scad | $(RESULTDIR) $(TMPDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d -o $@ $<
results/%b.png: %.scad | $(RESULTDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d --camera=0,0,100,0,0,0 -o $@ $<
results/%c.png: %.scad | $(RESULTDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d --render -o $@ $<
results/%d.png: %.scad | $(RESULTDIR)
	$(OPENSCAD) $(OPENSCAD_options) -d $(TMPDIR)/$(@F).d --camera=0,0,100,0,0,0 --render -o $@ $<

$(RESULTDIR) $(TMPDIR):
	mkdir -p $@
