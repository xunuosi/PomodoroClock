import { TimerStore, SettingsModel } from '../model/TimerModel';
import { window } from '@kit.ArkUI';

/**
 * 设置卡片容器组件
 */
@ComponentV2
struct SettingCard {
  @Param title: ResourceStr = ''; // 支持传入 string 或 Resource
  @BuilderParam content: () => void = this.emptyBuilder;

  @Builder emptyBuilder() {}

  build() {
    Column() {
      Text(this.title)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary')) // #989A9C
        .margin({ left: 12, bottom: 8 })

      Column() {
        this.content()
      }
      .backgroundColor(Color.White)
      .borderRadius(16)
      .padding({ top: 4, bottom: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct SettingsView {
  @Param store: TimerStore = new TimerStore();
  @Local draftSettings: SettingsModel = new SettingsModel();

  @Local topMargin: number = 0;

  aboutToAppear(): void {
    this.draftSettings.copyFrom(this.store.settings);

    window.getLastWindow(this.getUIContext().getHostContext()).then((win) => {
      // 确保状态栏显示且文字清晰
      win.setWindowSystemBarProperties({
        statusBarColor: '#F7F8FA',
        statusBarContentColor: '#000000',
        navigationBarContentColor: '#000000'
      });

      const updateHeight = (area: window.AvoidArea) => {
        const height = this.getUIContext().px2vp(area.topRect.height);
        if (height > 0) {
          this.topMargin = height;
        }
      };

      // 初始获取
      let type = window.AvoidAreaType.TYPE_SYSTEM;
      try {
        let avoidArea = win.getWindowAvoidArea(type);
        updateHeight(avoidArea);
      } catch (e) {}

      // 监听变化
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          updateHeight(data.area);
        }
      });
    });
  }

  build() {
    NavDestination() {
      Column() {
        // --- 标题栏 ---
        Row() {
          Text($r('app.string.settings_title')) // 设置
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary')) // #2B333E

          Blank()

          // 完成按钮
          Text($r('app.string.settings_done')) // 完成
            .fontSize(16)
            .fontColor($r('app.color.blue_500'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.store.settings.copyFrom(this.draftSettings);
              // A. 只有点击这里，才真正写入磁盘持久化
              this.store.saveData();

              // B. 返回上一页
              const nav = this.queryNavigationInfo();
              nav?.pathStack.pop();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15, bottom: 15 })

        // --- 内容滚动区 ---
        Scroll() {
          Column({ space: 20 }) {

            // 1. 计时器配置
            SettingCard({ title: $r('app.string.settings_timer_config') }) {
              this.CounterRow($r('app.string.settings_focus_duration'), this.draftSettings.focusDuration, (val: number) => {
                this.draftSettings.focusDuration = val; // 修改草稿，立即刷新 UI
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

            // 2. 自动化配置
            SettingCard({ title: $r('app.string.settings_automation') }) {
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

            // 3. 通知配置
            SettingCard({ title: $r('app.string.settings_notification') }) {
              this.ToggleRow($r('app.string.settings_timer_finished_alert'), this.draftSettings.notificationEnabled, (val: boolean) => {
                this.draftSettings.notificationEnabled = val;
              }, $r('app.string.settings_timer_finished_alert_desc'))
            }
            // 底部版本号
            Text($r('app.string.settings_version', $r('app.string.app_version')))
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary')) // #C0C0C0
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

  // --- 封装：计数器行 ---
  // label 和 desc 改为 ResourceStr 类型，兼容 string 和 Resource
  @Builder CounterRow(label: ResourceStr, value: number, onChange: (val: number) => void, desc?: ResourceStr) {
    Row() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
        if (desc) {
          Text(desc)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Row({ space: 12 }) {
        // 减号按钮
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.minus'))
            .fontSize(16)
            .fontColor([$r('app.color.text_primary')])
        }
        .width(32)
        .height(32)
        .backgroundColor($r('app.color.setting_btn_bg')) // #F0F2F5
        .onClick(() => {
          if (value > 1) onChange(value - 1)
        })

        Text((value ?? 0).toString())
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width(24)
          .textAlign(TextAlign.Center)

        // 加号按钮
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(16)
            .fontColor([$r('app.color.text_primary')])
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
    .padding(16)
    .height(desc ? 72 : 56)
  }

  // --- 封装：开关行 ---
  @Builder ToggleRow(label: ResourceStr, isOn: boolean, onChange: (val: boolean) => void, desc?: ResourceStr) {
    Row() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
        if (desc) {
          Text(desc)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor($r('app.color.text_primary')) // 开关开启颜色
        .width(52)   // 增大宽度 (建议 48-52)
        .height(32)  // 增大高度 (建议 28-32)
        .onChange((isOn: boolean) => {
          onChange(isOn)
        })
    }
    .width('100%')
    .padding(16)
    .height(desc ? 72 : 56)
  }
}