import { CalendarEvent } from '../model/CalendarEvent';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 序列化的事件数据接口
interface SerializedEventData {
  id: string;
  title: string;
  description: string;
  startTime: string;
  endTime: string;
  isAllDay: boolean;
  reminder: number;
  color: string;
}

// 事件统计信息接口
interface EventsStats {
  total: number;
  thisMonth: number;
  today: number;
}

// 日历服务类，负责数据存储和管理
export class CalendarService {
  private static instance: CalendarService;
  private events: CalendarEvent[] = [];
  private preferencesStore: preferences.Preferences | null = null;
  private readonly EVENTS_KEY = 'calendar_events';
  
  private constructor() {}
  
  static getInstance(): CalendarService {
    if (!CalendarService.instance) {
      CalendarService.instance = new CalendarService();
    }
    return CalendarService.instance;
  }
  
  // 初始化数据存储
  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      // 初始化首选项存储
      this.preferencesStore = await preferences.getPreferences(context, 'calendar_data');
      await this.loadEvents();
      console.info('日历服务初始化成功');
    } catch (error) {
      console.error('初始化日历服务失败:', error);
      // 如果首选项初始化失败，使用内存存储作为备用方案
      this.events = [];
    }
  }
  
  // 加载事件数据
  private async loadEvents(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        console.warn('首选项存储未初始化，使用空数据');
        this.events = [];
        return;
      }
      
      const eventsJson = await this.preferencesStore.get(this.EVENTS_KEY, '[]') as string;
      const eventsData: SerializedEventData[] = JSON.parse(eventsJson) as SerializedEventData[];
      
      // 将JSON数据转换为CalendarEvent对象，并恢复Date类型
      this.events = eventsData.map((eventData: SerializedEventData) => {
        const event = new CalendarEvent();
        event.id = eventData.id || '';
        event.title = eventData.title || '';
        event.description = eventData.description || '';
        event.startTime = new Date(eventData.startTime);
        event.endTime = new Date(eventData.endTime);
        event.isAllDay = eventData.isAllDay || false;
        event.reminder = eventData.reminder || 0;
        event.color = eventData.color || '#007AFF';
        return event;
      });
      
      console.info(`成功加载 ${this.events.length} 个日程事件`);
    } catch (error) {
      console.error('加载事件数据失败:', error);
      this.events = [];
    }
  }
  
  // 保存事件数据
  private async saveEvents(): Promise<void> {
    try {
      if (!this.preferencesStore) {
        console.warn('首选项存储未初始化，无法保存数据');
        return;
      }
      
      // 将事件数据序列化为JSON
      const eventsJson = JSON.stringify(this.events);
      await this.preferencesStore.put(this.EVENTS_KEY, eventsJson);
      await this.preferencesStore.flush(); // 确保数据立即写入磁盘
      
      console.info(`成功保存 ${this.events.length} 个日程事件`);
    } catch (error) {
      console.error('保存事件数据失败:', error);
      throw new Error(`保存事件数据失败: ${error}`);
    }
  }
  
  // 添加事件
  async addEvent(event: CalendarEvent): Promise<void> {
    try {
      this.events.push(event);
      await this.saveEvents();
      console.info(`成功添加日程: ${event.title}`);
    } catch (error) {
      // 如果保存失败，回滚内存中的更改
      this.events = this.events.filter(e => e.id !== event.id);
      console.error('添加事件失败:', error);
      throw new Error(`添加事件失败: ${error}`);
    }
  }
  
  // 更新事件
  async updateEvent(event: CalendarEvent): Promise<void> {
    try {
      const index = this.events.findIndex(e => e.id === event.id);
      if (index !== -1) {
        const oldEvent = this.events[index];
        this.events[index] = event;
        await this.saveEvents();
        console.info(`成功更新日程: ${event.title}`);
      } else {
        throw new Error(`未找到ID为 ${event.id} 的事件`);
      }
    } catch (error) {
      console.error('更新事件失败:', error);
      throw new Error(`更新事件失败: ${error}`);
    }
  }
  
  // 删除事件
  async deleteEvent(eventId: string): Promise<void> {
    try {
      const eventToDelete = this.events.find(e => e.id === eventId);
      if (!eventToDelete) {
        throw new Error(`未找到ID为 ${eventId} 的事件`);
      }
      
      this.events = this.events.filter(e => e.id !== eventId);
      await this.saveEvents();
      console.info(`成功删除日程: ${eventToDelete.title}`);
    } catch (error) {
      console.error('删除事件失败:', error);
      throw new Error(`删除事件失败: ${error}`);
    }
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
  
  // 获取事件统计信息
  getEventsStats(): EventsStats {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const thisMonthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    
    return {
      total: this.events.length,
      thisMonth: this.getEventsForDateRange(thisMonthStart, thisMonthEnd).length,
      today: this.getEventsForDate(today).length
    } as EventsStats;
  }
  
  // 清空所有事件（用于测试或重置）
  async clearAllEvents(): Promise<void> {
    try {
      this.events = [];
      await this.saveEvents();
      console.info('已清空所有日程事件');
    } catch (error) {
      console.error('清空事件失败:', error);
      throw new Error(`清空事件失败: ${error}`);
    }
  }
}