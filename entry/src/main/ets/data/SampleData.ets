import { CalendarEvent, ReminderType } from '../model/CalendarEvent';

// 示例数据生成器
export class SampleDataGenerator {
  
  // 生成示例日程数据
  static generateSampleEvents(): CalendarEvent[] {
    const today = new Date();
    const events: CalendarEvent[] = [];
    
    // 今天的会议
    const meeting = new CalendarEvent();
    meeting.title = '团队会议';
    meeting.description = '讨论项目进度和下周计划';
    meeting.startTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 10, 0);
    meeting.endTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 11, 0);
    meeting.reminder = ReminderType.FIFTEEN_MINUTES;
    meeting.color = '#007AFF';
    events.push(meeting);
    
    // 明天的约会
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const appointment = new CalendarEvent();
    appointment.title = '医生预约';
    appointment.description = '年度体检';
    appointment.startTime = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate(), 14, 30);
    appointment.endTime = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate(), 15, 30);
    appointment.reminder = ReminderType.ONE_HOUR;
    appointment.color = '#FF3B30';
    events.push(appointment);
    
    // 下周的生日聚会
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    const party = new CalendarEvent();
    party.title = '朋友生日聚会';
    party.description = '小李的生日派对';
    party.startTime = new Date(nextWeek.getFullYear(), nextWeek.getMonth(), nextWeek.getDate(), 18, 0);
    party.endTime = new Date(nextWeek.getFullYear(), nextWeek.getMonth(), nextWeek.getDate(), 22, 0);
    party.reminder = ReminderType.ONE_DAY;
    party.color = '#FF9500';
    party.isAllDay = false;
    events.push(party);
    
    // 全天事件 - 假期
    const vacation = new Date(today);
    vacation.setDate(vacation.getDate() + 14);
    const holiday = new CalendarEvent();
    holiday.title = '年假';
    holiday.description = '去海南旅游';
    holiday.startTime = new Date(vacation.getFullYear(), vacation.getMonth(), vacation.getDate(), 0, 0);
    holiday.endTime = new Date(vacation.getFullYear(), vacation.getMonth(), vacation.getDate(), 23, 59);
    holiday.reminder = ReminderType.ONE_DAY;
    holiday.color = '#34C759';
    holiday.isAllDay = true;
    events.push(holiday);
    
    // 重复的健身计划
    for (let i = 0; i < 7; i++) {
      const workoutDate = new Date(today);
      workoutDate.setDate(workoutDate.getDate() + i);
      
      // 只在工作日添加健身计划
      if (workoutDate.getDay() >= 1 && workoutDate.getDay() <= 5) {
        const workout = new CalendarEvent();
        workout.title = '健身';
        workout.description = '晨练 - 跑步和力量训练';
        workout.startTime = new Date(workoutDate.getFullYear(), workoutDate.getMonth(), workoutDate.getDate(), 7, 0);
        workout.endTime = new Date(workoutDate.getFullYear(), workoutDate.getMonth(), workoutDate.getDate(), 8, 0);
        workout.reminder = ReminderType.TEN_MINUTES;
        workout.color = '#5AC8FA';
        events.push(workout);
      }
    }
    
    return events;
  }
  
  // 检查是否需要生成示例数据
  static shouldGenerateSampleData(existingEvents: CalendarEvent[]): boolean {
    return existingEvents.length === 0;
  }
}