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
import json
import os

VERSION = '0.1.0pre'


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

# READ RESOURCES
PARSERS = {}


def iterhosts(resources):
    """yield host tuples of (name, attributes, groups)"""
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
def openstack_host(resource, module_name):
    raw_attrs = resource['primary']['attributes']
    name = raw_attrs['name']
    groups = []

    attrs = {
        'access_ip_v4': raw_attrs['access_ip_v4'],
        'access_ip_v6': raw_attrs['access_ip_v6'],
        'flavor': parse_dict(raw_attrs, 'flavor', sep='_'),
        'id': raw_attrs['id'],
        'image': parse_dict(raw_attrs, 'image', sep='_'),
        'key_pair': raw_attrs['key_pair'],
        'metadata': parse_dict(raw_attrs, 'metadata'),
        'network': parse_attr_list(raw_attrs, 'network'),
        'region': raw_attrs.get('region', ''),
        'security_groups': parse_list(raw_attrs, 'security_groups'),
        # ansible
        'ansible_ssh_port': 22,
        'ansible_ssh_user': raw_attrs.get('metadata.ssh_user', 'centos'),
        'ansible_ssh_host': raw_attrs['access_ip_v4'],
        # workaround for an OpenStack bug where hosts have a different domain
        # after they're restarted
        'host_domain': 'novalocal',
        'use_host_domain': True,
        # generic
        'public_ipv4': raw_attrs['access_ip_v4'],
        'private_ipv4': raw_attrs['access_ip_v4'],
        'provider': 'openstack',
    }

    if 'floating_ip' in raw_attrs:
        attrs['private_ipv4'] = raw_attrs['network.0.fixed_ip_v4']

    attrs.update({
        'role': attrs['metadata'].get('role', 'none'),
    })

    # add groups based on attrs
    groups.append('os_image=' + attrs['image']['name'])
    groups.append('os_flavor=' + attrs['flavor']['name'])
    groups.extend('os_metadata_%s=%s' % item
                  for item in attrs['metadata'].items())
    groups.append('os_region=' + attrs['region'])
    groups.append('role=' + attrs['metadata'].get('role', 'none'))

    return name, attrs, groups


# QUERY TYPES
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


def query_hostfile(hosts):
    out = ['## begin hosts generated by terraform.py ##']
    out.extend(
        '{}\t{}'.format(attrs['ansible_ssh_host'].ljust(16), name)
        for name, attrs, _ in hosts
    )

    out.append('## end hosts generated by terraform.py ##')
    return '\n'.join(out)


def main():
    parser = argparse.ArgumentParser(
        __file__, __doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter, )
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--list',
                       action='store_true',
                       help='list all variables')
    modes.add_argument('--host', help='list variables for a single host')
    modes.add_argument('--version',
                       action='store_true',
                       help='print version and exit')
    modes.add_argument('--hostfile',
                       action='store_true',
                       help='print hosts as a /etc/hosts snippet')
    parser.add_argument('--pretty',
                        action='store_true',
                        help='pretty-print output JSON')
    parser.add_argument('--nometa',
                        action='store_true',
                        help='with --list, exclude hostvars')
    default_root = os.environ.get('TERRAFORM_STATE_ROOT',
                                  os.path.abspath(os.path.join(
                                      os.path.dirname(__file__),
                                      '..', '..', )))
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
        print(json.dumps(output, indent=4 if args.pretty else None))
    elif args.host:
        output = query_host(hosts, args.host)
        print(json.dumps(output, indent=4 if args.pretty else None))
    elif args.hostfile:
        output = query_hostfile(hosts)
        print(output)

    parser.exit()


if __name__ == '__main__':
    main()
