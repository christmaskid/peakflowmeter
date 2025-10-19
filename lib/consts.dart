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
    },
    'zh': {
      'appTitle': '尖端吐氣流量值紀錄',
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
    },
  };

  static String get(String key) {
    return _localizedValues[currentLanguage]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}
