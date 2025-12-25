import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { CalendarEvent, ReminderType } from '../../../main/ets/model/CalendarEvent';
import { DateUtils } from '../../../main/ets/utils/DateUtils';
import { LunarUtils } from '../../../main/ets/utils/LunarUtils';
import { SolarTermUtils } from '../../../main/ets/utils/SolarTermUtils';

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
    
    it('should get lunar info correctly', () => {
      const date = new Date('2025-01-29'); // 春节
      const lunarInfo = LunarUtils.getLunarInfo(date);
      expect(lunarInfo.month).assertEqual(1);
      expect(lunarInfo.day).assertEqual(1);
      expect(lunarInfo.monthName).assertEqual('正月');
      expect(lunarInfo.dayName).assertEqual('初一');
    });
    
    it('should detect festivals correctly', () => {
      const springFestival = new Date('2025-01-29'); // 春节
      expect(LunarUtils.isFestival(springFestival)).assertTrue();
      expect(LunarUtils.getLunarFestival(springFestival)).assertEqual('春节');
    });
    
    it('should get solar terms on exact dates only', () => {
      // 测试2025年的精确节气日期
      const lichun = new Date(2025, 1, 4); // 2月4日立春
      const lichunBefore = new Date(2025, 1, 3); // 2月3日
      const lichunAfter = new Date(2025, 1, 5); // 2月5日
      
      expect(SolarTermUtils.getSolarTerm(lichun)).assertEqual('立春');
      expect(SolarTermUtils.getSolarTerm(lichunBefore)).assertEqual(null);
      expect(SolarTermUtils.getSolarTerm(lichunAfter)).assertEqual(null);
      
      // 测试春分
      const chunfen = new Date(2025, 2, 20); // 3月20日春分
      const chunfenBefore = new Date(2025, 2, 19); // 3月19日
      const chunfenAfter = new Date(2025, 2, 21); // 3月21日
      
      expect(SolarTermUtils.getSolarTerm(chunfen)).assertEqual('春分');
      expect(SolarTermUtils.getSolarTerm(chunfenBefore)).assertEqual(null);
      expect(SolarTermUtils.getSolarTerm(chunfenAfter)).assertEqual(null);
    });
    
    it('should get year solar terms correctly', () => {
      const yearTerms = SolarTermUtils.getYearSolarTerms(2025);
      expect(yearTerms.size).assertEqual(24);
      
      // 验证几个关键节气的日期
      let lichunFound = false;
      let chunfenFound = false;
      let xiazhiFound = false;
      let dongzhiFound = false;
      
      for (const entry of yearTerms) {
        const key = entry[0];
        const date = entry[1];
        const term = SolarTermUtils.getSolarTerm(date);
        if (term === '立春' && date.getMonth() === 1 && date.getDate() === 4) {
          lichunFound = true;
        }
        if (term === '春分' && date.getMonth() === 2 && date.getDate() === 20) {
          chunfenFound = true;
        }
        if (term === '夏至' && date.getMonth() === 5 && date.getDate() === 21) {
          xiazhiFound = true;
        }
        if (term === '冬至' && date.getMonth() === 11 && date.getDate() === 21) {
          dongzhiFound = true;
        }
      }
      
      expect(lichunFound).assertTrue();
      expect(chunfenFound).assertTrue();
      expect(xiazhiFound).assertTrue();
      expect(dongzhiFound).assertTrue();
    });
  });
}