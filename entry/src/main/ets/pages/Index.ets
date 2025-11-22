// 引入拆分后的独立组件
import { SplashPage } from './SplashPage';
import { TimerView } from './TimerView';

@Entry
@ComponentV2
struct AppEntry {
  @Local pageStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 初始路由推入 Splash
    this.pageStack.pushPath({ name: 'Splash' });
  }

  @Builder
  PageMap(name: string) {
    if (name === 'Splash') {
      SplashPage() // 这里直接使用引入的组件
    } else if (name === 'Home') {
      TimerView()
    }
  }

  build() {
    Navigation(this.pageStack) {
      // 根容器留空
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}