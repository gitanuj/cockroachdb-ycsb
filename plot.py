import Gnuplot, Gnuplot.funcutils
import os

Gnuplot.GnuplotOpts.default_term = 'postscript'

Y_IDS = {
	'Lease Holder':	'1',
	'Local':	'2',
	'Quorum':	'3',
	"Strongly Consistent Quorum":	'4'
}

def multiplot_internal(xlabel, x, ylabel, ys, ytitles, filename, keyposition):
	g = Gnuplot.Gnuplot()
	g.set(output=filename+'.eps')
	g("set term postscript eps size 3.5,2.62 enhanced color font 'Helvetica,14' lw 2")
	g("set key " + keyposition)
	g.xlabel(xlabel)
	g.ylabel(ylabel)
	plotData = []
	for i, y in enumerate(ys):
		ytitle = ytitles[i]
		with_str = "lp pt " + Y_IDS[ytitle] + " lc " + Y_IDS[ytitle] + " lt " + Y_IDS[ytitle]
		plotData.append(Gnuplot.Data(x, y, with_=with_str, title=ytitle))
	g.plot(*plotData)
	g.close()

def multiplot(xlabel, x, ylabel, ys, ytitles, filename):
	os.mkdir(filename)
	multiplot_internal(xlabel, x, ylabel, ys, ytitles, filename + "/key_right_top", "on right top")
	multiplot_internal(xlabel, x, ylabel, ys, ytitles, filename + "/key_right_bottom", "on right bottom")
	multiplot_internal(xlabel, x, ylabel, ys, ytitles, filename + "/key_left_top", "on left top")
	multiplot_internal(xlabel, x, ylabel, ys, ytitles, filename + "/key_left_bottom", "on left bottom")
	multiplot_internal(xlabel, x, ylabel, ys, ytitles, filename + "/key_off", "off")