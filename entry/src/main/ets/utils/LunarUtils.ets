import { i18n } from '@kit.LocalizationKit';
import { SolarTermUtils } from './SolarTermUtils';

// 农历信息接口
interface LunarInfo {
  month: number;
  day: number;
  monthName: string;
  dayName: string;
  isLeapMonth: boolean;
}

// 完整日期信息接口
interface FullDateInfo {
  lunarDate: string;
  ganZhiInfo: string;
  festival?: string;
}

// 日历对象接口
interface CalendarObject {
  get(field: string): number;
  setTime(time: number | Date): void;
  getTimeInMillis(): number;
  isLeapYear?(): boolean;
  hasLeapMonth?(): boolean;
  getLeapMonth?(): number;
}

// 农历工具类 - 严格使用官方LocalizationKit API
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
  
  // 传统节日映射（公历节日）
  private static readonly FESTIVALS = new Map<string, string>([
    ['01-01', '元旦'],
    ['02-14', '情人节'],
    ['03-08', '妇女节'],
    ['05-01', '劳动节'],
    ['06-01', '儿童节'],
    ['10-01', '国庆节'],
    ['12-25', '圣诞节']
  ]);
  
  // 农历节日映射（按农历日期）
  private static readonly LUNAR_FESTIVALS = new Map<string, string>([
    ['01-01', '春节'],
    ['01-15', '元宵节'],
    ['05-05', '端午节'],
    ['07-07', '七夕节'],
    ['08-15', '中秋节'],
    ['09-09', '重阳节'],
    ['12-08', '腊八节'],
    ['12-23', '小年']
  ]);
  
  // 天干地支
  private static readonly TIAN_GAN = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  private static readonly DI_ZHI = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  private static readonly SHENG_XIAO = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
  
  // 获取农历信息（严格使用官方API）
  static getLunarInfo(date: Date): LunarInfo {
    // 创建公历日历对象
    let gregorianCalendar = i18n.getCalendar("zh-Hans", "gregory") as CalendarObject;
    gregorianCalendar.setTime(date);
    
    // 创建农历日历对象
    let lunarCalendar = i18n.getCalendar("zh-Hans", "chinese") as CalendarObject;
    lunarCalendar.setTime(gregorianCalendar.getTimeInMillis());
    
    // 获取农历信息
    let lunarMonth = lunarCalendar.get("month") + 1;
    let lunarDay = lunarCalendar.get("date");
    
    // 检查是否为闰月
    let isLeapMonth = false;
    if (lunarCalendar.hasLeapMonth && lunarCalendar.getLeapMonth) {
      try {
        isLeapMonth = lunarCalendar.hasLeapMonth() && lunarCalendar.getLeapMonth() === lunarMonth;
      } catch (error) {
        isLeapMonth = false;
      }
    }
    
    return {
      month: lunarMonth,
      day: lunarDay,
      monthName: LunarUtils.LUNAR_MONTHS[lunarMonth - 1],
      dayName: LunarUtils.LUNAR_DAYS[lunarDay - 1],
      isLeapMonth: isLeapMonth
    };
  }
  
  // 获取干支纪年信息（严格使用官方API）
  static getLunarGanZhi(date: Date): string {
    // 创建公历日历对象
    let gregorianCalendar = i18n.getCalendar("zh-Hans", "gregory") as CalendarObject;
    gregorianCalendar.setTime(date);
    
    // 创建农历日历对象
    let lunarCalendar = i18n.getCalendar("zh-Hans", "chinese") as CalendarObject;
    lunarCalendar.setTime(gregorianCalendar.getTimeInMillis());
    
    // 获取农历年份（干支纪年）
    let lunarYear = lunarCalendar.get("year");
    let lunarMonth = lunarCalendar.get("month");
    let lunarDay = lunarCalendar.get("date");
    
    // 根据API返回的年份计算干支
    // 农历年份应该直接对应干支纪年
    let yearTianGanIndex = (lunarYear - 1) % 10;
    let yearDiZhiIndex = (lunarYear - 1) % 12;
    
    let yearTianGan = LunarUtils.TIAN_GAN[yearTianGanIndex];
    let yearDiZhi = LunarUtils.DI_ZHI[yearDiZhiIndex];
    let yearShengXiao = LunarUtils.SHENG_XIAO[yearDiZhiIndex];
    
    // 月干支和日干支需要通过API获取或计算
    // 这里暂时返回年份信息，月日干支需要进一步研究API
    return `${yearTianGan}${yearDiZhi}${yearShengXiao}年`;
  }
  
  // 获取完整的干支信息（年月日）
  static getFullGanZhi(date: Date): string {
    const yearGanZhi = LunarUtils.getLunarGanZhi(date);
    const monthGanZhi = LunarUtils.getMonthGanZhi(date);
    const dayGanZhi = LunarUtils.getDayGanZhi(date);
    
    return `${yearGanZhi}  ${monthGanZhi}月  ${dayGanZhi}日`;
  }
  
  // 计算干支月（按节气划分）
  static getMonthGanZhi(date: Date): string {
    // 以2025年12月21日冬至日为基准，应该是戊子月
    // 戊=4（天干），子=0（地支）
    
    const baseDate = new Date(2025, 11, 21); // 2025年12月21日
    const currentDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    
    // 计算年份差异
    const yearDiff = date.getFullYear() - 2025;
    
    // 计算节气月差异
    const baseSolarMonth = 12; // 基准日期的节气月（十二月）
    const currentSolarMonth = LunarUtils.getSolarMonth(date);
    
    // 总的节气月差异
    let totalMonthDiff = yearDiff * 12 + (currentSolarMonth - baseSolarMonth);
    
    // 2025年12月21日是戊子月：戊=4，子=0
    const baseTianGanIndex = 4; // 戊
    const baseDiZhiIndex = 0;   // 子
    
    // 计算当前日期的月干支
    let monthTianGanIndex = (baseTianGanIndex + totalMonthDiff) % 10;
    let monthDiZhiIndex = (baseDiZhiIndex + totalMonthDiff) % 12;
    
    // 处理负数情况
    if (monthTianGanIndex < 0) {
      monthTianGanIndex = (monthTianGanIndex % 10 + 10) % 10;
    }
    if (monthDiZhiIndex < 0) {
      monthDiZhiIndex = (monthDiZhiIndex % 12 + 12) % 12;
    }
    
    let monthTianGan = LunarUtils.TIAN_GAN[monthTianGanIndex];
    let monthDiZhi = LunarUtils.DI_ZHI[monthDiZhiIndex];
    
    return `${monthTianGan}${monthDiZhi}`;
  }
  
  // 根据节气确定节气月份（1-12）
  private static getSolarMonth(date: Date): number {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    
    // 简化版：根据公历月份和大致节气日期判断节气月
    // 正月（寅月）：立春到惊蛰前
    // 二月（卯月）：惊蛰到清明前
    // 三月（辰月）：清明到立夏前
    // 四月（巳月）：立夏到芒种前
    // 五月（午月）：芒种到小暑前
    // 六月（未月）：小暑到立秋前
    // 七月（申月）：立秋到白露前
    // 八月（酉月）：白露到寒露前
    // 九月（戌月）：寒露到立冬前
    // 十月（亥月）：立冬到大雪前
    // 十一月（子月）：大雪到小寒前
    // 十二月（丑月）：小寒到立春前
    
    if (month === 1) {
      return day < 5 ? 12 : 1; // 小寒前为十二月，小寒后为正月
    } else if (month === 2) {
      return day < 4 ? 1 : 2; // 立春前为正月，立春后为二月
    } else if (month === 3) {
      return day < 5 ? 2 : 3; // 惊蛰前为二月，惊蛰后为三月
    } else if (month === 4) {
      return day < 4 ? 3 : 4; // 清明前为三月，清明后为四月
    } else if (month === 5) {
      return day < 5 ? 4 : 5; // 立夏前为四月，立夏后为五月
    } else if (month === 6) {
      return day < 5 ? 5 : 6; // 芒种前为五月，芒种后为六月
    } else if (month === 7) {
      return day < 7 ? 6 : 7; // 小暑前为六月，小暑后为七月
    } else if (month === 8) {
      return day < 7 ? 7 : 8; // 立秋前为七月，立秋后为八月
    } else if (month === 9) {
      return day < 7 ? 8 : 9; // 白露前为八月，白露后为九月
    } else if (month === 10) {
      return day < 8 ? 9 : 10; // 寒露前为九月，寒露后为十月
    } else if (month === 11) {
      return day < 7 ? 10 : 11; // 立冬前为十月，立冬后为十一月
    } else { // month === 12
      return day < 7 ? 11 : 12; // 大雪前为十一月，大雪后为十二月
    }
  }
  
  // 计算干支日
  static getDayGanZhi(date: Date): string {
    // 使用2025年12月21日（冬至）为基准日（甲子日）
    const baseDate = new Date(2025, 11, 21); // 2025年12月21日
    const currentDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    
    // 计算距离基准日的天数
    const timeDiff = currentDate.getTime() - baseDate.getTime();
    const daysDiff = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
    
    // 2025年12月21日是甲子日，甲=0，子=0
    const baseTianGanIndex = 0; // 甲
    const baseDiZhiIndex = 0;   // 子
    
    // 计算当前日期的干支
    let dayTianGanIndex = (baseTianGanIndex + daysDiff) % 10;
    let dayDiZhiIndex = (baseDiZhiIndex + daysDiff) % 12;
    
    // 处理负数情况
    if (dayTianGanIndex < 0) {
      dayTianGanIndex = (dayTianGanIndex % 10 + 10) % 10;
    }
    if (dayDiZhiIndex < 0) {
      dayDiZhiIndex = (dayDiZhiIndex % 12 + 12) % 12;
    }
    
    let dayTianGan = LunarUtils.TIAN_GAN[dayTianGanIndex];
    let dayDiZhi = LunarUtils.DI_ZHI[dayDiZhiIndex];
    
    return `${dayTianGan}${dayDiZhi}`;
  }
  
  // 获取节气信息（使用SolarTermUtils）
  static getSolarTerm(date: Date): string | null {
    return SolarTermUtils.getSolarTerm(date);
  }
  
  // 判断是否为节气日
  static isSolarTerm(date: Date): boolean {
    return SolarTermUtils.isSolarTerm(date);
  }
  
  // 获取农历显示文本（优先显示节气和节日）
  static getLunarText(date: Date): string {
    // 首先检查是否为节气
    let solarTerm = LunarUtils.getSolarTerm(date);
    if (solarTerm) {
      return solarTerm;
    }
    
    // 然后检查是否为农历节日
    let lunar = LunarUtils.getLunarInfo(date);
    let lunarKey = `${String(lunar.month).padStart(2, '0')}-${String(lunar.day).padStart(2, '0')}`;
    let lunarFestival = LunarUtils.LUNAR_FESTIVALS.get(lunarKey);
    
    if (lunarFestival) {
      return lunarFestival;
    }
    
    // 然后检查公历节日
    let festival = LunarUtils.getFestival(date);
    if (festival) {
      return festival;
    }
    
    // 如果是农历初一，显示月份名称
    if (lunar.day === 1) {
      return lunar.isLeapMonth ? `闰${lunar.monthName}` : lunar.monthName;
    }
    
    // 否则显示农历日期
    return lunar.dayName;
  }
  
  // 获取公历节日信息
  static getFestival(date: Date): string | null {
    let month = String(date.getMonth() + 1).padStart(2, '0');
    let day = String(date.getDate()).padStart(2, '0');
    let key = `${month}-${day}`;
    
    return LunarUtils.FESTIVALS.get(key) || null;
  }
  
  // 获取农历节日信息
  static getLunarFestival(date: Date): string | null {
    let lunar = LunarUtils.getLunarInfo(date);
    let key = `${String(lunar.month).padStart(2, '0')}-${String(lunar.day).padStart(2, '0')}`;
    
    return LunarUtils.LUNAR_FESTIVALS.get(key) || null;
  }
  
  // 判断是否为节日或节气（包含公历和农历节日以及节气）
  static isFestival(date: Date): boolean {
    return LunarUtils.getSolarTerm(date) !== null || 
           LunarUtils.getFestival(date) !== null || 
           LunarUtils.getLunarFestival(date) !== null;
  }
  
  // 获取详细农历信息
  static getDetailedLunarInfo(date: Date): string {
    let lunar = LunarUtils.getLunarInfo(date);
    
    let seasonalMonth = '';
    switch (lunar.month) {
      case 1:
        seasonalMonth = '正月';
        break;
      case 2:
        seasonalMonth = '二月';
        break;
      case 3:
        seasonalMonth = '三月';
        break;
      case 4:
        seasonalMonth = '四月';
        break;
      case 5:
        seasonalMonth = '五月';
        break;
      case 6:
        seasonalMonth = '六月';
        break;
      case 7:
        seasonalMonth = '七月';
        break;
      case 8:
        seasonalMonth = '八月';
        break;
      case 9:
        seasonalMonth = '九月';
        break;
      case 10:
        seasonalMonth = '十月';
        break;
      case 11:
        seasonalMonth = '冬月';
        break;
      case 12:
        seasonalMonth = '腊月';
        break;
      default:
        seasonalMonth = lunar.monthName;
    }
    
    let prefix = lunar.isLeapMonth ? '闰' : '';
    return `${prefix}${seasonalMonth}${lunar.dayName}`;
  }
  
  // 获取完整的日期信息展示
  static getFullDateInfo(date: Date): FullDateInfo {
    let lunarDate = LunarUtils.getDetailedLunarInfo(date);
    let ganZhiInfo = LunarUtils.getLunarGanZhi(date);
    
    // 优先显示节气，然后是农历节日，最后是公历节日
    let solarTerm = LunarUtils.getSolarTerm(date);
    let lunarFestival = LunarUtils.getLunarFestival(date);
    let publicFestival = LunarUtils.getFestival(date);
    let festival = solarTerm || lunarFestival || publicFestival;
    
    let result: FullDateInfo = {
      lunarDate: lunarDate,
      ganZhiInfo: ganZhiInfo,
      festival: festival || undefined
    };
    return result;
  }
}