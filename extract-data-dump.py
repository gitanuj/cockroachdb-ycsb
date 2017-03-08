#
# Extracts results from custom instrumentation properly formatted for
# "Raft Read Scalability - YCSB Benchmarks" Google Sheet
# python extract-data-dump.py
#

import sys
import glob
import os
import Gnuplot as gp
import Gnuplot.funcutils
import errno

BENCHMARK_DIR_PREFIX = "03.06.2017.m3.2xl"
READ_TYPES = [0, 1, 2, 3]
WORKLOADS = ["uniform95"]
NUM_THREADS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
MACHINES = ['c0', 'c1', 'c2', 'c3', 'c4']

# from util/instrumentation/recorder.go in same order
DATA_INDICES = [
	"F_DistSender_sendPartialBatch",	# 0
	"V_DistSender_sendPartialBatch_numRetriesTotal",	# 1
	"V_DistSender_sendPartialBatch_returnedWithoutRetry",	# 2
	"V_DistSender_sendPartialBatch_writeIntentErrorCount",	# 3
	"F_Store_Send",	# 4
	"V_Store_Send_returnedWithoutRetry",	# 5
	"V_Store_Send_numRetriesTotal",	# 6
	"V_Store_Send_numRetriesWithoutBackoff",	# 7
	"V_Store_Send_processWriteIntentErrorCount",	# 8
	"V_Replica_addReadOnlyCmd_executeBatchCount",	# 9
	"V_Replica_addReadOnlyCmd_intentFoundCount",	# 10
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

def dumpThreadsVsTables(means, cols, readType, workload, delimiter='\t'):
	# headers
	for machine in MACHINES:
		sys.stdout.write('Threads' + delimiter)
		for col in cols:
			sys.stdout.write(col + delimiter)
		sys.stdout.write(delimiter)
	sys.stdout.write('\n')

	# data
	for numThread in NUM_THREADS:
		for machine in MACHINES:
			sys.stdout.write(str(numThread) + delimiter)
			file = getFile(getGlobpath(readType, workload), numThread, machine)
			data = means[file]
			for col in cols:
				sys.stdout.write(str(data[col]) + delimiter)
			sys.stdout.write(delimiter)
		sys.stdout.write('\n')

def plot(x, ys, labels, filename):
	g = gp.Gnuplot()
	g("set terminal svg")
	g("set multiplot")
	g("set title '" + filename + "'")
	plotData = []
	for i, y in enumerate(ys):
		plotData.append(gp.Data(x, y, with_="linespoints", title=str(labels[i])))
	g.plot(*plotData)
	g("unset multiplot")
	g.hardcopy(filename=filename, terminal="svg")
	del g

def getGlobpath(readType, workload):
	return "benchmarks/" + BENCHMARK_DIR_PREFIX + "." + str(readType) + "." + workload + ".*"

def getFile(dir, numThread, machine):
	return dir+"/"+str(numThread)+"/"+machine+"/data.dump"

def mkdirsp(dirs):
	try:
		os.makedirs(dirs)
	except OSError as e:
		if e.errno != errno.EEXIST:
			raise

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
	# for readType in READ_TYPES:
	# 	for workload in WORKLOADS:
	# 		print getGlobpath(readType, workload) + " " + ",".join(MACHINES)
	# 		dumpThreadsVsTables(means, DATA_INDICES, readType, workload)
	# 		print ""

	mkdirsp("graphs/data/" + BENCHMARK_DIR_PREFIX)
	for readType in READ_TYPES:
		for machine in MACHINES:
			for data in DATA_INDICES:
				ys = []
				for workload in WORKLOADS:
					y = []
					ys.append(y)
					globpath = getGlobpath(readType, workload)
					for numThread in NUM_THREADS:
						y.append(means[getFile(globpath, numThread, machine)][data])
				filename = "graphs/data/" + BENCHMARK_DIR_PREFIX + "/" + str(readType) + "." + data + "." + machine + ".svg"
				plot(NUM_THREADS, ys, WORKLOADS, filename)

	for workload in WORKLOADS:
		for machine in MACHINES:
			for data in DATA_INDICES:
				ys = []
				for readType in READ_TYPES:
					y = []
					ys.append(y)
					globpath = getGlobpath(readType, workload)
					for numThread in NUM_THREADS:
						y.append(means[getFile(globpath, numThread, machine)][data])
				filename = "graphs/data/" + BENCHMARK_DIR_PREFIX + "/" + workload + "." + data + "." + machine + ".svg"
				plot(NUM_THREADS, ys, READ_TYPES, filename)


if __name__ == '__main__':
	main()
