#
# Extracts results for a benchmark done using different number of threads for
# "Raft Read Scalability - YCSB Benchmarks" Google Sheet
# python extract-ycsb-results.py <results-dir0> <results-dir1> <results-dir2>
#
import sys
import numpy

DIRS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]

def extract(dir, param1, param2):
	result = []

	for d in DIRS:
		file = dir + "/" + str(d) + "/ycsb-results"
		found = False
		for line in open(file):
			vals = line.split(', ')
			
			if len(vals) > 2:
				if (vals[0] == param1) and (vals[1] == param2):
					found = True
					result.append(float(vals[2].rstrip()))
					break

		if found == False:
			result.append(0)

	return result

def extractAvg(param1, param2):
	result = [0] * len(DIRS)
	size = len(sys.argv)

	for i in range(1, size):
		dir = sys.argv[i]
		vals = extract(dir, param1, param2)
		result = [x + y for x, y in zip(result, vals)]

	return [x / (size-1) for x in result]

def main():
	result = []
	result.append(extractAvg('[OVERALL]', 'Throughput(ops/sec)'))
	result.append(extractAvg('[UPDATE]', 'AverageLatency(us)'))
	result.append(extractAvg('[UPDATE]', '95thPercentileLatency(us)'))
	result.append(extractAvg('[UPDATE]', '99thPercentileLatency(us)'))
	result.append(extractAvg('[READ]', 'AverageLatency(us)'))
	result.append(extractAvg('[READ]', '95thPercentileLatency(us)'))
	result.append(extractAvg('[READ]', '99thPercentileLatency(us)'))
	result.append(extractAvg('[UPDATE-FAILED]', 'Operations'))
	
	nparr = numpy.array(result)
	nparr = numpy.transpose(nparr)
	numpy.savetxt('output.txt', nparr, fmt='%f', delimiter='\t')

if __name__ == '__main__':
	main()
