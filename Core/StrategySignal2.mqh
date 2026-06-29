#ifndef __STRATEGY_SIGNAL2_MQH__
#define __STRATEGY_SIGNAL2_MQH__

#include "ZigZag.mqh"
#include "SignalTypes.mqh"
#include "SignalBus.mqh"

static LegInfo g_w1,g_w2,g_w3,g_w4,g_w5,g_w6;

#define WAVE2_MAX 0.70
#define WAVE4_MAX 0.70

#define FIB_LOW 0.55
#define FIB_HIGH 0.65

#define MAX_LEGS_WAIT 3
#define MAX_REJECTION_CANDLES 3

static int g_lastPatternLegIndex=-1;
static int g_lastCheckedLegIndex=-1;

static bool g_waitWave6=false;
static bool g_waitFibPullback=false;
static bool g_waitRejection2=false;

static int g_waitLegCount=0;
static int g_rejectCandleCount2=0;

static double g_zoneHigh=0;
static double g_zoneLow=0;

static int g_tradeDirection=SIGNAL_NONE;

color WAVE_COLOR=clrTurquoise;

//------------------------------------------------

void DeleteFibZone()
{
   ObjectDelete(0,"WAVE6_FIB_ZONE");
}

//------------------------------------------------

double WaveSize(const LegInfo &l)
{
   return MathAbs(l.endPrice-l.startPrice);
}

//------------------------------------------------

void DrawWave(string name,datetime t1,double p1,datetime t2,double p2)
{
   ObjectDelete(0,name);

   ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);

   ObjectSetInteger(0,name,OBJPROP_COLOR,WAVE_COLOR);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
}

//------------------------------------------------

void DrawFibZone(double low,double high)
{
   ObjectDelete(0,"WAVE6_FIB_ZONE");

   datetime t1=TimeCurrent();
   datetime t2=t1+PeriodSeconds(PERIOD_H1)*200;

   ObjectCreate(0,"WAVE6_FIB_ZONE",OBJ_RECTANGLE,0,t1,low,t2,high);

   ObjectSetInteger(0,"WAVE6_FIB_ZONE",OBJPROP_COLOR,clrAqua);
   ObjectSetInteger(0,"WAVE6_FIB_ZONE",OBJPROP_BACK,true);
}

//------------------------------------------------

void DrawEntryArrow(bool buy,datetime t,double price)
{
   string name="Wave6Entry_"+IntegerToString(t);

   ObjectCreate(0,name,buy?OBJ_ARROW_UP:OBJ_ARROW_DOWN,0,t,price);

   ObjectSetInteger(0,name,OBJPROP_COLOR,buy?clrLime:clrRed);
}

//------------------------------------------------

bool ValidateWave2(const LegInfo &w1,const LegInfo &w2)
{
   double s1=WaveSize(w1);
   double s2=WaveSize(w2);

   if(s1<=0) return false;

   return (s2/s1)<=WAVE2_MAX;
}

//------------------------------------------------

bool ValidateWave3(const LegInfo &w1,const LegInfo &w3)
{
   return WaveSize(w3)>=WaveSize(w1);
}

//------------------------------------------------

bool ValidateWave4(const LegInfo &w3,const LegInfo &w4,const LegInfo &w1)
{
   double s3=WaveSize(w3);
   double s4=WaveSize(w4);

   if((s4/s3)>WAVE4_MAX)
      return false;

   if(w3.direction>0)
   {
      if(w4.endPrice<=w1.endPrice)
         return false;
   }
   else
   {
      if(w4.endPrice>=w1.endPrice)
         return false;
   }

   return true;
}

//------------------------------------------------

bool ValidateWave5(const LegInfo &w3,const LegInfo &w5)
{
   return WaveSize(w5)>=WaveSize(w3);
}

//------------------------------------------------
// CHECK REJECTION (H1)
//------------------------------------------------

void CheckRejection(string symbol)
{
   if(!g_waitRejection2)
      return;

   static datetime lastBar=0;

   MqlRates r[2];
   ArraySetAsSeries(r,true);

   if(CopyRates(symbol,PERIOD_H1,0,2,r)<=0)
      return;

   if(r[1].time==lastBar)
      return;

   lastBar=r[1].time;

   g_rejectCandleCount2++;

   double body=MathAbs(r[1].close-r[1].open);

   double upper=r[1].high-MathMax(r[1].close,r[1].open);
   double lower=MathMin(r[1].close,r[1].open)-r[1].low;

   bool rejection=false;

   if(g_tradeDirection==SIGNAL_SELL)
      rejection=(upper>body);

   if(g_tradeDirection==SIGNAL_BUY)
      rejection=(lower>body);

   if(rejection)
   {
      StrategySignal sig;

      ResetSignalStruct(sig);

      sig.valid=true;
      sig.direction=g_tradeDirection;
      sig.symbol=symbol;
      sig.timeframe=PERIOD_H1;
      sig.signalTime=r[1].time;
      sig.strategyName="Wave6_FibPullback";
      sig.signalPrice=r[1].close;

      CreateSignal(sig);

      DrawEntryArrow(g_tradeDirection==SIGNAL_BUY,r[1].time,r[1].close);

      DeleteFibZone();

      g_waitRejection2=false;

      Print("ENTRY AFTER H1 REJECTION");
   }

   if(g_rejectCandleCount2>=MAX_REJECTION_CANDLES)
   {
      DeleteFibZone();
      g_waitRejection2=false;

      Print("No rejection → cancel setup");
   }
}

//------------------------------------------------
// WAVE6 DETECTION
//------------------------------------------------

void DetectWave6(string symbol)
{
   LegInfo legs[1];

   if(GetLastCompletedLegsNewestFirst(legs,1)<1)
      return;

   LegInfo lastLeg=legs[0];
   

   if(lastLeg.index <= g_w5.index)
      return;

   if(lastLeg.index==g_lastCheckedLegIndex)
      return;

   g_lastCheckedLegIndex=lastLeg.index;

   if(g_waitWave6)
   {
      g_w6=lastLeg;

      DrawWave("Wave1",g_w1.startTime,g_w1.startPrice,g_w1.endTime,g_w1.endPrice);
      DrawWave("Wave2",g_w2.startTime,g_w2.startPrice,g_w2.endTime,g_w2.endPrice);
      DrawWave("Wave3",g_w3.startTime,g_w3.startPrice,g_w3.endTime,g_w3.endPrice);
      DrawWave("Wave4",g_w4.startTime,g_w4.startPrice,g_w4.endTime,g_w4.endPrice);
      DrawWave("Wave5",g_w5.startTime,g_w5.startPrice,g_w5.endTime,g_w5.endPrice);
      DrawWave("Wave6",g_w6.startTime,g_w6.startPrice,g_w6.endTime,g_w6.endPrice);

      double size=WaveSize(g_w6);

      if(g_w6.direction>0)
      {
         g_tradeDirection=SIGNAL_SELL;
         g_zoneHigh=g_w6.endPrice-(size*FIB_LOW);
         g_zoneLow =g_w6.endPrice-(size*FIB_HIGH);
      }
      else
      {
         g_tradeDirection=SIGNAL_BUY;
         g_zoneLow =g_w6.endPrice+(size*FIB_LOW);
         g_zoneHigh=g_w6.endPrice+(size*FIB_HIGH);
      }

      DrawFibZone(g_zoneLow,g_zoneHigh);

      g_waitWave6=false;
      g_waitFibPullback=true;
      g_waitLegCount=0;

      Print("Wave6 detected → waiting fib pullback");
      return;
   }

   if(g_waitFibPullback)
   {
      g_waitLegCount++;

      if(g_waitLegCount>MAX_LEGS_WAIT)
      {
         DeleteFibZone();
         g_waitFibPullback=false;
         Print("Pullback never reached fib");
         return;
      }

      if(lastLeg.endPrice<=g_zoneHigh && lastLeg.endPrice>=g_zoneLow)
      {
         g_waitFibPullback=false;
         g_waitRejection2=true;
         g_rejectCandleCount2=0;

         Print("Price reached Wave6 fib → wait rejection");
      }
   }
}

//------------------------------------------------
// MAIN ENGINE
//------------------------------------------------

bool UpdateStrategySignal2(string symbol)
{
   LegInfo legs[5];

   int count=GetLastCompletedLegsNewestFirst(legs,5);

   if(count<5)
      return false;

   LegInfo w5=legs[0];
   LegInfo w4=legs[1];
   LegInfo w3=legs[2];
   LegInfo w2=legs[3];
   LegInfo w1=legs[4];

   if(w5.index==g_lastPatternLegIndex)
      return false;

   // impulse waves must have same direction
   if(w1.direction != w3.direction) return false;
   if(w3.direction != w5.direction) return false;
   
   // corrective waves must be opposite
   if(w2.direction == w1.direction) return false;
   if(w4.direction == w3.direction) return false;


   if(!ValidateWave2(w1,w2)) return false;
   if(!ValidateWave3(w1,w3)) return false;
   if(!ValidateWave4(w3,w4,w1)) return false;
   if(!ValidateWave5(w3,w5)) return false;

   g_w1=w1;
   g_w2=w2;
   g_w3=w3;
   g_w4=w4;
   g_w5=w5;

   g_waitWave6=true;
   g_waitFibPullback=false;
   g_waitRejection2=false;

   g_lastPatternLegIndex=w5.index;

   Print("5 wave impulse detected → waiting Wave6");

   return true;
}

#endif
