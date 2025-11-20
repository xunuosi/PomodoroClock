import promptAction from '@ohos.promptAction';

// 定义计时模式的枚举
enum TimerMode {
  Focus = 'Focus',
  Short = 'Short',
  Long = 'Long'
}

@Preview
@Entry
@Component
struct Index {
  // --- 状态变量 ---
  @State currentMode: TimerMode = TimerMode.Focus; // 当前模式
  @State timeLeft: number = 25 * 60; // 剩余时间（秒），默认25分钟
  @State totalTime: number = 25 * 60; // 总时间（用于计算进度条）
  @State isRunning: boolean = false; // 是否正在计时
  @State taskList: string[] = []; // 任务列表
  @State newTaskName: string = ''; // 输入框内容

  private timerId: number = -1; // 定时器ID

  // --- 颜色常量 (参考设计图) ---
  private readonly ColorPrimary: string = '#F08080'; // 番茄红
  private readonly ColorDark: string = '#2B333E'; // 深色按钮/文字
  private readonly ColorBg: string = '#F7F8FA'; // 页面背景灰
  private readonly ColorLightRed: string = '#FDECEC'; // 浅红色背景

  // --- 生命周期 ---
  aboutToDisappear() {
    this.stopTimer(); // 页面销毁时清除定时器
  }

  // --- 逻辑方法 ---

  // 切换模式
  switchMode(mode: TimerMode) {
    this.stopTimer();
    this.currentMode = mode;
    this.isRunning = false;

    // 根据模式设置时长
    if (mode === TimerMode.Focus) {
      this.totalTime = 25 * 60;
    } else if (mode === TimerMode.Short) {
      this.totalTime = 5 * 60;
    } else {
      this.totalTime = 15 * 60;
    }
    this.timeLeft = this.totalTime;
  }

  // 开始/暂停计时
  toggleTimer() {
    if (this.isRunning) {
      this.stopTimer();
      this.isRunning = false;
    } else {
      this.isRunning = true;
      this.timerId = setInterval(() => {
        if (this.timeLeft > 0) {
          this.timeLeft--;
        } else {
          this.stopTimer();
          this.isRunning = false;
          // 倒计时结束提示
          promptAction.showToast({ message: 'Time is up!' });
        }
      }, 1000);
    }
  }

  // 停止计时器
  stopTimer() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  // 重置计时
  resetTimer() {
    this.stopTimer();
    this.isRunning = false;
    this.timeLeft = this.totalTime;
  }

  // 添加任务
  addTask() {
    if (this.newTaskName.trim() !== '') {
      this.taskList.push(this.newTaskName);
      this.newTaskName = ''; // 清空输入框
    }
  }

  // 格式化时间 MM:SS
  formatTime(seconds: number): string {
    const m = Math.floor(seconds / 60).toString().padStart(2, '0');
    const s = (seconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  // --- UI 构建 ---

  build() {
    Column() {
      // 1. 顶部导航栏 (Logo + 设置)
      this.HeaderBuilder()

      // 2. 模式切换 (Focus/Short/Long)
      this.ModeSwitcherBuilder()

      // 3. 倒计时圆环
      this.TimerCircleBuilder()

      // 4. 控制按钮 (重置 + 播放/暂停)
      this.ControlsBuilder()

      // 5. 任务列表区域
      this.TasksSectionBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.ColorBg)
    .padding({ top: 10, bottom: 20 }) // 安全区和底部留白
  }

  @Builder HeaderBuilder() {
    Row() {
      Row({ space: 8 }) {
        // 这里引用之前的 logo，如果还没有可以使用 Image($r('app.media.icon'))
        Image($r('app.media.tomatodo_logo'))
          .width(24)
          .height(24)
        Text('Tomatodo')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ColorDark)
      }

      Blank()

      // 设置图标 (暂时用系统图标代替)
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
    .justifyContent(FlexAlign.SpaceEvenly) // 均匀分布
    .padding(4)
  }

  @Builder ModeButton(text: string, mode: TimerMode) {
    Button(text)
      .type(ButtonType.Capsule)
      .backgroundColor(this.currentMode === mode ? this.ColorDark : Color.Transparent)
      .fontColor(this.currentMode === mode ? Color.White : '#989A9C')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .height('100%')
      .width('30%') // 三等分
      .onClick(() => {
        this.switchMode(mode);
      })
  }

  @Builder TimerCircleBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      // 1. 底层浅红色圆背景
      Circle()
        .width(280)
        .height(280)
        .fill(this.ColorLightRed)

      // 2. 进度条 (环形)
      Progress({ value: this.timeLeft, total: this.totalTime, type: ProgressType.Ring })
        .width(280)
        .height(280)
        .color(this.ColorPrimary) // 进度条颜色
        .style({ strokeWidth: 12 }) // 线条宽度
        .backgroundColor(Color.Transparent) // 轨道透明

      // 3. 中间文字内容
      Column({ space: 8 }) {
        Text(this.formatTime(this.timeLeft))
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.ColorDark)

        Text(this.isRunning ? 'FOCUSING' : 'PAUSED')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isRunning ? this.ColorPrimary : '#A0A0A0')
          .letterSpacing(2)
      }
    }
    .margin({ top: 20, bottom: 40 })
  }

  @Builder ControlsBuilder() {
    Row({ space: 20 }) {
      // 重置按钮 (左侧小圆)
      Button({ type: ButtonType.Circle }) {
        // 这里的 refresh 图标可以用系统图标
        Image($r('sys.media.ohos_ic_public_restore'))
          .width(24)
          .height(24)
          .fillColor(this.ColorDark)
      }
      .width(56)
      .height(56)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        this.resetTimer();
      })

      // 播放/暂停按钮 (中间大圆角矩形)
      Button() {
        Image(this.isRunning ? $r('sys.media.ohos_ic_public_pause') : $r('sys.media.ohos_ic_public_play'))
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
        this.toggleTimer();
      })
    }
    .margin({ bottom: 40 })
  }

  @Builder TasksSectionBuilder() {
    Column() {
      // 任务栏标题
      Row() {
        Text('TASKS')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#989A9C')
          .letterSpacing(1)

        Blank()

        Text(`SESSIONS ${this.taskList.length}`)
          .fontSize(12)
          .fontColor('#989A9C')
          .backgroundColor('#F0F0F0')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(10)
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 输入框行
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
            this.addTask();
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
          this.addTask();
        })
      }
      .margin({ bottom: 20 })

      // 任务列表 / 空状态
      if (this.taskList.length === 0) {
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
        // 显示任务列表
        List({ space: 10 }) {
          ForEach(this.taskList, (task: string, index: number) => {
            ListItem() {
              Row() {
                // 模拟勾选框
                Circle().width(16).height(16).stroke(this.ColorPrimary).strokeWidth(2).fill(Color.Transparent).margin({right: 10})
                Text(task).fontSize(16).fontColor(this.ColorDark)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#F9F9F9')
              .borderRadius(8)
            }
          })
        }
        .height(150) // 限制高度，可滚动
      }
    }
    .width('90%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .padding(24)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 10 }) // 阴影效果
  }
}