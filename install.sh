#!/usr/bin/env bash

REV=8.18.1
REPO=https://github.com/gitleaks/gitleaks
LOCAL_HOOKS_DIR=.githooks
INSTALL_BIN=${LOCAL_HOOKS_DIR}/bin

case $OSTYPE in

  "linux-gnu"*)
    OS=linux
    ;;

  cygwin | msys)
    OS=windows
    ;;

  "darwin"*)
    OS=darwin
    ;;

  *)
    echo -n "Can't autodetect OS type; please enter yours:"
    read OS
    ;;
esac

case `uname -m` in

  x86_64*)
    ARCH=x64
    ;;

  i*86)
    ARCH=x32
    ;;

  arm64 | aarch64)
    ARCH=arm64
    ;;

  *)
    echo -n "Can't autodetect ARCH type; please enter yours:"
    read ARCH
    ;;
esac

echo -e "Trying to download gitleaks_${REV}_${OS}_${ARCH}.tar.gz ...\n"

mkdir -p ${INSTALL_BIN}
curl -L ${REPO}/releases/download/v${REV}/gitleaks_${REV}_${OS}_${ARCH}.tar.gz --fail | tar -xzf - -C ${INSTALL_BIN}

if [ $? -ne 0 ]; then
  echo -e "Download error. Exited with non-zero value."
  exit 1
fi

##
## Set git config hooks.gitleaks
##

git config core.hooksPath .githooks
git config hooks.gitleaks.enable true
git config hooks.gitleaks.bin  ${PWD}/${INSTALL_BIN}/gitleaks

##
## Install git pre-commit hook
##

echo -e "Installing gitleaks pre-commit hook to directory ${LOCAL_HOOKS_DIR}/pre-commit.d\n"

mkdir -p ${LOCAL_HOOKS_DIR}/pre-commit.d

cat <<"EOF" > ${LOCAL_HOOKS_DIR}/pre-commit.d/01-gitleaks
#!/usr/bin/env bash

gitleaksEnabled()
{
    local value

    value=`git config --type bool hooks.gitleaks.enable`

    if [ "${value}" = "true" ]; then
        return 0
    fi

    return 1
}

if ( gitleaksEnabled )
then
  gitleaks=`git config --type path hooks.gitleaks.bin`
  echo "Run gitleaks"
  ${gitleaks} protect --staged -v
fi

EOF

if [ -x .git/hooks/pre-commit ]; then

  echo -e "Adding symlink  ${LOCAL_HOOKS_DIR}/pre-commit.d/02-local-pre-commit to existing pre-commit script"
  ln -sf ${PWD}/.git/hooks/pre-commit ${LOCAL_HOOKS_DIR}/pre-commit.d/02-local-pre-commit

fi

for hook in `find .git/hooks -not -regex ".*/*/*.sample$" -a -not -name pre-commit -type f -exec basename {} \;`
do

  ln -sf ${PWD}/.git/hooks/${hookname} ${LOCAL_HOOKS_DIR}/${hookname}

done 

#
# Switch pre-commit to use scripts from pre-commit.d dir
#

cat <<"EOF" > ${LOCAL_HOOKS_DIR}/pre-commit
#!/usr/bin/env bash
# Pre-commit wrapper script

cd "$(dirname "$0")/pre-commit.d"

for hook in *; do
    bash $hook
    RESULT=$?
    if [ $RESULT != 0 ]; then
        echo "pre-commit.d/$hook returned non-zero: $RESULT, abort commit"
        exit $RESULT
    fi
done

exit 0
EOF

chmod +x ${LOCAL_HOOKS_DIR}/pre-commit.d/01-gitleaks
chmod +x ${LOCAL_HOOKS_DIR}/pre-commit
