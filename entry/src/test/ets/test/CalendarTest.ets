import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { CalendarEvent, ReminderType } from '../../../main/ets/model/CalendarEvent';
import { DateUtils } from '../../../main/ets/utils/DateUtils';

export default function calendarTest() {
  describe('CalendarTest', () => {
    
    it('should create calendar event correctly', () => {
      const event = new CalendarEvent({
        title: '测试事件',
        description: '这是一个测试事件',
        startTime: new Date('2024-12-25T10:00:00'),
        endTime: new Date('2024-12-25T11:00:00'),
        reminder: ReminderType.FIFTEEN_MINUTES,
        color: '#007AFF'
      });
      
      expect(event.title).assertEqual('测试事件');
      expect(event.description).assertEqual('这是一个测试事件');
      expect(event.reminder).assertEqual(ReminderType.FIFTEEN_MINUTES);
      expect(event.color).assertEqual('#007AFF');
      expect(event.id).assertNotEqual('');
    });
    
    it('should format date correctly', () => {
      const date = new Date('2024-12-25T15:30:00');
      const formatted = DateUtils.formatDate(date, 'YYYY-MM-DD HH:mm');
      expect(formatted).assertEqual('2024-12-25 15:30');
    });
    
    it('should check if dates are same day', () => {
      const date1 = new Date('2024-12-25T10:00:00');
      const date2 = new Date('2024-12-25T15:30:00');
      const date3 = new Date('2024-12-26T10:00:00');
      
      expect(DateUtils.isSameDay(date1, date2)).assertTrue();
      expect(DateUtils.isSameDay(date1, date3)).assertFalse();
    });
    
    it('should get month dates correctly', () => {
      const date = new Date('2024-12-15');
      const monthDates = DateUtils.getMonthDates(date);
      
      expect(monthDates.length).assertEqual(42); // 6 weeks * 7 days
      expect(monthDates[0].getMonth()).assertLessOrEqual(date.getMonth());
    });
    
    it('should get week dates correctly', () => {
      const date = new Date('2024-12-25'); // Wednesday
      const weekDates = DateUtils.getWeekDates(date);
      
      expect(weekDates.length).assertEqual(7);
      expect(weekDates[0].getDay()).assertEqual(1); // Monday
    });
    
    it('should get month name correctly', () => {
      const date = new Date('2024-12-25');
      const monthName = DateUtils.getMonthName(date);
      expect(monthName).assertEqual('十二月');
    });
    
    it('should get weekday name correctly', () => {
      const date = new Date('2024-12-25'); // Wednesday
      const weekdayName = DateUtils.getWeekdayName(date);
      expect(weekdayName).assertEqual('周三');
    });
  });
}