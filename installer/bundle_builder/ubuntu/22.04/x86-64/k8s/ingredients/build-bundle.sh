#!/bin/bash

# Copyright 2021 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0


INGREDIENTS_PATH=$1
CONFIG_PATH=$2
SCRIPTS_PATH=$3

set -e

rm -rf $INGREDIENTS_PATH/$4.tar

echo Building bundle...

echo Ingredients $INGREDIENTS_PATH
ls -l $INGREDIENTS_PATH

echo Strip version to well-known names
# Mandatory
cp $INGREDIENTS_PATH/*containerd.io*.deb containerd.io.deb
cp $INGREDIENTS_PATH/*kubeadm*.deb ./kubeadm.deb
cp $INGREDIENTS_PATH/*kubelet*.deb ./kubelet.deb
cp $INGREDIENTS_PATH/*kubectl*.deb ./kubectl.deb
# Optional
cp  $INGREDIENTS_PATH/*cri-tools*.deb cri-tools.deb > /dev/null | true
cp  $INGREDIENTS_PATH/*kubernetes-cni*.deb kubernetes-cni.deb > /dev/null | true

echo Configuration $CONFIG_PATH
ls -l $CONFIG_PATH

echo Add configuration under well-known name
(cd $CONFIG_PATH && tar -cvf conf.tar *)
cp $CONFIG_PATH/conf.tar .

echo Creating bundle tar
tar -cvf /bundle/bundle.tar *
cp /bundle/bundle.tar $INGREDIENTS_PATH/bundle.tar

if [ -d $SCRIPTS_PATH ];
then
    echo Add scripts under well-known name
    (cd $SCRIPTS_PATH && tar -cvf scripts.tar *)
    cp $SCRIPTS_PATH/scripts.tar $INGREDIENTS_PATH/scripts.tar
fi

echo Done
