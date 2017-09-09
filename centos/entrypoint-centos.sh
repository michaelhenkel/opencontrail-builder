#!/bin/bash
export LC_ALL=C
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

ssh-agent|grep -v "Agent pid" > ~/.ssh/ssh-agent.sh
chmod +x ~/.ssh/ssh-agent.sh
. ~/.ssh/ssh-agent.sh
eval "$(ssh-agent -s)"
ssh-add ${SSH_KEY:-"$HOME/.ssh/id_rsa"}
touch /root/.ssh/known_hosts
grep github ~/.ssh/known_hosts || ssh-keyscan github.com >> ~/.ssh/known_hosts

[ ! -d ~/build ] && mkdir ~/build
cd ~/build
if [[ "$CONTRAIL_BRANCH" == "default" ]]; then
     printf '\n\ny\n' | repo init -u $CONTRAIL_VNC_REPO
else
    printf '\n\ny\n' | repo init -u $CONTRAIL_VNC_REPO -b $CONTRAIL_BRANCH
fi

cat <<EOF > ~/build/.repo/manifest.xml
<manifest>
<remote name="github" fetch=".."/>

<default revision="${CONTRAIL_BRANCH}" remote="github"/>

<project name="contrail-build" remote="github" path="tools/build">
  <copyfile src="SConstruct" dest="SConstruct"/>
</project>
<project name="contrail-controller" remote="github" path="controller"/>
<project name="contrail-vrouter" remote="github" path="vrouter"/>
<project name="contrail-third-party" remote="github" path="third_party"/>
<project name="contrail-generateDS" remote="github" path="tools/generateds"/>
<project name="contrail-sandesh" remote="github" path="tools/sandesh"/>
<project name="contrail-packages" remote="github" path="tools/packages">
  <copyfile src="packages.make" dest="packages.make"/>
</project>
<project name="contrail-packaging" remote="github" path="tools/packaging"/>
<project name="contrail-provisioning" remote="github" path="tools/provisioning"/>
<project name="contrail-nova-vif-driver" remote="github" path="openstack/nova_contrail_vif"/>
<project name="contrail-neutron-plugin" remote="github" path="openstack/neutron_plugin"/>
<project name="contrail-nova-extensions" remote="github" path="openstack/nova_extensions"/>
<project name="contrail-heat" remote="github" path="openstack/contrail-heat"/>
<project name="contrail-web-storage" remote="github"/>
<project name="contrail-web-server-manager" remote="github"/>
<project name="contrail-web-controller" remote="github"/>
<project name="contrail-web-core" remote="github"/>
<project name="contrail-webui-third-party" remote="github" path="contrail-webui-third-party"/>

</manifest>
EOF
repo sync
cd ~/build/third_party
python fetch_packages.py
cd ~/build/tools/packaging/common/rpm
SCONSFLAGS="-j $JOBS -Q debug=1" make all
if [ $? -ne 0 ]; then
  SCONSFLAGS="-j $JOBS -Q debug=1" make all
fi

if [ ! -d /tmp/packages ]; then
  mkdir /tmp/packages
fi
cp -r ~/build/controller/build/package-build/RPMS/* /tmp/packages
