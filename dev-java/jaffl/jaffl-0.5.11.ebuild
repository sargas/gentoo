# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

JAVA_PKG_IUSE="doc source test"

WANT_ANT_TASKS="ant-nodeps"

inherit java-pkg-2 java-ant-2 versionator

DESCRIPTION="An abstracted interface to invoking native functions from java"
HOMEPAGE="http://kenai.com/projects/jaffl"
SRC_URI="http://github.com/jnr/jnr-ffi/tarball/${PV} -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"

CDEPEND="dev-java/jffi:1.2
	dev-java/jnr-x86asm:0
	dev-java/asm:3"

RDEPEND=">=virtual/jre-1.6
	${CDEPEND}"

DEPEND=">=virtual/jdk-1.6
	app-arch/unzip
	${CDEPEND}
	test? (
		dev-java/junit:4
		dev-java/ant-junit:0
		dev-java/hamcrest-core:0
	)"

JAR_VERSION=$(get_version_component_range 1-2)

src_unpack() {
	default

	mv * "${P}" || die
}

java_prepare() {
	rm -vf lib/{.,junit*}/*.jar

	epatch "${FILESDIR}"/${P}-library-path.patch
	epatch "${FILESDIR}"/${P}-GNUmakefile.patch

	# Don't choke on errors from generating the Javadoc
	cd "${S}" || die
	java-ant_xml-rewrite -f ./nbproject/build-impl.xml \
						 -c -e javadoc \
						 -a failonerror \
						 -v no

	java-pkg_jar-from --into lib jffi-1.2
	java-pkg_jar-from --into lib jnr-x86asm
	java-pkg_jar-from --into lib asm-3 asm.jar asm-3.2.jar
	java-pkg_jar-from --into lib asm-3 asm-analysis.jar asm-analysis-3.2.jar
	java-pkg_jar-from --into lib asm-3 asm-commons.jar asm-commons-3.2.jar
	java-pkg_jar-from --into lib asm-3 asm-tree.jar asm-tree-3.2.jar
	java-pkg_jar-from --into lib asm-3 asm-util.jar asm-utils-3.2.jar
	java-pkg_jar-from --into lib asm-3 asm-xml.jar asm-xml-3.2.jar
}

EANT_EXTRA_ARGS="-Dreference.jffi.jar=lib/jffi.jar \
	-Dreference.jnr-x86asm.jar=lib/jnr-x86asm.jar \
	-Dproject.jffi=\"${S}\" \
	-Dproject.jnr-x86asm=\"${S}\"
	-D\"already.built.${S}\"=true"

src_test() {
	local paths="$(java-config -di jnr-x86asm,jffi-1.2):${S}/build"

	ANT_TASKS="ant-junit ant-nodeps" eant test \
		-Drun.jvmargs="-Djava.library.path=${paths}" \
		-Dlibs.junit_4.classpath="$(java-pkg_getjars junit-4,hamcrest-core)" ${EANT_EXTRA_ARGS}
}

src_install() {
	java-pkg_newjar dist/${PN}-${JAR_VERSION}.jar

	use doc && java-pkg_dojavadoc dist/javadoc
	use source && java-pkg_dosrc src/*
}
