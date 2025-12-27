import { CalendarEvent } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';

@Component
export struct WeekView {
  @State @Watch('onCurrentDateChange') currentDate: Date = new Date();
  @State weekDates: Date[] = [];
  @Prop @Watch('onEventsChange') events: CalendarEvent[] = [];
  @Prop @Watch('onEventsVersionChange') eventsVersion: number = 0;
  @Prop selectedDate: Date = new Date();
  onDateSelected?: (date: Date) => void;
  onEventClick?: (event: CalendarEvent) => void;
  onTimeSlotClick?: (date: Date, hour: number) => void;
  
  private readonly hours: number[] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23];
  
  aboutToAppear() {
    this.updateWeekDates();
  }
  
  onCurrentDateChange() {
    this.updateWeekDates();
  }
  
  onEventsChange() {
    // 当events数组变化时，强制刷新UI
    console.info(`WeekView: 事件数组已更新，当前事件数量: ${this.events.length}`);
  }
  
  onEventsVersionChange() {
    // 当版本号变化时，强制刷新UI
    console.info(`WeekView: 事件版本已更新，版本号: ${this.eventsVersion}`);
  }
  
  private updateWeekDates() {
    this.weekDates = DateUtils.getWeekDates(this.currentDate);
  }
  
  private getEventsForDate(date: Date): CalendarEvent[] {
    return this.events.filter(event => 
      DateUtils.isSameDay(new Date(event.startTime), date)
    );
  }
  
  private getHourEvents(date: Date, hour: number): CalendarEvent[] {
    return this.getEventsForDate(date).filter(event => {
      const eventHour = new Date(event.startTime).getHours();
      return eventHour === hour;
    });
  }
  
  private isSelected(date: Date): boolean {
    return DateUtils.isSameDay(date, this.selectedDate);
  }
  
  build() {
    Column() {
      // 周标题
      Row() {
        Button('<')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            const newDate = new Date(this.currentDate);
            newDate.setDate(newDate.getDate() - 7);
            this.currentDate = newDate;
          })
        
        Text(`${this.weekDates[0].getFullYear()}年${this.weekDates[0].getMonth() + 1}月`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('>')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            const newDate = new Date(this.currentDate);
            newDate.setDate(newDate.getDate() + 7);
            this.currentDate = newDate;
          })
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      // 网格布局：行为时间，列为星期
      Column() {
        // 表头：星期标题行
        Row() {
          // 时间列标题（空白）
          Text('')
            .width(60)
            .height(40)
            .backgroundColor('#F5F5F5')
            .border({ width: 1, color: '#E0E0E0' })
          
          // 星期列标题
          ForEach(this.weekDates, (date: Date) => {
            Column() {
              Text(DateUtils.getWeekdayShort(date))
                .fontSize(12)
                .fontColor('#666666')
              
              Text(date.getDate().toString())
                .fontSize(14)
                .fontColor(DateUtils.isToday(date) ? Color.White : '#333333')
                .fontWeight(DateUtils.isToday(date) ? FontWeight.Bold : FontWeight.Normal)
                .backgroundColor(DateUtils.isToday(date) ? '#007AFF' : 
                  (this.isSelected(date) ? '#E3F2FD' : Color.Transparent))
                .borderRadius(12)
                .width(24)
                .height(24)
                .textAlign(TextAlign.Center)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#F5F5F5')
            .border({ width: 1, color: '#E0E0E0' })
            .onClick(() => {
              if (this.onDateSelected) {
                this.onDateSelected(date);
              }
            })
          })
        }
        .width('100%')
        
        // 时间网格
        Scroll() {
          Column() {
            ForEach(this.hours, (hour: number) => {
              Row() {
                // 时间标签列
                Text(`${hour.toString().padStart(2, '0')}:00`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .width(60)
                  .height((() => {
                    let maxHeight = 30;
                    for (const date of this.weekDates) {
                      const events = this.getHourEvents(date, hour);
                      // 只有当日程数量大于2时才扩展高度
                      const cellHeight = events.length > 2 ? 30 + (events.length - 2) * 18 : 30;
                      maxHeight = Math.max(maxHeight, cellHeight);
                    }
                    return maxHeight;
                  })())
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#F8F8F8')
                  .border({ width: 1, color: '#E0E0E0' })
                  .padding({ top: 12 })
                
                // 星期列（事件单元格）
                ForEach(this.weekDates, (date: Date, dayIndex: number) => {
                  Column() {
                    ForEach(this.getHourEvents(date, hour), (event: CalendarEvent) => {
                      this.EventItem(event)
                    })
                  }
                  .layoutWeight(1)
                  .height((() => {
                    let maxHeight = 30;
                    for (const date of this.weekDates) {
                      const events = this.getHourEvents(date, hour);
                      // 只有当日程数量大于2时才扩展高度
                      const cellHeight = events.length > 2 ? 30 + (events.length - 2) * 18 : 30;
                      maxHeight = Math.max(maxHeight, cellHeight);
                    }
                    return maxHeight;
                  })())
                  .backgroundColor(Color.White)
                  .border({ width: 1, color: '#E0E0E0' })
                  .padding(2)
                  .justifyContent(FlexAlign.Start)
                  .alignItems(HorizontalAlign.Start)
                  .onClick(() => {
                    if (this.onTimeSlotClick) {
                      this.onTimeSlotClick(date, hour);
                    }
                  })
                })
              }
              .width('100%')
            })
          }
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  @Builder EventItem(event: CalendarEvent) {
    Text(event.title)
      .fontSize(10)
      .fontColor(Color.White)
      .backgroundColor(event.color)
      .borderRadius(3)
      .padding({ left: 3, right: 3, top: 1, bottom: 1 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .margin({ bottom: 1 })
      .onClick(() => {
        if (this.onEventClick) {
          this.onEventClick(event);
        }
      })
  }
}