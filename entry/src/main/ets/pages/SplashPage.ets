import { promptAction, window } from '@kit.ArkUI';

@ComponentV2
export struct SplashPage {
  @Local opacityValue: number = 0;
  @Local scaleValue: number = 0.8;

  // --- 生命周期 ---
  aboutToAppear() {

    window.getLastWindow(this.getUIContext().getHostContext()).then((win) => {
      win.setWindowSystemBarEnable([]);
    })


    // 进场动画：延迟一小段时间确保渲染就绪
    setTimeout(() => {
      // ✅ 使用 animateTo 替代 withAnimation
      this.getUIContext().animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
        this.opacityValue = 1;
        this.scaleValue = 1;
      });
    }, 10);
    // 模拟加载耗时，2秒后跳转到主页
    setTimeout(() => {
      this.navigateToHome();
    }, 1000);
  }

  // --- 逻辑方法 ---
  private navigateToHome() {
    // [API 17 核心变更]
    // 不再使用 import router，而是获取上下文中的 Navigation 栈
    // queryNavigationInfo() 是组件内部获取自身所属 NavigationInfo 的标准 API
    const navInfo = this.queryNavigationInfo();

    if (navInfo) {
      const pathStack = navInfo.pathStack;
      // 使用 replacePath 销毁当前页（Splash），防止用户按返回键回到启动页
      pathStack.replacePath({ name: 'Home' });
    } else {
      // 异常处理：如果获取不到栈（极少情况），做个兜底提示
      this.getUIContext().getPromptAction().showToast({ message: 'Navigation stack not found' });
    }
  }

  // --- UI 构建 ---
  build() {
    // [强制] 所有路由子页面必须由 NavDestination 包裹
    NavDestination() {
      Column() {
        // 使用 Blank 占据上方空间，实现弹性布局
        Blank()

        // --- 中间核心内容 ---
        Column({ space: 10 }) {
          // Logo 图片
          Image($r('app.media.tomatodo_logo'))
            .width(120)
            .height(120)
            .objectFit(ImageFit.Contain)
            .opacity(this.opacityValue) // 绑定透明度
            .scale({ x: this.scaleValue, y: this.scaleValue }) // 绑定缩放
            .margin({ bottom: 10 })

          // 主标题
          Text($r('app.string.app_name'))
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B333E')

          // 副标题
          Text($r('app.string.app_slogan'))
            .fontSize(16)
            .fontColor('#989A9C')
            .letterSpacing(0.5)
        }

        Blank() // 将 Loading 组件推到底部

        // --- 底部加载圈 ---
        LoadingProgress()
          .color('#F08080')
          .width(40)
          .height(40)
          .margin({ bottom: 60 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      // [沉浸式] 确保背景铺满，内容避让非安全区
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true) // 隐藏默认导航栏
  }
}