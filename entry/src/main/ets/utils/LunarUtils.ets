// 农历月份信息接口
interface LunarMonthInfo {
  month: number;
  days: number;
  startDate: Date;
}

// 农历信息接口
interface LunarInfo {
  month: number;
  day: number;
  monthName: string;
  dayName: string;
}

// 农历工具类
export class LunarUtils {
  
  // 农历月份名称
  private static readonly LUNAR_MONTHS: string[] = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月'
  ];
  
  // 农历日期名称
  private static readonly LUNAR_DAYS: string[] = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'
  ];
  
  // 传统节日映射（简化版本，使用公历日期近似）
  private static readonly FESTIVALS = new Map<string, string>([
    // 固定公历节日
    ['01-01', '元旦'],
    ['02-14', '情人节'],
    ['03-08', '妇女节'],
    ['03-12', '植树节'],
    ['04-01', '愚人节'],
    ['05-01', '劳动节'],
    ['05-04', '青年节'],
    ['06-01', '儿童节'],
    ['07-01', '建党节'],
    ['08-01', '建军节'],
    ['09-10', '教师节'],
    ['10-01', '国庆节'],
    ['12-24', '平安夜'],
    ['12-25', '圣诞节'],
    
    // 农历节日（使用近似公历日期）
    ['02-10', '春节'], // 2025年春节大约在2月
    ['02-24', '元宵节'],
    ['04-05', '清明节'],
    ['05-31', '端午节'], // 2025年端午节大约在5月底
    ['08-29', '中秋节'], // 2025年中秋节大约在8月底
    ['10-11', '重阳节']
  ]);
  
  // 简化的农历数据（2025年）
  private static getLunar2025Data(): LunarMonthInfo[] {
    const data: LunarMonthInfo[] = [];
    
    data.push({ month: 1, days: 29, startDate: new Date(2025, 0, 29) }); // 正月
    data.push({ month: 2, days: 30, startDate: new Date(2025, 1, 28) }); // 二月
    data.push({ month: 3, days: 29, startDate: new Date(2025, 2, 29) }); // 三月
    data.push({ month: 4, days: 30, startDate: new Date(2025, 3, 28) }); // 四月
    data.push({ month: 5, days: 29, startDate: new Date(2025, 4, 27) }); // 五月
    data.push({ month: 6, days: 30, startDate: new Date(2025, 5, 26) }); // 六月
    data.push({ month: 7, days: 29, startDate: new Date(2025, 6, 25) }); // 七月
    data.push({ month: 8, days: 30, startDate: new Date(2025, 7, 24) }); // 八月
    data.push({ month: 9, days: 29, startDate: new Date(2025, 8, 22) }); // 九月
    data.push({ month: 10, days: 30, startDate: new Date(2025, 9, 22) }); // 十月
    data.push({ month: 11, days: 29, startDate: new Date(2025, 10, 20) }); // 十一月
    data.push({ month: 12, days: 30, startDate: new Date(2025, 11, 20) }); // 十二月
    
    return data;
  }
  
  // 获取农历信息
  static getLunarInfo(date: Date): LunarInfo {
    const year = date.getFullYear();
    
    // 简化处理，只处理2025年
    if (year === 2025) {
      const lunarData = LunarUtils.getLunar2025Data();
      for (let i = 0; i < lunarData.length; i++) {
        const lunarMonth = lunarData[i];
        const startDate = lunarMonth.startDate;
        const endDate = new Date(startDate);
        endDate.setDate(startDate.getDate() + lunarMonth.days - 1);
        
        if (date >= startDate && date <= endDate) {
          const day = Math.floor((date.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000)) + 1;
          const result: LunarInfo = {
            month: lunarMonth.month,
            day: day,
            monthName: LunarUtils.LUNAR_MONTHS[lunarMonth.month - 1],
            dayName: LunarUtils.LUNAR_DAYS[day - 1]
          };
          return result;
        }
      }
    }
    
    // 默认返回（其他年份的简化处理）
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const defaultResult: LunarInfo = {
      month: month,
      day: day,
      monthName: LunarUtils.LUNAR_MONTHS[month - 1] || '正月',
      dayName: LunarUtils.LUNAR_DAYS[day - 1] || '初一'
    };
    return defaultResult;
  }
  
  // 获取农历显示文本
  static getLunarText(date: Date): string {
    const festival = LunarUtils.getFestival(date);
    if (festival) {
      return festival;
    }
    
    const lunar = LunarUtils.getLunarInfo(date);
    
    // 如果是初一，显示月份名称
    if (lunar.day === 1) {
      return lunar.monthName;
    }
    
    return lunar.dayName;
  }
  
  // 获取节日信息
  static getFestival(date: Date): string | null {
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const key = `${month}-${day}`;
    
    return LunarUtils.FESTIVALS.get(key) || null;
  }
  
  // 判断是否为节日
  static isFestival(date: Date): boolean {
    return LunarUtils.getFestival(date) !== null;
  }
}