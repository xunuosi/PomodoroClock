// entry/src/main/ets/pages/Index.ets

import { SplashPage } from './SplashPage';
import { TimerView } from './TimerView';
import { SettingsView } from './SettingsView';
import { TimerStore } from '../model/TimerModel';
import { common } from '@kit.AbilityKit';

@Entry
@ComponentV2
struct AppEntry {
  @Local pageStack: NavPathStack = new NavPathStack();
  @Local store: TimerStore = new TimerStore();

  aboutToAppear(): void {
    this.pageStack.pushPath({ name: 'Splash' });
    // 获取 Context 并初始化 Store 数据
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.store.initData(context);
  }

  @Builder
  PageMap(name: string, param?: Object) {
    if (name === 'Splash') {
      SplashPage()
    } else if (name === 'Home') {
      TimerView({ store: this.store })
    } else if (name === 'Settings') {
      // ✅ 注册 Settings 路由，并将传入的 store (param) 传给页面
      SettingsView({ store: param as TimerStore })
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}