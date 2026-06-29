#property strict

#include "Utils/CandleUtils.mqh"
#include "Core/ZigZag.mqh"
#include "Core/MarketStructure.mqh"
#include "Core/SignalTypes.mqh"
#include "Core/SignalBus.mqh"
#include "Core/StrategySignals.mqh"
#include "Core/StrategySignal2.mqh"


#define STRATEGY_TIMEFRAME PERIOD_H1

datetime lastBarTime = 0;

//-----------------------------------------
// Example consumer function
//-----------------------------------------
void ProcessLastCompletedLegs(LegInfo &legs[], int count)
{
   for(int i = 0; i < count; i++)
   {
      LegInfo leg = legs[i];

      Print(
         "Leg #", leg.index,
         " | Direction=", GetLegDirectionText(leg.direction),
         " | Type=", leg.legTypeText,
         " | Strength=", DoubleToString(leg.strength, 2),
         " | Candles=", leg.candlesCount,
         " | NetPips=", DoubleToString(leg.netMovePips, 1)
      );
   }
}

//-----------------------------------------
// ICT / SMC style chart theme
//-----------------------------------------
void ApplyICTChartTheme()
{
   long chart_id = ChartID();

   color bg      = C'10,12,18';
   color fg      = C'210,214,220';
   color bull    = C'0,255,170';
   color bear    = C'255,95,95';
   color lineclr = C'160,170,180';
   color muted   = C'70,70,70';

   ChartSetInteger(chart_id, CHART_SHOW_GRID, false);
   ChartSetInteger(chart_id, CHART_SHOW_OHLC, false);
   ChartSetInteger(chart_id, CHART_SHOW_BID_LINE, false);
   ChartSetInteger(chart_id, CHART_SHOW_ASK_LINE, false);
   ChartSetInteger(chart_id, CHART_SHOW_VOLUMES, CHART_VOLUME_HIDE);

   ChartSetInteger(chart_id, CHART_AUTOSCROLL, true);
   ChartSetInteger(chart_id, CHART_SHIFT, true);
   ChartSetInteger(chart_id, CHART_SCALEFIX, false);

   ChartSetInteger(chart_id, CHART_MODE, CHART_CANDLES);

   ChartSetDouble(chart_id, CHART_SHIFT_SIZE, 20.0);

   ChartSetInteger(chart_id, CHART_COLOR_BACKGROUND, bg);
   ChartSetInteger(chart_id, CHART_COLOR_FOREGROUND, fg);

   ChartSetInteger(chart_id, CHART_COLOR_CHART_UP, bull);
   ChartSetInteger(chart_id, CHART_COLOR_CHART_DOWN, bear);

   ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BULL, bull);
   ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BEAR, bear);

   ChartSetInteger(chart_id, CHART_COLOR_CHART_LINE, lineclr);

   ChartSetInteger(chart_id, CHART_COLOR_GRID, bg);
   ChartSetInteger(chart_id, CHART_COLOR_STOP_LEVEL, muted);

   ChartSetInteger(chart_id, CHART_COLOR_VOLUME, muted);
   ChartSetInteger(chart_id, CHART_COLOR_ASK, bg);
   ChartSetInteger(chart_id, CHART_COLOR_BID, bg);

   ChartRedraw(chart_id);
}

//-----------------------------------------
// Init
//-----------------------------------------
int OnInit()
{
   lastBarTime = iTime(_Symbol, STRATEGY_TIMEFRAME, 1);

   ApplyICTChartTheme();

   InitializeSignalStorage();

   // ZigZag
   ClearSimpleZigZag(_Symbol, STRATEGY_TIMEFRAME);
   InitializeRealtimeZigZag(_Symbol, STRATEGY_TIMEFRAME);
   InitZigZagPanel(_Symbol, STRATEGY_TIMEFRAME);

   // Market Structure
   SetMarketStructureFilters(35.0, 8.0);
   InitializeMarketStructure(_Symbol, STRATEGY_TIMEFRAME);

   // Strategy
   if(!EnsureStrategyMA(_Symbol, STRATEGY_TIMEFRAME))
      return INIT_FAILED;

   DrawStrategyMAGold(_Symbol, STRATEGY_TIMEFRAME);

   return INIT_SUCCEEDED;
}

//-----------------------------------------
// Deinit
//-----------------------------------------
void OnDeinit(const int reason)
{


   ClearSimpleZigZag(_Symbol, STRATEGY_TIMEFRAME);
   ClearMarketStructureDrawings(_Symbol, STRATEGY_TIMEFRAME);
   ClearStrategyMA();
   ClearEntryZone();
   DeleteFibZone();


   if(g_maHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_maHandle);
      g_maHandle = INVALID_HANDLE;
   }
}

//-----------------------------------------
// Main Tick
//-----------------------------------------
void OnTick()
{

   //-------------------------------------------------
   // ENTRY LOGIC (M5) — run every tick
   //-------------------------------------------------
   CheckFibZoneEntry(_Symbol);
   CheckThreeWaveRejection(_Symbol);
   
   DetectWave6(_Symbol);
   CheckRejection(_Symbol);
        


   //-------------------------------------------------
   // STRUCTURE LOGIC (H1)
   //-------------------------------------------------
   if(!IsNewCandle(STRATEGY_TIMEFRAME, lastBarTime, _Symbol))
      return;

   DrawStrategyMAGold(_Symbol, STRATEGY_TIMEFRAME);

   bool changed = AddLatestZigZagSegment(_Symbol, STRATEGY_TIMEFRAME);

   UpdateZigZagPanel(_Symbol, STRATEGY_TIMEFRAME);

   if(changed)
   {
      UpdateMarketStructureFromLatestClosedLeg(_Symbol, STRATEGY_TIMEFRAME);

      UpdateStrategySignals(_Symbol, STRATEGY_TIMEFRAME);
      UpdateStrategySignal2(_Symbol);
   }
   else
   {
      RefreshMarketStructureVisuals(_Symbol, STRATEGY_TIMEFRAME);
   }

   //-------------------------------------------------
   // Debug output
   //-------------------------------------------------
   LegInfo lastLegs[];
   int count = GetLastCompletedLegsNewestFirst(lastLegs, 10);

   if(count > 0)
      ProcessLastCompletedLegs(lastLegs, count);

}

