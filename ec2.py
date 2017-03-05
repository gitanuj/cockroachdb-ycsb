#
# Usage: python ec2.py <args>
#	start <crdb_ami_id> <ycsb_ami_id> <cluster_size> <machine_type>
#		Returns:	<ids>
#					<tags>
#					<public ips>
#					<private ips>
#
#	stop <ids>
#

import boto3
import time
import sys

def create_instances(ec2, ami_id, count, machine_type):
	instances = ec2.create_instances(ImageId=ami_id, MinCount=count, MaxCount=count, InstanceType=machine_type, KeyName='tanuj', SecurityGroups=['cockroach-test'])
	return [ i.id for i in instances ]

def wait_until_running(ec2, ids):
	while(1):
		time.sleep(1)
		allRunning = True
		for i, instance in enumerate(ec2.instances.filter(InstanceIds=ids)):
			if instance.state['Name'] != 'running':
				allRunning = False

		if allRunning:
			break

def tag_instances(ec2, ids, tags):
	for i, instance in enumerate(ec2.instances.filter(InstanceIds=ids)):
		instance.create_tags(Tags=[
			{
				"Key": "Name",
				"Value": tags[i]
			}
		])

def start(ec2, crdb_ami_id, ycsb_ami_id, cluster_size, machine_type):
	crdb_ids = create_instances(ec2, crdb_ami_id, cluster_size, machine_type)
	ycsb_ids = create_instances(ec2, ycsb_ami_id, 1, machine_type)
	wait_until_running(ec2, crdb_ids)
	wait_until_running(ec2, ycsb_ids)

	crdb_tags = [ "c" + str(i) for i in range(0, len(crdb_ids)) ]
	ycsb_tags = [ "y" + str(i) for i in range(0, len(ycsb_ids)) ]
	tag_instances(ec2, crdb_ids, crdb_tags)
	tag_instances(ec2, ycsb_ids, ycsb_tags)

	return crdb_ids+ycsb_ids, crdb_tags+ycsb_tags

def stop(ec2, ids):
	ec2.instances.filter(InstanceIds=ids).terminate()

def dump_array(name, array):
	print name + "=( " + " ".join(array) + " )"

def dump_info(ec2, ids, tags):
	public_ips = []
	private_ips = []

	instances = ec2.instances.filter(InstanceIds=ids)
	for id in ids:
		for instance in instances:
			if instance.id == id:
				public_ips.append(instance.public_ip_address)
				private_ips.append(instance.private_ip_address)
				break

	dump_array("all_ec2_ids", ids)
	dump_array("all_names", tags)
	dump_array("all_ips", public_ips)
	dump_array("all_internal_ips", private_ips)

def main():
	ec2 = boto3.resource('ec2')

	if sys.argv[1] == "start":
		ids, tags = start(ec2, sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5])
		dump_info(ec2, ids, tags)
	else:
		stop(ec2, sys.argv[2:])

if __name__ == '__main__':
	main()
