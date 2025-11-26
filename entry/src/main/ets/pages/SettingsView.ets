import { TimerStore, SettingsModel } from '../model/TimerModel';
import { window } from '@kit.ArkUI';

/**
 * ✅ [新增] 计数器子组件
 * 使用 @ComponentV2 独立封装，确保 @Param value 变化时 Text 能 100% 刷新
 */
@ComponentV2
struct CounterRow {
  @Param label: ResourceStr = '';
  @Param value: number = 0;
  @Param desc: ResourceStr = '';
  @Event onChange: (val: number) => void = (val: number) => {};

  build() {
    Row() {
      // 左侧文字
      Column({ space: 4 }) {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        if (this.desc) {
          Text(this.desc)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧操作区
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
          if (this.value > 1) {
            this.onChange(this.value - 1); // 触发事件
          }
        })

        // 这里的 Text 现在绑定的是组件的 @Param，刷新绝对稳定
        Text((this.value ?? 0).toString())
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
          if (this.value < 60) {
            this.onChange(this.value + 1); // 触发事件
          }
        })
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .constraintSize({ minHeight: 56 })
  }
}

/**
 * ✅ [新增] 开关子组件
 * 同样独立封装，保持代码风格一致性
 */
@ComponentV2
struct ToggleRow {
  @Param label: ResourceStr = '';
  @Param isOn: boolean = false;
  @Param desc: ResourceStr = '';
  @Event onChange: (isOn: boolean) => void = (isOn: boolean) => {};

  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        if (this.desc) {
          Text(this.desc)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor($r('app.color.text_primary'))
        .width(52)
        .height(32)
        .onChange((isOn: boolean) => {
          this.onChange(isOn);
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .constraintSize({ minHeight: 56 })
  }
}

@Preview
@ComponentV2
export struct SettingsView {
  @Param store: TimerStore = new TimerStore();
  @Local draftSettings: SettingsModel = new SettingsModel();
  @Local topMargin: number = 0;

  aboutToAppear(): void {
    this.draftSettings.copyFrom(this.store.settings);

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
              this.store.settings.copyFrom(this.draftSettings);
              this.store.saveData();
              this.store.resetTimer();

              const nav = this.queryNavigationInfo();
              nav?.pathStack.pop();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15, bottom: 0 })

        // --- 内容滚动区 ---
        Scroll() {
          Column({ space: 20 }) {
            // ✅ 第一组：计时器配置
            Column() {
              this.GroupTitle($r('app.string.settings_timer_config'))

              Column() {
                // 使用子组件 CounterRow
                CounterRow({
                  label: $r('app.string.settings_focus_duration'),
                  value: this.draftSettings.focusDuration,
                  onChange: (val: number) => { this.draftSettings.focusDuration = val; }
                })
                Divider().color($r('app.color.divider'))
                CounterRow({
                  label: $r('app.string.settings_short_break_duration'),
                  value: this.draftSettings.shortBreakDuration,
                  onChange: (val: number) => { this.draftSettings.shortBreakDuration = val; }
                })
                Divider().color($r('app.color.divider'))
                CounterRow({
                  label: $r('app.string.settings_long_break_duration'),
                  value: this.draftSettings.longBreakDuration,
                  onChange: (val: number) => { this.draftSettings.longBreakDuration = val; }
                })
              }
              .backgroundColor(Color.White)
              .borderRadius(16)
              .padding({ top: 4, bottom: 4 })
            }

            // ✅ 第二组：自动化配置
            Column() {
              this.GroupTitle($r('app.string.settings_automation'))

              Column() {
                // 新增开关
                ToggleRow({
                  label: $r('app.string.settings_enable_breathing'), // 引用新添加的字符串
                  isOn: this.draftSettings.enableBreathing,
                  onChange: (val: boolean) => { this.draftSettings.enableBreathing = val; }
                })
                Divider().color($r('app.color.divider'))

                ToggleRow({
                  label: $r('app.string.settings_auto_start_break'),
                  isOn: this.draftSettings.autoStartBreaks,
                  onChange: (val: boolean) => { this.draftSettings.autoStartBreaks = val; }
                })
                Divider().color($r('app.color.divider'))

                ToggleRow({
                  label: $r('app.string.settings_auto_start_focus'),
                  isOn: this.draftSettings.autoStartFocus,
                  onChange: (val: boolean) => { this.draftSettings.autoStartFocus = val; }
                })
                Divider().color($r('app.color.divider'))

                CounterRow({
                  label: $r('app.string.settings_long_break_interval'),
                  value: this.draftSettings.longBreakInterval,
                  desc: $r('app.string.settings_long_break_interval_desc'),
                  onChange: (val: number) => { this.draftSettings.longBreakInterval = val; }
                })
              }
              .backgroundColor(Color.White)
              .borderRadius(16)
              .padding({ top: 4, bottom: 4 })
            }

            // ✅ 第三组：通知配置
            Column() {
              this.GroupTitle($r('app.string.settings_notification'))

              Column() {
                ToggleRow({
                  label: $r('app.string.settings_timer_finished_alert'),
                  isOn: this.draftSettings.notificationEnabled,
                  desc: $r('app.string.settings_timer_finished_alert_desc'),
                  onChange: (val: boolean) => { this.draftSettings.notificationEnabled = val; }
                })
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
          .margin({ top: -32 })
        }
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
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

  // 分组标题（静态内容，可以用 Builder）
  @Builder GroupTitle(title: ResourceStr) {
    Text(title)
      .fontSize(12)
      .fontColor($r('app.color.text_secondary'))
      .margin({ left: 12, bottom: 8 })
      .width('100%')
  }
}