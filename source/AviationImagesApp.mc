import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

var view;

var showBat;
var clockColorNum;
var clockShadNum;
var subColorNum;
var showNotes;
var whichBG, whichBGUpdated;
var timeOrStep;
var oldClockColorNum, oldClockShadNum, oldSubColorNum, oldWhichBG;
var colorsUpdated;
var clockColorSet, clockShadSet, subColorSet;
var backImg;
var ForC;
var dispSecs;


class AviationImagesApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();

        ForC = System.getDeviceSettings().temperatureUnits;
        
        onSettingsChanged();

    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        view = new AviationImagesView();
        return [view, new AviationImagesViewDelegate(view) ] as Array<Views or InputDelegates>;

    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {

        if (clockColorNum != null) {oldClockColorNum = clockColorNum;}
        if (clockShadNum != null) {oldClockShadNum = clockShadNum;}
        if (subColorNum != null) {oldSubColorNum = subColorNum;}

        if (whichBG != null) {oldWhichBG = whichBG;}


        clockColorNum = Properties.getValue("ClockColor");
        clockShadNum = Properties.getValue("ShadOpt");
        subColorNum = Properties.getValue("SubColor");
        timeOrStep = Properties.getValue("TimeStep");
        showBat = Properties.getValue("DispBatt");
        whichBG = Properties.getValue("BGOpt");   
        showNotes = Properties.getValue("ShowNotes"); 
        dispSecs = Properties.getValue("SecOpt");

        ForC = System.getDeviceSettings().temperatureUnits;

        if (oldClockColorNum != clockColorNum || oldClockShadNum != clockShadNum
            || oldSubColorNum != subColorNum) {
                colorsUpdated = true;
        } else {
            colorsUpdated = false;
        }

        if (oldWhichBG != whichBG) {
            whichBGUpdated = true;
        }

        if (colorsUpdated) {
            colorUpdate();  //Apply the changes
        }

        if (whichBGUpdated) {
            whichBGUpdate();
        }

        WatchUi.requestUpdate();
    
    }

        function colorUpdate(){
        //Get color settings

		    if (clockColorNum == 0) {
			    clockColorSet = Graphics.COLOR_WHITE;
            } else if (clockColorNum == 1) {
			    clockColorSet = Graphics.COLOR_LT_GRAY;
            } else if (clockColorNum == 2) {
			    clockColorSet = Graphics.COLOR_DK_GRAY;
            } else if (clockColorNum == 3) {
			    clockColorSet = Graphics.COLOR_BLACK;
            } else if (clockColorNum == 4) {
			    clockColorSet = Graphics.COLOR_RED;
            } else if (clockColorNum == 5) {
			    clockColorSet = Graphics.COLOR_DK_RED;
            } else if (clockColorNum == 6) {
			    clockColorSet = Graphics.COLOR_ORANGE;
            } else if (clockColorNum == 7) {
			    clockColorSet = Graphics.COLOR_YELLOW;
            } else if (clockColorNum == 8) {
				clockColorSet = Graphics.COLOR_GREEN;
            } else if (clockColorNum == 9) {
			    clockColorSet = Graphics.COLOR_DK_GREEN;
            } else if (clockColorNum == 10) {
			    clockColorSet = Graphics.COLOR_BLUE;
            } else if (clockColorNum == 11) {
			    clockColorSet = Graphics.COLOR_DK_BLUE;
            } else if (clockColorNum == 12) {
			    clockColorSet = Graphics.COLOR_PURPLE;
            } else {
				clockColorSet = Graphics.COLOR_PINK;
            }

            //Select shadowing
            if (clockShadNum == 0) {
                clockShadSet = Graphics.COLOR_TRANSPARENT;
            } else if (clockShadNum == 1) {
                clockShadSet = Graphics.COLOR_BLACK;
            } else if (clockShadNum == 2) {
                clockShadSet = Graphics.COLOR_WHITE;
            } else if (clockShadNum == 3) {
                clockShadSet = Graphics.COLOR_LT_GRAY;
            }

            //Select Sub items color
            if (subColorNum == 0) {
                subColorSet = Graphics.COLOR_LT_GRAY;
            } else if (subColorNum == 1) {
                subColorSet = Graphics.COLOR_DK_GRAY;
            } else if (subColorNum == 2) {
                subColorSet = Graphics.COLOR_BLACK;
            } else if (subColorNum == 3) {
                subColorSet = Graphics.COLOR_WHITE;
            } else if (subColorNum == 4) {
                subColorSet = Graphics.COLOR_RED;
            } else if (subColorNum == 5) {
                subColorSet = Graphics.COLOR_GREEN;
            } else if (subColorNum == 6) {
                subColorSet = Graphics.COLOR_BLUE;
            } else if (subColorNum == 7) {
                subColorSet = Graphics.COLOR_PINK;
            }

        }

        function whichBGUpdate() {

            if (whichBG == 0) {
                backImg = null;
            } else if (whichBG == 1) {
                backImg = WatchUi.loadResource(Rez.Drawables.Brushed);
            } else if (whichBG == 2) {
                backImg = WatchUi.loadResource(Rez.Drawables.Landing);
            } else if (whichBG == 3) {
                backImg = WatchUi.loadResource(Rez.Drawables.HUD);
            } else if (whichBG == 4) {
                backImg = WatchUi.loadResource(Rez.Drawables.c17);
            } else if (whichBG == 5) {
                backImg = WatchUi.loadResource(Rez.Drawables.phenom);
            } else if (whichBG == 6) {
                backImg = WatchUi.loadResource(Rez.Drawables.nose);
            } else if (whichBG == 7) {
                backImg = WatchUi.loadResource(Rez.Drawables.Cub);
            } else if (whichBG == 8) {
                backImg = WatchUi.loadResource(Rez.Drawables.Tetons);
            } else if (whichBG ==9) {
                backImg = WatchUi.loadResource(Rez.Drawables.OK);
            } else {
                backImg = WatchUi.loadResource(Rez.Drawables.Sunset);
            }
        }

}



function getApp() as AviationImagesApp {
    return Application.getApp() as AviationImagesApp;
}