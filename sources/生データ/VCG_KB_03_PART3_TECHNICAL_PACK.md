# VCG / VIBE Knowledge Base — 5-file Pack (Part 3)

Generated: 2026-01-08 22:40:21 UTC+09:00

含む: 06_PROMPTS_AND_RULES / 07_CODE_FULL_WPF / 08_PATCHES / 09_SCRIPTS_FULL / 10_ULTRASYNC / 11_ATTACHMENTS_INVENTORY / 12_HASHES_AND_MANIFEST

※ 生ソース（PDFやZIP内の追加資料）は Part 4 に入っています。


---

## 06_PROMPTS_AND_RULES.md (verbatim)

# PROMPTS_AND_RULES（ワンショット設計/カード運用）
## Claude Code One Shot Prompt（設計・分割用）
# 23 Claude Code（Cursor/Claude Code）用 ワンショット指示文（質問あり・一回で完了）

> **このまま全文を Claude Code に貼って実行**してください。  
> ワンショットで「診断→修正→ビルド→起動テスト→レポート作成」まで終わらせます。

---

あなたは「WPF（.NET）シニア開発者 + ビルド/リリースエンジニア」です。  
目的は **VIBE One Screen OS を“今すぐ使える状態”に戻す**こと。

## 作業ルート（絶対）
ユーザー環境の OneBoxRoot:
`C:\Users\koji2\Desktop\VCG\01_作業（加工中）`

以降すべてこの中だけで完結させる。

## まず最初に質問（最大5つ、回答が無くても進める）
1) 直近で `APP\OneScreenOSApp\MainWindow.xaml` を置き換え/編集しましたか？（特に x:Class や x:Name）
2) Visual Studio で開いていますか？それとも CLI のみですか？
3) `APP\OneScreenOSApp` 配下に `MainWindow.xaml` が複数存在していませんか？
4) `dotnet --info` の結果で .NET 8/WindowsDesktop が入っていますか？
5) 既に `UI_FIX_REPORT__20260106_155136.md` がある状態を尊重してよいですか？（基本YESで進める）

※回答待ちで止まらない。未回答なら「現在のファイル群が正」と仮定して進める。

## 成果物（必須）
- ビルド成功（Release publish）
- 起動テスト成功（クラッシュ無しで5秒以上）
- 変更ファイルのバックアップ
- `VAULT\06_LOGS\UI_FIX_REPORT__YYYYMMDD_HHMMSS.md` を新規作成（今回の修正内容を全文）

## 守るルール
- 変更前に必ずバックアップを作る  
  例: `_TRASH\UI_FIX__YYYYMMDD_HHMMSS\...`
- 既存の命名/フォルダ規約は破壊しない
- “たまたま通る”ではなく、根因を説明できる状態にする

---

# タスク（P0→P2を一回で）

## P0-1: 失敗を再現して「最初の原因」を特定
1) OneBoxRoot に移動し、現状のビルドを再現:
```powershell
cd "C:\Users\koji2\Desktop\VCG\01_作業（加工中）"
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\CORE\VIBE_CTRL\scripts\build_publish.ps1"
```
2) 生成された最新ログ `VAULT\06_LOGS\build_publish_*.log` を開き、**一番最初に出るエラー**を特定  
   （C#の148エラーより前に、XAMLコンパイルが落ちていることが多い）

## P0-2: `InitializeComponent` が消える根因を潰す（最優先）
次を上から監査し、必要なら修正して再ビルド:
- `MainWindow.xaml` の `x:Class` と `MainWindow.xaml.cs` の `namespace/class` 一致
- `MainWindow.xaml` の Build Action が `Page`
- `OneScreenOSApp.csproj` に `<UseWPF>true</UseWPF>` がある（あるはず）
- `bin/obj` を完全削除して再ビルド
```powershell
cd ".\APP\OneScreenOSApp"
Remove-Item -Recurse -Force .\bin,.\obj -ErrorAction SilentlyContinue
dotnet build .\OneScreenOSApp.csproj -c Release -v:n
```
- XAML構文エラーがあれば最初の1件から直す（直したら再ビルド）

## P0-3: TargetType不一致クラッシュを恒久修正（既知）
1) `APP\OneScreenOSApp\App.xaml` に `ToggleSecondary`（TargetType=ToggleButton）を追加  
2) `APP\OneScreenOSApp\MainWindow.xaml` の `ToggleInsightDetails` を `Style="{StaticResource ToggleSecondary}"` に変更  
3) Checked時の視覚フィードバックも入れる（Background/Foreground 等）

※既に入っていてもOK。重複だけ避ける。

## P1: 警告の整理（可能なら同時に）
- csproj に `<Reference Include="System.Windows.Forms"/>` がある場合、`UseWindowsForms=true` に一本化できるか検証  
  （FolderBrowserDialog を使っているため WindowsForms 自体は必要）

## P2: 簡易UIテスト
- 起動後、Dashboard → DataOps → Secrets → Providers → Settings を最低1回ずつ表示
- ToggleInsightDetails の expand/collapse を確認

---

# 実行後に必ず出力するレポート（Markdown）
`VAULT\06_LOGS\UI_FIX_REPORT__YYYYMMDD_HHMMSS.md` に以下を含める:
- Root Cause（最初の原因）
- 修正内容（ファイル/行/差分要約）
- ビルド結果（成功ログ、dist生成）
- 起動テスト結果（手順）
- 次の改善提案（P1/P2）

---

以上。必ずワンショットで完了させてください。

---

## カード運用テンプレ（大規模向け）
- 1カード=1パッチ（最大3ファイル）
- Acceptanceは機械判定（コマンド + 出力 + ログパス）
- DoneはVAULTに証拠が残ること

### Card Template
```md
# Card: <name>
## Goal
## Non-goals
## Acceptance (machine-check)
- [ ] command: <...> exit 0
- [ ] evidence: VAULT/<...>
## Constraints
- touch files: <list>
- do not touch: <list>
## Plan
- steps:
- risks:
```


---


---

## 07_CODE_FULL_WPF.md (verbatim)

# CODE_FULL（WPFアプリ全文：参照用）
> このファイルは “Knowledgeのファイル数節約” のため、主要コードを1つに統合しています。
> 実装時は各ファイルに反映してください。

---

## App.xaml
# 10 App.xaml（全文）

```xml
<Application x:Class="OneScreenOSApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
        <ResourceDictionary>
            <!-- ========== Notion-Style Light Theme ========== -->

            <!-- Primary Colors -->
            <SolidColorBrush x:Key="BackgroundPrimary" Color="#FAFAFA"/>
            <SolidColorBrush x:Key="BackgroundSecondary" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="BackgroundSidebar" Color="#F7F6F3"/>
            <SolidColorBrush x:Key="BorderSubtle" Color="#E8E8E8"/>
            <SolidColorBrush x:Key="BorderMedium" Color="#D4D4D4"/>

            <!-- Text Colors -->
            <SolidColorBrush x:Key="TextPrimary" Color="#37352F"/>
            <SolidColorBrush x:Key="TextSecondary" Color="#6B6B6B"/>
            <SolidColorBrush x:Key="TextMuted" Color="#9B9B9B"/>
            <SolidColorBrush x:Key="TextInverse" Color="#FFFFFF"/>

            <!-- Accent Colors -->
            <SolidColorBrush x:Key="AccentBlue" Color="#2383E2"/>
            <SolidColorBrush x:Key="AccentGreen" Color="#0F7B6C"/>
            <SolidColorBrush x:Key="AccentRed" Color="#E03E3E"/>
            <SolidColorBrush x:Key="AccentOrange" Color="#D9730D"/>
            <SolidColorBrush x:Key="AccentYellow" Color="#DFAB01"/>

            <!-- Status Colors -->
            <SolidColorBrush x:Key="StatusSuccess" Color="#0F7B6C"/>
            <SolidColorBrush x:Key="StatusError" Color="#E03E3E"/>
            <SolidColorBrush x:Key="StatusWarning" Color="#D9730D"/>
            <SolidColorBrush x:Key="StatusInfo" Color="#2383E2"/>

            <!-- Card Backgrounds -->
            <SolidColorBrush x:Key="CardBackground" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="CardBackgroundHover" Color="#F7F6F3"/>
            <SolidColorBrush x:Key="BgTertiary" Color="#F5F5F5"/>

            <!-- Corner Radius -->
            <CornerRadius x:Key="RadiusSmall">4</CornerRadius>
            <CornerRadius x:Key="RadiusMedium">8</CornerRadius>
            <CornerRadius x:Key="RadiusLarge">12</CornerRadius>

            <!-- Standard Margins/Padding -->
            <Thickness x:Key="SpaceSmall">8</Thickness>
            <Thickness x:Key="SpaceMedium">16</Thickness>
            <Thickness x:Key="SpaceLarge">24</Thickness>

            <!-- ========== Typography ========== -->
            <FontFamily x:Key="FontPrimary">Yu Gothic UI, Segoe UI, Meiryo, sans-serif</FontFamily>
            <FontFamily x:Key="FontMono">Consolas, MS Gothic, monospace</FontFamily>

            <!-- ========== Button Styles ========== -->

            <!-- Primary Button (Blue) -->
            <Style x:Key="ButtonPrimary" TargetType="Button">
                <Setter Property="Background" Value="{StaticResource AccentBlue}"/>
                <Setter Property="Foreground" Value="{StaticResource TextInverse}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="FontWeight" Value="Medium"/>
                <Setter Property="Padding" Value="16,10"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}" 
                                    CornerRadius="{StaticResource RadiusSmall}"
                                    Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="#1A73D8"/>
                                </Trigger>
                                <Trigger Property="IsEnabled" Value="False">
                                    <Setter TargetName="border" Property="Background" Value="#D4D4D4"/>
                                    <Setter Property="Foreground" Value="#9B9B9B"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Success Button (Green) -->
            <Style x:Key="ButtonSuccess" TargetType="Button">
                <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
                <Setter Property="Foreground" Value="{StaticResource TextInverse}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="FontWeight" Value="Medium"/>
                <Setter Property="Padding" Value="16,10"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}" 
                                    CornerRadius="{StaticResource RadiusSmall}"
                                    Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="#0D6B5E"/>
                                </Trigger>
                                <Trigger Property="IsEnabled" Value="False">
                                    <Setter TargetName="border" Property="Background" Value="#D4D4D4"/>
                                    <Setter Property="Foreground" Value="#9B9B9B"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Danger Button (Red) -->
            <Style x:Key="ButtonDanger" TargetType="Button">
                <Setter Property="Background" Value="{StaticResource AccentRed}"/>
                <Setter Property="Foreground" Value="{StaticResource TextInverse}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="FontWeight" Value="Medium"/>
                <Setter Property="Padding" Value="16,10"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}" 
                                    CornerRadius="{StaticResource RadiusSmall}"
                                    Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="#C93030"/>
                                </Trigger>
                                <Trigger Property="IsEnabled" Value="False">
                                    <Setter TargetName="border" Property="Background" Value="#D4D4D4"/>
                                    <Setter Property="Foreground" Value="#9B9B9B"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Secondary Button (Outlined) -->
            <Style x:Key="ButtonSecondary" TargetType="Button">
                <Setter Property="Background" Value="Transparent"/>
                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                <Setter Property="BorderBrush" Value="{StaticResource BorderMedium}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="Padding" Value="16,10"/>
                <Setter Property="BorderThickness" Value="1"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}" 
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}"
                                    CornerRadius="{StaticResource RadiusSmall}"
                                    Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="{StaticResource CardBackgroundHover}"/>
                                </Trigger>
                                <Trigger Property="IsEnabled" Value="False">
                                    <Setter Property="Foreground" Value="#9B9B9B"/>
                                    <Setter TargetName="border" Property="BorderBrush" Value="#E8E8E8"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Nav Button (Sidebar) -->
            <Style x:Key="ButtonNav" TargetType="Button">
                <Setter Property="Background" Value="Transparent"/>
                <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="Padding" Value="12,10"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="HorizontalContentAlignment" Value="Left"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}" 
                                    CornerRadius="{StaticResource RadiusSmall}"
                                    Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="#EEEEEE"/>
                                    <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- Large Action Button (Next) -->
            <Style x:Key="ButtonLargeAction" TargetType="Button">
                <Setter Property="Background" Value="{StaticResource AccentGreen}"/>
                <Setter Property="Foreground" Value="{StaticResource TextInverse}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="18"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="Padding" Value="24,20"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}" 
                                    CornerRadius="{StaticResource RadiusMedium}"
                                    Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="#0D6B5E"/>
                                </Trigger>
                                <Trigger Property="IsEnabled" Value="False">
                                    <Setter TargetName="border" Property="Background" Value="#D4D4D4"/>
                                    <Setter Property="Foreground" Value="#9B9B9B"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

            <!-- ========== Card Style ========== -->
            <Style x:Key="Card" TargetType="Border">
                <Setter Property="Background" Value="{StaticResource CardBackground}"/>
                <Setter Property="BorderBrush" Value="{StaticResource BorderSubtle}"/>
                <Setter Property="BorderThickness" Value="1"/>
                <Setter Property="CornerRadius" Value="{StaticResource RadiusMedium}"/>
                <Setter Property="Padding" Value="20"/>
            </Style>

            <!-- ========== Expander Style ========== -->
            <Style x:Key="ExpanderSubtle" TargetType="Expander">
                <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
                <Setter Property="FontFamily" Value="{StaticResource FontPrimary}"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Background" Value="Transparent"/>
            </Style>

        </ResourceDictionary>
    </Application.Resources>
</Application>
```

---

## App.xaml.cs
# 12 App.xaml.cs（全文）

```csharp
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows;

namespace OneScreenOSApp
{
    public partial class App : Application
    {
        private static Mutex? _instanceMutex;
        private static EventWaitHandle? _activateEvent;
        private const string MutexName = "Global\\VIBE_OneScreenOSApp_SingleInstance";
        private const string ActivateEventName = "Global\\VIBE_OneScreenOSApp_ActivateEvent";

        [DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        private static extern bool IsIconic(IntPtr hWnd);

        private const int SW_RESTORE = 9;

        protected override void OnStartup(StartupEventArgs e)
        {
            ShutdownMode = ShutdownMode.OnExplicitShutdown;

            AppDomain.CurrentDomain.UnhandledException += (s, args) =>
            {
                string logPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "crash_unhandled.log");
                System.IO.File.WriteAllText(logPath, args.ExceptionObject.ToString());
                MessageBox.Show($"CRASH: {args.ExceptionObject}", "Global Crash", MessageBoxButton.OK, MessageBoxImage.Error);
            };

            // Single Instance チェック
            bool createdNew;
            _instanceMutex = new Mutex(true, MutexName, out createdNew);

            if (!createdNew)
            {
                // 既存インスタンスが存在する場合
                string logPath = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "startup_mutex.log");
                System.IO.File.WriteAllText(logPath, "Mutex collision detected.");

                MessageBox.Show(
                    "VIBE One Screen OS は既に起動しています。\n既存のウィンドウをアクティブ化します。",
                    "既に起動中",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information);

                // 既存インスタンスへ通知
                SignalExistingInstance();

                // 新規インスタンスを終了
                Shutdown();
                return;
            }

            // イベント作成 (初回起動のみ)
            _activateEvent = new EventWaitHandle(false, EventResetMode.AutoReset, ActivateEventName);

            // 既存インスタンスからの通知を監視
            StartActivationListener();

            base.OnStartup(e);
        }

        protected override void OnExit(ExitEventArgs e)
        {
            _instanceMutex?.ReleaseMutex();
            _instanceMutex?.Dispose();
            _activateEvent?.Dispose();
            base.OnExit(e);
        }

        private void SignalExistingInstance()
        {
            try
            {
                // 既存インスタンスへアクティベーション要求を送信
                using (var evt = EventWaitHandle.OpenExisting(ActivateEventName))
                {
                    evt.Set();
                }

                // 既存インスタンスがウィンドウを復元するのを待つ (タイミング改善: 500→1000ms)
                Thread.Sleep(1000);

                // フォールバック: 直接プロセスを探して前面化を試みる
                ActivateExistingInstanceFallback();
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to signal existing instance: {ex.Message}");
                // フォールバック
                ActivateExistingInstanceFallback();
            }
        }

        private void ActivateExistingInstanceFallback()
        {
            try
            {
                var currentProcess = Process.GetCurrentProcess();
                var processes = Process.GetProcessesByName(currentProcess.ProcessName);

                foreach (var process in processes)
                {
                    // 自分自身以外のプロセスを探す
                    if (process.Id != currentProcess.Id)
                    {
                        var handle = process.MainWindowHandle;

                        if (handle != IntPtr.Zero)
                        {
                            // 最小化されている場合は復元
                            if (IsIconic(handle))
                            {
                                ShowWindow(handle, SW_RESTORE);
                                Thread.Sleep(200);
                            }

                            // 前面に持ってくる
                            SetForegroundWindow(handle);
                            break;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Failed to activate existing instance (fallback): {ex.Message}");
            }
        }

        private void StartActivationListener()
        {
            // バックグラウンドスレッドで通知を監視
            var listenerThread = new Thread(() =>
            {
                while (true)
                {
                    try
                    {
                        // 通知を待機
                        if (_activateEvent != null && _activateEvent.WaitOne())
                        {
                            // UI スレッドでウィンドウをアクティブ化
                            Dispatcher.Invoke(() =>
                            {
                                try
                                {
                                    if (MainWindow != null && !MainWindow.IsVisible)
                                    {
                                        MainWindow.Show();
                                    }

                                    if (MainWindow != null && MainWindow.WindowState == System.Windows.WindowState.Minimized)
                                    {
                                        MainWindow.WindowState = System.Windows.WindowState.Normal;
                                    }

                                    MainWindow?.Activate();
                                    MainWindow?.Focus();
                                }
                                catch (Exception ex)
                                {
                                    Debug.WriteLine($"Failed to activate window: {ex.Message}");
                                }
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        Debug.WriteLine($"Activation listener error: {ex.Message}");
                        break;
                    }
                }
            })
            {
                IsBackground = true,
                Name = "ActivationListenerThread"
            };

            listenerThread.Start();
        }
    }
}
```

---

## MainWindow.xaml
# 09 MainWindow.xaml（全文）

```xml
<Window x:Class="OneScreenOSApp.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:wv2="clr-namespace:Microsoft.Web.WebView2.Wpf;assembly=Microsoft.Web.WebView2.Wpf"
        mc:Ignorable="d"
        Title="VIBE One Screen OS" Height="900" Width="1400"
        Background="{StaticResource BackgroundPrimary}"
        FontFamily="{StaticResource FontPrimary}">


    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="260"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- ========== サイドバー ========== -->
        <Border Background="{StaticResource BackgroundSidebar}" 
                BorderBrush="{StaticResource BorderSubtle}" 
                BorderThickness="0,0,1,0">
            <DockPanel LastChildFill="False" Margin="16">

                <!-- ロゴ・タイトル -->
                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,24">
                    <TextBlock Text="VIBE" FontSize="24" FontWeight="Bold" 
                               Foreground="{StaticResource TextPrimary}"/>
                    <TextBlock Text="One Screen OS" FontSize="13" 
                               Foreground="{StaticResource TextSecondary}" Margin="0,2,0,0"/>
                </StackPanel>

                <!-- プロジェクト状態 -->
                <Border DockPanel.Dock="Top" Style="{StaticResource Card}" Margin="0,0,0,20" Padding="12">
                    <StackPanel>
                        <TextBlock Text="現在のプロジェクト" FontSize="11" FontWeight="Medium"
                                   Foreground="{StaticResource TextMuted}" Margin="0,0,0,6"/>
                        <TextBlock x:Name="TxtActiveProject" Text="---" FontWeight="SemiBold" 
                                   Foreground="{StaticResource TextPrimary}" FontSize="13" TextWrapping="Wrap"/>

                        <TextBlock Text="フェーズ" FontSize="11" FontWeight="Medium"
                                   Foreground="{StaticResource TextMuted}" Margin="0,12,0,6"/>
                        <Border x:Name="BorderPhase" Background="{StaticResource AccentBlue}" 
                                CornerRadius="4" HorizontalAlignment="Left" Padding="10,5">
                            <TextBlock x:Name="TxtPhase" Text="---" FontWeight="SemiBold" 
                                       Foreground="White" FontSize="12"/>
                        </Border>
                    </StackPanel>
                </Border>

                <!-- ナビゲーション -->
                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,20">
                    <TextBlock Text="メニュー" FontSize="11" FontWeight="Medium"
                               Foreground="{StaticResource TextMuted}" Margin="12,0,0,8"/>
                    <Button x:Name="BtnNavDashboard" Content="📊 ダッシュボード" 
                            Style="{StaticResource ButtonNav}" Click="BtnNavDashboard_Click"/>
                    <Button x:Name="BtnNavDataOps" Content="📁 DataOps" 
                            Style="{StaticResource ButtonNav}" Click="BtnNavDataOps_Click"/>
                    <Button x:Name="BtnNavSecrets" Content="🔐 シークレット" 
                            Style="{StaticResource ButtonNav}" Click="BtnNavSecrets_Click"/>
                    <Button x:Name="BtnNavProviders" Content="🌐 プロバイダー" 
                            Style="{StaticResource ButtonNav}" Click="BtnNavProviders_Click"/>
                    <Button x:Name="BtnNavSettings" Content="⚙️ 設定" 
                            Style="{StaticResource ButtonNav}" Click="BtnNavSettings_Click"/>
                </StackPanel>

                <!-- Safe Mode 表示 -->
                <Border DockPanel.Dock="Top" Background="#FFF3E0" CornerRadius="6" 
                        Padding="10" Margin="0,0,0,12">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="🛡️" FontSize="14" Margin="0,0,8,0"/>
                        <TextBlock x:Name="TxtSafeMode" Text="Safe Mode: ON" FontSize="12"
                                   Foreground="#E65100" FontWeight="Medium"/>
                    </StackPanel>
                </Border>

                <!-- 次へボタン（大） -->
                <Button x:Name="BtnAutoNext" DockPanel.Dock="Bottom" 
                        Style="{StaticResource ButtonLargeAction}"
                        Click="BtnAutoNext_Click" Margin="0,12,0,0">
                    <StackPanel>
                        <TextBlock Text="次へ" FontSize="20" FontWeight="Bold" 
                                   HorizontalAlignment="Center"/>
                        <TextBlock x:Name="TxtNextAction" Text="読み込み中..." FontSize="12" 
                                   FontWeight="Normal" Opacity="0.9"
                                   HorizontalAlignment="Center" Margin="0,4,0,0"/>
                    </StackPanel>
                </Button>

                <!-- キャンセルボタン（実行中のみ表示） -->
                <Button x:Name="BtnCancel" Content="キャンセル" DockPanel.Dock="Bottom"
                        Style="{StaticResource ButtonSecondary}" 
                        Click="BtnCancel_Click" Margin="0,8,0,0"
                        Visibility="Collapsed"/>

            </DockPanel>
        </Border>

        <!-- ========== メインコンテンツ ========== -->
        <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" Padding="24">
            <StackPanel x:Name="PanelMain" Margin="0,0,24,24">

                <!-- ========== ダッシュボードビュー ========== -->
                <StackPanel x:Name="ViewDashboard">

                    <!-- ヘッダー -->
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                        <TextBlock Text="ダッシュボード" FontSize="26" FontWeight="SemiBold"
                                   Foreground="{StaticResource TextPrimary}"/>
                        <Button x:Name="BtnRefreshAll" Content="更新" 
                                Style="{StaticResource ButtonSecondary}"
                                Click="BtnRefreshAll_Click" VerticalAlignment="Center"
                                Margin="20,0,0,0" Padding="12,6"/>
                    </StackPanel>

                    <!-- インサイト警告（問題時のみ表示） -->
                    <Border x:Name="BorderInsights" Background="#FFF8E1" 
                            BorderBrush="{StaticResource AccentOrange}" 
                            BorderThickness="1" CornerRadius="8" 
                            Padding="12,8" Margin="0,0,0,20" Visibility="Collapsed">
                        <StackPanel>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>

                                <TextBlock Text="⚠️" FontSize="16" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                <TextBlock x:Name="TxtInsightsSummary" Text="注意が必要です" FontWeight="SemiBold" 
                                           Foreground="{StaticResource AccentOrange}" FontSize="14" Grid.Column="1" VerticalAlignment="Center"/>
                                <ToggleButton x:Name="ToggleInsightDetails" Content="詳細" Style="{StaticResource ButtonSecondary}"
                                              Padding="8,4" FontSize="12" Grid.Column="2"
                                              Checked="ToggleInsightDetails_Changed" Unchecked="ToggleInsightDetails_Changed"/>
                            </Grid>

                            <StackPanel x:Name="PanelInsightDetails" Visibility="Collapsed">
                                <TextBlock x:Name="TxtInsights" Foreground="{StaticResource TextPrimary}" 
                                           TextWrapping="Wrap" FontSize="13" Margin="0,8,0,0"/>
                                <Button x:Name="BtnInsightAction" Content="修正する" 
                                        Style="{StaticResource ButtonSuccess}"
                                        Click="BtnInsightAction_Click" 
                                        HorizontalAlignment="Left" Margin="0,12,0,0"
                                        Visibility="Collapsed"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- カードグリッド -->
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <!-- カード1: いまの状態 -->
                        <Border Style="{StaticResource Card}" Grid.Column="0" Grid.Row="0" Margin="0,0,12,16">
                            <StackPanel>
                                <TextBlock Text="いまの状態" FontSize="13" FontWeight="Medium"
                                           Foreground="{StaticResource TextMuted}" Margin="0,0,0,12"/>

                                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                    <TextBlock Text="状態：" Foreground="{StaticResource TextSecondary}" FontSize="14"/>
                                    <Border x:Name="BorderStatus" Background="{StaticResource StatusSuccess}" 
                                            CornerRadius="4" Padding="8,3" Margin="8,0,0,0">
                                        <TextBlock x:Name="TxtStatus" Text="OK" Foreground="White" 
                                                   FontWeight="SemiBold" FontSize="12"/>
                                    </Border>
                                </StackPanel>

                                <TextBlock Text="次のアクション" Foreground="{StaticResource TextSecondary}" 
                                           FontSize="13" Margin="0,8,0,4"/>
                                <TextBlock x:Name="TxtNextActionDetail" Text="---" 
                                           Foreground="{StaticResource TextPrimary}" 
                                           FontSize="14" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>

                        <!-- カード2: 次へ（プレビューのみ） -->
                        <Border x:Name="CardNextPreview" Style="{StaticResource Card}" Grid.Column="1" Grid.Row="0" Margin="12,0,0,16" Background="{StaticResource BgTertiary}">
                            <StackPanel>
                                <TextBlock Text="次のアクション (プレビュー)" FontSize="13" FontWeight="Medium"
                                           Foreground="{StaticResource TextMuted}" Margin="0,0,0,12"/>

                                <Border Background="{StaticResource CardBackground}" CornerRadius="6" Padding="16" BorderBrush="{StaticResource BorderSubtle}" BorderThickness="1">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                            <TextBlock Text="Next:" FontWeight="Bold" Foreground="{StaticResource AccentGreen}" FontSize="14" Margin="0,0,8,0"/>
                                            <TextBlock x:Name="TxtNextMainSub" Text="読み込み中..." FontSize="14" FontWeight="SemiBold"/>
                                        </StackPanel>
                                        <TextBlock Text="サイドバーの「次へ」ボタンで実行できます" FontSize="11" Foreground="{StaticResource TextMuted}"/>
                                    </StackPanel>
                                </Border>

                                <TextBlock x:Name="TxtExecutionPreview" 
                                           Text="実行内容: ---" FontSize="12"
                                           Foreground="{StaticResource TextMuted}" 
                                           Margin="0,12,0,0" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>

                        <!-- カード3: 詰まり（FAIL時のみ） -->
                        <Border x:Name="CardBlocker" Style="{StaticResource Card}" 
                                Grid.Column="0" Grid.Row="1" Margin="0,0,12,16"
                                Background="#FFEBEE" BorderBrush="{StaticResource StatusError}"
                                Visibility="Collapsed">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                    <TextBlock Text="❌" FontSize="14" Margin="0,0,8,0"/>
                                    <TextBlock Text="解決が必要な問題" FontSize="13" FontWeight="SemiBold"
                                               Foreground="{StaticResource StatusError}"/>
                                </StackPanel>

                                <StackPanel x:Name="PanelBlockers">
                                    <!-- 動的に追加される問題リスト -->
                                </StackPanel>

                                <StackPanel Orientation="Horizontal" Margin="0,12,0,0">
                                    <Button x:Name="BtnCreateTemplate" Content="1. テンプレート作成"
                                            Style="{StaticResource ButtonSecondary}"
                                            Click="BtnCreateTemplate_Click" Margin="0,0,8,0"/>
                                    <Button x:Name="BtnRunVerify" Content="2. 検証"
                                            Style="{StaticResource ButtonPrimary}"
                                            Click="BtnVerify_Click"/>
                                </StackPanel>
                                <TextBlock Text="作成後、検証ボタンで状態を確認できます" FontSize="11" Foreground="{StaticResource TextMuted}" Margin="0,8,0,0"/>
                            </StackPanel>
                        </Border>

                        <!-- カード4: 最近の実行 -->
                        <Border Style="{StaticResource Card}" Grid.Column="1" Grid.Row="1" Margin="12,0,0,16">
                            <StackPanel>
                                <TextBlock Text="最近の実行（直近3回）" FontSize="13" FontWeight="Medium"
                                           Foreground="{StaticResource TextMuted}" Margin="0,0,0,12"/>

                                <StackPanel x:Name="PanelRecentRuns">
                                    <TextBlock Text="実行履歴がありません" 
                                               Foreground="{StaticResource TextMuted}" FontSize="13"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>
                    </Grid>

                    <!-- アクションボタン -->
                    <Border Style="{StaticResource Card}" Margin="0,0,0,16">
                        <StackPanel>
                            <TextBlock Text="操作" FontSize="13" FontWeight="Medium"
                                       Foreground="{StaticResource TextMuted}" Margin="0,0,0,12"/>
                            <WrapPanel>
                                <Button x:Name="BtnVerify" Content="検証" 
                                        Style="{StaticResource ButtonPrimary}"
                                        Click="BtnVerify_Click" Margin="0,0,8,8"/>
                                <Button x:Name="BtnRelease" Content="リリース" 
                                        Style="{StaticResource ButtonDanger}"
                                        Click="BtnRelease_Click" Margin="0,0,8,8"
                                        IsEnabled="False"/>
                            </WrapPanel>

                            <Expander Header="その他の操作" Style="{StaticResource ExpanderSubtle}">
                                <WrapPanel Margin="0,8,0,0">
                                    <Button x:Name="BtnUpdateDashboard" Content="ダッシュボード更新" 
                                            Style="{StaticResource ButtonSecondary}"
                                            Click="BtnUpdateDashboard_Click" Margin="0,0,8,8"/>
                                    <Button x:Name="BtnMakeIdePack" Content="IDEパック作成" 
                                            Style="{StaticResource ButtonSecondary}"
                                            Click="BtnMakeIdePack_Click" Margin="0,0,8,8"/>
                                </WrapPanel>
                            </Expander>

                            <!-- リリースの注意 -->
                            <Border x:Name="BorderReleaseWarning" Background="#FFF3E0" 
                                    CornerRadius="4" Padding="10" Margin="0,8,0,0">
                                <TextBlock x:Name="TxtReleaseWarning" 
                                           Text="💡 リリースには検証の成功が必要です" 
                                           FontSize="12" Foreground="#E65100"/>
                            </Border>
                        </StackPanel>
                    </Border>

                    <!-- 詳細（Expander） -->
                    <Expander Header="詳細を表示" Style="{StaticResource ExpanderSubtle}" 
                              Margin="0,0,0,16">
                        <Border Style="{StaticResource Card}" Margin="0,12,0,0">
                            <StackPanel>
                                <TextBlock Text="ダッシュボード (Raw)" FontSize="12" FontWeight="Medium"
                                           Foreground="{StaticResource TextMuted}" Margin="0,0,0,8"/>
                                <Border BorderBrush="{StaticResource BorderSubtle}" BorderThickness="1" 
                                        CornerRadius="4" MaxHeight="300">
                                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                                        <TextBlock x:Name="TxtDashboardRaw" Text="" 
                                                   FontFamily="{StaticResource FontMono}" 
                                                   FontSize="12" Foreground="{StaticResource TextSecondary}"
                                                   Padding="12" TextWrapping="Wrap"/>
                                    </ScrollViewer>
                                </Border>

                                <Expander Header="WebView2 プレビュー" Margin="0,16,0,0"
                                          Style="{StaticResource ExpanderSubtle}">
                                    <Border BorderBrush="{StaticResource BorderSubtle}" BorderThickness="1" 
                                            CornerRadius="4" Height="400" Margin="0,8,0,0">
                                        <wv2:WebView2 x:Name="WvDashboard" DefaultBackgroundColor="#FAFAFA"/>
                                    </Border>
                                </Expander>
                            </StackPanel>
                        </Border>
                    </Expander>

                    <!-- ログ（Expander） -->
                    <Expander Header="実行ログ" Style="{StaticResource ExpanderSubtle}">
                        <Border Style="{StaticResource Card}" Margin="0,12,0,0" Padding="0">
                            <TextBox x:Name="TxtConsole" IsReadOnly="True" 
                                     VerticalScrollBarVisibility="Auto" 
                                     Background="#1E1E1E" Foreground="#00FF00" 
                                     FontFamily="{StaticResource FontMono}" FontSize="12" 
                                     TextWrapping="Wrap" Padding="12" BorderThickness="0"
                                     Height="200"/>
                        </Border>
                    </Expander>
                </StackPanel>

                <!-- ========== DataOpsビュー ========== -->
                <StackPanel x:Name="ViewDataOps" Visibility="Collapsed">
                    <TextBlock Text="DataOps" FontSize="26" FontWeight="SemiBold"
                               Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                    <TextBlock Text="データパイプライン: カタログ → 要件 → マップ → 抽出 → パック" 
                               FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,20"/>

                    <!-- DBパス設定 -->
                    <Border Style="{StaticResource Card}" Margin="0,0,0,16">
                        <StackPanel>
                            <TextBlock Text="データベースパス" FontSize="13" FontWeight="Medium"
                                       Foreground="{StaticResource TextMuted}" Margin="0,0,0,8"/>
                            <StackPanel Orientation="Horizontal">
                                <TextBox x:Name="TxtDbPath" Width="400" Padding="8" 
                                         FontSize="13" BorderBrush="{StaticResource BorderMedium}"/>
                                <Button Content="参照..." Style="{StaticResource ButtonSecondary}"
                                        Click="BtnBrowseDbPath_Click" Margin="8,0,0,0"/>
                                <Button Content="保存" Style="{StaticResource ButtonPrimary}"
                                        Click="BtnSaveDbPath_Click" Margin="8,0,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- DataOps Empty State -->
                    <Border x:Name="BorderDataOpsEmptyState" Style="{StaticResource Card}" 
                            Background="#F1F8E9" BorderBrush="{StaticResource AccentGreen}"
                            Margin="0,0,0,16" Visibility="Collapsed">
                        <StackPanel>
                            <TextBlock Text="💡 データベース接続ガイド" FontWeight="Bold" Foreground="{StaticResource AccentGreen}" Margin="0,0,0,8"/>
                            <TextBlock Text="1. 上記の「データベースパス」を入力または参照から選択してください" Margin="16,0,0,4"/>
                            <TextBlock Text="2. 「保存」をクリックしてください" Margin="16,0,0,4"/>
                            <TextBlock Text="3. 自動的に次のステップへ進めます" Margin="16,0,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- DataOpsステップ -->
                    <Border Style="{StaticResource Card}" Margin="0,0,0,16">
                        <StackPanel>
                            <TextBlock Text="パイプライン操作" FontSize="13" FontWeight="Medium"
                                       Foreground="{StaticResource TextMuted}" Margin="0,0,0,12"/>


                            <Grid Margin="0,12,0,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <Button x:Name="BtnDataOpsCatalog" Grid.Column="0" Content="1. カタログ" Style="{StaticResource ButtonSecondary}" Click="BtnDataOpsCatalog_Click"/>
                                <TextBlock Grid.Column="1" Text="→" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="{StaticResource TextMuted}"/>

                                <Button x:Name="BtnDataOpsReq" Grid.Column="2" Content="2. 要件定義" Style="{StaticResource ButtonSecondary}" Click="BtnDataOpsReq_Click"/>
                                <TextBlock Grid.Column="3" Text="→" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="{StaticResource TextMuted}"/>

                                <Button x:Name="BtnDataOpsMap" Grid.Column="4" Content="3. マッピング" Style="{StaticResource ButtonSecondary}" Click="BtnDataOpsMap_Click"/>
                                <TextBlock Grid.Column="5" Text="→" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="{StaticResource TextMuted}"/>

                                <Button x:Name="BtnDataOpsExtract" Grid.Column="6" Content="4. 抽出" Style="{StaticResource ButtonSuccess}" Click="BtnDataOpsExtract_Click"/>
                                <TextBlock Grid.Column="7" Text="→" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="{StaticResource TextMuted}"/>

                                <Button x:Name="BtnDataOpsQa" Grid.Column="8" Content="5. QA" Style="{StaticResource ButtonSecondary}" Click="BtnDataOpsQa_Click"/>
                                <TextBlock Grid.Column="9" Text="→" VerticalAlignment="Center" HorizontalAlignment="Center" Foreground="{StaticResource TextMuted}"/>

                                <Button x:Name="BtnDataOpsPack" Grid.Column="10" Content="6. パック" Style="{StaticResource ButtonPrimary}" Click="BtnDataOpsPack_Click"/>
                            </Grid>
                        </StackPanel>
                    </Border>

                    <!-- DataOps進捗 -->
                    <Border x:Name="BorderDataOpsProgress" Style="{StaticResource Card}" 
                            Margin="0,0,0,16" Visibility="Collapsed">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                                <TextBlock x:Name="TxtDataOpsProgressLabel" Text="処理中..." 
                                           FontSize="14" Foreground="{StaticResource TextPrimary}"/>
                                <Button x:Name="BtnDataOpsCancel" Content="キャンセル" 
                                        Style="{StaticResource ButtonSecondary}"
                                        Click="BtnDataOpsCancel_Click" Margin="12,0,0,0" Padding="8,4"/>
                            </StackPanel>
                            <ProgressBar x:Name="ProgressDataOps" Height="6" IsIndeterminate="True"/>
                            <TextBlock x:Name="TxtDataOpsProgressDetail" Text="" 
                                       FontSize="12" Foreground="{StaticResource TextMuted}" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- DataOps結果 -->
                    <Expander x:Name="ExpanderDataOpsResult" Header="結果プレビュー"
                              Style="{StaticResource ExpanderSubtle}" IsExpanded="True">
                        <Border Style="{StaticResource Card}" Margin="0,12,0,0" Padding="0">
                            <StackPanel>
                                <!-- サマリー情報 -->
                                <Border Background="{StaticResource BgTertiary}" Padding="12,8"
                                        BorderBrush="{StaticResource BorderMedium}" BorderThickness="0,0,0,1">
                                    <StackPanel x:Name="StackDataOpsSummary" Visibility="Collapsed">
                                        <TextBlock x:Name="TxtDataOpsSummary" Text=""
                                                   FontSize="12" Foreground="{StaticResource TextMuted}"/>
                                    </StackPanel>
                                </Border>
                                <!-- 詳細プレビュー -->
                                <ScrollViewer VerticalScrollBarVisibility="Auto" MaxHeight="400">
                                    <TextBlock x:Name="TxtDataOpsResult" Text=""
                                               FontFamily="{StaticResource FontMono}"
                                               FontSize="12" Foreground="{StaticResource TextSecondary}"
                                               Padding="12" TextWrapping="Wrap"/>
                                </ScrollViewer>
                            </StackPanel>
                        </Border>
                    </Expander>
                </StackPanel>

                <!-- ========== シークレットビュー ========== -->
                <StackPanel x:Name="ViewSecrets" Visibility="Collapsed">
                    <TextBlock Text="シークレット" FontSize="26" FontWeight="SemiBold"
                               Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                    <TextBlock Text="暗号化された認証情報（DPAPI）"
                               FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,20"/>

                    <StackPanel Orientation="Horizontal" Margin="0,0,0,16">
                        <Button x:Name="BtnAddSecretPrimary" Content="🔐 シークレットを追加"
                                Style="{StaticResource ButtonSuccess}"
                                Click="BtnAddSecret_Click" Margin="0,0,8,0"
                                FontSize="14" Padding="16,10"/>
                        <Button Content="更新" Style="{StaticResource ButtonSecondary}"
                                Click="BtnRefreshSecrets_Click"/>
                    </StackPanel>

                    <!-- Empty State -->
                    <Border x:Name="BorderSecretsEmptyState" Style="{StaticResource Card}"
                            Padding="32" Margin="0,0,0,16" Visibility="Collapsed">
                        <StackPanel HorizontalAlignment="Center" MaxWidth="500">
                            <TextBlock Text="🔐" FontSize="48" HorizontalAlignment="Center" Margin="0,0,0,16"/>
                            <TextBlock Text="シークレットがまだ登録されていません"
                                       FontSize="16" FontWeight="Medium"
                                       Foreground="{StaticResource TextPrimary}"
                                       HorizontalAlignment="Center" Margin="0,0,0,12"/>
                            <TextBlock TextWrapping="Wrap" FontSize="13"
                                       Foreground="{StaticResource TextMuted}"
                                       HorizontalAlignment="Center" TextAlignment="Center" Margin="0,0,0,20">
                                シークレットは、APIキー、パスワード、トークンなどの機密情報を<LineBreak/>
                                Windows DPAPIで暗号化して安全に保存する機能です。
                            </TextBlock>
                            <TextBlock TextWrapping="Wrap" FontSize="12"
                                       Foreground="{StaticResource TextMuted}"
                                       Margin="0,0,0,16">
                                <Bold>登録が推奨されるシークレット:</Bold><LineBreak/>
                                • OpenAI API Key (カテゴリ: openai, キー: api_key)<LineBreak/>
                                • Anthropic API Key (カテゴリ: anthropic, キー: api_key)<LineBreak/>
                                • Google API Key (カテゴリ: google, キー: api_key)<LineBreak/>
                                • GitHub Token (カテゴリ: github, キー: token)
                            </TextBlock>
                            <Button Content="最初のシークレットを追加"
                                    Style="{StaticResource ButtonSuccess}"
                                    Click="BtnAddSecret_Click"
                                    HorizontalAlignment="Center"
                                    FontSize="14" Padding="20,12"/>
                        </StackPanel>
                    </Border>

                    <!-- Secrets Grid -->
                    <Border x:Name="BorderSecretsGrid" Style="{StaticResource Card}" Padding="0">
                        <DataGrid x:Name="GridSecrets" AutoGenerateColumns="False"
                                  CanUserAddRows="False" CanUserDeleteRows="False"
                                  Background="Transparent" BorderThickness="0"
                                  GridLinesVisibility="Horizontal"
                                  HorizontalGridLinesBrush="{StaticResource BorderSubtle}"
                                  HeadersVisibility="Column" FontSize="13">
                            <DataGrid.Columns>
                                <DataGridTextColumn Header="カテゴリ" Binding="{Binding Category}"
                                                    IsReadOnly="True" Width="100"/>
                                <DataGridTextColumn Header="キー" Binding="{Binding Key}"
                                                    IsReadOnly="True" Width="180"/>
                                <DataGridTextColumn Header="説明" Binding="{Binding Description}"
                                                    IsReadOnly="True" Width="*"/>
                                <DataGridTextColumn Header="更新日時"
                                                    Binding="{Binding UpdatedAt, StringFormat='yyyy-MM-dd HH:mm'}"
                                                    IsReadOnly="True" Width="130"/>
                                <DataGridTemplateColumn Header="操作" Width="180">
                                    <DataGridTemplateColumn.CellTemplate>
                                        <DataTemplate>
                                            <StackPanel Orientation="Horizontal">
                                                <Button Content="表示" Tag="{Binding Key}"
                                                        Click="BtnViewSecret_Click"
                                                        Style="{StaticResource ButtonSecondary}"
                                                        Padding="8,4" Margin="0,0,4,0"/>
                                                <Button Content="コピー" Tag="{Binding Key}"
                                                        Click="BtnCopySecret_Click"
                                                        Style="{StaticResource ButtonPrimary}"
                                                        Padding="8,4" Margin="0,0,4,0"/>
                                                <Button Content="削除" Tag="{Binding Key}"
                                                        Click="BtnDeleteSecret_Click"
                                                        Style="{StaticResource ButtonDanger}"
                                                        Padding="8,4"/>
                                            </StackPanel>
                                        </DataTemplate>
                                    </DataGridTemplateColumn.CellTemplate>
                                </DataGridTemplateColumn>
                            </DataGrid.Columns>
                        </DataGrid>
                    </Border>
                </StackPanel>

                <!-- ========== プロバイダービュー ========== -->
                <StackPanel x:Name="ViewProviders" Visibility="Collapsed">
                    <TextBlock Text="プロバイダー" FontSize="26" FontWeight="SemiBold"
                               Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                    <TextBlock Text="APIプロバイダーの状態とレート制限" 
                               FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,20"/>

                    <Button Content="状態を更新" Style="{StaticResource ButtonSecondary}"
                            Click="BtnRefreshProviders_Click" Margin="0,0,0,16"/>

                    <StackPanel x:Name="PanelProviders">
                        <TextBlock Text="プロバイダー情報がありません" 
                                   Foreground="{StaticResource TextMuted}" FontSize="13"/>
                    </StackPanel>
                </StackPanel>

                <!-- ========== 設定ビュー ========== -->
                <StackPanel x:Name="ViewSettings" Visibility="Collapsed">
                    <TextBlock Text="設定" FontSize="26" FontWeight="SemiBold"
                               Foreground="{StaticResource TextPrimary}" Margin="0,0,0,20"/>

                    <!-- Safe Mode -->
                    <Border Style="{StaticResource Card}" Margin="0,0,0,16">
                        <StackPanel>
                            <TextBlock Text="Safe Mode" FontSize="15" FontWeight="SemiBold"
                                       Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                            <TextBlock Text="有効時：ファイル上書き禁止、リリース前に検証必須、危険操作の確認" 
                                       FontSize="13" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,12"/>
                            <StackPanel Orientation="Horizontal">
                                <CheckBox x:Name="ChkSafeMode" Content="Safe Modeを有効にする" 
                                          IsChecked="True" FontSize="14"
                                          Checked="ChkSafeMode_Changed" Unchecked="ChkSafeMode_Changed"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- テーマ -->
                    <Border Style="{StaticResource Card}" Margin="0,0,0,16">
                        <StackPanel>
                            <TextBlock Text="テーマ" FontSize="15" FontWeight="SemiBold"
                                       Foreground="{StaticResource TextPrimary}" Margin="0,0,0,8"/>
                            <StackPanel Orientation="Horizontal">
                                <RadioButton x:Name="RdoThemeLight" Content="ライト" 
                                             IsChecked="True" Margin="0,0,16,0" FontSize="14"/>
                                <RadioButton x:Name="RdoThemeDark" Content="ダーク" FontSize="14"
                                             IsEnabled="False"/>
                            </StackPanel>
                            <TextBlock Text="（ダークテーマは今後対応予定）" FontSize="12" 
                                       Foreground="{StaticResource TextMuted}" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- Local LLM -->
                    <Border Style="{StaticResource Card}" Margin="0,0,0,16">
                        <StackPanel>
                            <TextBlock Text="ローカルLLM" FontSize="15" FontWeight="SemiBold"
                                       Foreground="{StaticResource TextPrimary}" Margin="0,0,0,12"/>

                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <!-- LM Studio -->
                                <Border Grid.Column="0" BorderBrush="{StaticResource BorderSubtle}"
                                        BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,0,8,0">
                                    <StackPanel>
                                        <TextBlock Text="LM Studio" FontWeight="SemiBold"
                                                   Foreground="{StaticResource AccentBlue}" Margin="0,0,0,8"/>

                                        <TextBlock Text="Base URL:" FontSize="12" Margin="0,0,0,4"/>
                                        <DockPanel Margin="0,0,0,8">
                                            <Button DockPanel.Dock="Right" Content="🔗" ToolTip="ブラウザで開く" 
                                                    Click="BtnOpenLmStudioWeb_Click" Style="{StaticResource ButtonSecondary}" Padding="6,4" Margin="4,0,0,0"/>
                                            <Button DockPanel.Dock="Right" Content="📋" ToolTip="コピー" 
                                                    Click="BtnCopyLmStudioUrl_Click" Style="{StaticResource ButtonSecondary}" Padding="6,4" Margin="4,0,0,0"/>
                                            <TextBox x:Name="TxtLmStudioUrl" Text="http://localhost:1234/v1" Padding="6" FontSize="13"/>
                                        </DockPanel>

                                        <Border x:Name="StatusLmStudioWrapper" Background="{StaticResource BgTertiary}" CornerRadius="4" Padding="8,4" HorizontalAlignment="Left" Margin="0,0,0,4">
                                            <TextBlock x:Name="TxtLmStudioStatus" Text="状態: 未テスト"
                                                       Foreground="{StaticResource TextSecondary}" FontSize="12"/>
                                        </Border>
                                        <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                                            <Button Content="保存" Click="BtnSaveLmStudioUrl_Click" Style="{StaticResource ButtonSecondary}" Padding="8,4" Margin="0,0,8,0"/>
                                            <Button Content="接続テスト" Click="BtnLmStudioTest_Click"
                                                    Style="{StaticResource ButtonPrimary}"
                                                    Padding="8,4"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>



                                <!-- Ollama -->
                                <Border Grid.Column="1" BorderBrush="{StaticResource BorderSubtle}"
                                        BorderThickness="1" CornerRadius="6" Padding="12" Margin="8,0,0,0">
                                    <StackPanel>
                                        <TextBlock Text="Ollama" FontWeight="SemiBold"
                                                   Foreground="{StaticResource AccentGreen}" Margin="0,0,0,8"/>

                                        <TextBlock Text="Base URL:" FontSize="12" Margin="0,0,0,4"/>
                                        <DockPanel Margin="0,0,0,8">
                                            <Button DockPanel.Dock="Right" Content="🔗" ToolTip="ブラウザで開く" 
                                                    Click="BtnOpenOllamaWeb_Click" Style="{StaticResource ButtonSecondary}" Padding="6,4" Margin="4,0,0,0"/>
                                            <Button DockPanel.Dock="Right" Content="📋" ToolTip="コピー" 
                                                    Click="BtnCopyOllamaUrl_Click" Style="{StaticResource ButtonSecondary}" Padding="6,4" Margin="4,0,0,0"/>
                                            <TextBox x:Name="TxtOllamaUrl" Text="http://localhost:11434" Padding="6" FontSize="13"/>
                                        </DockPanel>

                                        <Border x:Name="StatusOllamaWrapper" Background="{StaticResource BgTertiary}" CornerRadius="4" Padding="8,4" HorizontalAlignment="Left" Margin="0,0,0,4">
                                            <TextBlock x:Name="TxtOllamaStatus" Text="状態: 未テスト"
                                                       Foreground="{StaticResource TextSecondary}" FontSize="12"/>
                                        </Border>

                                        <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                                             <Button Content="保存" Click="BtnSaveOllamaUrl_Click" Style="{StaticResource ButtonSecondary}" Padding="8,4" Margin="0,0,8,0"/>
                                            <Button Content="接続テスト" Click="BtnOllamaTest_Click"
                                                    Style="{StaticResource ButtonSuccess}"
                                                    Padding="8,4"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>
                            </Grid>

                            <TextBox x:Name="TxtLocalLlmLog" IsReadOnly="True" 
                                     VerticalScrollBarVisibility="Auto" 
                                     Background="#F5F5F5" Foreground="{StaticResource TextSecondary}"
                                     FontFamily="{StaticResource FontMono}" FontSize="12" 
                                     Padding="10" BorderThickness="1" 
                                     BorderBrush="{StaticResource BorderSubtle}"
                                     Height="150" Margin="0,16,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- MCP Servers -->
                    <Expander Header="MCP サーバー" Style="{StaticResource ExpanderSubtle}">
                        <Border Style="{StaticResource Card}" Margin="0,12,0,0">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                    <Button Content="+ サーバー追加" Click="BtnAddMcpServer_Click" 
                                            Style="{StaticResource ButtonSuccess}" Margin="0,0,8,0"/>
                                    <Button Content="AutoStart実行" Click="BtnStartAutoStartServers_Click" 
                                            Style="{StaticResource ButtonPrimary}" Margin="0,0,8,0"/>
                                    <Button Content="状態更新" Click="BtnRefreshMcpStatus_Click" 
                                            Style="{StaticResource ButtonSecondary}"/>
                                </StackPanel>

                                <DataGrid x:Name="GridMcpServers" AutoGenerateColumns="False" 
                                          CanUserAddRows="False" SelectionChanged="GridMcpServers_SelectionChanged"
                                          Background="Transparent" BorderThickness="0" FontSize="13"
                                          GridLinesVisibility="Horizontal" 
                                          HorizontalGridLinesBrush="{StaticResource BorderSubtle}">
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="名前" Binding="{Binding Name}" 
                                                            IsReadOnly="True" Width="120"/>
                                        <DataGridTextColumn Header="状態" Binding="{Binding State}" 
                                                            IsReadOnly="True" Width="80"/>
                                        <DataGridTextColumn Header="PID" Binding="{Binding ProcessId}" 
                                                            IsReadOnly="True" Width="60"/>
                                        <DataGridTextColumn Header="稼働時間" Binding="{Binding Uptime}" 
                                                            IsReadOnly="True" Width="100"/>
                                        <DataGridTemplateColumn Header="操作" Width="*">
                                            <DataGridTemplateColumn.CellTemplate>
                                                <DataTemplate>
                                                    <StackPanel Orientation="Horizontal">
                                                        <Button Content="起動" Tag="{Binding Name}" 
                                                                Click="BtnStartMcpServer_Click" 
                                                                Style="{StaticResource ButtonSuccess}"
                                                                Padding="6,3" Margin="0,0,4,0"/>
                                                        <Button Content="停止" Tag="{Binding Name}" 
                                                                Click="BtnStopMcpServer_Click" 
                                                                Style="{StaticResource ButtonDanger}"
                                                                Padding="6,3" Margin="0,0,4,0"/>
                                                        <Button Content="再起動" Tag="{Binding Name}" 
                                                                Click="BtnRestartMcpServer_Click" 
                                                                Style="{StaticResource ButtonPrimary}"
                                                                Padding="6,3"/>
                                                    </StackPanel>
                                                </DataTemplate>
                                            </DataGridTemplateColumn.CellTemplate>
                                        </DataGridTemplateColumn>
                                    </DataGrid.Columns>
                                </DataGrid>

                                <TextBlock Text="サーバーログ" FontWeight="Medium" 
                                           Foreground="{StaticResource TextMuted}" Margin="0,16,0,8"/>
                                <TextBox x:Name="TxtMcpLogs" IsReadOnly="True" 
                                         VerticalScrollBarVisibility="Auto" 
                                         Background="#F5F5F5" Foreground="{StaticResource TextSecondary}"
                                         FontFamily="{StaticResource FontMono}" FontSize="11" 
                                         Padding="8" BorderThickness="1" Height="120"
                                         BorderBrush="{StaticResource BorderSubtle}"/>
                            </StackPanel>
                        </Border>
                    </Expander>
                </StackPanel>

            </StackPanel>
        </ScrollViewer>

        <!-- ステータスバー -->
        <Border Grid.Column="1" VerticalAlignment="Bottom" 
                Background="{StaticResource AccentBlue}" Padding="12,6">
            <TextBlock x:Name="TxtStatusBar" Text="準備完了" Foreground="White" FontSize="12"/>
        </Border>
    </Grid>
</Window>
```

---

## MainWindow.xaml.cs
# 11 MainWindow.xaml.cs（全文）

```csharp
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using System.Text.Json;
using RunnerCore;

namespace OneScreenOSApp
{
    public partial class MainWindow : Window
    {
        // ========== フィールド ==========
        private string _oneBoxRoot = "";
        private EntryRegistry? _registry;
        private Snapshot? _currentSnapshot;
        private FileSystemWatcher? _watcher;
        private bool _lastVerifyPassed = false;

        // 新コンポーネント
        private ProviderTelemetry? _providerTelemetry;
        private SecretsVault? _secretsVault;
        private LocalLlmIntegration? _localLlm;
        private McpServerManager? _mcpManager;
        private BackupManager? _backupManager;

        // 実行キュー（同時実行防止）
        private readonly ExecutionQueue _executionQueue = new();

        // デバウンス用
        private CancellationTokenSource? _debounceRefreshCts;
        private readonly object _debounceLock = new();
        private const int DebounceMs = 500;

        // 実行履歴
        private readonly List<RunHistoryItem> _runHistory = new();

        public MainWindow()
        {
            try
            {
                InitializeComponent();
                Loaded += MainWindow_Loaded;
                Closing += MainWindow_Closing;
            }
            catch (Exception ex)
            {
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "startup_error.log");
                File.WriteAllText(logPath, ex.ToString());
                MessageBox.Show($"起動エラー: {ex.Message}\n詳細は {logPath} を確認してください。", "Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
                throw;
            }
        }

        // ========== 初期化 ==========
        private async void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            Log("VIBE One Screen OS 起動中...");
            UpdateSafeModeDisplay();

            // 1. OneBox Root検出 (Auto-Detect + Persistence + Fallback)
            if (!await LoadOrDetectOneBoxRootAsync())
            {
                // ユーザーがキャンセルの場合など
                TxtStatusBar.Text = "エラー: OneBox Rootが特定できませんでした";
                return;
            }

            Log($"OneBox Root: {_oneBoxRoot}");

            // 2. Entry Registry読み込み
            _registry = await EntryDiscovery.DiscoverAsync(_oneBoxRoot);
            Log($"Entry Registry: {_registry.AllowList.Count}件のエントリ");

            // 3. コンポーネント初期化
            await InitializeComponentsAsync();

            // 4. バックアップマネージャー
            _backupManager = new BackupManager(_oneBoxRoot);
            _backupManager.CleanupOldBackups(30);

            // 5. FileSystemWatcher設定
            SetupFileWatcher();

            // 6. 初回リフレッシュ
            await RefreshAllAsync();

            // ダッシュボード表示
            ShowView("Dashboard");
        }

        private async Task InitializeComponentsAsync()
        {
            try
            {
                _providerTelemetry = new ProviderTelemetry(_oneBoxRoot);
                Log("ProviderTelemetry 初期化完了");

                _secretsVault = new SecretsVault(_oneBoxRoot);
                await _secretsVault.InitializeAsync();
                Log($"SecretsVault: {_secretsVault.GetStats().TotalSecrets}件のシークレット");

                _localLlm = new LocalLlmIntegration(null, _providerTelemetry);
                Log("LocalLlmIntegration 初期化完了");

                _mcpManager = new McpServerManager(_oneBoxRoot);
                await _mcpManager.InitializeAsync();
                Log("McpServerManager 初期化完了");

                await _mcpManager.StartAutoStartServersAsync();
                Log("AutoStart MCPサーバー起動完了");
            }
            catch (Exception ex)
            {
                Log($"コンポーネント初期化エラー: {ex.Message}");
            }
        }

        private async Task<bool> LoadOrDetectOneBoxRootAsync()
        {
            // 1. Try Auto-Detect (Standard VaultLocator)
            var location = VaultLocator.LocateRoot(AppDomain.CurrentDomain.BaseDirectory);
            if (location.Success)
            {
                _oneBoxRoot = location.RootPath!;
                return true;
            }

            // 2. Try Load Config (Next to EXE)
            var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "onebox_config.json");
            if (File.Exists(configPath))
            {
                try
                {
                    var json = await File.ReadAllTextAsync(configPath);
                    using var doc = JsonDocument.Parse(json);
                    if (doc.RootElement.TryGetProperty("onebox_root", out var rootProp))
                    {
                        var savedRoot = rootProp.GetString();
                        if (!string.IsNullOrEmpty(savedRoot) && Directory.Exists(savedRoot))
                        {
                            _oneBoxRoot = savedRoot;
                            Log($"ConfigからRootを復元: {_oneBoxRoot}");
                            return true;
                        }
                    }
                }
                catch (Exception ex)
                {
                    Log($"Config読み込みエラー: {ex.Message}");
                }
            }

            // 3. Fallback: User Selection
            var result = MessageBox.Show(
                "OneBox Rootが見つかりませんでした。\n手動で OneBox Root フォルダ（VAULTフォルダがある場所）を選択しますか？",
                "OneBox Root 未検出",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (result == MessageBoxResult.Yes)
            {
                var dialog = new System.Windows.Forms.FolderBrowserDialog
                {
                    Description = "OneBox Root フォルダを選択してください",
                    ShowNewFolderButton = false
                };

                if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                {
                    var selectedPath = dialog.SelectedPath;

                    // Verify structure
                    if (Directory.Exists(Path.Combine(selectedPath, "VAULT")))
                    {
                        _oneBoxRoot = selectedPath;
                        await SaveOneBoxRootAsync(_oneBoxRoot);
                        return true;
                    }
                    else
                    {
                        MessageBox.Show(
                            "選択されたフォルダに 'VAULT' フォルダが見つかりません。\n正しい OneBox Root を選択してください。",
                            "不正なフォルダ",
                            MessageBoxButton.OK,
                            MessageBoxImage.Warning);
                    }
                }
            }

            return false;
        }

        private async Task SaveOneBoxRootAsync(string rootPath)
        {
            try
            {
                var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "onebox_config.json");
                var config = new { onebox_root = rootPath, updated_at = DateTime.Now };
                var json = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true });
                await File.WriteAllTextAsync(configPath, json);
                Log("OneBox Root設定を保存しました");
            }
            catch (Exception ex)
            {
                Log($"Config保存エラー: {ex.Message}");
            }
        }

        // ========== FileSystemWatcher ==========
        private void SetupFileWatcher()
        {
            try
            {
                string vaultPath = Path.Combine(_oneBoxRoot, "VAULT");
                if (Directory.Exists(vaultPath))
                {
                    _watcher = new FileSystemWatcher(vaultPath)
                    {
                        Filter = "*.*",
                        NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName,
                        IncludeSubdirectories = false
                    };
                    _watcher.Changed += OnFileChanged;
                    _watcher.Created += OnFileChanged;
                    _watcher.Renamed += OnFileChanged;
                    _watcher.Error += OnWatcherError;
                    _watcher.EnableRaisingEvents = true;
                    Log("FileSystemWatcher: VAULT監視開始");
                }
            }
            catch (Exception ex)
            {
                Log($"Watcher初期化エラー: {ex.Message}");
            }
        }

        private void OnFileChanged(object sender, FileSystemEventArgs e)
        {
            if (e.Name?.Contains("VIBE_DASHBOARD") == true || 
                e.Name?.Contains("APP_KPI") == true || 
                e.Name?.Contains("APP_INSIGHTS") == true)
            {
                // デバウンス付きリフレッシュ（後勝ちキャンセル）
                DebouncedRefreshAsync();
            }
        }

        private void OnWatcherError(object sender, ErrorEventArgs e)
        {
            Log("FileSystemWatcher エラー（バッファオーバーフロー？）再スキャン中...");
            DebouncedRefreshAsync();
        }

        private async void DebouncedRefreshAsync()
        {
            CancellationToken token;
            lock (_debounceLock)
            {
                _debounceRefreshCts?.Cancel();
                _debounceRefreshCts = new CancellationTokenSource();
                token = _debounceRefreshCts.Token;
            }

            try
            {
                await Task.Delay(DebounceMs, token);
                if (!token.IsCancellationRequested)
                {
                    await Dispatcher.InvokeAsync(async () => await RefreshAllAsync());
                }
            }
            catch (OperationCanceledException) { /* キャンセルは正常 */ }
        }

        // ========== リフレッシュ ==========
        private async Task RefreshAllAsync()
        {
            TxtStatusBar.Text = "更新中...";

            try
            {
                // Snapshot読み込み
                string dashPath = Path.Combine(_oneBoxRoot, "VAULT", "VIBE_DASHBOARD.md");
                _currentSnapshot = await SnapshotReader.ReadAsync(dashPath);

                // UI更新
                TxtActiveProject.Text = _currentSnapshot.ActiveProject;
                TxtPhase.Text = _currentSnapshot.CurrentPhase.ToUpper();

                // 状態表示
                bool isFail = _currentSnapshot.PassCheckStatus == "FAIL";
                if (isFail)
                {
                    BorderPhase.Background = FindResource("StatusError") as SolidColorBrush;
                    BorderStatus.Background = FindResource("StatusError") as SolidColorBrush;
                    TxtStatus.Text = "FAIL";
                    CardBlocker.Visibility = Visibility.Visible;

                    // Parse and display missing files
                    await PopulateMissingFilesAsync(dashPath);
                }
                else
                {
                    BorderPhase.Background = FindResource("AccentBlue") as SolidColorBrush;
                    BorderStatus.Background = FindResource("StatusSuccess") as SolidColorBrush;
                    TxtStatus.Text = "OK";
                    CardBlocker.Visibility = Visibility.Collapsed;
                }

                // 次のアクション解決
                var resolution = AutoNextResolver.Resolve(_currentSnapshot, _registry!);
                if (resolution.Success)
                {
                    var entry = _registry!.Find(resolution.EntryId);
                    string displayName = entry?.DisplayName ?? resolution.EntryId;
                    TxtNextAction.Text = displayName;
                    TxtNextActionDetail.Text = displayName;
                    TxtNextMainSub.Text = $"クリックで実行: {displayName}";
                    TxtExecutionPreview.Text = $"実行内容: {entry?.Description ?? "次の工程を実行します"}";

                    BtnAutoNext.IsEnabled = true;
                    // BtnNextMain removed
                }
                else
                {
                    TxtNextAction.Text = "待機中...";
                    TxtNextActionDetail.Text = "次のアクションはありません";
                    TxtNextMainSub.Text = "---";
                    TxtExecutionPreview.Text = "---";

                    BtnAutoNext.IsEnabled = false;
                    // BtnNextMain removed
                }

                // リリースボタン制御
                UpdateReleaseButtonState();

                // Dashboard Raw表示
                if (File.Exists(dashPath))
                {
                    TxtDashboardRaw.Text = await File.ReadAllTextAsync(dashPath);
                }

                // 実行履歴更新
                UpdateRunHistoryDisplay();

                // KPI・インサイト（軽量版）
                await UpdateInsightsAsync();

                TxtStatusBar.Text = "準備完了";
            }
            catch (Exception ex)
            {
                Log($"リフレッシュエラー: {ex.Message}");
                TxtStatusBar.Text = "エラー発生";
            }
        }

        private void UpdateReleaseButtonState()
        {
            bool canRelease = SafeMode.CanRelease(_lastVerifyPassed);
            BtnRelease.IsEnabled = canRelease;

            if (!canRelease)
            {
                TxtReleaseWarning.Text = "💡 リリースには検証の成功が必要です";
                BorderReleaseWarning.Background = new SolidColorBrush(Color.FromRgb(255, 243, 224));
            }
            else
            {
                TxtReleaseWarning.Text = "✅ 検証成功済み。リリース可能です";
                BorderReleaseWarning.Background = new SolidColorBrush(Color.FromRgb(232, 245, 233));
            }
        }

        private async Task UpdateInsightsAsync()
        {
            try
            {
                var stuck = new StuckWarning();
                var insights = await InsightsEngine.GenerateAsync(_oneBoxRoot, _currentSnapshot!, stuck);

                if (insights.Any())
                {
                    var top = insights.First();
                    BorderInsights.Visibility = Visibility.Visible;
                    TxtInsights.Text = $"{top.Title}: {top.Description}";

                    if (top.ActionType != "none")
                    {
                        BtnInsightAction.Visibility = Visibility.Visible;
                        BtnInsightAction.Tag = top;
                        BtnInsightAction.Content = $"修正: {top.ActionTarget}";
                    }
                    else
                    {
                        BtnInsightAction.Visibility = Visibility.Collapsed;
                    }
                }
                else
                {
                    BorderInsights.Visibility = Visibility.Collapsed;
                }
            }
            catch (Exception ex)
            {
                Log($"インサイト取得エラー: {ex.Message}");
            }
        }

        private void UpdateRunHistoryDisplay()
        {
            PanelRecentRuns.Children.Clear();

            var recent = _runHistory.TakeLast(3).Reverse();
            if (!recent.Any())
            {
                PanelRecentRuns.Children.Add(new TextBlock
                {
                    Text = "実行履歴がありません",
                    Foreground = FindResource("TextMuted") as SolidColorBrush,
                    FontSize = 13
                });
                return;
            }

            foreach (var item in recent)
            {
                var panel = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 0, 0, 6) };

                panel.Children.Add(new TextBlock
                {
                    Text = item.Success ? "✅" : "❌",
                    FontSize = 14,
                    Margin = new Thickness(0, 0, 8, 0)
                });

                panel.Children.Add(new TextBlock
                {
                    Text = item.DisplayName,
                    Foreground = FindResource("TextPrimary") as SolidColorBrush,
                    FontSize = 13
                });

                panel.Children.Add(new TextBlock
                {
                    Text = $" ({item.DurationMs}ms)",
                    Foreground = FindResource("TextMuted") as SolidColorBrush,
                    FontSize = 12
                });

                PanelRecentRuns.Children.Add(panel);
            }
        }

        // ========== 実行 ==========
        private async Task RunEntryAsync(Entry entry)
        {
            if (_executionQueue.IsRunning)
            {
                Log($"別の処理が実行中です: {_executionQueue.CurrentEntryId}");
                MessageBox.Show($"別の処理が実行中です。\n実行中: {_executionQueue.CurrentEntryId}", 
                    "実行中", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            // UI更新（実行中状態）
            SetExecutingState(true, entry.DisplayName);
            var startTime = DateTime.Now;

            try
            {
                var result = await _executionQueue.RunAsync(entry.Id, async (ct) =>
                {
                    var progress = new Progress<RunEvent>(evt =>
                    {
                        Log(evt.Message);
                        if (evt.IsError)
                        {
                            TxtStatusBar.Text = $"エラー: {evt.Message}";
                        }
                    });

                    return await EngineInvoker.ExecuteAsync(entry, _oneBoxRoot, _currentSnapshot!, progress);
                }, TimeSpan.FromMinutes(10));

                var duration = (int)(DateTime.Now - startTime).TotalMilliseconds;
                bool success = result.exit_code == 0;

                // 履歴追加
                _runHistory.Add(new RunHistoryItem
                {
                    DisplayName = entry.DisplayName,
                    Success = success,
                    DurationMs = duration,
                    Timestamp = DateTime.Now
                });

                // Verifyの場合、結果を記録
                if (entry.Id.Contains("verify"))
                {
                    _lastVerifyPassed = success;
                }

                TxtStatusBar.Text = $"完了: {entry.DisplayName} (終了コード: {result.exit_code})";
                Log($"完了: {entry.DisplayName} - {duration}ms");

                // リフレッシュ
                await RefreshAllAsync();
            }
            catch (OperationCanceledException)
            {
                Log($"キャンセル: {entry.DisplayName}");
                TxtStatusBar.Text = "キャンセルされました";
            }
            catch (Exception ex)
            {
                Log($"実行エラー: {ex.Message}");
                TxtStatusBar.Text = $"エラー: {ex.Message}";

                _runHistory.Add(new RunHistoryItem
                {
                    DisplayName = entry.DisplayName,
                    Success = false,
                    DurationMs = (int)(DateTime.Now - startTime).TotalMilliseconds,
                    Timestamp = DateTime.Now
                });
            }
            finally
            {
                SetExecutingState(false, null);
            }
        }

        private void SetExecutingState(bool isExecuting, string? entryName)
        {
            if (isExecuting)
            {
                BtnAutoNext.IsEnabled = false;
                // BtnNextMain removed
                BtnUpdateDashboard.IsEnabled = false;
                BtnVerify.IsEnabled = false;
                BtnRelease.IsEnabled = false;
                BtnMakeIdePack.IsEnabled = false;
                BtnCancel.Visibility = Visibility.Visible;

                TxtStatusBar.Text = $"実行中: {entryName}...";
            }
            else
            {
                BtnCancel.Visibility = Visibility.Collapsed;
                BtnUpdateDashboard.IsEnabled = true;
                BtnVerify.IsEnabled = true;
                BtnMakeIdePack.IsEnabled = true;
                UpdateReleaseButtonState();
                // BtnAutoNext/BtnNextMainはRefreshAllAsyncで更新
            }
        }

        private async Task RunEntryById(string id)
        {
            var entry = _registry?.Find(id);
            if (entry != null)
            {
                await RunEntryAsync(entry);
            }
            else
            {
                Log($"エントリが見つかりません: {id}");
            }
        }

        // ========== ナビゲーション ==========
        private void ShowView(string viewName)
        {
            ViewDashboard.Visibility = viewName == "Dashboard" ? Visibility.Visible : Visibility.Collapsed;
            ViewDataOps.Visibility = viewName == "DataOps" ? Visibility.Visible : Visibility.Collapsed;
            ViewSecrets.Visibility = viewName == "Secrets" ? Visibility.Visible : Visibility.Collapsed;
            ViewProviders.Visibility = viewName == "Providers" ? Visibility.Visible : Visibility.Collapsed;
            ViewSettings.Visibility = viewName == "Settings" ? Visibility.Visible : Visibility.Collapsed;
        }

        private void BtnNavDashboard_Click(object sender, RoutedEventArgs e) => ShowView("Dashboard");
        private void BtnNavDataOps_Click(object sender, RoutedEventArgs e) => ShowView("DataOps");
        private void BtnNavSecrets_Click(object sender, RoutedEventArgs e) 
        { 
            ShowView("Secrets"); 
            BtnRefreshSecrets_Click(sender, e);
        }
        private void BtnNavProviders_Click(object sender, RoutedEventArgs e) 
        { 
            ShowView("Providers"); 
            BtnRefreshProviders_Click(sender, e);
        }
        private void BtnNavSettings_Click(object sender, RoutedEventArgs e) => ShowView("Settings");

        // ========== Safe Mode ==========
        private void UpdateSafeModeDisplay()
        {
            TxtSafeMode.Text = SafeMode.IsEnabled ? "Safe Mode: ON" : "Safe Mode: OFF (危険)";
            ChkSafeMode.IsChecked = SafeMode.IsEnabled;
        }

        private void ChkSafeMode_Changed(object sender, RoutedEventArgs e)
        {
            SafeMode.IsEnabled = ChkSafeMode.IsChecked == true;
            UpdateSafeModeDisplay();
            UpdateReleaseButtonState();
            Log($"Safe Mode: {(SafeMode.IsEnabled ? "有効" : "無効")}");
        }

        // ========== ダッシュボードアクション ==========
        private async void BtnAutoNext_Click(object sender, RoutedEventArgs e)
        {
            var resolution = AutoNextResolver.Resolve(_currentSnapshot!, _registry!);
            if (!resolution.Success)
            {
                MessageBox.Show(resolution.Message, "実行不可", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var entry = _registry!.Find(resolution.EntryId);
            if (entry != null)
            {
                await RunEntryAsync(entry);
            }
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            _executionQueue.Cancel();
            Log("キャンセル要求を送信しました");
        }

        private async void BtnRefreshAll_Click(object sender, RoutedEventArgs e) => await RefreshAllAsync();
        private async void BtnUpdateDashboard_Click(object sender, RoutedEventArgs e) => await RunEntryById("update_dashboard");
        private async void BtnMakeIdePack_Click(object sender, RoutedEventArgs e) => await RunEntryById("make_ide_pack");
        private async void BtnVerify_Click(object sender, RoutedEventArgs e) => await RunEntryById("run_verify");

        private async void BtnRelease_Click(object sender, RoutedEventArgs e)
        {
            // 二段階確認
            if (!_lastVerifyPassed)
            {
                MessageBox.Show("リリースには検証（Verify）の成功が必要です。\n先に検証を実行してください。", 
                    "リリース不可", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var result = MessageBox.Show(
                "本当にリリースを実行しますか？\n\nこの操作は取り消せません。",
                "リリース確認",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (result == MessageBoxResult.Yes)
            {
                await RunEntryById("run_release");
            }
        }

        private async void BtnInsightAction_Click(object sender, RoutedEventArgs e)
        {
            if (BtnInsightAction.Tag is Insight insight)
            {
                if (insight.ActionType == "run_entry")
                {
                    await RunEntryById(insight.ActionTarget);
                }
                else if (insight.ActionType == "open_file")
                {
                    string path = Path.Combine(_oneBoxRoot, insight.ActionTarget);
                    try
                    {
                        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo 
                        { 
                            FileName = path, 
                            UseShellExecute = true 
                        });
                    }
                    catch (Exception ex)
                    {
                        Log($"ファイルを開けません: {ex.Message}");
                    }
                }
            }
        }

        private void ToggleInsightDetails_Changed(object sender, RoutedEventArgs e)
        {
            if (PanelInsightDetails != null)
            {
                PanelInsightDetails.Visibility = ToggleInsightDetails.IsChecked == true ? Visibility.Visible : Visibility.Collapsed;
            }
        }

        private async void BtnCreateTemplate_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var filePath = button?.Tag as string;

            if (string.IsNullOrEmpty(filePath))
            {
                // Fallback: create all missing files
                await CreateAllMissingFilesAsync();
                return;
            }

            // Create single file
            await CreateTemplateFileAsync(filePath);
        }

        private async Task PopulateMissingFilesAsync(string dashboardPath)
        {
            PanelBlockers.Children.Clear();

            if (!File.Exists(dashboardPath))
                return;

            try
            {
                string content = await File.ReadAllTextAsync(dashboardPath);

                // Parse Pass Check section (lines with "- [ ]" and "MISSING")
                var lines = content.Split('\n');
                var missingFiles = new List<string>();

                foreach (var line in lines)
                {
                    // Match pattern: - [ ] path/file.md (MISSING)
                    var match = Regex.Match(line, @"-\s*\[\s*\]\s*([^\(]+)\s*\(MISSING\)");
                    if (match.Success)
                    {
                        var path = match.Groups[1].Value.Trim();
                        missingFiles.Add(path);
                    }
                }

                if (missingFiles.Count == 0)
                {
                    // No missing files but still FAIL? Show generic message
                    var msg = new TextBlock
                    {
                        Text = "問題が検出されましたが、欠損ファイルが特定できませんでした。",
                        TextWrapping = TextWrapping.Wrap,
                        Margin = new Thickness(0, 0, 0, 8)
                    };
                    PanelBlockers.Children.Add(msg);
                    return;
                }

                // Display each missing file
                foreach (var file in missingFiles)
                {
                    var item = new StackPanel
                    {
                        Orientation = Orientation.Horizontal,
                        Margin = new Thickness(0, 0, 0, 8)
                    };

                    item.Children.Add(new TextBlock
                    {
                        Text = "❌",
                        FontSize = 14,
                        Margin = new Thickness(0, 0, 8, 0),
                        VerticalAlignment = VerticalAlignment.Center
                    });

                    item.Children.Add(new TextBlock
                    {
                        Text = Path.GetFileName(file),
                        VerticalAlignment = VerticalAlignment.Center,
                        FontWeight = FontWeights.Medium
                    });

                    item.Children.Add(new TextBlock
                    {
                        Text = $" ({Path.GetDirectoryName(file)})",
                        VerticalAlignment = VerticalAlignment.Center,
                        Foreground = Brushes.Gray,
                        FontSize = 12
                    });

                    var btnCreate = new Button
                    {
                        Content = "作成",
                        Tag = file,
                        Margin = new Thickness(8, 0, 0, 0),
                        Padding = new Thickness(12, 4, 12, 4),
                        VerticalAlignment = VerticalAlignment.Center
                    };
                    btnCreate.SetResourceReference(Button.StyleProperty, "ButtonSecondary");
                    btnCreate.Click += BtnCreateTemplate_Click;
                    item.Children.Add(btnCreate);

                    PanelBlockers.Children.Add(item);
                }

                // Add "Create All" button if multiple files
                if (missingFiles.Count > 1)
                {
                    var btnAll = new Button
                    {
                        Content = $"すべて作成 ({missingFiles.Count}個)",
                        Margin = new Thickness(0, 12, 0, 0),
                        Padding = new Thickness(16, 8, 16, 8)
                    };
                    btnAll.SetResourceReference(Button.StyleProperty, "ButtonPrimary");
                    btnAll.Click += BtnCreateTemplate_Click; // Tag is null, triggers CreateAllMissingFilesAsync
                    PanelBlockers.Children.Add(btnAll);
                }
            }
            catch (Exception ex)
            {
                Log($"欠損ファイルパースエラー: {ex.Message}");
            }
        }

        private async Task CreateTemplateFileAsync(string relativePath)
        {
            try
            {
                var fullPath = Path.Combine(_oneBoxRoot, "PROJECTS", _currentSnapshot?.ActiveProject ?? "", relativePath);
                var directory = Path.GetDirectoryName(fullPath);

                if (!Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory!);
                    Log($"ディレクトリ作成: {directory}");
                }

                // Determine template content
                var template = GetTemplateContent(Path.GetFileName(fullPath));

                // Write file (UTF-8 without BOM)
                await File.WriteAllTextAsync(fullPath, template, new System.Text.UTF8Encoding(false));

                Log($"テンプレート作成: {relativePath}");
                MessageBox.Show($"作成しました: {Path.GetFileName(fullPath)}", "完了", MessageBoxButton.OK, MessageBoxImage.Information);

                // Refresh dashboard
                await RefreshAllAsync();
            }
            catch (Exception ex)
            {
                Log($"テンプレート作成エラー: {ex.Message}");
                MessageBox.Show($"作成に失敗しました: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async Task CreateAllMissingFilesAsync()
        {
            try
            {
                string dashPath = Path.Combine(_oneBoxRoot, "VAULT", "VIBE_DASHBOARD.md");
                if (!File.Exists(dashPath))
                    return;

                string content = await File.ReadAllTextAsync(dashPath);
                var lines = content.Split('\n');
                var missingFiles = new List<string>();

                foreach (var line in lines)
                {
                    var match = Regex.Match(line, @"-\s*\[\s*\]\s*([^\(]+)\s*\(MISSING\)");
                    if (match.Success)
                    {
                        missingFiles.Add(match.Groups[1].Value.Trim());
                    }
                }

                if (missingFiles.Count == 0)
                {
                    MessageBox.Show("欠損ファイルがありません", "情報", MessageBoxButton.OK, MessageBoxImage.Information);
                    return;
                }

                int created = 0;
                foreach (var file in missingFiles)
                {
                    await CreateTemplateFileAsync(file);
                    created++;
                }

                MessageBox.Show($"{created}個のファイルを作成しました", "完了", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                Log($"一括作成エラー: {ex.Message}");
                MessageBox.Show($"エラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private string GetTemplateContent(string filename)
        {
            // Return appropriate template based on filename
            if (filename.Contains("DECISIONS"))
            {
                return @"# 設計判断

## アーキテクチャ判断
- TBD

## 技術選定
- TBD

## 懸念事項
- TBD
";
            }
            else if (filename.Contains("ACCEPTANCE"))
            {
                return @"# 受入条件

## 機能要件
- [ ] 要件1

## 非機能要件
- [ ] パフォーマンス
- [ ] セキュリティ

## テストシナリオ
- TBD
";
            }
            else if (filename.Contains("SPEC"))
            {
                return @"# 仕様書

## 概要
TBD

## 詳細仕様
TBD

## 制約事項
TBD
";
            }
            else
            {
                return $@"# {Path.GetFileNameWithoutExtension(filename)}

作成日: {DateTime.Now:yyyy-MM-dd}

## 内容

TBD
";
            }
        }

        // ========== DataOps ==========
        private async void BtnDataOpsCatalog_Click(object sender, RoutedEventArgs e)
        {
            BorderDataOpsProgress.Visibility = Visibility.Visible;
            TxtDataOpsProgressLabel.Text = "カタログ作成中...";

            await RunEntryById("run_db_catalog");

            BorderDataOpsProgress.Visibility = Visibility.Collapsed;
            await ShowDataOpsResultAsync("VAULT/DATAOPS/DB_CATALOG.md");
        }

        private async void BtnDataOpsReq_Click(object sender, RoutedEventArgs e) => await RunEntryById("run_dataops_tool_req");

        private async void BtnDataOpsMap_Click(object sender, RoutedEventArgs e)
        {
            await RunEntryById("run_dataops_map");
            var toolId = _currentSnapshot?.ActiveProject;
            if (!string.IsNullOrEmpty(toolId))
            {
                await ShowDataOpsResultAsync($"PROJECTS/{toolId}/DATA_MAP.md");
            }
        }

        private async void BtnDataOpsExtract_Click(object sender, RoutedEventArgs e) => await RunEntryById("run_dataops_extract");
        private async void BtnDataOpsPack_Click(object sender, RoutedEventArgs e) => await RunEntryById("run_dataops_pack");

        private async void BtnDataOpsQa_Click(object sender, RoutedEventArgs e)
        {
            await RunEntryById("run_dataops_qa");
            var toolId = _currentSnapshot?.ActiveProject;
            if (!string.IsNullOrEmpty(toolId))
            {
                await ShowDataOpsResultAsync($"PROJECTS/{toolId}/DATA_QA/qa_report.md");
            }
        }

        private void BtnDataOpsCancel_Click(object sender, RoutedEventArgs e)
        {
            _executionQueue.Cancel();
            BorderDataOpsProgress.Visibility = Visibility.Collapsed;
        }

        private async Task ShowDataOpsResultAsync(string relativePath)
        {
            var path = Path.Combine(_oneBoxRoot, relativePath);
            if (File.Exists(path))
            {
                var content = await File.ReadAllTextAsync(path);
                TxtDataOpsResult.Text = content;

                // Generate summary
                var fileInfo = new FileInfo(path);
                var lines = content.Split('\n').Length;
                var sizeKb = Math.Round(fileInfo.Length / 1024.0, 2);
                var summary = $"📄 {Path.GetFileName(relativePath)} | {lines} 行 | {sizeKb} KB | 更新: {fileInfo.LastWriteTime:yyyy-MM-dd HH:mm}";

                // Count specific patterns if it's a QA report
                if (relativePath.Contains("qa_report"))
                {
                    var passCount = System.Text.RegularExpressions.Regex.Matches(content, @"✅|PASS|OK", System.Text.RegularExpressions.RegexOptions.IgnoreCase).Count;
                    var failCount = System.Text.RegularExpressions.Regex.Matches(content, @"❌|FAIL|ERROR", System.Text.RegularExpressions.RegexOptions.IgnoreCase).Count;
                    summary += $" | ✅ {passCount} / ❌ {failCount}";
                }

                TxtDataOpsSummary.Text = summary;
                StackDataOpsSummary.Visibility = Visibility.Visible;
                ExpanderDataOpsResult.IsExpanded = true;
            }
            else
            {
                TxtDataOpsResult.Text = $"ファイルが見つかりません: {relativePath}";
                TxtDataOpsSummary.Text = "ℹ ファイル未生成";
                StackDataOpsSummary.Visibility = Visibility.Visible;
            }
        }

        private void BtnBrowseDbPath_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new System.Windows.Forms.FolderBrowserDialog
            {
                Description = "データベースフォルダを選択"
            };
            if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                TxtDbPath.Text = dialog.SelectedPath;
            }
        }

        private async void BtnSaveDbPath_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var configPath = Path.Combine(_oneBoxRoot, "VAULT", "DATAOPS", "DATAOPS_CONFIG.json");
                var config = $"{{ \"db_path\": \"{TxtDbPath.Text.Replace("\\", "\\\\")}\" }}";

                if (_backupManager != null)
                {
                    await _backupManager.AtomicWriteAsync(configPath, config);
                    Log($"DBパス保存完了: {TxtDbPath.Text}");
                    MessageBox.Show("保存しました", "完了", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
            catch (Exception ex)
            {
                Log($"DBパス保存エラー: {ex.Message}");
                MessageBox.Show($"保存エラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        // ========== シークレット ==========
        private async void BtnRefreshSecrets_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var secrets = new System.Collections.ObjectModel.ObservableCollection<SecretDisplayItem>();
                var keys = _secretsVault!.GetAllKeys();

                foreach (var key in keys)
                {
                    var meta = _secretsVault.GetSecretMetadata(key);
                    if (meta != null)
                    {
                        secrets.Add(new SecretDisplayItem
                        {
                            Category = GetSecretCategory(key),
                            Key = key,
                            Description = meta.Description,
                            UpdatedAt = meta.UpdatedAt
                        });
                    }
                }

                GridSecrets.ItemsSource = secrets;

                // Show/hide empty state
                if (secrets.Count == 0)
                {
                    BorderSecretsEmptyState.Visibility = Visibility.Visible;
                    BorderSecretsGrid.Visibility = Visibility.Collapsed;
                }
                else
                {
                    BorderSecretsEmptyState.Visibility = Visibility.Collapsed;
                    BorderSecretsGrid.Visibility = Visibility.Visible;
                }

                Log($"シークレット更新: {secrets.Count}件");
            }
            catch (Exception ex)
            {
                Log($"シークレット取得エラー: {ex.Message}");
            }
        }

        private string GetSecretCategory(string key)
        {
            if (key.StartsWith("openai.") || key.StartsWith("anthropic.")) return "プロバイダー";
            if (key.StartsWith("lmstudio.") || key.StartsWith("ollama.")) return "ローカルLLM";
            if (key.StartsWith("mcp.")) return "MCP";
            return "その他";
        }

        private void BtnSaveLmStudioUrl_Click(object sender, RoutedEventArgs e)
        {
             // TODO: Save to config
             MessageBox.Show($"LM Studio URL ({TxtLmStudioUrl.Text}) を保存しました（シミュレーション）。", "保存完了", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void BtnSaveOllamaUrl_Click(object sender, RoutedEventArgs e)
        {
             // TODO: Save to config
             MessageBox.Show($"Ollama URL ({TxtOllamaUrl.Text}) を保存しました（シミュレーション）。", "保存完了", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private async void BtnAddSecret_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new SecretInputDialog { Owner = this };
            if (dialog.ShowDialog() == true)
            {
                try
                {
                    await _secretsVault!.SetSecretAsync(dialog.SecretKey, dialog.SecretValue, dialog.SecretDescription);
                    Log($"シークレット保存: {dialog.SecretKey}");
                    BtnRefreshSecrets_Click(sender, e);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"保存エラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private async void BtnViewSecret_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var key = button?.Tag as string;
            if (key == null) return;

            try
            {
                var value = await _secretsVault!.GetSecretAsync(key);
                MessageBox.Show($"キー: {key}\n\n値: {value}", "シークレット値", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"取得エラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void BtnCopySecret_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var key = button?.Tag as string;
            if (key == null) return;

            try
            {
                var value = await _secretsVault!.GetSecretAsync(key);
                if (value != null)
                {
                    Clipboard.SetText(value);
                    Log($"シークレットをコピー: {key} (30秒後に自動クリア)");

                    // 30秒後に自動クリア
                    _ = Task.Run(async () =>
                    {
                        await Task.Delay(30000);
                        await Dispatcher.InvokeAsync(() =>
                        {
                            try
                            {
                                if (Clipboard.GetText() == value)
                                {
                                    Clipboard.Clear();
                                    Log("クリップボード自動クリア完了");
                                }
                            }
                            catch { }
                        });
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"コピーエラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void BtnDeleteSecret_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var key = button?.Tag as string;
            if (key == null) return;

            var result = MessageBox.Show($"シークレット '{key}' を削除しますか？\n\nこの操作は取り消せません。", 
                "削除確認", MessageBoxButton.YesNo, MessageBoxImage.Warning);
            if (result == MessageBoxResult.Yes)
            {
                try
                {
                    await _secretsVault!.DeleteSecretAsync(key);
                    Log($"シークレット削除: {key}");
                    BtnRefreshSecrets_Click(sender, e);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"削除エラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        // ========== プロバイダー ==========
        private async void BtnRefreshProviders_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                PanelProviders.Children.Clear();
                var stats = await _providerTelemetry!.GetAllStatsAsync();

                foreach (var kvp in stats)
                {
                    var providerName = kvp.Key;
                    var stat = kvp.Value;
                    var circuitState = await _providerTelemetry.GetCircuitStateAsync(providerName);

                    var border = new Border
                    {
                        Style = FindResource("Card") as Style,
                        Margin = new Thickness(0, 0, 0, 12)
                    };

                    var panel = new StackPanel();

                    panel.Children.Add(new TextBlock
                    {
                        Text = providerName.ToUpper(),
                        FontWeight = FontWeights.SemiBold,
                        FontSize = 15,
                        Foreground = FindResource("TextPrimary") as SolidColorBrush,
                        Margin = new Thickness(0, 0, 0, 10)
                    });

                    panel.Children.Add(new TextBlock
                    {
                        Text = $"成功率: {stat.SuccessRatePercent}% ({stat.SuccessCount}/{stat.TotalRequests})",
                        Foreground = FindResource("TextSecondary") as SolidColorBrush,
                        FontSize = 13
                    });

                    panel.Children.Add(new TextBlock
                    {
                        Text = $"レート制限: {stat.RateLimitCount}回",
                        Foreground = FindResource("TextSecondary") as SolidColorBrush,
                        FontSize = 13
                    });

                    var stateColor = circuitState == CircuitState.Open 
                        ? FindResource("StatusError") as SolidColorBrush 
                        : FindResource("StatusSuccess") as SolidColorBrush;

                    var stateIcon = circuitState == CircuitState.Open ? "🔴" : "🟢";

                    panel.Children.Add(new TextBlock
                    {
                        Text = $"状態: {stateIcon} {(circuitState == CircuitState.Open ? "停止中 (Circuit Open)" : "正常 (Circuit Closed)")}",
                        Foreground = stateColor,
                        FontSize = 13,
                        FontWeight = FontWeights.Medium,
                        Margin = new Thickness(0, 4, 0, 0)
                    });

                    // 最終成功/失敗日時
                    if (stat.LastSuccessAt != DateTime.MinValue)
                    {
                        panel.Children.Add(new TextBlock
                        {
                            Text = $"最終成功: {stat.LastSuccessAt:MM/dd HH:mm:ss}",
                            Foreground = Brushes.Gray,
                            FontSize = 11,
                            Margin = new Thickness(0, 2, 0, 0)
                        });
                    }

                    if (stat.LastFailureAt != DateTime.MinValue)
                    {
                        panel.Children.Add(new TextBlock
                        {
                            Text = $"最終失敗: {stat.LastFailureAt:MM/dd HH:mm:ss} ({stat.LastError})",
                            Foreground = FindResource("AccentOrange") as SolidColorBrush,
                            FontSize = 11,
                            TextWrapping = TextWrapping.Wrap,
                            Margin = new Thickness(0, 2, 0, 0)
                        });
                    }

                    if (stat.LastRateLimitAt != DateTime.MinValue)
                    {
                        var resetEstimate = stat.LastRateLimitAt.AddMinutes(1);
                        panel.Children.Add(new TextBlock
                        {
                            Text = $"⚠ レート制限: {stat.LastRateLimitAt:HH:mm:ss} (復旧予測: ~{resetEstimate:HH:mm:ss})",
                            Foreground = FindResource("AccentOrange") as SolidColorBrush,
                            FontSize = 12,
                            FontWeight = FontWeights.Bold,
                            Margin = new Thickness(0, 8, 0, 0)
                        });

                        // 切り替え提案ボタン
                        var btnSwitch = new Button
                        {
                            Content = "別プロバイダーに切替",
                            Style = FindResource("ButtonSecondary") as Style,
                            Margin = new Thickness(0, 8, 0, 0),
                            Padding = new Thickness(10, 5, 10, 5)
                        };
                        panel.Children.Add(btnSwitch);
                    }

                    // 成功率0%警告
                    if (stat.TotalRequests > 0 && stat.SuccessRatePercent == 0)
                    {
                        panel.Children.Add(new Border
                        {
                            Background = new SolidColorBrush(Color.FromRgb(255, 235, 238)),
                            CornerRadius = new CornerRadius(4),
                            Padding = new Thickness(8),
                            Margin = new Thickness(0, 8, 0, 0),
                            Child = new TextBlock
                            {
                                Text = "⚠️ 成功率0%: APIキーや設定を確認してください",
                                Foreground = Brushes.Red,
                                FontSize = 12,
                                TextWrapping = TextWrapping.Wrap
                            }
                        });
                    }

                    border.Child = panel;
                    PanelProviders.Children.Add(border);
                }

                if (stats.Count == 0)
                {
                    PanelProviders.Children.Add(new TextBlock
                    {
                        Text = "プロバイダー情報がありません。API呼び出しを行うと表示されます。",
                        Foreground = FindResource("TextMuted") as SolidColorBrush,
                        FontSize = 13
                    });
                }

                Log($"プロバイダー状態更新: {stats.Count}件");
            }
            catch (Exception ex)
            {
                Log($"プロバイダー取得エラー: {ex.Message}");
            }
        }

        // ========== ローカルLLM ==========
        private async void BtnLmStudioHealth_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                TxtLocalLlmLog.AppendText("[LM Studio] ヘルスチェック中...\n");
                var health = await _localLlm!.CheckHealthAsync("lmstudio");

                TxtLmStudioStatus.Text = health.IsHealthy
                    ? $"状態: 正常 ({health.ResponseTimeMs}ms)"
                    : $"状態: 異常 - {health.Message}";

                TxtLmStudioStatus.Foreground = health.IsHealthy
                    ? FindResource("StatusSuccess") as SolidColorBrush
                    : FindResource("StatusError") as SolidColorBrush;

                TxtLocalLlmLog.AppendText($"[LM Studio] {health.Message} ({health.ResponseTimeMs}ms)\n");
            }
            catch (Exception ex)
            {
                TxtLocalLlmLog.AppendText($"[LM Studio] エラー: {ex.Message}\n");
            }
        }

        private async void BtnOllamaHealth_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                TxtLocalLlmLog.AppendText("[Ollama] ヘルスチェック中...\n");
                var health = await _localLlm!.CheckHealthAsync("ollama");

                TxtOllamaStatus.Text = health.IsHealthy
                    ? $"状態: 正常 ({health.ResponseTimeMs}ms)"
                    : $"状態: 異常 - {health.Message}";

                TxtOllamaStatus.Foreground = health.IsHealthy
                    ? FindResource("StatusSuccess") as SolidColorBrush
                    : FindResource("StatusError") as SolidColorBrush;

                TxtLocalLlmLog.AppendText($"[Ollama] {health.Message} ({health.ResponseTimeMs}ms)\n");
            }
            catch (Exception ex)
            {
                TxtLocalLlmLog.AppendText($"[Ollama] エラー: {ex.Message}\n");
            }
        }

        private async void BtnLmStudioTest_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                // Update provider URL from UI
                var customUrl = TxtLmStudioUrl.Text.Trim();
                if (string.IsNullOrEmpty(customUrl))
                {
                    customUrl = "http://localhost:1234/v1";
                }

                var providerConfig = new LlmProviderConfig
                {
                    Type = LlmProviderType.LmStudio,
                    Name = "lmstudio",
                    BaseUrl = customUrl,
                    Model = "local-model",
                    IsLocal = true
                };
                _localLlm!.AddOrUpdateProvider(providerConfig);

                TxtLmStudioStatus.Text = "状態: 接続テスト中...";
                TxtLocalLlmLog.AppendText($"[LM Studio] 接続テスト開始: {customUrl}\n");

                // Health check first
                var healthResult = await _localLlm.CheckHealthAsync("lmstudio");

                if (!healthResult.IsHealthy)
                {
                    var diagnostic = DiagnoseConnectionError(healthResult.Message, customUrl);
                    TxtLmStudioStatus.Text = $"状態: ❌ {diagnostic.Category}";
                    TxtLocalLlmLog.AppendText($"[LM Studio] 接続失敗\n");
                    TxtLocalLlmLog.AppendText($"  エラー: {healthResult.Message}\n");
                    TxtLocalLlmLog.AppendText($"  診断: {diagnostic.Diagnosis}\n");
                    TxtLocalLlmLog.AppendText($"  対処法:\n{diagnostic.Suggestion}\n");
                    return;
                }

                TxtLocalLlmLog.AppendText($"[LM Studio] 接続成功 ({healthResult.ResponseTimeMs}ms)\n");
                TxtLocalLlmLog.AppendText("[LM Studio] テストプロンプト送信中...\n");

                var request = new LlmRequest { Prompt = "VIBEワークフローを一文で説明してください。", MaxTokens = 100 };
                var response = await _localLlm.CallAsync("lmstudio", request);

                if (response.Success)
                {
                    TxtLmStudioStatus.Text = "状態: ✅ 正常動作";
                    TxtLocalLlmLog.AppendText($"[LM Studio] 応答: {response.ResponseText}\n");
                    TxtLocalLlmLog.AppendText($"[LM Studio] トークン数: {response.TokensUsed}\n");
                }
                else
                {
                    TxtLmStudioStatus.Text = "状態: ⚠ 接続OK / 応答エラー";
                    TxtLocalLlmLog.AppendText($"[LM Studio] エラー: {response.ErrorMessage}\n");
                }
            }
            catch (Exception ex)
            {
                TxtLmStudioStatus.Text = "状態: ❌ 例外発生";
                TxtLocalLlmLog.AppendText($"[LM Studio] 例外: {ex.Message}\n");
            }
        }

        private async void BtnOllamaTest_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                // Update provider URL from UI
                var customUrl = TxtOllamaUrl.Text.Trim();
                if (string.IsNullOrEmpty(customUrl))
                {
                    customUrl = "http://localhost:11434";
                }

                var providerConfig = new LlmProviderConfig
                {
                    Type = LlmProviderType.Ollama,
                    Name = "ollama",
                    BaseUrl = customUrl,
                    Model = "llama2",
                    IsLocal = true
                };
                _localLlm!.AddOrUpdateProvider(providerConfig);

                TxtOllamaStatus.Text = "状態: 接続テスト中...";
                TxtLocalLlmLog.AppendText($"[Ollama] 接続テスト開始: {customUrl}\n");

                // Health check first
                var healthResult = await _localLlm.CheckHealthAsync("ollama");

                if (!healthResult.IsHealthy)
                {
                    var diagnostic = DiagnoseConnectionError(healthResult.Message, customUrl);
                    TxtOllamaStatus.Text = $"状態: ❌ {diagnostic.Category}";
                    TxtLocalLlmLog.AppendText($"[Ollama] 接続失敗\n");
                    TxtLocalLlmLog.AppendText($"  エラー: {healthResult.Message}\n");
                    TxtLocalLlmLog.AppendText($"  診断: {diagnostic.Diagnosis}\n");
                    TxtLocalLlmLog.AppendText($"  対処法:\n{diagnostic.Suggestion}\n");
                    return;
                }

                TxtLocalLlmLog.AppendText($"[Ollama] 接続成功 ({healthResult.ResponseTimeMs}ms)\n");
                TxtLocalLlmLog.AppendText("[Ollama] テストプロンプト送信中...\n");

                var request = new LlmRequest { Prompt = "VIBEワークフローを一文で説明してください。", MaxTokens = 100 };
                var response = await _localLlm.CallAsync("ollama", request);

                if (response.Success)
                {
                    TxtOllamaStatus.Text = "状態: ✅ 正常動作";
                    TxtLocalLlmLog.AppendText($"[Ollama] 応答: {response.ResponseText}\n");
                    TxtLocalLlmLog.AppendText($"[Ollama] トークン数: {response.TokensUsed}\n");
                }
                else
                {
                    TxtOllamaStatus.Text = "状態: ⚠ 接続OK / 応答エラー";
                    TxtLocalLlmLog.AppendText($"[Ollama] エラー: {response.ErrorMessage}\n");
                }
            }
            catch (Exception ex)
            {
                TxtOllamaStatus.Text = "状態: ❌ 例外発生";
                TxtLocalLlmLog.AppendText($"[Ollama] 例外: {ex.Message}\n");
            }
        }

        private void BtnCopyLmStudioUrl_Click(object sender, RoutedEventArgs e)
        {
            Clipboard.SetText(TxtLmStudioUrl.Text);
            Log("URLをコピーしました");
        }

        private void BtnOpenLmStudioWeb_Click(object sender, RoutedEventArgs e)
        {
            try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo { FileName = "http://localhost:1234", UseShellExecute = true }); } catch { }
        }

        private void BtnCopyOllamaUrl_Click(object sender, RoutedEventArgs e)
        {
            Clipboard.SetText(TxtOllamaUrl.Text);
            Log("URLをコピーしました");
        }

        private void BtnOpenOllamaWeb_Click(object sender, RoutedEventArgs e)
        {
            try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo { FileName = "http://localhost:11434", UseShellExecute = true }); } catch { }
        }

        /// <summary>
        /// 接続エラーを診断して、わかりやすいメッセージと対処法を返す
        /// </summary>
        private (string Category, string Diagnosis, string Suggestion) DiagnoseConnectionError(string errorMessage, string url)
        {
            var lowerError = errorMessage.ToLower();

            // Connection refused
            if (lowerError.Contains("refused") || lowerError.Contains("actively refused"))
            {
                return (
                    "接続拒否",
                    "指定されたポートでサービスが起動していません",
                    "  1. LM Studio/Ollamaが起動しているか確認\n" +
                    "  2. ポート番号が正しいか確認（LM Studio: 1234, Ollama: 11434）\n" +
                    "  3. LM Studioの場合、Server機能が有効になっているか確認"
                );
            }

            // Timeout
            if (lowerError.Contains("timeout") || lowerError.Contains("timed out"))
            {
                return (
                    "タイムアウト",
                    "サービスが応答しません（起動中または過負荷）",
                    "  1. サービスが完全に起動するまで待つ（特にOllama初回起動）\n" +
                    "  2. CPU/メモリ使用率を確認（タスクマネージャー）\n" +
                    "  3. 他のアプリケーションを終了してリソースを空ける"
                );
            }

            // DNS/URL invalid
            if (lowerError.Contains("host") || lowerError.Contains("dns") || lowerError.Contains("resolve"))
            {
                return (
                    "URL/DNS不正",
                    "ホスト名が解決できません",
                    "  1. URLが正しいか確認（例: http://localhost:1234）\n" +
                    "  2. localhostの代わりに127.0.0.1を試す\n" +
                    "  3. URLにスペースや全角文字が含まれていないか確認"
                );
            }

            // 404 Not Found
            if (lowerError.Contains("404") || lowerError.Contains("not found"))
            {
                return (
                    "エンドポイント不正",
                    "指定されたURLパスが存在しません",
                    "  1. LM Studioの場合: http://localhost:1234/v1 で試す\n" +
                    "  2. Ollamaの場合: http://localhost:11434 で試す\n" +
                    "  3. Base URLの末尾に不要な/api/等が含まれていないか確認"
                );
            }

            // Generic network error
            if (lowerError.Contains("network") || lowerError.Contains("socket"))
            {
                return (
                    "ネットワークエラー",
                    "ネットワーク接続に問題があります",
                    "  1. ファイアウォール設定を確認\n" +
                    "  2. ウイルス対策ソフトがポートをブロックしていないか確認\n" +
                    "  3. Windowsの場合、Windows Defender Firewallの設定を確認"
                );
            }

            // Unknown error
            return (
                "不明なエラー",
                errorMessage,
                "  1. エラーメッセージを確認して原因を特定\n" +
                "  2. LM Studio/Ollamaのログを確認\n" +
                "  3. サービスを再起動してみる"
            );
        }

        // ========== MCP ==========
        private async void BtnRefreshMcpStatus_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                var statuses = await _mcpManager!.GetAllStatusAsync();
                GridMcpServers.ItemsSource = statuses;
                Log($"MCPサーバー状態更新: {statuses.Count}件");
            }
            catch (Exception ex)
            {
                Log($"MCP取得エラー: {ex.Message}");
            }
        }

        private async void BtnAddMcpServer_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new McpServerInputDialog { Owner = this };
            if (dialog.ShowDialog() == true)
            {
                try
                {
                    await _mcpManager!.AddOrUpdateServerAsync(dialog.ServerConfig);
                    Log($"MCPサーバー追加: {dialog.ServerConfig.Name}");
                    BtnRefreshMcpStatus_Click(sender, e);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"追加エラー: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private async void BtnStartAutoStartServers_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                await _mcpManager!.StartAutoStartServersAsync();
                Log("AutoStart MCPサーバー起動完了");
                BtnRefreshMcpStatus_Click(sender, e);
            }
            catch (Exception ex)
            {
                Log($"AutoStartエラー: {ex.Message}");
            }
        }

        private async void BtnStartMcpServer_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var name = button?.Tag as string;
            if (name == null) return;

            try
            {
                var success = await _mcpManager!.StartServerAsync(name);
                Log(success ? $"MCPサーバー起動: {name}" : $"起動失敗: {name}");
                BtnRefreshMcpStatus_Click(sender, e);
            }
            catch (Exception ex)
            {
                Log($"起動エラー: {ex.Message}");
            }
        }

        private async void BtnStopMcpServer_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var name = button?.Tag as string;
            if (name == null) return;

            try
            {
                var success = await _mcpManager!.StopServerAsync(name);
                Log(success ? $"MCPサーバー停止: {name}" : $"停止失敗: {name}");
                BtnRefreshMcpStatus_Click(sender, e);
            }
            catch (Exception ex)
            {
                Log($"停止エラー: {ex.Message}");
            }
        }

        private async void BtnRestartMcpServer_Click(object sender, RoutedEventArgs e)
        {
            var button = sender as Button;
            var name = button?.Tag as string;
            if (name == null) return;

            try
            {
                var success = await _mcpManager!.RestartServerAsync(name);
                Log(success ? $"MCPサーバー再起動: {name}" : $"再起動失敗: {name}");
                BtnRefreshMcpStatus_Click(sender, e);
            }
            catch (Exception ex)
            {
                Log($"再起動エラー: {ex.Message}");
            }
        }

        private async void GridMcpServers_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (GridMcpServers.SelectedItem is McpServerStatus status)
            {
                try
                {
                    var (stdout, stderr) = await _mcpManager!.GetServerLogsAsync(status.Name);
                    TxtMcpLogs.Text = $"=== 標準出力 ===\n{stdout}\n\n=== 標準エラー ===\n{stderr}";
                }
                catch (Exception ex)
                {
                    TxtMcpLogs.Text = $"ログ取得エラー: {ex.Message}";
                }
            }
        }

        // ========== ログ ==========
        private void Log(string message)
        {
            Dispatcher.Invoke(() =>
            {
                TxtConsole.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}\n");
                TxtConsole.ScrollToEnd();
            });
        }

        // ========== クリーンアップ ==========
        private void MainWindow_Closing(object? sender, System.ComponentModel.CancelEventArgs e)
        {
            if (_watcher != null)
            {
                _watcher.EnableRaisingEvents = false;
                _watcher.Dispose();
            }

            _mcpManager?.StopAllServersAsync().Wait();
            _executionQueue.Reset();
        }
    }

    // ========== ヘルパークラス ==========
    public class SecretDisplayItem
    {
        public string Category { get; set; } = "";
        public string Key { get; set; } = "";
        public string Description { get; set; } = "";
        public DateTime UpdatedAt { get; set; }
    }

    public class RunHistoryItem
    {
        public string DisplayName { get; set; } = "";
        public bool Success { get; set; }
        public int DurationMs { get; set; }
        public DateTime Timestamp { get; set; }
    }
}
```

---

## OneScreenOSApp.csproj
# 13 OneScreenOSApp.csproj（全文）

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <UseWindowsForms>true</UseWindowsForms>
    <Nullable>enable</Nullable>
    <!-- <ApplicationIcon>app.ico</ApplicationIcon> -->
    <AssemblyName>OneScreenOSApp</AssemblyName>
    <RootNamespace>OneScreenOSApp</RootNamespace>

    <!-- Single File Publish Settings -->
    <PublishSingleFile>true</PublishSingleFile>
    <SelfContained>true</SelfContained>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
    <PublishTrimmed>false</PublishTrimmed>
    <IncludeNativeLibrariesForSelfExtract>true</IncludeNativeLibrariesForSelfExtract>
  </PropertyGroup>

  <ItemGroup>
    <!-- WinForms for NotifyIcon -->
    <PackageReference Include="Microsoft.Web.WebView2" Version="1.0.3650.58" />
    <PackageReference Include="System.Drawing.Common" Version="8.0.0" />
  </ItemGroup>

  <ItemGroup>
    <Reference Include="System.Windows.Forms" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\RunnerCore\RunnerCore.csproj" />
  </ItemGroup>

</Project>
```


---


---

## 08_PATCHES.md (verbatim)

# PATCHES（既知の差し替えパッチ）
## ToggleSecondary Style
# 07 パッチ（App.xaml）: ToggleSecondary を追加

## 目的
ToggleButton が Button用Styleを参照してクラッシュするのを防ぐため、
ToggleButton専用Style（TargetType=ToggleButton）を用意します。

## 適用先
`APP\OneScreenOSApp\App.xaml`

## 追加するStyle（例：最小構成）
> 既存の `ButtonBaseSecondary` / `ButtonSecondary` の設計に合わせて調整してOK。

```xml
<!-- ToggleButton 用 -->
<Style x:Key="ToggleSecondary"
       TargetType="{x:Type ToggleButton}"
       BasedOn="{StaticResource ButtonBaseSecondary}">
  <Style.Triggers>
    <Trigger Property="IsChecked" Value="True">
      <Setter Property="Background" Value="#2E3440"/>
      <Setter Property="Foreground" Value="White"/>
    </Trigger>
  </Style.Triggers>
</Style>
```

## 注意
- `BasedOn` に `ButtonBaseSecondary` を使えば Button/Toggle 共通の見た目が揃います
- Checked時だけ Toggle固有で上書きします

---

---

## ToggleInsightDetails Reference
# 08 パッチ（MainWindow.xaml）: ToggleInsightDetails のStyle差し替え

## 適用先
`APP\OneScreenOSApp\MainWindow.xaml`

## 対象
`x:Name="ToggleInsightDetails"` の ToggleButton

## 修正
```xml
<ToggleButton x:Name="ToggleInsightDetails"
              Style="{StaticResource ToggleSecondary}"
              ... />
```

---


---


---

## 09_SCRIPTS_FULL.md (verbatim)

# SCRIPTS_FULL（PowerShell/運用スクリプト全文）
## build_publish.ps1
# 14 build_publish.ps1（全文）

```powershell
# build_publish.ps1
# Purpose: Build and publish OneScreenOSApp to dist folder
# Usage: .\build_publish.ps1
#
# ULTRASYNC MASTER v4.x.x ENHANCEMENTS:
# - UTF-8 BOM-less log output to VAULT\06_LOGS
# - Non-interactive (no Read-Host)
# - Automatic timestamp logging

param(
    [string]$Configuration = "Release",
    [switch]$NoPause
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Determine OneBoxRoot
$ScriptRoot = Split-Path -Parent $PSCommandPath
$VIBECtrlRoot = Split-Path -Parent $ScriptRoot
$CoreRoot = Split-Path -Parent $VIBECtrlRoot
$OneBoxRoot = Split-Path -Parent $CoreRoot

$ProjectPath = Join-Path $OneBoxRoot "APP\OneScreenOSApp\OneScreenOSApp.csproj"
$OutputDir = Join-Path $OneBoxRoot "APP\dist"

# Setup logging
$LogDir = Join-Path $OneBoxRoot "VAULT\06_LOGS"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "build_publish_$Timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamped = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $timestamped -Encoding UTF8
}

Write-Log "=== VIBE One Screen OS Build ===" -Color Cyan
Write-Log "Log: $LogFile" -Color Gray
Write-Log "OneBoxRoot: $OneBoxRoot"
Write-Log "Project: $ProjectPath"
Write-Log "Output: $OutputDir"
Write-Log "Configuration: $Configuration"
Write-Log ""

# Check dotnet
try {
    $dotnetVersion = dotnet --version
    Write-Log "✓ .NET SDK: $dotnetVersion" -Color Green
} catch {
    Write-Log "[ERROR] .NET SDK not found. Please install .NET 8.0 SDK or later." -Color Red
    exit 1
}

# Check project
if (-not (Test-Path $ProjectPath)) {
    Write-Log "[ERROR] Project file not found: $ProjectPath" -Color Red
    exit 1
}

# Clean previous output
if (Test-Path $OutputDir) {
    Write-Log "Cleaning previous build output..." -Color Yellow
    Remove-Item "$OutputDir\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# Build and publish
Write-Log ""
Write-Log "Building project..." -Color Yellow
Write-Log ""

$buildArgs = @(
    "publish"
    $ProjectPath
    "-c", $Configuration
    "-r", "win-x64"
    "--self-contained", "false"
    "-o", $OutputDir
    "/p:PublishSingleFile=true"
    "/p:IncludeNativeLibrariesForSelfExtract=true"
)

$process = Start-Process -FilePath "dotnet" -ArgumentList $buildArgs -NoNewWindow -Wait -PassThru

Write-Log ""

if ($process.ExitCode -eq 0) {
    Write-Log "=== Build Success ===" -Color Green

    # Check output
    $exePath = Join-Path $OutputDir "OneScreenOSApp.exe"
    if (Test-Path $exePath) {
        $exeSize = (Get-Item $exePath).Length / 1MB
        $exeTimestamp = (Get-Item $exePath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Log "✓ OneScreenOSApp.exe created ($([math]::Round($exeSize, 2)) MB)" -Color Green
        Write-Log "  Location: $exePath"
        Write-Log "  Updated: $exeTimestamp"
    } else {
        Write-Log "[WARN] Build succeeded but .exe not found at expected location" -Color Yellow
    }

    Write-Log ""
    Write-Log "[NEXT STEPS]" -Color Cyan
    Write-Log "1. Test launch: .\LAUNCH_ONE_SCREEN_OS.cmd"
    Write-Log "2. Or use desktop shortcut: VIBE One Screen OS"
    Write-Log "3. Run selftest: .\CORE\VIBE_CTRL\scripts\selftest_launch_enhanced.ps1"
    Write-Log ""
    Write-Log "Build log saved to: $LogFile" -Color Gray

    exit 0
} else {
    Write-Log "=== Build Failed ===" -Color Red
    Write-Log "Exit code: $($process.ExitCode)"
    Write-Log ""
    Write-Log "Common issues:" -Color Yellow
    Write-Log "- Missing dependencies (check project references)"
    Write-Log "- Syntax errors (check recent code changes)"
    Write-Log "- Missing .NET workload (run: dotnet workload install wpf)"
    Write-Log ""
    Write-Log "Build log saved to: $LogFile" -Color Gray

    exit $process.ExitCode
}
```

---

## selftest_launch_enhanced.ps1
# 15 selftest_launch_enhanced.ps1（全文）

```powershell
# selftest_launch_enhanced.ps1
# Purpose: Enhanced self-test for VIBE One Screen OS launch with STRONG DONE verification
# Usage: .\selftest_launch_enhanced.ps1 [-LaunchIfNeeded] [-WhatIf]
#
# DONE条件:
#   1) プロセスが起動し、2秒後も生存している
#   2) MainWindowHandle が 0 ではない（UIが生成済み）
#   3) ウィンドウが前面に出る（最小化/背面/画面外を検知したら自動でRestore+Foreground）

param(
    [switch]$LaunchIfNeeded,
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"

# Determine OneBoxRoot (script is in CORE\VIBE_CTRL\scripts)
$ScriptRoot = Split-Path -Parent $PSCommandPath
$VIBECtrlRoot = Split-Path -Parent $ScriptRoot
$CoreRoot = Split-Path -Parent $VIBECtrlRoot
$OneBoxRoot = Split-Path -Parent $CoreRoot

# Paths
$ExePath = Join-Path $OneBoxRoot "APP\dist\OneScreenOSApp.exe"
$CmdPath = Join-Path $OneBoxRoot "LAUNCH_ONE_SCREEN_OS.cmd"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "VIBE One Screen OS.lnk"
$LogDir = Join-Path $OneBoxRoot "VAULT\06_LOGS"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogPath = Join-Path $LogDir "launch_selftest_enhanced_$Timestamp.md"
$ActivateScriptPath = Join-Path $ScriptRoot "activate_window.ps1"

# Test results
$Results = @()

Write-Host "=== VIBE One Screen OS Enhanced Launch Self-Test ===" -ForegroundColor Cyan
Write-Host "OneBoxRoot: $OneBoxRoot"
Write-Host "Timestamp: $Timestamp"
Write-Host ""

# ========== Test 1: OneScreenOSApp.exe existence ==========
Write-Host "[TEST 1] Checking OneScreenOSApp.exe..." -NoNewline
if (Test-Path $ExePath) {
    $FileInfo = Get-Item $ExePath
    $SizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
    Write-Host " PASS" -ForegroundColor Green
    $Results += "[✓] OneScreenOSApp.exe exists ($SizeMB MB, modified: $($FileInfo.LastWriteTime))"
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $Results += "[✗] OneScreenOSApp.exe NOT FOUND at: $ExePath"
}

# ========== Test 2: LAUNCH_ONE_SCREEN_OS.cmd existence and content ==========
Write-Host "[TEST 2] Checking LAUNCH_ONE_SCREEN_OS.cmd..." -NoNewline
if (Test-Path $CmdPath) {
    $CmdContent = Get-Content $CmdPath -Raw
    if ($CmdContent -match '%~dp0') {
        Write-Host " PASS" -ForegroundColor Green
        $Results += "[✓] LAUNCH_ONE_SCREEN_OS.cmd exists and uses %~dp0 (correct)"
    } else {
        Write-Host " WARN" -ForegroundColor Yellow
        $Results += "[⚠] LAUNCH_ONE_SCREEN_OS.cmd exists but does not use %~dp0 (may cause issues with Japanese paths)"
    }
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $Results += "[✗] LAUNCH_ONE_SCREEN_OS.cmd NOT FOUND at: $CmdPath"
}

# ========== Test 3: Desktop shortcut validity (MUST use cmd.exe /c) ==========
Write-Host "[TEST 3] Checking desktop shortcut (cmd.exe /c enforcement)..." -NoNewline
if (Test-Path $ShortcutPath) {
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Target = $Shortcut.TargetPath
        $Args = $Shortcut.Arguments
        $WorkDir = $Shortcut.WorkingDirectory

        # Check if target is cmd.exe
        $isCmdExe = $Target -match 'cmd\.exe$'

        # Check if arguments use /c with LAUNCH_ONE_SCREEN_OS.cmd
        $hasCorrectArgs = $Args -match '/c.*LAUNCH_ONE_SCREEN_OS\.cmd'

        # Check working directory
        $WorkDirOK = $WorkDir -eq $OneBoxRoot

        if ($isCmdExe -and $hasCorrectArgs -and $WorkDirOK) {
            Write-Host " PASS" -ForegroundColor Green
            $Results += "[✓] Desktop shortcut exists and correctly uses cmd.exe /c wrapper"
            $Results += "    Target: $Target"
            $Results += "    Arguments: $Args"
        } elseif (-not $isCmdExe) {
            Write-Host " FAIL" -ForegroundColor Red
            $Results += "[✗] Desktop shortcut does NOT use cmd.exe wrapper (UNSAFE)"
            $Results += "    Current Target: $Target"
            $Results += "    Expected: C:\Windows\System32\cmd.exe"
            $Results += "    FIX REQUIRED: Recreate shortcut using make_desktop_shortcut_enhanced.ps1"
        } else {
            Write-Host " WARN" -ForegroundColor Yellow
            $Results += "[⚠] Desktop shortcut uses cmd.exe but has incorrect settings:"
            $Results += "    Target: $Target (OK: $isCmdExe)"
            $Results += "    Arguments: $Args (OK: $hasCorrectArgs)"
            $Results += "    WorkDir: $WorkDir (OK: $WorkDirOK, Expected: $OneBoxRoot)"
        }
    } catch {
        Write-Host " WARN" -ForegroundColor Yellow
        $Results += "[⚠] Desktop shortcut exists but could not be validated: $_"
    }
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $Results += "[✗] Desktop shortcut NOT FOUND at: $ShortcutPath"
}

# ========== Test 4: Activate window script existence ==========
Write-Host "[TEST 4] Checking activate_window.ps1..." -NoNewline
if (Test-Path $ActivateScriptPath) {
    Write-Host " PASS" -ForegroundColor Green
    $Results += "[✓] activate_window.ps1 exists"
} else {
    Write-Host " WARN" -ForegroundColor Yellow
    $Results += "[⚠] activate_window.ps1 NOT FOUND (window activation will not work)"
}

# ========== Test 5: Single Instance Check (before DONE verification) ==========
Write-Host "[TEST 5] Single Instance check..." -NoNewline

$processName = "OneScreenOSApp"
$existingProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
$processCountBefore = if ($existingProcesses) { $existingProcesses.Count } else { 0 }

if ($processCountBefore -eq 0) {
    Write-Host " PASS (no instances running)" -ForegroundColor Green
    $Results += "[✓] Single Instance: No instances running (clean start)"
} elseif ($processCountBefore -eq 1) {
    Write-Host " PASS (1 instance running)" -ForegroundColor Green
    $Results += "[✓] Single Instance: Exactly 1 instance running (PID: $($existingProcesses[0].Id))"
} else {
    Write-Host " FAIL ($processCountBefore instances detected!)" -ForegroundColor Red
    $Results += "[✗] Single Instance VIOLATION: $processCountBefore instances detected"
    foreach ($proc in $existingProcesses) {
        $Results += "    - PID: $($proc.Id), StartTime: $($proc.StartTime)"
    }
}

# ========== Test 6: Process alive + MainWindowHandle + Foreground (STRONG DONE verification) ==========
Write-Host "[TEST 6] STRONG DONE Verification (process alive, UI created, foreground)..." -NoNewline

if ($existingProcesses) {
    Write-Host " RUNNING" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "既存のOneScreenOSAppプロセスが検出されました。検証を実行します..." -ForegroundColor Cyan

    $process = $existingProcesses[0]

    # Sub-test 6.1: Process alive for 2 seconds
    Write-Host "  [6.1] Process alive check (2秒待機)..." -NoNewline
    Start-Sleep -Seconds 2
    $process.Refresh()
    if (-not $process.HasExited) {
        Write-Host " PASS" -ForegroundColor Green
        $Results += "[✓] Process is alive after 2 seconds (PID: $($process.Id))"
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        $Results += "[✗] Process exited within 2 seconds (crash suspected)"
    }

    # Sub-test 6.2: MainWindowHandle != 0
    Write-Host "  [6.2] MainWindowHandle check..." -NoNewline
    $process.Refresh()
    $hwnd = $process.MainWindowHandle

    if ($hwnd -ne [IntPtr]::Zero) {
        Write-Host " PASS" -ForegroundColor Green
        $Results += "[✓] MainWindowHandle is valid: 0x$($hwnd.ToString('X8'))"
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        $Results += "[✗] MainWindowHandle is 0 (UI not created or crashed)"

        # Attempt to collect crash logs
        Write-Host "     クラッシュログを収集しています..." -ForegroundColor Yellow
        $crashLogScript = Join-Path $ScriptRoot "collect_crash_logs.ps1"
        if (Test-Path $crashLogScript) {
            & $crashLogScript -ProcessName $processName
        }
    }

    # Sub-test 6.3: Window activation (Restore + SetForegroundWindow) - STRICT MODE
    if ($hwnd -ne [IntPtr]::Zero) {
        Write-Host "  [6.3] Window activation check (STRICT)..." -NoNewline

        if (Test-Path $ActivateScriptPath) {
            $activateResult = & $ActivateScriptPath -Pid $process.Id -TimeoutSeconds 5 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host " PASS" -ForegroundColor Green
                $Results += "[✓] Window successfully activated and brought to foreground"
            } else {
                Write-Host " FAIL" -ForegroundColor Red
                $Results += "[✗] Window activation FAILED (exit code: $LASTEXITCODE)"
                $Results += "    Activation is REQUIRED for DONE condition - this is a CRITICAL failure"
            }
        } else {
            Write-Host " FAIL" -ForegroundColor Red
            $Results += "[✗] activate_window.ps1 not found - REQUIRED for DONE verification"
        }
    }

} elseif ($LaunchIfNeeded) {
    Write-Host " NOT RUNNING" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "-LaunchIfNeeded が指定されたため、アプリケーションを起動します..." -ForegroundColor Cyan

    if (-not (Test-Path $CmdPath)) {
        Write-Host "[FAIL] LAUNCH_ONE_SCREEN_OS.cmd が見つかりません" -ForegroundColor Red
        $Results += "[✗] Cannot launch: LAUNCH_ONE_SCREEN_OS.cmd not found"
    } else {
        Write-Host "起動中: $CmdPath" -ForegroundColor Cyan

        # Launch via cmd.exe /c (recommended method)
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$CmdPath`"" -WorkingDirectory $OneBoxRoot -WindowStyle Hidden

        Write-Host "起動しました。STRONG DONE検証を実行します..." -ForegroundColor Cyan

        # Wait and verify
        Start-Sleep -Seconds 3

        $newProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if ($newProcesses) {
            $process = $newProcesses[0]

            # Single Instance check after launch
            $processCountAfter = $newProcesses.Count
            if ($processCountAfter -gt 1) {
                Write-Host ""
                Write-Host "  [CRITICAL] Single Instance violation detected after launch!" -ForegroundColor Red
                $Results += "[✗] Single Instance VIOLATION after launch: $processCountAfter instances"
            }

            # 6.1: Process alive
            Write-Host "  [6.1] Process alive check (2秒待機)..." -NoNewline
            Start-Sleep -Seconds 2
            $process.Refresh()
            if (-not $process.HasExited) {
                Write-Host " PASS" -ForegroundColor Green
                $Results += "[✓] Process is alive after 2 seconds (PID: $($process.Id))"
            } else {
                Write-Host " FAIL" -ForegroundColor Red
                $Results += "[✗] Process exited within 2 seconds (crash suspected)"
            }

            # 6.2: MainWindowHandle
            Write-Host "  [6.2] MainWindowHandle check..." -NoNewline
            $process.Refresh()
            $hwnd = $process.MainWindowHandle

            if ($hwnd -ne [IntPtr]::Zero) {
                Write-Host " PASS" -ForegroundColor Green
                $Results += "[✓] MainWindowHandle is valid: 0x$($hwnd.ToString('X8'))"
            } else {
                Write-Host " FAIL" -ForegroundColor Red
                $Results += "[✗] MainWindowHandle is 0 (UI not created or crashed)"
            }

            # 6.3: Window activation (STRICT)
            if ($hwnd -ne [IntPtr]::Zero -and (Test-Path $ActivateScriptPath)) {
                Write-Host "  [6.3] Window activation check (STRICT)..." -NoNewline
                $activateResult = & $ActivateScriptPath -Pid $process.Id -TimeoutSeconds 5 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Host " PASS" -ForegroundColor Green
                    $Results += "[✓] Window successfully activated and brought to foreground"
                } else {
                    Write-Host " FAIL" -ForegroundColor Red
                    $Results += "[✗] Window activation FAILED (exit code: $LASTEXITCODE)"
                }
            } elseif ($hwnd -ne [IntPtr]::Zero) {
                Write-Host "  [6.3] Window activation check..." -NoNewline
                Write-Host " FAIL" -ForegroundColor Red
                $Results += "[✗] activate_window.ps1 not found - REQUIRED"
            }
        } else {
            Write-Host "[FAIL] プロセスが起動しませんでした" -ForegroundColor Red
            $Results += "[✗] Process did not start after launch command"
        }
    }

} else {
    Write-Host " NOT RUNNING" -ForegroundColor Yellow
    $Results += "[⚠] OneScreenOSApp is not running (use -LaunchIfNeeded to auto-launch)"
}

# ========== Generate report ==========
if ($WhatIf) {
    Write-Host ""
    Write-Host "[WHATIF] Would write report to: $LogPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=== Report Preview ===" -ForegroundColor Cyan
    $Results | ForEach-Object { Write-Host $_ }
    exit 0
}

# Write log
$ReportContent = @"
# VIBE One Screen OS Enhanced Launch Self-Test

**Date:** $Timestamp
**OneBoxRoot:** ``$OneBoxRoot``

---

## Test Results

$($Results -join "`n")

---

## DONE Condition Checklist

- [$(if ($Results -match 'Process is alive after 2 seconds') { 'x' } else { ' ' })] Process alive for 2+ seconds
- [$(if ($Results -match 'MainWindowHandle is valid') { 'x' } else { ' ' })] MainWindowHandle != 0 (UI created)
- [$(if ($Results -match 'Window successfully activated') { 'x' } else { ' ' })] Window brought to foreground

---

## Recommendations

$(
if ($Results -match '\[✗\]') {
    "- **CRITICAL:** Fix failed tests immediately"
}
if ($Results -match '\[⚠\]') {
    "- **WARNING:** Review warnings and fix if necessary"
}
if ($Results -match 'Desktop shortcut does NOT use cmd.exe wrapper') {
    "- **ACTION REQUIRED:** Recreate desktop shortcut using: ``.\CORE\VIBE_CTRL\scripts\make_desktop_shortcut_enhanced.ps1``"
}
if (-not ($Results -match '\[✗\]') -and -not ($Results -match '\[⚠\]')) {
    "- **ALL TESTS PASSED:** Launch infrastructure is healthy and DONE conditions satisfied"
}
)

---

**Next Steps:**

1. If desktop shortcut is missing or incorrect, run: ``.\CORE\VIBE_CTRL\scripts\make_desktop_shortcut_enhanced.ps1``
2. If OneScreenOSApp.exe is missing, run: ``.\CORE\VIBE_CTRL\scripts\build_publish.ps1``
3. If LAUNCH_ONE_SCREEN_OS.cmd has issues, review its content and fix encoding/path issues
4. If MainWindowHandle is 0, check crash logs at: ``VAULT\06_LOGS\crash_*.log``
5. If window activation fails, verify user32.dll access and run as administrator if needed
"@

try {
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($LogPath, $ReportContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host ""
    Write-Host "[SUCCESS] Report written to: $LogPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to write report: $_"
    exit 1
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$PassCount = ($Results | Where-Object { $_ -match '^\[✓\]' }).Count
$FailCount = ($Results | Where-Object { $_ -match '^\[✗\]' }).Count
$WarnCount = ($Results | Where-Object { $_ -match '^\[⚠\]' }).Count
Write-Host "Passed: $PassCount | Failed: $FailCount | Warnings: $WarnCount"

if ($FailCount -eq 0 -and $WarnCount -eq 0) {
    Write-Host "✅ Launch infrastructure is healthy and DONE conditions satisfied!" -ForegroundColor Green
    exit 0
} elseif ($FailCount -gt 0) {
    Write-Host "❌ Critical issues detected. Please fix." -ForegroundColor Red
    exit 1
} else {
    Write-Host "⚠ Warnings detected. Review recommended." -ForegroundColor Yellow
    exit 0
}
```

---

## doctor_activate.ps1
# 16 doctor_activate.ps1（全文）

```powershell
# doctor_activate.ps1
# Purpose: One-command Doctor with integrated Activate functionality
# Usage: .\doctor_activate.ps1 [-LaunchIfNeeded] [-ForceActivate]
#
# Functions:
#   1. Run OneBox diagnostics (encoding, file structure)
#   2. Check if OneScreenOSApp is running
#   3. If running but not visible, auto-activate (Restore + SetForegroundWindow)
#   4. If MainWindowHandle is 0, collect crash logs automatically
#   5. Generate comprehensive diagnostic report

param(
    [switch]$LaunchIfNeeded,
    [switch]$ForceActivate
)

$ErrorActionPreference = "Continue"

# Determine OneBoxRoot (script is in CORE\VIBE_CTRL\scripts)
$ScriptRoot = Split-Path -Parent $PSCommandPath
$VIBECtrlRoot = Split-Path -Parent $ScriptRoot
$CoreRoot = Split-Path -Parent $VIBECtrlRoot
$OneBoxRoot = Split-Path -Parent $CoreRoot

$LogDir = Join-Path $OneBoxRoot "VAULT\06_LOGS"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$SummaryPath = Join-Path $LogDir "doctor_activate_${Timestamp}.txt"

$ActivateScriptPath = Join-Path $ScriptRoot "activate_window.ps1"
$CrashLogScriptPath = Join-Path $ScriptRoot "collect_crash_logs.ps1"
$CmdPath = Join-Path $OneBoxRoot "LAUNCH_ONE_SCREEN_OS.cmd"

Write-Host "=== Doctor + Activate (One Command) ===" -ForegroundColor Cyan
Write-Host "Timestamp: $Timestamp"
Write-Host "OneBoxRoot: $OneBoxRoot"
Write-Host ""

# Create log directory
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("VIBE OneBox Doctor + Activate - $(Get-Date)")
$lines.Add("Root: $OneBoxRoot")
$lines.Add("PowerShell: $($PSVersionTable.PSVersion)")
$lines.Add("")

# ========== SECTION 1: Basic OneBox Diagnostics ==========
Write-Host "[SECTION 1] OneBox Diagnostics" -ForegroundColor Cyan

$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $lines.Add("pwsh found: $($pwsh.Source)")
} else {
    $lines.Add("pwsh: NOT FOUND (Windows PowerShell only)")
}

$menuOrig = Join-Path $OneBoxRoot "RUN_START_MENU.cmd"
$menuSafe = Join-Path $OneBoxRoot "RUN_START_MENU_SAFE.cmd"
$lines.Add("")
$lines.Add("Entry points:")
$lines.Add(" - Original menu exists: $(Test-Path $menuOrig)")
$lines.Add(" - SAFE menu exists    : $(Test-Path $menuSafe)")

# BOM detection
function Get-BomInfo([byte[]]$b) {
    if ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { return "UTF-16LE" }
    if ($b.Length -ge 2 -and $b[0] -eq 0xFE -and $b[1] -eq 0xFF) { return "UTF-16BE" }
    if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { return "UTF-8-BOM" }
    return "NONE"
}

$cmds = Get-ChildItem -Path $OneBoxRoot -File -Filter "*.cmd" -ErrorAction SilentlyContinue
$lines.Add("")
$lines.Add("CMD files: $($cmds.Count)")

$bad = @()
foreach ($f in $cmds) {
    try {
        $b = [System.IO.File]::ReadAllBytes($f.FullName)
        $bom = Get-BomInfo $b
        if ($bom -ne "NONE") {
            $sig = ($b[0..([Math]::Min(7, $b.Length - 1))] | ForEach-Object { $_.ToString("X2") }) -join " "
            $bad += [pscustomobject]@{ File = $f.Name; BOM = $bom; Sig = $sig }
        }
    } catch {}
}

if ($bad.Count -gt 0) {
    $lines.Add("")
    $lines.Add("Potential encoding risks (BOM detected in .cmd):")
    foreach ($x in $bad | Select-Object -First 10) {
        $lines.Add(" - $($x.File)  [$($x.BOM)]  sig:$($x.Sig)")
    }
} else {
    $lines.Add("")
    $lines.Add("No BOM detected in .cmd files (good).")
}

Write-Host "[OK] OneBox structure check completed" -ForegroundColor Green

# ========== SECTION 2: OneScreenOSApp Process Check ==========
Write-Host ""
Write-Host "[SECTION 2] OneScreenOSApp Process Check" -ForegroundColor Cyan

$processName = "OneScreenOSApp"
$processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

$lines.Add("")
$lines.Add("===== OneScreenOSApp Status =====")

if ($processes) {
    $proc = $processes[0]
    $proc.Refresh()

    $lines.Add("Process: RUNNING")
    $lines.Add(" - PID: $($proc.Id)")
    $lines.Add(" - StartTime: $($proc.StartTime)")
    $lines.Add(" - MainWindowHandle: 0x$($proc.MainWindowHandle.ToString('X8'))")
    $lines.Add(" - MainWindowTitle: $($proc.MainWindowTitle)")
    $lines.Add(" - WorkingSet (MB): $([math]::Round($proc.WorkingSet64 / 1MB, 2))")

    Write-Host "[OK] Process is running (PID: $($proc.Id))" -ForegroundColor Green

    # Check MainWindowHandle
    if ($proc.MainWindowHandle -eq [IntPtr]::Zero) {
        Write-Host "[WARN] MainWindowHandle is 0 (UI not created or crashed)" -ForegroundColor Yellow
        $lines.Add(" - WARNING: MainWindowHandle is 0")

        # Auto-collect crash logs
        Write-Host ""
        Write-Host "Collecting crash logs..." -ForegroundColor Yellow
        if (Test-Path $CrashLogScriptPath) {
            & $CrashLogScriptPath -ProcessName $processName
            $lines.Add(" - Crash logs collected (check VAULT\06_LOGS)")
        } else {
            $lines.Add(" - Crash log script not found")
        }
    } else {
        Write-Host "[OK] MainWindowHandle is valid" -ForegroundColor Green

        # Check if activation is needed or forced
        if ($ForceActivate) {
            Write-Host ""
            Write-Host "[SECTION 3] Force Activate Window" -ForegroundColor Cyan
            $lines.Add("")
            $lines.Add("===== Window Activation (Forced) =====")

            if (Test-Path $ActivateScriptPath) {
                $activateOutput = & $ActivateScriptPath -Pid $proc.Id -TimeoutSeconds 15 2>&1
                $activateExitCode = $LASTEXITCODE

                $lines.Add("Activation script executed (exit code: $activateExitCode)")
                $lines.Add($activateOutput -join "`n")

                if ($activateExitCode -eq 0) {
                    Write-Host "[OK] Window activated successfully" -ForegroundColor Green
                } elseif ($activateExitCode -eq 2) {
                    Write-Host "[WARN] Window activation partially succeeded" -ForegroundColor Yellow
                } else {
                    Write-Host "[FAIL] Window activation failed" -ForegroundColor Red
                }
            } else {
                Write-Host "[WARN] activate_window.ps1 not found" -ForegroundColor Yellow
                $lines.Add("Activation script not found: $ActivateScriptPath")
            }
        } else {
            $lines.Add(" - Window activation: Skipped (use -ForceActivate to activate)")
        }
    }

} elseif ($LaunchIfNeeded) {
    Write-Host "[INFO] Process not running. Launching..." -ForegroundColor Yellow
    $lines.Add("Process: NOT RUNNING")
    $lines.Add("Action: Launching OneScreenOSApp.exe directly (avoiding recursion)")

    $ExePath = Join-Path $OneBoxRoot "APP\dist\OneScreenOSApp.exe"

    if (Test-Path $ExePath) {
        try {
            # Launch EXE directly (avoid recursion through LAUNCH_ONE_SCREEN_OS.cmd)
            Start-Process -FilePath $ExePath -WorkingDirectory $OneBoxRoot -WindowStyle Normal
            Write-Host "[OK] Launch command executed" -ForegroundColor Green
            $lines.Add("Launch: Success (direct EXE)")

            # Wait and verify
            Start-Sleep -Seconds 3
            $newProc = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if ($newProc) {
                $newProc[0].Refresh()
                $lines.Add("Verification: Process started (PID: $($newProc[0].Id))")
                $lines.Add(" - MainWindowHandle: 0x$($newProc[0].MainWindowHandle.ToString('X8'))")

                # Auto-activate after launch
                if ($newProc[0].MainWindowHandle -ne [IntPtr]::Zero -and (Test-Path $ActivateScriptPath)) {
                    Write-Host "Auto-activating window..." -ForegroundColor Cyan
                    Start-Sleep -Seconds 2
                    & $ActivateScriptPath -Pid $newProc[0].Id -TimeoutSeconds 15 | Out-Null
                } elseif ($newProc[0].MainWindowHandle -eq [IntPtr]::Zero) {
                    Write-Host "MainWindowHandle is 0, collecting crash logs..." -ForegroundColor Yellow
                    $crashLogScript = Join-Path $ScriptRoot "collect_crash_logs.ps1"
                    if (Test-Path $crashLogScript) {
                        & $crashLogScript -ProcessName $processName
                    }
                }
            } else {
                $lines.Add("Verification: Process did not start")
            }
        } catch {
            Write-Host "[FAIL] Launch failed: $_" -ForegroundColor Red
            $lines.Add("Launch: FAILED - $_")
        }
    } else {
        Write-Host "[FAIL] OneScreenOSApp.exe not found" -ForegroundColor Red
        $lines.Add("Launch: FAILED - OneScreenOSApp.exe not found at $ExePath")
    }

} else {
    Write-Host "[INFO] Process not running (use -LaunchIfNeeded to auto-launch)" -ForegroundColor Yellow
    $lines.Add("Process: NOT RUNNING")
    $lines.Add("Action: None (use -LaunchIfNeeded)")
}

# ========== SECTION 3: Recommendations ==========
$lines.Add("")
$lines.Add("===== Recommendations =====")
$lines.Add("1. Launch: Use desktop shortcut or run LAUNCH_ONE_SCREEN_OS.cmd")
$lines.Add("2. Doctor: Run this script regularly to monitor health")
$lines.Add("3. Activate: Use -ForceActivate to bring window to foreground")
$lines.Add("4. Self-Test: Run .\CORE\VIBE_CTRL\scripts\selftest_launch_enhanced.ps1")
$lines.Add("5. Logs: Check VAULT\06_LOGS for crash logs and diagnostics")

# ========== Write Summary ==========
try {
    [System.IO.File]::WriteAllLines($SummaryPath, $lines.ToArray(), [System.Text.Encoding]::UTF8)
    Write-Host ""
    Write-Host "[SUCCESS] Doctor summary written to: $SummaryPath" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not write summary: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Doctor + Activate Complete ===" -ForegroundColor Cyan
Write-Host "Check the summary file for full details." -ForegroundColor Yellow
```

---

## kb_sync_inbox_analyzer.ps1
# 19 kb_sync_inbox_analyzer.ps1（全文）

```powershell
# kb_sync_inbox_analyzer.ps1
# Purpose: Analyze KB_SYNC__INBOX contents without deletion
# Creates classification report for manual review

param(
    [string]$InboxPath = "C:\Users\koji2\Desktop\VCG\01_作業（加工中）\KB_SYNC__INBOX"
)

$ErrorActionPreference = "Continue"

Write-Host "=== KB_SYNC__INBOX Analysis ===" -ForegroundColor Cyan
Write-Host "Path: $InboxPath"
Write-Host "NOTE: This is READ-ONLY analysis. No files will be moved or deleted."
Write-Host ""

if (-not (Test-Path $InboxPath)) {
    Write-Error "KB_SYNC__INBOX not found at: $InboxPath"
    exit 1
}

# Initialize counters
$report = @{
    TotalFiles = 0
    TotalSize = 0
    ExtensionStats = @{}
    TopDirectories = @()
    BackupZips = @()
    LargeFiles = @()
    RecentFiles = @()
    OldFiles = @()
}

Write-Host "[1/7] Counting files and calculating size..." -ForegroundColor Yellow
$allFiles = Get-ChildItem $InboxPath -File -Recurse -ErrorAction SilentlyContinue
$report.TotalFiles = $allFiles.Count
$report.TotalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum

Write-Host "    Total: $($report.TotalFiles) files, $([math]::Round($report.TotalSize / 1GB, 2)) GB"

Write-Host "[2/7] Analyzing by extension..." -ForegroundColor Yellow
$extGroups = $allFiles | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 20
foreach ($ext in $extGroups) {
    $size = ($ext.Group | Measure-Object -Property Length -Sum).Sum
    $report.ExtensionStats[$ext.Name] = @{
        Count = $ext.Count
        SizeMB = [math]::Round($size / 1MB, 2)
    }
}

Write-Host "[3/7] Finding backup ZIPs..." -ForegroundColor Yellow
$report.BackupZips = Get-ChildItem $InboxPath -File -Filter "*.zip" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "ONEBOX" } |
    Select-Object -First 10 Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime

Write-Host "[4/7] Finding large files (>100MB)..." -ForegroundColor Yellow
$report.LargeFiles = $allFiles |
    Where-Object { $_.Length -gt 100MB } |
    Sort-Object Length -Descending |
    Select-Object -First 10 Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, Directory

Write-Host "[5/7] Analyzing top-level directories..." -ForegroundColor Yellow
$topDirs = Get-ChildItem $InboxPath -Directory -ErrorAction SilentlyContinue
foreach ($dir in $topDirs) {
    $dirFiles = Get-ChildItem $dir.FullName -File -Recurse -ErrorAction SilentlyContinue
    $dirSize = ($dirFiles | Measure-Object -Property Length -Sum).Sum
    $report.TopDirectories += [PSCustomObject]@{
        Name = $dir.Name
        Files = $dirFiles.Count
        SizeMB = [math]::Round($dirSize / 1MB, 2)
    }
}
$report.TopDirectories = $report.TopDirectories | Sort-Object SizeMB -Descending | Select-Object -First 10

Write-Host "[6/7] Analyzing file age distribution..." -ForegroundColor Yellow
$now = Get-Date
$report.RecentFiles = ($allFiles | Where-Object { $_.LastWriteTime -gt $now.AddDays(-7) }).Count
$report.OldFiles = ($allFiles | Where-Object { $_.LastWriteTime -lt $now.AddDays(-90) }).Count

Write-Host "[7/7] Generating report..." -ForegroundColor Yellow

# Generate markdown report
$reportContent = @"
# KB_SYNC__INBOX Classification Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Path:** ``$InboxPath``
**Analysis Mode:** READ-ONLY (No files modified or deleted)

---

## Executive Summary

- **Total Files:** $($report.TotalFiles)
- **Total Size:** $([math]::Round($report.TotalSize / 1GB, 2)) GB ($([math]::Round($report.TotalSize / 1MB, 2)) MB)
- **Recent Files (< 7 days):** $($report.RecentFiles)
- **Old Files (> 90 days):** $($report.OldFiles)

---

## File Types (Top 20)

| Extension | Files | Size (MB) | % of Total |
|-----------|-------|-----------|------------|
$($report.ExtensionStats.GetEnumerator() | Sort-Object {$_.Value.Count} -Descending | ForEach-Object {
    $pct = [math]::Round(($_.Value.Count / $report.TotalFiles) * 100, 1)
    "| $($_.Key) | $($_.Value.Count) | $($_.Value.SizeMB) | $pct% |"
} | Out-String)

---

## Top-Level Directories

$( if ($report.TopDirectories.Count -gt 0) {
@"
| Directory | Files | Size (MB) |
|-----------|-------|-----------|
$($report.TopDirectories | ForEach-Object { "| $($_.Name) | $($_.Files) | $($_.SizeMB) |" } | Out-String)
"@
} else {
"*No subdirectories found (all files at root level)*"
})

---

## OneBox Backup ZIPs

$( if ($report.BackupZips.Count -gt 0) {
@"
| Filename | Size (MB) | Last Modified |
|----------|-----------|---------------|
$($report.BackupZips | ForEach-Object { "| $($_.Name) | $($_.SizeMB) | $($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) |" } | Out-String)
"@
} else {
"*No OneBox backup ZIPs found*"
})

---

## Large Files (>100MB)

$( if ($report.LargeFiles.Count -gt 0) {
@"
| Filename | Size (MB) | Directory |
|----------|-----------|-----------|
$($report.LargeFiles | ForEach-Object { "| $($_.Name) | $($_.SizeMB) | $($_.Directory.Name) |" } | Out-String)
"@
} else {
"*No files larger than 100MB*"
})

---

## Classification Recommendations

### Category A: OneBox Backups
**Files:** ONEBOX_*.zip files ($($report.BackupZips.Count) found)
**Recommendation:**
- **KEEP** the most recent 3-5 backups
- **ARCHIVE** older backups to external storage or VAULT/07_RELEASE
- **DELETE** only after confirming recent backups are valid

### Category B: Knowledge Base Data (.json, .md)
**Files:** ~$($report.ExtensionStats['.json'].Count + $report.ExtensionStats['.md'].Count) files
**Recommendation:**
- **INVESTIGATE** if these are:
  - Processed knowledge entries (can be re-generated)
  - Unprocessed inbox items (must be processed first)
  - Duplicate entries (safe to deduplicate)
- **DO NOT DELETE** without understanding the source and purpose

### Category C: Temporary/Cache Files
**Files:** .tmp, .cache, .log extensions
**Recommendation:**
- **SAFE TO DELETE** if older than 30 days and not actively referenced

### Category D: Old Files (>90 days)
**Files:** $($report.OldFiles) files
**Recommendation:**
- **REVIEW** before deletion
- Check if these are:
  - Historical records (archive to VAULT)
  - Unused drafts (safe to delete)
  - Important backups (keep or archive)

---

## Risk Assessment

### High Risk (DO NOT DELETE without manual review)
- OneBox backup ZIPs
- .json and .md files (knowledge base)
- Files modified within last 30 days

### Medium Risk (Review before deletion)
- Files between 30-90 days old
- Large files (>100MB) — may be important data
- Subdirectories with many files

### Low Risk (Likely safe to delete after confirmation)
- .tmp, .cache files older than 30 days
- Duplicate files (after hash verification)
- Empty directories

---

## Proposed Actions (Manual)

### Option 1: Archive to External Storage
Move entire KB_SYNC__INBOX to external drive or network storage for offline retention.

``````powershell
# Example: Move to external drive
Move-Item "$InboxPath" "E:\Backups\KB_SYNC__INBOX_$(Get-Date -Format 'yyyyMMdd')"
``````

### Option 2: Selective Retention
1. Keep most recent OneBox backups (last 5)
2. Archive .json/.md files to VAULT/KB_ARCHIVE
3. Delete .tmp/.cache files older than 30 days

### Option 3: Full Preservation (Recommended for now)
Leave KB_SYNC__INBOX untouched until:
- You understand the knowledge base workflow
- You've verified recent backups are valid
- You've extracted any needed data

---

## Next Steps

1. **URGENT:** Determine if KB_SYNC__INBOX is still actively used
   - Check if any processes write to this folder
   - Review timestamps of recent files
   - Understand the knowledge base ingestion workflow

2. **Validate Backups:** Extract and verify 2-3 recent ONEBOX_*.zip files

3. **Deduplicate:** Run hash-based deduplication to identify exact copies

4. **Archive Strategy:** Define retention policy (e.g., "keep 90 days, archive rest")

5. **Automate:** Create scheduled task to archive/cleanup old files monthly

---

**IMPORTANT:** This report is for information only. **NO FILES WERE MODIFIED OR DELETED** during this analysis.

To proceed with cleanup, user must explicitly approve specific actions.

---

**Generated by:** kb_sync_inbox_analyzer.ps1
**Report Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

# Save report
$reportPath = Join-Path (Split-Path $InboxPath -Parent) "VAULT\06_LOGS\KB_SYNC_INBOX_ANALYSIS_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
$reportDir = Split-Path $reportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

try {
    [System.IO.File]::WriteAllText($reportPath, $reportContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host ""
    Write-Host "=== Analysis Complete ===" -ForegroundColor Green
    Write-Host "Report saved to: $reportPath"
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Files: $($report.TotalFiles)"
    Write-Host "  Size: $([math]::Round($report.TotalSize / 1GB, 2)) GB"
    Write-Host "  Top extension: $($extGroups[0].Name) ($($extGroups[0].Count) files)"
    Write-Host ""
    Write-Host "Next: Review report and decide on retention strategy" -ForegroundColor Yellow
} catch {
    Write-Error "Failed to write report: $_"
    exit 1
}
```


---


---

## 10_ULTRASYNC.md (verbatim)

# ULTRASYNC（計画/提案）
## PLAN
# 17 ULTRASYNC_PLAN.md（全文）

```md
# UltraSync v2 実行計画（PLAN）

**作成日時:** 2026-01-05
**OneBoxRoot:** `C:\Users\koji2\Desktop\VCG\01_作業（加工中）`

---

## 現状サマリー（AUDIT結果）

### ✓ 正常稼働確認済み
- VAULT\VIBE_DASHBOARD.md: 存在
- CORE\VIBE_CTRL\scripts\update_dashboard.ps1: 存在
- APP\dist\OneScreenOSApp.exe: 存在
- LAUNCH_ONE_SCREEN_OS.cmd: **既に適切に実装済み**（%~dp0使用）

### ⚠ 削除/退避対象（ゴミファイル）

#### A) 100%削除OK（ビルド生成物）
| パス | サイズ | 理由 |
|------|--------|------|
| APP\OneScreenOSApp\obj | 9.73 MB | .NET ビルド中間ファイル |
| APP\RunnerCore\obj | 0.59 MB | .NET ビルド中間ファイル |
| APP\RunnerCore.Tests\obj | 0.2 MB | .NET ビルド中間ファイル |
| **合計** | **10.52 MB** | |

#### B) 退避→確認後削除（KB_SYNC系）
| パス | ファイル数 | 推定理由 |
|------|-----------|----------|
| KB_SYNC__INBOX | **357,679 files** | 🚨 異常に巨大。調査必要 |
| KB_SYNC__20251229_110120 | 663 files | 古いシンクログ? |
| KB_SYNC__20251230_* (5個) | 各408 files | タイムスタンプ付き履歴 |
| KB_SYNC__20251229_233619 | 7 files | 小規模シンクログ |
| KB_SYNC__20251229_105313 | 3 files | 最小シンクログ |

#### C) 文字化けフォルダ（退避→削除）
- `20251228_1340__VCG��Ր���__��ƒ�__v01` ← 文字化けにより内容不明

### ✓ エンコーディング状態
- VAULT配下のMDファイル: UTF-8 without BOM（適切）
- 追加のBOM監査不要

---

## 実行フェーズ（DRY → DO → VERIFY）

### PHASE 1: デスクトップ起動導線構築

#### 1.1 ショートカット生成スクリプト作成
**ファイル:** `CORE\VIBE_CTRL\scripts\make_desktop_shortcut.ps1`

```powershell
# 概要:
# - ユーザーデスクトップに「VIBE One Screen OS.lnk」を作成
# - TargetPath: <Root>\LAUNCH_ONE_SCREEN_OS.cmd
# - IconLocation: <Root>\APP\dist\OneScreenOSApp.exe,0
# - WorkingDirectory: <Root>
```

**作成理由:** LAUNCH_ONE_SCREEN_OS.cmd は既に存在するが、デスクトップからのアクセスが不便

#### 1.2 起動セルフテストスクリプト作成
**ファイル:** `CORE\VIBE_CTRL\scripts\selftest_launch.ps1`

```powershell
# 検証項目:
# 1. APP\dist\OneScreenOSApp.exe の存在
# 2. LAUNCH_ONE_SCREEN_OS.cmd の存在と内容確認
# 3. デスクトップショートカットの存在と有効性
# 4. 結果を VAULT\06_LOGS\launch_selftest_<timestamp>.md に出力
```

#### 1.3 DRY実行
- 両スクリプトを `-WhatIf` モードで実行
- 予想される変更を確認

---

### PHASE 2: ゴミファイル退避と削除

#### 2.1 cleanup_junk.ps1 作成
**ファイル:** `CORE\VIBE_CTRL\scripts\cleanup_junk.ps1`

**機能:**
- `-WhatIf` パラメータ対応（DRY実行）
- 退避先: `_TRASH\<yyyyMMdd_HHmmss>\`
- 以下を退避:
  - APP\OneScreenOSApp\obj
  - APP\RunnerCore\obj
  - APP\RunnerCore.Tests\obj
  - KB_SYNC__* (INBOX含む、全9個)
  - 20251228_1340__VCG��Ր���__��ƒ�__v01
- 退避ログ生成: `_TRASH\<timestamp>\MANIFEST.md`（退避したパス、サイズ、復元コマンド）

#### 2.2 DRY実行
```powershell
.\CORE\VIBE_CTRL\scripts\cleanup_junk.ps1 -WhatIf
```

予想される出力:
- 退避予定パス一覧
- 合計削減サイズ（推定 > 10 MB + KB_SYNC総量）
- 復元手順

#### 2.3 DO実行
```powershell
.\CORE\VIBE_CTRL\scripts\cleanup_junk.ps1
```

実行後:
- `_TRASH\<timestamp>\` 配下に全ゴミを移動
- MANIFEST.md に復元コマンド記録
- アプリ起動確認（ゴミ削除が影響しないことを確認）

---

### PHASE 3: UI/UX 改善実装

**前提:** この改善は大規模なため、別途詳細設計が必要。今回は骨組みのみ。

#### 3.1 共通デザイン改善（優先度: 高）

**ファイル:** `APP\OneScreenOSApp\MainWindow.xaml`

変更内容:
1. **ヘッダ追加** (Grid.Row=0):
   - 現在プロジェクト / フェーズ / SafeMode / 最終更新 / 重要アラート
   - サイドバーの「現在のプロジェクト」カードと統合・整理

2. **「次へ」ボタン縮小**:
   - 現状: 左下に大きく配置（行77-87）
   - 変更後: 右上に小型化、または現状サイズ維持（ユーザー判断）

3. **空状態コンポーネント追加**:
   - 各画面（Dashboard, Secrets, Providers等）で「何もないとき」のUIを用意
   - "次にやるべきこと" を明示

4. **ステータスバー追加** (Grid.Row=最下部):
   - 「準備完了」「実行中」「エラー」等の状態表示
   - クリックでログ詳細を開く

#### 3.2 Dashboard改善（優先度: 高）

**変更箇所:** `APP\OneScreenOSApp\MainWindow.xaml.cs` - `LoadDashboard()` メソッド

改善内容:
- **Pass Check Failed時の対応UI:**
  - 不足ファイル一覧を表形式で表示
  - 「テンプレ一括生成」ボタンを追加
    - クリックで 01_SPEC/DECISIONS.md 等の不足ファイルを自動生成
  - 「ダッシュボード更新」ボタンを明示（update_dashboard.ps1実行）

#### 3.3 DataOps改善（優先度: 中）

**変更箇所:** DataOps表示部分

改善内容:
- データパス未設定時はステップボタン無効化
- 「参照→保存」を促すガイドテキスト
- 結果プレビューをデフォルト展開（空に見えない工夫）

#### 3.4 Secrets改善（優先度: 中）

**変更箇所:** Secrets表示部分

改善内容:
- **空状態UI:**
  - 「シークレットがありません」メッセージ
  - 「+追加」ボタンと使い方説明
  - サンプルカテゴリ例（API_KEY, DATABASE_URL等）
- 検索/フィルタ機能追加
- マスク表示/コピー機能

#### 3.5 Providers改善（優先度: 中）

**変更箇所:** Providers表示部分

改善内容:
- プロバイダー状態をカード化:
  - 接続テスト結果（成功/失敗/未テスト）
  - レート制限情報
  - 最終成功時刻
  - 直近エラーメッセージ
- 上部入力フィールドに説明追加

#### 3.6 Settings改善（優先度: 高）

**変更箇所:** Settings表示部分

改善内容:
- **LM Studio / Ollama設定:**
  - Base URL編集可能（デフォルト: http://localhost:1234）
  - 接続失敗時の原因別メッセージ:
    - 「接続拒否 → サーバー起動を確認してください」
    - 「タイムアウト → ネットワーク設定を確認してください」
    - 「DNS解決失敗 → URLを確認してください」
  - 「起動手順」を折りたたみパネルでUI内に表示:
    ```
    LM Studio起動手順:
    1. LM Studio.exeを起動
    2. メニュー → Local Server → Start Server
    3. ポート1234で起動されることを確認
    4. 「接続テスト」ボタンをクリック
    ```

#### 3.7 テーマ/見た目統一（優先度: 低）

**変更箇所:** `APP\OneScreenOSApp\App.xaml` - リソースディクショナリ

改善内容:
- ダークモード対応（可能なら）
- 色・角丸・余白・ボタンスタイルを統一
- アイコン追加（左メニュー視認性UP）

**注意:** 大規模変更のため、今回は骨組み実装のみ。完全実装は別タスク。

---

### PHASE 4: ビルド実行とdist再生成

#### 4.1 build_publish.ps1 実行

**前提:** CORE\VIBE_CTRL\scripts\build_publish.ps1 が存在すると想定

```powershell
.\CORE\VIBE_CTRL\scripts\build_publish.ps1
```

**期待される結果:**
- APP\dist\OneScreenOSApp.exe が最新状態に更新
- ビルド警告/エラーをログに記録

#### 4.2 ビルド警告の対応方針
- 既知の警告（Nullable参照型等）は記録のみ
- クリティカルエラーは即座に修正

---

### PHASE 5: VERIFY（検証）

#### 5.1 起動確認
1. デスクトップショートカットから起動
2. LAUNCH_ONE_SCREEN_OS.cmd から起動
3. APP\dist\OneScreenOSApp.exe を直接起動

すべて成功することを確認。

#### 5.2 機能確認
- Dashboard表示
- DataOps画面表示
- Secrets画面表示
- Providers画面表示
- Settings画面表示

#### 5.3 ゴミ削除の影響確認
- ビルド生成物(obj)削除後も正常動作
- KB_SYNC削除後も正常動作
- 文字化けフォルダ削除後も正常動作

---

### PHASE 6: REPORT生成

**ファイル:** `VAULT\06_LOGS\ULTRASYNC_REPORT_<yyyyMMdd_HHmmss>.md`

**内容:**
1. 実施した変更（ファイル単位）
2. 削除/退避したゴミ一覧と容量
3. デスクトップ起動（lnk, cmd）の作成結果
4. UI改善のサマリー（スクリーンショット差分は任意）
5. 既知の警告と対応/未対応理由
6. 復旧手順（_TRASH から戻す方法）

---

## ドライラン実行順序（DRY）

1. `make_desktop_shortcut.ps1 -WhatIf`
2. `selftest_launch.ps1 -WhatIf`
3. `cleanup_junk.ps1 -WhatIf`
4. UI改善の差分確認（コード変更前にバックアップ）
5. ビルドテスト（既存コードで）

**全DRY成功後、ユーザー承認を得てDO実行**

---

## DO実行順序

1. `make_desktop_shortcut.ps1`
2. `selftest_launch.ps1`（初回テスト）
3. `cleanup_junk.ps1`（ゴミ退避）
4. UI改善コード変更
5. `build_publish.ps1`（ビルド）
6. `selftest_launch.ps1`（最終テスト）
7. ULTRASYNC_REPORT生成

---

## リスクと対策

### リスク1: KB_SYNC__INBOX が必要物だった場合
**対策:** _TRASH に退避してから削除。MANIFEST.md に復元コマンド記録。

### リスク2: UI改善でビルドエラー
**対策:** 変更前にGit commit（推奨）または手動バックアップ。

### リスク3: 文字化けフォルダに重要ファイル
**対策:** 退避後、中身を確認してから最終削除。

---

## 完了条件

- [ ] デスクトップショートカットから起動成功
- [ ] ゴミファイル削除でディスク容量 > 10 MB 削減
- [ ] UI改善（最低限Dashboard/Settings）実装
- [ ] ビルド成功、dist\OneScreenOSApp.exe 更新
- [ ] ULTRASYNC_REPORT生成完了
- [ ] _TRASH に退避ファイル保存、復元手順記録

---

**次のアクション:** DRY実行（WhatIfモード）
```

---

## DRY Proposal
# 18 ULTRASYNC_DRY_PROPOSAL_v3.md（全文）

```md
# UltraSync v3 — DRY Proposal (改訂版)

**作成日時:** 2026-01-05 22:10
**OneBoxRoot:** `C:\Users\koji2\Desktop\VCG\01_作業（加工中）`
**Phase:** DRY（ユーザー承認待ち）

---

## 📋 Executive Summary

本提案はUltraSync v2の成果（デスクトップ起動・安全なクリーンアップ）を壊さず、**UI/UX改善**（Dashboard/Settings/DataOps/Secrets/Providers）を実装します。

### 重要原則
- ✅ **ゼロブレイク:** 既存機能を壊さない
- ✅ **KB_SYNC__INBOX保護:** 削除なし（分類レポートのみ作成済み）
- ✅ **文字化け対策維持:** %~dp0、UTF-8 without BOM
- ✅ **段階的実装:** 高リスク変更なし、既存骨組みを強化

---

## 🔍 Phase 1: 現状確認（完了）

### 1.1 既存完了済み項目（UltraSync v2）
- ✅ デスクトップショートカット作成＋セルフテスト
- ✅ 1.17 GB のゴミ削除（_TRASH に退避、復元可能）
- ✅ KB_SYNC__INBOX (29.65 GB, 357k files) 保護・保留
- ✅ OneScreenOSApp.exe ビルド成功（155.67 MB）
- ✅ 文字化け対策完了（%~dp0使用）
- ✅ UI改善計画書作成（18時間工数見積）

### 1.2 KB_SYNC__INBOX 分析結果
**レポート:** `VAULT\06_LOGS\KB_SYNC_INBOX_ANALYSIS_20260105_221033.md`

**内訳:**
- 総ファイル: 357,679
- 総サイズ: 29.65 GB
- 主要拡張子:
  - .md: 169,890 files (47%)
  - .json: 152,507 files (43%)
  - .zip: OneBox backup files (各14MB)

**推奨:** 削除なし、手動レビュー後にアーカイブ戦略を決定

### 1.3 UI現状課題（スクリーンショット分析済み）

**優先度 P0（Critical）:**
- Settings: LM Studio/Ollama接続失敗時のガイド不足
- Dashboard: Pass Check Failed時の対処UIが弱い

**優先度 P1（High）:**
- Dashboard: 欠損ファイル一覧と「テンプレ作成」機能の実装
- DataOps: 結果プレビューが薄い、手順ガイド不足

**優先度 P2（Medium）:**
- Secrets/Providers: 空状態のガイド不足
- デザイン統一: 余白・コントラスト・バッジ色

---

## 📝 Phase 2: 変更提案（DO内容）

### 変更A: Dashboard UI強化（P1）

**ファイル:** `APP\OneScreenOSApp\MainWindow.xaml` + `MainWindow.xaml.cs`

**変更内容:**
1. **既存のCardBlockerを強化**（XAML 195-219行目に存在）
   - PanelBlockers に欠損ファイル一覧を動的表示
   - 各ファイルごとに「作成」ボタンを追加

2. **MainWindow.xaml.cs に実装追加:**
   ```csharp
   // 欠損ファイルのパース（Pass Check結果から）
   private List<MissingFileInfo> ParseMissingFiles(PassCheckResult result)
   {
       var missing = new List<MissingFileInfo>();
       foreach (var item in result.Items)
       {
           if (item.Status == "MISSING")
           {
               missing.Add(new MissingFileInfo
               {
                   Path = item.Path,
                   Reason = item.Reason,
                   TemplateName = DetermineTemplate(item.Path)
               });
           }
       }
       return missing;
   }

   // テンプレ作成（既存BtnCreateTemplate_Clickを強化）
   private async void BtnCreateTemplate_Click(object sender, RoutedEventArgs e)
   {
       var button = sender as Button;
       var fileInfo = button?.Tag as MissingFileInfo;

       if (fileInfo != null)
       {
           await CreateTemplateFileAsync(fileInfo);
           await RefreshAllAsync(); // ダッシュボード再読み込み
       }
   }

   private async Task CreateTemplateFileAsync(MissingFileInfo file)
   {
       var templatePath = Path.Combine(_oneBoxRoot, file.Path);
       var templateDir = Path.GetDirectoryName(templatePath);

       if (!Directory.Exists(templateDir))
           Directory.CreateDirectory(templateDir);

       var template = GetTemplateContent(file.TemplateName);
       await File.WriteAllTextAsync(templatePath, template, new UTF8Encoding(false));

       Log($"テンプレ作成: {file.Path}");
   }
   ```

3. **PanelBlockersへの動的追加:**
   ```csharp
   private void PopulateBlockers(List<MissingFileInfo> missingFiles)
   {
       PanelBlockers.Children.Clear();

       foreach (var file in missingFiles)
       {
           var item = new StackPanel
           {
               Orientation = Orientation.Horizontal,
               Margin = new Thickness(0, 0, 0, 8)
           };

           item.Children.Add(new TextBlock
           {
               Text = "❌",
               Margin = new Thickness(0, 0, 8, 0)
           });

           item.Children.Add(new TextBlock
           {
               Text = $"{Path.GetFileName(file.Path)} (欠損)",
               VerticalAlignment = VerticalAlignment.Center
           });

           var btnCreate = new Button
           {
               Content = "作成",
               Tag = file,
               Margin = new Thickness(8, 0, 0, 0)
           };
           btnCreate.Click += BtnCreateTemplate_Click;
           item.Children.Add(btnCreate);

           PanelBlockers.Children.Add(item);
       }

       CardBlocker.Visibility = missingFiles.Count > 0
           ? Visibility.Visible
           : Visibility.Collapsed;
   }
   ```

**工数:** 2-3時間
**リスク:** 低（既存UIの強化のみ）
**テスト:** 欠損ファイル作成→Dashboard表示→テンプレ作成→再検証

---

### 変更B: Settings — LM Studio/Ollama接続ガイド（P0）

**ファイル:** `APP\OneScreenOSApp\MainWindow.xaml` (Settings section)

**変更内容:**
1. **URL編集可能テキストボックス追加:**
   ```xaml
   <StackPanel Margin="0,0,0,16">
       <TextBlock Text="LM Studio Base URL" FontWeight="Medium" Margin="0,0,0,4"/>
       <TextBox x:Name="TxtLmStudioUrl" Text="http://localhost:1234"
                Padding="8" FontSize="14"/>
       <TextBlock Text="既定: http://localhost:1234 (変更可能)"
                  FontSize="11" Foreground="{StaticResource TextMuted}" Margin="0,4,0,0"/>
   </StackPanel>

   <Button x:Name="BtnTestLmStudio" Content="接続テスト"
           Click="BtnTestLmStudio_Click" Margin="0,0,8,0"/>

   <TextBlock x:Name="TxtLmStudioStatus" Text="未テスト"
              Margin="8,0,0,0" VerticalAlignment="Center"/>
   ```

2. **接続テストとエラー解析:**
   ```csharp
   private async void BtnTestLmStudio_Click(object sender, RoutedEventArgs e)
   {
       string baseUrl = TxtLmStudioUrl.Text.Trim();
       TxtLmStudioStatus.Text = "テスト中...";

       try
       {
           var result = await _localLlm.TestConnectionAsync(baseUrl);
           if (result.Success)
           {
               TxtLmStudioStatus.Text = "✓ 接続成功";
               TxtLmStudioStatus.Foreground = Brushes.Green;
           }
           else
           {
               var diagnosis = DiagnoseConnectionError(result.Error);
               TxtLmStudioStatus.Text = $"✗ {diagnosis.Message}";
               TxtLmStudioStatus.Foreground = Brushes.Red;

               if (!string.IsNullOrEmpty(diagnosis.Guidance))
               {
                   MessageBox.Show(
                       diagnosis.Guidance,
                       "接続失敗 — 対処方法",
                       MessageBoxButton.OK,
                       MessageBoxImage.Information
                   );
               }
           }
       }
       catch (Exception ex)
       {
           var diagnosis = DiagnoseConnectionError(ex);
           TxtLmStudioStatus.Text = $"✗ {diagnosis.Message}";
           TxtLmStudioStatus.Foreground = Brushes.Red;
       }
   }

   private (string Message, string Guidance) DiagnoseConnectionError(Exception ex)
   {
       if (ex.Message.Contains("refused") || ex.Message.Contains("拒否"))
       {
           return (
               "接続拒否（サーバー未起動）",
               @"LM Studioが起動していない可能性があります。

起動手順:
1. LM Studio.exe を起動
2. メニュー → Local Server → Start Server
3. ポート1234で起動していることを確認
4. 「接続テスト」を再実行

別のポートで起動している場合は、上のURL欄を変更してください。"
           );
       }
       else if (ex.Message.Contains("timeout") || ex.Message.Contains("タイムアウト"))
       {
           return (
               "タイムアウト（応答なし）",
               @"サーバーが応答していません。

確認事項:
- LM Studioが正常に起動しているか
- ファイアウォールでポートがブロックされていないか
- 別のプロセスがポートを占有していないか
- WSLや別PCで起動している場合はIPアドレスを確認"
           );
       }
       else if (ex.Message.Contains("DNS") || ex.Message.Contains("名前"))
       {
           return (
               "URL無効（名前解決失敗）",
               @"URLが正しくありません。

正しい形式:
- http://localhost:1234
- http://127.0.0.1:1234
- http://192.168.x.x:1234 (別PC/WSL)

「http://」または「https://」を忘れずに入力してください。"
           );
       }
       else
       {
           return (
               $"接続エラー: {ex.Message}",
               "不明なエラーです。ログを確認してください。"
           );
       }
   }
   ```

3. **Expanderで起動手順を埋め込み:**
   ```xaml
   <Expander Header="LM Studio起動手順" Margin="0,12,0,0">
       <StackPanel Padding="12" Background="#F5F5F5">
           <TextBlock TextWrapping="Wrap" Foreground="{StaticResource TextPrimary}">
               1. LM Studio.exe を起動<LineBreak/>
               2. メニュー → Local Server → Start Server<LineBreak/>
               3. 「Server running on port 1234」と表示されるのを確認<LineBreak/>
               4. 上の「接続テスト」ボタンをクリック
           </TextBlock>
       </StackPanel>
   </Expander>
   ```

**工数:** 2-3時間
**リスク:** 低（新機能追加、既存に影響なし）
**テスト:** LM Studio OFF → 接続テスト → エラーメッセージ確認 → LM Studio ON → 再テスト

---

### 変更C: DataOps結果プレビュー強化（P1）

**ファイル:** `APP\OneScreenOSApp\MainWindow.xaml` (DataOps section)

**変更内容:**
1. **結果プレビューをデフォルト展開:**
   ```xaml
   <Expander x:Name="ExpanderDataOpsResult" Header="結果プレビュー"
             IsExpanded="True" Margin="0,12,0,0">
       <Border Background="#F9F9F9" Padding="12" BorderBrush="#DDD" BorderThickness="1">
           <StackPanel>
               <TextBlock x:Name="TxtDataOpsResultSummary"
                          Text="まだ実行されていません"
                          FontSize="13" Foreground="{StaticResource TextMuted}"
                          Margin="0,0,0,8"/>
               <ScrollViewer MaxHeight="200" VerticalScrollBarVisibility="Auto">
                   <TextBlock x:Name="TxtDataOpsResult" TextWrapping="Wrap"
                              FontFamily="Consolas" FontSize="12"/>
               </ScrollViewer>
           </StackPanel>
       </Border>
   </Expander>
   ```

2. **結果表示の強化:**
   ```csharp
   private async Task ShowDataOpsResultAsync(string relativePath, string stepName)
   {
       var path = Path.Combine(_oneBoxRoot, relativePath);

       if (File.Exists(path))
       {
           var content = await File.ReadAllTextAsync(path);
           var lines = content.Split('\n');

           TxtDataOpsResultSummary.Text = $"✓ {stepName} 完了 — {lines.Length}行、{new FileInfo(path).Length / 1024}KB";
           TxtDataOpsResultSummary.Foreground = Brushes.Green;

           // 最初の50行のみ表示（全文は長すぎる場合）
           TxtDataOpsResult.Text = string.Join("\n", lines.Take(50));
           if (lines.Length > 50)
               TxtDataOpsResult.Text += $"\n\n... ({lines.Length - 50}行省略)";
       }
       else
       {
           TxtDataOpsResultSummary.Text = $"✗ {stepName} — ファイルが見つかりません: {relativePath}";
           TxtDataOpsResultSummary.Foreground = Brushes.Red;
           TxtDataOpsResult.Text = "";
       }

       ExpanderDataOpsResult.IsExpanded = true; // 強制展開
   }
   ```

**工数:** 1時間
**リスク:** 極低（表示のみの変更）

---

### 変更D: Secrets空状態ガイド（P2）

**ファイル:** `APP\OneScreenOSApp\MainWindow.xaml` (Secrets section)

**変更内容:**
1. **空状態パネル追加:**
   ```xaml
   <StackPanel x:Name="PanelSecretsEmpty" Visibility="Collapsed"
               HorizontalAlignment="Center" VerticalAlignment="Center"
               Margin="0,40,0,0">
       <TextBlock Text="🔐" FontSize="48" HorizontalAlignment="Center" Margin="0,0,0,12"/>
       <TextBlock Text="シークレットがまだ登録されていません"
                  FontSize="16" FontWeight="Medium" HorizontalAlignment="Center"/>
       <TextBlock Text="API キーやデータベース接続情報などを安全に保存できます"
                  FontSize="13" Foreground="{StaticResource TextMuted}"
                  HorizontalAlignment="Center" Margin="0,8,0,16"/>
       <Button Content="+ シークレットを追加"
               Style="{StaticResource ButtonPrimary}"
               Click="BtnAddSecret_Click" Padding="16,8"/>

       <TextBlock Text="例: API_KEY, DATABASE_URL, AUTH_TOKEN"
                  FontSize="11" Foreground="{StaticResource TextMuted}"
                  HorizontalAlignment="Center" Margin="0,12,0,0"/>
   </StackPanel>
   ```

2. **DataGrid表示/非表示制御:**
   ```csharp
   private async void BtnRefreshSecrets_Click(object sender, RoutedEventArgs e)
   {
       var keys = _secretsVault!.GetAllKeys();

       if (keys.Count == 0)
       {
           DataGridSecrets.Visibility = Visibility.Collapsed;
           PanelSecretsEmpty.Visibility = Visibility.Visible;
       }
       else
       {
           DataGridSecrets.Visibility = Visibility.Visible;
           PanelSecretsEmpty.Visibility = Visibility.Collapsed;

           // 既存のDataGrid表示ロジック
           // ...
       }
   }
   ```

**工数:** 1時間
**リスク:** 極低

---

### 変更E: ビルド警告整理（P2）

**ファイル:** `APP\OneScreenOSApp\OneScreenOSApp.csproj`

**問題:** System.Windows.Forms 参照警告（MSB3245/MSB3243）

**原因調査:**
```xml
<!-- 現状の参照（推定） -->
<ItemGroup>
  <Reference Include="System.Windows.Forms" />
</ItemGroup>
```

**対策:**
1. WinFormsが本当に必要か確認（FolderBrowserDialog用？）
2. 必要なら正しいPackageReference に変更:
   ```xml
   <ItemGroup>
     <PackageReference Include="System.Windows.Forms" Version="8.0.*" />
   </ItemGroup>
   ```
3. 不要なら削除し、代替API使用（例：WPF標準のダイアログ）

**工数:** 1-2時間（調査＋修正＋テスト）
**リスク:** 中（ビルド設定変更、要テスト）

---

## 📊 Phase 3: 影響見積と差分

### 3.1 変更ファイル一覧

| ファイル | 変更内容 | 行数変更 | リスク |
|----------|----------|----------|--------|
| `MainWindow.xaml` | Dashboard/Settings/DataOps/Secrets UI追加 | +150行 | 低 |
| `MainWindow.xaml.cs` | ロジック実装（テンプレ作成/接続テスト/結果表示） | +200行 | 低 |
| `OneScreenOSApp.csproj` | WinForms参照修正 | ±5行 | 中 |
| `_tools\kb_sync_inbox_analyzer.ps1` | 新規（分析のみ） | +300行 | なし |

**合計:** 約655行の追加/変更

### 3.2 新規ファイル

| ファイル | 目的 | サイズ見積 |
|----------|------|-----------|
| `VAULT\06_LOGS\KB_SYNC_INBOX_ANALYSIS_*.md` | KB_SYNC分析レポート | ~10KB |
| `_tools\kb_sync_inbox_analyzer.ps1` | 分析スクリプト | ~12KB |

### 3.3 ビルド後の影響

**予想:**
- OneScreenOSApp.exe: 155.67 MB → ~156 MB（UI追加で微増）
- ビルド警告: 9個 → 3-5個（WinForms参照修正で減少）

### 3.4 ディスク使用量

**変更前:**
- obj/ bin/ フォルダ: 削除済み
- KB_SYNC__INBOX: 29.65 GB（保護）

**変更後:**
- obj/ bin/ フォルダ: 再生成（~11 MB、ビルド後削除推奨）
- KB_SYNC__INBOX: 29.65 GB（変更なし）

**追加容量:** < 1 MB（レポート・スクリプトのみ）

---

## ⚠️ リスク評価

### 低リスク（緑）
- ✅ Dashboard UI強化（既存骨組み利用）
- ✅ Settings接続ガイド（新機能追加）
- ✅ DataOps/Secrets表示改善（表示のみ）
- ✅ KB_SYNC分析（読み取り専用）

### 中リスク（黄）
- ⚠️ ビルド設定変更（WinForms参照）
  - **対策:** 変更前にバックアップ、段階的テスト

### 高リスク（赤）
- ❌ なし

---

## 🧪 Phase 4: テスト計画

### 4.1 Unit Tests（自動化可能）
- [ ] テンプレート作成機能（DECISIONS.md生成）
- [ ] 接続エラー診断（各エラーケース）
- [ ] Pass Check パース（欠損ファイル検出）

### 4.2 Integration Tests（手動）
1. **Dashboard:**
   - Pass Check Failed時に CardBlocker 表示
   - 欠損ファイル一覧表示
   - 「作成」ボタンでテンプレ生成
   - 再検証でPASS確認

2. **Settings:**
   - LM Studio OFF → 接続テスト → エラーメッセージ確認
   - URL変更（http://localhost:5678） → テスト
   - Ollama でも同様にテスト

3. **DataOps:**
   - 各ステップ実行 → 結果プレビュー自動展開確認
   - 長いログ（>50行）の省略表示確認

4. **Secrets:**
   - 空状態 → ガイド表示確認
   - シークレット追加 → DataGrid表示切り替え確認

### 4.3 Regression Tests
- [ ] デスクトップショートカット起動（v2成果）
- [ ] selftest_launch.ps1 全テストPASS
- [ ] ビルド成功（警告減少確認）
- [ ] 全画面遷移（Dashboard/DataOps/Secrets/Providers/Settings）

---

## 📅 Phase 5: 実装スケジュール

**前提:** ユーザーGO後に実施

| タスク | 工数 | 順序 | 依存 |
|--------|------|------|------|
| Dashboard UI強化 | 2-3h | 1 | なし |
| Settings接続ガイド | 2-3h | 2 | なし |
| DataOps/Secrets改善 | 2h | 3 | なし |
| ビルド警告整理 | 1-2h | 4 | なし |
| **統合テスト** | 2h | 5 | 全タスク完了後 |
| **最終ビルド＋VERIFY** | 1h | 6 | テスト完了後 |
| **REPORT作成** | 1h | 7 | VERIFY完了後 |

**合計工数:** 11-15時間（段階的実施可能）

---

## 🚀 Phase 6: 実装方針

### 段階的DO（推奨）
1. **Stage 1:** Dashboard + Settings（P0/P1）→ テスト
2. **Stage 2:** DataOps + Secrets（P1/P2）→ テスト
3. **Stage 3:** ビルド警告整理（P2）→ 最終テスト
4. **Stage 4:** VERIFY + REPORT

**利点:** 各段階でテスト・ロールバック可能

### 一括DO（非推奨）
全変更を一度に実施 → リスク高、デバッグ困難

---

## ✅ Phase 7: 完了条件

### 必須（MUST）
- [ ] Dashboard: Pass Check Failed時の対処UIが完全動作
- [ ] Settings: LM Studio接続テストとエラー診断が動作
- [ ] ビルド成功（dist/OneScreenOSApp.exe生成）
- [ ] selftest_launch.ps1 全テストPASS
- [ ] KB_SYNC__INBOX 未変更（29.65 GB保持）

### 推奨（SHOULD）
- [ ] DataOps結果プレビュー強化
- [ ] Secrets空状態ガイド表示
- [ ] ビルド警告50%以上削減（9個→<5個）

### オプション（MAY）
- [ ] Providersステータスカード化（次イテレーション可）
- [ ] デザイン統一（余白・色・バッジ）

---

## 📝 KB_SYNC__INBOX 最終判断（ユーザー決定必要）

**現状:** 29.65 GB (357,679 files)、削除なしで保護中

**分析結果:**
- .md: 169,890 files（ドキュメント/ノート）
- .json: 152,507 files（ナレッジベースエントリ）
- .zip: OneBox backups（各14MB）

**推奨アクション（次フェーズ）:**
1. **最近30日のファイル:** KEEP（アクティブデータ可能性）
2. **90日以上前のファイル:** ARCHIVE候補（外部ストレージへ）
3. **OneBox backups:** 最新5個 KEEP、古いものはアーカイブ
4. **重複ファイル:** ハッシュ検証後に削除候補

**今回DO範囲:** 分析レポート作成のみ（削除なし）

---

## 🔒 安全柵（ゼロブレイク保証）

### コミット前チェックリスト
- [ ] 既存機能（v2成果）が壊れていないか確認
- [ ] selftest_launch.ps1 PASS
- [ ] デスクトップショートカット動作
- [ ] LAUNCH_ONE_SCREEN_OS.cmd 動作
- [ ] KB_SYNC__INBOX 未変更

### ロールバック手順
1. Git管理下の場合: `git reset --hard HEAD`
2. Git未管理の場合: 変更前のバックアップから復元
3. 緊急時: `_TRASH\20260105_213132\` から復元（v2のクリーンアップ）

---

## 💬 ユーザー承認ポイント

以下を確認の上、**GO/NO-GO**を判断してください：

1. **UI改善の優先度:** Dashboard + Settings を優先実装？
2. **段階的 vs 一括:** Stage 1,2,3 に分けるか、一度に全実装するか？
3. **ビルド警告:** 整理実施するか、次回に延期するか？
4. **KB_SYNC__INBOX:** 今回は分析のみでOK？

**推奨:** 段階的実装（Stage 1 → テスト → Stage 2）

---

**次のアクション:**

ユーザーが **"GO"** と言ったら、Phase 2: DO（実装）を開始します。
特定のStageのみ実施したい場合は、指定してください（例: "Stage 1のみGO"）。

---

**作成者:** UltraSync v3 DRY Agent
**作成日時:** 2026-01-05 22:10
**Status:** ✅ DRY Complete — Awaiting User Approval
```


---


---

## 11_ATTACHMENTS_INVENTORY.md (verbatim)

# ATTACHMENTS_INVENTORY
Generated: 2026-01-08T12:41:17.445443

このファイルは、このプロジェクト資料作成時点で /mnt/data に存在した添付・参照ファイルの一覧です。

|name|bytes|sha256|path|
|---:|---:|---:|---|

|VCG_MASTERPACK_20260108_121401.zip|111996190|28e565e524b94bb11294993bbfc5400ac47ed442745806d3172cdbe89c685e55|/mnt/data/VCG_MASTERPACK_20260108_121401.zip|

|screencapture-grok-c-7f1fd466-5731-4ee2-9c77-e365c382d957-2026-01-08-17_43_54.pdf|35958993|c9bdc1c574bbe8c02e50d4e861538da4e20ed80d98e3bf55fa9205e9f62b445f|/mnt/data/screencapture-grok-c-7f1fd466-5731-4ee2-9c77-e365c382d957-2026-01-08-17_43_54.pdf|

|screencapture-grok-c-7f1fd466-5731-4ee2-9c77-e365c382d957-2026-01-08-17_27_05.pdf|30306029|81017d3b069d28962a6c5b31abd5b7a3e448a5f29bca46c30b0b68ac5a5e8c34|/mnt/data/screencapture-grok-c-7f1fd466-5731-4ee2-9c77-e365c382d957-2026-01-08-17_27_05.pdf|

|screencapture-chat-z-ai-c-72b4912a-233e-46f3-b0b6-62fae46d1bbf-2026-01-08-18_11_29.pdf|10634173|3a6233332e54d41e1a432f5450300510c898da83702a9e5e72e13d39f527cf71|/mnt/data/screencapture-chat-z-ai-c-72b4912a-233e-46f3-b0b6-62fae46d1bbf-2026-01-08-18_11_29.pdf|

|screencapture-chat-z-ai-2026-01-08-18_12_08.pdf|5813901|2c5c5664bae98d853b235c7431701dfb5b8b42de2a7b3f9484e942086de8c610|/mnt/data/screencapture-chat-z-ai-2026-01-08-18_12_08.pdf|

|仕上げの仕上げ - アプリ改善提案.pdf|5568712|4e37dfbd42fba06abea928fc11139cc1d5a9b00c7e6a39e806ca6d3ac8278ee5|/mnt/data/仕上げの仕上げ - アプリ改善提案.pdf|

|screencapture-you-search-2026-01-08-18_12_24.pdf|3108834|d8ca7722cdb10748788e8f0a771087c4182c50135e9b0161cf6744102128d1eb|/mnt/data/screencapture-you-search-2026-01-08-18_12_24.pdf|

|screencapture-chat-z-ai-c-1f7db3ea-2755-4f2b-ab2a-669596e767fb-2026-01-08-18_11_55.pdf|2999085|10ffd3a5901847a9b19be1c72dabc50cde7540fc1b056dbd73c723a33c22e8ac|/mnt/data/screencapture-chat-z-ai-c-1f7db3ea-2755-4f2b-ab2a-669596e767fb-2026-01-08-18_11_55.pdf|

|screencapture-kimi-chat-19b9cd5b-7f52-815d-8000-0989ee0f3f73-2026-01-08-18_16_47.pdf|2005620|ef501f1e8820029f382ed91197061b359ffee390b5e6a1d3efb0acbb039386f5|/mnt/data/screencapture-kimi-chat-19b9cd5b-7f52-815d-8000-0989ee0f3f73-2026-01-08-18_16_47.pdf|

|part_0004.md|1714189|6b6ac79e6d659484d8c4d2a55daf3310e92a186e5870e4a45949cb82cd115b4c|/mnt/data/part_0004.md|

|part_0002.md|1487007|185092625a3780fc1f8ad65ae48e11f387eb75c75dab4b505b72b15e9233d632|/mnt/data/part_0002.md|

|part_0003.md|1403032|6cc9495391a7243f3e5dc9054a83e9acb429188bbf86c5d166912dc468c4c495|/mnt/data/part_0003.md|

|part_0011.md|1121039|cd62a8ed190324c46fd1795e0b4278fe8877b05d988a646918c848afd2809238|/mnt/data/part_0011.md|

|part_0020.md|1070591|cb42cb9545eff4588aa113d1f93b58706a20fde505cf6d10b89f7dd3ec2a8626|/mnt/data/part_0020.md|

|part_0019.md|1047656|bd2b7d559a5387049ff12f93a559a027ee20fbbbf8a283997e5f40324e3f1315|/mnt/data/part_0019.md|

|part_0017.md|1018962|4e362e19023426feaa91c90eb7b8d75051ab46e4edba962c272448081986cd45|/mnt/data/part_0017.md|

|part_0013.md|1005742|468b679a00cdabff8bcbbc66c1181ae632b820bc2e9c88afc9b964205fcc0001|/mnt/data/part_0013.md|

|part_0009.md|1001289|698891b6256b10ec4231745d3385436d8dcb6b45310f322c4559f7bc965ef1b1|/mnt/data/part_0009.md|

|part_0018.md|997865|a212f6e53f411ad6ef2f0c7af8f2fff2cf07120a828d4de7da80965cc30935a6|/mnt/data/part_0018.md|

|part_0023.md|980422|897f5ecc679fd56c1974b9d7cbb5dadf2c22eba1d0e15d6e48e0124a02d702ed|/mnt/data/part_0023.md|

|part_0005.md|970355|b1d3b4cee752dce2cee30df30ec05870b7950b52f30aa8179cd6e0e610e523ba|/mnt/data/part_0005.md|

|part_0022.md|969952|8ddbc71d22276c9a73d53946e1cda60e6c897b0b399e7f1a85042e3e9432b77f|/mnt/data/part_0022.md|

|part_0016.md|957498|55e0f955979e69da41637eee6b47e287fdc57779914d0777b93daf125babd8ce|/mnt/data/part_0016.md|

|part_0012.md|955932|52b37801fec605e5658c543c448e39d74f3a6c8d05d70c3dc01f6669c8eccf60|/mnt/data/part_0012.md|

|part_0014.md|951575|fad08b7599714cdd1375e171d79b2dd218db60d640a2dd2a9d76f7b1d81e6850|/mnt/data/part_0014.md|

|part_0026.md|950640|f940d721597a0f17a6010f31e9b6dfde86c5648eba9ef64fdde59fdad6f49ba5|/mnt/data/part_0026.md|

|part_0010.md|942881|301f7ac9df68aa0711f75c83a2ddc8fb64b80b48db95139071160adcf7e35de3|/mnt/data/part_0010.md|

|part_0015.md|919660|d3e3f76a38bd94ee300d993ba1cfe7f8b1cca36c742eb083c1b181c83c674c74|/mnt/data/part_0015.md|

|part_0007.md|888877|86e789004d7e672119f0bd32d258963e28d24f822005c31b71269cd3d5f0cb2c|/mnt/data/part_0007.md|

|part_0021.md|882698|7089fc0780da9541d5fb338b927608dfea723c7960786cee0d700c0497e435ea|/mnt/data/part_0021.md|

|part_0008.md|860468|a4cbc6f27dfc25722d00eac4e8e4de049b6b800dd66b91bfddd396faf33df4e7|/mnt/data/part_0008.md|

|part_0001.md|812476|fbff12bf695d8ed49ce0ce9a0c8751f0342e879ac1b3fb09607b70716136340f|/mnt/data/part_0001.md|

|part_0006.md|731563|f5e61f1b9b444e5c3c274552f2eba5044d9da2cda19c36acdb4ad2569abf64e6|/mnt/data/part_0006.md|

|03_UI_SCREENSHOTS.pdf|571665|577110f2a3a1d1cd779ffd57809462c9e1885ab8c3b004f0942b4150422c9172|/mnt/data/03_UI_SCREENSHOTS.pdf|

|grok_pdf_p2.png|502957|8561b707b6bd874770c7412e18d43afdc192828ac9680484349ba10986d7ec60|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/d0dd5baad0ab4af183c0f3e3c2eb53c3/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p2.png|

|grok_pdf_p2.png|502957|8561b707b6bd874770c7412e18d43afdc192828ac9680484349ba10986d7ec60|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p2.png|

|grok_pdf_p2.png|502957|8561b707b6bd874770c7412e18d43afdc192828ac9680484349ba10986d7ec60|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p2.png|

|grok_pdf_p1.png|473385|a49febc08210d933c8ace595cc15444acba9fbe4735c921f0730b5bfae31d009|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/d0dd5baad0ab4af183c0f3e3c2eb53c3/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p1.png|

|grok_pdf_p1.png|473385|a49febc08210d933c8ace595cc15444acba9fbe4735c921f0730b5bfae31d009|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p1.png|

|grok_pdf_p1.png|473385|a49febc08210d933c8ace595cc15444acba9fbe4735c921f0730b5bfae31d009|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p1.png|

|grok_pdf_p3.png|463336|29309e24291f61cce7156402c57da9ee679ecb8410f90ece98aa9ace9d47fdc2|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/d0dd5baad0ab4af183c0f3e3c2eb53c3/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p3.png|

|grok_pdf_p3.png|463336|29309e24291f61cce7156402c57da9ee679ecb8410f90ece98aa9ace9d47fdc2|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p3.png|

|grok_pdf_p3.png|463336|29309e24291f61cce7156402c57da9ee679ecb8410f90ece98aa9ace9d47fdc2|/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/user-AlaLaVW2v6q1LtXueqWhJQhd/228f37114a1243a8bd369d7c26d6c744/mnt/data/grok_pdf_p3.png|

|21_LOGS_AND_REPORTS_EXCERPTS.md|87138|43e46dbc480aceab55d0aee7a5ffca5a747b132b05be57db98a64fb248d3397d|/mnt/data/21_LOGS_AND_REPORTS_EXCERPTS.md|

|11_CODE__MainWindow_xaml_cs__FULL.md|74161|fa9ec9217005bed6c4f114323e0694414e95dd3c072fc7917f3fa4fb88d50cfd|/mnt/data/11_CODE__MainWindow_xaml_cs__FULL.md|

|09_CODE__MainWindow_xaml__FULL.md|54206|0503eb209727f4bc84da16ce2594641f5634bfb38b939e559dae4d27ff77c472|/mnt/data/09_CODE__MainWindow_xaml__FULL.md|

|vibe_large_scale_upgrade_kit_v2.zip|37383|5849b74b819e19449eae9eb75db482b31d7661a1c2edc8c02cac593a500921e8|/mnt/data/vibe_large_scale_upgrade_kit_v2.zip|

|onebox.zip|33954|9561bb25ab0297e68885f95478a1b465312d4d6d2380cf27bc916b586e45398c|/mnt/data/onebox.zip|

|vibe_large_scale_upgrade_kit_v3.zip|33877|e346f63627e5c8dd980e349a5db83a2bec69a8f6b294372f8096d90884e27398|/mnt/data/vibe_large_scale_upgrade_kit_v3.zip|

|vibe_large_scale_upgrade_kit_v1.zip|30023|8608b4eaa64a00da23a120969e38ab6562320281edc3fd3a33a1e6cb7bf1883c|/mnt/data/vibe_large_scale_upgrade_kit_v1.zip|

|18_TOOLS__ULTRASYNC_DRY_PROPOSAL__FULL.md|22555|b054c0594bd5fea3fb53ef733ecd1a23748e0dd57bd65311b1ed13ac2cb02440|/mnt/data/18_TOOLS__ULTRASYNC_DRY_PROPOSAL__FULL.md|

|10_CODE__App_xaml__FULL.md|16407|6e6d2a5db363535a5731488345a5a68741365c382207c4912e38c033985e1dcd|/mnt/data/10_CODE__App_xaml__FULL.md|

|15_SCRIPT__selftest_launch_enhanced_ps1__FULL.md|16393|87e570b7eed8f21973e0fab55accb86ecabb1516cca80386fb63a8312d176a48|/mnt/data/15_SCRIPT__selftest_launch_enhanced_ps1__FULL.md|

|17_TOOLS__ULTRASYNC_PLAN__FULL.md|10673|31c589c0dbb1d7ea8a1c695d4ce46f527f1e6354baa13a5b8912caf66d91b933|/mnt/data/17_TOOLS__ULTRASYNC_PLAN__FULL.md|

|16_SCRIPT__doctor_activate_ps1__FULL.md|10212|a89d44d5380e0b502c1992a162a698dd399928d640a9a9a2d4a5c7d5e6ce5ad5|/mnt/data/16_SCRIPT__doctor_activate_ps1__FULL.md|

|19_TOOLS__kb_sync_inbox_analyzer_ps1__FULL.md|9547|b78425be828d09baf9e4430f2793c5e9bc461915e64000aeb87cfdd5702ccd54|/mnt/data/19_TOOLS__kb_sync_inbox_analyzer_ps1__FULL.md|

|12_CODE__App_xaml_cs__FULL.md|7404|0469403e2765f67c0eda034fbdb4a08ce1af31c0a1290fd32a73f11db2e69c80|/mnt/data/12_CODE__App_xaml_cs__FULL.md|

|20_RUN_CMDS__FULL.md|7023|339d37c32207f73e30ffe82bbc31e3913cfa585665bb1985505a6badc044cfdb|/mnt/data/20_RUN_CMDS__FULL.md|

|23_CLAUDE_CODE_ONE_SHOT_PROMPT.md|4397|dce9357253783f860b77e5b2668f0b7fa304660ba92f11623cf40ea092853e2e|/mnt/data/23_CLAUDE_CODE_ONE_SHOT_PROMPT.md|

|14_SCRIPT__build_publish_ps1__FULL.md|4209|aaa2346f8b4217674b30140581e6a039ef7d3dab93c541ac5cc97fa0436ad2c7|/mnt/data/14_SCRIPT__build_publish_ps1__FULL.md|

|00_INDEX.md|2130|f46925e5a70b79ce200b779a7fcb4402118292fdc5ca4e1e868cdc41a9335b44|/mnt/data/00_INDEX.md|

|06_FIX_CHECKLIST_BUILD_WPF.md|1851|b5930927b1ae8cf05791357b04cd405dbeeb0fe8428027396aa4163168f3bd34|/mnt/data/06_FIX_CHECKLIST_BUILD_WPF.md|

|02_HOW_TO_RUN_APP.md|1656|83f764cd3f9038741a4e1ce1198fdf09ea5a3f2279184a6b5ffe70770c54ba31|/mnt/data/02_HOW_TO_RUN_APP.md|

|13_CODE__OneScreenOSApp_csproj__FULL.md|1222|0a268b0a894477d1b2412f2d3bd935626b18459d8329637898eb1d25586a984a|/mnt/data/13_CODE__OneScreenOSApp_csproj__FULL.md|

|05_CURRENT_BUILD_FAILURE_148_ERRORS.md|1183|d0f098d8501c1c65c970b52b45e9d86325cee91e0f91c291862bbcd7ed803e83|/mnt/data/05_CURRENT_BUILD_FAILURE_148_ERRORS.md|

|22_BACKLOG_P0_P1_P2.md|1102|f7eb0f75ec006d9a9407b4ad7090672b9a48ee5f9bbdf024716a0a66ad591ba3|/mnt/data/22_BACKLOG_P0_P1_P2.md|

|24_APPENDIX_MANIFEST_HASHES.md|1007|90b413e0aea27c96ed5ac56c5307f1176e27b12fe3e3e088963455292ef67185|/mnt/data/24_APPENDIX_MANIFEST_HASHES.md|

|07_PATCH_TOGGLE_SECONDARY_STYLE.md|967|35c3aaec36f21cfb95b58073a9680426f793a2cdd7f2edc00eb72007239e05c7|/mnt/data/07_PATCH_TOGGLE_SECONDARY_STYLE.md|

|01_PROJECT_OVERVIEW.md|834|de6daed76e73966e24d80c34babce048d6624a796ed4c1c19373ea0ae4cceca4|/mnt/data/01_PROJECT_OVERVIEW.md|

|04_ROOT_CAUSE_XAML_PARSE_EXCEPTION.md|725|a9fa2c0357058c72334d3fd692d86d1c7659cb2c21848ca9136c513a073bdb10|/mnt/data/04_ROOT_CAUSE_XAML_PARSE_EXCEPTION.md|

|08_PATCH_TOGGLEINSIGHTDETAILS_REFERENCE.md|337|cd6f469b265ce2e72854c47e4be5a6bedc8b85b45e768349f0b2c1698d7eb743|/mnt/data/08_PATCH_TOGGLEINSIGHTDETAILS_REFERENCE.md|


---


---

## 12_HASHES_AND_MANIFEST.md (verbatim)

# HASHES_AND_MANIFEST
## 元の25ファイル版（24_APPENDIX_MANIFEST_HASHES.md）
# 24 参照ソースのSHA-256（このKB生成時点）

- `03_UI_SCREENSHOTS.pdf` : `577110f2a3a1d1cd779ffd57809462c9e1885ab8c3b004f0942b4150422c9172`
- `APP.zip` : `75d9f2102f38eb061194104de3b01a2879659d51851bc2e9e0a7889c86bb7c85`
- `App.g.cs` : `c3be5039a0edd1ad36eca942eb8dc8fbda665f9c3b367c4e8d365b4945653015`
- `App.xaml.cs` : `ff936ddb6a7f1e1eb80d153f1e375022a3dfa06e3f781b33466d53bda5ed4428`
- `CORE.zip` : `45e1c3ea86f032653533a1fe8c5a6d3238db6c574bce5bdf98a8498a51fdfbcd`
- `MainWindow.g.cs` : `bcaffb479a012566a381bb0ecb7816b4ce9b908fab827fc17f4df1e0af74d728`
- `MainWindow.xaml` : `ff3c02c21e28441e0b81a95a55c2e430c8e3bd62f25df9869ff8045787dbf339`
- `MainWindow.xaml.cs` : `3581ed8a6f1cb5d7c2c94b9a6611623c5f417093e440c97c2eac8ac1e39e2052`
- `PROJECTS.zip` : `1be6ba2f82a3b146cfb6eaf9a3b87aa32ca545f387db92c04338ba005668000d`
- `VAULT.zip` : `edd5a4d42afdd11dceabbee8cff142849649e499a5a198a63bcd418ab5dd0b6f`
- `_tools.zip` : `bde9691bc98b5791be98972fc7fcefa02b435913e071bfdd48c11591ff87a39b`

---

## この“完全版”のファイルハッシュ
（MANIFESTで自動生成）
