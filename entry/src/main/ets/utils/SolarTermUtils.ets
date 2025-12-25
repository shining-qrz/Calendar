// 二十四节气工具类（精确计算版）
export class SolarTermUtils {
  
  // 二十四节气名称
  private static readonly SOLAR_TERMS: string[] = [
    '小寒', '大寒', '立春', '雨水', '惊蛰', '春分',
    '清明', '谷雨', '立夏', '小满', '芒种', '夏至',
    '小暑', '大暑', '立秋', '处暑', '白露', '秋分',
    '寒露', '霜降', '立冬', '小雪', '大雪', '冬至'
  ];
  
  // 2025年二十四节气精确日期（基于天文数据）
  private static readonly SOLAR_TERMS_2025: Map<string, string> = new Map([
    ['01-05', '小寒'], ['01-20', '大寒'],
    ['02-04', '立春'], ['02-18', '雨水'],
    ['03-05', '惊蛰'], ['03-20', '春分'],
    ['04-04', '清明'], ['04-20', '谷雨'],
    ['05-05', '立夏'], ['05-21', '小满'],
    ['06-05', '芒种'], ['06-21', '夏至'],
    ['07-07', '小暑'], ['07-22', '大暑'],
    ['08-07', '立秋'], ['08-23', '处暑'],
    ['09-07', '白露'], ['09-23', '秋分'],
    ['10-08', '寒露'], ['10-23', '霜降'],
    ['11-07', '立冬'], ['11-22', '小雪'],
    ['12-07', '大雪'], ['12-21', '冬至']
  ]);
  
  // 2024年二十四节气精确日期
  private static readonly SOLAR_TERMS_2024: Map<string, string> = new Map([
    ['01-06', '小寒'], ['01-20', '大寒'],
    ['02-04', '立春'], ['02-19', '雨水'],
    ['03-05', '惊蛰'], ['03-20', '春分'],
    ['04-04', '清明'], ['04-19', '谷雨'],
    ['05-05', '立夏'], ['05-20', '小满'],
    ['06-05', '芒种'], ['06-21', '夏至'],
    ['07-06', '小暑'], ['07-22', '大暑'],
    ['08-07', '立秋'], ['08-22', '处暑'],
    ['09-07', '白露'], ['09-22', '秋分'],
    ['10-08', '寒露'], ['10-23', '霜降'],
    ['11-07', '立冬'], ['11-22', '小雪'],
    ['12-06', '大雪'], ['12-21', '冬至']
  ]);
  
  // 2026年二十四节气精确日期
  private static readonly SOLAR_TERMS_2026: Map<string, string> = new Map([
    ['01-05', '小寒'], ['01-20', '大寒'],
    ['02-03', '立春'], ['02-18', '雨水'],
    ['03-05', '惊蛰'], ['03-20', '春分'],
    ['04-04', '清明'], ['04-20', '谷雨'],
    ['05-05', '立夏'], ['05-21', '小满'],
    ['06-05', '芒种'], ['06-21', '夏至'],
    ['07-07', '小暑'], ['07-22', '大暑'],
    ['08-07', '立秋'], ['08-23', '处暑'],
    ['09-07', '白露'], ['09-23', '秋分'],
    ['10-08', '寒露'], ['10-23', '霜降'],
    ['11-07', '立冬'], ['11-22', '小雪'],
    ['12-07', '大雪'], ['12-21', '冬至']
  ]);
  
  // 获取指定年份的节气数据
  private static getYearSolarTermsData(year: number): Map<string, string> {
    switch (year) {
      case 2024:
        return SolarTermUtils.SOLAR_TERMS_2024;
      case 2025:
        return SolarTermUtils.SOLAR_TERMS_2025;
      case 2026:
        return SolarTermUtils.SOLAR_TERMS_2026;
      default:
        // 对于其他年份，使用2025年的数据作为近似值
        return SolarTermUtils.SOLAR_TERMS_2025;
    }
  }
  
  // 获取指定日期的节气信息（精确匹配）
  static getSolarTerm(date: Date): string | null {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    
    const dateKey = `${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const yearSolarTerms = SolarTermUtils.getYearSolarTermsData(year);
    
    return yearSolarTerms.get(dateKey) || null;
  }
  
  // 判断是否为节气日（精确匹配）
  static isSolarTerm(date: Date): boolean {
    return SolarTermUtils.getSolarTerm(date) !== null;
  }
  
  // 获取指定年份的所有节气日期
  static getYearSolarTerms(year: number): Map<string, Date> {
    const yearTermsData = SolarTermUtils.getYearSolarTermsData(year);
    const yearTerms = new Map<string, Date>();
    
    for (const entry of yearTermsData) {
      const dateKey = entry[0];
      const termName = entry[1];
      const dateParts = dateKey.split('-');
      const monthStr = dateParts[0];
      const dayStr = dateParts[1];
      const month = parseInt(monthStr) - 1; // Date对象的月份从0开始
      const day = parseInt(dayStr);
      const termDate = new Date(year, month, day);
      
      yearTerms.set(dateKey, termDate);
    }
    
    return yearTerms;
  }
}