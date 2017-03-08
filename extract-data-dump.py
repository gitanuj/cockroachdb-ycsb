#
# Extracts results from custom instrumentation properly formatted for
# "Raft Read Scalability - YCSB Benchmarks" Google Sheet
# python extract-data-dump.py
#

import sys
import glob

BENCHMARK_DIR_PREFIX = "03.06.2017.dsl"
READ_TYPES = [0, 1, 2, 3]
WORKLOADS = ["uniform95"]
NUM_THREADS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
MACHINES = ['dsl0', 'dsl1', 'dsl2']

# from util/instrumentation/recorder.go in same order
DATA_INDICES = [
	"F_DistSender_sendPartialBatch",
	"V_DistSender_sendPartialBatch_numRetriesTotal", 
	"V_DistSender_sendPartialBatch_returnedWithoutRetry", 
	"V_DistSender_sendPartialBatch_writeIntentErrorCount",
	"F_Store_Send",
	"V_Store_Send_returnedWithoutRetry",
	"V_Store_Send_numRetriesTotal",
	"V_Store_Send_numRetriesWithoutBackoff",
	"V_Store_Send_processWriteIntentErrorCount",
	"V_Replica_addReadOnlyCmd_executeBatchCount",
	"V_Replica_addReadOnlyCmd_intentFoundCount",
]

def extractDataIndex(file, dataIndex):
	sum = 0
	for line in open(file):
		sum += int(line.split(',')[dataIndex + 1])
	return sum

def extractDataIndices(file):
	results = dict()
	for i, dataIndex in enumerate(DATA_INDICES):
		results[dataIndex] = extractDataIndex(file, i)
	return results

def meanDicts(dicts):
	mean = dict()
	total = float(len(dicts))
	for k in dicts[0].keys():
		mean[k] = 0
		for d in dicts:
			mean[k] += d[k]/total
	return mean

def dumpThreadsVsTables(means, cols, readType, workload, machine, delimiter='\t'):
	# headers
	sys.stdout.write('Threads' + delimiter)
	for col in cols:
		sys.stdout.write(col + delimiter)
	sys.stdout.write('\n')

	# data
	for numThread in NUM_THREADS:
		file = getFile(getGlobpath(readType, workload), numThread, machine)
		data = means[file]
		sys.stdout.write(str(numThread) + delimiter)
		for col in cols:
			sys.stdout.write(str(data[col]) + delimiter)
		sys.stdout.write('\n')

def getGlobpath(readType, workload):
	return "benchmarks/" + BENCHMARK_DIR_PREFIX + "." + str(readType) + "." + workload + ".*"

def getFile(dir, numThread, machine):
	return dir+"/"+str(numThread)+"/"+machine+"/data.dump"

def main():
	results = dict()
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			globpath = getGlobpath(readType, workload)
			dirs = glob.glob(globpath)
			for dir in dirs:
				for numThread in NUM_THREADS:
					for machine in MACHINES:
						file = getFile(dir, numThread, machine)
						data = extractDataIndices(file)
						results[file] = data

	# Calculate mean
	means = dict()
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			for numThread in NUM_THREADS:
				for machine in MACHINES:
					toAvg = []
					globpath = getGlobpath(readType, workload)
					for dir in glob.glob(globpath):
						file = getFile(dir, numThread, machine)
						toAvg.append(results[file])
					mean = meanDicts(toAvg)
					means[getFile(globpath, numThread, machine)] = mean

	# dump
	for readType in READ_TYPES:
		for workload in WORKLOADS:
			for machine in MACHINES:
				print getGlobpath(readType, workload) + " " + machine
				dumpThreadsVsTables(means, DATA_INDICES, readType, workload, machine)
				print ""

if __name__ == '__main__':
	main()
