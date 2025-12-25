import { CalendarEvent, ViewType } from '../model/CalendarEvent';
import { CalendarService } from '../service/CalendarService';
import { ReminderService } from '../service/ReminderService';
import { SampleDataGenerator } from '../data/SampleData';
import { MonthView } from '../components/MonthView';
import { WeekView } from '../components/WeekView';
import { DayView } from '../components/DayView';
import { EventDialog } from '../components/EventDialog';
import { DateUtils } from '../utils/DateUtils';

@Entry
@Component
struct Index {
  @State currentView: ViewType = ViewType.MONTH;
  @State selectedDate: Date = new Date();
  @State events: CalendarEvent[] = [];
  @State isLoading: boolean = true;
  
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
  }
  
  private async initServices() {
    try {
      await this.calendarService.init(getContext(this));
      this.isLoading = false;
    } catch (error) {
      console.error('初始化服务失败:', error);
      this.isLoading = false;
    }
  }
  
  private async loadEvents() {
    try {
      this.events = this.calendarService.getAllEvents();
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
  
  private async handleEventSave(event: CalendarEvent) {
    try {
      const existingEvent = this.calendarService.getEventById(event.id);
      if (existingEvent) {
        await this.calendarService.updateEvent(event);
      } else {
        await this.calendarService.addEvent(event);
      }
      
      // 设置提醒
      await this.reminderService.setEventReminder(event);
      
      await this.loadEvents();
    } catch (error) {
      console.error('保存事件失败:', error);
    }
  }
  
  private async handleEventDelete(eventId: string) {
    try {
      await this.calendarService.deleteEvent(eventId);
      await this.reminderService.cancelEventReminder(eventId);
      await this.loadEvents();
    } catch (error) {
      console.error('删除事件失败:', error);
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
          // 顶部工具栏（只保留"+"按钮）
          Row() {
            Blank()
            
            Button('+')
              .backgroundColor('#007AFF')
              .fontColor(Color.White)
              .fontSize(18)
              .width(40)
              .height(40)
              .borderRadius(20)
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
                onDateSelected: (date: Date) => {
                  this.selectedDate = date;
                },
                onDateDoubleClick: (date: Date) => {
                  this.showEventDialog(undefined, date);
                }
              })
            } else if (this.currentView === ViewType.WEEK) {
              WeekView({
                events: this.events,
                selectedDate: this.selectedDate,
                onDateSelected: (date: Date) => {
                  this.selectedDate = date;
                },
                onEventClick: (event: CalendarEvent) => {
                  this.showEventDialog(event);
                }
              })
            } else {
              DayView({
                currentDate: this.selectedDate,
                events: this.events,
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