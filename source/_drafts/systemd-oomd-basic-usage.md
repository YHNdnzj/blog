---
title: systemd-oomd 基本使用
date:
tags: 
- Linux
- systemd
---

> systemd 247 引入了自己的 OOM killer systemd-oomd（~~「systemd，你個 init 又吞併功能了」~~，瞭解後發現其可以更好地針對 cgroup 進行 OOM 監控/管理。但其文檔並不豐富、缺少示例配置，於是打算介紹一下其基本使用。
>
> <!-- more -->

> 2021 年末本想試着寫年終總結，結果和之前提過的 幻 14 的使用感受、軟路由之後幾篇一起拖到了 2022
>
> 而且看來還要拖很久的樣子（~~其它可以拖，但年終總結是有時間限制的啊~~
