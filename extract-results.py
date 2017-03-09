#
# Extracts results and plots graphs
# python extract-ycsb-results.py <output-dir>
# 	Qualifiers: $readtype, $workload, $repetition, $thread, $machine
#

import sys
import os
import numpy as np
from plot import multiplot

OUTPUT_DIR = sys.argv[1]

READ_TYPES = [0, 1, 2, 3]
MAX_REPETITIONS = 3
WORKLOADS = ["uniform75", "uniform80", "uniform85", "uniform90", "uniform95", "uniform99"]
NUM_THREADS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
MACHINES = ['dsl0', 'dsl1', 'dsl2']

YCSB_PATH = "benchmarks/03.06.2017.dsl.$readtype.$workload.$repetition/$thread/ycsb-results"
YCSB_PARAMS = [
	{ "id" : "[OVERALL], Throughput(ops/sec), ", "title" : "Throughput (ops per sec)" },
	# { "id" : "[UPDATE], Operations, ", "title" : "Update Operations" },
	{ "id" : "[UPDATE], AverageLatency(us), ", "title" : "Avg Update Latency (us)" },
	# { "id" : "[UPDATE], 95thPercentileLatency(us), ", "title" : "95th%ile Update Latency (us)" },
	# { "id" : "[UPDATE], 99thPercentileLatency(us), ", "title" : "99th%ile Update Latency (us)" },
	# { "id" : "[UPDATE-FAILED], Operations, ", "title" : "Failed Update Operations" },
	# { "id" : "[READ], Operations, ", "title" : "Read Operations" },
	{ "id" : "[READ], AverageLatency(us), ", "title" : "Avg Read Latency (us)" },
	# { "id" : "[READ], 95thPercentileLatency(us), ", "title" : "95th%ile Read Latency (us)" },
	# { "id" : "[READ], 99thPercentileLatency(us), ", "title" : "99th%ile Read Latency (us)" },
	# { "id" : "[READ-FAILED], Operations, ", "title" : "Failed Read Operations" },
]

DATA_PATH = "benchmarks/03.06.2017.dsl.$readtype.$workload.$repetition/$thread/$machine/data.dump"
DATA_PARAMS = [
	# { "id" : "0", "title" : "DistSender Requests" },
	{ "id" : "1", "title" : "DistSender Retries" },
	# { "id" : "2", "title" : "DistSender No-Retry Requests" },
	# { "id" : "3", "title" : "DistSender WriteIntent Encounters" },
	# { "id" : "4", "title" : "Store Requests" },
	{ "id" : "6", "title" : "Store Retries" },
	# { "id" : "5", "title" : "Store No-Retry Requests" },
	# { "id" : "7", "title" : "Store No-Backoff Retries" },
	# { "id" : "9", "title" : "Replica Read Requests" },
	# { "id" : "10", "title" : "Replica WriteIntent Encounters" },
]

def extractDataParam(file, data_param_id):
	sum = 0
	for line in open(file):
		sum += int(line.split(',')[int(data_param_id) + 1])
	return sum

def extractDataParams(file):
	try:
		results = []
		for param in DATA_PARAMS:
			param_id = param["id"]
			results.append(extractDataParam(file, param_id))
		return results
	except:
		print "Error in parsing " + file
		return None

def extractYcsbParam(file, param_id):
	for line in open(file):
		if line.startswith(param_id):
			result = line[len(param_id):].rstrip()
			return float(result)
	return 0

def extractYcsbParams(file):
	try:
		results = []
		for param in YCSB_PARAMS:
			param_id = param["id"]
			results.append(extractYcsbParam(file, param_id))
		return results
	except:
		print "Error in parsing " + file
		return None

def my(path_exp, extract_func):
	all_paths = set()
	for readtype in READ_TYPES:
		for workload in WORKLOADS:
			for thread in NUM_THREADS:
				for machine in MACHINES:
					path = path_exp.replace("$readtype", str(readtype))
					path = path.replace("$workload", workload)
					path = path.replace("$thread", str(thread))
					path = path.replace("$machine", str(machine))
					all_paths.add(path)
	results = dict()
	for path in all_paths:
		toMean = []
		for repetition in range(MAX_REPETITIONS):
			file = path.replace("$repetition", str(repetition))
			result = extract_func(file)
			if result is not None:
				toMean.append(result)
		results[path] = np.mean(toMean, axis=0).tolist()
	return results

def dump_raw_results(results, params, filename, delimiter=':\t'):
	with open(filename, 'w') as f:
		for file, result in results.iteritems():
			f.write(file + '\n')
			for i, param in enumerate(params):
				f.write(param["title"] + delimiter + str(result[i]) + '\n')
			f.write('\n')

def dump_ycsb_graphs(results):
	path_exp = YCSB_PATH

	# for uniform95 workload
	path = path_exp.replace("$workload", "uniform95")
	x = NUM_THREADS
	xlabel = "Threads"
	ytitles = ["Lease Holder", "Local", "Quorum", "Strongly Consistent Quorum"]
	for i, param in enumerate(YCSB_PARAMS):
		ys = []
		for readtype in READ_TYPES:
			y = []
			ys.append(y)
			for thread in NUM_THREADS:
				curr = path.replace("$readtype", str(readtype))
				curr = curr.replace("$thread", str(thread))
				y.append(results[curr][i])
		filename = OUTPUT_DIR + "/" + param["title"]+"."+str(readtype)+".svg"
		multiplot(xlabel, x, param["title"], ys, ytitles, filename)

	# for 70 threads
	path = path_exp.replace("$thread", "70")
	x = [75, 80, 85, 90, 95, 99] # workloads
	xlabel = "Read percentage"
	ytitles = ["Lease Holder", "Local", "Quorum", "Strongly Consistent Quorum"]
	for i, param in enumerate(YCSB_PARAMS):
		ys = []
		for readtype in READ_TYPES:
			y = []
			ys.append(y)
			for workload in WORKLOADS:
				curr = path.replace("$readtype", str(readtype))
				curr = curr.replace("$workload", str(workload))
				y.append(results[curr][i])
		filename = OUTPUT_DIR + "/70threads." + param["title"]+"."+str(readtype)+".svg"
		multiplot(xlabel, x, param["title"], ys, ytitles, filename)

if __name__ == '__main__':
	os.mkdir(OUTPUT_DIR)

	ycsb_results = my(YCSB_PATH, extractYcsbParams)
	dump_raw_results(ycsb_results, YCSB_PARAMS, OUTPUT_DIR + "/" + "ycsb-results.txt")
	dump_ycsb_graphs(ycsb_results)

	data_results = my(DATA_PATH, extractDataParams)
	dump_raw_results(data_results, DATA_PARAMS, OUTPUT_DIR + "/" + "data-results.txt")
