import { CalendarEvent } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';

@Component
export struct WeekView {
  @State @Watch('onCurrentDateChange') currentDate: Date = new Date();
  @State weekDates: Date[] = [];
  @Prop events: CalendarEvent[] = [];
  @Prop selectedDate: Date = new Date();
  onDateSelected?: (date: Date) => void;
  onEventClick?: (event: CalendarEvent) => void;
  
  private readonly hours: number[] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23];
  
  aboutToAppear() {
    this.updateWeekDates();
  }
  
  onCurrentDateChange() {
    this.updateWeekDates();
  }
  
  private updateWeekDates() {
    this.weekDates = DateUtils.getWeekDates(this.currentDate);
  }
  
  private getEventsForDate(date: Date): CalendarEvent[] {
    return this.events.filter(event => 
      DateUtils.isSameDay(new Date(event.startTime), date)
    );
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
      
      // 日期标题行
      Row() {
        ForEach(this.weekDates, (date: Date) => {
          Column() {
            Text(DateUtils.getWeekdayShort(date))
              .fontSize(12)
              .fontColor('#666666')
            
            Text(date.getDate().toString())
              .fontSize(16)
              .fontColor(DateUtils.isToday(date) ? Color.White : '#333333')
              .fontWeight(DateUtils.isToday(date) ? FontWeight.Bold : FontWeight.Normal)
              .backgroundColor(DateUtils.isToday(date) ? '#007AFF' : 
                (this.isSelected(date) ? '#E3F2FD' : Color.Transparent))
              .borderRadius(16)
              .width(32)
              .height(32)
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .onClick(() => {
            if (this.onDateSelected) {
              this.onDateSelected(date);
            }
          })
        })
      }
      .width('100%')
      .height(80)
      .backgroundColor('#F5F5F5')
      .padding({ top: 8, bottom: 8 })
      
      // 时间轴和事件
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
              
              // 时间线
              Column() {
                Divider()
                  .color('#E0E0E0')
                  .strokeWidth(1)
                
                // 事件区域
                Row() {
                  ForEach(this.weekDates, (date: Date) => {
                    Column() {
                      ForEach(this.getHourEvents(date, hour), (event: CalendarEvent) => {
                        this.EventItem(event)
                      })
                    }
                    .layoutWeight(1)
                    .height(60)
                    .margin({ left: 1, right: 1 })
                  })
                }
                .width('100%')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .height(60)
          })
        }
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
  }
  
  private getHourEvents(date: Date, hour: number): CalendarEvent[] {
    return this.getEventsForDate(date).filter(event => {
      const eventHour = new Date(event.startTime).getHours();
      return eventHour === hour;
    });
  }
  
  @Builder EventItem(event: CalendarEvent) {
    Text(event.title)
      .fontSize(12)
      .fontColor(Color.White)
      .backgroundColor(event.color)
      .borderRadius(4)
      .padding({ left: 4, right: 4, top: 2, bottom: 2 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
      .margin({ bottom: 2 })
      .onClick(() => {
        if (this.onEventClick) {
          this.onEventClick(event);
        }
      })
  }
}