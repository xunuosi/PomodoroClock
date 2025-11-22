// entry/src/main/ets/pages/Index.ets

import { SplashPage } from './SplashPage';
import { TimerView } from './TimerView';

@Entry
@ComponentV2
struct AppEntry {
  @Local pageStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.pageStack.pushPath({ name: 'Splash' });
  }

  @Builder
  PageMap(name: string) {
    if (name === 'Splash') {
      SplashPage()
    } else if (name === 'Home') {
      TimerView()
    }
  }

  build() {
    // 1. 给 Navigation 设置全屏扩展
    Navigation(this.pageStack) {
      // 空内容
    }
    .navDestination(this.PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .height('100%')
    .width('100%')
    // ✅【加固】明确声明 Navigation 容器本身占据全屏（包括状态栏区域）
    // 这样它内部的 NavDestination (Splash/TimerView) 才有资格去处理是否避让
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}