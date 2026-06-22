# LOCALEDIR, RM, INSTALL defined in parent makefile

MOFILES = af.mo am.mo an.mo ar.mo as.mo az.mo be.mo be@latin.mo bg.mo bn.mo bn_IN.mo br.mo bs.mo ca.mo cs.mo cy.mo da.mo de.mo dz.mo el.mo eo.mo es.mo et.mo eu.mo fa.mo ff.mo fi.mo fo.mo fr.mo fy.mo ga.mo gd.mo gl.mo gu.mo gv.mo ha.mo he.mo hi.mo hr.mo ht.mo hu.mo hy.mo ia.mo id.mo ig.mo io.mo is.mo it.mo ja.mo jv.mo ka.mo kk.mo km.mo kn.mo ko.mo kr.mo ku.mo kw.mo ky.mo la.mo lb.mo lg.mo li.mo lt.mo lv.mo mg.mo mi.mo mk.mo ml.mo mn.mo mr.mo ms.mo my.mo nb.mo ne.mo nl.mo nn.mo oc.mo or.mo pa.mo pl.mo ps.mo pt.mo pt_BR.mo ro.mo ru.mo rw.mo si.mo sk.mo sl.mo sq.mo sr.mo sr@Latn.mo sr@latin.mo st.mo sv.mo sw.mo ta.mo te.mo tg.mo th.mo tk.mo tl.mo tr.mo ts.mo tt.mo ug.mo uk.mo ur.mo ur_PK.mo uz.mo uz@cyrillic.mo wa.mo wo.mo xh.mo yi.mo yo.mo zh_CN.mo zh_TW.mo zu.mo

all: $(MOFILES)
	
# static pattern rule
$(MOFILES): %.mo: %.po Makefile
	@echo 'Compiling translation' $<
	@msgfmt -c -v $< -o $@

clean:
	$(RM) *.mo *.percent

# for info about DESTDIR see http://www.gnu.org/prep/standards/html_node/DESTDIR.html

install: all
	for NAME in $(MOFILES); do \
	  $(INSTALL) -v -d $(DESTDIR)$(LOCALEDIR)/`basename $$NAME .mo`/LC_MESSAGES; \
	  $(INSTALL) -v -m 644 $$NAME $(DESTDIR)$(LOCALEDIR)/`basename $$NAME .mo`/LC_MESSAGES/isomaster.mo; \
	done

uninstall:
	for NAME in $(MOFILES); do \
	  $(RM) -f $(DESTDIR)$(LOCALEDIR)/`basename $$NAME .mo`/LC_MESSAGES/isomaster.mo; \
	done
