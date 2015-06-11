#!/usr/bin/env python
#
# Copyright 2015 Cisco Systems, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""\
Dynamic inventory for Terraform - finds all `.tfstate` files below the working
directory and generates an inventory based on them.
"""
from __future__ import unicode_literals, print_function
import argparse
from collections import defaultdict
from functools import wraps
import json
import os
import re

VERSION = '0.3.0pre'


def tfstates(root=None):
    root = root or os.getcwd()
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            if os.path.splitext(name)[-1] == '.tfstate':
                yield os.path.join(dirpath, name)


def iterresources(filenames):
    for filename in filenames:
        with open(filename, 'r') as json_file:
            state = json.load(json_file)
            for module in state['modules']:
                name = module['path'][-1]
                for key, resource in module['resources'].items():
                    yield name, key, resource

## READ RESOURCES
PARSERS = {}


def _clean_dc(dcname):
    # Consul DCs are strictly alphanumeric with underscores and hyphens -
    # ensure that the consul_dc attribute meets these requirements.
    return re.sub('[^\w_\-]', '-', dcname)


def iterhosts(resources):
    '''yield host tuples of (name, attributes, groups)'''
    for module_name, key, resource in resources:
        resource_type, name = key.split('.', 1)
        try:
            parser = PARSERS[resource_type]
        except KeyError:
            continue

        yield parser(resource, module_name)


def parses(prefix):
    def inner(func):
        PARSERS[prefix] = func
        return func

    return inner


def calculate_mi_vars(func):
    """calculate microservices-infrastructure vars"""

    @wraps(func)
    def inner(*args, **kwargs):
        name, attrs, groups = func(*args, **kwargs)

        # attrs
        if attrs.get('role', '') == 'control':
            attrs['consul_is_server'] = True
        else:
            attrs['consul_is_server'] = False

        # groups
        if attrs.get('publicly_routable', False):
            groups.append('publicly_routable')

        return name, attrs, groups

    return inner


def _parse_prefix(source, prefix, sep='.'):
    for compkey, value in source.items():
        try:
            curprefix, rest = compkey.split(sep, 1)
        except ValueError:
            continue

        if curprefix != prefix or rest == '#':
            continue

        yield rest, value


def parse_attr_list(source, prefix, sep='.'):
    size_key = '%s%s#' % (prefix, sep)
    try:
        size = int(source[size_key])
    except KeyError:
        return []

    attrs = [{} for _ in range(size)]
    for compkey, value in _parse_prefix(source, prefix, sep):
        nth, key = compkey.split(sep, 1)
        attrs[int(nth)][key] = value

    return attrs


def parse_dict(source, prefix, sep='.'):
    return dict(_parse_prefix(source, prefix, sep))


def parse_list(source, prefix, sep='.'):
    return [value for _, value in _parse_prefix(source, prefix, sep)]


def parse_bool(string_form):
    token = string_form.lower()[0]

    if token == 't':
        return True
    elif token == 'f':
        return False
    else:
        raise ValueError('could not convert %r to a bool' % string_form)


@parses('openstack_compute_instance_v2')
@calculate_mi_vars
def openstack_host(resource, module_name):
    raw_attrs = resource['primary']['attributes']
    name = raw_attrs['name']
    groups = []

    attrs = {
        'access_ip_v4': raw_attrs['access_ip_v4'],
        'access_ip_v6': raw_attrs['access_ip_v6'],
        'flavor': parse_dict(raw_attrs, 'flavor',
                             sep='_'),
        'id': raw_attrs['id'],
        'image': parse_dict(raw_attrs, 'image',
                            sep='_'),
        'key_pair': raw_attrs['key_pair'],
        'metadata': parse_dict(raw_attrs, 'metadata'),
        'network': parse_attr_list(raw_attrs, 'network'),
        'region': raw_attrs.get('region', ''),
        'security_groups': parse_list(raw_attrs, 'security_groups'),
        #ansible
        'ansible_ssh_port': 22,
        'ansible_ssh_user': 'centos',
        # workaround for an OpenStack bug where hosts have a different domain
        # after they're restarted
        'host_domain': 'novalocal',
        'use_host_domain': True,
    }

    try:
        attrs.update({
            'ansible_ssh_host': raw_attrs['access_ip_v4'],
            'publicly_routable': True,
        })
    except (KeyError, ValueError):
        attrs.update({'ansible_ssh_host': '', 'publicly_routable': False})

    # attrs specific to microservices-infrastructure
    attrs.update({
        'consul_dc': _clean_dc(attrs['metadata'].get('dc', module_name)),
        'role': attrs['metadata'].get('role', 'none'),
    })

    # add groups based on attrs
    groups.append('os_image=' + attrs['image']['name'])
    groups.append('os_flavor=' + attrs['flavor']['name'])
    groups.extend('os_metadata_%s=%s' % item
                  for item in attrs['metadata'].items())
    groups.append('os_region=' + attrs['region'])

    # groups specific to microservices-infrastructure
    groups.append('role=' + attrs['metadata'].get('role', 'none'))
    groups.append('dc=' + attrs['consul_dc'])

    return name, attrs, groups


@parses('aws_instance')
@calculate_mi_vars
def aws_host(resource, module_name):
    name = resource['primary']['attributes']['tags.Name']
    raw_attrs = resource['primary']['attributes']

    groups = []

    attrs = {
        'ami': raw_attrs['ami'],
        'availability_zone': raw_attrs['availability_zone'],
        'ebs_block_device': parse_attr_list(raw_attrs, 'ebs_block_device'),
        'ebs_optimized': parse_bool(raw_attrs['ebs_optimized']),
        'ephemeral_block_device': parse_attr_list(raw_attrs,
                                                  'ephemeral_block_device'),
        'id': raw_attrs['id'],
        'key_name': raw_attrs['key_name'],
        'private': parse_dict(raw_attrs, 'private',
                              sep='_'),
        'public': parse_dict(raw_attrs, 'public',
                             sep='_'),
        'root_block_device': parse_attr_list(raw_attrs, 'root_block_device'),
        'security_groups': parse_attr_list(raw_attrs, 'security_groups'),
        'subnet': parse_dict(raw_attrs, 'subnet',
                             sep='_'),
        'tags': parse_dict(raw_attrs, 'tags'),
        'tenancy': raw_attrs['tenancy'],
        'vpc_security_group_ids': parse_list(raw_attrs,
                                             'vpc_security_group_ids'),
        # ansible-specific
        'ansible_ssh_port': 22,
        'ansible_ssh_user': raw_attrs['tags.sshUser'],
        'ansible_ssh_host': raw_attrs['public_ip'],
    }

    # attrs specific to microservices-infrastructure
    attrs.update({
        'consul_dc': _clean_dc(attrs['tags'].get('dc', module_name)),
        'role': attrs['tags'].get('role', 'none')
    })

    # groups specific to microservices-infrastructure
    groups.extend(['aws_ami=' + attrs['ami'],
                   'aws_az=' + attrs['availability_zone'],
                   'aws_key_name=' + attrs['key_name'],
                   'aws_tenancy=' + attrs['tenancy']])
    groups.extend('aws_tag_%s=%s' % item for item in attrs['tags'].items())
    groups.extend('aws_vpc_security_group=' + group
                  for group in attrs['vpc_security_group_ids'])
    groups.extend('aws_subnet_%s=%s' % subnet
                  for subnet in attrs['subnet'].items())

    # groups specific to microservices-infrastructure
    groups.append('role=' + attrs['role'])
    groups.append('dc=' + attrs['consul_dc'])

    return name, attrs, groups


@parses('google_compute_instance')
@calculate_mi_vars
def gce_host(resource, module_name):
    name = resource['primary']['id']
    raw_attrs = resource['primary']['attributes']
    groups = []

    # network interfaces
    interfaces = parse_attr_list(raw_attrs, 'network_interface')
    for interface in interfaces:
        interface['access_config'] = parse_attr_list(interface,
                                                     'access_config')
        for key in interface.keys():
            if '.' in key:
                del interface[key]

    # general attrs
    attrs = {
        'can_ip_forward': raw_attrs['can_ip_forward'] == 'true',
        'disks': parse_attr_list(raw_attrs, 'disk'),
        'machine_type': raw_attrs['machine_type'],
        'metadata': parse_dict(raw_attrs, 'metadata'),
        'network': parse_attr_list(raw_attrs, 'network'),
        'network_interface': interfaces,
        'self_link': raw_attrs['self_link'],
        'service_account': parse_attr_list(raw_attrs, 'service_account'),
        'tags': parse_list(raw_attrs, 'tags'),
        'zone': raw_attrs['zone'],
        # ansible
        'ansible_ssh_port': 22,
        'ansible_ssh_user': 'deploy',
    }

    # attrs specific to microservices-infrastructure
    attrs.update({
        'consul_dc': _clean_dc(attrs['metadata'].get('dc', module_name)),
        'role': attrs['metadata'].get('role', 'none'),
    })

    try:
        attrs.update({
            'ansible_ssh_host': interfaces[0]['access_config'][0]['nat_ip'],
            'publicly_routable': True,
        })
    except (KeyError, ValueError):
        attrs.update({'ansible_ssh_host': '', 'publicly_routable': False})

    # add groups based on attrs
    groups.extend('gce_image=' + disk['image'] for disk in attrs['disks'])
    groups.append('gce_machine_type=' + attrs['machine_type'])
    groups.extend('gce_metadata_%s=%s' % (key, value)
                  for (key, value) in attrs['metadata'].items()
                  if key not in set(['sshKeys']))
    groups.extend('gce_tag=' + tag for tag in attrs['tags'])
    groups.append('gce_zone=' + attrs['zone'])

    if attrs['can_ip_forward']:
        groups.append('gce_ip_forward')
    if attrs['publicly_routable']:
        groups.append('gce_publicly_routable')

    # groups specific to microservices-infrastructure
    groups.append('role=' + attrs['metadata'].get('role', 'none'))
    groups.append('dc=' + attrs['consul_dc'])

    return name, attrs, groups


## QUERY TYPES
def query_host(hosts, target):
    for name, attrs, _ in hosts:
        if name == target:
            return attrs

    return {}


def query_list(hosts):
    groups = defaultdict(dict)
    meta = {}

    for name, attrs, hostgroups in hosts:
        for group in set(hostgroups):
            groups[group].setdefault('hosts', [])
            groups[group]['hosts'].append(name)

        meta[name] = attrs

    groups['_meta'] = {'hostvars': meta}
    return groups


def main():

    parser = argparse.ArgumentParser(
        __file__,
        __doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--list',
                       action='store_true',
                       help='list all variables')
    modes.add_argument('--host', help='list variables for a single host')
    modes.add_argument('--version',
                       action='store_true',
                       help='print version and exit')
    parser.add_argument('--pretty',
                        action='store_true',
                        help='pretty-print output JSON')
    parser.add_argument('--nometa',
                        action='store_true',
                        help='with --list, exclude hostvars')
    default_root = os.path.abspath(os.path.join(os.path.dirname(__file__),
                                                '..', '..', ))
    parser.add_argument('--root',
                        default=default_root,
                        help='custom root to search for `.tfstate`s in')

    args = parser.parse_args()

    if args.version:
        print('%s %s' % (__file__, VERSION))
        parser.exit()

    hosts = iterhosts(iterresources(tfstates(args.root)))
    if args.list:
        output = query_list(hosts)
        if args.nometa:
            del output['_meta']
    else:
        output = query_host(hosts, args.host)

    print(json.dumps(output, indent=4 if args.pretty else None))
    parser.exit()


if __name__ == '__main__':
    main()
