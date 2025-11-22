import { TimerStore, TimerMode } from '../model/TimerModel';
import { window } from '@kit.ArkUI';

@Preview
@ComponentV2
export struct TimerView {
  // 接收外部传入的 VM，或者内部实例化
  @Local store: TimerStore = new TimerStore();
  @Local newTaskName: string = '';
  // ✅ 新增：顶部避让高度状态
  @Local topMargin: number = 0;

  // 颜色常量
  private readonly ColorDark: string = '#2B333E';
  private readonly ColorLightRed: string = '#FDECEC';

  // --- 2. 核心逻辑：获取当前主题色 ---
  // 如果是 Focus 模式显示红色，否则（Short/Long）显示绿色
  get themeColor(): ResourceStr {
    if (this.store.currentMode === TimerMode.Focus) {
      return $r('app.color.app_primary_red_500');
    } else if (this.store.currentMode === TimerMode.Short) {
      return $r('app.color.green_500');
    } else {
      // ✅ [修改] 长休息返回蓝色
      return $r('app.color.blue_500');
    }
  }

  get circleBackgroundColor(): ResourceStr {
    if (this.store.currentMode === TimerMode.Focus) {
      return $r('app.color.focus_circle_bg');
    } else if (this.store.currentMode === TimerMode.Short) {
      return $r('app.color.short_rest_circle_bg');
    } else {
      return $r('app.color.long_rest_circle_bg');
    }
  }

  get statusText(): ResourceStr {
    if (!this.store.isRunning) {
      return $r('app.string.app_h_stopped');
    }
    // 专注显示“专注中”，其他（短/长休息）都显示“休息中”
    return this.store.currentMode === TimerMode.Focus ? $r('app.string.app_focusing') : $r('app.string.app_resting');
  }

  aboutToAppear(): void {
    // ✅ 获取 Window 实例进行设置
    window.getLastWindow(this.getUIContext().getHostContext()).then((win) => {
      // 1. 恢复状态栏显示
      win.setWindowSystemBarEnable(['status', 'navigation']);
      win.setWindowSystemBarProperties({
        statusBarColor: '#F7F8FA',
        statusBarContentColor: '#000000',
        navigationBarContentColor: '#000000'
      });
      // 2. 定义获取高度的逻辑
      const updateHeight = (area: window.AvoidArea) => {
        const height = this.getUIContext().px2vp(area.topRect.height);
        // 只有当高度大于0（状态栏真的出现了）才更新，避免闪烁
        if (height > 0) {
          this.topMargin = height;
        }
      };

      // 3. 【初次尝试】获取当前高度 (可能还是0，但试一下无妨)
      let type = window.AvoidAreaType.TYPE_SYSTEM;
      let avoidArea = win.getWindowAvoidArea(type);
      updateHeight(avoidArea);

      // 4. 【核心修复】监听高度变化事件
      // 当状态栏从“隐藏”变为“显示”的过程中，这个回调会被触发，
      // 从而自动修正 topMargin，把 UI 挤下来。
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          updateHeight(data.area);
        }
      });
    });
  }

  aboutToDisappear(): void {
    this.store.stopTimer();
  }

  build() {
    // NavDestination 是 Navigation 架构下的标准页面容器
    NavDestination() {
      Scroll() {
        Column() {
          // 1. 顶部导航
          this.HeaderBuilder()

          // 2. 模式切换
          this.ModeSwitcherBuilder()

          // 3. 倒计时圆环
          this.TimerCircleBuilder()

          // 4. 控制按钮
          this.ControlsBuilder()

          // 5. 任务列表
          this.TasksSectionBuilder()
        }
        .width('100%')
        .backgroundColor($r('app.color.app_window_bg'))
        .padding({ top: 13, bottom: 50 }) // 底部留白，防止划到底太贴边
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto) // 自动显示滚动条
      .align(Alignment.TopStart)
      // ✅ 关键修复：手动添加顶部 Padding，避开状态栏
      .padding({ top: this.topMargin })
      // API 17+ 使用 expandSafeArea 处理沉浸式，不再需要手动计算 padding
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true) // 隐藏系统默认标题栏，使用自定义 Header
  }

  @Builder HeaderBuilder() {
    Row() {
      Row({ space: 8 }) {
        Image($r('app.media.tomatodo_logo'))
          .width(24)
          .height(24)
        Text($r('app.string.app_name'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ColorDark)
      }
      Blank()
      SymbolGlyph($r('sys.symbol.gearshape'))
        .fontSize(24)
        .fontColor([$r('app.color.989A9C')])
        .fontWeight(FontWeight.Medium)            // 可选：设置粗细
        .renderingStrategy(SymbolRenderingStrategy.SINGLE) // 可选：单色渲染
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 0, bottom: 10 })
  }

  @Builder ModeSwitcherBuilder() {
    Row() {
      this.ModeButton($r('app.string.app_focus'), TimerMode.Focus)
      this.ModeButton($r('app.string.app_short_rest'), TimerMode.Short)
      this.ModeButton($r('app.string.app_long_rest'), TimerMode.Long)
    }
    .width('90%')
    .height(48)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .margin({ top: 20, bottom: 30 })
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding(4)
  }

  @Builder ModeButton(text: ResourceStr, mode: TimerMode) {
    Button(text)
      .type(ButtonType.Capsule)
      // 直接读取 store 中的状态
      .backgroundColor(this.store.currentMode === mode ? this.ColorDark : Color.Transparent)
      .fontColor(this.store.currentMode === mode ? Color.White : '#989A9C')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .height('100%')
      .width('30%')
      .onClick(() => {
        this.store.switchMode(mode);
      })
  }

  @Builder TimerCircleBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(280)
        .height(280)
        .fill(this.circleBackgroundColor)

      Progress({ value: this.store.timeLeft, total: this.store.totalTime, type: ProgressType.Ring })
        .width(280)
        .height(280)
        .color(this.themeColor)
        .style({ strokeWidth: 12 })
        .backgroundColor(Color.Transparent)

      Column({ space: 8 }) {
        // 使用 getter 获取格式化时间
        Text(this.store.formattedTime)
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ColorDark)

        Text(this.statusText)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.store.isRunning ? this.themeColor : '#A0A0A0')
          .letterSpacing(2)
      }
    }
    .margin({ top: 20, bottom: 40 })
  }

  @Builder ControlsBuilder() {
    Row({ space: 20 }) {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
          .fontSize(24)
          .fontColor([this.ColorDark])
          .fontWeight(FontWeight.Medium)
          .renderingStrategy(SymbolRenderingStrategy.SINGLE)
      }
      .width(56)
      .height(56)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .onClick(() => {
        this.store.resetTimer();
      })

      Button() {
        Image(this.store.isRunning ? $r('sys.media.ohos_ic_public_pause') : $r('sys.media.ohos_ic_public_play'))
          .width(32)
          .height(32)
          .fillColor(Color.White)
      }
      .type(ButtonType.Normal)
      .borderRadius(20)
      .width(100)
      .height(64)
      .backgroundColor(this.themeColor)
      .onClick(() => {
        this.store.toggleTimer();
      })
    }
    .margin({ bottom: 40 })
  }

  @Builder TasksSectionBuilder() {
    Column() {
      Row() {
        Text($r('app.string.tasks_hint'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#989A9C')
          .letterSpacing(1)
        Blank()
        Text($r('app.string.sessions_count', this.store.taskList.length))
          .fontSize(12)
          .fontColor('#989A9C')
          .backgroundColor('#F0F0F0')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row({ space: 12 }) {
        TextInput({ placeholder: $r('app.string.app_add_task_hint'), text: this.newTaskName })
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F7F8FA')
          .borderRadius(12)
          .onChange((value: string) => {
            this.newTaskName = value;
          })
          .onSubmit(() => {
            this.store.addTask(this.newTaskName);
            this.newTaskName = '';
          })

        Button({ type: ButtonType.Normal }) {
          Image($r('sys.media.ohos_ic_public_add'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .borderRadius(12)
        .width(48)
        .height(48)
        .backgroundColor('#989A9C')
        .onClick(() => {
          this.store.addTask(this.newTaskName);
          this.newTaskName = '';
        })
      }
      .margin({ bottom: 20 })

      if (this.store.taskList.length === 0) {
        Column({ space: 4 }) {
          Text($r('app.string.app_empty_task_hint'))
            .fontSize(14)
            .fontColor('#C0C0C0')
            .fontStyle(FontStyle.Italic)
          Text($r('app.string.app_add_task_slogan'))
            .fontSize(14)
            .fontColor('#C0C0C0')
            .fontStyle(FontStyle.Italic)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 20 })
      } else {
        List({ space: 10 }) {
          // V2 中 ForEach 依然可用，Repeat 是更优选择，但 ForEach 足够稳定
          ForEach(this.store.taskList, (task: string, index: number) => {
            ListItem() {
              Row() {
                Circle().width(16).height(16).stroke($r('app.color.app_primary_red_500')).strokeWidth(2).fill(Color.Transparent).margin({ right: 10 })
                Text(task).fontSize(16).fontColor(this.ColorDark)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#F9F9F9')
              .borderRadius(8)
            }
          })
        }
        .height(150)
      }
    }
    .width('90%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding(24)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 10 })
  }
}