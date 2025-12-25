import { CalendarEvent } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';
import { LunarUtils } from '../utils/LunarUtils';

@Component
export struct MonthView {
  @State @Watch('onCurrentDateChange') currentDate: Date = new Date();
  @State monthDates: Date[] = [];
  @State animationOffset: number = 0;
  @State isAnimating: boolean = false;
  @Prop events: CalendarEvent[] = [];
  @Prop selectedDate: Date = new Date();
  onDateSelected?: (date: Date) => void;
  onDateDoubleClick?: (date: Date) => void;
  onMonthChanged?: (date: Date) => void;
  
  aboutToAppear() {
    this.updateMonthDates();
    // 初始化时通知父组件当前月份
    if (this.onMonthChanged) {
      this.onMonthChanged(this.currentDate);
    }
  }
  
  onCurrentDateChange() {
    this.updateMonthDates();
    // 月份变化时通知父组件
    if (this.onMonthChanged) {
      this.onMonthChanged(this.currentDate);
    }
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
  
  private animateMonthChange(direction: number) {
    this.isAnimating = true;
    this.animationOffset = direction * 100;
    
    animateTo({
      duration: 300,
      curve: Curve.EaseInOut,
      onFinish: () => {
        this.isAnimating = false;
        this.animationOffset = 0;
      }
    }, () => {
      this.animationOffset = 0;
    });
  }
  
  private previousMonth() {
    this.animateMonthChange(-1);
    this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
  }
  
  private nextMonth() {
    this.animateMonthChange(1);
    this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
  }
  
  private getFestivalText(): string {
    const festival = LunarUtils.getFestival(this.selectedDate) || LunarUtils.getLunarFestival(this.selectedDate);
    const fullGanZhi = LunarUtils.getFullGanZhi(this.selectedDate);
    
    if (festival) {
      return `${festival} | ${fullGanZhi}`;
    } else {
      return fullGanZhi;
    }
  }
  
  build() {
    Column() {
      // 月份标题
      Row() {
        Button('<')
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .onClick(() => {
            this.previousMonth();
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
            this.nextMonth();
          })
      }
      .width('100%')
      .backgroundColor('#FFF8DC')
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
      .backgroundColor('#FFF8DC')
      
      // 日期网格容器（添加动画效果）
      Stack() {
        Grid() {
          ForEach(this.monthDates, (date: Date, index: number) => {
            GridItem() {
              if (this.isCurrentMonth(date)) {
                Column() {
                  // 公历日期
                  Text(date.getDate().toString())
                    .fontSize(14)
                    .fontColor(DateUtils.isToday(date) ? Color.White : '#333333')
                    .fontWeight(DateUtils.isToday(date) ? FontWeight.Bold : FontWeight.Normal)
                  
                  // 农历日期或节日
                  Text(LunarUtils.getLunarText(date))
                    .fontSize(9)
                    .fontColor(LunarUtils.isFestival(date) ? '#FF3B30' : '#999999')
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
                .onClick(() => {
                  if (this.onDateSelected) {
                    this.onDateSelected(date);
                  }
                })
              } else {
                // 非本月日期显示为空白
                Column()
                  .width('100%')
                  .height(45)
              }
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
        .width('100%')
        .height(280)
        .padding(1)
        .translate({ x: this.animationOffset })
        .opacity(this.isAnimating ? 0.7 : 1.0)
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
      .width('100%')
      .height(280)
      .clip(true)
      .backgroundColor('#FFF8DC')
      
      // 选中日期的详细信息展示
      Column() {
        // 第一行：农历日期
        Text(LunarUtils.getDetailedLunarInfo(this.selectedDate))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: 6 })
          .padding({top: 5})
        
        // 第二行：节日 + 干支信息（紧凑的圆角矩形）
        Row() {
          Text(this.getFestivalText())
            .fontSize(11)
            .fontColor('#555555')
        }
        .alignItems(VerticalAlign.Center)
        .borderRadius(12)
        .padding({right: 12, top: 2, bottom: 6 })
        .margin({ top: 2 })
        .width('100%') // Row占满Column宽度
      }
      .width('98%') // 减小宽度
      .backgroundColor('#FFF8DC')
      .borderRadius(12)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .margin({ top: 8 })
      .alignItems(HorizontalAlign.Start) // Column内部元素左对齐
      .alignSelf(ItemAlign.Center) // 整个组件居中
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8') // 米黄色背景'#FFF8DC'
  }
}