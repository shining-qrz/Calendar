import { CalendarEvent, ViewType } from '../model/CalendarEvent';
import { CalendarService } from '../service/CalendarService';
import { ReminderService } from '../service/ReminderService';
import { SampleDataGenerator } from '../data/SampleData';
import { MonthView } from '../components/MonthView';
import { WeekView } from '../components/WeekView';
import { DayView } from '../components/DayView';
import { EventDialog } from '../components/EventDialog';
import { DateUtils } from '../utils/DateUtils';
import { StorageUtils } from '../utils/StorageUtils';
import { ReminderUtils } from '../utils/ReminderUtils';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State currentView: ViewType = ViewType.MONTH;
  @State selectedDate: Date = new Date();
  @State currentDisplayDate: Date = new Date(); // 当前显示的月份
  @State events: CalendarEvent[] = [];
  @State isLoading: boolean = true;
  @State eventsVersion: number = 0; // 添加版本号来强制UI刷新
  
  private calendarService = CalendarService.getInstance();
  private reminderService = ReminderService.getInstance();
  private eventDialogController: CustomDialogController = new CustomDialogController({
    builder: EventDialog({
      onConfirm: (event: CalendarEvent) => {
        this.handleEventSave(event);
      },
      onDelete: (eventId: string) => {
        this.handleEventDelete(eventId);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  });
  
  async aboutToAppear() {
    await this.initServices();
    await this.loadEvents();
    await this.initSampleData();
    
    // 开发调试：测试持久化功能
    await this.testPersistence();
  }
  
  private async initServices() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.calendarService.init(context);
      await this.reminderService.init(context);
      this.isLoading = false;
    } catch (error) {
      console.error('初始化服务失败:', error);
      this.isLoading = false;
    }
  }
  
  private async loadEvents() {
    try {
      const newEvents = this.calendarService.getAllEvents();
      // 强制触发响应式更新：创建新的数组引用并更新版本号
      this.events = [...newEvents];
      this.eventsVersion++; // 强制触发UI刷新
      console.info(`已加载 ${this.events.length} 个日程事件，版本: ${this.eventsVersion}`);
    } catch (error) {
      console.error('加载事件失败:', error);
    }
  }
  
  private async initSampleData() {
    try {
      if (SampleDataGenerator.shouldGenerateSampleData(this.events)) {
        const sampleEvents = SampleDataGenerator.generateSampleEvents();
        for (const event of sampleEvents) {
          await this.calendarService.addEvent(event);
          await this.reminderService.setEventReminder(event);
        }
        await this.loadEvents();
        console.info('已生成示例数据');
      }
    } catch (error) {
      console.error('初始化示例数据失败:', error);
    }
  }
  
  // 测试持久化功能（开发调试用）
  private async testPersistence() {
    try {
      const stats = await StorageUtils.getStorageStats();
      console.info('存储统计:', stats);
      
      const validation = await StorageUtils.validateData();
      console.info('数据验证:', validation);
      
      if (!validation.isValid) {
        console.warn('发现数据问题:', validation.issues);
        const cleanedCount = await StorageUtils.cleanupInvalidData();
        console.info(`已清理 ${cleanedCount} 个无效数据`);
      }
    } catch (error) {
      console.error('测试持久化功能失败:', error);
    }
  }
  
  
  private async handleEventSave(event: CalendarEvent) {
    try {
      const existingEvent = this.calendarService.getEventById(event.id);
      if (existingEvent) {
        await this.calendarService.updateEvent(event);
        console.info('日程更新成功');
      } else {
        await this.calendarService.addEvent(event);
        console.info('日程添加成功');
      }
      
      // 设置提醒
      await this.reminderService.setEventReminder(event);
      
      // 重新加载事件列表
      await this.loadEvents();
      
      // 强制触发UI刷新
      console.info(`事件保存完成，当前事件总数: ${this.events.length}`);
    } catch (error) {
      console.error('保存事件失败:', error);
      // 这里可以添加用户提示，比如Toast或AlertDialog
    }
  }
  
  private async handleEventDelete(eventId: string) {
    try {
      await this.calendarService.deleteEvent(eventId);
      await this.reminderService.cancelEventReminder(eventId);
      console.info('日程删除成功');
      
      // 重新加载事件列表
      await this.loadEvents();
      
      // 强制触发UI刷新
      console.info(`事件删除完成，当前事件总数: ${this.events.length}`);
    } catch (error) {
      console.error('删除事件失败:', error);
      // 这里可以添加用户提示，比如Toast或AlertDialog
    }
  }
  
  private showEventDialog(event?: CalendarEvent, date?: Date) {
    let dialogEvent: CalendarEvent;
    
    if (event) {
      // 手动复制事件属性
      dialogEvent = new CalendarEvent();
      dialogEvent.id = event.id;
      dialogEvent.title = event.title;
      dialogEvent.description = event.description;
      dialogEvent.startTime = event.startTime;
      dialogEvent.endTime = event.endTime;
      dialogEvent.isAllDay = event.isAllDay;
      dialogEvent.reminder = event.reminder;
      dialogEvent.color = event.color;
    } else {
      // 创建新事件
      dialogEvent = new CalendarEvent();
      dialogEvent.startTime = date || this.selectedDate;
      dialogEvent.endTime = new Date((date || this.selectedDate).getTime() + 60 * 60 * 1000); // 默认1小时
    }
    
    this.eventDialogController = new CustomDialogController({
      builder: EventDialog({
        event: dialogEvent,
        isEdit: !!event,
        onConfirm: (event: CalendarEvent) => {
          this.handleEventSave(event);
        },
        onDelete: (eventId: string) => {
          this.handleEventDelete(eventId);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: false
    });
    
    this.eventDialogController.open();
  }
  
  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#007AFF')
          
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          // 顶部工具栏（左侧显示年月，右侧保留"+"按钮）
          Row() {
            Text(`${this.currentDisplayDate.getFullYear()}/${this.currentDisplayDate.getMonth() + 1}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            
            Blank()
            
            Button() {
              Image($r('app.media.add_icon'))
                .width(24)
                .height(24)
                .fillColor('#007AFF')
            }
            .backgroundColor(Color.Transparent)
            .width(40)
            .height(40)
            .onClick(() => {
              this.showEventDialog();
            })
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 1 }, color: '#E0E0E0' })
          
          // 日历视图
          Column() {
            if (this.currentView === ViewType.MONTH) {
              MonthView({
                events: this.events,
                selectedDate: this.selectedDate,
                eventsVersion: this.eventsVersion, // 传递版本号
                onDateSelected: (date: Date) => {
                  this.selectedDate = date;
                },
                onDateDoubleClick: (date: Date) => {
                  this.showEventDialog(undefined, date);
                },
                onMonthChanged: (date: Date) => {
                  this.currentDisplayDate = date;
                }
              })
            } else if (this.currentView === ViewType.WEEK) {
              WeekView({
                events: this.events,
                selectedDate: this.selectedDate,
                eventsVersion: this.eventsVersion, // 传递版本号
                onDateSelected: (date: Date) => {
                  this.selectedDate = date;
                },
                onEventClick: (event: CalendarEvent) => {
                  this.showEventDialog(event);
                },
                onTimeSlotClick: (date: Date, hour: number) => {
                  const eventDate = new Date(date);
                  eventDate.setHours(hour, 0, 0, 0);
                  this.showEventDialog(undefined, eventDate);
                }
              })
            } else {
              DayView({
                currentDate: this.selectedDate,
                events: this.events,
                eventsVersion: this.eventsVersion, // 传递版本号
                onEventClick: (event: CalendarEvent) => {
                  this.showEventDialog(event);
                },
                onTimeSlotClick: (date: Date, hour: number) => {
                  const eventDate = new Date(date);
                  eventDate.setHours(hour, 0, 0, 0);
                  this.showEventDialog(undefined, eventDate);
                }
              })
            }
          }
          .layoutWeight(1)
          .width('100%')
          
          // 底部导航栏
          Row() {
            Column() {
              Text('月')
                .fontSize(14)
                .fontColor(this.currentView === ViewType.MONTH ? '#007AFF' : '#666666')
                .fontWeight(this.currentView === ViewType.MONTH ? FontWeight.Bold : FontWeight.Normal)
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentView = ViewType.MONTH;
            })
            
            Column() {
              Text('周')
                .fontSize(14)
                .fontColor(this.currentView === ViewType.WEEK ? '#007AFF' : '#666666')
                .fontWeight(this.currentView === ViewType.WEEK ? FontWeight.Bold : FontWeight.Normal)
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentView = ViewType.WEEK;
            })
            
            Column() {
              Text('日')
                .fontSize(14)
                .fontColor(this.currentView === ViewType.DAY ? '#007AFF' : '#666666')
                .fontWeight(this.currentView === ViewType.DAY ? FontWeight.Bold : FontWeight.Normal)
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentView = ViewType.DAY;
            })
          }
          .width('100%')
          .height(60)
          .backgroundColor('#FFFFFF')
          .border({ width: { top: 1 }, color: '#E0E0E0' })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}