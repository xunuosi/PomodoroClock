import router from '@ohos.router';

@Preview
@Entry
@Component
struct SplashPage {
  // 页面加载时执行
  aboutToAppear() {
    // 模拟加载耗时，2秒后跳转到主页
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/Index' }); // 替换为你实际的主页路径
    }, 2000);
  }

  build() {
    Column() {
      // 使用 Blank 组件来占据空间，实现上下布局的弹性分配
      // 这里放一个 Blank，把中间的内容往下顶一点，或者让上下平分
      Blank()

      // --- 中间核心内容 (Logo + 文字) ---
      Column({ space: 10 }) {
        // Logo 图片
        Image($r('app.media.tomatodo_logo'))
          .width(120)
          .height(120)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 10 })

        // 主标题 Tomatodo
        Text('Tomatodo')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B333E') // 深色字体

        // 副标题 Master your time
        Text('Master your time')
          .fontSize(16)
          .fontColor('#989A9C') // 灰色字体
          .letterSpacing(0.5) // 稍微增加一点字间距
      }

      Blank() // 下方的 Blank，将 Loading 组件推到底部

      // --- 底部加载圈 ---
      LoadingProgress()
        .color('#F08080') // 设置加载圈颜色与 Logo 一致
        .width(40)
        .height(40)
        .margin({ bottom: 60 }) // 距离底部留出一些空间
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF') // 背景纯白
  }
}