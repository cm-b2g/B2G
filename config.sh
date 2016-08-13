#!/bin/bash

REPO=${REPO:-./repo}
sync_flags=""

repo_sync() {
	rm -rf .repo/manifest* &&
	$REPO init -u $GITREPO -b $BRANCH -m $1.xml $REPO_INIT_FLAGS &&
	$REPO sync $sync_flags $REPO_SYNC_FLAGS
	ret=$?
	if [ "$GITREPO" = "$GIT_TEMP_REPO" ]; then
		rm -rf $GIT_TEMP_REPO
	fi
	if [ $ret -ne 0 ]; then
		echo Repo sync failed
		exit -1
	fi
}

case `uname` in
"Darwin")
	# Should also work on other BSDs
	CORE_COUNT=`sysctl -n hw.ncpu`
	;;
"Linux")
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
*)
	echo Unsupported platform: `uname`
	exit -1
esac

GITREPO=${GITREPO:-"git://github.com/kskarthik/b2g-manifest"}
BRANCH=${BRANCH:-b2g/cm-12.1-YOG7D}

while [ $# -ge 1 ]; do
	case $1 in
	-d|-l|-f|-n|-c|-q|--force-sync|-j*)
		sync_flags="$sync_flags $1"
		if [ $1 = "-j" ]; then
			shift
			sync_flags+=" $1"
		fi
		shift
		;;
	--help|-h)
		# The main case statement will give a usage message.
		break
		;;
	-*)
		echo "$0: unrecognized option $1" >&2
		exit 1
		;;
	*)
		break
		;;
	esac
done

GIT_TEMP_REPO="tmp_manifest_repo"
if [ -n "$2" ]; then
	GITREPO=$GIT_TEMP_REPO
	rm -rf $GITREPO &&
	git init $GITREPO &&
	cp $2 $GITREPO/$1.xml &&
	cd $GITREPO &&
	git add $1.xml &&
	git commit -m "manifest" &&
	git branch -m $BRANCH &&
	cd ..
fi

echo MAKE_FLAGS=-j$((CORE_COUNT + 2)) > .tmp-config
echo GECKO_OBJDIR=$PWD/objdir-gecko >> .tmp-config
echo DEVICE_NAME=$1 >> .tmp-config

case "$1" in
"galaxy-s2"|"galaxy-nexus"|"nexus-s"|"nexus-s-4g"|"otoro"|"unagi"|"keon"|"inari"|"hamachi"|"peak"|"helix"|"wasabi"|"flatfish"|"tarako"|"pandaboard"|"rpi"|"vixen"|"flo"|"dolphin"|"dolphin-512")
	echo
	echo "WARNING: You are trying to build a legacy device. Legacy devices are too old"
	echo "for Gecko master branch or simply not maintained. If you wish to continue try:"
	echo
	echo "./legacy-config.sh $1"
	echo
	exit -1
	;;

"emulator"|"emulator-jb"|"emulator-kk"|"emulator-l")
	echo DEVICE=generic >> .tmp-config &&
	echo LUNCH=full-eng >> .tmp-config &&
	repo_sync $1
	;;

"emulator-x86"|"emulator-x86-jb"|"emulator-x86-kk"|"emulator-x86-l")
	echo DEVICE=generic_x86 >> .tmp-config &&
	echo LUNCH=full_x86-eng >> .tmp-config &&
	repo_sync $1
	;;

"nexus-4"|"nexus-4-kk")
	echo DEVICE=mako >> .tmp-config &&
	repo_sync $1
	;;

"nexus-5"|"nexus-5-l")
	echo DEVICE=hammerhead >> .tmp-config &&
	repo_sync $1
	;;

"nexus-6-l")
	echo DEVICE=shamu >> .tmp-config &&
	echo PRODUCT_NAME=aosp_shamu >> .tmp-config &&
	repo_sync $1
	;;

"flame"|"flame-kk"|"flame-l")
	echo PRODUCT_NAME=flame >> .tmp-config &&
	repo_sync $1
	;;

"leo-kk")
	echo PRODUCT_NAME=leo >> .tmp-config &&
	repo_sync $1
	;;

"aries|aries-kk")
	echo PRODUCT_NAME=aries >> .tmp-config &&
	repo_sync aries
	;;

"leo-l"|"aries-l"|"scorpion-l"|"sirius-l"|"honami-l"|"amami-l"|"tianchi-l"|"flamingo-l"|"eagle-l"|"seagull-l")
	echo PRODUCT_NAME=$1 | sed 's/..$//' >> .tmp-config &&
	repo_sync sony-aosp-l
	;;

"leo-l-cm"|"aries-l-cm"|"scorpion-l-cm"|"sirius-l-cm"|"honami-l-cm"|"amami-l-cm"|"tianchi-l-cm"|"seagull-cm"|"eagle-cm"|"flamingo-l-cm")
	echo PRODUCT_NAME=$1 | sed 's/.....$//' >> .tmp-config &&
	repo_sync sony-cm-l
	;;

"cm-porting")
	echo PRODUCT_NAME=$1 >> .tmp-config &&
	repo_sync base-l-cm
	;;

"crackling-l-cm")
	echo PRODUCT_NAME=full_$1 | sed 's/.....$//' >> .tmp-config &&
	repo_sync wileyfox
	;;

"tomato-l-cm")
	echo PRODUCT_NAME=full_$1 | sed 's/.....$//' >> .tmp-config &&
	repo_sync yu
	;;

"d802-l-cm"|"d855-l-cm")
	echo PRODUCT_NAME=full_$1 | sed 's/.....$//' >> .tmp-config &&
	repo_sync lge
	;;

*)
	echo "Usage: $0 [-cdflnq] [-j <jobs>] [--force-sync] (device name)"
	echo "Flags are passed through to |./repo sync|."
	echo
	echo Valid devices to configure are:
	echo
	echo "$(tput setaf 1)$(tput bold)* [LEGACY] AOSP Ice Cream Sandwich base$(tput sgr 0)"
	echo - emulator
	echo - emulator-x86
	echo
	echo "$(tput setaf 1)$(tput bold)* [LEGACY] AOSP Jellybean base$(tput sgr 0)"
	echo - emulator-jb
	echo - emulator-x86-jb
	echo - nexus-4
	echo - flame
	echo
	echo "$(tput setaf 3)$(tput bold)* AOSP KitKat base$(tput sgr 0)"
	echo - emulator-kk
	echo - emulator-x86-kk
	echo - nexus-4-kk
	echo - nexus-5
	echo - flame-kk
	echo "- leo-kk    (Z3 KK)"
	echo "- aries-kk  (Z3 Compact KK)"
	echo
	echo "$(tput setaf 2)$(tput bold)* AOSP Lollipop base$(tput sgr 0)"
	echo - emulator-l
	echo - emulator-x86-l
	echo - nexus-5-l
	echo - nexus-6-l
	echo - flame-l
	echo "- leo-l       (Z3 L)"
	echo "- aries-l     (Z3 Compact L)"
	echo "- scorpion-l  (Z3 Tablet Compact L)"
	echo "- sirius-l    (Z2 L)"
	echo "- honami-l    (Z1 L)"
	echo "- amami-l     (Z1 Compact L)"
	echo "- tianchi-l   (T2U L)"
	echo "- seagull-l   (T3 L)"
	echo "- eagle-l     (M2 L)"
	echo "- flamingo-l  (E3 L)"
	echo ""
	echo "$(tput bold)* Base for porting CyanogenMod devices$(tput sgr 0)"
	echo "- cm-porting"
	echo
	echo "$(tput setaf 6)$(tput bold)* Sony Xperia devices on CyanogenMod$(tput sgr 0)"
	echo "- $(tput setaf 6)leo-l-cm$(tput sgr 0)      (Z3 CM+)"
	echo "- $(tput setaf 6)aries-l-cm$(tput sgr 0)    (Z3 Compact CM+)"
	echo "- $(tput setaf 6)scorpion-l-cm$(tput sgr 0) (Z3 Tablet Compact CM+)"
	echo "- $(tput setaf 6)sirius-l-cm$(tput sgr 0)   (Z2 CM+)"
	echo "- $(tput setaf 6)honami-l-cm$(tput sgr 0)   (Z1 CM+)"
	echo "- $(tput setaf 6)amami-l-cm$(tput sgr 0)    (Z1 Compact CM+)"
	echo "- $(tput setaf 6)tianchi-l-cm$(tput sgr 0)  (T2 Ultra CM+)"
	echo "- $(tput setaf 6)seagull-l-cm$(tput sgr 0)  (T3 CM+)"
	echo "- $(tput setaf 6)eagle-l-cm$(tput sgr 0)    (M2 CM+)"
	echo "- $(tput setaf 6)flamingo-l-cm$(tput sgr 0) (E3 CM+)"
	echo ""
	echo "$(tput setaf 6)$(tput bold)* Official CyanogenMod devices$(tput sgr 0)"
	echo "- $(tput setaf 6)crackling-l-cm$(tput sgr 0)  (Wileyfox Swift)"
	echo "- $(tput setaf 6)tomato-l-cm$(tput sgr 0)  (Yu Yureka)"
	echo ""
	echo "$(tput setaf 6)$(tput bold)* Ported CyanogenMod devices$(tput sgr 0)"
	echo "- $(tput setaf 6)d802-l-cm$(tput sgr 0)  (LG G2 Intl)"
	echo "- $(tput setaf 6)d855-l-cm$(tput sgr 0)  (Lg G3 Intl)"
	exit -1
	;;
esac

if [ $? -ne 0 ]; then
	echo Configuration failed
	exit -1
fi

mv .tmp-config .config

echo Run \|./build.sh\| to start building
