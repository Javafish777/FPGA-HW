# HW3：EGO-XZ7 HDMI RGB 色塊顯示

## 一、作業目的

本題使用 EGO-XZ7 V1.2 板載的 **ADV7511 HDMI 發射器**，將 FPGA 產生的影像送到 HDMI 螢幕。預設畫面為黑色背景，上方顯示紅、綠、藍三個直向排列的色塊（同一水平列、由左至右排列）。不需要另外接 VGA 轉接器。

目標裝置為 `xc7z020clg484-1`，設計時脈來源為板上的 100 MHz PL clock。

## 二、畫面與顯示時序

- 有效顯示區域：640 × 480。
- 水平總像素：800（640 有效區 + 16 前肩 + 96 同步 + 48 後肩）。
- 垂直總行數：525（480 有效區 + 10 前肩 + 2 同步 + 33 後肩）。
- Pixel Clock：約 25.1553 MHz，由 100 MHz PL clock 經 MMCM 產生。
- 更新率：約 59.9 Hz。
- HSYNC／VSYNC：低電位有效。
- ADV7511 平行輸入格式：24-bit YCbCr 4:2:2、Style 2。

三個色塊的座標及尺寸可在 `HW3_HDMI_TOP.vhd` 的 Generic 修改：

| 色塊 | 預設左上角 | 預設尺寸 |
|---|---:|---:|
| 紅色 | (40, 80) | 160 × 120 |
| 綠色 | (240, 80) | 160 × 120 |
| 藍色 | (440, 80) | 160 × 120 |

## 三、程式模組說明

| 檔案 | 功能 |
|---|---|
| `src/HW3_HDMI_TOP.vhd` | 頂層模組，產生像素時脈、640×480 掃描時序、色塊圖案，並將 RGB 轉成 ADV7511 所需的 YCbCr 資料格式 |
| `src/ADV7511_INIT.vhd` | 透過 I2C 初始化 ADV7511 暫存器，設定影像輸入格式及 640×480 顯示相關參數 |
| `sim/HW3_HDMI_TOP_tb.vhd` | 測試平台，使用模擬模式檢查同步訊號與 HDMI 資料匯流排是否為有效邏輯值 |
| `constraints/EGO_XZ7_HDMI.xdc` | EGO-XZ7 V1.2 的時脈、HDMI 資料、同步、I2C、重置及 LED 腳位限制 |
| `scripts/create_project.tcl` | 建立 Vivado 專案並加入主程式、初始化模組、Testbench 與 XDC |

## 四、LED 狀態指示

- **LED0：** ADV7511 初始化完成。
- **LED1：** I2C 初始化發生錯誤或未取得 ACK。
- **BTNC：** 重置影像時序與 ADV7511 初始化流程（高電位有效）。

ADV7511 的 I2C 腳位採 Open-Drain：FPGA 只負責拉低或釋放訊號，板上需有適當上拉。初始化程式會先嘗試 7-bit 位址 `0x39`，若未收到 ACK 再嘗試 `0x3D`；實際位址仍須依板上 PD／AD Strap 狀態確認。

## 五、Vivado 開啟方式

在 Vivado 2026.1 的 Tcl Console，從倉庫根目錄執行：

```tcl
source HW3/HDMI/scripts/create_project.tcl
```

建立專案後，確認：

- Synthesis Top：`HW3_HDMI_TOP`
- Simulation Top：`HW3_HDMI_TOP_tb`
- FPGA Part：`xc7z020clg484-1`
- XDC：`EGO_XZ7_HDMI.xdc`

模擬時使用 Testbench 內的 `G_SIMULATION => true` 設定；實際板卡設計則使用預設的 MMCM 像素時脈模式。模擬通過後，再依序執行 Synthesis、Implementation、Generate Bitstream。

## 六、EGO-XZ7 硬體注意事項

XDC 中 HDMI 訊號與 LED 使用 LVCMOS33；中心按鍵 BTNC（P16）使用 LVCMOS25，這是依 EGO-XZ7 V1.2 手冊所記錄的 JP1 預設 2.5 V VADJ 條件設定。若 JP1 已改為其他電壓，必須先依實際 Bank 電壓核對並調整 IOSTANDARD。

上電建議順序：先接好 HDMI 線與螢幕，再開啟板卡並下載 Bitstream。若沒有畫面，應先檢查 I2C ACK、ADV7511 位址 Strap、HDMI 線與螢幕、HPD、Bank 電壓及 XDC 腳位。

## 七、目前驗證狀態

這次已找回並整理 HDL、Testbench、XDC 與專案腳本，但目前沒有在此環境使用 Vivado 2026.1 完成綜合、實作、模擬或實體 HDMI 螢幕測試。因此不能保證已能直接產生可用 Bitstream；請在實際板卡上依手冊核對腳位及電壓後再測試。
