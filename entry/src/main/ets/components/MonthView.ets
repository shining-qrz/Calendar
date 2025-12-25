import { CalendarEvent } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';

@Component
export struct MonthView {
  @State @Watch('onCurrentDateChange') currentDate: Date = new Date();
  @State monthDates: Date[] = [];
  @Prop events: CalendarEvent[] = [];
  @Prop selectedDate: Date = new Date();
  onDateSelected?: (date: Date) => void;
  onDateDoubleClick?: (date: Date) => void;
  
  aboutToAppear() {
    this.updateMonthDates();
  }
  
  onCurrentDateChange() {
    this.updateMonthDates();
  }
  
  private updateMonthDates() {
    this.monthDates = DateUtils.getMonthDates(this.currentDate);
  }
  
  private getEventsForDate(date: Date): CalendarEvent[] {
    return this.events.filter(event => 
      DateUtils.isSameDay(new Date(event.startTime), date)
    );
  }
  
  private isCurrentMonth(date: Date): boolean {
    return date.getMonth() === this.currentDate.getMonth();
  }
  
  private isSelected(date: Date): boolean {
    return DateUtils.isSameDay(date, this.selectedDate);
  }
  
  build() {
    Column() {
      // 月份标题
      Row() {
        Button('<')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
          })
        
        Text(`${this.currentDate.getFullYear()}年${DateUtils.getMonthName(this.currentDate)}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('>')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
          })
      }
      .width('100%')
      .height(50)
      .padding({ left: 16, right: 16 })
      
      // 星期标题
      Row() {
        ForEach(['一', '二', '三', '四', '五', '六', '日'], (weekday: string) => {
          Text(weekday)
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#F5F5F5')
      
      // 日期网格
      Grid() {
        ForEach(this.monthDates, (date: Date, index: number) => {
          GridItem() {
            Column() {
              Text(date.getDate().toString())
                .fontSize(16)
                .fontColor(this.isCurrentMonth(date) ? 
                  (DateUtils.isToday(date) ? Color.White : '#333333') : '#CCCCCC')
                .fontWeight(DateUtils.isToday(date) ? FontWeight.Bold : FontWeight.Normal)
              
              // 事件指示器
              if (this.getEventsForDate(date).length > 0) {
                Row() {
                  ForEach(this.getEventsForDate(date).slice(0, 3), (event: CalendarEvent) => {
                    Circle({ width: 6, height: 6 })
                      .fill(event.color)
                      .margin({ right: 2 })
                  })
                  
                  if (this.getEventsForDate(date).length > 3) {
                    Text(`+${this.getEventsForDate(date).length - 3}`)
                      .fontSize(10)
                      .fontColor('#666666')
                  }
                }
                .justifyContent(FlexAlign.Center)
                .margin({ top: 2 })
              }
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.isSelected(date) ? '#007AFF' : 
              (DateUtils.isToday(date) ? '#007AFF' : Color.Transparent))
            .borderRadius(4)
            .margin(2)
          }
          .onClick(() => {
            if (this.onDateSelected) {
              this.onDateSelected(date);
            }
          })
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .layoutWeight(1)
      .padding(4)
    }
    .width('100%')
    .height('100%')
  }
}