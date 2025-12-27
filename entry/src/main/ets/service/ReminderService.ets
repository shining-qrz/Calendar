import { CalendarEvent, ReminderType } from '../model/CalendarEvent';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 提醒统计接口
interface ReminderStats {
  totalReminders: number;
  activeReminders: number;
  upcomingReminders: number;
}

// 批量设置结果接口
interface BatchSetResult {
  success: number;
  failed: number;
}

// 提醒服务类（基于定时器）
export class ReminderService {
  private static instance: ReminderService;
  private reminderTimers: Map<string, number> = new Map();
  private preferencesStore: preferences.Preferences | null = null;
  private readonly REMINDERS_KEY = 'reminder_mappings';
  
  private constructor() {}
  
  static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService();
    }
    return ReminderService.instance;
  }
  
  // 初始化提醒服务
  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      // 初始化首选项存储
      this.preferencesStore = await preferences.getPreferences(context, 'reminder_data');
      await this.loadReminderMappings();
      
      // 请求通知权限
      await this.requestNotificationPermission(context);
      
      // 发送测试通知验证功能
      await this.testNotification();
      
      console.info('提醒服务初始化成功（定时器模式）');
    } catch (error) {
      console.error('初始化提醒服务失败:', error);
    }
  }
  
  // 加载提醒映射关系
  private async loadReminderMappings(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        return;
      }
      
      const mappingsJson = await this.preferencesStore.get(this.REMINDERS_KEY, '{}') as string;
      const mappingsData: Record<string, number> = JSON.parse(mappingsJson) as Record<string, number>;
      
      this.reminderTimers.clear();
      const eventIds = Object.keys(mappingsData);
      for (const eventId of eventIds) {
        this.reminderTimers.set(eventId, mappingsData[eventId]);
      }
      
      console.info(`已加载 ${this.reminderTimers.size} 个提醒映射`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`加载提醒映射失败，错误码: ${err.code}, 信息: ${err.message}`);
      this.reminderTimers.clear();
    }
  }
  
  // 保存提醒映射关系
  private async saveReminderMappings(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        return;
      }
      
      const mappingsData: Record<string, number> = {};
      this.reminderTimers.forEach((timerId: number, eventId: string) => {
        mappingsData[eventId] = timerId;
      });
      
      const mappingsJson = JSON.stringify(mappingsData);
      await this.preferencesStore.put(this.REMINDERS_KEY, mappingsJson);
      await this.preferencesStore.flush();
      
      console.info(`已保存 ${this.reminderTimers.size} 个提醒映射`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`保存提醒映射失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 测试通知功能
  async testNotification(): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: Date.now(),
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: "📅 日程提醒测试",
            text: "通知系统工作正常",
            additionalText: "测试通知"
          }
        }
      };

      await notificationManager.publish(notificationRequest);
      console.info('✅ 测试通知发送成功');
      
      // 添加一个10秒后的测试定时器
      setTimeout(() => {
        console.info('🔔 10秒测试定时器触发成功！');
        this.sendTestReminderNotification();
      }, 10000);
      
      console.info('⏰ 已设置10秒后的测试定时器');
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 测试通知发送失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 发送测试提醒通知
  private async sendTestReminderNotification(): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: Date.now(),
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: "🔔 定时器测试",
            text: "定时器功能正常工作！",
            additionalText: "测试提醒"
          }
        }
      };

      await notificationManager.publish(notificationRequest);
      console.info('✅ 测试定时器提醒发送成功');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 测试定时器提醒发送失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 请求通知权限
  private async requestNotificationPermission(context: common.UIAbilityContext): Promise<void> {
    try {
      const isEnabled = await notificationManager.isNotificationEnabled();
      console.info(`通知权限状态: ${isEnabled}`);
      
      if (!isEnabled) {
        console.info('请求通知权限...');
        try {
          await notificationManager.requestEnableNotification(context);
          console.info('✅ 通知权限请求成功');
        } catch (error) {
          const err = error as BusinessError;
          if (err.code === 1600004) {
            console.warn('⚠️ 用户拒绝了通知权限');
          } else {
            console.error(`❌ 请求通知权限失败，错误码: ${err.code}, 信息: ${err.message}`);
          }
        }
      } else {
        console.info('✅ 通知权限已开启');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`检查通知权限失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 设置事件提醒（定时器方式）
  async setEventReminder(event: CalendarEvent): Promise<void> {
    try {
      // 先取消已存在的提醒
      await this.cancelEventReminder(event.id);
      
      if (event.reminder === ReminderType.NONE) {
        console.info(`事件 ${event.title} 不需要提醒`);
        return;
      }
      
      const reminderTime = this.calculateReminderTime(event);
      const now = new Date();
      
      console.info(`设置提醒 - 事件: ${event.title}, 当前时间: ${now.toLocaleString()}, 提醒时间: ${reminderTime.toLocaleString()}`);
      
      if (reminderTime <= now) {
        console.warn(`事件 ${event.title} 的提醒时间已过，不设置提醒`);
        return;
      }
      
      // 使用定时器 + 通知方式
      const delay = reminderTime.getTime() - now.getTime();
      console.info(`使用定时器方式设置提醒，延迟: ${delay}ms (${Math.round(delay/1000)}秒)`);
      
      const timerId = setTimeout(async () => {
        try {
          console.info(`⏰ 定时器触发 - 发送提醒: ${event.title}`);
          await this.sendReminderNotification(event);
          // 提醒发送后清理映射
          this.reminderTimers.delete(event.id);
          await this.saveReminderMappings();
          console.info(`✅ 提醒处理完成并清理映射: ${event.title}`);
        } catch (error) {
          console.error('发送提醒通知失败:', error);
        }
      }, delay);
      
      // 保存提醒映射 - 注意：setTimeout返回的是NodeJS.Timeout，需要转换
      const timerIdNumber = Number(timerId);
      this.reminderTimers.set(event.id, timerIdNumber);
      await this.saveReminderMappings();
      
      console.info(`✅ 设置定时器提醒成功: ${event.title}, 将在 ${Math.round(delay/1000)}秒 后触发, 定时器ID: ${timerIdNumber}`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 设置提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      throw new Error(`设置提醒失败: ${err.message}`);
    }
  }
  
  // 发送提醒通知
  private async sendReminderNotification(event: CalendarEvent): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: this.generateNotificationId(event.id),
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: `📅 ${event.title}`,
            text: this.generateReminderContent(event),
            additionalText: "日程提醒"
          }
        }
      };

      await notificationManager.publish(notificationRequest);
      console.info(`✅ 提醒通知发送成功: ${event.title}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 发送提醒通知失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 取消事件提醒
  async cancelEventReminder(eventId: string): Promise<void> {
    try {
      const timerId = this.reminderTimers.get(eventId);
      if (timerId !== undefined) {
        clearTimeout(timerId);
        this.reminderTimers.delete(eventId);
        await this.saveReminderMappings();
        console.info(`✅ 取消定时器提醒成功: 事件ID ${eventId}`);
      } else {
        console.warn(`⚠️ 未找到事件 ${eventId} 的定时器ID`);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 取消提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      this.reminderTimers.delete(eventId);
      await this.saveReminderMappings();
    }
  }
  
  // 计算提醒时间
  private calculateReminderTime(event: CalendarEvent): Date {
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
      default:
        console.warn(`未知的提醒类型: ${event.reminder}`);
        break;
    }
    
    return reminderTime;
  }
  
  // 生成提醒内容
  private generateReminderContent(event: CalendarEvent): string {
    const startTime = new Date(event.startTime);
    const timeStr = startTime.toLocaleTimeString('zh-CN', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
    
    let content = `时间: ${timeStr}`;
    
    if (event.description && event.description.trim()) {
      content += `\n描述: ${event.description}`;
    }
    
    const reminderTypeText = this.getReminderTypeText(event.reminder);
    if (reminderTypeText !== '准时') {
      content += `\n提醒: ${reminderTypeText}`;
    }
    
    return content;
  }
  
  // 获取提醒类型文本
  private getReminderTypeText(reminderType: ReminderType): string {
    switch (reminderType) {
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
  
  // 生成通知ID
  private generateNotificationId(eventId: string): number {
    let hash = 0;
    for (let i = 0; i < eventId.length; i++) {
      const char = eventId.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash) % 1000000;
  }
  
  // 获取提醒统计信息
  async getReminderStats(): Promise<ReminderStats> {
    return {
      totalReminders: this.reminderTimers.size,
      activeReminders: this.reminderTimers.size,
      upcomingReminders: 0
    } as ReminderStats;
  }
  
  // 清理过期的提醒
  async cleanupExpiredReminders(): Promise<number> {
    return 0;
  }
  
  // 取消所有提醒
  async cancelAllReminders(): Promise<void> {
    this.reminderTimers.forEach((timerId: number) => {
      clearTimeout(timerId);
    });
    
    this.reminderTimers.clear();
    await this.saveReminderMappings();
    console.info('✅ 取消所有定时器提醒成功');
  }
  
  // 检查提醒权限
  async checkReminderPermission(): Promise<boolean> {
    try {
      const isNotificationEnabled = await notificationManager.isNotificationEnabled();
      return isNotificationEnabled;
    } catch (error) {
      return false;
    }
  }
  
  // 批量设置提醒
  async batchSetReminders(events: CalendarEvent[]): Promise<BatchSetResult> {
    let successCount = 0;
    let failedCount = 0;
    
    for (const event of events) {
      try {
        await this.setEventReminder(event);
        successCount++;
      } catch (error) {
        failedCount++;
      }
    }
    
    return { success: successCount, failed: failedCount } as BatchSetResult;
  }
}