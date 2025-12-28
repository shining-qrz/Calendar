// 日期工具类
export class DateUtils {
  
  // 获取月份的第一天
  static getFirstDayOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }
  
  // 获取月份的最后一天
  static getLastDayOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0);
  }
  
  // 获取周的第一天（周日）
  static getFirstDayOfWeek(date: Date): Date {
    const day = date.getDay(); // 0=周日, 1=周一, ..., 6=周六
    const diff = date.getDate() - day; // 直接减去星期数，周日为0
    const firstDay = new Date(date);
    firstDay.setDate(diff);
    return firstDay;
  }
  
  // 获取月份的所有日期（包含前后月份的日期以填满6周）
  static getMonthDates(date: Date): Date[] {
    const firstDay = DateUtils.getFirstDayOfMonth(date);
    const lastDay = DateUtils.getLastDayOfMonth(date);
    const startDate = DateUtils.getFirstDayOfWeek(new Date(firstDay));
    
    const dates: Date[] = [];
    const current = new Date(startDate);
    
    // 生成6周的日期
    for (let i = 0; i < 42; i++) {
      dates.push(new Date(current));
      current.setDate(current.getDate() + 1);
    }
    
    return dates;
  }
  
  // 获取周的所有日期
  static getWeekDates(date: Date): Date[] {
    const firstDay = DateUtils.getFirstDayOfWeek(new Date(date));
    const dates: Date[] = [];
    
    for (let i = 0; i < 7; i++) {
      const current = new Date(firstDay);
      current.setDate(firstDay.getDate() + i);
      dates.push(current);
    }
    
    return dates;
  }
  
  // 判断是否为同一天
  static isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getDate() === date2.getDate();
  }
  
  // 判断是否为今天
  static isToday(date: Date): boolean {
    return DateUtils.isSameDay(date, new Date());
  }
  
  // 格式化日期
  static formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    
    return format
      .replace('YYYY', year.toString())
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hours)
      .replace('mm', minutes);
  }
  
  // 获取月份名称
  static getMonthName(date: Date): string {
    const months = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];
    return months[date.getMonth()];
  }
  
  // 获取星期名称
  static getWeekdayName(date: Date): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.getDay()];
  }
  
  // 获取星期简称
  static getWeekdayShort(date: Date): string {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return weekdays[date.getDay()];
  }
}