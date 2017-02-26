#
# python record-raft-status.py <num_of_recordings>
#
import requests, json, time

URL = "http://128.111.44.237:8081/_status/raft"

def fetch_status():
	data = None
	try:
		response = requests.get(URL)
		data = response.json()
	finally:
		return data

def record_status():
	data = fetch_status()
	if data is None:
		return

	ranges = data["ranges"]

	timestamp = str(int(time.time()))
	output = [timestamp]
	for range in ranges.values():
		rangeId = range["rangeId"]
		lead = range["nodes"][0]["range"]["raftState"]["lead"]
		output.append("r" + rangeId + " " + lead)
		
	print(", ".join(output))

def main():
	while True:
		record_status()
		time.sleep(2)

if __name__ == '__main__':
	main()