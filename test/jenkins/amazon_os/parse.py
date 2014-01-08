#!/usr/bin/env python

import yaml
import argparse
import re
import sys

query_choices = ['all_down', 'all_up', 'master_ip', 'first_slave_ip', 'slave_ips', 'master_name', 'slave_names']
parser = argparse.ArgumentParser()
parser.add_argument('-f','--file', help='the file to parse', required=True)
parser.add_argument('query', nargs=1, choices=query_choices, help='what to return')
args = vars(parser.parse_args())

query  = args['query'][0]
stream = open(args['file'], 'r')

try:
  all_data = yaml.load(stream)
  top_elem = all_data[all_data.keys()[0]]
  if 'architecture' in top_elem.keys():
    data = all_data
  else:
    data = top_elem['ec2']
except:
  print 'Cannot read yaml data from ' + args['file']
  exit(12)

hosts = data.keys()
masters=[]
slaves=[]

for h in hosts:
  m = re.match(".*master.*", h)
  if m:
    masters.append(h)
  s = re.match(".*slave.*", h)
  if s:
    slaves.append(h)

if len(masters) == 1:
  master = masters[0]
else:
  print "Found more than one host named something like master: " + masters
  exit(3)

sys.stderr.write('Master: ' + master + '\n')
sys.stderr.write('Slaves: ' + ','.join(slaves) + '\n')

if not query == 'all_down':
  for host in hosts:
    if not data[host] == 'Absent':
      state = data[host].get('instanceState', {}).get('name', '')
      if state in ["terminated", "stopped", "shutting-down"]:
        sys.stderr.write(host + ' appears to be down\n')
        exit(2)
      elif state in ["pending"]:
        sys.stderr.write(host + ' is still pending - come back later\n')
        exit(127)
      else:
        sys.stderr.write(host + ' is ' + state + '\n')
    else:
      sys.stderr.write(host + ' is blissfully absent\n')
      exit(2)
      

if query == "all_up":
  print "Ok"
elif query == "all_down":
  for host in hosts:
    if not data[host] == 'Absent':
      state = data[host].get('instanceState', {}).get('name', '')
      if state in ["pending"]:
        sys.stderr.write(host + ' is still pending - come back later\n')
        exit(127)
      elif not state in ["terminated", "stopped", "shutting-down"]:
        sys.stderr.write(host + ' appears to be up\n')
        exit(2)
      else:
        sys.stderr.write(host + ' is ' + state + '\n')
  print "Ok"
elif query == "master_ip":
  print data[master]['privateIpAddress']
elif query == "master_name":
  print master
elif query == "first_slave_ip":
  if len(slaves) < 1:
    print "no slaves could be identified"
    exit(4)
  print data[slaves[0]]['privateIpAddress']
elif query == "slave_ips":
  ips = []
  for slave in slaves:
    ips.append(data[slave]['private_ips'])
  print ips
elif query == "slave_names":
  print ','.join(slaves)
