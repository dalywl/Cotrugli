# Make file to generate Cotrugli web site

VPATH = ../htdocs

PAGES = index.html GL_API.html setup.html

$(PAGES): template.xslt

%.html: %.xhtml
	xsltproc --output $(VPATH)/$@ template.xslt $<
