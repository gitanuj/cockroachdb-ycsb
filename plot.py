import Gnuplot, Gnuplot.funcutils

Gnuplot.GnuplotOpts.default_term = 'svg'

def multiplot(xlabel, x, ylabel, ys, ytitles, filename):
	g = Gnuplot.Gnuplot()
	g.set(output=filename)
	g("set term svg enhanced background rgb 'white' size 1024,600")
	g("set border 1+2")
	g("set key outside vertical right top")
	g.xlabel(xlabel)
	g.ylabel(ylabel)
	plotData = []
	for i, y in enumerate(ys):
		plotData.append(Gnuplot.Data(x, y, with_="lp", title=ytitles[i]))
	g.plot(*plotData)
	g.close()
