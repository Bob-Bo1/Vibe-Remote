Remote Mic · RC003 Windows 便携版
================================

这是免安装便携版。把 ZIP 解压到短路径后，双击 RemoteMicRC003.exe 打开设置窗口；
也可以运行 .\RemoteMicRC003.exe --settings。
程序和配置会分开保存：配置、按键绑定和日志位于
%LOCALAPPDATA%\RemoteMic\RC003。

首次配置
--------
1. 在 Windows 设置中完成 RC003 蓝牙配对：同时长按遥控器的主页键和菜单键，
   看到设备进入配对状态后，在 Windows 蓝牙页面完成配对。
2. 打开 RemoteMicRC003.exe，进入“连接与配置”页，按页面顺序点击“连接”。
3. 连接时程序会自动准备完整按键能力。若 Windows 弹出固定目录的安全授权提示，
   请先核对提示内容，再决定是否确认。取消授权时，普通方向键和 OK 键仍可继续使用。
4. 页面会先检查 CABLE Input 和 CABLE Output。缺少 VB-CABLE 时，点击“安装
   VB-CABLE”，按说明确认并完成官方安装，重启 Windows 后点击“重新检测”。也可以
   从 VB-Audio 官方页面手动下载安装：https://vb-audio.com/Cable/。
5. 新安装默认使用微信电脑端：按住 Ctrl+Win 说话，松开结束。切换到豆包时，
   选择豆包预设；需要切换模式时使用 ralt+space，需要按住模式时使用 ralt。
   Windows 系统听写使用 Win+H。语音软件的麦克风输入选择 CABLE Output，Remote
   Mic 的“语音输出设备”选择 CABLE Input。
6. 选择语音软件后，按页面提示测试普通按键和语音。右上角显示“已连接”才表示
   遥控器的 BLE 会话已经建立；“等待遥控器”只表示桥接服务正在运行。
需要单独启动桥接时，在同一文件夹运行 `.\RemoteMicRC003.exe --bridge` 启动桥接。

Windows 听写检查
----------------
如果要单独排查 Windows 听写，先在记事本打开一个可编辑文本框，手动按 Win+H，
确认听写栏出现并能输入文字。Windows 11 的设置路径是“设置 → 隐私和安全性 → 语音”，
  Windows 10 的设置路径是“设置 → 隐私 → 语音”；请确认联机语音识别已开启。使用 VB-CABLE 时，听写软件的
麦克风输入选择 CABLE Output。这个检查只用于确认 Windows 听写链路，不能代替
RC003 语音快捷键测试。

按键映射
--------
进入“按键映射”页后，可点击遥控器实物图或左右卡片定位对应按键。每个按键分别
设置单击、双击和长按动作；长动作列表可以用滚轮继续查看。修改后点击底部保存。
RC003 有 13 个物理按键，包含一个固定的麦克风键；遥控器没有独立的物理静音键，
返回键默认映射为退格动作。

退出与移除
----------
停止时打开任务管理器（Ctrl+Shift+Esc），找到 RemoteMicRC003.exe 并选择“结束任务”。
移除程序时关闭程序后删除整个解压文件夹。配置和日志仍保留在
%LOCALAPPDATA%\RemoteMic\RC003，其中包括 config.json、key_bindings.json 和 logs\app.log；
如果以后完全不用 RC003，可以再手动删除这个目录。
如果还会用到同一台电脑上的其他 RC003 配置，请不要删除这个共享目录。

安全与校验
----------
这是未签名便携程序，Windows SmartScreen 可能提示风险。运行前建议使用以下命令
核对 ZIP 的 SHA-256，并与同一次 Release 中的 SHA256SUMS.txt 比较：

    Get-FileHash -Algorithm SHA256 .\RemoteMicRC003-<版本号>-portable-unsigned.zip

CI 和软件自检不能替代每台电脑上的蓝牙、实体按键、音频和语音复测。
