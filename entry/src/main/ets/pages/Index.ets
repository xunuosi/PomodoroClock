/**
 * HarmonyOS Next - Pomodoro Timer UI
 * 基于图片还原的界面
 */

@Entry
@Component
struct PomodoroTimerPage {
  // 状态管理：当前选中的模式
  @State currentMode: string = 'Focus';
  // 状态管理：底部导航选中项
  @State activeTab: number = 0;

  // 定义颜色常量，方便统一管理
  private readonly colorPrimaryDark: string = '#131728'; // 深色背景/按钮
  private readonly colorBackground: string = '#FFFFFF'; // 整体背景
  private readonly colorGrayLight: string = '#F3F4F6'; // 浅灰背景
  private readonly colorTextGray: string = '#999999'; // 灰色文字
  private readonly colorAccentYellow: string = '#FFF5D6'; // 金币背景
  private readonly colorAccentRed: string = '#FF6B6B'; // 底部激活色

  build() {
    Column() {
      // 1. 顶部状态栏占位 (模拟图片中的 9:41)
      Row() {
        Text('9:41').fontWeight(FontWeight.Bold).fontSize(14)
        Row({ space: 4 }) {
          Rect().width(16).height(10).fill('#E0E0E0') // 信号图标占位
          Rect().width(20).height(10).fill(this.colorPrimaryDark).radius(2) // 电池图标占位
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })

      // 2. 主要内容区域 (可滚动或弹性布局)
      Column() {

        // --- 金币积分显示 ---
        Row() {
          Blank() // 撑开左边，使内容靠右
          Row() {
            Text('🏆').fontSize(14).margin({ right: 4 })
            Text('210')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D98E26')
          }
          .backgroundColor(this.colorAccentYellow)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(20)
        }
        .width('100%')
        .padding({ right: 20, top: 10 })

        // --- 模式切换 (Focus / Short Break / Long Break) ---
        Row() {
          this.ModeButton('Focus')
          this.ModeButton('Short Break')
          this.ModeButton('Long Break')
        }
        .backgroundColor(this.colorGrayLight)
        .borderRadius(24)
        .padding(4)
        .margin({ top: 30 })

        // --- 计时器圆环 ---
        Stack({ alignContent: Alignment.Center }) {
          // 外圈灰色进度条
          Circle({ width: 280, height: 280 })
            .fill(Color.Transparent)
            .stroke(this.colorGrayLight)
            .strokeWidth(20)

          // 内部文字
          Column() {
            Text('25:00')
              .fontSize(64)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colorPrimaryDark)
              .fontFamily('HarmonyOS Sans Condensed') // 紧凑字体模拟数字感

            Text('Focus Time')
              .fontSize(16)
              .fontColor(this.colorTextGray)
              .margin({ top: 8 })
          }
        }
        .margin({ top: 50, bottom: 40 })

        // --- 任务提示区域 (虚线框) ---
        Column() {
          Text('No task selected. Stay focused!')
            .fontColor('#A0A4AB')
            .fontSize(14)
        }
        .width('85%')
        .height(60)
        .borderRadius(30)
        .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed })
        .justifyContent(FlexAlign.Center) // Container 需要配合 Flex 布局属性
        .alignItems(HorizontalAlign.Center)

        // --- 播放控制按钮 ---
        Row({ space: 30 }) {
          // 重置按钮
          Button({ type: ButtonType.Circle }) {
            Text('↺').fontSize(24).fontColor('#555')
          }
          .width(60)
          .height(60)
          .backgroundColor(this.colorGrayLight)

          // 播放按钮 (大)
          Button({ type: ButtonType.Circle }) {
            Polygon({ width: 20, height: 20 })
              .points([[0, 0], [0, 20], [18, 10]])
              .fill(Color.White)
              .margin({ left: 4 }) // 视觉校正居中
          }
          .width(80)
          .height(80)
          .backgroundColor(this.colorPrimaryDark)
          .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        }
        .margin({ top: 50 })

      }
      .layoutWeight(1) // 占据中间剩余空间
      .width('100%')

      // 3. 底部导航栏
      Column() {
        Divider().color('#F0F0F0')
        Row() {
          this.BottomTabItem(0, 'Focus', '⏱️') // 使用 Emoji 模拟图标
          this.BottomTabItem(1, 'Tasks', '📝')
          this.BottomTabItem(2, 'Stats', '📊')
          this.BottomTabItem(3, 'Settings', '⚙️')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ top: 12, bottom: 20 })
        .backgroundColor(Color.White)
      }
    }
    .height('100%')
    .backgroundColor(this.colorBackground)
  }

  // --- 组件构造器：顶部模式切换按钮 ---
  @Builder
  ModeButton(text: string) {
    Button(text)
      .type(ButtonType.Capsule)
      .backgroundColor(this.currentMode === text ? Color.White : Color.Transparent)
      .fontColor(this.currentMode === text ? this.colorPrimaryDark : this.colorTextGray)
      .fontSize(14)
      .fontWeight(this.currentMode === text ? FontWeight.Medium : FontWeight.Normal)
      .height(36)
      .padding({ left: 20, right: 20 })
      .onClick(() => {
        this.currentMode = text;
      })
      .shadow(this.currentMode === text ? { radius: 8, color: '#10000000', offsetY: 2 } : undefined)
  }

  // --- 组件构造器：底部导航项 ---
  @Builder
  BottomTabItem(index: number, label: string, icon: string) {
    Column() {
      // 图标背景 (仅激活时显示浅红色圆圈)
      Stack() {
        if (this.activeTab === index) {
          Circle({ width: 30, height: 30 })
            .fill('#FFF0F0')
        }
        Text(icon).fontSize(20)
      }
      .width(40)
      .height(30)
      .alignContent(Alignment.Center)

      Text(label)
        .fontSize(10)
        .fontColor(this.activeTab === index ? this.colorAccentRed : '#C0C0C0')
        .margin({ top: 4 })
        .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .onClick(() => {
      this.activeTab = index;
    })
  }
}