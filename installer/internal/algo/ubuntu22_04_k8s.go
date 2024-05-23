// Copyright 2022 VMware, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package algo

import (
	"bytes"
	"context"
	"fmt"
	"html/template"
)

// UbuntuK8SInstaller represent the installer implementation for Ubuntu distribution
type UbuntuK8SInstaller struct {
	install   string
	uninstall string
}

// NewUbuntuK8SInstaller will return new UbuntuK8SInstaller instance
func NewUbuntuK8SInstaller(ctx context.Context, osbundle, arch, bundleAddrs, k8sVersion string) (*UbuntuK8SInstaller, error) {
	parseFn := func(script string) (string, error) {
		parser, err := template.New("parser").Parse(script)
		if err != nil {
			return "", fmt.Errorf("unable to parse install script")
		}
		var tpl bytes.Buffer
		if err = parser.Execute(&tpl, map[string]string{
			"BundleAddrs": bundleAddrs,
			"K8sVersion":  k8sVersion,
			"Arch":        arch,
			// ImgpkgVersion defines the imgpkg version that will be installed on host if imgpkg is not already installed
			"ImgpkgVersion":      "v0.42.1",
			"BundleDownloadPath": "{{.BundleDownloadPath}}",
		}); err != nil {
			return "", fmt.Errorf("unable to apply install parsed template to the data object")
		}
		return tpl.String(), nil
	}

	install, err := parseFn(DoPre + DoUbuntuK8S + DoPost)
	if err != nil {
		return nil, err
	}
	uninstall, err := parseFn(DoPre + UndoUbuntuK8S + DoPost)
	if err != nil {
		return nil, err
	}
	return &UbuntuK8SInstaller{
		install:   install,
		uninstall: uninstall,
	}, nil
}

// Install will return k8s install script
func (s *UbuntuK8SInstaller) Install() string {
	return s.install
}

// Uninstall will return k8s uninstall script
func (s *UbuntuK8SInstaller) Uninstall() string {
	return s.uninstall
}

// contains the installation and uninstallation steps for the supported os and k8s
var (
	DoPre = `
set -euox pipefail

BUNDLE_DOWNLOAD_PATH={{.BundleDownloadPath}}
BUNDLE_ADDR={{.BundleAddrs}}
K8S_VERSION={{.K8sVersion}}
IMGPKG_VERSION={{.ImgpkgVersion}}
ARCH={{.Arch}}
BUNDLE_PATH=$BUNDLE_DOWNLOAD_PATH/${BUNDLE_ADDR//\:/-}

if ! command -v imgpkg >>/dev/null; then
	echo "installing imgpkg"	
	
	if command -v wget >>/dev/null; then
		dl_bin="wget -nv -O-"
	elif command -v curl >>/dev/null; then
		dl_bin="curl -s -L"
	else
		echo "installing curl"
		apt-get install -y curl
		dl_bin="curl -s -L"
	fi
	
	$dl_bin https://github.com/carvel-dev/imgpkg/releases/download/$IMGPKG_VERSION/imgpkg-linux-$ARCH > /tmp/imgpkg
	mv /tmp/imgpkg /usr/local/bin/imgpkg
	chmod +x /usr/local/bin/imgpkg
fi

echo "downloading bundle"
mkdir -p $BUNDLE_PATH
imgpkg pull -i $BUNDLE_ADDR-scripts -o $BUNDLE_PATH-scripts
tar -C $BUNDLE_PATH-scripts/ -xvf "$BUNDLE_PATH-scripts/scripts.tar"
chmod +x $BUNDLE_PATH-scripts/*.sh
imgpkg pull -i $BUNDLE_ADDR -o $BUNDLE_PATH
tar -C $BUNDLE_PATH/ -xvf "$BUNDLE_PATH/bundle.tar"`

	DoUbuntuK8S = `
K8S_VERSION=$K8S_VERSION BUNDLE_PATH=$BUNDLE_PATH $BUNDLE_PATH-scripts/install.sh`

	UndoUbuntuK8S = `
K8S_VERSION=$K8S_VERSION BUNDLE_PATH=$BUNDLE_PATH $BUNDLE_PATH-scripts/uninstall.sh`

	DoPost = `
rm -rf $BUNDLE_PATH
rm -rf $BUNDLE_PATH-scripts`
)
