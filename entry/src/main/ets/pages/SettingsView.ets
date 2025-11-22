import { TimerStore, SettingsModel } from '../model/TimerModel';
import { window } from '@kit.ArkUI';

// ⚠️ 注意：这里不再定义 SettingCard struct，完全使用扁平化布局

@ComponentV2
export struct SettingsView {
  @Param store: TimerStore = new TimerStore();
  // 本地草稿：确保修改时立即响应，不影响全局，直到点击完成
  @Local draftSettings: SettingsModel = new SettingsModel();
  @Local topMargin: number = 0;

  aboutToAppear(): void {
    // 1. 复制数据到草稿
    this.draftSettings.copyFrom(this.store.settings);

    // 2. 沉浸式状态栏适配
    window.getLastWindow(this.getUIContext().getHostContext()).then((win) => {
      win.setWindowSystemBarProperties({
        statusBarColor: '#F7F8FA',
        statusBarContentColor: '#000000',
        navigationBarContentColor: '#000000'
      });

      const updateHeight = (area: window.AvoidArea) => {
        const height = this.getUIContext().px2vp(area.topRect.height);
        if (height > 0) this.topMargin = height;
      };

      let type = window.AvoidAreaType.TYPE_SYSTEM;
      try {
        let avoidArea = win.getWindowAvoidArea(type);
        updateHeight(avoidArea);
      } catch (e) {}

      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) updateHeight(data.area);
      });
    });
  }

  build() {
    NavDestination() {
      Column() {
        // --- 标题栏 ---
        Row() {
          Text($r('app.string.settings_title'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))

          Blank()

          // --- 完成按钮 ---
          Text($r('app.string.settings_done'))
            .fontSize(16)
            .fontColor($r('app.color.blue_500'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              // 1. 提交修改：将草稿同步回全局
              this.store.settings.copyFrom(this.draftSettings);
              // 2. 持久化保存
              this.store.saveData();
              // 3. 返回上一页
              const nav = this.queryNavigationInfo();
              nav?.pathStack.pop();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15, bottom: 15 })

        // --- 内容滚动区 ---
        Scroll() {
          Column({ space: 20 }) {

            // ============================================================
            // ✅ 第一组：计时器配置
            // 核心修复：直接使用 Column 包裹，移除 SettingCard
            // ============================================================
            Column() {
              this.GroupTitle($r('app.string.settings_timer_config'))

              Column() {
                this.CounterRow($r('app.string.settings_focus_duration'), this.draftSettings.focusDuration, (val: number) => {
                  this.draftSettings.focusDuration = val; // 修改草稿 -> 立即触发 SettingsView 重绘 -> 数字更新
                })
                Divider().color($r('app.color.divider'))
                this.CounterRow($r('app.string.settings_short_break_duration'), this.draftSettings.shortBreakDuration, (val: number) => {
                  this.draftSettings.shortBreakDuration = val;
                })
                Divider().color($r('app.color.divider'))
                this.CounterRow($r('app.string.settings_long_break_duration'), this.draftSettings.longBreakDuration, (val: number) => {
                  this.draftSettings.longBreakDuration = val;
                })
              }
              .backgroundColor(Color.White)
              .borderRadius(16)
              .padding({ top: 4, bottom: 4 })
            }

            // ============================================================
            // ✅ 第二组：自动化配置
            // ============================================================
            Column() {
              this.GroupTitle($r('app.string.settings_automation'))

              Column() {
                this.ToggleRow($r('app.string.settings_auto_start_break'), this.draftSettings.autoStartBreaks, (val: boolean) => {
                  this.draftSettings.autoStartBreaks = val;
                })
                Divider().color($r('app.color.divider'))
                this.ToggleRow($r('app.string.settings_auto_start_focus'), this.draftSettings.autoStartFocus, (val: boolean) => {
                  this.draftSettings.autoStartFocus = val;
                })
                Divider().color($r('app.color.divider'))
                this.CounterRow($r('app.string.settings_long_break_interval'), this.draftSettings.longBreakInterval, (val: number) => {
                  this.draftSettings.longBreakInterval = val;
                }, $r('app.string.settings_long_break_interval_desc'))
              }
              .backgroundColor(Color.White)
              .borderRadius(16)
              .padding({ top: 4, bottom: 4 })
            }

            // ============================================================
            // ✅ 第三组：通知配置
            // ============================================================
            Column() {
              this.GroupTitle($r('app.string.settings_notification'))

              Column() {
                this.ToggleRow($r('app.string.settings_timer_finished_alert'), this.draftSettings.notificationEnabled, (val: boolean) => {
                  this.draftSettings.notificationEnabled = val;
                }, $r('app.string.settings_timer_finished_alert_desc'))
              }
              .backgroundColor(Color.White)
              .borderRadius(16)
              .padding({ top: 4, bottom: 4 })
            }

            // 底部版本号
            Text($r('app.string.settings_version', $r('app.string.app_version')))
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 20, bottom: 40 })

          }
          .padding({ left: 16, right: 16 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.app_window_bg'))
      .padding({ top: this.topMargin })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
  }

  // --- 辅助 Builder：分组标题 ---
  @Builder GroupTitle(title: ResourceStr) {
    Text(title)
      .fontSize(12)
      .fontColor($r('app.color.text_secondary'))
      .margin({ left: 12, bottom: 8 })
      .width('100%')
  }

  // --- 计数器行 ---
  @Builder CounterRow(label: ResourceStr, value: number, onChange: (val: number) => void, desc?: ResourceStr) {
    Row() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        if (desc) {
          Text(desc)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1) // 这里的 layoutWeight 防止文字遮挡右侧按钮

      Row({ space: 12 }) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.minus'))
            .fontSize(16)
            .fontColor([$r('app.color.text_primary')])
            .fontWeight(FontWeight.Bold)
        }
        .width(32)
        .height(32)
        .backgroundColor($r('app.color.setting_btn_bg'))
        .onClick(() => {
          if (value > 1) onChange(value - 1)
        })

        Text((value ?? 0).toString())
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width(24)
          .textAlign(TextAlign.Center)

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(16)
            .fontColor([$r('app.color.text_primary')])
            .fontWeight(FontWeight.Bold)
        }
        .width(32)
        .height(32)
        .backgroundColor($r('app.color.setting_btn_bg'))
        .onClick(() => {
          if (value < 60) onChange(value + 1)
        })
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .constraintSize({ minHeight: 56 })
  }

  // --- 开关行 ---
  @Builder ToggleRow(label: ResourceStr, isOn: boolean, onChange: (val: boolean) => void, desc?: ResourceStr) {
    Row() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        if (desc) {
          Text(desc)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor($r('app.color.text_primary'))
        .width(52)
        .height(32)
        .onChange((isOn: boolean) => {
          onChange(isOn)
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .constraintSize({ minHeight: 56 })
  }
}