import { CalendarEvent, ReminderType } from '../model/CalendarEvent';
import reminderAgentManager from '@ohos.reminderAgentManager';

// 提醒服务类
export class ReminderService {
  private static instance: ReminderService;
  private reminderIds: Map<string, number> = new Map();
  
  private constructor() {}
  
  static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService();
    }
    return ReminderService.instance;
  }
  
  // 设置事件提醒
  async setEventReminder(event: CalendarEvent): Promise<void> {
    try {
      // 先取消已存在的提醒
      await this.cancelEventReminder(event.id);
      
      if (event.reminder === ReminderType.NONE) {
        return;
      }
      
      const reminderTime = this.calculateReminderTime(event);
      if (reminderTime <= new Date()) {
        return; // 提醒时间已过，不设置提醒
      }
      
      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: reminderTime.getFullYear(),
          month: reminderTime.getMonth() + 1,
          day: reminderTime.getDate(),
          hour: reminderTime.getHours(),
          minute: reminderTime.getMinutes()
        },
        title: event.title,
        content: event.description || '日程提醒',
        expiredContent: '日程提醒已过期',
        snoozeContent: '稍后提醒',
        notificationId: 1,
        slotType: 1
      };
      
      const reminderId = await reminderAgentManager.publishReminder(reminderRequest);
      this.reminderIds.set(event.id, reminderId);
      
      console.info(`设置提醒成功: ${event.title}, 提醒ID: ${reminderId}`);
    } catch (error) {
      console.error('设置提醒失败:', error);
    }
  }
  
  // 取消事件提醒
  async cancelEventReminder(eventId: string): Promise<void> {
    try {
      const reminderId = this.reminderIds.get(eventId);
      if (reminderId !== undefined) {
        await reminderAgentManager.cancelReminder(reminderId);
        this.reminderIds.delete(eventId);
        console.info(`取消提醒成功: ${reminderId}`);
      }
    } catch (error) {
      console.error('取消提醒失败:', error);
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
    }
    
    return reminderTime;
  }
  
  // 获取所有有效的提醒
  async getValidReminders(): Promise<Array<reminderAgentManager.ReminderRequest>> {
    try {
      return await reminderAgentManager.getValidReminders();
    } catch (error) {
      console.error('获取有效提醒失败:', error);
      return [];
    }
  }
  
  // 取消所有提醒
  async cancelAllReminders(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      this.reminderIds.clear();
      console.info('取消所有提醒成功');
    } catch (error) {
      console.error('取消所有提醒失败:', error);
    }
  }
}