import { TimerStore } from '../model/TimerModel';

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
              this.CounterRow($r('app.string.settings_focus_duration'), this.store.settings.focusDuration, (val: number) => {
                this.store.settings.focusDuration = val;
                this.store.saveData();
              })
              Divider().color($r('app.color.divider'))
              this.CounterRow($r('app.string.settings_short_break_duration'), this.store.settings.shortBreakDuration, (val: number) => {
                this.store.settings.shortBreakDuration = val;
                this.store.saveData();
              })
              Divider().color($r('app.color.divider'))
              this.CounterRow($r('app.string.settings_long_break_duration'), this.store.settings.longBreakDuration, (val: number) => {
                this.store.settings.longBreakDuration = val;
                this.store.saveData();
              })
            }

            // 2. 自动化配置
            SettingCard({ title: $r('app.string.settings_automation') }) {
              this.ToggleRow($r('app.string.settings_auto_start_break'), this.store.settings.autoStartBreaks, (val: boolean) => {
                this.store.settings.autoStartBreaks = val;
                this.store.saveData();
              })
              Divider().color($r('app.color.divider'))
              this.ToggleRow($r('app.string.settings_auto_start_focus'), this.store.settings.autoStartFocus, (val: boolean) => {
                this.store.settings.autoStartFocus = val;
                this.store.saveData();
              })
              Divider().color($r('app.color.divider'))
              this.CounterRow($r('app.string.settings_long_break_interval'), this.store.settings.longBreakInterval, (val: number) => {
                this.store.settings.longBreakInterval = val;
                this.store.saveData();
              }, $r('app.string.settings_long_break_interval_desc'))
            }

            // 3. 通知配置
            SettingCard({ title: $r('app.string.settings_notification') }) {
              this.ToggleRow($r('app.string.settings_timer_finished_alert'), this.store.settings.notificationEnabled, (val: boolean) => {
                this.store.settings.notificationEnabled = val;
                this.store.saveData();
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

        Text(value.toString())
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
        .onChange((isOn: boolean) => {
          onChange(isOn)
        })
    }
    .width('100%')
    .padding(16)
    .height(desc ? 72 : 56)
  }
}