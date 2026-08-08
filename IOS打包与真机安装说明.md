# 《纵横四海：潮汐纪事》iOS 打包说明

## 当前交付状态

- Godot 4.7.1 iOS 工程已于 2026-08-09 重新生成。
- Xcode 26.6 的 iPhone ARM64 Debug 真机编译已通过。
- 本机构建已使用 Apple Development 身份完成开发签名。公开仓库不包含个人团队编号和描述文件。
- 最新签名应用：`build/ios/DerivedData-final/Build/Products/Debug-iphoneos/SiHai.app`。
- 最新开发 IPA：`build/ios/SiHai-development-signed.ipa`。
- 应用版本：`1.0.0 (1)`。
- 最低系统：`iOS 15.0`。
- 目标设备：`iPhone`。
- 屏幕方向：竖屏。
- 默认 Bundle ID：`com.jianghu.zonghengsihai`。

当前 Mac 能看到 `JH iPhone14 Pro`，但设备状态为 `unavailable`，因此本轮无法完成最后的自动安装与启动。解锁手机、保持数据线连接、确认“信任此电脑”和开发者模式后，即可安装上述已签名应用。

## 在 iPhone 上运行

1. 用 Xcode 打开 `build/ios/SiHai.xcodeproj`。
2. 在左侧选中蓝色的 `SiHai` 工程，再选中 `TARGETS > SiHai`。
3. 打开 `Signing & Capabilities`，保持 `Automatically manage signing` 开启。
4. 在 `Team` 中选择你自己的 Apple Developer 团队。
5. 如果 Bundle ID 已被占用，将 `com.jianghu.zonghengsihai` 改为你自己的唯一标识，例如 `com.你的名称.zonghengsihai`。
6. 用数据线连接 iPhone，在 Xcode 顶部设备菜单选中该 iPhone，然后点击运行。

免费 Apple ID 通常可用于个人真机测试；上传 App Store/TestFlight 需要 Apple Developer Program 会员资格。

## 导出 TestFlight 或 App Store 包

1. 完成上面的 Team 与 Bundle ID 设置。
2. 将 Xcode 顶部运行目标设为 `Any iOS Device (arm64)`。
3. 选择 `Product > Archive`。
4. 在 Organizer 中选择 `Distribute App`，再选择 App Store Connect 或 Ad Hoc。

## 模拟器说明

Godot 4.7.1 当前这份官方 iOS Release 模板中，模拟器静态库实际为 x86_64；已通过 x86_64 模拟器编译。如果 Apple Silicon Mac 在模拟器上默认使用 arm64 而链接失败，请优先用 iPhone 真机运行；真机 ARM64 Release 已验证通过。

## 重新从 Godot 生成工程

项目已包含 `export_presets.cfg`。首次打包时，请在 Godot 导出设置中填入自己的 Apple Developer Team ID，然后选择 `iOS`，或在项目目录执行：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer godot --headless --path . --export-release iOS build/ios/SiHai.zip
```
