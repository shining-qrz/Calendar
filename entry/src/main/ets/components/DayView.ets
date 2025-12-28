import { CalendarEvent } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';

@Component
export struct DayView {
  @Prop @Watch('onCurrentDateChange') currentDate: Date = new Date();
  @State refreshKey: number = 0; // 用于强制刷新UI
  @State dayEvents: CalendarEvent[] = []; // 缓存当天的事件
  @Prop @Watch('onEventsChange') events: CalendarEvent[] = [];
  @Prop @Watch('onEventsVersionChange') eventsVersion: number = 0;
  onEventClick?: (event: CalendarEvent) => void;
  onTimeSlotClick?: (date: Date, hour: number) => void;
  onDateChange?: (date: Date) => void; // 新增日期变化回调
  
  private readonly hours: number[] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23];
  
  onCurrentDateChange() {
    // 当日期变化时，更新当天事件并强制刷新UI
    this.updateDayEvents();
    this.refreshKey++;
    console.info(`DayView: 当前日期已更新: ${this.currentDate.toDateString()}, refreshKey: ${this.refreshKey}`);
  }
  
  onEventsChange() {
    // 当events数组变化时，更新当天事件并强制刷新UI
    this.updateDayEvents();
    console.info(`DayView: 事件数组已更新，当前事件数量: ${this.events.length}`);
  }
  
  onEventsVersionChange() {
    // 当版本号变化时，更新当天事件并强制刷新UI
    this.updateDayEvents();
    console.info(`DayView: 事件版本已更新，版本号: ${this.eventsVersion}`);
  }
  
  private updateDayEvents() {
    const currentDateStr = this.currentDate.toDateString();
    const filteredEvents = this.events.filter(event => {
      const eventDateStr = new Date(event.startTime).toDateString();
      const isSame = DateUtils.isSameDay(new Date(event.startTime), this.currentDate);
      console.info(`  检查事件 ${event.title}: 事件日期=${eventDateStr}, 当前日期=${currentDateStr}, 匹配=${isSame}`);
      return isSame;
    });
    this.dayEvents = [...filteredEvents]; // 确保引用更新
    console.info(`DayView: 更新${currentDateStr}的事件，共${this.dayEvents.length}个`);
  }
  
  aboutToAppear() {
    // 组件初始化时更新事件
    this.updateDayEvents();
  }
  
  private getDayEvents(): CalendarEvent[] {
    return this.dayEvents;
  }
  
  private getHourEvents(hour: number): CalendarEvent[] {
    return this.dayEvents.filter(event => {
      const eventHour = new Date(event.startTime).getHours();
      return eventHour === hour;
    });
  }
  
  build() {
    Column() {
      // 日期标题
      Row() {
        Button('<')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            const newDate = new Date(this.currentDate.getTime());
            newDate.setDate(newDate.getDate() - 1);
            if (this.onDateChange) {
              this.onDateChange(newDate);
            }
          })
        
        Column() {
          Text(`${this.currentDate.getFullYear()}年${this.currentDate.getMonth() + 1}月${this.currentDate.getDate()}日`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          
          Text(DateUtils.getWeekdayName(this.currentDate))
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        
        Button('>')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            const newDate = new Date(this.currentDate.getTime());
            newDate.setDate(newDate.getDate() + 1);
            if (this.onDateChange) {
              this.onDateChange(newDate);
            }
          })
      }
      .width('100%')
      .height(70)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      
      // 全天事件区域
      if (this.getAllDayEvents().length > 0) {
        Column() {
          Text('全天')
            .fontSize(12)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ left: 58, bottom: 4 })
          
          ForEach(this.getAllDayEvents(), (event: CalendarEvent) => {
            Row() {
              Text('')
                .width(50)
              
              Text(event.title)
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor(event.color)
                .borderRadius(4)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .layoutWeight(1)
                .onClick(() => {
                  if (this.onEventClick) {
                    this.onEventClick(event);
                  }
                })
            }
            .width('100%')
            .margin({ bottom: 4 })
          })
        }
        .width('100%')
        .backgroundColor('#F8F8F8')
        .padding({ top: 8, bottom: 8 })
        
        Divider()
          .color('#E0E0E0')
          .strokeWidth(1)
      }
      
      // 时间轴
      Scroll() {
        Column() {
          ForEach(this.hours, (hour: number) => {
            Row() {
              // 时间标签
              Text(`${hour.toString().padStart(2, '0')}:00`)
                .fontSize(12)
                .fontColor('#666666')
                .width(50)
                .textAlign(TextAlign.End)
                .margin({ right: 8 })
              
              // 事件区域
              Column() {
                Divider()
                  .color('#E0E0E0')
                  .strokeWidth(1)
                
                Column() {
                  this.HourEventsLayout(this.getHourEvents(hour), hour)
                }
                .width('100%')
                .height(60)
                .justifyContent(FlexAlign.Start)
                .alignItems(HorizontalAlign.Start)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .height(60)
          }, (hour: number) => `hour-${hour}-${this.refreshKey}`)
        }
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
  }
  
  private getAllDayEvents(): CalendarEvent[] {
    return this.getDayEvents().filter(event => event.isAllDay);
  }
  
  @Builder EventItem(event: CalendarEvent, width?: string) {
    Row() {
      Column()
        .width(3)
        .height('100%')
        .backgroundColor(event.color)
        .margin({ right: 6 })
      
      Column() {
        Text(event.title)
          .fontSize(width ? 12 : 14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(`${DateUtils.formatDate(new Date(event.startTime), 'HH:mm')} - ${DateUtils.formatDate(new Date(event.endTime), 'HH:mm')}`)
          .fontSize(width ? 10 : 12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(width || '100%')
    .backgroundColor('#F8F8F8')
    .borderRadius(6)
    .padding(width ? 8 : 12)
    .margin({ bottom: 4, right: width ? 2 : 0 })
    .onClick(() => {
      if (this.onEventClick) {
        this.onEventClick(event);
      }
    })
  }
  
  @Builder HourEventsLayout(events: CalendarEvent[], hour: number) {
    if (events.length === 0) {
      // 空白区域，可点击添加事件
      Row() {}
        .width('100%')
        .height('100%')
        .onClick(() => {
          if (this.onTimeSlotClick) {
            this.onTimeSlotClick(this.currentDate, hour);
          }
        })
    } else if (events.length === 1) {
      // 单个事件，占满宽度
      this.EventItem(events[0])
    } else {
      // 多个事件，横向排列
      Row() {
        ForEach(events, (event: CalendarEvent, index: number) => {
          this.EventItem(event, `${Math.floor(96 / events.length)}%`)
        }, (event: CalendarEvent) => `event-${event.id || event.title}-${hour}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Top)
    }
  }
}