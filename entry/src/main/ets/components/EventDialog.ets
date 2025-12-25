import { CalendarEvent, ReminderType } from '../model/CalendarEvent';
import { DateUtils } from '../utils/DateUtils';

@CustomDialog
export struct EventDialog {
  @State event: CalendarEvent = new CalendarEvent();
  @State isEdit: boolean = false;
  @State startDateStr: string = '';
  @State startTimeStr: string = '';
  @State endDateStr: string = '';
  @State endTimeStr: string = '';
  
  controller: CustomDialogController;
  onConfirm?: (event: CalendarEvent) => void;
  onDelete?: (eventId: string) => void;
  
  aboutToAppear() {
    this.updateDateTimeStrings();
  }
  
  private updateDateTimeStrings() {
    this.startDateStr = DateUtils.formatDate(this.event.startTime, 'YYYY-MM-DD');
    this.startTimeStr = DateUtils.formatDate(this.event.startTime, 'HH:mm');
    this.endDateStr = DateUtils.formatDate(this.event.endTime, 'YYYY-MM-DD');
    this.endTimeStr = DateUtils.formatDate(this.event.endTime, 'HH:mm');
  }
  
  private updateEventDateTime() {
    const startDate = new Date(`${this.startDateStr}T${this.startTimeStr}`);
    const endDate = new Date(`${this.endDateStr}T${this.endTimeStr}`);
    
    this.event.startTime = startDate;
    this.event.endTime = endDate;
  }
  
  build() {
    Column() {
      // 标题
      Row() {
        Text(this.isEdit ? '编辑日程' : '新建日程')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        if (this.isEdit) {
          Button('删除')
            .backgroundColor('#FF3B30')
            .fontColor(Color.White)
            .fontSize(14)
            .onClick(() => {
              if (this.onDelete) {
                this.onDelete(this.event.id);
              }
              this.controller.close();
            })
        }
      }
      .width('100%')
      .margin({ bottom: 20 })
      
      // 标题输入
      Column() {
        Text('标题')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入日程标题', text: this.event.title })
          .onChange((value: string) => {
            this.event.title = value;
          })
          .width('100%')
      }
      .margin({ bottom: 16 })
      
      // 描述输入
      Column() {
        Text('描述')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextArea({ placeholder: '请输入日程描述', text: this.event.description })
          .onChange((value: string) => {
            this.event.description = value;
          })
          .width('100%')
          .height(80)
      }
      .margin({ bottom: 16 })
      
      // 全天开关
      Row() {
        Text('全天')
          .fontSize(14)
          .layoutWeight(1)
        
        Toggle({ type: ToggleType.Switch, isOn: this.event.isAllDay })
          .onChange((isOn: boolean) => {
            this.event.isAllDay = isOn;
          })
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 开始时间
      Column() {
        Text('开始时间')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        Row() {
          Button(this.startDateStr)
            .backgroundColor('#F2F2F2')
            .fontColor('#333333')
            .layoutWeight(1)
            .margin({ right: 8 })
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date('1900-1-1'),
                end: new Date('2100-1-1'),
                selected: new Date(this.startDateStr),
                onAccept: (value: DatePickerResult) => {
                  if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                    this.startDateStr = `${value.year}-${String(value.month + 1).padStart(2, '0')}-${String(value.day).padStart(2, '0')}`;
                    this.updateEventDateTime();
                  }
                }
              });
            })
          
          if (!this.event.isAllDay) {
            Button(this.startTimeStr)
              .backgroundColor('#F2F2F2')
              .fontColor('#333333')
              .layoutWeight(1)
              .onClick(() => {
                TimePickerDialog.show({
                  selected: new Date(`2000-01-01T${this.startTimeStr}`),
                  onAccept: (value: TimePickerResult) => {
                    if (value.hour !== undefined && value.minute !== undefined) {
                      this.startTimeStr = `${String(value.hour).padStart(2, '0')}:${String(value.minute).padStart(2, '0')}`;
                      this.updateEventDateTime();
                    }
                  }
                });
              })
          }
        }
      }
      .margin({ bottom: 16 })
      
      // 结束时间
      Column() {
        Text('结束时间')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        Row() {
          Button(this.endDateStr)
            .backgroundColor('#F2F2F2')
            .fontColor('#333333')
            .layoutWeight(1)
            .margin({ right: 8 })
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date('1900-1-1'),
                end: new Date('2100-1-1'),
                selected: new Date(this.endDateStr),
                onAccept: (value: DatePickerResult) => {
                  if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                    this.endDateStr = `${value.year}-${String(value.month + 1).padStart(2, '0')}-${String(value.day).padStart(2, '0')}`;
                    this.updateEventDateTime();
                  }
                }
              });
            })
          
          if (!this.event.isAllDay) {
            Button(this.endTimeStr)
              .backgroundColor('#F2F2F2')
              .fontColor('#333333')
              .layoutWeight(1)
              .onClick(() => {
                TimePickerDialog.show({
                  selected: new Date(`2000-01-01T${this.endTimeStr}`),
                  onAccept: (value: TimePickerResult) => {
                    if (value.hour !== undefined && value.minute !== undefined) {
                      this.endTimeStr = `${String(value.hour).padStart(2, '0')}:${String(value.minute).padStart(2, '0')}`;
                      this.updateEventDateTime();
                    }
                  }
                });
              })
          }
        }
      }
      .margin({ bottom: 16 })
      
      // 提醒设置
      Column() {
        Text('提醒')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        Select([
          { value: '无提醒' },
          { value: '准时' },
          { value: '5分钟前' },
          { value: '10分钟前' },
          { value: '15分钟前' },
          { value: '30分钟前' },
          { value: '1小时前' },
          { value: '1天前' }
        ])
          .selected(this.getReminderIndex())
          .value(this.getReminderText())
          .onSelect((index: number, value: string) => {
            const reminderTypes = [
              ReminderType.NONE, ReminderType.AT_TIME, ReminderType.FIVE_MINUTES,
              ReminderType.TEN_MINUTES, ReminderType.FIFTEEN_MINUTES,
              ReminderType.THIRTY_MINUTES, ReminderType.ONE_HOUR, ReminderType.ONE_DAY
            ];
            this.event.reminder = reminderTypes[index];
          })
          .width('100%')
      }
      .margin({ bottom: 16 })
      
      // 颜色选择
      Column() {
        Text('颜色')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        Row() {
          ForEach([
            '#007AFF', '#FF3B30', '#FF9500', '#FFCC00',
            '#34C759', '#5AC8FA', '#AF52DE', '#FF2D92'
          ], (color: string) => {
            Circle({ width: 30, height: 30 })
              .fill(color)
              .stroke(this.event.color === color ? '#333333' : Color.Transparent)
              .strokeWidth(2)
              .margin({ right: 8 })
              .onClick(() => {
                this.event.color = color;
              })
          })
        }
      }
      .margin({ bottom: 24 })
      
      // 按钮
      Row() {
        Button('取消')
          .backgroundColor('#F2F2F2')
          .fontColor('#333333')
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => {
            this.controller.close();
          })
        
        Button('确定')
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            if (this.event.title.trim()) {
              this.updateEventDateTime();
              if (this.onConfirm) {
                this.onConfirm(this.event);
              }
              this.controller.close();
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
  
  private getReminderIndex(): number {
    const options = [
      ReminderType.NONE, ReminderType.AT_TIME, ReminderType.FIVE_MINUTES,
      ReminderType.TEN_MINUTES, ReminderType.FIFTEEN_MINUTES,
      ReminderType.THIRTY_MINUTES, ReminderType.ONE_HOUR, ReminderType.ONE_DAY
    ];
    return options.indexOf(this.event.reminder);
  }
  
  private getReminderText(): string {
    const texts = [
      '无提醒', '准时', '5分钟前', '10分钟前',
      '15分钟前', '30分钟前', '1小时前', '1天前'
    ];
    return texts[this.getReminderIndex()] || '无提醒';
  }
}