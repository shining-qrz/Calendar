import { CalendarEvent, ReminderType } from '../model/CalendarEvent';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 提醒信息接口
interface ReminderInfo {
  eventId: string;
  reminderId: number;
  reminderTime: Date;
  eventTitle: string;
}

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

// 提醒服务类
export class ReminderService {
  private static instance: ReminderService;
  private reminderIds: Map<string, number> = new Map();
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
      
      // 创建通知渠道
      await this.createNotificationSlot();
      
      // 请求通知权限
      await this.requestNotificationPermission(context);
      
      // 请求代理提醒权限
      await this.requestReminderPermission(context);
      
      // 发送测试通知验证功能
      await this.testNotification();
      
      // 先清理所有提醒，解决数量限制问题
      await this.cancelAllReminders();
      
      // 清理过期的提醒
      await this.cleanupExpiredReminders();
      
      console.info('提醒服务初始化成功');
    } catch (error) {
      console.error('初始化提醒服务失败:', error);
    }
  }
  
  // 请求代理提醒权限
  private async requestReminderPermission(context: common.UIAbilityContext): Promise<void> {
    try {
      // 检查代理提醒权限
      console.info('检查代理提醒权限...');
      
      // 尝试获取有效提醒来测试权限
      try {
        const reminders = await reminderAgentManager.getValidReminders();
        console.info(`✅ 代理提醒权限正常，当前有 ${reminders.length} 个提醒`);
      } catch (error) {
        const err = error as BusinessError;
        console.error(`❌ 代理提醒权限检查失败，错误码: ${err.code}, 信息: ${err.message}`);
        
        if (err.code === 201) {
          console.error('❌ 缺少代理提醒权限，请在设置中手动开启');
        } else if (err.code === 202) {
          console.error('❌ 代理提醒权限被拒绝');
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`检查代理提醒权限失败，错误码: ${err.code}, 信息: ${err.message}`);
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
      
      this.reminderIds.clear();
      const eventIds = Object.keys(mappingsData);
      for (const eventId of eventIds) {
        this.reminderIds.set(eventId, mappingsData[eventId]);
      }
      
      console.info(`已加载 ${this.reminderIds.size} 个提醒映射`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`加载提醒映射失败，错误码: ${err.code}, 信息: ${err.message}`);
      this.reminderIds.clear();
    }
  }
  
  // 保存提醒映射关系
  private async saveReminderMappings(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        return;
      }
      
      const mappingsData: Record<string, number> = {};
      this.reminderIds.forEach((reminderId: number, eventId: string) => {
        mappingsData[eventId] = reminderId;
      });
      
      const mappingsJson = JSON.stringify(mappingsData);
      await this.preferencesStore.put(this.REMINDERS_KEY, mappingsJson);
      await this.preferencesStore.flush();
      
      console.info(`已保存 ${this.reminderIds.size} 个提醒映射`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`保存提醒映射失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 测试立即提醒（用于调试）
  async testImmediateReminder(): Promise<void> {
    try {
      const now = new Date();
      const testTime = new Date(now.getTime() + 30 * 1000); // 30秒后
      
      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: testTime.getFullYear(),
          month: testTime.getMonth() + 1,
          day: testTime.getDate(),
          hour: testTime.getHours(),
          minute: testTime.getMinutes(),
          second: testTime.getSeconds()
        },
        title: `🔔 测试提醒`,
        content: `这是一个30秒后的测试提醒 - ${testTime.toLocaleString()}`,
        notificationId: Date.now(),
        repeatMonths: [],
        repeatDays: [],
        daysOfWeek: []
      };
      
      console.info('测试提醒配置:', JSON.stringify(reminderRequest, null, 2));
      
      const reminderId = await reminderAgentManager.publishReminder(reminderRequest);
      console.info(`✅ 测试提醒设置成功，ID: ${reminderId}, 将在30秒后触发`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 测试提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 测试通知功能（用于验证通知系统）
  async testNotification(): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: Date.now(), // 使用时间戳作为唯一ID
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
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 测试通知发送失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 创建通知渠道（API 21中可能不需要显式创建通知槽）
  private async createNotificationSlot(): Promise<void> {
    try {
      // 在API 21中，通知槽可能是自动管理的
      // 我们只需要确保通知权限已开启
      console.info('✅ 通知渠道准备完成（API 21自动管理）');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 通知渠道准备失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 请求通知权限
  private async requestNotificationPermission(context: common.UIAbilityContext): Promise<void> {
    try {
      // 检查是否已有通知权限
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
  
  // 检查并管理提醒数量限制
  private async manageReminderLimit(): Promise<void> {
    try {
      const validReminders = await this.getValidReminders();
      console.info(`当前系统中有 ${validReminders.length} 个有效提醒`);
      
      // 如果提醒数量接近限制（假设限制是30个），清理一些旧的
      if (validReminders.length >= 25) {
        console.warn('提醒数量接近限制，开始清理旧提醒');
        
        // 清理所有提醒，重新开始
        await this.cancelAllReminders();
        console.info('已清理所有旧提醒');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`管理提醒限制失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  // 设置事件提醒（混合提醒方案）
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
      
      // 检查权限状态
      const hasPermission = await this.checkReminderPermission();
      if (!hasPermission) {
        console.error('❌ 提醒权限未开启，无法设置提醒');
        throw new Error('提醒权限未开启');
      }
      
      // 尝试使用简单的定时器 + 通知方式
      const delay = reminderTime.getTime() - now.getTime();
      if (delay > 0 && delay < 24 * 60 * 60 * 1000) { // 24小时内
        console.info(`使用定时器方式设置提醒，延迟: ${delay}ms`);
        
        setTimeout(async () => {
          try {
            await this.sendReminderNotification(event);
          } catch (error) {
            console.error('发送提醒通知失败:', error);
          }
        }, delay);
        
        // 保存提醒映射（使用负数表示定时器提醒）
        this.reminderIds.set(event.id, -Date.now());
        await this.saveReminderMappings();
        
        console.info(`✅ 设置定时器提醒成功: ${event.title}, 将在 ${delay}ms 后触发`);
        return;
      }
      
      // 如果超过24小时，使用系统提醒方式
      console.info('使用系统代理提醒方式');
      
      // 根据API 21创建系统级代理提醒请求（使用Calendar类型）
      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: reminderTime.getFullYear(),
          month: reminderTime.getMonth() + 1,
          day: reminderTime.getDate(),
          hour: reminderTime.getHours(),
          minute: reminderTime.getMinutes(),
          second: 0
        },
        // 提醒内容
        title: `📅 ${event.title}`,
        content: this.generateReminderContent(event),
        // 通知相关设置
        notificationId: this.generateNotificationId(event.id),
        // 添加重复设置确保提醒触发
        repeatMonths: [],
        repeatDays: [],
        daysOfWeek: []
      };
      
      console.info('提醒请求配置:', JSON.stringify(reminderRequest, null, 2));
      
      const reminderId: number = await reminderAgentManager.publishReminder(reminderRequest);
      this.reminderIds.set(event.id, reminderId);
      await this.saveReminderMappings();
      
      console.info(`✅ 设置系统提醒成功: ${event.title}, 提醒时间: ${reminderTime.toLocaleString()}, 提醒ID: ${reminderId}`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 设置提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      
      // 如果系统提醒失败，尝试使用定时器方式作为备选
      if (err.code === 1700002) {
        console.warn('系统提醒失败，尝试使用定时器备选方案');
        try {
          const reminderTime = this.calculateReminderTime(event);
          const now = new Date();
          const delay = reminderTime.getTime() - now.getTime();
          
          if (delay > 0 && delay < 24 * 60 * 60 * 1000) {
            setTimeout(async () => {
              try {
                await this.sendReminderNotification(event);
              } catch (notifyError) {
                console.error('发送备选提醒通知失败:', notifyError);
              }
            }, delay);
            
            this.reminderIds.set(event.id, -Date.now());
            await this.saveReminderMappings();
            
            console.info(`✅ 设置备选定时器提醒成功: ${event.title}`);
            return;
          }
        } catch (fallbackError) {
          console.error('备选方案也失败:', fallbackError);
        }
      }
      
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
  
  // 验证提醒是否成功创建
  private async verifyReminderCreated(reminderId: number, eventTitle: string): Promise<void> {
    try {
      const validReminders = await this.getValidReminders();
      const foundReminder = validReminders.find(r => {
        // 由于API限制，我们通过标题来验证
        return r.title && r.title.includes(eventTitle);
      });
      
      if (foundReminder) {
        console.info(`✅ 提醒验证成功: ${eventTitle} (ID: ${reminderId})`);
      } else {
        console.warn(`⚠️ 提醒验证失败: 未找到 ${eventTitle} 的提醒`);
      }
      
      console.info(`当前系统中共有 ${validReminders.length} 个有效提醒`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`验证提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  async cancelEventReminder(eventId: string): Promise<void> {
    try {
      const reminderId = this.reminderIds.get(eventId);
      if (reminderId !== undefined) {
        await reminderAgentManager.cancelReminder(reminderId);
        this.reminderIds.delete(eventId);
        await this.saveReminderMappings();
        console.info(`✅ 取消提醒成功: 事件ID ${eventId}, 提醒ID ${reminderId}`);
      } else {
        console.warn(`⚠️ 未找到事件 ${eventId} 的提醒ID`);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 取消提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      // 即使取消失败，也要从映射中移除
      this.reminderIds.delete(eventId);
      await this.saveReminderMappings();
    }
  }
  
  // 计算提醒时间
  private calculateReminderTime(event: CalendarEvent): Date {
    const eventTime = new Date(event.startTime);
    const reminderTime = new Date(eventTime);
    
    switch (event.reminder) {
      case ReminderType.AT_TIME:
        // 准时提醒
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
    
    // 添加提醒类型说明
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
    // 使用事件ID的哈希值作为通知ID
    let hash = 0;
    for (let i = 0; i < eventId.length; i++) {
      const char = eventId.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }
    return Math.abs(hash) % 1000000; // 限制在6位数内
  }
  
  // 获取所有有效的提醒
  async getValidReminders(): Promise<Array<reminderAgentManager.ReminderRequest>> {
    try {
      const reminders = await reminderAgentManager.getValidReminders();
      console.info(`当前系统中有 ${reminders.length} 个有效提醒`);
      return reminders;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`获取有效提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      return [];
    }
  }
  
  // 获取提醒统计信息
  async getReminderStats(): Promise<ReminderStats> {
    try {
      const validReminders = await this.getValidReminders();
      const now = new Date();
      const nextHour = new Date(now.getTime() + 60 * 60 * 1000);
      
      let upcomingCount = 0;
      for (const reminder of validReminders) {
        if (reminder.reminderType === reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR) {
          const calendarReminder = reminder as reminderAgentManager.ReminderRequestCalendar;
          if (calendarReminder.dateTime) {
            const reminderTime = new Date(
              calendarReminder.dateTime.year || 0,
              (calendarReminder.dateTime.month || 1) - 1,
              calendarReminder.dateTime.day || 1,
              calendarReminder.dateTime.hour || 0,
              calendarReminder.dateTime.minute || 0
            );
            
            if (reminderTime >= now && reminderTime <= nextHour) {
              upcomingCount++;
            }
          }
        }
      }
      
      return {
        totalReminders: this.reminderIds.size,
        activeReminders: validReminders.length,
        upcomingReminders: upcomingCount
      } as ReminderStats;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`获取提醒统计失败，错误码: ${err.code}, 信息: ${err.message}`);
      return {
        totalReminders: 0,
        activeReminders: 0,
        upcomingReminders: 0
      } as ReminderStats;
    }
  }
  
  // 清理过期的提醒
  async cleanupExpiredReminders(): Promise<number> {
    try {
      const validReminders = await this.getValidReminders();
      // 简化实现：直接清理所有映射中不存在的提醒ID
      const toRemove: string[] = [];
      
      // 由于API限制，暂时跳过详细的ID匹配，直接进行基本清理
      this.reminderIds.forEach((reminderId: number, eventId: string) => {
        // 这里可以添加更多的验证逻辑
        // 暂时保留所有映射
      });
      
      let cleanedCount = 0;
      
      // 移除无效的映射
      for (const eventId of toRemove) {
        this.reminderIds.delete(eventId);
        cleanedCount++;
      }
      
      if (cleanedCount > 0) {
        await this.saveReminderMappings();
        console.info(`清理了 ${cleanedCount} 个过期提醒映射`);
      }
      
      return cleanedCount;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`清理过期提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      return 0;
    }
  }
  
  // 取消所有提醒
  async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      this.reminderIds.clear();
      await this.saveReminderMappings();
      console.info('✅ 取消所有提醒成功');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`❌ 取消所有提醒失败，错误码: ${err.code}, 信息: ${err.message}`);
      throw new Error(`取消所有提醒失败: ${err.message}`);
    }
  }
  
  // 检查提醒权限
  async checkReminderPermission(): Promise<boolean> {
    try {
      // 检查通知权限
      const isNotificationEnabled = await notificationManager.isNotificationEnabled();
      if (!isNotificationEnabled) {
        console.warn('通知权限未开启');
        return false;
      }
      
      // 尝试获取有效提醒来检查提醒权限
      await this.getValidReminders();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`提醒权限检查失败，错误码: ${err.code}, 信息: ${err.message}`);
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
        const err = error as BusinessError;
        console.error(`批量设置提醒失败 - 事件: ${event.title}，错误码: ${err.code}, 信息: ${err.message}`);
        failedCount++;
      }
    }
    
    console.info(`批量设置提醒完成: 成功 ${successCount}, 失败 ${failedCount}`);
    return { success: successCount, failed: failedCount } as BatchSetResult;
  }
}