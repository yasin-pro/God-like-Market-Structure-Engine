<p align="center">
  <img src="image.png">
</p>

# Market Structure Analysis Engine

A modular MQL5 analysis framework for realtime market structure, ZigZag legs, swing detection, and structure‑based trading research.

---

# Version 2 — Leg‑Based Strategy Engine

Version 2 expands the project from pure market structure analysis into a **research framework for leg‑based trading strategies**.

Instead of building strategies directly on raw candles, the engine converts price action into a sequence of **directional price legs** extracted from a realtime ZigZag structure.

Once the market is represented as legs, strategies can analyze higher‑level behaviour such as:

- impulse sequences
- pullbacks
- structural continuation
- wave patterns
- Fibonacci retracement behaviour

This update introduces three major components:

### Market Structure Engine
The core engine that detects directional legs and structural events in realtime.

### Strategy Modules
Independent strategy modules that analyze sequences of market legs and publish trading signals.

### Signal Bus
A decoupled communication layer where strategies publish signals without depending on execution logic.

This modular architecture allows new strategies to be added without modifying the core analysis engine.

---

## Overview

This project is built around several core modules:

- `CandleUtils.mqh`: candle utility helpers and bar-state logic
- `ZigZag.mqh`: realtime leg detection, leg strength measurement, reversal confirmation, and swing generation
- `MarketStructure.mqh`: swing structure analysis, BOS/CHOCH detection, bias tracking, protected levels, and chart visualization
- `StrategySignals.mqh`: three‑wave Fibonacci strategy
- `StrategySignal2.mqh`: five‑wave impulse + Wave6 pullback strategy
- `SignalBus.mqh`: signal publishing interface

Together, these modules form a reusable analytical engine for understanding price action in a structured way.

---

## What It Does

- Detects bullish and bearish legs in realtime
- Measures leg strength, quality, and internal candle composition
- Detects swing highs and swing lows
- Classifies swings as major or minor
- Tracks protected highs and protected lows
- Identifies BOS (Break of Structure)
- Identifies CHOCH (Change of Character)
- Maintains bullish, bearish, or unknown market bias
- Adapts to market volatility using dynamic thresholds
- Displays structure information directly on the chart
- Generates strategy signals based on leg sequences

---

## Strategy Modules

### Three‑Wave Fibonacci Strategy

A structure‑based continuation strategy.

Logic:

1. **Wave 1** breaks a moving average and establishes direction.
2. **Wave 2** retraces but respects the moving average.
3. **Wave 3** extends the impulse.

After Wave 3 completes, the system builds a **55‑65% Fibonacci retracement zone** of Wave 3.

If price returns to the zone and forms a **higher timeframe rejection candle**, a signal is generated.

---

### Five‑Wave Impulse + Wave 6 Pullback

Inspired by **Elliott Wave impulse logic**.

1. The engine detects a **five‑wave impulse structure**.
2. After the impulse completes, it waits for the next leg (**Wave 6**).
3. A Fibonacci retracement of Wave 6 is calculated.
4. If price retraces into the zone and forms a rejection candle, a signal is produced.

This allows strategies to react to **post‑impulse pullbacks** in a structured way.

---

## Trading Concepts Covered

### Leg Analysis

The engine splits price action into directional legs and measures:

- start and end price
- duration
- candle count
- net move vs total move
- efficiency
- bullish, bearish, and doji composition
- with‑leg and against‑leg pressure

### Reversal Detection

The ZigZag logic does not rely on a single fixed condition. It combines:

- opposite candle pressure
- pivot/fractal confirmation
- dynamic retracement logic
- adaptive thresholds based on market range and volatility

### Market Structure

The structure layer interprets swings and events to build a structural view of the market:

- major swing highs and lows
- protected levels
- BOS and CHOCH events
- bias transitions
- historical structure events

### Visualization

The project also draws the analytical state on chart:

- leg lines
- swing markers
- protected levels
- structure labels
- dashboard panel
- current bias and last structural event

---

## Architecture

```text
Main Script
├── CandleUtils.mqh
├── ZigZag.mqh
├── MarketStructure.mqh
├── StrategySignals.mqh
├── StrategySignal2.mqh
└── SignalBus.mqh
```

### Responsibilities

- `CandleUtils.mqh`: low‑level candle and bar helpers
- `ZigZag.mqh`: leg engine, strength model, reversal logic, swing extraction
- `MarketStructure.mqh`: structure interpretation, bias, BOS/CHOCH, protected levels
- `StrategySignals.mqh`: three‑wave Fibonacci strategy logic
- `StrategySignal2.mqh`: impulse + pullback strategy logic
- `SignalBus.mqh`: strategy signal interface

---

## Strengths

- modular design
- clear state management
- reusable components
- adaptive market modeling
- realtime structural analysis
- extensible strategy framework
- strong chart visualization support

---

## Current Limitations

- no complete entry/exit execution model
- no risk management layer
- no portfolio management
- no multi‑timeframe confirmation layer
- analysis and visualization are still partially coupled

---

## Potential Extensions

- order block detection
- fair value gap detection
- liquidity sweep logic
- multi‑timeframe structure alignment
- execution engine
- position sizing and risk manager
- logging and backtesting layer

---

## Summary

This project provides a **leg‑based market structure research engine** for MQL5.

It combines realtime ZigZag detection, structural analysis, and modular strategy components to create a flexible environment for developing and testing **structure‑driven trading strategies**.

If you are building algorithmic trading systems based on **market structure instead of raw candles**, this project provides a strong foundation.

---

## Support Development

If you find this project useful and want to support continued development, you can donate.

TRX Wallet:

```
TG6yyH3JRA7zEqQ8aUvvzhRwRAS4k6z7hv
```

---

## License

MIT License

---

## Author

GitHub: https://github.com/yasin-pro
