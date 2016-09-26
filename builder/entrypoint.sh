#!/bin/bash
if [ -n "$PPA_KEY" ]; then
  export KEY=${PPA_KEY}
fi
if [ -n "$JOBS" ]; then
  export JOBS=${JOBS}
else
  export JOBS=1
fi
if [ -n "$CONTRAIL_VNC_REPO" ]; then
  export CONTRAIL_VNC_REPO=${CONTRAIL_VNC_REPO}
else
  export CONTRAIL_VNC_REPO=git@github.com:Juniper/contrail-vnc.git
fi
if [ -n "$BRANCH" ]; then
  export CONTRAIL_BRANCH=${BRANCH}
else
  export CONTRAIL_BRANCH=default
fi
if [ -n "$VERSION" ]; then
  export VERSION=${VERSION}
fi
export GIT_ACCOUNT=${GIT_ACCOUNT}
export USER=root
git config --global user.email $GIT_ACCOUNT

ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
ssh-agent|grep -v "Agent pid" > ~/.ssh/ssh-agent.sh
chmod +x ~/.ssh/ssh-agent.sh
. ~/.ssh/ssh-agent.sh
eval "$(ssh-agent -s)"
ssh-add ${SSH_KEY:-"$HOME/.ssh/id_rsa"}
touch /root/.ssh/known_hosts
grep github ~/.ssh/known_hosts || ssh-keyscan github.com >> ~/.ssh/known_hosts

[ ! -d build ] && mkdir build
cd build
if [[ "$CONTRAIL_BRANCH" == "default" ]]; then
     printf '\n\ny\n' | repo init -u $CONTRAIL_VNC_REPO
else
    printf '\n\ny\n' | repo init -u $CONTRAIL_VNC_REPO -b $CONTRAIL_BRANCH
fi
repo sync

cd third_party
cat <<EOF > fetch_packages.patch
--- fetch_packages.py      2016-09-26 07:21:47.632946648 +0000
+++ fetch_packages.py.new          2016-09-26 07:24:05.812953040 +0000
@@ -232,7 +232,10 @@
     elif pkg.format == 'tbz':
         cmd = ['tar', 'jxvf', ccfile]
     elif pkg.format == 'zip':
-        cmd = ['unzip', '-o', ccfile]
+        if unpackdir:
+            cmd = ['unzip', '-o', '../' + ccfile]
+        else:
+            cmd = ['unzip', '-o', ccfile]
     elif pkg.format == 'npm':
         cmd = ['npm', 'install', ccfile, '--prefix', ARGS['cache_dir']]
     elif pkg.format == 'file':
EOF
patch < fetch_packages.patch
python fetch_packages.py
cd ..
chmod +w packages.make
grep $KEY packages.make
if [ $? -eq 1 ]; then
  sed -i "s/KEYID?=/KEYID?=$KEY/g" packages.make
fi
if [ -n "$VERSION" ]; then
  grep $VERSION packages.make
  if [ $? -eq 1 ]; then
    echo -e "VERSION=$VERSION\n$(cat packages.make)" > packages.make
  fi
fi
sed -i "s#| sed 's/tools\\\/packages//'##g" packages.make
sed -i 's#cp -r -a contrail-web-controller/webroot#cp -r -a \${SB_TOP}/contrail-web-controller/webroot#g' ./tools/packages/debian/contrail-web-controller/debian/rules
sed -i '/libipfix,/ a \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ libipfix-dev,' tools/packages/debian/contrail/debian/control
sed -i '/override_dh_install:/ a \\tcp -r -a ${SB_TOP}\/contrail-web-core\/build-files.sh ${INSTALL_ROOT}' tools/packages/debian/contrail-web-core/debian/rules
grep '^source-package-.*:' packages.make |grep -v ceilometer| cut -d : -f 1 | while read i; do
    make -f packages.make $i
done
cd build/packages
for i in *.dsc; do pkgname=$(echo $i|cut -d "_" -f 1); mv ${pkgname}_*.gz ${pkgname}_*.dsc ${pkgname}/; done
for i in `echo */`; do cd $i;  SCONSFLAGS="-j ${JOBS} -Q debug=1" dpkg-buildpackage -b -rfakeroot -k${KEY}; cd ..; done
