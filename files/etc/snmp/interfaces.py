#!/usr/bin/env python

import sys
import subprocess
import getopt
import re
import json

def print_usage_and_exit():
  print "Usage: check_lldp.py [-d] [-h] [-i interface]"
  sys.exit(2)

try:
  opts, args = getopt.gnu_getopt(sys.argv[1:], "hdi:", ["debug", "help", "interface"])
except getopt.GetoptError, e:
  print str(e)
  print_usage_and_exit()

DEBUG = 0
single_interface = None

for opt, arg in opts:
  if opt in ("-h", "--help"):
    print_usage_and_exit()
  elif opt in ("-d", "--debug"):
    DEBUG = 1
  elif opt in ("-i", "--interface"):
    single_interface = arg

def debug(msg):
  if DEBUG:
    print "DEBUG: " + msg

def fail(msg):
  print "ERROR: " + msg
  sys.exit(2)

def pp(data):
  if DEBUG:
    print json.dumps(data, indent=2, sort_keys=True)

def parse_all_interfaces(d):
  ret = []
  #something seriously wrong with this LLDP data, bail
  if u'lldp' not in data:
    fail("expected JSON data to have the key 'lldp'")
  lldp = data[u'lldp']
  if not isinstance(lldp, list):
    fail("expecting lldp data to be a list!")
  interfaces = lldp[0]
  if not isinstance(interfaces, dict):
    fail("expecting interfaces data to be a dict!")
  if u'interface' not in interfaces:
    fail("expecting interfaces dict to have the key 'interface'")

  for interface in interfaces['interface']:
    debug("found interface data: %s" % (interface))
    ret.append(clean_interface(parse_one_interface(interface)))
  return ret

#LB: lots of regex to try figure out the switch type
def parse_switch_type_from_data(s):
  make = 'Unknown'
  model = 'Model'

  #LB: we may not have a helpful chassis description...
  if u'descr' in s:
    chassis_description = s['descr'][0]['value']
    #LB: some sort of Cisco...
    if re.search('Cisco', chassis_description):
      make = 'Cisco'
      m = re.match(r"Cisco IOS Software, (\w+) Software", chassis_description)
      if m:
        model = m.group(1)
    elif re.search('Arista', chassis_description):
      make = 'Arista'
      #Arista Networks EOS version 4.14.2F running on an Arista Networks DCS-7010T-48
      m = re.match(r"Arista Networks.*on an Arista Networks (\S+)", chassis_description)
      if m:
        model = m.group(1)
    elif re.search('Linux', chassis_description):
      make = 'Linux'
      model = 'OS'
    elif re.search('FortiGate', chassis_description):
      make = 'FortiGate'
      m = re.match(r"FortiGate-(\S+) ", chassis_description)
      if m:
        model = m.group(1)
    elif re.search('Dell Real Time', chassis_description):
      #Assume all Dell switches are FX2 chassis I/O module switches for now
      make = 'Dell'
      model = 'PowerEdge FX2 FN410S'
  else:
    debug('No chassis description, trying to work out what this is')
    if u'id' in s:
      chassis_id = s['id'][0]
      if u'type' in chassis_id and chassis_id['type'] == 'mac':
        mac = chassis_id['value']
        #LB: the only defining characteristic of an ancient FLS is it's chassis MAC address,
        #which is still not the best way of figuring it out
        if re.search('^(00:12:f2|00:1b:ed)', mac):
          make = 'Foundry'
          model = 'FLS648'
        if re.search('^(74:8e:f8)', mac):
          make = 'Brocade'
          model = 'ICX6450-48'
        if re.search('^(cc:4e:24)', mac):
          make = 'Brocade'
          model = 'ICX7450-48'
        if re.search('^f4:8e:38', mac):
          #Assume all Dell switches are FX2 chassis I/O module switches for now
          make = 'Dell'
          model = 'PowerEdge FX2 FN410S'


  return make + ' ' + model

#LB: convert the very nested LLDP JSON data into a flatter Dict
def parse_one_interface(d):
  debug("parse_one_interface() starting")
  ret = {}
  pp(d)
  ret['name'] = d['name']
  ret['age'] = d['age']
  #LB: not all switches set a Chassis Description, co1ss01 for example
  if u'chassis' in d:
    ret['switch_type'] = parse_switch_type_from_data(d['chassis'][0])
  else:
    ret['switch_type'] = 'Unknown Model'

  ret['switch_name'] = d['chassis'][0]['name'][0]['value']

  #LB: Foundries, Brocades and Linux LLDPD have the port MAC address as the ID, but we want
  #what they call the 'descr' field
  if ret['switch_type'] in [ 'Foundry FLS648', 'Brocade ICX6450-48', 'Brocade ICX7450-48', 'Linux OS' ]:
    ret['port_id'] = d['port'][0]['descr'][0]['value']
  else:
    ret['port_id'] = d['port'][0]['id'][0]['value']

  #Fortigate LLDP data is vastly different to switches
  if ret['switch_type'] in [ 'FortiGate 800C', 'Dell PowerEdge FX2 FN410S' ]:
    ret['port_description'] = d['port'][0]['id'][0]['value']
  else:
    ret['port_description'] = d['port'][0]['descr'][0]['value']

  ret['vlan'] = []
  if u'vlan' in d:
    ret['vlan'].append(d['vlan'][0]['vlan-id'])
  elif u'ppvid' in d:
    for v in d['ppvid']:
      ret['vlan'].append(v['value'])
  else:
    ret['vlan'] = ['unknown']

  pp(ret)
  return ret

#LB: make whatever changes are necessary to the interface data to make it
#"friendly" to compare against Patch Manager.
def clean_interface(d):
  debug("clean_interface() starting")
  #LB: strip the 'Gi' bit from the port ID
  d['port_id'] = re.sub('Gi', '', d['port_id'])

  if d['switch_type'] == 'Foundry FLS648' or d['switch_type'] == 'Brocade ICX6450-48' or d['switch_type'] == 'Brocade ICX7450-48':
    d['port_id'] = re.sub('gabitEthernet', '', d['port_id'])

  if re.search('Arista', d['switch_type']):
    d['port_id'] = re.sub('Ethernet', '', d['port_id'])

  if d['switch_type'] == 'Dell PowerEdge FX2 FN410S':
    d['port_id'] = re.sub('TengabitEthernet ', '', d['port_id'])

  pp(d)
  return d

def print_interfaces_for_snmp(d):
  for i in d:
    link = get_link_status(i['name'])
    print i['name'] + ',' + link + ',' + i['switch_name'] + ',' + i['port_id'] + ',' + '|'.join(i['vlan']) + ',' + i['switch_type']


def get_lldp_data():
  lldctl_args = ['lldpctl', '-f', 'json']
  if single_interface:
    lldctl_args.append(single_interface)
  p = subprocess.Popen(lldctl_args, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  ret = p.wait()
  out, err = p.communicate()

  #We got an error?
  if ret != 0:
    fail("lldpctl returned %d, stderr: %s" % (ret, err))

  return json.loads(out)

def get_link_status(i):
  link = 'no'
  ethtool_args = ['ethtool', i]
  p = subprocess.Popen(ethtool_args, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  ret = p.wait()
  out, err = p.communicate()
  if ret != 0:
    #fail("ethtool returned %d, stderr: %s", % (ret, err))
    pass
  for line in out.split('\n'):
    m = re.match(r"\s+Link detected:\s+(\w+)", line)
    if m:
      link = m.group(1)
  return link

#parse the JSON and build up a list of information about the connected switches
data = get_lldp_data()

#loop through all interfaces
interfaces = parse_all_interfaces(data)
pp(interfaces)

print_interfaces_for_snmp(interfaces)
