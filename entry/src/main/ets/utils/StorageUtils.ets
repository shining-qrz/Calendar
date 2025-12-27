import { CalendarService } from '../service/CalendarService';
import { CalendarEvent } from '../model/CalendarEvent';

// 存储统计信息接口
interface StorageStats {
  totalEvents: number;
  thisMonthEvents: number;
  todayEvents: number;
  storageSize: string;
}

// 数据验证结果接口
interface ValidationResult {
  isValid: boolean;
  issues: string[];
}

// 导出数据格式接口
interface ExportData {
  version: string;
  exportTime: string;
  events: CalendarEvent[];
}

// 存储工具类，用于调试和管理持久化数据
export class StorageUtils {
  
  // 获取存储统计信息
  static async getStorageStats(): Promise<StorageStats> {
    try {
      const calendarService = CalendarService.getInstance();
      const stats = calendarService.getEventsStats();
      
      // 估算存储大小（简单计算）
      const allEvents = calendarService.getAllEvents();
      const jsonString = JSON.stringify(allEvents);
      // 使用字符串长度估算字节大小（UTF-8编码下，英文字符1字节，中文字符约3字节）
      const sizeInBytes = jsonString.length * 2; // 简单估算，假设平均每字符2字节
      const sizeInKB = (sizeInBytes / 1024).toFixed(2);
      
      return {
        totalEvents: stats.total,
        thisMonthEvents: stats.thisMonth,
        todayEvents: stats.today,
        storageSize: `${sizeInKB} KB`
      } as StorageStats;
    } catch (error) {
      console.error('获取存储统计失败:', error);
      return {
        totalEvents: 0,
        thisMonthEvents: 0,
        todayEvents: 0,
        storageSize: '0 KB'
      } as StorageStats;
    }
  }
  
  // 导出数据（用于备份）
  static async exportData(): Promise<string> {
    try {
      const calendarService = CalendarService.getInstance();
      const allEvents = calendarService.getAllEvents();
      
      const exportData: ExportData = {
        version: '1.0',
        exportTime: new Date().toISOString(),
        events: allEvents
      };
      
      return JSON.stringify(exportData, null, 2);
    } catch (error) {
      console.error('导出数据失败:', error);
      throw new Error(`导出数据失败: ${error}`);
    }
  }
  
  // 验证数据完整性
  static async validateData(): Promise<ValidationResult> {
    try {
      const calendarService = CalendarService.getInstance();
      const allEvents = calendarService.getAllEvents();
      const issues: string[] = [];
      
      // 检查数据完整性
      for (const event of allEvents) {
        if (!event.id) {
          issues.push(`事件缺少ID: ${event.title}`);
        }
        if (!event.title || event.title.trim() === '') {
          issues.push(`事件缺少标题: ID ${event.id}`);
        }
        if (!event.startTime || isNaN(event.startTime.getTime())) {
          issues.push(`事件开始时间无效: ${event.title}`);
        }
        if (!event.endTime || isNaN(event.endTime.getTime())) {
          issues.push(`事件结束时间无效: ${event.title}`);
        }
        if (event.startTime && event.endTime && event.startTime > event.endTime) {
          issues.push(`事件时间顺序错误: ${event.title}`);
        }
      }
      
      // 检查ID重复
      const ids = allEvents.map(e => e.id);
      const duplicateIds = ids.filter((id, index) => ids.indexOf(id) !== index);
      if (duplicateIds.length > 0) {
        issues.push(`发现重复ID: ${duplicateIds.join(', ')}`);
      }
      
      return {
        isValid: issues.length === 0,
        issues: issues
      } as ValidationResult;
    } catch (error) {
      console.error('验证数据失败:', error);
      return {
        isValid: false,
        issues: [`验证过程出错: ${error.message}`]
      } as ValidationResult;
    }
  }
  
  // 清理无效数据
  static async cleanupInvalidData(): Promise<number> {
    try {
      const calendarService = CalendarService.getInstance();
      const allEvents = calendarService.getAllEvents();
      let cleanedCount = 0;
      
      for (const event of allEvents) {
        let needsCleanup = false;
        
        // 检查并修复无效数据
        if (!event.id) {
          event.id = new Date().getTime().toString() + Math.random().toString(36).substr(2, 9);
          needsCleanup = true;
        }
        
        if (!event.title || event.title.trim() === '') {
          event.title = '未命名事件';
          needsCleanup = true;
        }
        
        if (!event.startTime || isNaN(event.startTime.getTime())) {
          event.startTime = new Date();
          needsCleanup = true;
        }
        
        if (!event.endTime || isNaN(event.endTime.getTime())) {
          event.endTime = new Date(event.startTime.getTime() + 60 * 60 * 1000); // 默认1小时
          needsCleanup = true;
        }
        
        if (event.startTime > event.endTime) {
          event.endTime = new Date(event.startTime.getTime() + 60 * 60 * 1000);
          needsCleanup = true;
        }
        
        if (needsCleanup) {
          await calendarService.updateEvent(event);
          cleanedCount++;
        }
      }
      
      console.info(`数据清理完成，修复了 ${cleanedCount} 个事件`);
      return cleanedCount;
    } catch (error) {
      console.error('清理数据失败:', error);
      throw new Error(`清理数据失败: ${error}`);
    }
  }
}