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

READ_TYPES = [2, 3]
REPETITIONS = 3
WORKLOADS = ["hotspot8001", "hotspot8002", "hotspot8003", "hotspot8004", "hotspot8005", "hotspot8006", "hotspot8007", "hotspot8008", "hotspot8009", "hotspot8010"]
# NUM_THREADS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]
NUM_THREADS = [70]
# LHFALLBACK_PROBS = ["0.0", "0.10", "0.20", "0.30", "0.40", "0.50"]
MACHINES = ['c0', 'c1', 'c2', 'c3', 'c4']

# YCSB_PATH = "final-ec2-benchmarks/diff_lhfallback/ec2.m3.2xl.$readtype.$workload.$lhfallback.$repetition/$thread/ycsb-results"
YCSB_PATH = "final-ec2-benchmarks/ec2.m3.2xl.$readtype.$workload.$repetition/$thread/ycsb-results"
YCSB_PARAMS = [
	{ "id" : "[OVERALL], Throughput(ops/sec), ", "title" : "Throughput (ops per sec)" },
	# { "id" : "[UPDATE], Operations, ", "title" : "Update Operations" },
	{ "id" : "[UPDATE], AverageLatency(us), ", "title" : "Avg Update Latency (us)" },
	{ "id" : "[UPDATE], 95thPercentileLatency(us), ", "title" : "95th%ile Update Latency (us)" },
	{ "id" : "[UPDATE], 99thPercentileLatency(us), ", "title" : "99th%ile Update Latency (us)" },
	# { "id" : "[UPDATE-FAILED], Operations, ", "title" : "Failed Update Operations" },
	# { "id" : "[READ], Operations, ", "title" : "Read Operations" },
	{ "id" : "[READ], AverageLatency(us), ", "title" : "Avg Read Latency (us)" },
	{ "id" : "[READ], 95thPercentileLatency(us), ", "title" : "95th%ile Read Latency (us)" },
	{ "id" : "[READ], 99thPercentileLatency(us), ", "title" : "99th%ile Read Latency (us)" },
	# { "id" : "[READ-FAILED], Operations, ", "title" : "Failed Read Operations" },
]

# DATA_PATH = "final-ec2-benchmarks/diff_lhfallback/ec2.m3.2xl.$readtype.$workload.$lhfallback.$repetition/$thread/$machine/data.dump"
DATA_PATH = "final-ec2-benchmarks/ec2.m3.2xl.$readtype.$workload.$repetition/$thread/$machine/data.dump"
DATA_PARAMS = [
	# { "id" : "0", "title" : "DistSender Requests" },
	# { "id" : "1", "title" : "DistSender Retries" },
	# { "id" : "2", "title" : "DistSender No-Retry Requests" },
	{ "id" : "3", "title" : "DistSender WriteIntent Encounters" },
	# { "id" : "4", "title" : "Store Requests" },
	{ "id" : "6", "title" : "Store Retries" },
	# { "id" : "5", "title" : "Store No-Retry Requests" },
	{ "id" : "7", "title" : "Store No-Backoff Retries" },
	# { "id" : "9", "title" : "Replica Read Requests" },
	# { "id" : "10", "title" : "Replica WriteIntent Encounters" },
]

def extractDataParam(file, data_param_id):
	sum = 0.0
	for machine in MACHINES:
		for line in open(file.replace("$machine", machine)):
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
			# for lhfallback in LHFALLBACK_PROBS:
				path = path_exp.replace("$readtype", str(readtype))
				path = path.replace("$workload", workload)
				path = path.replace("$thread", str(thread))
				# path = path.replace("$lhfallback", str(lhfallback))
				all_paths.add(path)
	results = dict()
	for path in all_paths:
		toMean = []
		for repetition in range(REPETITIONS):
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

	# for single workload
	# path = path_exp.replace("$workload", "zipfian95")
	# x = NUM_THREADS
	# xlabel = "Threads"
	# ytitles = ["Lease Holder", "Local", "Quorum", "Strongly Consistent Quorum"]
	# for i, param in enumerate(YCSB_PARAMS):
	# 	ys = []
	# 	for readtype in READ_TYPES:
	# 		y = []
	# 		ys.append(y)
	# 		for thread in NUM_THREADS:
	# 			curr = path.replace("$readtype", str(readtype))
	# 			curr = curr.replace("$thread", str(thread))
	# 			y.append(results[curr][i])
	# 	filename = OUTPUT_DIR + "/" + param["title"]
	# 	multiplot(xlabel, x, param["title"], ys, ytitles, filename)

	# for 70 threads
	path = path_exp.replace("$thread", "70")
	# path = path.replace("$workload", "uniform95")
	x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	xlabel = "Hotspot Data Fraction"
	# ytitles = ["Lease Holder", "Local", "Quorum", "Strongly Consistent Quorum"]
	ytitles = ["Quorum", "Strongly Consistent Quorum"]
	for i, param in enumerate(YCSB_PARAMS):
		ys = []
		for readtype in READ_TYPES:
			y = []
			ys.append(y)
			for workload in WORKLOADS:
				curr = path.replace("$readtype", str(readtype))
				curr = curr.replace("$workload", str(workload))
				# curr = curr.replace("$lhfallback", lhfallback)
				y.append(results[curr][i])
		filename = OUTPUT_DIR + "/" + param["title"]
		multiplot(xlabel, x, param["title"], ys, ytitles, filename)

def dump_data_graphs(results):
	path_exp = DATA_PATH

	# # for single workload
	# path = path_exp.replace("$workload", "zipfian95")
	# x = NUM_THREADS
	# xlabel = "Threads"
	# ytitles = ["Lease Holder", "Local", "Quorum", "Strongly Consistent Quorum"]

	# # DistSender backoff retries
	# ys = []
	# ylabel = "DistSender backoff retries"
	# for readtype in READ_TYPES:
	# 	y = []
	# 	ys.append(y)
	# 	for thread in NUM_THREADS:
	# 		curr = path.replace("$readtype", str(readtype))
	# 		curr = curr.replace("$thread", str(thread))
	# 		y.append(results[curr][0])
	# filename = OUTPUT_DIR + "/"+ylabel
	# multiplot(xlabel, x, ylabel, ys, ytitles, filename)

	# # Store backoff retries
	# ys = []
	# ylabel = "Store backoff retries"
	# for readtype in READ_TYPES:
	# 	y = []
	# 	ys.append(y)
	# 	for thread in NUM_THREADS:
	# 		curr = path.replace("$readtype", str(readtype))
	# 		curr = curr.replace("$thread", str(thread))
	# 		y.append(results[curr][1] - results[curr][2])
	# filename = OUTPUT_DIR + "/"+ylabel
	# multiplot(xlabel, x, ylabel, ys, ytitles, filename)

	# for 70 threads
	path = path_exp.replace("$thread", "70")
	x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	xlabel = "Hotspot Data Fraction"
	ytitles = ["Quorum", "Strongly Consistent Quorum"]

	# DistSender backoff retries
	ys = []
	ylabel = "DistSender backoff retries"
	for readtype in READ_TYPES:
		y = []
		ys.append(y)
		for workload in WORKLOADS:
			curr = path.replace("$readtype", str(readtype))
			curr = curr.replace("$workload", workload)
			y.append(results[curr][0])
	filename = OUTPUT_DIR + "/"+ylabel
	multiplot(xlabel, x, ylabel, ys, ytitles, filename)

	# Store backoff retries
	ys = []
	ylabel = "Store backoff retries"
	for readtype in READ_TYPES:
		y = []
		ys.append(y)
		for workload in WORKLOADS:
			curr = path.replace("$readtype", str(readtype))
			curr = curr.replace("$workload", workload)
			y.append(results[curr][1] - results[curr][2])
	filename = OUTPUT_DIR + "/"+ylabel
	multiplot(xlabel, x, ylabel, ys, ytitles, filename)

if __name__ == '__main__':
	os.mkdir(OUTPUT_DIR)

	ycsb_results = my(YCSB_PATH, extractYcsbParams)
	dump_raw_results(ycsb_results, YCSB_PARAMS, OUTPUT_DIR + "/" + "raw-ycsb-results.txt")
	dump_ycsb_graphs(ycsb_results)

	data_results = my(DATA_PATH, extractDataParams)
	dump_raw_results(data_results, DATA_PARAMS, OUTPUT_DIR + "/" + "raw-data-results.txt")
	dump_data_graphs(data_results)
