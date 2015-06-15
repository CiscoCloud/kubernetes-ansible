#!/usr/bin/python
# -*- coding: utf-8 -*-
 
import json
 
f = open('terraform.tfstate', 'r')
obj = json.load(f)
 
hosts = dict()
 
for i in obj['modules']:
    if any(i['resources']):
        resources = i['resources']
        for resource in resources:
            attributes = resources[resource]['primary']['attributes']
            if 'access_ip_v4' in attributes.keys():
                hosts.update({
                    attributes['name']: attributes['access_ip_v4']
                })
 
for host in sorted(hosts):
    print("%s\t%s" % (hosts[host], host))
