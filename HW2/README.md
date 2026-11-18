# HW2：PWM 呼吸燈與多功能 LED 效果

## 一、作業目的

本題使用 VHDL 設計一個可調整亮度與速度的 LED 控制器。透過 PWM（脈衝寬度調變）控制 LED 平均亮度，再利用 EGO-XZ7 板上的按鍵切換不同燈效。

程式預設輸入時脈為 **100 MHz**、PWM 頻率為 **1 kHz**、亮度解析度為 **8 bit（0～255）**。

## 二、功能說明

1. **呼吸燈模式：** LED 亮度從暗逐步增加至最亮，再逐步降低至熄滅，反覆循環。
2. **閃爍模式：** LED 在全亮與熄滅之間切換。
3. **漸亮常亮模式：** LED 從熄滅逐步增加亮度，達到最亮後保持常亮。
4. **速度調整：** 可切換慢速、一般、快速三個速度等級。
5. **暫停／繼續：** 暫停燈效變化，但 PWM 仍持續運作，避免亮度輸出不穩。
6. **按鍵處理：** 使用兩級同步及約 10 ms 的取樣消抖，並以按下事件觸發控制。

## 三、板上按鍵功能

| EGO-XZ7 按鍵 | VHDL 訊號 | 功能 |
|---|---|---|
| U | `btn(0)` | 切換燈效：呼吸 → 閃爍 → 漸亮常亮 → 循環 |
| R | `btn(1)` | 加快速度 |
| L | `btn(2)` | 放慢速度 |
| D | `btn(3)` | 暫停／繼續 |
| C | `reset` | 重置系統，回到預設呼吸燈與一般速度 |

速度參數在原始程式中定義為：慢速約 4 秒一個呼吸循環、一般速度約 2 秒、快速約 1 秒。實際循環時間仍會受到時脈與整數除頻參數影響。

## 四、檔案說明

| 檔案 | 用途 |
|---|---|
| `src/HW2.vhd` | 主程式，包含 PWM、燈效狀態、速度及按鍵控制 |
| `sim/HW2_tb.vhd` | 模擬測試平台，產生時脈、重置及按鍵輸入 |
| `constraints/HW2.xdc` | EGO-XZ7 時脈、按鍵及 LED 腳位設定 |
| `scripts/create_project.tcl` | 自動建立 Vivado 專案並加入上述檔案 |

## 五、Vivado 開啟方式

在 Vivado 2026.1 的 Tcl Console，從倉庫根目錄執行：

```tcl
source HW2/scripts/create_project.tcl
```

建立專案後，確認：

- Synthesis Top：`HW2`
- Simulation Top：`HW2_tb`
- Constraints：`HW2.xdc`
- FPGA Part：`xc7z020clg484-1`

接著可執行 Run Simulation、Run Synthesis、Run Implementation。若要下載到板子，再執行 Generate Bitstream。

## 六、硬體注意事項

XDC 依 EGO-XZ7 的按鍵與 LED 腳位整理。按鍵所在 Bank 的 I/O 電壓設定假設為板卡手冊所述的預設 2.5 V（JP1／VADJ）。若實際板卡跳線或供電不同，請先核對硬體手冊，再調整 IOSTANDARD；不要直接忽略 DRC 的電壓警告。

## 七、目前驗證狀態

本次工作是找回與整理原有檔案，沒有在此環境執行 Vivado 2026.1 模擬、綜合、實作或實體 LED 測試。請在自己的 Vivado 環境重新跑過流程後，再記錄實際測試結果。
