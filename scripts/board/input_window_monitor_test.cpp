// Modified by dc-a588-ohos contributors: see THIRD_PARTY.md for changes and provenance.
/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

#include <gtest/gtest.h>
#include "input_window_monitor.h"

using namespace testing;
using namespace testing::ext;

namespace OHOS {
namespace Rosen {
class InputWindowMonitorTest : public testing::Test {
public:
    static void SetUpTestCase();
    static void TearDownTestCase();
    void SetUp() override;
    void TearDown() override;

    sptr<WindowRoot> root_;
    sptr<InputWindowMonitor> input_monitor_;
};

void InputWindowMonitorTest::SetUpTestCase()
{
}

void InputWindowMonitorTest::TearDownTestCase()
{
}

void InputWindowMonitorTest::SetUp()
{
    root_ = new WindowRoot([](Event event, const sptr<IRemoteObject>& remoteObject) {});
    input_monitor_ = new InputWindowMonitor(root_);
}

void InputWindowMonitorTest::TearDown()
{
    root_ = nullptr;
    input_monitor_->InputWindowMonitor::~InputWindowMonitor();
}

namespace {
/**
 * @tc.name: UpdateInputWindow
 * @tc.desc: Update Input Window
 * @tc.type: FUNC
 */
HWTEST_F(InputWindowMonitorTest, UpdateInputWindow01, TestSize.Level1)
{
    input_monitor_->windowRoot_ = nullptr;
    input_monitor_->UpdateInputWindow(0);
    ASSERT_EQ(nullptr, input_monitor_->windowRoot_);

    input_monitor_->windowRoot_ = new WindowRoot([](Event event, const sptr<IRemoteObject>& remoteObject) {});
    input_monitor_->windowRoot_->windowNodeMap_.insert(std::make_pair(0, nullptr));
    input_monitor_->UpdateInputWindow(0);
    ASSERT_EQ(nullptr, input_monitor_->windowRoot_->windowNodeMap_[0]);
}

/**
 * @tc.name: GetDisplayDirectionForMmi
 * @tc.desc: get display direction
 * @tc.type: FUNC
 */
HWTEST_F(InputWindowMonitorTest, GetDisplayDirectionForMmi01, TestSize.Level1)
{
    Rotation rotate = Rotation::ROTATION_0;
    ASSERT_EQ(MMI::DIRECTION0, input_monitor_->GetDisplayDirectionForMmi(rotate));
}

/**
 * @tc.name: UpdateDisplayInfo
 * @tc.desc: update displayinfo
 * @tc.type: FUNC
 */
HWTEST_F(InputWindowMonitorTest, UpdateDisplayInfo01, TestSize.Level1)
{
    std::vector<sptr<DisplayInfo>> displayInfos;
    std::vector<MMI::DisplayInfo> displayInfoVector;
    displayInfos.clear();
    displayInfoVector.clear();
    sptr<DisplayInfo> displayinfo = nullptr;
    displayInfos.emplace_back(displayinfo);
    input_monitor_->UpdateDisplayInfo(displayInfos, displayInfoVector);
    ASSERT_EQ(0, displayInfoVector.size());
}

/**
 * @tc.name: UpdateDisplayInfoRejectsMissingScreen
 * @tc.desc: Do not advertise a display without a corresponding render screen.
 * @tc.type: FUNC
 */
HWTEST_F(InputWindowMonitorTest, UpdateDisplayInfoRejectsMissingScreen, TestSize.Level1)
{
    std::vector<sptr<DisplayInfo>> displayInfos;
    std::vector<MMI::DisplayInfo> displayInfoVector;
    displayInfos.clear();
    displayInfoVector.clear();
    sptr<DisplayInfo> displayInfo = new (std::nothrow) DisplayInfo();
    displayInfos.emplace_back(displayInfo);
    input_monitor_->UpdateDisplayInfo(displayInfos, displayInfoVector);
    ASSERT_TRUE(displayInfoVector.empty());
}

/**
 * @tc.name: TransformWindowRects
 * @tc.desc: TransformWindowRects
 * @tc.type: FUNC
 */
HWTEST_F(InputWindowMonitorTest, TransformWindowRects, TestSize.Level1)
{
    sptr<WindowNode> windowNode = new WindowNode();
    Rect areaRect;
    std::vector<Rect> touchHotAreas;
    std::vector<Rect> pointerHotAreas;
    input_monitor_->TransformWindowRects(windowNode, areaRect, touchHotAreas, pointerHotAreas);
    WindowProperty windowProperty;
    auto result = windowProperty.isNeedComputerTransform();
    ASSERT_EQ(result, false);
}

/**
 * @tc.name: GetDisplayDirectionForMmi02
 * @tc.desc: get display direction
 * @tc.type: FUNC
 */
HWTEST_F(InputWindowMonitorTest, GetDisplayDirectionForMmi02, TestSize.Level1)
{
    MMI::Direction direction = MMI::DIRECTION0;
    Rotation rotate = Rotation::ROTATION_90;
    rotate = Rotation::ROTATION_180;
    EXPECT_NE(direction, MMI::DIRECTION180);
    rotate = Rotation::ROTATION_270;
    EXPECT_NE(direction, MMI::DIRECTION270);
    ASSERT_NE(MMI::DIRECTION0, input_monitor_->GetDisplayDirectionForMmi(rotate));
}
}
}
}
