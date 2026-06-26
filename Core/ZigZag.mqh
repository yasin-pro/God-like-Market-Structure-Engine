#ifndef __ZIGZAG_CORE_MQH__
#define __ZIGZAG_CORE_MQH__

#define MAX_STORED_LEGS 50
#define PANEL_LINES 24

#define MAX_CANDLES_PER_LEG 300
#define LAST_COMPLETED_LEGS 10


//==================================================
// Structs
//==================================================
struct ZigZagSegment
{
   datetime time1;
   datetime time2;
   double   price1;
   double   price2;
   int      direction;
   double   movePrice;
   double   movePoints;
   double   movePips;
};

struct LegCandleInfo
{
   int      indexInLeg;

   datetime time;

   double   open;
   double   high;
   double   low;
   double   close;

   double   bodyPrice;
   double   bodyPoints;
   double   bodyPips;

   double   rangePrice;
   double   rangePoints;
   double   rangePips;

   double   upperWickPrice;
   double   lowerWickPrice;

   int      candleDirection;     // 1 bullish, -1 bearish, 0 doji
   int      relationToLeg;       // 1 with leg, -1 against leg, 0 neutral
   bool     isExtensionCandle;   // true if made new high/low in direction of leg
   bool     isOppositeCandle;    // true if opposite according to reversal logic

   double   strength;            // dynamic candle strength
   string   typeText;            // BULL, BEAR, DOJI
   string   relationText;        // WITH_LEG, AGAINST_LEG, NEUTRAL
};


struct LegInfo
{
   int      index;
   int      direction;      // 1 up, -1 down, 0 flat

   datetime startTime;
   datetime endTime;

   double   startPrice;
   double   endPrice;

   double   legHigh;
   double   legLow;

   int      segmentsCount;

   double   totalMovePrice;
   double   totalMovePoints;
   double   totalMovePips;

   double   netMovePrice;
   double   netMovePoints;
   double   netMovePips;

   int      durationBars;
   int      durationMinutes;

   bool     isClosed;

   // ==============================
   // New detailed leg information
   // ==============================
   int      candlesCount;
   datetime lastStoredCandleTime;

   double   averageCandleRangePrice;
   double   averageCandleRangePips;

   double   averageBodyPrice;
   double   averageBodyPips;

   int      bullishCandles;
   int      bearishCandles;
   int      dojiCandles;

   int      withLegCandles;
   int      againstLegCandles;
   int      neutralCandles;

   int      extensionCandles;
   int      oppositeCandles;

   double   strength;          // final leg strength score
   string   legTypeText;       // IMPULSE_UP, IMPULSE_DOWN, WEAK_UP, WEAK_DOWN, etc.

   LegCandleInfo candles[MAX_CANDLES_PER_LEG];
};


struct MarketDynamics
{
   int    runtimeBars;
   int    lookback;
   int    fractalWing;
   double avgRange;
   double rangeDeviation;
   double dynamicRetracePrice;
   double dynamicRetracePoints;
   double dynamicRetracePips;
};

//==================================================
// Global state
//==================================================
static LegInfo g_activeLeg;
static bool    g_hasActiveLeg = false;

static LegInfo g_closedLegs[MAX_STORED_LEGS];
static int     g_closedLegsCount = 0;
static int     g_nextLegIndex = 1;

static datetime g_lastProcessedBarTime = 0;
static int      g_runtimeBarsObserved = 0;

// first runtime candle after attach
static bool     g_hasSeedBar = false;
static datetime g_seedTime = 0;
static double   g_seedHigh = 0.0;
static double   g_seedLow  = 0.0;

static datetime g_firstRuntimeBarTime = 0;

// reversal state
static int      g_oppositeCandlesCount = 0;

//==================================================
// Prefix helpers
//==================================================
string ZigZagPrefix(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return "ZZ_" + symbol + "_" + IntegerToString((int)timeframe) + "_";
}

string PanelPrefix(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return "ZZP_" + symbol + "_" + IntegerToString((int)timeframe) + "_";
}

//==================================================
// Utility
//==================================================
color GetDirectionColor(int direction)
{
   if(direction > 0) return clrBlue;
   if(direction < 0) return clrMagenta;
   return clrSilver;
}

string GetLegDirectionText(int direction)
{
   if(direction > 0) return "UP";
   if(direction < 0) return "DOWN";
   return "FLAT";
}

string TfToText(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
   }
   return IntegerToString((int)tf);
}

double GetPipSize(string symbol)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   if(digits == 3 || digits == 5)
      return _Point * 10.0;

   return _Point;
}

double PriceToPoints(double priceMove)
{
   if(_Point <= 0.0)
      return 0.0;

   return priceMove / _Point;
}

double PriceToPips(string symbol, double priceMove)
{
   double pipSize = GetPipSize(symbol);

   if(pipSize <= 0.0)
      return 0.0;

   return priceMove / pipSize;
}

int TimeframeToMinutes(ENUM_TIMEFRAMES timeframe)
{
   switch(timeframe)
   {
      case PERIOD_M1:   return 1;
      case PERIOD_M2:   return 2;
      case PERIOD_M3:   return 3;
      case PERIOD_M4:   return 4;
      case PERIOD_M5:   return 5;
      case PERIOD_M6:   return 6;
      case PERIOD_M10:  return 10;
      case PERIOD_M12:  return 12;
      case PERIOD_M15:  return 15;
      case PERIOD_M20:  return 20;
      case PERIOD_M30:  return 30;
      case PERIOD_H1:   return 60;
      case PERIOD_H2:   return 120;
      case PERIOD_H3:   return 180;
      case PERIOD_H4:   return 240;
      case PERIOD_H6:   return 360;
      case PERIOD_H8:   return 480;
      case PERIOD_H12:  return 720;
      case PERIOD_D1:   return 1440;
      case PERIOD_W1:   return 10080;
      case PERIOD_MN1:  return 43200;
   }
   return 0;
}

string ShortTime(datetime t)
{
   if(t <= 0)
      return "-";

   return TimeToString(t, TIME_DATE | TIME_MINUTES);
}

string PriceText(double price)
{
   return DoubleToString(price, _Digits);
}

//==================================================
// Candle / Leg detail helpers
//==================================================
string GetCandleDirectionText(int direction)
{
   if(direction > 0) return "BULL";
   if(direction < 0) return "BEAR";
   return "DOJI";
}

string GetRelationToLegText(int relation)
{
   if(relation > 0) return "WITH_LEG";
   if(relation < 0) return "AGAINST_LEG";
   return "NEUTRAL";
}

int GetCandleDirection(double open, double close)
{
   if(close > open) return 1;
   if(close < open) return -1;
   return 0;
}

double CalculateCandleStrength(string symbol, ENUM_TIMEFRAMES timeframe, int shift)
{
   double open  = iOpen(symbol, timeframe, shift);
   double high  = iHigh(symbol, timeframe, shift);
   double low   = iLow(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);

   double range = high - low;
   if(range <= 0.0)
      return 0.0;

   double body = MathAbs(close - open);

   double bodyRatio = body / range;

   MarketDynamics d;
   double volatilityFactor = 1.0;

   if(CalculateMarketDynamics(symbol, timeframe, d))
   {
      if(d.avgRange > 0.0)
         volatilityFactor = range / d.avgRange;
   }

   double strength = bodyRatio * volatilityFactor * 100.0;

   if(strength < 0.0)
      strength = 0.0;

   return strength;
}

string GetLegTypeText(int direction, double strength)
{
   if(direction > 0)
   {
      if(strength >= 120.0) return "STRONG_IMPULSE_UP";
      if(strength >= 80.0)  return "IMPULSE_UP";
      if(strength >= 45.0)  return "NORMAL_UP";
      return "WEAK_UP";
   }

   if(direction < 0)
   {
      if(strength >= 120.0) return "STRONG_IMPULSE_DOWN";
      if(strength >= 80.0)  return "IMPULSE_DOWN";
      if(strength >= 45.0)  return "NORMAL_DOWN";
      return "WEAK_DOWN";
   }

   return "FLAT";
}


//==================================================
// Reset / cleanup
//==================================================
void ResetZigZagState()
{
   g_hasActiveLeg = false;
   g_closedLegsCount = 0;
   g_nextLegIndex = 1;

   g_lastProcessedBarTime = 0;
   g_runtimeBarsObserved = 0;

   g_hasSeedBar = false;
   g_seedTime = 0;
   g_seedHigh = 0.0;
   g_seedLow  = 0.0;
   g_firstRuntimeBarTime = 0;

   g_oppositeCandlesCount = 0;
}

void DeleteObjectsByPrefix(string prefix)
{
   int total = ObjectsTotal(0);

   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

void ClearSimpleZigZag(string symbol, ENUM_TIMEFRAMES timeframe)
{
   DeleteObjectsByPrefix(ZigZagPrefix(symbol, timeframe));
   DeleteObjectsByPrefix(PanelPrefix(symbol, timeframe));
   ResetZigZagState();
}

void InitializeRealtimeZigZag(string symbol, ENUM_TIMEFRAMES timeframe)
{
   ResetZigZagState();
}

//==================================================
// Runtime bar helpers
//==================================================
bool IsShiftInsideRuntime(string symbol, ENUM_TIMEFRAMES timeframe, int shift)
{
   if(g_firstRuntimeBarTime == 0)
      return false;

   datetime t = iTime(symbol, timeframe, shift);
   if(t == 0)
      return false;

   return (t >= g_firstRuntimeBarTime);
}

int GetRuntimeShiftLimit(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(g_runtimeBarsObserved <= 0)
      return 0;

   int availableBars = Bars(symbol, timeframe) - 1;
   if(availableBars < 1)
      return 0;

   int limit = g_runtimeBarsObserved;
   if(limit > availableBars)
      limit = availableBars;

   return limit;
}

double GetBarTrueRange(string symbol, ENUM_TIMEFRAMES timeframe, int shift)
{
   double high = iHigh(symbol, timeframe, shift);
   double low  = iLow(symbol, timeframe, shift);
   double prevClose = iClose(symbol, timeframe, shift + 1);

   double r1 = high - low;
   double r2 = MathAbs(high - prevClose);
   double r3 = MathAbs(low - prevClose);

   return MathMax(r1, MathMax(r2, r3));
}

//==================================================
// Dynamic market model - runtime only
//==================================================
int GetDynamicLookback(string symbol, ENUM_TIMEFRAMES timeframe)
{
   int runtimeLimit = GetRuntimeShiftLimit(symbol, timeframe);
   if(runtimeLimit <= 0)
      return 0;

   int lookback = (int)MathRound(MathSqrt((double)runtimeLimit) * 2.0);

   if(lookback < 2)
      lookback = 2;

   if(lookback > runtimeLimit)
      lookback = runtimeLimit;

   return lookback;
}

bool CalculateMarketDynamics(string symbol, ENUM_TIMEFRAMES timeframe, MarketDynamics &d)
{
   int runtimeLimit = GetRuntimeShiftLimit(symbol, timeframe);
   if(runtimeLimit < 2)
      return false;

   int lookback = GetDynamicLookback(symbol, timeframe);
   if(lookback < 2)
      return false;

   double sum = 0.0;
   int count = 0;

   for(int shift = 1; shift <= lookback; shift++)
   {
      if(!IsShiftInsideRuntime(symbol, timeframe, shift))
         break;

      sum += GetBarTrueRange(symbol, timeframe, shift);
      count++;
   }

   if(count < 2)
      return false;

   double avg = sum / count;

   double variance = 0.0;
   for(int shift = 1; shift <= count; shift++)
   {
      double tr = GetBarTrueRange(symbol, timeframe, shift);
      variance += MathPow(tr - avg, 2.0);
   }

   double deviation = MathSqrt(variance / count);

   double ratio = 0.0;
   if(avg > 0.0)
      ratio = deviation / avg;

   int wing = 1 + (int)MathRound(ratio * MathSqrt((double)count));
   if(wing < 1)
      wing = 1;

   int maxWing = count / 2;
   if(maxWing < 1)
      maxWing = 1;

   if(wing > maxWing)
      wing = maxWing;

   d.runtimeBars = runtimeLimit;
   d.lookback = count;
   d.fractalWing = wing;
   d.avgRange = avg;
   d.rangeDeviation = deviation;
   d.dynamicRetracePrice  = avg + deviation;
   d.dynamicRetracePoints = PriceToPoints(d.dynamicRetracePrice);
   d.dynamicRetracePips   = PriceToPips(symbol, d.dynamicRetracePrice);

   return true;
}

void ResetLegDetails(LegInfo &leg)
{
   leg.candlesCount = 0;
   leg.lastStoredCandleTime = 0;

   leg.averageCandleRangePrice = 0.0;
   leg.averageCandleRangePips  = 0.0;

   leg.averageBodyPrice = 0.0;
   leg.averageBodyPips  = 0.0;

   leg.bullishCandles = 0;
   leg.bearishCandles = 0;
   leg.dojiCandles    = 0;

   leg.withLegCandles    = 0;
   leg.againstLegCandles = 0;
   leg.neutralCandles    = 0;

   leg.extensionCandles = 0;
   leg.oppositeCandles  = 0;

   leg.strength = 0.0;
   leg.legTypeText = "";
}


//==================================================
// Metrics
//==================================================
void UpdateLegDerivedMetrics(string symbol, ENUM_TIMEFRAMES timeframe, LegInfo &leg)
{
   leg.netMovePrice  = MathAbs(leg.endPrice - leg.startPrice);
   leg.netMovePoints = PriceToPoints(leg.netMovePrice);
   leg.netMovePips   = PriceToPips(symbol, leg.netMovePrice);

   int startShift = iBarShift(symbol, timeframe, leg.startTime, true);
   int endShift   = iBarShift(symbol, timeframe, leg.endTime, true);

   if(startShift >= 0 && endShift >= 0)
      leg.durationBars = MathAbs(startShift - endShift) + 1;
   else
      leg.durationBars = MathMax(1, leg.segmentsCount);

   leg.durationMinutes = leg.durationBars * TimeframeToMinutes(timeframe);

   // ==============================
   // Detailed candle statistics
   // ==============================
   double sumRange = 0.0;
   double sumBody  = 0.0;
   double sumStrength = 0.0;

   leg.bullishCandles = 0;
   leg.bearishCandles = 0;
   leg.dojiCandles    = 0;

   leg.withLegCandles    = 0;
   leg.againstLegCandles = 0;
   leg.neutralCandles    = 0;

   leg.extensionCandles = 0;
   leg.oppositeCandles  = 0;

   for(int i = 0; i < leg.candlesCount; i++)
   {
      sumRange += leg.candles[i].rangePrice;
      sumBody  += leg.candles[i].bodyPrice;
      sumStrength += leg.candles[i].strength;

      if(leg.candles[i].candleDirection > 0)
         leg.bullishCandles++;
      else if(leg.candles[i].candleDirection < 0)
         leg.bearishCandles++;
      else
         leg.dojiCandles++;

      if(leg.candles[i].relationToLeg > 0)
         leg.withLegCandles++;
      else if(leg.candles[i].relationToLeg < 0)
         leg.againstLegCandles++;
      else
         leg.neutralCandles++;

      if(leg.candles[i].isExtensionCandle)
         leg.extensionCandles++;

      if(leg.candles[i].isOppositeCandle)
         leg.oppositeCandles++;
   }

   if(leg.candlesCount > 0)
   {
      leg.averageCandleRangePrice = sumRange / leg.candlesCount;
      leg.averageCandleRangePips  = PriceToPips(symbol, leg.averageCandleRangePrice);

      leg.averageBodyPrice = sumBody / leg.candlesCount;
      leg.averageBodyPips  = PriceToPips(symbol, leg.averageBodyPrice);

      double avgCandleStrength = sumStrength / leg.candlesCount;

      double efficiency = 0.0;
      if(leg.totalMovePrice > 0.0)
         efficiency = leg.netMovePrice / leg.totalMovePrice;

      double withLegRatio = 0.0;
      if(leg.candlesCount > 0)
         withLegRatio = (double)leg.withLegCandles / (double)leg.candlesCount;

      double extensionRatio = 0.0;
      if(leg.candlesCount > 0)
         extensionRatio = (double)leg.extensionCandles / (double)leg.candlesCount;

      leg.strength =
         avgCandleStrength * 0.40 +
         efficiency * 100.0 * 0.30 +
         withLegRatio * 100.0 * 0.20 +
         extensionRatio * 100.0 * 0.10;

      leg.legTypeText = GetLegTypeText(leg.direction, leg.strength);
   }
   else
   {
      leg.averageCandleRangePrice = 0.0;
      leg.averageCandleRangePips  = 0.0;
      leg.averageBodyPrice        = 0.0;
      leg.averageBodyPips         = 0.0;
      leg.strength                = 0.0;
      leg.legTypeText             = GetLegTypeText(leg.direction, 0.0);
   }
}

bool AddCandleToLegDetails(string symbol, ENUM_TIMEFRAMES timeframe, LegInfo &leg, int shift)
{
   if(shift < 0)
      return false;

   datetime candleTime = iTime(symbol, timeframe, shift);
   if(candleTime == 0)
      return false;

   if(leg.lastStoredCandleTime == candleTime)
      return false;

   if(leg.candlesCount >= MAX_CANDLES_PER_LEG)
      return false;

   double open  = iOpen(symbol, timeframe, shift);
   double high  = iHigh(symbol, timeframe, shift);
   double low   = iLow(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);

   double range = high - low;
   double body  = MathAbs(close - open);

   int candleDir = GetCandleDirection(open, close);

   int relation = 0;
   if(candleDir == leg.direction)
      relation = 1;
   else if(candleDir == -leg.direction)
      relation = -1;

   bool isExtension = false;

   if(leg.direction > 0)
   {
      if(high >= leg.endPrice)
         isExtension = true;
   }
   else if(leg.direction < 0)
   {
      if(low <= leg.endPrice)
         isExtension = true;
   }

   bool isOpposite = IsOppositeCandle(symbol, timeframe, leg.direction, shift);

   int i = leg.candlesCount;

   leg.candles[i].indexInLeg = i + 1;
   leg.candles[i].time = candleTime;

   leg.candles[i].open  = open;
   leg.candles[i].high  = high;
   leg.candles[i].low   = low;
   leg.candles[i].close = close;

   leg.candles[i].bodyPrice  = body;
   leg.candles[i].bodyPoints = PriceToPoints(body);
   leg.candles[i].bodyPips   = PriceToPips(symbol, body);

   leg.candles[i].rangePrice  = range;
   leg.candles[i].rangePoints = PriceToPoints(range);
   leg.candles[i].rangePips   = PriceToPips(symbol, range);

   leg.candles[i].upperWickPrice = high - MathMax(open, close);
   leg.candles[i].lowerWickPrice = MathMin(open, close) - low;

   leg.candles[i].candleDirection = candleDir;
   leg.candles[i].relationToLeg = relation;

   leg.candles[i].isExtensionCandle = isExtension;
   leg.candles[i].isOppositeCandle  = isOpposite;

   leg.candles[i].strength = CalculateCandleStrength(symbol, timeframe, shift);

   leg.candles[i].typeText = GetCandleDirectionText(candleDir);
   leg.candles[i].relationText = GetRelationToLegText(relation);

   leg.candlesCount++;
   leg.lastStoredCandleTime = candleTime;

   UpdateLegDerivedMetrics(symbol, timeframe, leg);

   return true;
}



void StoreClosedLeg(const LegInfo &leg)
{
   if(g_closedLegsCount < MAX_STORED_LEGS)
   {
      g_closedLegs[g_closedLegsCount] = leg;
      g_closedLegsCount++;
      return;
   }

   for(int i = 1; i < MAX_STORED_LEGS; i++)
      g_closedLegs[i - 1] = g_closedLegs[i];

   g_closedLegs[MAX_STORED_LEGS - 1] = leg;
}

//==================================================
// Accessors
//==================================================
int GetClosedLegsCount()
{
   return g_closedLegsCount;
}

bool GetClosedLegByIndex(int index, LegInfo &leg)
{
   if(index < 0 || index >= g_closedLegsCount)
      return false;

   leg = g_closedLegs[index];
   return true;
}

bool GetLastClosedLeg(LegInfo &leg)
{
   if(g_closedLegsCount <= 0)
      return false;

   leg = g_closedLegs[g_closedLegsCount - 1];
   return true;
}

bool HasActiveLeg()
{
   return g_hasActiveLeg;
}

bool GetActiveLeg(LegInfo &leg)
{
   if(!g_hasActiveLeg)
      return false;

   leg = g_activeLeg;
   return true;
}

//==================================================
// Detailed completed legs accessors
//==================================================
int GetLastCompletedLegsCount(int requestedCount = LAST_COMPLETED_LEGS)
{
   if(requestedCount <= 0)
      return 0;

   if(g_closedLegsCount <= 0)
      return 0;

   if(requestedCount > g_closedLegsCount)
      return g_closedLegsCount;

   return requestedCount;
}

bool GetLastCompletedLegByOffset(int offsetFromLast, LegInfo &leg)
{
   // offsetFromLast = 0 means last closed leg
   // offsetFromLast = 1 means one before last

   if(offsetFromLast < 0)
      return false;

   if(offsetFromLast >= g_closedLegsCount)
      return false;

   int index = g_closedLegsCount - 1 - offsetFromLast;

   if(index < 0 || index >= g_closedLegsCount)
      return false;

   leg = g_closedLegs[index];
   return true;
}

int GetLastCompletedLegs(LegInfo &legs[], int requestedCount = LAST_COMPLETED_LEGS)
{
   int count = GetLastCompletedLegsCount(requestedCount);

   ArrayResize(legs, count);

   for(int i = 0; i < count; i++)
   {
      int sourceIndex = g_closedLegsCount - count + i;
      legs[i] = g_closedLegs[sourceIndex];
   }

   return count;
}

int GetLastCompletedLegsNewestFirst(LegInfo &legs[], int requestedCount = LAST_COMPLETED_LEGS)
{
   int count = GetLastCompletedLegsCount(requestedCount);

   ArrayResize(legs, count);

   for(int i = 0; i < count; i++)
   {
      int sourceIndex = g_closedLegsCount - 1 - i;
      legs[i] = g_closedLegs[sourceIndex];
   }

   return count;
}

int GetLegCandlesCount(const LegInfo &leg)
{
   return leg.candlesCount;
}

bool GetLegCandleByIndex(const LegInfo &leg, int candleIndex, LegCandleInfo &candle)
{
   if(candleIndex < 0 || candleIndex >= leg.candlesCount)
      return false;

   candle = leg.candles[candleIndex];
   return true;
}

bool GetLastClosedLegCandleByIndex(int legOffsetFromLast, int candleIndex, LegCandleInfo &candle)
{
   LegInfo leg;

   if(!GetLastCompletedLegByOffset(legOffsetFromLast, leg))
      return false;

   return GetLegCandleByIndex(leg, candleIndex, candle);
}


//==================================================
// Drawing
//==================================================
bool CreateTrendObject(string name, datetime time1, double price1, datetime time2, double price2, color lineColor, int width = 2)
{
   if(ObjectFind(0, name) != -1)
      ObjectDelete(0, name);

   if(!ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2))
      return false;

   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

bool DrawClosedLegLine(string symbol, ENUM_TIMEFRAMES timeframe, const LegInfo &leg)
{
   string name = ZigZagPrefix(symbol, timeframe) + "LEG_" + IntegerToString(leg.index);

   return CreateTrendObject(
      name,
      leg.startTime,
      leg.startPrice,
      leg.endTime,
      leg.endPrice,
      GetDirectionColor(leg.direction),
      10
   );
}

//==================================================
// Leg management
//==================================================
void StartNewLegFromSeedToCurrent(string symbol, ENUM_TIMEFRAMES timeframe, int direction)
{
   datetime currTime = iTime(symbol, timeframe, 1);
   double currHigh   = iHigh(symbol, timeframe, 1);
   double currLow    = iLow(symbol, timeframe, 1);

   g_activeLeg.index = g_nextLegIndex++;
   g_activeLeg.direction = direction;
   g_activeLeg.startTime = g_seedTime;
   g_activeLeg.endTime   = currTime;

   if(direction > 0)
   {
      g_activeLeg.startPrice = g_seedHigh;
      g_activeLeg.endPrice   = currHigh;
   }
   else
   {
      g_activeLeg.startPrice = g_seedLow;
      g_activeLeg.endPrice   = currLow;
   }

   g_activeLeg.legHigh = MathMax(g_seedHigh, currHigh);
   g_activeLeg.legLow  = MathMin(g_seedLow, currLow);

   g_activeLeg.segmentsCount   = 1;
   g_activeLeg.totalMovePrice  = MathAbs(g_activeLeg.endPrice - g_activeLeg.startPrice);
   g_activeLeg.totalMovePoints = PriceToPoints(g_activeLeg.totalMovePrice);
   g_activeLeg.totalMovePips   = PriceToPips(symbol, g_activeLeg.totalMovePrice);
   g_activeLeg.isClosed = false;

   ResetLegDetails(g_activeLeg);

   AddCandleToLegDetails(symbol, timeframe, g_activeLeg, 2);
   AddCandleToLegDetails(symbol, timeframe, g_activeLeg, 1);

   UpdateLegDerivedMetrics(symbol, timeframe, g_activeLeg);

   g_hasActiveLeg = true;
   g_oppositeCandlesCount = 0;
}


void StartNewLegFromPreviousEnd(string symbol, ENUM_TIMEFRAMES timeframe, int direction, datetime startTime, double startPrice)
{
   datetime currTime = iTime(symbol, timeframe, 1);
   double currHigh   = iHigh(symbol, timeframe, 1);
   double currLow    = iLow(symbol, timeframe, 1);

   g_activeLeg.index = g_nextLegIndex++;
   g_activeLeg.direction = direction;
   g_activeLeg.startTime = startTime;
   g_activeLeg.endTime   = currTime;
   g_activeLeg.startPrice = startPrice;

   if(direction > 0)
      g_activeLeg.endPrice = currHigh;
   else
      g_activeLeg.endPrice = currLow;

   g_activeLeg.legHigh = MathMax(startPrice, currHigh);
   g_activeLeg.legLow  = MathMin(startPrice, currLow);

   g_activeLeg.segmentsCount   = 1;
   g_activeLeg.totalMovePrice  = MathAbs(g_activeLeg.endPrice - g_activeLeg.startPrice);
   g_activeLeg.totalMovePoints = PriceToPoints(g_activeLeg.totalMovePrice);
   g_activeLeg.totalMovePips   = PriceToPips(symbol, g_activeLeg.totalMovePrice);
   g_activeLeg.isClosed = false;

   ResetLegDetails(g_activeLeg);

   AddCandleToLegDetails(symbol, timeframe, g_activeLeg, 1);

   UpdateLegDerivedMetrics(symbol, timeframe, g_activeLeg);

   g_hasActiveLeg = true;
   g_oppositeCandlesCount = 0;
}


void ExtendActiveLegIfNeeded(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(!g_hasActiveLeg)
      return;

   datetime currTime = iTime(symbol, timeframe, 1);
   double currHigh   = iHigh(symbol, timeframe, 1);
   double currLow    = iLow(symbol, timeframe, 1);

   bool extended = false;

   if(g_activeLeg.direction > 0)
   {
      if(currHigh > g_activeLeg.endPrice)
      {
         double delta = currHigh - g_activeLeg.endPrice;
         g_activeLeg.endPrice = currHigh;
         g_activeLeg.endTime  = currTime;
         g_activeLeg.totalMovePrice  += delta;
         g_activeLeg.totalMovePoints += PriceToPoints(delta);
         g_activeLeg.totalMovePips   += PriceToPips(symbol, delta);
         g_activeLeg.segmentsCount++;
         extended = true;
      }
   }
   else if(g_activeLeg.direction < 0)
   {
      if(currLow < g_activeLeg.endPrice)
      {
         double delta = g_activeLeg.endPrice - currLow;
         g_activeLeg.endPrice = currLow;
         g_activeLeg.endTime  = currTime;
         g_activeLeg.totalMovePrice  += delta;
         g_activeLeg.totalMovePoints += PriceToPoints(delta);
         g_activeLeg.totalMovePips   += PriceToPips(symbol, delta);
         g_activeLeg.segmentsCount++;
         extended = true;
      }
   }

   if(currHigh > g_activeLeg.legHigh)
      g_activeLeg.legHigh = currHigh;

   if(currLow < g_activeLeg.legLow)
      g_activeLeg.legLow = currLow;

   UpdateLegDerivedMetrics(symbol, timeframe, g_activeLeg);

   if(extended)
      g_oppositeCandlesCount = 0;
}

void FinalizeActiveLeg(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(!g_hasActiveLeg)
      return;

   UpdateLegDerivedMetrics(symbol, timeframe, g_activeLeg);
   g_activeLeg.isClosed = true;

   DrawClosedLegLine(symbol, timeframe, g_activeLeg);
   StoreClosedLeg(g_activeLeg);

   g_hasActiveLeg = false;
   g_oppositeCandlesCount = 0;
}

//==================================================
// Reversal logic
//==================================================
bool IsOppositeCandle(string symbol, ENUM_TIMEFRAMES timeframe, int activeDirection, int shift)
{
   double open  = iOpen(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);
   double high  = iHigh(symbol, timeframe, shift);
   double low   = iLow(symbol, timeframe, shift);

   double prevHigh = iHigh(symbol, timeframe, shift + 1);
   double prevLow  = iLow(symbol, timeframe, shift + 1);

   if(activeDirection > 0)
      return (close < open) || (low < prevLow);

   if(activeDirection < 0)
      return (close > open) || (high > prevHigh);

   return false;
}

void UpdateOppositeCandleCounter(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(!g_hasActiveLeg)
   {
      g_oppositeCandlesCount = 0;
      return;
   }

   bool favorable = false;

   if(g_activeLeg.direction > 0)
      favorable = (iHigh(symbol, timeframe, 1) > g_activeLeg.endPrice);
   else if(g_activeLeg.direction < 0)
      favorable = (iLow(symbol, timeframe, 1) < g_activeLeg.endPrice);

   if(favorable)
   {
      g_oppositeCandlesCount = 0;
      return;
   }

   if(IsOppositeCandle(symbol, timeframe, g_activeLeg.direction, 1))
      g_oppositeCandlesCount++;
   else
      g_oppositeCandlesCount = 0;
}

bool HasThreeOppositeCandlesConfirmed()
{
   return (g_oppositeCandlesCount >= 3);
}

bool IsLegEndPivotFractal(string symbol, ENUM_TIMEFRAMES timeframe, int direction, int wing)
{
   if(!g_hasActiveLeg)
      return false;

   int pivotShift = iBarShift(symbol, timeframe, g_activeLeg.endTime, true);
   if(pivotShift < 0)
      return false;

   if(pivotShift <= 0)
      return false;

   if(!IsShiftInsideRuntime(symbol, timeframe, pivotShift))
      return false;

   int barsToRight = pivotShift - 1;
   int runtimeLimit = GetRuntimeShiftLimit(symbol, timeframe);
   int barsToLeftWithinRuntime = runtimeLimit - pivotShift;

   int usableWing = wing;
   if(usableWing > barsToRight)
      usableWing = barsToRight;
   if(usableWing > barsToLeftWithinRuntime)
      usableWing = barsToLeftWithinRuntime;

   if(usableWing < 1)
      return false;

   double pivotHigh = iHigh(symbol, timeframe, pivotShift);
   double pivotLow  = iLow(symbol, timeframe, pivotShift);

   for(int i = pivotShift - usableWing; i <= pivotShift + usableWing; i++)
   {
      if(i == pivotShift)
         continue;

      if(!IsShiftInsideRuntime(symbol, timeframe, i))
         return false;

      if(direction < 0)
      {
         if(iHigh(symbol, timeframe, i) >= pivotHigh)
            return false;
      }
      else if(direction > 0)
      {
         if(iLow(symbol, timeframe, i) <= pivotLow)
            return false;
      }
   }

   return true;
}

bool HasDynamicRetraceConfirmed(string symbol, ENUM_TIMEFRAMES timeframe, int reversalDirection, const MarketDynamics &dynamics)
{
   if(!g_hasActiveLeg)
      return false;

   double currHigh = iHigh(symbol, timeframe, 1);
   double currLow  = iLow(symbol, timeframe, 1);

   if(reversalDirection < 0)
      return (g_activeLeg.endPrice - currLow) >= dynamics.dynamicRetracePrice;

   if(reversalDirection > 0)
      return (currHigh - g_activeLeg.endPrice) >= dynamics.dynamicRetracePrice;

   return false;
}

bool IsReversalConfirmed(string symbol, ENUM_TIMEFRAMES timeframe, int reversalDirection, const MarketDynamics &dynamics)
{
   if(!HasThreeOppositeCandlesConfirmed())
      return false;

   bool fractalConfirmed = IsLegEndPivotFractal(symbol, timeframe, reversalDirection, dynamics.fractalWing);
   bool retraceConfirmed = HasDynamicRetraceConfirmed(symbol, timeframe, reversalDirection, dynamics);

   return (fractalConfirmed || retraceConfirmed);
}

//==================================================
// Initial runtime start
//==================================================
void CaptureSeedBar(string symbol, ENUM_TIMEFRAMES timeframe)
{
   g_seedTime = iTime(symbol, timeframe, 1);
   g_seedHigh = iHigh(symbol, timeframe, 1);
   g_seedLow  = iLow(symbol, timeframe, 1);
   g_hasSeedBar = (g_seedTime != 0);

   if(g_firstRuntimeBarTime == 0)
      g_firstRuntimeBarTime = g_seedTime;
}

bool TryStartInitialLeg(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(!g_hasSeedBar)
      return false;

   datetime currTime = iTime(symbol, timeframe, 1);
   if(currTime == 0 || currTime == g_seedTime)
      return false;

   double currHigh = iHigh(symbol, timeframe, 1);
   double currLow  = iLow(symbol, timeframe, 1);

   double upMove   = currHigh - g_seedHigh;
   double downMove = g_seedLow - currLow;

   if(upMove <= 0.0 && downMove <= 0.0)
      return false;

   if(upMove > downMove)
   {
      StartNewLegFromSeedToCurrent(symbol, timeframe, 1);
      return true;
   }

   if(downMove > upMove)
   {
      StartNewLegFromSeedToCurrent(symbol, timeframe, -1);
      return true;
   }

   double currOpen  = iOpen(symbol, timeframe, 1);
   double currClose = iClose(symbol, timeframe, 1);

   if(currClose >= currOpen)
      StartNewLegFromSeedToCurrent(symbol, timeframe, 1);
   else
      StartNewLegFromSeedToCurrent(symbol, timeframe, -1);

   return true;
}

//==================================================
// Main realtime processing
//==================================================
bool AddLatestZigZagSegment(string symbol, ENUM_TIMEFRAMES timeframe)
{
   datetime barTime = iTime(symbol, timeframe, 1);
   if(barTime == 0)
      return false;

   if(g_lastProcessedBarTime == barTime)
      return false;

   g_lastProcessedBarTime = barTime;
   g_runtimeBarsObserved++;

   // first runtime bar after attach => just seed, no drawing
   if(!g_hasSeedBar)
   {
      CaptureSeedBar(symbol, timeframe);
      UpdateZigZagPanel(symbol, timeframe);
      return false;
   }

   // until first real leg starts
   if(!g_hasActiveLeg)
   {
      bool started = TryStartInitialLeg(symbol, timeframe);
      UpdateZigZagPanel(symbol, timeframe);
      return started;
   }
   
   
   AddCandleToLegDetails(symbol, timeframe, g_activeLeg, 1);


   // active leg exists: extend if favorable
   ExtendActiveLegIfNeeded(symbol, timeframe);

   // after extension maybe still no reversal
   UpdateOppositeCandleCounter(symbol, timeframe);

   MarketDynamics dynamics;
   bool hasDynamics = CalculateMarketDynamics(symbol, timeframe, dynamics);

   if(hasDynamics)
   {
      if(g_activeLeg.direction > 0)
      {
         if(IsReversalConfirmed(symbol, timeframe, -1, dynamics))
         {
            datetime newStartTime = g_activeLeg.endTime;
            double   newStartPrice = g_activeLeg.endPrice;

            FinalizeActiveLeg(symbol, timeframe);
            StartNewLegFromPreviousEnd(symbol, timeframe, -1, newStartTime, newStartPrice);

            UpdateZigZagPanel(symbol, timeframe);
            return true;
         }
      }
      else if(g_activeLeg.direction < 0)
      {
         if(IsReversalConfirmed(symbol, timeframe, 1, dynamics))
         {
            datetime newStartTime = g_activeLeg.endTime;
            double   newStartPrice = g_activeLeg.endPrice;

            FinalizeActiveLeg(symbol, timeframe);
            StartNewLegFromPreviousEnd(symbol, timeframe, 1, newStartTime, newStartPrice);

            UpdateZigZagPanel(symbol, timeframe);
            return true;
         }
      }
   }

   UpdateZigZagPanel(symbol, timeframe);
   return false;
}

//==================================================
// Panel helpers
//==================================================
string PanelLineName(string symbol, ENUM_TIMEFRAMES timeframe, int index)
{
   return PanelPrefix(symbol, timeframe) + "LINE_" + IntegerToString(index);
}

string PanelBgName(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return PanelPrefix(symbol, timeframe) + "BG";
}

bool CreatePanelBackground(string symbol, ENUM_TIMEFRAMES timeframe)
{
   string name = PanelBgName(symbol, timeframe);

   if(ObjectFind(0, name) == -1)
   {
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 8);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 18);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, 360);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 430);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

bool CreatePanelLineObject(string symbol, ENUM_TIMEFRAMES timeframe, int index)
{
   string name = PanelLineName(symbol, timeframe, index);

   if(ObjectFind(0, name) == -1)
   {
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 350);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 28 + index * 16);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

void SetPanelLine(string symbol, ENUM_TIMEFRAMES timeframe, int index, string text, color clr)
{
   string name = PanelLineName(symbol, timeframe, index);

   if(ObjectFind(0, name) == -1)
      CreatePanelLineObject(symbol, timeframe, index);

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

void ClearPanelLines(string symbol, ENUM_TIMEFRAMES timeframe)
{
   for(int i = 0; i < PANEL_LINES; i++)
      SetPanelLine(symbol, timeframe, i, "", clrWhite);
}

void InitZigZagPanel(string symbol, ENUM_TIMEFRAMES timeframe)
{
   CreatePanelBackground(symbol, timeframe);

   for(int i = 0; i < PANEL_LINES; i++)
      CreatePanelLineObject(symbol, timeframe, i);

   UpdateZigZagPanel(symbol, timeframe);
}

void UpdateZigZagPanel(string symbol, ENUM_TIMEFRAMES timeframe)
{
   CreatePanelBackground(symbol, timeframe);
   ClearPanelLines(symbol, timeframe);

   MarketDynamics dynamics;
   bool hasDynamics = CalculateMarketDynamics(symbol, timeframe, dynamics);

   int line = 0;

   SetPanelLine(symbol, timeframe, line++, "ZIGZAG REALTIME PANEL", clrAqua);
   SetPanelLine(symbol, timeframe, line++, "------------------------------", clrDimGray);
   SetPanelLine(symbol, timeframe, line++, "Symbol      : " + symbol, clrWhite);
   SetPanelLine(symbol, timeframe, line++, "Timeframe   : " + TfToText(timeframe), clrWhite);
   SetPanelLine(symbol, timeframe, line++, "RuntimeBars : " + IntegerToString(g_runtimeBarsObserved), clrWhite);
   SetPanelLine(symbol, timeframe, line++, "FirstBar    : " + ShortTime(g_firstRuntimeBarTime), clrWhite);
   SetPanelLine(symbol, timeframe, line++, "ClosedLegs  : " + IntegerToString(g_closedLegsCount), clrWhite);
   SetPanelLine(symbol, timeframe, line++, "OppCandles  : " + IntegerToString(g_oppositeCandlesCount) + " / 3", clrYellow);

   if(hasDynamics)
   {
      SetPanelLine(symbol, timeframe, line++, "Lookback    : " + IntegerToString(dynamics.lookback), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "FractalWing : " + IntegerToString(dynamics.fractalWing), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "AvgRange    : " + DoubleToString(dynamics.avgRange, _Digits), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "Deviation   : " + DoubleToString(dynamics.rangeDeviation, _Digits), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "RetracePx   : " + DoubleToString(dynamics.dynamicRetracePrice, _Digits), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "RetracePips : " + DoubleToString(dynamics.dynamicRetracePips, 1), clrWhite);
   }
   else
   {
      SetPanelLine(symbol, timeframe, line++, "Lookback    : waiting...", clrSilver);
      SetPanelLine(symbol, timeframe, line++, "FractalWing : waiting...", clrSilver);
      SetPanelLine(symbol, timeframe, line++, "AvgRange    : waiting...", clrSilver);
      SetPanelLine(symbol, timeframe, line++, "Deviation   : waiting...", clrSilver);
      SetPanelLine(symbol, timeframe, line++, "RetracePx   : waiting...", clrSilver);
      SetPanelLine(symbol, timeframe, line++, "RetracePips : waiting...", clrSilver);
   }

   SetPanelLine(symbol, timeframe, line++, "------------------------------", clrDimGray);

   if(g_hasActiveLeg)
   {
      color dirClr = GetDirectionColor(g_activeLeg.direction);

      SetPanelLine(symbol, timeframe, line++, "ACTIVE LEG  : #" + IntegerToString(g_activeLeg.index) + " " + GetLegDirectionText(g_activeLeg.direction), dirClr);
      SetPanelLine(symbol, timeframe, line++, "Start       : " + ShortTime(g_activeLeg.startTime) + " @ " + PriceText(g_activeLeg.startPrice), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "End         : " + ShortTime(g_activeLeg.endTime) + " @ " + PriceText(g_activeLeg.endPrice), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "Net / Total : " + DoubleToString(g_activeLeg.netMovePips, 1) + " / " + DoubleToString(g_activeLeg.totalMovePips, 1) + " pips", clrWhite);
      SetPanelLine(symbol, timeframe, line++, "Bars / Min  : " + IntegerToString(g_activeLeg.durationBars) + " / " + IntegerToString(g_activeLeg.durationMinutes), clrWhite);
      SetPanelLine(symbol, timeframe, line++, "Leg H / L   : " + PriceText(g_activeLeg.legHigh) + " / " + PriceText(g_activeLeg.legLow), clrWhite);
   }
   else
   {
      SetPanelLine(symbol, timeframe, line++, "ACTIVE LEG  : none", clrSilver);
      if(g_hasSeedBar)
         SetPanelLine(symbol, timeframe, line++, "Seed        : " + ShortTime(g_seedTime) + " H=" + PriceText(g_seedHigh) + " L=" + PriceText(g_seedLow), clrSilver);
      else
         SetPanelLine(symbol, timeframe, line++, "Seed        : waiting first runtime candle", clrSilver);
   }

   SetPanelLine(symbol, timeframe, line++, "------------------------------", clrDimGray);

   LegInfo lastClosed;
   if(GetLastClosedLeg(lastClosed))
   {
      color dirClr2 = GetDirectionColor(lastClosed.direction);
      SetPanelLine(symbol, timeframe, line++, "LAST CLOSED : #" + IntegerToString(lastClosed.index) + " " + GetLegDirectionText(lastClosed.direction), dirClr2);
      SetPanelLine(symbol, timeframe, line++, "Closed Net  : " + DoubleToString(lastClosed.netMovePips, 1) + " pips", clrWhite);
      SetPanelLine(symbol, timeframe, line++, "Closed Bars : " + IntegerToString(lastClosed.durationBars), clrWhite);
   }
   else
   {
      SetPanelLine(symbol, timeframe, line++, "LAST CLOSED : none", clrSilver);
   }

   for(int i = 0; i < 3; i++)
   {
      int idx = g_closedLegsCount - 1 - i;
      if(idx < 0)
         break;

      LegInfo leg = g_closedLegs[idx];
      string txt =
         "#" + IntegerToString(leg.index) +
         " " + GetLegDirectionText(leg.direction) +
         "  net=" + DoubleToString(leg.netMovePips, 1) +
         "  bars=" + IntegerToString(leg.durationBars);

      SetPanelLine(symbol, timeframe, line++, txt, GetDirectionColor(leg.direction));
   }

   ChartRedraw(0);
}

//==================================================
// Optional history print
//==================================================
void PrintLegSummary(const LegInfo &leg)
{
   Print(
      "Leg #", leg.index,
      " | ", GetLegDirectionText(leg.direction),
      " | Type=", leg.legTypeText,
      " | Strength=", DoubleToString(leg.strength, 2),
      " | Net=", DoubleToString(leg.netMovePips, 1), " pips",
      " | Total=", DoubleToString(leg.totalMovePips, 1), " pips",
      " | Bars=", leg.durationBars,
      " | Minutes=", leg.durationMinutes,
      " | Candles=", leg.candlesCount,
      " | WithLeg=", leg.withLegCandles,
      " | Against=", leg.againstLegCandles,
      " | Extensions=", leg.extensionCandles,
      " | Opposite=", leg.oppositeCandles,
      " | AvgRange=", DoubleToString(leg.averageCandleRangePips, 1), " pips",
      " | AvgBody=", DoubleToString(leg.averageBodyPips, 1), " pips",
      " | High=", DoubleToString(leg.legHigh, _Digits),
      " | Low=", DoubleToString(leg.legLow, _Digits),
      " | Start=", TimeToString(leg.startTime, TIME_DATE | TIME_MINUTES),
      " | End=", TimeToString(leg.endTime, TIME_DATE | TIME_MINUTES)
   );
}

void PrintLegCandles(const LegInfo &leg)
{
   Print("========== LEG #", leg.index, " CANDLES ==========");

   for(int i = 0; i < leg.candlesCount; i++)
   {
      LegCandleInfo c = leg.candles[i];

      Print(
         "#", c.indexInLeg,
         " | Time=", TimeToString(c.time, TIME_DATE | TIME_MINUTES),
         " | Type=", c.typeText,
         " | Relation=", c.relationText,
         " | Strength=", DoubleToString(c.strength, 2),
         " | O=", DoubleToString(c.open, _Digits),
         " | H=", DoubleToString(c.high, _Digits),
         " | L=", DoubleToString(c.low, _Digits),
         " | C=", DoubleToString(c.close, _Digits),
         " | Body=", DoubleToString(c.bodyPips, 1), " pips",
         " | Range=", DoubleToString(c.rangePips, 1), " pips",
         " | Extension=", c.isExtensionCandle,
         " | Opposite=", c.isOppositeCandle
      );
   }

   Print("========================================");
}

void PrintLastCompletedLegsDetailed(int count = LAST_COMPLETED_LEGS)
{
   LegInfo legs[];
   int n = GetLastCompletedLegsNewestFirst(legs, count);

   Print("========== LAST COMPLETED LEGS DETAILED ==========");
   Print("Count = ", n);

   for(int i = 0; i < n; i++)
   {
      PrintLegSummary(legs[i]);
      PrintLegCandles(legs[i]);
   }

   Print("==================================================");
}


void PrintLegHistory()
{
   Print("========== CLOSED LEGS HISTORY ==========");
   Print("Count = ", g_closedLegsCount);

   for(int i = 0; i < g_closedLegsCount; i++)
      PrintLegSummary(g_closedLegs[i]);

   Print("========================================");
}

#endif
