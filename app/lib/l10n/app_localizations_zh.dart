// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'SkyPort';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '还原';

  @override
  String get windowClose => '关闭窗口';

  @override
  String get serialPageLabel => '串口';

  @override
  String get settingsPageLabel => '设置';

  @override
  String get expandConfiguration => '展开配置面板';

  @override
  String get collapseConfiguration => '收起配置面板';

  @override
  String get noPortSelected => '未选择端口';

  @override
  String get serialPortSettings => '串口设置';

  @override
  String get portName => '端口';

  @override
  String get noPortsFound => '未发现端口';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开';

  @override
  String get close => '关闭';

  @override
  String get baudRate => '波特率';

  @override
  String get flowControl => '流控制';

  @override
  String get flowControlNone => '无';

  @override
  String get flowControlHardware => 'RTS/CTS';

  @override
  String get flowControlSoftware => 'XON/XOFF';

  @override
  String get flowControlSoftwareWarning =>
      '启用 XON/XOFF 时，接收到 0x13 会暂停本机发送，接收到 0x11 会恢复本机发送。这些控制字节不适用于透明二进制传输。';

  @override
  String get dataBits => '数据位';

  @override
  String get parity => '校验位';

  @override
  String get parityNone => '无';

  @override
  String get parityOdd => '奇';

  @override
  String get parityEven => '偶';

  @override
  String get stopBits => '停止位';

  @override
  String get receiveSettings => '接收设置';

  @override
  String get hexDisplay => '十六进制显示';

  @override
  String get showTimestamp => '显示时间戳';

  @override
  String get showSent => '显示发送数据';

  @override
  String get clearReceiveArea => '清空接收区';

  @override
  String get sendSettings => '发送设置';

  @override
  String get hexSend => '十六进制发送';

  @override
  String get appendNewline => '添加换行符';

  @override
  String get newlineMode => '换行符';

  @override
  String get enterDataToSend => '输入要发送的数据';

  @override
  String get invalidHexChars => '字符不合法，仅允许 0-9 与 A-F';

  @override
  String get hexEvenLength => 'Hex 字符串长度必须为偶数';

  @override
  String get send => '发送';

  @override
  String get rxLabel => '接收';

  @override
  String get connected => '已连接';

  @override
  String get connecting => '连接中...';

  @override
  String get disconnecting => '断开中...';

  @override
  String get reconnecting => '等待设备重连...';

  @override
  String get disconnectedReconnecting => '串口已断开，正在自动重连';

  @override
  String get disconnected => '未连接';

  @override
  String get autoReconnect => '智能重连';

  @override
  String get unavailable => '不可用';

  @override
  String trafficStats(int rx, int tx, int lastRx) {
    return '接收: $rx 字节 - $lastRx 字节 | 发送: $tx 字节';
  }

  @override
  String get trafficStatsTooltip => '累计接收字节数 - 最近一包大小 · 累计发送字节数 · 接收速率';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsConnection => '连接';

  @override
  String get settingsLogs => '日志';

  @override
  String get logBufferSizeHint => '16–512 MB · 按 Enter 应用';

  @override
  String get theme => '主题';

  @override
  String get themeColor => '主题颜色';

  @override
  String get dynamicColor => '使用系统强调色';

  @override
  String get themeColorSaveFailed => '无法保存主题设置';

  @override
  String get colorScheme => '配色方案';

  @override
  String get themeBlue => '默认蓝';

  @override
  String get themeRed => '红';

  @override
  String get themeGreen => '绿';

  @override
  String get themeTeal => '青';

  @override
  String get themeIndigo => '靛蓝';

  @override
  String get themeViolet => '紫罗兰';

  @override
  String get themePink => '粉';

  @override
  String get themeYellow => '黄';

  @override
  String get themeOrange => '橙';

  @override
  String get customSeedColor => '自定义种子色';

  @override
  String get seedColorHex => '种子色 (#RRGGBB)';

  @override
  String get seedColorHexError => '请输入 #RRGGBB（六位十六进制数，不含透明度）。';

  @override
  String get colorChannelRed => '红色通道';

  @override
  String get colorChannelGreen => '绿色通道';

  @override
  String get colorChannelBlue => '蓝色通道';

  @override
  String get applyColor => '应用';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get logBufferSize => '日志缓冲区大小';

  @override
  String get logBufferSizeError => '16-512之间的整数';

  @override
  String get enableAnsi => '启用 ANSI';

  @override
  String get autoSend => '自动发送';

  @override
  String get secondsUnit => '秒';

  @override
  String get exportLogs => '导出日志';

  @override
  String get exportPath => '导出路径';

  @override
  String get exportPathHint => '日志导出的默认文件夹';

  @override
  String get logsExportedTo => '日志已导出到：';

  @override
  String exportFailed(String message) {
    return '导出失败：$message';
  }

  @override
  String writeFailure(int bytes, String message) {
    return '写入失败，已发送 $bytes 字节：$message';
  }

  @override
  String autoSendPaused(String message) {
    return '自动发送已暂停：$message';
  }

  @override
  String get applyingConfiguration => '正在应用配置...';

  @override
  String get logDataGap => '部分日志事件丢失；视图已重新同步。';

  @override
  String logTrimmed(int records, int bytes) {
    return '已清除较早记录：$records 条记录 / $bytes 字节';
  }

  @override
  String get startupFailed => 'SkyPort 无法启动';

  @override
  String get errorInvalidArgument => '参数无效';

  @override
  String get errorPortNotFound => '未找到串口';

  @override
  String get errorOpenFailed => '串口打开失败';

  @override
  String get errorPermissionDenied => '权限不足';

  @override
  String get errorUnsupportedConfiguration => '不支持此配置';

  @override
  String get errorReadFailed => '串口读取失败';

  @override
  String get errorDisconnected => '串口连接丢失';

  @override
  String get errorTimeout => '操作超时';

  @override
  String get errorClosed => '应用核心已关闭';

  @override
  String get errorQueueOverflow => '队列容量已满';

  @override
  String get errorTaskFailed => '后台任务失败';

  @override
  String get errorInternal => '内部错误';

  @override
  String get logIncomplete => '当前保留的日志存在串口数据或会话缺口。';

  @override
  String get diagnosticDetails => '诊断详情';

  @override
  String get errorWriteFailed => '串口写入失败';

  @override
  String get errorPortNameRequired => '请选择串口。';

  @override
  String get errorPortNameTooLong => '串口名称不能超过 4096 字节。';

  @override
  String get errorPortNameInvalid => '串口名称不能包含空字符或换行符。';

  @override
  String get errorBaudRateInvalid => '波特率必须大于零。';

  @override
  String get errorDataBitsInvalid => '数据位必须在 5 到 8 之间。';

  @override
  String get errorStopBitsInvalid => '停止位必须为 1 或 2。';

  @override
  String get errorLegacyConfigInvalid => '旧版应用的串口设置无效。';

  @override
  String get errorConfigVersionUnsupported => '不支持此配置文件版本。';

  @override
  String get errorNewlineInvalid => '保存的换行符必须为 LF、CR 或 CRLF。';

  @override
  String get errorAutoSendIntervalInvalid => '自动发送间隔必须在 0.01 到 60 秒之间。';

  @override
  String get errorLogCapacityInvalid => '日志缓冲区大小必须在 16 到 512 MiB 之间。';

  @override
  String get errorHistoryTooLong => '发送历史不能超过 100 条。';

  @override
  String get errorHistoryEntryEmpty => '发送历史不能包含空记录。';

  @override
  String get errorHistoryTooLarge => '发送历史不能超过 1 MiB。';

  @override
  String get errorConfigTooLarge => '配置文件不能超过 8 MiB。';

  @override
  String get errorConfigInvalid => '配置文件无效。';

  @override
  String get errorConfigIo => '无法读取或保存配置文件。';

  @override
  String get errorSendTooLarge => '单次发送的数据不能超过 1 MiB。';

  @override
  String get errorSendInputTooLarge => '发送输入不能超过 2 MiB。';

  @override
  String get errorAutoSendTooLarge => '自动发送的数据不能超过 1 MiB。';

  @override
  String get errorSendEmpty => '请输入要发送的数据。';

  @override
  String get errorNoLogsToExport => '没有符合导出选项的日志记录。';

  @override
  String get errorExportLog => '无法写入日志文件。';

  @override
  String get errorQueueCapacityInvalid => '队列容量必须在 1 到 4096 之间。';

  @override
  String get errorBridgeInitialization => '无法加载串口核心组件，请检查应用安装文件是否完整。';

  @override
  String get errorPreferenceMigration => '无法保存旧设置的迁移状态。';

  @override
  String get errorPreferencesUnavailable => '无法读取应用设置。';

  @override
  String get errorFileAccess => '无法访问所需的文件或文件夹。';

  @override
  String get errorPluginUnavailable => '所需的平台服务不可用。';

  @override
  String get errorPlatform => '系统服务调用失败。';

  @override
  String get errorPlatformUnsupported => '不支持此平台。';

  @override
  String get errorUnexpected => '发生意外错误，请查看诊断详情。';

  @override
  String get scrollToBottom => '滚动到最新';

  @override
  String get cancel => '取消';

  @override
  String get language => '语言';

  @override
  String get toolsPageLabel => '工具';

  @override
  String get toolChecksum => '校验计算';

  @override
  String get toolInputFormat => '输入格式';

  @override
  String get toolInputTextUtf8 => '文本 (UTF-8)';

  @override
  String toolByteCount(int count) {
    return '$count 字节';
  }

  @override
  String get toolChecksumNote => '结果按大端显示，不会自动附加到发送数据。';

  @override
  String get toolHexText => 'Hex 与文本互转';

  @override
  String get toolTextToHex => '文本 → Hex';

  @override
  String get toolHexToText => 'Hex → 文本';

  @override
  String get toolNumberBase => '进制转换';

  @override
  String get toolInvalidNumber => '不是该进制下的有效数字';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制到剪贴板';

  @override
  String get quickCommandsPageLabel => '指令';

  @override
  String get quickCommandAdd => '添加指令';

  @override
  String get quickCommandEdit => '编辑指令';

  @override
  String get quickCommandName => '名称';

  @override
  String get quickCommandNameHint => '留空则使用内容';

  @override
  String get quickCommandPayload => '内容';

  @override
  String get quickCommandPayloadRequired => '请输入要发送的内容';

  @override
  String get quickCommandsEmpty => '还没有保存的指令。添加常用指令后可一键发送。';

  @override
  String get quickCommandNotConnected => '连接串口后才能发送';

  @override
  String get quickCommandListFull => '指令列表已满。';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get receiveTab => '接收';

  @override
  String get chartTab => '曲线';

  @override
  String get chartEmpty =>
      '接收到的数值行会绘制在这里，例如 \"12.5,30\" 或 \"temp:23.5 hum:41\"。每一列是一条曲线。';

  @override
  String get chartPausedEmpty => '绘图已暂停。';

  @override
  String get chartPause => '暂停绘图';

  @override
  String get chartResume => '继续绘图';

  @override
  String get chartClear => '清空曲线';

  @override
  String chartSkipped(int count) {
    return '$count 行非数值';
  }

  @override
  String get chartSkippedHint => '不是纯数值的行会被跳过，不绘制。';

  @override
  String get errorModemLineUnavailable => '已启用硬件流控，RTS 由流控自动控制。';

  @override
  String get errorSendScheduleConflict => '自动发送和指令循环发送不能同时运行。';

  @override
  String get errorSequenceTooLong => '循环发送的指令过多。';

  @override
  String get modemLines => '控制线';

  @override
  String get modemLinesHint => '作用于已打开的串口。串口打开或关闭时两条线都会复位为无效。';

  @override
  String get modemLinesHardwareFlow => '已启用硬件流控，RTS 由流控控制';

  @override
  String get sequenceLoop => '循环发送';

  @override
  String get sequenceLoopHint => '按顺序循环发送所有指令，每个间隔发送一条。写入失败时停止。';

  @override
  String sequenceRunning(int current, int total) {
    return '正在发送 $current/$total';
  }

  @override
  String sequenceStopped(String message) {
    return '循环已停止：$message';
  }

  @override
  String get sequenceStart => '开始循环';

  @override
  String get sequenceStop => '停止循环';
}
