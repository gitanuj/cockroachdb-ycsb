#
# Extracts results for benchmarks properly formatted for
# "Raft Read Scalability - YCSB Benchmarks" Google Sheet
# python extract-ycsb-results.py
#

import sys
import glob

BENCHMARK_DIR_PREFIX = "03.06.2017.dsl"
READ_TYPES = [0, 1, 2, 3]
WORKLOADS = ["uniform95"]
NUM_THREADS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]

YCSB_PARAMS = [
	"[OVERALL], Throughput(ops/sec), ",
	"[UPDATE], Operations, ",
	"[UPDATE], AverageLatency(us), ",
	"[UPDATE], 95thPercentileLatency(us), ",
	"[UPDATE], 99thPercentileLatency(us), ",
	"[UPDATE-FAILED], Operations, ",
	"[READ], Operations, ",
	"[READ], AverageLatency(us), ",
	"[READ], 95thPercentileLatency(us), ",
	"[READ], 99thPercentileLatency(us), ",
	"[READ-FAILED], Operations, ",
]

def extractYcsbParam(file, param):
	for line in open(file):
		if line.startswith(param):
			result = line[len(param):].rstrip()
			return float(result)
	return 0

def extractYcsbParams(file):
	results = dict()
	for param in YCSB_PARAMS:
		results[param] = extractYcsbParam(file, param)
	return results

def meanDicts(dicts):
	mean = dict()
	total = float(len(dicts))
	for k in dicts[0].keys():
		mean[k] = 0
		for d in dicts:
			mean[k] += d[k]/total
	return mean

def dumpThreadsVsTables(means, cols, readType, workload, delimiter='\t'):
	# headers
	sys.stdout.write('Threads' + delimiter)
	for col in cols:
		sys.stdout.write(col.rstrip(', ') + delimiter)
	sys.stdout.write('\n')

	# data
	for numThread in NUM_THREADS:
		file = getFile(getGlobpath(readType, workload), numThread)
		data = means[file]
		sys.stdout.write(str(numThread) + delimiter)
		for col in cols:
			sys.stdout.write(str(data[col]) + delimiter)
		sys.stdout.write('\n')

def getGlobpath(readType, workload):
	return "benchmarks/" + BENCHMARK_DIR_PREFIX + "." + str(readType) + "." + workload + ".*"

def getFile(dir, numThread):
	return dir+"/"+str(numThread)+"/ycsb-results"

def main():
	results = dict()
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			globpath = getGlobpath(readType, workload)
			dirs = glob.glob(globpath)
			for dir in dirs:
				for numThread in NUM_THREADS:
					file = getFile(dir, numThread)
					params = extractYcsbParams(file)
					results[file] = params

	# Calculate mean
	means = dict()
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			for numThread in NUM_THREADS:
				toAvg = []
				globpath = getGlobpath(readType, workload)
				for dir in glob.glob(globpath):
					file = getFile(dir, numThread)
					toAvg.append(results[file])
				mean = meanDicts(toAvg)
				means[getFile(globpath, numThread)] = mean

	# dump
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			print getFile(getGlobpath(readType, workload), numThread)
			dumpThreadsVsTables(means, YCSB_PARAMS, readType, workload)
			print ""

if __name__ == '__main__':
	main()
