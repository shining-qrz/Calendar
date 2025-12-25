import { CalendarEvent } from '../model/CalendarEvent';
import preferences from '@ohos.data.preferences';

// 日历服务类，负责数据存储和管理
export class CalendarService {
  private static instance: CalendarService;
  private events: CalendarEvent[] = [];
  private preferencesStore: preferences.Preferences | null = null;
  
  private constructor() {}
  
  static getInstance(): CalendarService {
    if (!CalendarService.instance) {
      CalendarService.instance = new CalendarService();
    }
    return CalendarService.instance;
  }
  
  // 初始化数据存储
  async init(context: any): Promise<void> {
    try {
      this.preferencesStore = await preferences.getPreferences(context, 'calendar_events');
      await this.loadEvents();
    } catch (error) {
      console.error('初始化日历服务失败:', error);
    }
  }
  
  // 加载事件数据
  private async loadEvents(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const eventsData = await this.preferencesStore.get('events', '[]') as string;
        const parsedEvents = JSON.parse(eventsData);
        this.events = parsedEvents.map((data: any) => {
          const event = new CalendarEvent(data);
          event.startTime = new Date(data.startTime);
          event.endTime = new Date(data.endTime);
          return event;
        });
      }
    } catch (error) {
      console.error('加载事件数据失败:', error);
      this.events = [];
    }
  }
  
  // 保存事件数据
  private async saveEvents(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const eventsData = JSON.stringify(this.events);
        await this.preferencesStore.put('events', eventsData);
        await this.preferencesStore.flush();
      }
    } catch (error) {
      console.error('保存事件数据失败:', error);
    }
  }
  
  // 添加事件
  async addEvent(event: CalendarEvent): Promise<void> {
    this.events.push(event);
    await this.saveEvents();
  }
  
  // 更新事件
  async updateEvent(event: CalendarEvent): Promise<void> {
    const index = this.events.findIndex(e => e.id === event.id);
    if (index !== -1) {
      this.events[index] = event;
      await this.saveEvents();
    }
  }
  
  // 删除事件
  async deleteEvent(eventId: string): Promise<void> {
    this.events = this.events.filter(e => e.id !== eventId);
    await this.saveEvents();
  }
  
  // 获取指定日期的事件
  getEventsForDate(date: Date): CalendarEvent[] {
    return this.events.filter(event => {
      const eventDate = new Date(event.startTime);
      return eventDate.getFullYear() === date.getFullYear() &&
             eventDate.getMonth() === date.getMonth() &&
             eventDate.getDate() === date.getDate();
    });
  }
  
  // 获取指定日期范围的事件
  getEventsForDateRange(startDate: Date, endDate: Date): CalendarEvent[] {
    return this.events.filter(event => {
      const eventStart = new Date(event.startTime);
      return eventStart >= startDate && eventStart <= endDate;
    });
  }
  
  // 获取所有事件
  getAllEvents(): CalendarEvent[] {
    return [...this.events];
  }
  
  // 根据ID获取事件
  getEventById(id: string): CalendarEvent | undefined {
    return this.events.find(event => event.id === id);
  }
}