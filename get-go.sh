#!/bin/bash

hm="\n
Usage:\n
   -f   force install, overwrite previous executable\n
   -k   keep download file\n
   -p   input installed prefix, ex: /home/user/ (default: /usr/local/)\n
   -v   installed go version (ex: 1.5.2)\n
   -b   enable automatically fetch beta version, default as False
   -h   show this message\n
"

platform=unknow
this=`uname`

if [ "$this" == "Linux" ]; then
    platform=linux
elif [ "$this" == "Darwin" ]; then
    platform=darwin  #OSX
elif [ "$this" == "FreeBSD" ]; then
    platform=freebsd
fi

keep=0
pre=/usr/local
force=0
version=0
beta=0

while getopts "fkhbp:v:" o; do
    case $o in
        f)      force=1
                ;;
        k)      keep=1
                ;;
        p)      pre=$OPTARG
                ;;
        v)      version=$OPTARG
                ;;
        h)      echo -e $hm >&2
                exit 1
                ;;
        b)      beta=1
                ;;
        \?)     echo "invalid options -$OPTARG" >&2
                exit 1
                ;;
    esac
done

echo "OPTS: version=$version platfrom=$platform keep=$keep, pre=$pre, force=$force"

# check existing
if [ -e $pre/go/ ]; then
    if [ "$force" == "0" ]; then
        echo -e "Found existing golang at $pre/go !\nOverwrite existing with -f option, or install another with prefix -p PREFIX"
        exit 1
    fi
fi

# start install
echo "Start installing go$version under $pre/ ..."

# download golang page and package
curl https://golang.org/dl/ -o dl.html
if [ "$version" == "0" ]; then
    # get version
    if [ "$beta" == "1" ]; then
        version=$(grep -o "id=\"go[0-9]\.[0-9].\"" dl.html | sed "s/id=\"go//g" | sort -r | sed -n "1p")
    else
        version=$(grep -o "id=\"go[0-9]\.[0-9]\.*[0-9]*\"" dl.html | sed "s/id=\"go//g" | sort -r | sed -n "1p")
    fi
    echo "Automatically fetch latest version: $version"
fi

curl https://storage.googleapis.com/golang/go$version.$platform-amd64.tar.gz -o go.tar.bz
if grep -q "$(shasum go.tar.bz | awk '{print $1}')" dl.html; then
    tar -C $pre -xzf go.tar.bz
else
    echo -e "SHA1 checksum fail"
    rm dl.html go.tar.bz
    exit 1
fi

# clear env
rm dl.html
if [ "$keep" == "0" ];then
    rm go.tar.bz
fi

# setup env
export PATH=$PATH:$pre/go/bin

echo -e "
PATH already be exported with:\n\n
  $ export PATH=\$PATH:$pre/go/bin\n\n
If you want the environment auto-setup, please add following configs to your .*shrc\n\n
  PATH=\$PATH:$pre/go/bin\n
  GOROOT=$pre/go\n
  GOPATH=/path/you/to/store/your/go/package/\n\n
then enjoy your go programming :)
"
