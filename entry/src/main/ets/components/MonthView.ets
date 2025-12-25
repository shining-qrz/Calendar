import { CalendarEvent } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';
import { LunarUtils } from '../utils/LunarUtils';

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
      .height(40)
      .padding({ left: 16, right: 16 })
      
      // 星期标题
      Row() {
        ForEach(['日', '一', '二', '三', '四', '五', '六'], (weekday: string) => {
          Text(weekday)
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        })
      }
      .width('100%')
      .height(30)
      .backgroundColor('#F5F5F5')
      
      // 日期网格
      Grid() {
        ForEach(this.monthDates, (date: Date, index: number) => {
          GridItem() {
            Column() {
              // 公历日期
              Text(date.getDate().toString())
                .fontSize(14)
                .fontColor(this.isCurrentMonth(date) ? 
                  (DateUtils.isToday(date) ? Color.White : '#333333') : '#CCCCCC')
                .fontWeight(DateUtils.isToday(date) ? FontWeight.Bold : FontWeight.Normal)
              
              // 农历日期或节日
              Text(LunarUtils.getLunarText(date))
                .fontSize(9)
                .fontColor(LunarUtils.isFestival(date) ? '#FF3B30' : 
                  (this.isCurrentMonth(date) ? '#999999' : '#DDDDDD'))
                .margin({ top: 1 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              
              // 事件指示器
              if (this.getEventsForDate(date).length > 0) {
                Row() {
                  ForEach(this.getEventsForDate(date).slice(0, 3), (event: CalendarEvent) => {
                    Circle({ width: 3, height: 3 })
                      .fill(event.color)
                      .margin({ right: 1 })
                  })
                  
                  if (this.getEventsForDate(date).length > 3) {
                    Text(`+${this.getEventsForDate(date).length - 3}`)
                      .fontSize(7)
                      .fontColor('#666666')
                  }
                }
                .justifyContent(FlexAlign.Center)
                .margin({ top: 1 })
              }
            }
            .width('100%')
            .height(45)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(DateUtils.isToday(date) ? '#007AFF' : Color.Transparent)
            .border(this.isSelected(date) && !DateUtils.isToday(date) ? 
              { width: 1, color: '#007AFF' } : { width: 0 })
            .borderRadius(3)
            .margin(0.5)
            .padding(1)
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
      .height(280)
      .padding(1)
    }
    .width('100%')
    .height('100%')
  }
}