// src/main/ets/pages/SplashPage.ets
import router from '@ohos.router';

@Entry
@Component
struct SplashPage {
  // 页面显示后，延迟跳转到主页
  aboutToAppear() {
    setTimeout(() => {
      // 跳转到主页 (Index)
      router.replaceUrl({ url: 'pages/Index' });
    }, 12000); // 2秒后跳转
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // -------------------------------------------
      // 1. 背景层：红色到白色的线性渐变
      // -------------------------------------------
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180, // 从上到下
          colors: [
            ['#FF4E50', 0.0], // 顶部：番茄红
            ['#FF4E50', 0.4], // 中间保持一段红色
            ['#FFFFFF', 1.0]  // 底部：白色
          ]
        })

      // -------------------------------------------
      // 2. 内容层
      // -------------------------------------------
      Column() {
        // A. LOGO 部分 (根据图片，位于中上方)
        Image($r('app.media.pomodoro')) // 请确保你有这个图标
          .width(120)
          .height(120)
          .objectFit(ImageFit.Contain)
          .margin({ top: '25%' }) // 距离顶部位置

        // B. Slogan 文字
        Text('专注每一刻，前行每一天') // 假设这是设计图上的文字
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .letterSpacing(2) // 字间距
          .margin({ top: 20 })
          .opacity(0.9)

        // C. 撑开空间，让底部图形沉底
        Blank()

        // D. 底部图形 (模拟设计图底部的半圆/图表)
        // 这里用一个简单的圆形示意，实际开发可用 Image 替换
        Stack({ alignContent: Alignment.Center }) {
          // 红色半圆部分示意
          Circle({ width: 200, height: 200 })
            .fill('#D93025') // 深一点的红色
            .opacity(0.8)

          Text('25日') // 模拟图中的文字
            .fontColor(Color.White)
            .fontSize(16)
        }
        .margin({ bottom: 50 }) // 距离底部距离

      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}