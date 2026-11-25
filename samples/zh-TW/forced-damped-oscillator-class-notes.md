# 受迫阻尼振盪：為什麼接近共振時振幅會變大？

> 大學普通物理課堂筆記 · 力學與振動

## 從彈簧上的質塊開始

把質量為 $m$ 的物體接到彈簧上。以平衡位置為原點，彈力為 $-kx$，阻力與速度成正比，寫成 $-b\dot{x}$。若再施加週期性外力 $F_0\cos(\omega t)$，牛頓第二定律給出

$$
m\ddot{x}+b\dot{x}+kx=F_0\cos(\omega t).
$$

令 $\omega_0=\sqrt{k/m}$ 為無阻尼自然角頻率，$\gamma=b/(2m)$ 為振幅衰減率。當系統欠阻尼（$0<\gamma<\omega_0$），初始位置與速度決定的暫態解為

$$
x_{\mathrm{tr}}(t)=e^{-\gamma t}
\bigl[C\cos(\omega_d t)+D\sin(\omega_d t)\bigr],
\qquad
\omega_d=\sqrt{\omega_0^2-\gamma^2}.
$$

經過足夠長的時間，暫態隨指數因子衰減，剩下與外力同頻率的穩態振動。

## 用複數求穩態

把外力寫成 $F_0e^{i\omega t}$ 的實部，並設位移為 $\tilde X e^{i\omega t}$ 的實部。每微分一次就會乘上 $i\omega$。代回運動方程後，

$$
\begin{aligned}
(-m\omega^2+ib\omega+k)\tilde X &=F_0,\\
\tilde X &=\frac{F_0}{k-m\omega^2+ib\omega}
          =A(\omega)e^{-i\phi}.
\end{aligned}
$$

取實部得到 $x_{\mathrm{ss}}(t)=A(\omega)\cos(\omega t-\phi)$，其中

$$
A(\omega)=\frac{F_0}{\sqrt{(k-m\omega^2)^2+(b\omega)^2}},
\qquad
\phi=\operatorname{atan2}(b\omega,k-m\omega^2).
$$

$\phi$ 是位移落後外力的相位角。當 $\omega=\omega_0$，分母中的實部為零，位移落後外力 $\pi/2$。此時速度與外力同相，所以兩者相乘得出的瞬時功率在整個週期內皆非負。

## 位移振幅在哪裡最大？

固定 $F_0>0$，讓振幅分母的平方 $Q(\omega)=(k-m\omega^2)^2+b^2\omega^2$ 最小。

$$
\begin{aligned}
\frac{dQ}{d\omega}
  &=2\omega\bigl[2m^2\omega^2-2mk+b^2\bigr],\\
\omega_{\mathrm{peak}}
  &=\sqrt{\frac{k}{m}-\frac{b^2}{2m^2}}
   =\sqrt{\omega_0^2-2\gamma^2}.
\end{aligned}
$$

當 $0<\gamma<\omega_0/\sqrt{2}$，上式給出正頻率上的位移振幅峰值。阻尼達到或超過這個門檻時，振幅從低頻往高頻遞減。注意題目問的是**位移峰值**時，用的是 $\omega_{\mathrm{peak}}$。$\omega_d$ 則是外力關掉後，自由振盪的角頻率。

## 算例：比較三個角頻率

取 $m=1.0\,\mathrm{kg}$、$k=25\,\mathrm{N/m}$、$b=4.0\,\mathrm{N\,s/m}$，外力振幅 $F_0=2.0\,\mathrm{N}$。

| 物理量 | 計算結果 |
| --- | --- |
| 無阻尼自然角頻率 $\omega_0$ | $5.00\,\mathrm{rad/s}$ |
| 欠阻尼自由振盪角頻率 $\omega_d$ | $\sqrt{21}\,\mathrm{rad/s}\approx4.58\,\mathrm{rad/s}$ |
| 位移振幅峰值所在角頻率 $\omega_{\mathrm{peak}}$ | $\sqrt{17}\,\mathrm{rad/s}\approx4.12\,\mathrm{rad/s}$ |

若外力以 $\omega_0=5.00\,\mathrm{rad/s}$ 驅動，穩態振幅為

$$
A(\omega_0)=\frac{F_0}{b\omega_0}
=\frac{2.0\,\mathrm{N}}{20\,\mathrm{N/m}}
=0.10\,\mathrm{m}.
$$

若改在位移峰值頻率驅動，振幅約為 $0.109\,\mathrm{m}$。

## 自我練習

1. 關掉外力後，振幅包絡線降到關閉當下的 $1/e$ 需要多久？
2. 將算例的阻尼係數改成 $8.0\,\mathrm{N\,s/m}$。自由振盪還會出現嗎？位移振幅還有正頻率峰值嗎？

### 參考答案

1. 由 $e^{-\gamma t}=e^{-1}$ 得 $t=1/\gamma=0.50\,\mathrm{s}$。
2. 此時 $\gamma=4.0\,\mathrm{s^{-1}}<\omega_0=5.0\,\mathrm{rad/s}$，自由振盪仍為欠阻尼，角頻率為 $3.0\,\mathrm{rad/s}$。但 $\omega_0^2-2\gamma^2=25-32<0$，所以位移振幅沒有正頻率峰值。
