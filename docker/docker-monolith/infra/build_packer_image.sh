#!/bin/bash
packer build  -var-file=packer/variables.json packer/docker-host.json
