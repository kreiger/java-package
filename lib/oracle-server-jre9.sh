# Detect product
j2se_detect_oracle_server_j9re=oracle_server_j9re_detect
oracle_server_j9re_detect() {
  j2se_release=0

  # Update or GA release (serverjre-9_linux-x64_bin.tar.gz)
  # Update release format isn't decided yet (might be 9.1, might be 18.3)
  if [[ $archive_name =~ serverjre-(9)()_linux-(x86|x64)_bin\.tar\.gz ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[2]}
    j2se_arch=${BASH_REMATCH[3]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update"
      j2se_version=${j2se_release}u${j2se_update}${revision}
    else
      j2se_version_name="$j2se_release GA"
      j2se_version=${j2se_release}${revision}
    fi
  fi

  # Early Access Release (serverjre-9-ea+123_linux-x64_bin.tar.gz)
  if [[ $archive_name =~ serverjre-(9)()-ea\+([0-9]+)_linux-(x86|x64)_bin\.tar\.gz ]]
  then
    j2se_release=${BASH_REMATCH[1]}
    j2se_update=${BASH_REMATCH[2]}
    j2se_build=${BASH_REMATCH[3]}
    j2se_arch=${BASH_REMATCH[4]}
    if [[ $j2se_update != "" ]]
    then
      j2se_version_name="$j2se_release Update $j2se_update Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}u${j2se_update}~ea-build-${j2se_build}${revision}
    else
      j2se_version_name="$j2se_release Early Access Release Build $j2se_build"
      j2se_version=${j2se_release}~ea-build-${j2se_build}${revision}
    fi
  fi

  if [[ $j2se_release > 0 ]]
  then
    j2se_priority=$((310 + $j2se_release - 1))
    j2se_expected_min_size=85 #Mb

    # check if the architecture matches
    let compatible=1

    case "${DEB_BUILD_ARCH:-$DEB_BUILD_GNU_TYPE}" in
      i386|i486-linux-gnu)
        if [[ "$j2se_arch" != "x86" ]]; then compatible=0; fi
        ;;
      amd64|x86_64-linux-gnu)
        if [[ "$j2se_arch" != "x64" ]]; then compatible=0; fi
        ;;
    esac

    if [[ $compatible == 0 ]]
    then
      echo "The archive $archive_name is not supported on the ${DEB_BUILD_ARCH} architecture"
      return
    fi


    cat << EOF

Detected product:
    Server Java(TM) Runtime Environment (JRE)
    Standard Edition, Version $j2se_version_name
    Oracle(TM)
EOF
    if read_yn "Is this correct [Y/n]: "; then
      j2se_found=true
      j2se_required_space=$(( $j2se_expected_min_size * 2 + 20 ))
      j2se_vendor="oracle"
      j2se_title="Java Platform, Standard Edition $j2se_release Server Runtime Environment"

      j2se_install=oracle_server_j9re_install
      j2se_remove=oracle_server_j9re_remove
      j2se_jinfo=oracle_server_j9re_jinfo
      j2se_control=oracle_server_j9re_control

      oracle_bin_hl="java jrunscript keytool rmid rmiregistry"
      oracle_lib_hl="jexec"
      oracle_bin_jdk="jar jarsigner javac jcmd jdb jinfo jmap jps jstack jstat jstatd schemagen serialver wsgen wsimport xjc"

      j2se_package="$j2se_vendor-java$j2se_release-server-jre"
      exlude_libs="appletviewer libawt_xawt.so libsplashscreen.so policytool"
      j2se_run
    fi
  fi
}

oracle_server_j9re_install() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

install_no_man_alternatives $jvm_base$j2se_name/bin $oracle_bin_hl
install_no_man_alternatives $jvm_base$j2se_name/lib $oracle_lib_hl
install_no_man_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk
EOF
}

oracle_server_j9re_remove() {
    cat << EOF
if [ ! -e "$jvm_base$j2se_name/debian/info" ]; then
    exit 0
fi

remove_alternatives $jvm_base$j2se_name/bin $oracle_bin_hl
remove_alternatives $jvm_base$j2se_name/lib $oracle_lib_hl
remove_alternatives $jvm_base$j2se_name/bin $oracle_bin_jdk
EOF
}

oracle_server_j9re_jinfo() {
    cat << EOF
name=$j2se_name
priority=${priority_override:-$j2se_priority}
section=main
EOF
    jinfos "hl" $jvm_base$j2se_name/bin/ $oracle_bin_hl
    jinfos "hl" $jvm_base$j2se_name/lib/ $oracle_lib_hl
    jinfos "jre" $jvm_base$j2se_name/bin/ $oracle_bin_jre
    jinfos "jdk" $jvm_base$j2se_name/bin/ $oracle_bin_jdk
}

oracle_server_j9re_control() {
    j2se_control
    if [ "$create_cert_softlinks" == "true" ]; then
        depends="ca-certificates-java"
    fi
    for i in `seq 5 ${j2se_release}`;
    do
        provides_headless="${provides_headless} java${i}-runtime-headless,"
    done
    cat << EOF
Package: $j2se_package
Architecture: $j2se_debian_arch
Depends: \${misc:Depends}, \${shlibs:Depends}, java-common, $depends
Recommends: netbase
Provides: java-runtime-headless, java2-runtime-headless, $provides_headless
Description: $j2se_title
 The Java(TM) SE Server Runtime Environment contains the Java virtual machine,
 runtime class libraries, and Java application launcher that are necessary to
 run programs written in the Java programming language. It includes tools for
 JVM monitoring and tools commonly required for server applications, but does
 not include browser integration (the Java plug-in), auto-update, nor an
 installer.
 .
 This package has been automatically created with java-package ($version).
EOF
}
