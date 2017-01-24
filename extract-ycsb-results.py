#
# Extracts results for a benchmark done using different number of threads for Google Sheets
# python extract-ycsb-results.py <results-dir>
#
import sys

DIRS = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80]

def extract(param1, param2):
	result = []

	for d in DIRS:
		file = sys.argv[1] + "/" + str(d) + "/ycsb-results"
		for line in open(file):
			vals = line.split(', ')
			
			if len(vals) > 2:
				if (vals[0] == param1) and (vals[1] == param2):
					result.append(vals[2].rstrip())

	return result

def main():
	print("[OVERALL], Throughput(ops/sec)")
	result = extract('[OVERALL]', 'Throughput(ops/sec)')
	print("\t".join(result))

	print("[UPDATE], AverageLatency(us)")
	result = extract('[UPDATE]', 'AverageLatency(us)')
	print("\t".join(result))
	print("[UPDATE], 95thPercentileLatency(us)")
	result = extract('[UPDATE]', '95thPercentileLatency(us)')
	print("\t".join(result))

	print("[READ], AverageLatency(us)")
	result = extract('[READ]', 'AverageLatency(us)')
	print("\t".join(result))
	print("[READ], 95thPercentileLatency(us)")
	result = extract('[READ]', '95thPercentileLatency(us)')
	print("\t".join(result))

if __name__ == '__main__':
	main()
