import { TimerStore, TimerMode, TaskItem, BreathPhase } from '../model/TimerModel';
import { window } from '@kit.ArkUI';

@Preview
@ComponentV2
export struct TimerView {
  // 接收外部传入的 VM，或者内部实例化
  @Param store: TimerStore = new TimerStore();
  @Local newTaskName: string = '';
  // 新增：顶部避让高度状态
  @Local topMargin: number = 0;
  // 呼吸动画控制变量
  @Local breathScale: number = 0.8;
  @Local breathOpacity: number = 0.6;
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

  // 监听呼吸阶段变化，执行动画
  @Monitor('store.breathPhase')
  onPhaseChange() {
    if (this.store.currentMode !== TimerMode.Breathing) return;
    const uiContext = this.getUIContext();

    if (this.store.breathPhase === BreathPhase.Inhale) {
      // 吸气：光晕扩散，变亮
      uiContext.animateTo({ duration: 4000, curve: Curve.EaseInOut }, () => {
        this.breathScale = 1.2;
        this.breathOpacity = 0.8;
      });
    } else if (this.store.breathPhase === BreathPhase.Hold) {
      // 屏息：保持并在微幅波动 (模拟静止中的张力)
      uiContext.animateTo({ duration: 7000, curve: Curve.Linear }, () => {
        this.breathScale = 1.25;
      });
    } else if (this.store.breathPhase === BreathPhase.Exhale) {
      // 呼气：收缩，变淡
      uiContext.animateTo({ duration: 8000, curve: Curve.EaseInOut }, () => {
        this.breathScale = 0.8;
        this.breathOpacity = 0.4;
      });
    }
  }

  build() {
    NavDestination() {
      // 使用 Stack 确保内容可以全屏覆盖
      Stack({ alignContent: Alignment.TopStart }) {

        // --- 1. 常规界面 (放在底层) ---
        // 只有在非呼吸模式下才渲染/显示常规内容，或者用 visibility 控制
        // 这里为了简单，我们用条件渲染。当 breathing 时，完全替换整个界面
        if (this.store.currentMode !== TimerMode.Breathing) {
          Scroll() {
            Column() {
              this.HeaderBuilder() // 标题栏
              this.ModeSwitcherBuilder()
              this.TimerCircleBuilder()
              this.ControlsBuilder()
              this.TasksSectionBuilder()
            }
            .width('100%')
            .padding({ top: this.topMargin, bottom: 50 })
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Auto)
          // ...
        }

        // --- 2. 全屏呼吸引导 (独占显示) ---
        if (this.store.currentMode === TimerMode.Breathing) {
          this.BreathingSectionBuilder()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.store.currentMode === TimerMode.Breathing ? $r('app.color.white') : $r('app.color.app_window_bg'))
      // 呼吸模式使用纯白背景更干净
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
  }

  @Builder
  HeaderBuilder() {
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
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        .onClick(() => {
          // 跳转到 'Settings' 并传递当前的 store 实例
          // 这样 Settings 页面修改的数据会直接同步回 TimerView
          const navInfo = this.queryNavigationInfo();
          if (navInfo) {
            navInfo.pathStack.pushPath({ name: 'Settings', param: this.store });
          }
        })
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 0,
      bottom: 10
    })
  }

  @Builder
  ModeSwitcherBuilder() {
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

  @Builder
  ModeButton(text: ResourceStr, mode: TimerMode) {
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

  @Builder
  TimerCircleBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(280)
        .height(280)
        .borderRadius(140) // 关键：宽高的一半，剪裁成正圆
        .radialGradient({
          center: ['50%', '50%'],
          radius: 220,
          colors: [
            // 0.0 (中心) -> 主体背景色
            [this.circleBackgroundColor, 0.0],
            // 1.0 (边缘) -> 纯白 (逐渐变浅)
            [Color.White, 1.0]
          ]
        })

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

  @Builder
  ControlsBuilder() {
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

  @Builder
  TasksSectionBuilder() {
    Column() {
      Row() {
        Text($r('app.string.tasks_hint'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#989A9C')
          .letterSpacing(1)
        Blank()
        Text($r('app.string.sessions_count', this.store.completedTaskCount))
          .fontSize(12)
          .fontColor('#989A9C')
          .backgroundColor('#F0F0F0')
          .padding({
            left: 8,
            right: 8,
            top: 4,
            bottom: 4
          })
          .borderRadius(10)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row({ space: 12 }) {
        TextInput({ placeholder: $r('app.string.app_add_task_hint'), text: this.newTaskName })
          .placeholderColor($r('app.color.text_hint'))
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F8FAFC')
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
        .backgroundColor(this.newTaskName.trim().length > 0 ? '#0f172a' : '#989A9C')
        .animation({ duration: 200 })
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
        Column({ space: 10 }) {
          // 遍历 TaskItem 对象
          ForEach(this.store.taskList, (task: TaskItem, index: number) => {
            Row() {
              // 1. 左侧勾选按钮 (点击切换状态)
              Row() {
                if (task.isCompleted) {
                  // ✅ 完成状态：显示绿色对勾圆环
                  // 使用 SymbolGlyph 的 checkmark.circle
                  SymbolGlyph($r('sys.symbol.checkmark_circle'))
                    .fontSize(24)
                    .fontColor([$r('app.color.green_500')]) // 绿色
                } else {
                  // ✅ 未完成状态：显示绿色描边圆圈
                  Circle()
                    .width(20)
                    .height(20)
                    .stroke($r('app.color.green_500')) // 绿色描边
                    .strokeWidth(2)
                    .fill(Color.Transparent)
                    .margin({ left: 2, right: 2 }) // 微调位置以对齐 Symbol
                }
              }
              .width(30) // 固定触控区域宽度
              .justifyContent(FlexAlign.Start)
              .onClick(() => {
                // 触发 V2 状态更新
                this.store.toggleTask(task);
              })

              // 2. 中间任务文本
              Text(task.content)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(task.isCompleted ? $r('app.color.989A9C') : this.ColorDark) // 完成变灰
                .decoration({
                  type: task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None,
                  color: $r('app.color.989A9C')
                }) // 完成加删除线 (如果不想要删除线，可去掉此属性)
                .layoutWeight(1)
                .margin({ left: 8 })

              // 3. 右侧删除按钮 (垃圾桶)
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(18)
                  .fontColor(['#CFD1D4']) // 浅灰色图标
              }
              .width(32)
              .height(32)
              .backgroundColor(Color.Transparent) // 透明背景
              .onClick(() => {
                // 触发删除逻辑
                this.store.deleteTask(task);
              })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F9F9F9')
            .borderRadius(12)
          })
        }
      }
    }
    .width('90%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding(24)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 10 })
  }

  @Builder BreathingSectionBuilder() {
    Stack({ alignContent: Alignment.Center }) {

      // --- 层级 1: 呼吸光晕 (背景) ---
      // 使用一个巨大的圆形，配合径向渐变和高斯模糊
      Circle()
        .width(300) // 基础大小
        .height(300)
        .fill(Color.Transparent) // 填充透明，仅靠渐变
        .radialGradient({
          center: ['50%', '50%'],
          radius: 150,
          colors: [
            // [替换] 中心薄荷绿
            [$r('app.color.breath_halo_center'), 0.0],
            // [替换] 边缘透明
            [$r('app.color.breath_halo_edge'), 1.0]
          ]
        })
        .blur(60) // 关键：强力高斯模糊，制造弥散光感
        .scale({ x: this.breathScale * 2.5, y: this.breathScale * 2.5 }) // 放大铺满屏幕中心
        .opacity(this.breathOpacity)
        .animation({ duration: 1000 }) // 属性变化时的平滑过渡

      // --- 层级 2: 文字与读秒 (前景) ---
      Column({ space: 16 }) {
        // 1. 状态标题 (如：屏息)
        Text(this.store.breathText)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.breath_text_title'))
          .opacity(0.9)

        // 2. 指导语 (如：感受当下的静止)
        Text(this.store.breathGuideText)
          .fontSize(16)
          .fontWeight(FontWeight.Normal)
          .fontColor($r('app.color.breath_text_guide'))
          .letterSpacing(2) // 增加字间距，显得更空灵

        // 3. 超大倒计时 (如：7)
        Text(`${this.store.breathSeconds}`)
          .fontSize(100) // 超大字号
          .fontWeight(FontWeight.Lighter) // 极细字体
          .fontColor($r('app.color.breath_text_counter'))
          .margin({ top: 20 })
          // 数字跳动动画（可选，让数字变化不那么生硬）
          .animation({ duration: 200 })
      }
      .alignItems(HorizontalAlign.Center)

      // --- 层级 3: 底部跳过按钮 ---
      Column() {
        Blank() // 占位，推到底部
        Button($r('app.string.btn_skip'))
          .type(ButtonType.Normal) // 纯文字按钮风格
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.breath_btn_skip'))
          .fontSize(14)
          .margin({ bottom: 80 }) // 避开底部手势区
          .onClick(() => {
            this.store.skipBreathing();
          })
      }
      .height('100%')
      .width('100%')
    }
    .width('100%')
    .height('100%')
    // 沉浸式：这一层要覆盖到状态栏区域
    .margin({ top: 0 })
  }
}