/**
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
const fs = require('fs');
const path = require('path');
const scbPath = __dirname;
const args = process.argv.slice(2);
const sdkBasePath = args[0];

// 将项目中staticcommon中的如下文件 拷贝到本地SDK的hms/ets/api/路径下
const copyHmsPathFileArray = [
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.hdsBaseComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.HdsVisualComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../product/pcbase/src/main/ets/SceneBoard/virtualmachine/@ohos.virtService.vmManagerInner.d.ets'
    },
    // {
    //     path: './ets/kits/',
    //     file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.d.ts'
    // },
    // {
    //     path: './ets/build-tools/ets-loader/kit_configs/',
    //     file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.json'
    // },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.virtService.abilityFrameworkBroker.d.ts'
    }
];

const copyOHPathFileArray = [
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.pcService.statusBar.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.multimodalAwareness.motion.d.ts'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.hdsBaseComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.HdsVisualComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.hdsDrawable.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.json'
    },
    {
        path: './ets/kits/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/kit_configs/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.json'
    },
    {
        path: './ets/build-tools/ets-loader/components/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/HdsVisualComponent.json'
    },
    {
        path: './ets/build-tools/ets-loader/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/tsconfig.json'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.sceneSessionManager.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.screenSessionManager.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.sessionManagerService.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.space_ability_napi.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.distributedHardware.mechanicManager.d.ts'
    },
    {
        path: './ets/api',
        file: '../feature/screenlockcomponent/@ohos.effectKit.d.ts'
    },
    {
        path: './ets/api',
        file: '../feature/screenlockcomponent/@ohos.screenLock.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/',
        file: '../feature/screenlockcomponent/sysResource.js'
    },
    {
        path: './ets/api',
        file: '../feature/screenlockcomponent/@ohos.account.osAccount.d.ts'
    },{
        path: './ets/api',
        file: '../feature/screenlockcomponent/@ohos.power.d.ts'
    },
    {
        path: './ets/api',
        file: '../feature/aod/@ohos.sceneboard.aod.d.ts'
    },
    {
        path: './ets/api',
        file: '../feature/aod/@ohos.swingability.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.transactionManager.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.migrate.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.security.privacyIndicatorManager.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.graphic.apsManager.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.pcService.statusBar.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.pcService.scb_mode_change_napi.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.nearlink.remoteDevice.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.graphics.uiEffect.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.virtService.bmsBrokerAdapter.d.ts'
    },
    {
        path: './js/api/',
        file: '../product/watch/src/main/ets/common/interfaces/@ohos.arkui.ArcList.d.ts'
    },
    {
        path: './ets/api/',
        file: '../product/watch/src/main/ets/common/interfaces/@ohos.arkui.ArcList.d.ts'
    },
    {
        path: './ets/api/',
        file: '../product/watch/src/main/ets/common/interfaces/@ohos.arkui.ArcAlphabetIndexer.d.ts'
    },
    {
        path: './js/api/',
        file: '../product/watch/src/main/ets/common/interfaces/@ohos.arkui.ArcAlphabetIndexer.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/components/',
        file: '../product/watch/src/main/ets/common/interfaces/arcAlphabetIndexer.json'
    },
    {
        path: './ets/build-tools/ets-loader/components/',
        file: '../product/watch/src/main/ets/common/interfaces/arcList.json'
    },
    {
        path: './ets/build-tools/ets-loader/components/',
        file: '../product/watch/src/main/ets/common/interfaces/arcListItem.json'
    },
    {
        path: './js/api/',
        file: '../product/watch/src/main/ets/common/interfaces/@ohos.telephony.esim.d.ts'
    },
    {
        path: './ets/api/',
        file: '../product/watch/src/main/ets/common/interfaces/@ohos.telephony.esim.d.ts'
    },
    {
        path: './ets/component',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/dynamic_component.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/dynamic_component.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/components',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/dynamic_component.json'
    },
    {
        path: './ets/api/graphics3d/',
        file: '../product/watch/src/main/ets/common/interfaces/Scene.d.ts'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.app.form.formInfo.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.xrGlassesService.xrGlassesAppService.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/text.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/text_common.d.ts'
    },
    {
        path: './ets/component',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/text.d.ts'
    },
    {
        path: './ets/component',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/text_common.d.ts'
    },
    {
        path: './ets/api/bundleManager',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/ShortcutInfo.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.application.BackupExtensionAbility.d.ts'
    }
];

const removeHmsPathFileArray = [
    {
        path: './ets/api/@ohos.hds.hdsBaseComponent.d.ts'
    }
];

const removeOHPathFileArray = [
    {
        path: './ets/api/@ohos.hds.hdsBaseComponent.d.ts'
    }
];

const replaceHmsPathFileArray = [
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.hdsBaseComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.HdsVisualComponent.d.ets'
    },
    {
        path: './ets/kits/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/kit_configs/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.json'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.virtService.servicebrokerWms.d.ts'
    }
];

const replaceOHPathFileArray = [
    {
        path: './ets/component',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/common.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/common.d.ts'
    },
    {
        path: './ets/component/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/swiper.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/swiper.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.displayengine.displayengine_napi.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.multimedia.audio.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.window.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.security.appLock.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.utilityApplication.parentControl.d.ts'
    },
    {
        path: './ets/component',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/effect_component.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/effect_component.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.resourceschedule.animationPolicy.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.ai.vision.imageGeneration.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.fusionConnectivityExt.d.ts'
    },
    {
        path: './ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.app.form.formHost.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/declarations',
        file: '../product/watch/src/main/ets/common/interfaces/form_component.d.ts'
    },
    {
        path:'./ets/build-tools/ets-loader',
        file:'../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/tsconfig.json'
    },
    {
        path: '../ohos/ets/kits',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.d.ts'
    },
    {
        path: '../ohos/ets/build-tools/ets-loader/kit_configs',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.json'
    },
    {
        path: '../ohos/ets/api',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.hdsBaseComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.hdsBaseComponent.d.ets'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.hds.HdsVisualComponent.d.ets'
    },
    {
        path: './ets/kits/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.d.ts'
    },
    {
        path: './ets/build-tools/ets-loader/kit_configs/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@kit.UIDesignKit.json'
    },
    {
        path: './ets/build-tools/ets-loader/components/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/HdsVisualComponent.json'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.bundle.launcherBundleManager.d.ts'
    },
    {
        path: './ets/api/',
        file: '../staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/@ohos.app.ability.AbilityConstant.d.ts'
    },
];

/**
 * 修改DC组件配置
 */
function setDynamicComponent() {
    for (const dir of ['ets/component', 'ets/build-tools/ets-loader/declarations']) {
        const componentIndexFilePath = path.resolve(sdkBasePath, dir, 'index-full.d.ts');
        if (!fs.existsSync(componentIndexFilePath)) {
            continue;
        }
        let fileContent = fs.readFileSync(componentIndexFilePath, 'utf-8');
        if (fileContent.includes('/// <reference path="./dynamic_component.d.ts" />')) {
            continue;
        }
        fileContent += '\n/// <reference path="./dynamic_component.d.ts" />';
        fs.writeFileSync(componentIndexFilePath, fileContent, 'utf-8');
    }

    //tsconfig.json主要用于配置TypeScript编译规则
    const tsconfigFilePath = path.resolve(sdkBasePath, 'ets/build-tools/ets-loader/tsconfig.json');
    if (!fs.existsSync(tsconfigFilePath)) {
        return;
    }
    try {
        // json中数组最后一项不能加逗号，否则require无法解析 ]前面不能是逗号
        let fileContent = fs.readFileSync(tsconfigFilePath, 'utf-8');
        const errJsonEnd = `,\n      ],`;
        const jsonEnd = `\n      ],`;
        if (fileContent.includes(errJsonEnd)) {
            fileContent = fileContent.replace(errJsonEnd, jsonEnd);
            fs.writeFileSync(tsconfigFilePath, fileContent, 'utf-8');
        }

        const tsconfig = require(tsconfigFilePath);
        let isNeedWrite = false;
        if (!tsconfig.compilerOptions.ets.components.includes('DynamicComponent')) {
            tsconfig.compilerOptions.ets.components.push('DynamicComponent');
            isNeedWrite = true;
        }
        if (!tsconfig.compilerOptions.ets.extend.components.some((c) => c.name === 'DynamicComponent')) {
            tsconfig.compilerOptions.ets.extend.components.push({
                name: 'DynamicComponent',
                type: 'DynamicComponentAttribute',
                instance: 'DynamicComponentInstance'
            });
            isNeedWrite = true;
        }
        if (isNeedWrite) {
            fs.writeFileSync(tsconfigFilePath, JSON.stringify(tsconfig, null, 2), 'utf-8');
        }
    } catch (e) {
        console.error('Set tsconfig.json error:', e);
    }
}

function copyFile(pathFile, basePath) {
    try {
        const destDir = path.resolve(basePath, pathFile.path);
        const sourceFile = path.resolve(scbPath, pathFile.file);
        if (!fs.existsSync(sourceFile)) {
            console.warn('copy sdk sourceFile not exist', sourceFile);
            return;
        }

        const destFile = path.resolve(destDir, path.basename(sourceFile));
        console.log('copyFile', destFile);
        fs.copyFileSync(sourceFile, destFile);
    } catch (error) {
        console.error('copyFile fail', pathFile,error);
    }
}

function removeFile(pathFile, basePath) {
    try {
        const destFile = path.resolve(basePath, pathFile.path);
        if (!fs.existsSync(destFile)) {
            console.warn('remove sdk destDir not exist', destFile);
            return;
        }

        console.log('removeFile', destFile);
        fs.rmSync(destFile);
    } catch (error) {
        console.error('removeFile fail', pathFile);
    }
}

function replaceFile(pathFile, basePath) {
    try {
        const destDir = path.resolve(basePath, pathFile.path);
        if (!fs.existsSync(destDir)) {
            console.warn('replace sdk destDir not exist', destDir);
            return;
        }

        const sourceFile = path.resolve(scbPath, pathFile.file);
        if (!fs.existsSync(sourceFile)) {
            console.warn('replace sdk sourceFile not exist', sourceFile);
            return;
        }

        const destFile = path.resolve(destDir, path.basename(sourceFile));
        console.log('replaceFile', destFile);
        fs.copyFileSync(sourceFile, destFile);
    } catch (error) {
        console.error('replaceFile fail', pathFile);
    }
}

/**
 * 打桩更新SDK
 * 如果打桩的文件发生了变化，本地执行./hvigorw --stop-daemon命令重启进程后再验证
 */
function updateSdkInterface() {
    try {
        console.log('Update SDK interface base path', sdkBasePath);
        // 路径替换成  ohos
        // const hmsSdkBasePath = sdkBasePath.replace('openharmony', 'ohos');
        // for (let pathFile of copyHmsPathFileArray) {
        //     copyFile(pathFile, hmsSdkBasePath);
        // }
        //
        // for (let pathFile of removeHmsPathFileArray) {
        //     removeFile(pathFile, hmsSdkBasePath);
        // }
        //
        // for (let pathFile of replaceHmsPathFileArray) {
        //     replaceFile(pathFile, hmsSdkBasePath);
        // }

        for (let pathFile of copyOHPathFileArray) {
            copyFile(pathFile, sdkBasePath);
        }

        for (let pathFile of removeOHPathFileArray) {
            removeFile(pathFile, sdkBasePath);
        }

        for (let pathFile of replaceOHPathFileArray) {
            replaceFile(pathFile, sdkBasePath);
        }

        setDynamicComponent();
    } catch (error) {
        console.error('update SDK interface error');
    }
}
updateSdkInterface();