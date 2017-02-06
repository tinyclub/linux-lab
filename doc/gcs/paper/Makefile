all:	paper.pdf

paper.pdf: paper.tex
	latex paper.tex
	latex paper.tex
	dvips -o paper.ps paper.dvi
	ps2pdf paper.ps paper.pdf

clean:
	rm -f *.dvi *.aux *.log *.ps *.pdf
