class AppConsts{
  static const String dbName = 'peakflow.db';
  static const String entriesTable = 'entries';
  static const String settingsTable = 'settings';

  static const double upperThreshold = 200;
  static const double lowerThreshold = 100;

  static const double maxYValue = 1000;
  static const double minYValue = 0;
  static const double yInterval = 100;
}


// All user-facing strings for easy translation

class AppStrings {
  static String currentLanguage = 'zh'; // 'en';
  // set default to Mandarin Chinese in 0.1.9

  // Month name tables (used by chart axis labels)
  static const Map<String, List<String>> _monthNames = {
    'en': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
    'zh': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
  };
  static List<String> getMonthNames() {
    return _monthNames[currentLanguage] ?? _monthNames['en']!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Peak Flow Meter',
      'graphTitle': 'Graph',
      'addEntry': 'Add Entry',
      'editEntry': 'Edit Entry',
      'peakFlowValue': 'Please enter peak flow value here:',
      'symptoms': 'Symptoms',
      'pickDate': 'Pick Date',
      'pickTime': 'Pick Time',
      'cancel': 'Cancel',
      'add': 'Add',
      'save': 'Save',
      'deleteEntry': 'Delete Entry',
      'deleteEntryConfirm': 'Are you sure you want to delete this entry?',
      'delete': 'Delete',
      'noEntries': 'No entries yet. Tap + to add your first entry!',
      'value': 'Value',
      'symptomsLabel': 'Symptoms:',
      'exportDataCSV': 'Export Data (CSV)',
      'exportChartImage': 'Export Chart (Image)',
      'exportedCSV': 'Exported CSV',
      'exportedChartImage': 'Exported Chart Image',
      'csvExported': 'CSV Exported',
      'csvSave': 'CSV file saved to',
      'chartImageExported': 'Chart Image Exported',
      'chartImageSave': 'Image file saved to',
      'date': 'Date',
      'time': 'Time',
      'morning': 'Morning',
      'night': 'Night',
      'symptomatic': 'Symptomatic',
      'symptomsHint': 'e.g., cough, wheeze, shortness of breath',
      'open': 'Open',
      'close': 'Close',
      'startDate': 'Start Date',
      'endDate': 'End Date',
      'start': 'Start',
      'end': 'End',
      'clearRange': 'Clear range',
      'upperThreshold': 'Upper Threshold',
      'lowerThreshold': 'Lower Threshold',
      'notEnoughData': 'Not enough data to display a graph. Add at least 2 entries.',
      'thresholdValidationError': 'Upper threshold must be higher than lower threshold',
      'thresholdCorrected': 'Threshold values have been automatically corrected',
      'language': 'Language',
      'english': 'English',
      'chinese': '繁體中文',
      'notSelected': 'Not selected',
      'guide': 'Guide',
      'welcomeTitle': 'Welcome to Peak Flow Meter!',
      'welcomeSubtitle': 'Track your breathing health easily',
      'welcomeDescription': 'This guide will walk you through the key features of the Peak Flow Meter app to help you track your respiratory health effectively.',
      'guideStep1Title': 'Step 1: Add Your First Entry',
      'guideStep1Desc': 'Tap the "+" button to record your peak flow reading. Enter the value from your peak flow meter and select whether it was taken in the morning, night, or when you had symptoms.',
      'guideStep2Title': 'Step 2: Track Symptoms',
      'guideStep2Desc': 'When recording a symptomatic reading, you can add details about your symptoms like cough, wheeze, or shortness of breath.',
      'guideStep3Title': 'Step 3: View Your Progress',
      'guideStep3Desc': 'Tap the chart icon to see your readings over time. The colored zones help you understand your breathing patterns.',
      'guideStep4Title': 'Step 4: Export Your Data',
      'guideStep4Desc': 'In the chart view, use the export menu to save your data as a CSV file or chart image to share with your doctor.',
      'guideStep5Title': 'Tips for Best Results',
      'guideStep5Desc': 'Take readings at the same times daily, record symptoms when they occur, and bring your data to medical appointments.',
      'getStarted': 'Get Started',
      'next': 'Next',
      'previous': 'Previous',
      'skipGuide': 'Skip Guide',
      'noAppToOpenCSV': 'No app found to open CSV files',
      'needSpreadsheetApp': 'You may need to install a spreadsheet app (Excel, Google Sheets)',
      'copyPath': 'Copy Path',
      'noAppToOpenImage': 'No app found to open image files',
      'needImageApp': 'You may need to install a photo or gallery app',
      'pathCopied': 'Path copied to clipboard',
      'fileSavedToDocuments': 'File saved to app documents. Use "Files" app to access.',
    },
    'zh': {
      'appTitle': '尖端吐氣流量值',
      'graphTitle': '圖表',
      'addEntry': '新增紀錄',
      'editEntry': '編輯記錄',
      'peakFlowValue': '請在此輸入尖端吐氣流量值：',
      'symptoms': '症狀',
      'pickDate': '選擇日期',
      'pickTime': '選擇時間',
      'cancel': '取消',
      'add': '新增',
      'save': '儲存',
      'deleteEntry': '刪除紀錄',
      'deleteEntryConfirm': '確定要刪除此紀錄嗎？',
      'delete': '刪除',
      'noEntries': '暫無紀錄，按"+"新增資料！',
      'value': '數值',
      'symptomsLabel': '症狀：',
      'exportDataCSV': '匯出報表',
      'exportChartImage': '匯出圖片',
      'exportedCSV': 'CSV 已匯出',
      'exportedChartImage': '圖片已匯出',
      'csvExported': '報表已匯出',
      'csvSave': '檔案已儲存至',
      'chartImageExported': '圖片已匯出',
      'chartImageSave': '圖片已儲存至',
      'date': '日期',
      'time': '時間',
      'morning': '早上',
      'night': '晚上',
      'symptomatic': '有症狀時',
      'symptomsHint': '例如：咳嗽、喘、呼吸急促',
      'open': '打開',
      'close': '關閉',
      'startDate': '開始日期',
      'endDate': '結束日期',
      'start': '開始',
      'end': '結束',
      'clearRange': '清除區間',
      'upperThreshold': '高閾值',
      'lowerThreshold': '低閾值',
      'notEnoughData': '數據不足，至少需要兩筆資料。',
      'thresholdValidationError': '高閾值必須高於低閾值',
      'thresholdCorrected': '閾值已自動校正',
      'language': '語言',
      'english': 'English',
      'chinese': '繁體中文',
      'notSelected': '未選擇',
      'guide': '使用指南',
      'welcomeTitle': '歡迎使用尖端吐氣流量計！',
      'welcomeSubtitle': '輕鬆追蹤您的呼吸健康',
      'welcomeDescription': '本指南將引導您了解尖端吐氣流量計應用程式的主要功能，幫助您有效追蹤呼吸健康。',
      'guideStep1Title': '步驟1：新增您的第一筆記錄',
      'guideStep1Desc': '點擊"+"按鈕記錄您的尖端吐氣流量讀數。輸入從尖端吐氣流量計得到的數值，並選擇是在早上、晚上或有症狀時測量的。',
      'guideStep2Title': '步驟2：記錄症狀',
      'guideStep2Desc': '記錄有症狀時的讀數時，您可以添加症狀詳情，如咳嗽、喘鳴或呼吸急促。',
      'guideStep3Title': '步驟3：查看您的進展',
      'guideStep3Desc': '點擊圖表圖標查看您隨時間變化的讀數。彩色區域幫助您了解呼吸模式。',
      'guideStep4Title': '步驟4：匯出您的數據',
      'guideStep4Desc': '在圖表檢視中，使用匯出選單將數據保存為CSV檔案或圖表圖片，以便與醫生分享。',
      'guideStep5Title': '獲得最佳結果的提示',
      'guideStep5Desc': '每天在相同時間測量，出現症狀時記錄，並將數據帶到醫療預約中。',
      'getStarted': '開始使用',
      'next': '下一步',
      'previous': '上一步',
      'skipGuide': '跳過指南',
      'noAppToOpenCSV': '找不到可開啟CSV檔案的應用程式',
      'needSpreadsheetApp': '您可能需要安裝試算表應用程式（Excel、Google試算表）',
      'copyPath': '複製路徑',
      'noAppToOpenImage': '找不到可開啟圖片檔案的應用程式',
      'needImageApp': '您可能需要安裝相片或相簿應用程式',
      'pathCopied': '路徑已複製到剪貼板',
      'fileSavedToDocuments': '檔案已儲存至應用程式文件。請使用「檔案」應用程式存取。',
    },
  };

  static String get(String key) {
    return _localizedValues[currentLanguage]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}
