# VGA XDC 使用注意事項

`EGO_XZ7_VGA.xdc` 是早期 VGA 設計的時脈限制起始檔，只提供時脈限制與 PACKAGE_PIN 語法範例，並未替 `video_clk`、`rst`、`VGA_HSYNC`、`VGA_VSYNC`、`VGA_R`、`VGA_G`、`VGA_B` 全部指定已核對的板卡腳位。

因此它不能直接作為 EGO-XZ7 實體板卡的完整約束檔，也不應在未補齊、未核對腳位前用來產生 Bitstream。請依正確板卡版本的硬體手冊或原廠 Master XDC 補上腳位。
