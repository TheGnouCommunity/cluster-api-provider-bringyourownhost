#!/bin/bash

# Copyright 2021 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

set -e

echo Pushing bundles "$*"

imgpkg push -f . -i $@

echo Done
