#
# Extracts results from custom instrumentation using different number of threads for
# "Raft Read Scalability - YCSB Benchmarks" Google Sheet
# python extract-ycsb-results.py <results-dir0> <results-dir1> <results-dir2>
#

import sys
import numpy

DIRS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
MACHINES = ['dsl0', 'dsl1', 'dsl2']

def extract(index):
	parentDirs = sys.argv[1:]
	result = [0] * len(DIRS)

	for i, childDir in enumerate(DIRS):
		sum = 0
		for machine in MACHINES:
			for parentDir in parentDirs:
				file = parentDir + "/" + str(childDir) + "/" + machine + "/data.dump"
				sum += numpy.sum(numpy.loadtxt(file, dtype=int, delimiter=', ', usecols=(index + 1)))
		result[i] = sum / (len(MACHINES) * len(parentDirs))

	return result

def main():
	result = []

	result.append(extract(9))
	result.append(numpy.subtract(extract(4), extract(2)))
	result.append(numpy.subtract(extract(7), extract(6)))

	nparr = numpy.array(result)
	nparr = numpy.transpose(nparr)
	numpy.savetxt('output.txt', nparr, fmt='%d', delimiter='\t')

if __name__ == '__main__':
	main()