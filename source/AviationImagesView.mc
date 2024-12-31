import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;


var wHeight=100.0;
var wWidth=100.0;
var batY = 0.1; 
var stepY = 0.8;



class AviationImagesView extends WatchUi.WatchFace {


    var hasComps;
    var stepId, batId, calId, noteId, wxId;
    var stepComp, batComp, noteComp, wxComp;
    var compId;

    var storeOpt;

    var batLoad, mSteps, stepLoad, noteSets, wxNow;

    var calcTime;
    var dateCalc;
    var dateString;
    var batString;

    var stepString;
    var myZuluLabel;
    var myZuluTime;

    var alarmString=" ";

    var lowPowerMode = false;
    var timeF = Graphics.FONT_NUMBER_MEDIUM;
    var fontH;
    var fontW;

    var BIP = true;  //burn in protection, top or bottom


    function initialize() {
        WatchFace.initialize();
                        
        hasComps = (Toybox has :Complications); 
        lowPowerMode = (Toybox has :onPartialUpdate);

        if (hasComps) {
            stepId = new Id(Complications.COMPLICATION_TYPE_STEPS);
            batId = new Id(Complications.COMPLICATION_TYPE_BATTERY);
            calId = new Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);
            noteId = new Id(Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT);
            wxId = new Id(Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE);

            stepComp = Complications.getComplication(stepId);
            if (stepComp != null) {
                Complications.subscribeToUpdates(stepId);
            }

            batComp = Complications.getComplication(batId);
            if (batComp != null) {
                Complications.subscribeToUpdates(batId);  
            }

            noteComp = Complications.getComplication(noteId);
            if (noteComp != null) {
                Complications.subscribeToUpdates(noteId);
            } 

            wxComp = Complications.getComplication(wxId);
            if (wxComp != null) {
                Complications.subscribeToUpdates(wxId);
            }

            Complications.registerComplicationChangeCallback(self.method(:onComplicationChanged));         
        }    
    }

    function onComplicationChanged(compId as Complications.Id) as Void {

        if (compId == batId) {
            batLoad = (Complications.getComplication(batId)).value;
            if (batLoad == null) {
                batLoad = ((System.getSystemStats().battery) + 0.5).toNumber();
            }
        } else if (compId == stepId) {
            mSteps = (Complications.getComplication(stepId)).value;
            if (mSteps == null){
                var stepLoad = ActivityMonitor.getInfo();
                mSteps = stepLoad.steps;
            }
            if (mSteps instanceof Toybox.Lang.Float) {
                mSteps = (mSteps * 1000).toNumber(); //System converts to float at 10k. Reported system error
            }
        } else if (compId == noteId) {
            noteSets = (Complications.getComplication(noteId)).value;
            if (noteSets == null) {
                var tempNotes = System.getDeviceSettings();
                noteSets = tempNotes.notificationCount;
            }
        } else if (compId == wxId) {
            wxNow = (Complications.getComplication(wxId)).value;
            if (wxNow == null) {
               wxNow = -99; 
            }
        } else {
            System.println("no valid comps");
        }
    }


    // Load your resources here
    function onLayout(dc as Dc) as Void {
        wHeight = dc.getHeight();
        wWidth = dc.getWidth();

        fontH = dc.getFontHeight(timeF);
        fontW = dc.getTextWidthInPixels("00:00", timeF);

        //Draw Background Image
            if (backImg != null) {
                dc.drawBitmap(0, 0, backImg);
            } else {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.clear();
            }
        //Draw battery
            battDisp(dc);
            dc.drawText((wWidth/2), (0.08 * wHeight), Graphics.FONT_TINY, batString, Graphics.TEXT_JUSTIFY_CENTER);    
        //Draw Alarm
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
            alarmDisp();
            dc.drawText(wWidth * 0.7, wHeight * 0.1, Graphics.FONT_TINY, alarmString, Graphics.TEXT_JUSTIFY_LEFT);
        //Draw Time
            drawTime();
            dc.setColor(clockShadSet, Graphics.COLOR_TRANSPARENT);
            dc.drawText(((wWidth / 2) + 1), ((wHeight * 0.22) + 1), Graphics.FONT_NUMBER_THAI_HOT, calcTime, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(clockColorSet, Graphics.COLOR_TRANSPARENT);
            dc.drawText((wWidth / 2), (wHeight * 0.22), Graphics.FONT_NUMBER_THAI_HOT, calcTime, Graphics.TEXT_JUSTIFY_CENTER);
        //Draw Date
            dateDisp();
            dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
            dc.drawText(wWidth / 2, wHeight * 0.58, Graphics.FONT_MEDIUM, dateString, Graphics.TEXT_JUSTIFY_CENTER);
        //Draw Z Time or Steps
            drawZTime();
            dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
            dc.drawText(wWidth / 2, wHeight * 0.75, Graphics.FONT_LARGE, stepString, Graphics.TEXT_JUSTIFY_CENTER);
        //Draw Notes if on
            if (showNotes) {
                if (!hasComps) {
                    var tempNotes = System.getDeviceSettings();
                    noteSets = tempNotes.notificationCount;
                }
                if (noteSets > 0) {
                    dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(wWidth / 4, wHeight * 0.1, Graphics.FONT_TINY, "N", Graphics.TEXT_JUSTIFY_LEFT);
                }
            } else {
                dc.drawText(wWidth / 4, wHeight * 0.1, Graphics.FONT_TINY, " ", Graphics.TEXT_JUSTIFY_LEFT);
            }
        //Draw Seconds Arc
            if (dispSecs && 
                    System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {

                    var centerX = wWidth / 2;
                    var centerY = wHeight / 2;
                    var mRadius = centerX < centerY ? centerX - 4: centerY - 4;
                    var clockTime = System.getClockTime();
                    var mSeconds = clockTime.sec;

                    var mPen = 4;

                    var mArc = 90 - (mSeconds * 6);

                    dc.setPenWidth(mPen);
                    dc.setColor(clockColorSet, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(centerX, centerY, mRadius, Graphics.ARC_CLOCKWISE, 90, mArc);
            }
        
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        if (!lowPowerMode) {
            //Draw Background Image
            if (whichBGUpdated) {
                if (backImg != null) {
                    dc.drawBitmap(0, 0, backImg);
                } else {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                    dc.clear();
                }
            }

            //Draw battery
                battDisp(dc);
                dc.drawText((wWidth/2), (0.08 * wHeight), Graphics.FONT_TINY, batString, Graphics.TEXT_JUSTIFY_CENTER);    
        
            //Draw Time
                drawTime();
                dc.setColor(clockShadSet, Graphics.COLOR_TRANSPARENT);
                dc.drawText(((wWidth / 2) + 1), ((wHeight * 0.22) + 1), Graphics.FONT_NUMBER_THAI_HOT, calcTime, Graphics.TEXT_JUSTIFY_CENTER);
                dc.setColor(clockColorSet, Graphics.COLOR_TRANSPARENT);
                dc.drawText((wWidth / 2), (wHeight * 0.20), Graphics.FONT_NUMBER_THAI_HOT, calcTime, Graphics.TEXT_JUSTIFY_CENTER);
        
            //Draw Date
                dateDisp();
                dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
                dc.drawText(wWidth / 2, wHeight * 0.58, Graphics.FONT_MEDIUM, dateString, Graphics.TEXT_JUSTIFY_CENTER);

            //Draw Alarm
                dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
                alarmDisp();
                dc.drawText(wWidth * 0.7, wHeight * 0.1, Graphics.FONT_TINY, alarmString, Graphics.TEXT_JUSTIFY_LEFT);

            //Draw Z Time or Steps
                drawZTime();
                dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
                dc.drawText(wWidth / 2, wHeight * 0.75, Graphics.FONT_LARGE, stepString, Graphics.TEXT_JUSTIFY_CENTER);
 
            //Draw Notes if on
                if (showNotes) {
                    if (!hasComps) {
                        var tempNotes = System.getDeviceSettings();
                        noteSets = tempNotes.notificationCount;
                    }
                    if (noteSets > 0) {
                        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(wWidth / 4, wHeight * 0.1, Graphics.FONT_TINY, "N", Graphics.TEXT_JUSTIFY_LEFT);
                    }
                } else {
                    dc.drawText(wWidth / 4, wHeight * 0.1, Graphics.FONT_TINY, " ", Graphics.TEXT_JUSTIFY_LEFT);
                }

                if (dispSecs && 
                        System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {

                        var centerX = wWidth / 2;
                        var centerY = wHeight / 2;
                        var mRadius = centerX < centerY ? centerX - 4: centerY - 4;
                        var clockTime = System.getClockTime();
                        var mSeconds = clockTime.sec;

                        var mPen = 4;

                        var mArc = 90 - (mSeconds * 6);

                        dc.setPenWidth(mPen);
                        dc.setColor(clockColorSet, Graphics.COLOR_TRANSPARENT);
                        dc.drawArc(centerX, centerY, mRadius, Graphics.ARC_CLOCKWISE, 90, mArc);
                }
        } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            drawTime();
            timeOrStep = 0; //This forces z time to be displayed
            drawZTime();
            dc.setColor(clockColorSet, Graphics.COLOR_BLACK);
            if (BIP) {
                dc.drawText((wWidth / 2), (wHeight * 0.15), Graphics.FONT_NUMBER_MEDIUM, calcTime, Graphics.TEXT_JUSTIFY_CENTER); 
                dc.drawText((wWidth / 2), (wHeight * 0.60), Graphics.FONT_MEDIUM, stepString, Graphics.TEXT_JUSTIFY_CENTER);
                BIP = false; 
            } else {
                dc.drawText((wWidth / 2), (wHeight * 0.30), Graphics.FONT_NUMBER_MEDIUM, calcTime, Graphics.TEXT_JUSTIFY_CENTER); 
                dc.drawText((wWidth / 2), (wHeight * 0.70), Graphics.FONT_MEDIUM, stepString, Graphics.TEXT_JUSTIFY_CENTER); 
                BIP = true;
            }
        } 
    }
    
        //Dispaly time
        function drawTime() {
 
            //Created formated local time

            var clockTime = System.getClockTime();
            var hours = clockTime.hour;

            //Calc local time for 12 or 24 hour clock
            if (System.getDeviceSettings().is24Hour == true){      
                calcTime = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
            } else {
                if (hours > 12) {
                    hours = hours - 12;
                }
                calcTime = Lang.format("$1$:$2$", [hours, clockTime.min.format("%02d")]);
            }
        }

        function dateDisp() {

            var dateLoad = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

            dateString = Lang.format("$1$, $2$ $3$", 
                [dateLoad.day_of_week,
                dateLoad.day,
                dateLoad.month]);

        }

            //Battery Display Area
        function battDisp(dc) {
            //Get battery info

            if (hasComps && showBat == 2) {
                dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
                if (ForC == System.UNIT_METRIC) {
                    batString = Lang.format("$1$", [wxNow])+"°";
                } else {
                    wxNow = (wxNow * 9 / 5 + 32).toNumber();
                    batString = Lang.format("$1$", [wxNow])+"°";
                }
            } else if (showBat == 0) {

                if (!hasComps) {
                    batLoad = ((System.getSystemStats().battery) + 0.5).toNumber();
                }
                batString = Lang.format("$1$", [batLoad])+"%";

                if (System has :SCREEN_SHAPE_SEMI_OCTAGON &&
                    System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_SEMI_OCTAGON){     //Monocrhrome correction

                    if (batLoad < 5.0) {
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    } else if (batLoad < 25.0) {
                        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                    } else {
                        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
                    }
                } else {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                }
            } else { 
                batString = " ";
            }  
        }

        //Draw Zulu Time Offset
        function drawZTime() {

            //Zulu time or steps option 
            if (timeOrStep == 1){
                //Format Steps
                if (!hasComps){
                    var stepLoad = ActivityMonitor.getInfo();
                    var steps = stepLoad.steps;
                    stepString = Lang.format("$1$", [steps]);
                } else {
                    stepString = Lang.format("$1$", [mSteps]);
                }

            } else {
                //Format zulu time
                var zTime = Gregorian.utcInfo(Time.now(), Time.FORMAT_MEDIUM);

                stepString = Lang.format("$1$:$2$", [zTime.hour.format("%02d"), zTime.min.format("%02d")])+"Z";
            }
        }

        function alarmDisp() {

            var alSets = System.getDeviceSettings().alarmCount;

            if (alSets != 0) {
                alarmString = "A";
            } else {
                alarmString = " ";
            }
        } 
    
    function onExitSleep() {
        lowPowerMode = false;
        if (storeOpt != null) {
            timeOrStep = storeOpt;  //After always on, select user display for second time
        } else {
            timeOrStep = 0;
        }
        WatchUi.requestUpdate();
    }

    function onEnterSleep() {
        lowPowerMode = true;
        storeOpt = timeOrStep;  //Store this value for coming out of low power mode
        WatchUi.requestUpdate();
    }
     

}

class AviationImagesViewDelegate extends WatchUi.WatchFaceDelegate
{
	var view;
	
	function initialize(v) {
		WatchFaceDelegate.initialize();
		view=v;	
	}

    function onPress(evt) {
        var c=evt.getCoordinates();
        var batY = view.batY * view.wHeight;
        var stepY = view.stepY * view.wHeight;

        if (!touchOff && c[1] <= batY) {

            if (showBat == 0 && view.batId != null) {
                Complications.exitTo(view.batId);
                return true;
            } else if (showBat == 2 && view.wxId != null) {
                Complications.exitTo(view.wxId);
                return true;
            } else {
                return false;
            }

        } else if (!touchOff && c[1] > batY && c[1] <= stepY && view.calId != null) {
            Complications.exitTo(view.calId);
            return true;
        } else if (!touchOff && view.stepId != null) {
            Complications.exitTo(view.stepId);
            return true;
        } else {
            return false;
        }
    }
	
}
