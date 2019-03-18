#! /bin/bash

BUILD_MODE="debug"
ARCHS_ARM="arm64,armv7"
FLUTTER_ROOT=".flutter"
PRODUCT_DIR="product"
PRODUCT_ZIP="product.zip"

BUILD_PATH=".build_ios/${BUILD_MODE}" #build_ios/debug
PRODUCT_PATH="${BUILD_PATH}/${PRODUCT_DIR}" # build_ios/debug/product
PRODUCT_APP_PATH="${PRODUCT_PATH}/Flutter" # .build_ios/debug/product/Flutter

usage() {
    echo
    echo "build_ios.sh [-h | [-m <build_mode>] [-s]]"
    echo ""
    echo "-h    - Help."
    echo "-m    - Build model, valid values are 'debug', 'profile', or 'release'. "
    echo "        Default values: 'debug'."
    echo ""
    echo "Build product in 'build_ios/<builde_model>/${PRODUCT_DIR}' directory."
    echo
}

EchoError() {
    echo "$@" 1>&2
}

flutter_get_packages() {
    echo "================================="
    echo "Start get flutter app plugin"

    local flutter_wrapper="./flutterw"
    if [ -e $flutter_wrapper ]; then
        echo 'flutterw installed' >/dev/null
    else
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/passsy/flutter_wrapper/master/install.sh)"
        if [[ $? -ne 0 ]]; then
            EchoError "Failed to installed flutter_wrapper."
            exit -1
        fi
    fi

    ${flutter_wrapper} packages get --verbose
    if [[ $? -ne 0 ]]; then
        EchoError "Failed to install flutter plugins."
        exit -1
    fi

    echo "Finish get flutter app plugin"
}

build_flutter_app() {
    echo "================================="
    echo "Start Build flutter app"
    echo "Build mode: ${BUILD_MODE}"

    mkdir -p -- "${PRODUCT_APP_PATH}"

    # local target_path="lib/main.dart"
    local target_path="lib/main.dart"

    local artifact_variant="unknown"
    case "$BUILD_MODE" in
    release*)
        artifact_variant="ios-release"
        ;;
    profile*)
        artifact_variant="ios-profile"
        ;;
    debug*)
        artifact_variant="ios"
        ;;
    *)
        EchoError "========================================================================"
        EchoError "ERROR: Unknown FLUTTER_BUILD_MODE: ${BUILD_MODE}."
        EchoError "Valid values are 'debug', 'profile', or 'release'."
        EchoError "This is controlled by the -m environment varaible."
        EchoError "========================================================================"
        exit -1
        ;;
    esac

    if [[ "${BUILD_MODE}" != "debug" ]]; then
        if [[ $ARCHS_ARM =~ .*i386.* || $ARCHS_ARM =~ .*x86_64.* ]]; then
            EchoError "========================================================================"
            EchoError "ERROR: Flutter does not support running in profile or release mode on"
            EchoError "the Simulator (this build was: '$BUILD_MODE')."
            EchoError "mode by setting '-m debug'"
            EchoError "========================================================================"
            exit -1
        fi

        echo "Build archs: ${ARCHS_ARM}"

        # build fLutter app
        ${FLUTTER_ROOT}/bin/flutter --suppress-analytics \
            --verbose \
            build aot \
            --output-dir="${BUILD_PATH}" \
            --target-platform=ios \
            --target="${target_path}" \
            --${BUILD_MODE} \
            --ios-arch="${ARCHS_ARM}"

        if [[ $? -ne 0 ]]; then
            EchoError "Failed to build flutter app"
            exit -1
        fi
    else
        # debug编译模式直接使用编译好的App.framework，
        # 因为在 debug 模式下 flutter 代码并没有编译成二进制机器码，而是在后续build bundle时被打包进资源包，
        # 在'xcode_backend.sh'脚本里，这一步这里只是编译成一个App.framework空壳。
        # 提前编译好的原因是'xcode_backend.sh'脚本执行和Xcode一起执行，所以执行时能获取到Xcode设置的编译配置，能正确的编译出'App.framework',
        # 而本脚本不依赖Xcode执行，即便把'xcode_backend.sh'对应的代码拷贝出来也不能正确的编译出'App.framework'，除非我们能正确的配置编译环境。
        # 
        # 而我又不想那么麻烦，选择另辟蹊径:
        # 随便创建了一个 Flutter 工程，
        # 在debug模式下，先在模拟器编译运行一下，得到x86_64的App.framework，
        # 再到真机运行一下，得到arm64/armv7的App.framework,
        # 最后使用lipo命令将两个App.framework合并，得到x86_64/arm64/armv7的App.framework，
        # 这样最后得到的App.framework在模拟器和真机都可以用
        # 因为debug模式下App.framework就是占位的空壳，所以其他flutter工程一样用
        echo "Build archs: x86_64 ${ARCHS_ARM}"
        local app_framework_debug="iOSApp/Debug/App.framework"
        cp -r -- "${app_framework_debug}" "${BUILD_PATH}"
    fi

    app_plist_path="ios/Flutter/AppFrameworkInfo.plist"
    cp -- "${app_plist_path}" "${BUILD_PATH}/App.framework/Info.plist"

    # copy flutter sdk
    local framework_path="${FLUTTER_ROOT}/bin/cache/artifacts/engine/${artifact_variant}"
    local flutter_framework="${framework_path}/Flutter.framework"
    local flutter_podspec="${framework_path}/Flutter.podspec"

    cp -r -- "${BUILD_PATH}/App.framework" "${PRODUCT_APP_PATH}"
    cp -r -- "${flutter_framework}" "${PRODUCT_APP_PATH}"
    cp -r -- "${flutter_podspec}" "${PRODUCT_APP_PATH}"

    local precompilation_flag=""
    if [[ "$BUILD_MODE" != "debug" ]]; then
        precompilation_flag="--precompiled"
    fi

    # build bundle
    ${FLUTTER_ROOT}/bin/flutter --suppress-analytics \
        --verbose \
        build bundle \
        --target-platform=ios \
        --target="${target_path}" \
        --${BUILD_MODE} \
        --depfile="${BUILD_PATH}/snapshot_blob.bin.d" \
        --asset-dir="${BUILD_PATH}/flutter_assets" \
        ${precompilation_flag}

    if [[ $? -ne 0 ]]; then
        EchoError "Failed to build flutter assets"
        exit -1
    fi

    local product_app_assets_path="${PRODUCT_APP_PATH}/Assets"
    mkdir -p -- "${product_app_assets_path}"
    cp -rf -- "${BUILD_PATH}/flutter_assets" "${PRODUCT_APP_PATH}/App.framework"

    # local product_app_assets_path="${PRODUCT_APP_PATH}/Assets"
    # mkdir -p -- "${product_app_assets_path}"
    # cp -rf -- "${BUILD_PATH}/flutter_assets" "${PRODUCT_APP_PATH}/App.framework"

    # setting podspec
    # replace:
    # 'Flutter.framework'
    # to:
    # 'Flutter.framework', 'App.framework'
    #   s.resource='Assets/*'
    sed -i '' -e $'s/\'Flutter.framework\'/\'Flutter.framework\', \'App.framework\'\\\n  s.resource=\'Assets\/*\'/g' ${PRODUCT_APP_PATH}/Flutter.podspec

    echo "Finish build flutter app"
}

flutter_copy_packages() {
    echo "================================="
    echo "Start copy flutter app plugin"

    local flutter_plugin_registrant="FlutterPluginRegistrant"
    local flutter_plugin_registrant_path="ios/Flutter/${flutter_plugin_registrant}"
    echo "copy 'flutter_plugin_registrant' from '${flutter_plugin_registrant_path}' to '${PRODUCT_PATH}/${flutter_plugin_registrant}'"
    cp -rf -- "${flutter_plugin_registrant_path}" "${PRODUCT_PATH}/${flutter_plugin_registrant}"

    local flutter_plugin=".flutter-plugins"
    if [ -e $flutter_plugin ]; then
        OLD_IFS="$IFS"
        IFS="="
        cat ${flutter_plugin} | while read plugin; do
            local plugin_info=($plugin)
            local plugin_name=${plugin_info[0]}
            local plugin_path=${plugin_info[1]}

            if [ -e ${plugin_path} ]; then
                local plugin_path_ios="${plugin_path}ios"
                if [ -e ${plugin_path_ios} ]; then
                    if [ -s ${plugin_path_ios} ]; then
                        echo "copy plugin 'plugin_name' from '${plugin_path_ios}' to '${PRODUCT_PATH}/${plugin_name}'"
                        cp -rf ${plugin_path_ios} "${PRODUCT_PATH}/${plugin_name}"
                    fi
                fi
            fi
        done
        IFS="$OLD_IFS"
    fi

    echo "Finish copy flutter app plugin"
}

zip_product() {
    echo "================================="
    echo "Start zip product"

    pushd ${BUILD_PATH}
    zip -r "${PRODUCT_ZIP}" "${PRODUCT_DIR}"
    if [[ $? -ne 0 ]]; then
        EchoError "Failed to zip product"
        exit -1
    fi

    popd

    echo "Finish zip product"
}

maven_upload() {
    echo "================================="
    echo "Start upload ${PRODUCT_ZIP} to maven"

    local app_version=$(./get_version.sh)

    echo "Upload version: ${app_version}"

    ./maven.sh upload ${app_version} ${BUILD_PATH}/${PRODUCT_ZIP}

    if [[ $? -ne 0 ]]; then
        EchoError "Failed to upload maven"
        exit -1
    fi

    echo "Finish upload ${PRODUCT_ZIP} to maven"
}

start_build() {

    rm -rf ${BUILD_PATH}

    flutter_get_packages

    build_flutter_app

    flutter_copy_packages

    if [[ "${BUILD_MODE}" == "release" ]]; then

        zip_product

        maven_upload
    fi

    echo ""
    echo "done!"
}

show_help=0
while getopts "m:sh" arg; do
    case $arg in
    m)
        BUILD_MODE="$OPTARG"
        ;;
    h)
        show_help=1
        ;;
    ?)
        show_help=1
        ;;
    esac
done

if [ $show_help == 1 ]; then
    usage
    exit 0
fi

BUILD_PATH=".build_ios/${BUILD_MODE}"
PRODUCT_PATH="${BUILD_PATH}/${PRODUCT_DIR}"
PRODUCT_APP_PATH="${PRODUCT_PATH}/Flutter"

start_build

exit 0
