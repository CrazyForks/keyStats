using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Reflection;
using System.IO;
using System.Drawing;
using KeyStats.Helpers;
using KeyStats.Services;
using KeyStats.Views;
using DrawingIcon = System.Drawing.Icon;

namespace KeyStats.ViewModels;

public class TrayIconViewModel : ViewModelBase
{
    private DrawingIcon? _trayIcon;
    private string _tooltipText = "KeyStats";
    private StatsPopupWindow? _popupWindow;
    private SettingsWindow? _settingsWindow;

    public DrawingIcon? TrayIcon
    {
        get => _trayIcon;
        set => SetProperty(ref _trayIcon, value);
    }

    public string TooltipText
    {
        get => _tooltipText;
        set => SetProperty(ref _tooltipText, value);
    }

    public ICommand TogglePopupCommand { get; }
    public ICommand ShowStatsCommand { get; }
    public ICommand ShowSettingsCommand { get; }
    public ICommand QuitCommand { get; }

    public TrayIconViewModel()
    {
        TogglePopupCommand = new RelayCommand(TogglePopup);
        ShowStatsCommand = new RelayCommand(ShowStats);
        ShowSettingsCommand = new RelayCommand(ShowSettings);
        QuitCommand = new RelayCommand(Quit);

        UpdateTrayIcon();
        UpdateTooltip();

        StatsManager.Instance.TrayUpdateRequested += OnTrayUpdateRequested;
    }

    private void OnTrayUpdateRequested()
    {
        Application.Current?.Dispatcher.Invoke(() =>
        {
            UpdateTrayIcon();
            UpdateTooltip();
        });
    }

    private void UpdateTrayIcon()
    {
        // 使用静态图标文件
        try
        {
            var assembly = Assembly.GetExecutingAssembly();
            var resourceName = "KeyStats.Resources.Icons.tray-icon.png";
            
            using var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream != null)
            {
                using var bitmap = new Bitmap(stream);
                // 转换为图标，使用系统托盘图标大小
                int iconSize = GetSystemTrayIconSize();
                using var resizedBitmap = new Bitmap(bitmap, iconSize, iconSize);
                TrayIcon = Icon.FromHandle(resizedBitmap.GetHicon());
                return;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading tray icon: {ex.Message}");
        }

        // 如果加载失败，尝试从文件系统加载
        try
        {
            var exePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            var iconPath = Path.Combine(exePath ?? "", "Resources", "Icons", "tray-icon.png");
            if (File.Exists(iconPath))
            {
                using var bitmap = new Bitmap(iconPath);
                int iconSize = GetSystemTrayIconSize();
                using var resizedBitmap = new Bitmap(bitmap, iconSize, iconSize);
                TrayIcon = Icon.FromHandle(resizedBitmap.GetHicon());
                return;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading tray icon from file: {ex.Message}");
        }

        // 如果都失败，使用默认的动态生成图标
        TrayIcon = IconGenerator.CreateTrayIconKeyboard();
    }

    private static int GetSystemTrayIconSize()
    {
        // Get DPI scale factor
        using var screen = Graphics.FromHwnd(IntPtr.Zero);
        var dpiX = screen.DpiX;

        // Base size is 16 at 96 DPI (100%)
        int size = (int)(16 * dpiX / 96);

        // Clamp to reasonable sizes
        if (size <= 16) return 16;
        if (size <= 20) return 20;
        if (size <= 24) return 24;
        if (size <= 32) return 32;
        if (size <= 48) return 48;
        return 64;
    }

    private void UpdateTooltip()
    {
        TooltipText = StatsManager.Instance.GetTooltipText();
    }

    private void TogglePopup()
    {
        Console.WriteLine("=== TogglePopup called ===");
        try
        {
            if (_popupWindow != null && _popupWindow.IsVisible)
            {
                Console.WriteLine("Closing existing window");
                _popupWindow.Close();
                _popupWindow = null;
            }
            else
            {
                Console.WriteLine("Calling ShowStats...");
                ShowStats();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"TogglePopup error: {ex}");
        }
    }

    private void ShowStats()
    {
        try
        {
            Console.WriteLine("ShowStats called...");
            if (_popupWindow != null)
            {
                _popupWindow.Activate();
                return;
            }

            Console.WriteLine("Creating StatsPopupWindow...");
            _popupWindow = new StatsPopupWindow();
            _popupWindow.Closed += (_, _) => _popupWindow = null;
            Console.WriteLine("Showing window...");
            _popupWindow.Show();
            Console.WriteLine("Window shown.");
        }
        catch (Exception ex)
        {
            Console.WriteLine("=== ERROR IN SHOWSTATS ===");
            Console.WriteLine(ex.ToString());
            Console.WriteLine("=== END ERROR ===");
        }
    }

    private void ShowSettings()
    {
        if (_settingsWindow != null)
        {
            _settingsWindow.Activate();
            return;
        }

        _settingsWindow = new SettingsWindow();
        _settingsWindow.Closed += (_, _) => _settingsWindow = null;
        _settingsWindow.Show();
    }

    private void Quit()
    {
        StatsManager.Instance.FlushPendingSave();
        InputMonitorService.Instance.StopMonitoring();
        Application.Current.Shutdown();
    }

    public void Cleanup()
    {
        StatsManager.Instance.TrayUpdateRequested -= OnTrayUpdateRequested;
    }
}
