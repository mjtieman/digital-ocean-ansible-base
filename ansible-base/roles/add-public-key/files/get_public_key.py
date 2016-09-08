#!/usr/bin/env python
import argparse
import digitalocean

def execute(api_token, key_name):
    manager = digitalocean.Manager(token=api_token)

    filtered_keys = filter(lambda key: key.name == key_name, manager.get_all_sshkeys())
    if not filtered_keys:
        raise StandardError('Could not find SSH key: ' + key_name)
    return filtered_keys[0].public_key

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('api_token', help='The Digital Ocean API token.')
    parser.add_argument('key_name', help='Name of the SSH public to fetch from the account.')
    args = parser.parse_args()

    print execute(args.api_token, args.key_name)
