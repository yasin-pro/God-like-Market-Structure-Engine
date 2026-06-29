#ifndef __STRATEGY_SIGNALS_MQH__
#define __STRATEGY_SIGNALS_MQH__

#include "ZigZag.mqh"
#include "SignalTypes.mqh"
#include "SignalBus.mqh"

#define STRATEGY_MA_PERIOD 50
#define STRATEGY_WAVE2_MAX_RATIO 0.70
#define STRATEGY_WAVE3_MIN_RATIO 1.00

#define MAX_REJECTION_CANDLES 3

static bool g_waitRejection = false;
static int  g_rejectCandleCount = 0;


// ورود روی 60 درصد اصلاح موج 3
#define STRATEGY_ENTRY_FIB_TARGET 0.60

// زون بصری اطراف سطح 60 درصد
#define STRATEGY_ENTRY_FIB_LOW  0.55
#define STRATEGY_ENTRY_FIB_HIGH 0.65

static int g_maHandle = INVALID_HANDLE;
static int g_lastProcessedLegIndex = -1;

static bool g_activeThreeWaveSetup = false;
static int  g_activeSetupDirection = SIGNAL_NONE;
static int  g_activeSetupLeg3Index = -1;
static bool g_signalTriggered = false;

static datetime g_leg3EndTime = 0;

// سطوح ورود بر اساس موج 3
static double g_entryTargetPrice = 0.0;
static double g_entryZoneTop = 0.0;
static double g_entryZoneBottom = 0.0;

static string g_maObjectPrefix = "STRATEGY_MA50_H1_";
static string g_entryZoneName  = "STRATEGY_ENTRY_ZONE";
static string g_entryMidName   = "STRATEGY_ENTRY_MID";

static int g_maDrawBars = 200;

//------------------------------------------------
// Helpers
//------------------------------------------------

double PriceDistance(const LegInfo &leg)
{
   return MathAbs(leg.endPrice - leg.startPrice);
}

bool EnsureStrategyMA(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(g_maHandle == INVALID_HANDLE)
   {
      g_maHandle = iMA(symbol, timeframe, STRATEGY_MA_PERIOD, 0, MODE_SMA, PRICE_CLOSE);

      if(g_maHandle == INVALID_HANDLE)
      {
         Print("MA creation failed: ", GetLastError());
         return false;
      }
   }

   return true;
}

void ClearStrategyMA()
{
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);

      if(StringFind(name, g_maObjectPrefix) == 0)
         ObjectDelete(0, name);
   }
}

bool DrawStrategyMAGold(string symbol, ENUM_TIMEFRAMES timeframe)
{
   if(!EnsureStrategyMA(symbol, timeframe))
      return false;

   int bars = Bars(symbol, timeframe);
   if(bars <= STRATEGY_MA_PERIOD + 5)
      return false;

   int count = MathMin(g_maDrawBars, bars - STRATEGY_MA_PERIOD - 1);
   if(count < 2)
      return false;

   double ma[];
   datetime times[];

   ArraySetAsSeries(ma, true);
   ArraySetAsSeries(times, true);

   if(CopyBuffer(g_maHandle, 0, 0, count, ma) <= 0)
   {
      Print("MA CopyBuffer failed: ", GetLastError());
      return false;
   }

   if(CopyTime(symbol, timeframe, 0, count, times) <= 0)
   {
      Print("MA CopyTime failed: ", GetLastError());
      return false;
   }

   ClearStrategyMA();

   for(int i = count - 2; i >= 0; i--)
   {
      if(ma[i] == EMPTY_VALUE || ma[i + 1] == EMPTY_VALUE)
         continue;

      string name = g_maObjectPrefix + IntegerToString(i);

      if(!ObjectCreate(0, name, OBJ_TREND, 0, times[i + 1], ma[i + 1], times[i], ma[i]))
         continue;

      ObjectSetInteger(0, name, OBJPROP_COLOR, clrGold);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 5);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }

   ChartRedraw(0);
   return true;
}

bool GetMAValueAtTime(string symbol, ENUM_TIMEFRAMES timeframe, datetime t, double &ma)
{
   if(!EnsureStrategyMA(symbol, timeframe))
      return false;

   int shift = iBarShift(symbol, timeframe, t, false);
   if(shift < 0)
      return false;

   double buf[];
   ArraySetAsSeries(buf, true);

   if(CopyBuffer(g_maHandle, 0, shift, 1, buf) <= 0)
      return false;

   ma = buf[0];
   return true;
}

//------------------------------------------------
// Wave / MA Validation
//------------------------------------------------

// موج 1 باید MA را در جهت خودش بشکند
bool LegBreaksMAInDirection(string symbol, ENUM_TIMEFRAMES timeframe, const LegInfo &leg)
{
   double maStart, maEnd;

   if(!GetMAValueAtTime(symbol, timeframe, leg.startTime, maStart))
      return false;
   if(!GetMAValueAtTime(symbol, timeframe, leg.endTime, maEnd))
      return false;

   if(leg.direction > 0)
      return (leg.startPrice <= maStart && leg.endPrice > maEnd);

   if(leg.direction < 0)
      return (leg.startPrice >= maStart && leg.endPrice < maEnd);

   return false;
}

// موج 2 نباید MA را در خلاف منطق setup بشکند
bool Wave2RespectsMA(string symbol, ENUM_TIMEFRAMES timeframe, const LegInfo &wave1, const LegInfo &wave2)
{
   double maStart, maEnd;

   if(!GetMAValueAtTime(symbol, timeframe, wave2.startTime, maStart))
      return false;
   if(!GetMAValueAtTime(symbol, timeframe, wave2.endTime, maEnd))
      return false;

   if(wave1.direction > 0)
   {
      // BUY setup -> موج 2 باید بالای MA بماند
      return (wave2.startPrice >= maStart && wave2.endPrice >= maEnd);
   }

   if(wave1.direction < 0)
   {
      // SELL setup -> موج 2 باید زیر MA بماند
      return (wave2.startPrice <= maStart && wave2.endPrice <= maEnd);
   }

   return false;
}

bool IsWave2Valid(const LegInfo &w1, const LegInfo &w2)
{
   double s1 = PriceDistance(w1);
   double s2 = PriceDistance(w2);

   if(s1 <= 0.0)
      return false;

   return ((s2 / s1) <= STRATEGY_WAVE2_MAX_RATIO);
}

bool IsWave3Valid(const LegInfo &w1, const LegInfo &w3)
{
   double s1 = PriceDistance(w1);
   double s3 = PriceDistance(w3);

   if(s1 <= 0.0)
      return false;

   return (s3 >= s1 * STRATEGY_WAVE3_MIN_RATIO);
}

//------------------------------------------------
// Drawing
//------------------------------------------------

void DrawMABreakLegGold(string symbol, ENUM_TIMEFRAMES timeframe, const LegInfo &leg)
{
   string name = "MA_BREAK_" + IntegerToString(leg.index);

   if(ObjectFind(0, name) >= 0)
      return;

   ObjectCreate(0, name, OBJ_TREND, 0, leg.startTime, leg.startPrice, leg.endTime, leg.endPrice);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawEntryArrow(string symbol, int direction, datetime t, double price)
{
   string name = "ENTRY_" + IntegerToString((int)t);

   if(ObjectFind(0, name) >= 0)
      return;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(direction == SIGNAL_BUY)
      price -= point * 40;
   else
      price += point * 40;

   ObjectCreate(0, name, OBJ_ARROW, 0, t, price);

   if(direction == SIGNAL_BUY)
   {
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrLime);
   }
   else
   {
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrTomato);
   }

   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
}

void ClearEntryZone()
{
   ObjectDelete(0, g_entryZoneName);
   ObjectDelete(0, g_entryMidName);
}

bool BuildEntryZoneFromWave3(const LegInfo &leg3)
{
   double wave3Size = PriceDistance(leg3);
   if(wave3Size <= 0.0)
      return false;

   double zoneA, zoneB;

   if(leg3.direction > 0)
   {
      // BUY -> اصلاح از سقف موج 3 به پایین
      g_entryTargetPrice = leg3.endPrice - (wave3Size * STRATEGY_ENTRY_FIB_TARGET);
      zoneA = leg3.endPrice - (wave3Size * STRATEGY_ENTRY_FIB_LOW);
      zoneB = leg3.endPrice - (wave3Size * STRATEGY_ENTRY_FIB_HIGH);
   }
   else
   {
      // SELL -> اصلاح از کف موج 3 به بالا
      g_entryTargetPrice = leg3.endPrice + (wave3Size * STRATEGY_ENTRY_FIB_TARGET);
      zoneA = leg3.endPrice + (wave3Size * STRATEGY_ENTRY_FIB_LOW);
      zoneB = leg3.endPrice + (wave3Size * STRATEGY_ENTRY_FIB_HIGH);
   }

   g_entryZoneTop    = MathMax(zoneA, zoneB);
   g_entryZoneBottom = MathMin(zoneA, zoneB);

   return true;
}

bool DrawEntryZone()
{
   ClearEntryZone();

   datetime t1 = g_leg3EndTime;
   datetime t2 = TimeCurrent() + PeriodSeconds(PERIOD_H1) * 20;

   if(!ObjectCreate(0, g_entryZoneName, OBJ_RECTANGLE, 0, t1, g_entryZoneTop, t2, g_entryZoneBottom))
      return false;

   ObjectSetInteger(0, g_entryZoneName, OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, g_entryZoneName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, g_entryZoneName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, g_entryZoneName, OBJPROP_BACK, true);
   ObjectSetInteger(0, g_entryZoneName, OBJPROP_FILL, true);
   ObjectSetInteger(0, g_entryZoneName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, g_entryZoneName, OBJPROP_HIDDEN, false);

   if(ObjectCreate(0, g_entryMidName, OBJ_TREND, 0, t1, g_entryTargetPrice, t2, g_entryTargetPrice))
   {
      ObjectSetInteger(0, g_entryMidName, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, g_entryMidName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, g_entryMidName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, g_entryMidName, OBJPROP_SELECTABLE, false);
   }

   return true;
}

//------------------------------------------------
// Entry Detection
//------------------------------------------------

void ResetActiveSetup()
{
   g_activeThreeWaveSetup = false;
   g_activeSetupDirection = SIGNAL_NONE;
   g_activeSetupLeg3Index = -1;
   g_signalTriggered      = false;
   g_leg3EndTime          = 0;
   g_entryTargetPrice     = 0.0;
   g_entryZoneTop         = 0.0;
   g_entryZoneBottom      = 0.0;

   ClearEntryZone();
}

void CheckFibZoneEntry(string symbol)
{
   if(!g_activeThreeWaveSetup)
      return;

   if(g_signalTriggered)
      return;

   if(g_waitRejection)
      return;

   MqlRates r[];
   ArraySetAsSeries(r, true);

   if(CopyRates(symbol, PERIOD_H1, 0, 1, r) <= 0)
      return;

   if(g_activeSetupDirection == SIGNAL_BUY)
   {
      if(r[0].low <= g_entryZoneTop && r[0].high >= g_entryZoneBottom)
      {
         g_waitRejection = true;
         g_rejectCandleCount = 0;

         Print("Price entered fib zone → waiting rejection");
      }
   }
   else if(g_activeSetupDirection == SIGNAL_SELL)
   {
      if(r[0].high >= g_entryZoneBottom && r[0].low <= g_entryZoneTop)
      {
         g_waitRejection = true;
         g_rejectCandleCount = 0;

         Print("Price entered fib zone → waiting rejection");
      }
   }
}


//------------------------------------------------
// Strategy Engine
//------------------------------------------------

bool UpdateStrategySignals(string symbol, ENUM_TIMEFRAMES timeframe)
{
   LegInfo legs[3];
   int count = GetLastCompletedLegsNewestFirst(legs, 3);

   if(count < 3)
   {
      Print("Strategy: not enough legs");
      return false;
   }

   LegInfo leg3 = legs[0];
   LegInfo leg2 = legs[1];
   LegInfo leg1 = legs[2];

   // اگر ستاپ فعال داریم و لگ جدیدی ثبت شد یعنی موج 4 آمده و ستاپ قبلی باطل است
   if(g_activeThreeWaveSetup)
   {
      if(leg3.index != g_activeSetupLeg3Index)
      {
         Print("Wave 4 formed -> setup invalidated");
         ResetActiveSetup();
         return false;
      }
   }

   if(leg3.index == g_lastProcessedLegIndex)
      return false;

   g_lastProcessedLegIndex = leg3.index;

   if(!LegBreaksMAInDirection(symbol, timeframe, leg1))
   {
      Print("FAIL: wave1 does not break MA");
      return false;
   }

   if(leg2.direction != -leg1.direction)
   {
      Print("FAIL: wave2 direction invalid");
      return false;
   }

   if(!IsWave2Valid(leg1, leg2))
   {
      Print("FAIL: wave2 retracement too deep");
      return false;
   }

   if(!Wave2RespectsMA(symbol, timeframe, leg1, leg2))
   {
      Print("FAIL: wave2 breaks/touches MA");
      return false;
   }

   if(leg3.direction != leg1.direction)
   {
      Print("FAIL: wave3 direction invalid");
      return false;
   }

   if(!IsWave3Valid(leg1, leg3))
   {
      Print("FAIL: wave3 smaller than wave1");
      return false;
   }

   DrawMABreakLegGold(symbol, timeframe, leg1);
   DrawMABreakLegGold(symbol, timeframe, leg2);
   DrawMABreakLegGold(symbol, timeframe, leg3);

   g_activeSetupDirection = (leg1.direction > 0 ? SIGNAL_BUY : SIGNAL_SELL);
   g_activeThreeWaveSetup = true;
   g_activeSetupLeg3Index = leg3.index;
   g_leg3EndTime          = leg3.endTime;
   g_signalTriggered      = false;

   if(!BuildEntryZoneFromWave3(leg3))
   {
      Print("FAIL: fib zone build failed");
      ResetActiveSetup();
      return false;
   }

   DrawEntryZone();

   Print("VALID 3 WAVE SETUP + FIB 60% ENTRY ZONE");
   return true;
}

void CheckThreeWaveRejection(string symbol)
{
   if(!g_waitRejection)
      return;

   static datetime lastBar=0;

   MqlRates r[2];
   ArraySetAsSeries(r,true);

   if(CopyRates(symbol,PERIOD_H1,0,2,r)<=0)
      return;

   if(r[1].time==lastBar)
      return;

   lastBar=r[1].time;

   g_rejectCandleCount++;

   double body=MathAbs(r[1].close-r[1].open);

   double upper=r[1].high-MathMax(r[1].close,r[1].open);
   double lower=MathMin(r[1].close,r[1].open)-r[1].low;

   bool rejection=false;

   if(g_activeSetupDirection==SIGNAL_BUY)
      rejection=(lower>body);

   if(g_activeSetupDirection==SIGNAL_SELL)
      rejection=(upper>body);

   if(rejection)
   {
      StrategySignal sig;

      ResetSignalStruct(sig);

      sig.valid        = true;
      sig.used         = false;
      sig.direction    = g_activeSetupDirection;
      sig.signalTime   = r[1].time;
      sig.strategyName = "ThreeWave";
      sig.symbol       = symbol;
      sig.timeframe    = PERIOD_H1;
      sig.signalPrice  = r[1].close;

      CreateSignal(sig);

      DrawEntryArrow(symbol, g_activeSetupDirection, r[1].time, r[1].close);

      Print("ThreeWave ENTRY after H1 rejection");

      g_signalTriggered = true;
      g_waitRejection = false;
   }

   if(g_rejectCandleCount >= MAX_REJECTION_CANDLES)
   {
      Print("No rejection → cancel setup");
      g_waitRejection = false;
   }
}



#endif
