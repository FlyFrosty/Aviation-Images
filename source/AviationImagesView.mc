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

var ForC;



class AviationImagesView extends WatchUi.WatchFace {

    var hasComps;
    var hasWx = false;
    var stepId, batId, calId, noteId, wxId;
    var stepComp, batComp, noteComp, wxComp;
    var compId;
    var anyNotes = false;
    var noteString = " ";

    var batLoad, mSteps, stepLoad, noteSets;
    var wxNow = -99.0;

    var calcTime;
    var dateCalc;
    var dateString;
    var batString;

    var stepString;
    var myZuluLabel;
    var myZuluTime;

    var myEnvelope;
    var myClock;

    var alarmString=" ";
    var alSets;

    var lowPowerMode = false;
    var timeF = Graphics.FONT_NUMBER_MEDIUM;

    var BIP = true;  //burn in protection, top or bottom

    var myView;


    function initialize() {
        WatchFace.initialize();

        myView = new AviationImagesApp();
                        
        hasComps = (Toybox has :Complications); 
        lowPowerMode = (Toybox has :onPartialUpdate);
        hasWx = (Toybox has :Weather);

        ForC = System.getDeviceSettings().temperatureUnits;

        myEnvelope = WatchUi.loadResource(Rez.Drawables.envelope);
        myClock = WatchUi.loadResource(Rez.Drawables.clock); 

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
        
        } else if (compId == wxId) {
            wxNow = (Complications.getComplication(wxId)).value;
            if ((ForC != System.UNIT_METRIC) && (wxNow != null)) {
                wxNow = (wxNow * 9.0 / 5.0 + 32.0).toFloat();
            }

        } else if (compId == stepId) {
            mSteps = (Complications.getComplication(stepId)).value;

        } else if (compId == noteId) {
            noteSets = (Complications.getComplication(noteId)).value;

        } else {
            System.println("no valid comps");
        }
    }


    // Load your resources here
    function onLayout(dc as Dc) as Void {

        wHeight = dc.getHeight();
        wWidth = dc.getWidth();

        //Draw Background Image
        if (backImg != null) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            dc.drawBitmap(0, 0, backImg);
        } else {
            try {
                whichBG = Properties.getValue("BGOpt");
                myView.whichBGUpdate();
            } catch (e) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.clear();
                if (clockColorNum == 3) {clockColorSet = Graphics.COLOR_WHITE;} //in case of error
            }
        }
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        if (!lowPowerMode) {
            //Draw Background Image
            if (backImg != null) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.clear();
                dc.drawBitmap(0, 0, backImg);
            } else {
                try {
                    whichBG = Properties.getValue("BGOpt");
                    myView.whichBGUpdate();
                } catch (e) {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                    dc.clear();
                    if (clockColorNum == 3) {clockColorSet = Graphics.COLOR_WHITE;} //in case of error
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
                if (alSets) {
                    try {
                        dc.drawBitmap(wWidth * 0.64, wHeight * 0.11, myClock);
                    } catch (e) {
                        dc.drawText(wWidth * 0.7, wHeight * 0.1, Graphics.FONT_TINY, alarmString, Graphics.TEXT_JUSTIFY_LEFT);
                    }
                } else {
                    dc.drawText(wWidth * 0.7, wHeight * 0.1, Graphics.FONT_TINY, " ", Graphics.TEXT_JUSTIFY_LEFT);
                }

            //Draw Z Time or Steps
                drawZTime();
                dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
                dc.drawText(wWidth / 2, wHeight * 0.75, Graphics.FONT_LARGE, stepString, Graphics.TEXT_JUSTIFY_CENTER);
 
            //Draw Notes if on               
                if (showNotes) {
                    notesDisp();
                    if (anyNotes) {
                        try {
                            dc.drawBitmap(wWidth / 4, wHeight * 0.1,myEnvelope);
                        } catch (e) {
                            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
                            dc.drawText(wWidth / 4, wHeight * 0.1, Graphics.FONT_TINY, noteString, Graphics.TEXT_JUSTIFY_LEFT);
                        }
                    } else {
                        dc.drawText(wWidth / 4, wHeight * 0.1, Graphics.FONT_TINY, " ", Graphics.TEXT_JUSTIFY_LEFT);
                    }
                }

            //Draw Seconds Arc if on
                if (dispSecs && 
                    System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
                        secondsDisplay(dc);
                }

        } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            drawTime();
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

        if (showBat == 2 && hasWx) {

            if ((hasComps && wxNow == null) || (!hasComps)) {
                var tempTemp = Weather.getCurrentConditions();
                if (tempTemp != null){    
                    wxNow = tempTemp.temperature; 
                    if ((ForC != System.UNIT_METRIC) && (wxNow != null)) {
                    wxNow = (wxNow * 9.0 / 5.0 + 32.0).toFloat();
                    }
                } 
            }
            
            dc.setColor(subColorSet, Graphics.COLOR_TRANSPARENT);
            if (wxNow != null) {
                if (ForC != System.UNIT_METRIC){
                    wxNow = wxNow.toNumber();
                    batString = Lang.format("$1$", [wxNow])+"°";
                } else {
                    batString = Lang.format("$1$", [wxNow.format("%.01f")])+"°";
                }
            } else {
                batString = "err";
            }

        } else if (showBat == 0) {
            if (!hasComps || batLoad == null) {
                batLoad = ((System.getSystemStats().battery) + 0.5).toNumber();
            }

            if (batLoad < 5.0) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            } else if (batLoad < 25.0) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
            }
            batString = Lang.format("$1$", [batLoad])+"%";

        } else {
            batString = " ";
        }
    }
        
    //Notifications Display Area
    function notesDisp() {

        if (hasComps == false || noteSets == null) {
            var tempNotes = System.getDeviceSettings();
            if (tempNotes != null) {
                noteSets = tempNotes.notificationCount;
            } else {
                noteSets = 0;
            }
        }

        if (noteSets != 0 && noteSets != null) {
            anyNotes = true;
            noteString = "N";
        } else {
            anyNotes = false;
            noteString = " ";
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
                    if (mSteps != null) {
                        stepString = Lang.format("$1$", [mSteps]);
                    } else {
                        stepString = " ";
                    }
                }
            } else {
                //Format zulu time
                var zTime = Gregorian.utcInfo(Time.now(), Time.FORMAT_MEDIUM);
                stepString = Lang.format("$1$:$2$", [zTime.hour.format("%02d"), zTime.min.format("%02d")])+"Z";
            }
        }

        function alarmDisp() {

            alSets = System.getDeviceSettings().alarmCount;

            if (alSets != 0) {
                alarmString = "A";
            } else {
                alarmString = " ";
            }
        } 

        function secondsDisplay(dc) {

            var screenWidth = dc.getWidth();
            var screenHeight = dc.getHeight();
            var centerX = screenWidth / 2;
            var centerY = screenHeight / 2;
            var mRadius = centerX < centerY ? centerX - 4: centerY - 4;
            var clockTime = System.getClockTime();
            var mSeconds = clockTime.sec;

            var mPen = 4;

            var mArc = 90 - (mSeconds * 6);

            dc.setPenWidth(mPen);
            dc.setColor(clockColorSet, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(centerX, centerY, mRadius, Graphics.ARC_CLOCKWISE, 90, mArc);

        }
    
    function onExitSleep() {
        lowPowerMode = false;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() {
        lowPowerMode = true;
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
