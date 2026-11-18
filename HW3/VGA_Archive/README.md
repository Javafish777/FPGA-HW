# HW3 VGA 舊版程式保存區

## 資料夾用途

這裡保存 HW3 早期以 VGA 時序產生 RGB 色塊的版本，供比較與回顧設計過程使用。它們不是目前的 ADV7511 HDMI 實體輸出版本；若要接 EGO-XZ7 板載 HDMI，請使用 `HW3/HDMI/` 內的程式。

## 檔案說明

| 檔案 | 說明 |
|---|---|
| `src/HW3_VGA.vhd` | 較完整的 VGA 版本，輸入 100 MHz 時脈，使用每四個時脈一次的像素更新使能，產生 640×480 掃描與 RGB 色塊 |
| `src/HW3_VGA_early.vhd` | 較早期的 VGA 實作，保留作為程式演進的參考 |
| `constraints/EGO_XZ7_VGA.xdc` | VGA 時脈限制範例，並未包含所有 VGA 訊號已核實的 PACKAGE_PIN |
| `constraints/README.md` | 說明 VGA XDC 尚不能直接用於實體燒錄的原因 |

## VGA 基本時序

- 有效區域：640 × 480。
- 水平總計：800 像素。
- 垂直總計：525 行。
- 舊版以 100 MHz 時脈除以 4，建立約 25 MHz 像素更新節奏。
- 畫面包含紅、綠、藍色塊。

## 使用提醒

這一區是歷史參考程式，不是 HDMI 專案。`EGO_XZ7_VGA.xdc` 只有時脈限制與腳位設定語法範例，沒有完整、已確認的 VGA PACKAGE_PIN 對照。**不可直接拿它當成可燒錄的完整 XDC。**
