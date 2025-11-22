import { TimerStore, TimerMode } from '../model/TimerModel';

@ComponentV2
export struct TimerView {
  // 接收外部传入的 VM，或者内部实例化
  @Local store: TimerStore = new TimerStore();
  @Local newTaskName: string = '';

  // 颜色常量
  private readonly ColorPrimary: string = '#F08080';
  private readonly ColorDark: string = '#2B333E';
  private readonly ColorBg: string = '#F7F8FA';
  private readonly ColorLightRed: string = '#FDECEC';

  aboutToDisappear(): void {
    this.store.stopTimer();
  }

  build() {
    // NavDestination 是 Navigation 架构下的标准页面容器
    NavDestination() {
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
      .height('100%')
      .backgroundColor(this.ColorBg)
      // API 17+ 使用 expandSafeArea 处理沉浸式，不再需要手动计算 padding
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true) // 隐藏系统默认标题栏，使用自定义 Header
  }

  @Builder HeaderBuilder() {
    Row() {
      Row({ space: 8 }) {
        Image($r('app.media.tomatodo_logo'))
          .width(24)
          .height(24)
        Text('Tomatodo')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ColorDark)
      }
      Blank()
      Image($r('sys.media.ohos_ic_public_edit'))
        .width(24)
        .height(24)
        .fillColor('#989A9C')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
  }

  @Builder ModeSwitcherBuilder() {
    Row() {
      this.ModeButton('Focus', TimerMode.Focus)
      this.ModeButton('Short', TimerMode.Short)
      this.ModeButton('Long', TimerMode.Long)
    }
    .width('90%')
    .height(48)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .margin({ top: 20, bottom: 30 })
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding(4)
  }

  @Builder ModeButton(text: string, mode: TimerMode) {
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
        .fill(this.ColorLightRed)

      Progress({ value: this.store.timeLeft, total: this.store.totalTime, type: ProgressType.Ring })
        .width(280)
        .height(280)
        .color(this.ColorPrimary)
        .style({ strokeWidth: 12 })
        .backgroundColor(Color.Transparent)

      Column({ space: 8 }) {
        // 使用 getter 获取格式化时间
        Text(this.store.formattedTime)
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ColorDark)

        Text(this.store.isRunning ? 'FOCUSING' : 'PAUSED')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.store.isRunning ? this.ColorPrimary : '#A0A0A0')
          .letterSpacing(2)
      }
    }
    .margin({ top: 20, bottom: 40 })
  }

  @Builder ControlsBuilder() {
    Row({ space: 20 }) {
      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.ohos_ic_public_restore'))
          .width(24)
          .height(24)
          .fillColor(this.ColorDark)
      }
      .width(56)
      .height(56)
      .backgroundColor('#FFFFFF')
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
      .backgroundColor(this.ColorPrimary)
      .onClick(() => {
        this.store.toggleTimer();
      })
    }
    .margin({ bottom: 40 })
  }

  @Builder TasksSectionBuilder() {
    Column() {
      Row() {
        Text('TASKS')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#989A9C')
          .letterSpacing(1)
        Blank()
        Text(`SESSIONS ${this.store.taskList.length}`)
          .fontSize(12)
          .fontColor('#989A9C')
          .backgroundColor('#F0F0F0')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Row({ space: 12 }) {
        TextInput({ placeholder: 'Add a new task...', text: this.newTaskName })
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
          Text('No tasks yet.')
            .fontSize(14)
            .fontColor('#C0C0C0')
            .fontStyle(FontStyle.Italic)
          Text('Add one to get started!')
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
                Circle().width(16).height(16).stroke(this.ColorPrimary).strokeWidth(2).fill(Color.Transparent).margin({ right: 10 })
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