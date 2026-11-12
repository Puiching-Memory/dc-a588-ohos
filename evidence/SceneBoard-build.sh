#!/bin/bash
# Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function init_env() {
    export NODE_OPTIONS="--max-old-space-size=20000"
    export NODE_HOME="${NODE_HOME%/bin}"
    export IS_DT_IN_LINUX=true

    echo ${NODE_HOME}
    echo "${HM_SDK_HOME}"
    node -v
    npm -v

    # 初始化相关路径
    PROJECT_PATH=$(pwd -P)
    TOOLS_INSTALL_DIR=${PROJECT_PATH}

    # Setup npm
    npm config set strict-ssl false

    if [ "${DT_DEVICE_FLAG}" == "pc" ];then
       # 是否开启默认的冲突处理机制
       ohpm config set resolve_conflict false
    fi

    #echo "hwsdk.dir=${HM_SDK_HOME}"  > ./local.properties
    #echo "nodejs.dir=${NODE_HOME}" >> ./local.properties
}

# 进入package目录安装依赖
function ohpm_install() {
    pushd "$1"
    ohpm install
    popd
}

# 环境适配
function ohpm_install_deps() {
    cd ${PROJECT_PATH}
    ohpm -v
    ohpm_install "${PROJECT_PATH}"
    ohpm_install "${PROJECT_PATH}/staticcommon/screenlockcommon"
    ohpm_install "${PROJECT_PATH}/feature/appcenter"
    ohpm_install "${PROJECT_PATH}/feature/carcastsource"
    ohpm_install "${PROJECT_PATH}/feature/castengine"
    ohpm_install "${PROJECT_PATH}/feature/devecoviewer"
    ohpm_install "${PROJECT_PATH}/feature/controlcentercomponent"
    ohpm_install "${PROJECT_PATH}/feature/desktop/aisuggestion/"
    ohpm_install "${PROJECT_PATH}/feature/desktop/bigfolder"
    ohpm_install "${PROJECT_PATH}/feature/desktop/emergencymode"
    ohpm_install "${PROJECT_PATH}/feature/desktop/desktopedit"
    ohpm_install "${PROJECT_PATH}/feature/desktop/form"
    ohpm_install "${PROJECT_PATH}/feature/desktop/formstack"
    ohpm_install "${PROJECT_PATH}/feature/desktop/numbadge"
    ohpm_install "${PROJECT_PATH}/feature/desktop/pagedesktop"
    ohpm_install "${PROJECT_PATH}/feature/desktop/smallfolder"
    ohpm_install "${PROJECT_PATH}/feature/desktopfilefolder"
    ohpm_install "${PROJECT_PATH}/feature/engineservice"
    ohpm_install "${PROJECT_PATH}/feature/gesturenavigation"
    ohpm_install "${PROJECT_PATH}/feature/immersivekeyguard"
    ohpm_install "${PROJECT_PATH}/feature/liveview/"
    ohpm_install "${PROJECT_PATH}/feature/multiinput"
    ohpm_install "${PROJECT_PATH}/feature/notification/managementcomponent"
    ohpm_install "${PROJECT_PATH}/feature/notification/notificationcomponent"
    ohpm_install "${PROJECT_PATH}/feature/notification/notificationmanagement"
    ohpm_install "${PROJECT_PATH}/feature/recents"
    ohpm_install "${PROJECT_PATH}/feature/screenlockcomponent"
    ohpm_install "${PROJECT_PATH}/feature/smartdock/commonsmartdock"
    ohpm_install "${PROJECT_PATH}/feature/smartdock/pcsmartdock"
    ohpm_install "${PROJECT_PATH}/feature/statusbarcomponent"
    ohpm_install "${PROJECT_PATH}/feature/superprivacy"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/brightnesscomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/hcastcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/superprivacycomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/mediacontrolcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/powercomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/eyecomfortcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/superhubtogglecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/powersavingtogglecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/nearlinktogglecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemcontrol/soundcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemdialog"
    ohpm_install "${PROJECT_PATH}/feature/collaborationfwkdialog"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/airplanecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/autorotatecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/batterycomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/bluetoothcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/cameraindicator"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/clockcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/customcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/darkmodecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/datetimecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/earphonecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/flashlightcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/hotspotcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/inputmethodcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/linkspeedcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/locationcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/microphonecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/mobiledatacomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/nfccomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/plugincomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/ringmodecomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/signalcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/starflashcomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/statusbarsuperprivacycomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/wificomponent"
    ohpm_install "${PROJECT_PATH}/feature/systemstatus/plugincardcomponent"
    ohpm_install "${PROJECT_PATH}/feature/themecomponent"
    ohpm_install "${PROJECT_PATH}/feature/volume/volumepanel"
    ohpm_install "${PROJECT_PATH}/feature/volume/volumepanelcomponent"
    ohpm_install "${PROJECT_PATH}/feature/togglehome"
    ohpm_install "${PROJECT_PATH}/feature/wallpapercomponent"
    ohpm_install "${PROJECT_PATH}/feature/statusbarextension"
    ohpm_install "${PROJECT_PATH}/product/phone"
    ohpm_install "${PROJECT_PATH}/product/pc"
    ohpm_install "${PROJECT_PATH}/staticcommon/systemuicommon"
    ohpm_install "${PROJECT_PATH}/staticcommon/launchercommon"
    ohpm_install "${PROJECT_PATH}/feature/themeservice/themeservice_base"
    ohpm_install "${PROJECT_PATH}/feature/themeservice/themeservice_inner_api"
    ohpm_install "${PROJECT_PATH}/feature/themeservice/themeservice_core_lem"
    ohpm_install "${PROJECT_PATH}/feature/themeservice/themeservice_kit"
    ohpm_install "${PROJECT_PATH}/feature/themeservice/themeservice_core"
	ohpm_install "${PROJECT_PATH}/product/pcbase"
    ohpm_install "${PROJECT_PATH}/product/pad"
    ohpm_install "${PROJECT_PATH}/product/phonebase"
}

# clean任务
function clean() {
    cd ${PROJECT_PATH}
    hvigorw clean --no-daemon
}

# 替换脚本
function shell_replace() {
    if [ "${DT_TASK_FLAG}" == "coverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverage" ];then
        node ./shell/Test_withcoverage.build.js
    elif [ "${DT_TASK_FLAG}" == "fullCoverageReboot" ];then 
        node ./shell/Test_cov_reboot.build.js
    fi
}


function update_sdk_interface() {
  echo "[OHOS INFO] update_sdk_interface begin"
  node ${PROJECT_PATH}/hvigor/update-sdk-interface.js ${HM_SDK_HOME}/default/openharmony/
  echo "[OHOS INFO] update_sdk_interface end"
}

# 打包产物
function dtpinpeline_zip() {
    if [ -e "build/DTPipeline.zip" ];then
        echo "build/DTPipeline.zip is exist"
        rm -rf ${PROJECT_PATH}/build/DTPipeline.zip
        cd build/outputs
        if [ $? -ne 0 ];then
            echo "build/outputs is not exist"
            exit 1
        fi
        zip -r ${PROJECT_PATH}/build/DTPipeline.zip ./*
        cd ${PROJECT_PATH}
    else
       echo "build/DTPipeline.zip is not exist"
        cd build/outputs
        if [ $? -ne 0 ];then
            echo "build/outputs is not exist"
            exit 1
        fi
        zip -r ${PROJECT_PATH}/build/DTPipeline.zip ./*
        cd ${PROJECT_PATH}
    fi
}

# 构建任务
function build() {
    cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >> ${HOME}/.npmrc
    cd ${PROJECT_PATH}/signature
    chmod +x build.sh
    ./build.sh

    cd ${PROJECT_PATH}
    update_sdk_interface
    hvigorw clean --no-daemon
    
    shell_replace

    mkdir build
    mkdir build/outputs
    mkdir build/outputs/SceneBoard
    hvigorw assembleHap --mode module -p module=default_notificationmanagement --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    hvigorw assembleHap --mode module -p module=engineservice --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    hvigorw assembleHap --mode module -p module=themecomponent --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    hvigorw assembleHsp --mode module -p module=basecommon@default -p product=default --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    cp ./feature/notification/notificationmanagement/build/default/outputs/default/default_notificationmanagement-phone_sceneboard-default-signed.hap ./build/outputs/SceneBoard/SceneBoard_NotificationManagement.hap
    cp ./feature/engineservice/build/default/outputs/default/engineservice-phone_sceneboard-default-signed.hap ./build/outputs/SceneBoard/SceneBoard_EngineService.hap
    cp ./feature/themecomponent/build/default/outputs/default/themecomponent-phone_sceneboard-default-signed.hap ./build/outputs/SceneBoard/SceneBoard_ThemeComponent.hap
    cp ./basecommon/build/default/outputs/default/basecommon-default-signed.hsp ./build/outputs/SceneBoard/basecommon.hsp
    if [ "${DT_TASK_FLAG}" == "fullCoverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverageReboot" ];then
        echo "hvigorw phone_sceneboard"
        hvigorw assembleHap --mode module -p module=phone_sceneboard --no-daemon -p debuggable=false -p build_mode=release -p ohos-test-coverage=true -p hvigor-obfuscation=true
        mv ./product/phone/build/default/outputs/default/phone_sceneboard-default-signed.hap ./product/phone/build/default/outputs/default/SceneBoard.hap
    else
        hvigorw assembleHap --mode module -p module=phone_sceneboard --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    fi
    if [ "${DT_TASK_FLAG}" == "coverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverageReboot" ];then
        echo "hvigorw phone_sceneboard@ohosTest"
        hvigorw --mode module -p module=phone_sceneboard@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p ohos-test-coverage=true -p hvigor-obfuscation=true
    else
        hvigorw --mode module -p module=phone_sceneboard@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    fi
    dtpinpeline_zip
}

# 构建任务PAD
function build_pad() {
    cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >> ${HOME}/.npmrc
    cd ${PROJECT_PATH}/signature
    chmod +x build.sh
    ./build.sh

    cd ${PROJECT_PATH}
    update_sdk_interface
    hvigorw clean --no-daemon

    shell_replace

    mkdir build
    mkdir build/outputs
    mkdir build/outputs/SceneBoard
    hvigorw assembleHap --mode module -p module=default_notificationmanagement --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    hvigorw assembleHap --mode module -p module=engineservice --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    hvigorw assembleHap --mode module -p module=themecomponent --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    hvigorw assembleHsp --mode module -p module=basecommon@default -p product=default --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    cp ./feature/notification/notificationmanagement/build/default/outputs/default/default_notificationmanagement-phone_sceneboard-default-signed.hap ./build/outputs/SceneBoard/SceneBoard_NotificationManagement.hap
    cp ./feature/engineservice/build/default/outputs/default/engineservice-phone_sceneboard-default-signed.hap ./build/outputs/SceneBoard/SceneBoard_EngineService.hap
    cp ./feature/themecomponent/build/default/outputs/default/themecomponent-phone_sceneboard-default-signed.hap ./build/outputs/SceneBoard/SceneBoard_ThemeComponent.hap
    cp ./basecommon/build/default/outputs/default/basecommon-default-signed.hsp ./build/outputs/SceneBoard/basecommon.hsp
    if [ "${DT_TASK_FLAG}" == "fullCoverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverageReboot" ];then
        echo "hvigorw pad_sceneboard"
        hvigorw assembleHap --mode module -p module=pad_sceneboard --no-daemon -p debuggable=false -p build_mode=release -p ohos-test-coverage=true -p hvigor-obfuscation=true
        mv ./product/pad/build/default/outputs/default/pad_sceneboard-default-signed.hap ./product/pad/build/default/outputs/default/SceneBoard.hap
    else
        hvigorw assembleHap --mode module -p module=pad_sceneboard --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    fi
    if [ "${DT_TASK_FLAG}" == "coverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverageReboot" ];then
        echo "hvigorw pad_sceneboard@ohosTest"
        hvigorw --mode module -p module=pad_sceneboard@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p ohos-test-coverage=true -p hvigor-obfuscation=true
    else
        hvigorw --mode module -p module=pad_sceneboard@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    fi
    dtpinpeline_zip
}

# 构建任务 - pc
function build_pc() {
    cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >> ${HOME}/.npmrc
    cd ${PROJECT_PATH}/signature
    chmod +x build.sh
    ./build.sh

    cd ${PROJECT_PATH}
    update_sdk_interface
    hvigorw clean --no-daemon

    mkdir build
    mkdir build/outputs
    mkdir build/outputs/PCDockAndAppCenter

    hvigorw assembleHap --mode module -p module=pc_sceneboard --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    mv ./product/pc/build/default/outputs/default/pc_sceneboard-default-signed.hap ./product/pc/build/default/outputs/default/SceneBoard.hap
    cp ./product/pc/build/default/outputs/default/SceneBoard.hap ./build/outputs/PCDockAndAppCenter/SceneBoard.hap
    if [ "${DT_TASK_FLAG}" == "coverage" ];then
        hvigorw --mode module -p module=pc_sceneboard@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p ohos-test-coverage=true -p hvigor-obfuscation=true
    else
        hvigorw --mode module -p module=pc_sceneboard@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p hvigor-obfuscation=true
    fi
    dtpinpeline_zip
}

# 构建任务 - themeservice
function build_themeservice() {
	cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >> ${HOME}/.npmrc
    cd ${PROJECT_PATH}/signature
    chmod +x build.sh
    ./build.sh

    cd ${PROJECT_PATH}
    update_sdk_interface
    hvigorw clean --no-daemon

    mkdir build
    mkdir build/outputs
    mkdir build/outputs/ThemeService


    hvigorw assembleHap --mode module -p module=themeservice_core --daemon -p debuggable=false -p build_mode=release -p ohos-test-coverage=true -p hvigor-obfuscation=true
    mv ./feature/themeservice/themeservice_core/build/default/outputs/default/themeservice_core-phone_sceneboard-default-signed.hap ./feature/themeservice/themeservice_core/build/default/outputs/default/ThemeService.hap

	if [ "${DT_TASK_FLAG}" == "coverage" ] || [ "${DT_TASK_FLAG}" == "fullCoverage" ];then
	    hvigorw --mode module -p module=themeservice_core@ohosTest -p debuggable=false -p ohos-test-coverage=true hvigor-obfuscation=true assembleHap packageTesting  --parallel --incremental --no-daemon --stacktrace
    else
      hvigorw --mode module -p module=themeservice_core@ohosTest packageTesting --no-daemon -p debuggable=false -p build_mode=release -p
	fi
    dtpinpeline_zip
}

function main() {
    local start_time=$(date '+%s')
    init_env
    clean
    ohpm_install_deps
    if [ "${DT_DEVICE_FLAG}" == "pc" ];then
        build_pc
    elif [ "${DT_DEVICE_FLAG}" == "themeservice" ];then
        build_themeservice
    elif [ "${DT_DEVICE_FLAG}" == "pad" ];then
        build_pad
    else
        build
    fi
    local end_time=$(date '+%s')
    local elapsed_time=$(expr $end_time - $start_time)
    echo "build success in ${elapsed_time}s..."
}

if [ "$1" == "clean" ] || [ "$1" == "projects" ];then
   echo "do nothing"
elif [ "$1" == "SystemUI_DT" ];then
    sh ./feature/notification/systemui_build.sh "${@:2}"
else
   DT_TASK_FLAG=$2
   DT_DEVICE_FLAG=$3
   echo "DT_TASK_FLAG is ${DT_TASK_FLAG}, DT_DEVICE_FLAG is ${DT_DEVICE_FLAG}"
   main
fi
