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

def calcMeanResults(results):
	meanDict = dict()
	totalReadings = len(results.keys())

	for dir, dirDict in results.items():
		for numThread, numThreadDict in dirDict.items():
			meanNumThreadDict = meanDict.get(numThread, dict())
			for param, paramVal in numThreadDict.items():
				meanNumThreadDict[param] = meanNumThreadDict.get(param, 0) + paramVal
			meanDict[numThread] = meanNumThreadDict

	for numThread, numThreadDict in meanDict.items():
		for param, paramVal in numThreadDict.items():
			numThreadDict[param] = numThreadDict[param] / totalReadings

	return meanDict

def dumpForGoogleSheet(d, delimiter='\t'):
	# print headers
	sys.stdout.write("Threads" + delimiter)
	for param in YCSB_PARAMS:
		sys.stdout.write(param.rstrip(', ') + delimiter)
	sys.stdout.write('\n')

	# print vals
	for numThread in NUM_THREADS:
		sys.stdout.write(str(numThread) + delimiter)
		numThreadDict = d[numThread]
		for param in YCSB_PARAMS:
			sys.stdout.write(str(numThreadDict[param]) + delimiter)
		sys.stdout.write('\n')

	sys.stdout.flush()

def main():
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			path = "benchmarks/" + BENCHMARK_DIR_PREFIX + "." + str(readType) + "." + workload + ".*"
			dirs = glob.glob(path)

			results = dict()
			for dir in dirs:
				result = dict()
				for numThread in NUM_THREADS:
					result[numThread] = extractYcsbParams(dir+"/"+str(numThread)+"/ycsb-results")
				results[dir] = result

			mean = calcMeanResults(results)
			print path + " (" + str(len(results.keys())) + " readings)"
			dumpForGoogleSheet(mean)
			print ""

if __name__ == '__main__':
	main()
