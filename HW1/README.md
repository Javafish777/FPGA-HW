# HW1：FPGA 第一題

## 作業說明

這個資料夾預留給 FPGA 課程的 HW1 原始程式、測試平台與腳位限制檔。預計整理內容如下：

- `src/`：HW1 的 VHDL 主程式（例如 `HW1.vhd`）。
- `sim/`：Testbench（例如 `HW1_tb.vhd`），用來在 Vivado Simulator 檢查輸入與輸出時序。
- `constraints/`：對應 EGO-XZ7 板卡的 XDC 腳位與時脈限制。
- `README.md`：作業目的、操作方式、按鍵定義與測試結果。

## 目前找回狀態

目前從可讀取的舊專案與檔案紀錄中，尚未找到可確認為 FPGA HW1 的原始 VHDL 主程式、Testbench 或完整 XDC。GitHub 舊歷史中曾出現 `HW1` 項目，但當時內容為空白檔案，不能當成可用原始碼。

另有找到 VLSI 電路設計、Virtuoso、HSPICE 相關的 HW1 報告；該份作業是 IC 電路設計內容，並非本 FPGA 專案的 HW1，因此不放入此資料夾，避免混淆。

## 後續補檔方式

找到原始程式後，請依照以下結構放入：

```text
HW1/
├── src/
│   └── HW1.vhd
├── sim/
│   └── HW1_tb.vhd
├── constraints/
│   └── HW1.xdc
└── README.md
```

**注意：** 目前沒有自行產生替代版主程式，也沒有宣稱 HW1 已完成或通過模擬。
