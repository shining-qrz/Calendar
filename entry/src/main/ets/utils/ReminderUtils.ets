import { ReminderService } from '../service/ReminderService';
import { CalendarEvent, ReminderType } from '../model/CalendarEvent';

// 提醒选项接口
interface ReminderOption {
  value: ReminderType;
  text: string;
}

// 提醒验证结果接口
interface ReminderValidationResult {
  valid: CalendarEvent[];
  invalid: CalendarEvent[];
  expired: CalendarEvent[];
}

// 提醒系统状态接口
interface ReminderSystemStatus {
  hasPermission: boolean;
  activeReminders: number;
  systemSupported: boolean;
}

// 提醒工具类，用于管理和调试提醒功能
export class ReminderUtils {
  
  // 获取提醒类型的显示文本
  static getReminderTypeText(reminderType: ReminderType): string {
    switch (reminderType) {
      case ReminderType.NONE: return '无提醒';
      case ReminderType.AT_TIME: return '准时';
      case ReminderType.FIVE_MINUTES: return '5分钟前';
      case ReminderType.TEN_MINUTES: return '10分钟前';
      case ReminderType.FIFTEEN_MINUTES: return '15分钟前';
      case ReminderType.THIRTY_MINUTES: return '30分钟前';
      case ReminderType.ONE_HOUR: return '1小时前';
      case ReminderType.ONE_DAY: return '1天前';
      default: return '未知';
    }
  }
  
  // 获取所有提醒类型选项
  static getAllReminderOptions(): ReminderOption[] {
    const options: ReminderOption[] = [
      { value: ReminderType.NONE, text: '无提醒' } as ReminderOption,
      { value: ReminderType.AT_TIME, text: '准时' } as ReminderOption,
      { value: ReminderType.FIVE_MINUTES, text: '5分钟前' } as ReminderOption,
      { value: ReminderType.TEN_MINUTES, text: '10分钟前' } as ReminderOption,
      { value: ReminderType.FIFTEEN_MINUTES, text: '15分钟前' } as ReminderOption,
      { value: ReminderType.THIRTY_MINUTES, text: '30分钟前' } as ReminderOption,
      { value: ReminderType.ONE_HOUR, text: '1小时前' } as ReminderOption,
      { value: ReminderType.ONE_DAY, text: '1天前' } as ReminderOption
    ];
    return options;
  }
  
  // 计算提醒时间
  static calculateReminderTime(event: CalendarEvent): Date | null {
    if (event.reminder === ReminderType.NONE) {
      return null;
    }
    
    const eventTime = new Date(event.startTime);
    const reminderTime = new Date(eventTime);
    
    switch (event.reminder) {
      case ReminderType.AT_TIME:
        break;
      case ReminderType.FIVE_MINUTES:
        reminderTime.setMinutes(reminderTime.getMinutes() - 5);
        break;
      case ReminderType.TEN_MINUTES:
        reminderTime.setMinutes(reminderTime.getMinutes() - 10);
        break;
      case ReminderType.FIFTEEN_MINUTES:
        reminderTime.setMinutes(reminderTime.getMinutes() - 15);
        break;
      case ReminderType.THIRTY_MINUTES:
        reminderTime.setMinutes(reminderTime.getMinutes() - 30);
        break;
      case ReminderType.ONE_HOUR:
        reminderTime.setHours(reminderTime.getHours() - 1);
        break;
      case ReminderType.ONE_DAY:
        reminderTime.setDate(reminderTime.getDate() - 1);
        break;
    }
    
    return reminderTime;
  }
  
  // 检查提醒时间是否有效（未过期）
  static isReminderTimeValid(event: CalendarEvent): boolean {
    const reminderTime = ReminderUtils.calculateReminderTime(event);
    if (!reminderTime) {
      return false;
    }
    return reminderTime > new Date();
  }
  
  // 格式化提醒时间显示
  static formatReminderTime(event: CalendarEvent): string {
    const reminderTime = ReminderUtils.calculateReminderTime(event);
    if (!reminderTime) {
      return '无提醒';
    }
    
    const now = new Date();
    if (reminderTime <= now) {
      return '提醒时间已过';
    }
    
    return reminderTime.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  }
  
  // 获取提醒状态描述
  static getReminderStatus(event: CalendarEvent): string {
    if (event.reminder === ReminderType.NONE) {
      return '未设置提醒';
    }
    
    const reminderTime = ReminderUtils.calculateReminderTime(event);
    if (!reminderTime) {
      return '提醒时间无效';
    }
    
    const now = new Date();
    if (reminderTime <= now) {
      return '提醒时间已过';
    }
    
    const timeDiff = reminderTime.getTime() - now.getTime();
    const minutes = Math.floor(timeDiff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);
    
    if (days > 0) {
      return `${days}天后提醒`;
    } else if (hours > 0) {
      return `${hours}小时后提醒`;
    } else if (minutes > 0) {
      return `${minutes}分钟后提醒`;
    } else {
      return '即将提醒';
    }
  }
  
  // 验证提醒设置
  static validateReminderSettings(events: CalendarEvent[]): ReminderValidationResult {
    const valid: CalendarEvent[] = [];
    const invalid: CalendarEvent[] = [];
    const expired: CalendarEvent[] = [];
    
    for (const event of events) {
      if (event.reminder === ReminderType.NONE) {
        continue;
      }
      
      const reminderTime = ReminderUtils.calculateReminderTime(event);
      if (!reminderTime) {
        invalid.push(event);
        continue;
      }
      
      if (reminderTime <= new Date()) {
        expired.push(event);
      } else {
        valid.push(event);
      }
    }
    
    return { valid, invalid, expired } as ReminderValidationResult;
  }
  
  // 获取即将到来的提醒
  static getUpcomingReminders(events: CalendarEvent[], withinHours: number = 24): CalendarEvent[] {
    const now = new Date();
    const cutoffTime = new Date(now.getTime() + withinHours * 60 * 60 * 1000);
    
    return events.filter(event => {
      const reminderTime = ReminderUtils.calculateReminderTime(event);
      return reminderTime && reminderTime > now && reminderTime <= cutoffTime;
    }).sort((a, b) => {
      const timeA = ReminderUtils.calculateReminderTime(a);
      const timeB = ReminderUtils.calculateReminderTime(b);
      if (!timeA || !timeB) return 0;
      return timeA.getTime() - timeB.getTime();
    });
  }
  
  // 批量检查提醒权限和状态
  static async checkReminderSystemStatus(): Promise<ReminderSystemStatus> {
    try {
      const reminderService = ReminderService.getInstance();
      
      // 检查权限
      const hasPermission = await reminderService.checkReminderPermission();
      
      // 获取活跃提醒数量
      const validReminders = await reminderService.getValidReminders();
      const activeReminders = validReminders.length;
      
      return {
        hasPermission,
        activeReminders,
        systemSupported: true
      } as ReminderSystemStatus;
    } catch (error) {
      console.error('检查提醒系统状态失败:', error);
      return {
        hasPermission: false,
        activeReminders: 0,
        systemSupported: false
      } as ReminderSystemStatus;
    }
  }
}