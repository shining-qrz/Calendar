// 日程事件数据模型
export class CalendarEvent {
  id: string = '';
  title: string = '';
  description: string = '';
  startTime: Date = new Date();
  endTime: Date = new Date();
  isAllDay: boolean = false;
  reminder: number = 0; // 提醒时间（分钟）
  color: string = '#007AFF';
  
  constructor(data?: Partial<CalendarEvent>) {
    if (data) {
      if (data.id !== undefined) this.id = data.id;
      if (data.title !== undefined) this.title = data.title;
      if (data.description !== undefined) this.description = data.description;
      if (data.startTime !== undefined) this.startTime = data.startTime;
      if (data.endTime !== undefined) this.endTime = data.endTime;
      if (data.isAllDay !== undefined) this.isAllDay = data.isAllDay;
      if (data.reminder !== undefined) this.reminder = data.reminder;
      if (data.color !== undefined) this.color = data.color;
    }
    if (!this.id) {
      this.id = this.generateId();
    }
  }
  
  private generateId(): string {
    const timestamp = Date.now().toString();
    const randomNum = Math.floor(Math.random() * 1000000000).toString();
    return timestamp + randomNum;
  }
}

// 日程提醒类型
export enum ReminderType {
  NONE = 0,
  AT_TIME = 1,
  FIVE_MINUTES = 5,
  TEN_MINUTES = 10,
  FIFTEEN_MINUTES = 15,
  THIRTY_MINUTES = 30,
  ONE_HOUR = 60,
  ONE_DAY = 1440
}

// 视图类型
export enum ViewType {
  MONTH = 'month',
  WEEK = 'week',
  DAY = 'day'
}