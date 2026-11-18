# FPGA 作業整理專案（FPGA-HW）

這個倉庫用來整理 FPGA 課程的 HW1、HW2、HW3 程式、模擬檔與硬體腳位設定。主要開發環境為 **Vivado 2026.1**，目標板卡為 **EGO-XZ7 V1.2（XC7Z020-CLG484-1）**。

## 作業總覽

| 作業 | 主題 | 目前整理狀態 |
|---|---|---|
| HW1 | FPGA 第一題 | 原始 VHDL 尚未找回，已建立說明與待補資料夾 |
| HW2 | PWM LED 呼吸燈與多種燈效 | 已整理主程式、Testbench、XDC、Vivado 建立專案腳本 |
| HW3 | VGA／HDMI 影像輸出與 RGB 色塊 | 已整理 HDMI 版本、ADV7511 初始化、Testbench、XDC，並保留早期 VGA 版本 |

## 資料夾結構

```text
FPGA-HW/
├── README.md
├── .gitignore
├── HW1/
│   └── README.md
├── HW2/
│   ├── src/HW2.vhd
│   ├── sim/HW2_tb.vhd
│   ├── constraints/HW2.xdc
│   ├── scripts/create_project.tcl
│   └── README.md
└── HW3/
    ├── HDMI/
    │   ├── src/HW3_HDMI_TOP.vhd
    │   ├── src/ADV7511_INIT.vhd
    │   ├── sim/HW3_HDMI_TOP_tb.vhd
    │   ├── constraints/EGO_XZ7_HDMI.xdc
    │   ├── scripts/create_project.tcl
    │   └── README.md
    └── VGA_Archive/
        ├── src/HW3_VGA.vhd
        ├── src/HW3_VGA_early.vhd
        ├── constraints/EGO_XZ7_VGA.xdc
        ├── constraints/README.md
        └── README.md
```

## 各作業在做什麼？

### HW1：第一題

目前找回的歷史資料中，HW1 資料夾沒有可用的 VHDL 程式，原本的 FPGA 程式尚未成功還原。因此這裡先保留資料夾與說明文件，等找到原始檔後再補上，不會拿其他課程的程式代替。

### HW2：PWM 呼吸燈與多種 LED 效果

使用 PWM 控制 LED 亮度，並透過 EGO-XZ7 按鍵切換呼吸、閃爍、漸亮常亮三種效果。按鍵包含模式切換、速度調整與暫停／繼續，另有按鍵同步與消抖設計。

### HW3：影像輸出

HW3 先保留早期 VGA 色塊實作，另有目前整理的 HDMI 版本。HDMI 版本透過 EGO-XZ7 板載 ADV7511，輸出 640×480 影像，預設在黑色背景上顯示紅、綠、藍三個色塊。

## 使用方式

1. 使用 Vivado 2026.1 開啟對應作業的專案，或在 Vivado Tcl Console 執行該作業資料夾內的 `scripts/create_project.tcl`。
2. 確認專案中的 Top Module、Simulation Top 與 XDC 檔案均指向正確版本。
3. 先執行模擬，再執行 Synthesis、Implementation；需要實體板卡時才產生 Bitstream。
4. 燒錄前務必確認 EGO-XZ7 板卡版本、JP1／VADJ 電壓與 XDC 腳位設定。

## 開啟 Vivado 專案的 Tcl 指令

在倉庫根目錄下執行：

```tcl
source HW2/scripts/create_project.tcl
```

HW3 HDMI：

```tcl
source HW3/HDMI/scripts/create_project.tcl
```

## 還原與測試狀態

- HW2 與 HW3 的 VHDL、Testbench 和部分 XDC 是從先前保存的專案檔案找回並歸檔，原始邏輯沒有為了整理而改寫。
- HW1 的 FPGA 原始程式目前尚未找回。另有一份 VLSI／Virtuoso／HSPICE 的 HW1 報告，但它不是這個 FPGA 專案的程式，因此沒有混放。
- 這次整理沒有在本環境執行 Vivado 2026.1 綜合、實作、完整模擬或實體板卡測試。請勿將「檔案已整理」視為「已通過硬體驗證」。

## GitHub

遠端倉庫：<https://github.com/Javafish777/FPGA-HW>

若要從 Windows 上傳，請使用資料夾中的 `開始上傳.bat`；它會只對該次 PowerShell 程序暫時使用執行原則 Bypass，不會永久修改系統的 PowerShell 安全設定。也可以參考 `UPLOAD_TO_GITHUB.ps1`。
