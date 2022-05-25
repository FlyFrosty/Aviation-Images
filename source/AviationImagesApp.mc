import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Graphics;

    var timeOrStep;
    var showBat;
    var clockColorSet = Graphics.COLOR_DK_BLUE;
    var clockShadSet = Graphics.COLOR_TRANSPARENT;
    var subColorSet = Graphics.COLOR_LT_GRAY;
    var whichBG;
    var oldWhichBG;


class AviationImagesApp extends Application.AppBase {

    var clockColorNum;
    var clockShadNum;
    var subColorNum;

    function initialize() {
        AppBase.initialize();
        onSettingsChanged();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (whichBG == null) {whichBG=0;}
        onSettingsChanged();
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new AviationImagesView()];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
        //Set Global Settings variables

        clockColorNum = Properties.getValue("ClockColor");
        clockShadNum = Properties.getValue("ShadOpt");
        subColorNum = Properties.getValue("SubColor");
        timeOrStep = Properties.getValue("TimeStep");
        showBat = Properties.getValue("DispBatt");
        whichBG = Properties.getValue("BGOpt");

        colorUpdate();  //Apply the changes
        WatchUi.requestUpdate();
    }

        function colorUpdate(){
        //Get color settings
            //Primary Clock Colors
		        if (clockColorNum == 0) {
                    clockColorSet = Graphics.COLOR_BLACK;
                } else if (clockColorNum == 1){
				    clockColorSet = Graphics.COLOR_LT_GRAY;
                } else if (clockColorNum == 2) {
				    clockColorSet = Graphics.COLOR_BLUE;
                } else if (clockColorNum == 3) {
				    clockColorSet = Graphics.COLOR_DK_BLUE;
                } else if (clockColorNum == 4) {
				    clockColorSet = Graphics.COLOR_GREEN;
                } else if (clockColorNum == 5) {
				    clockColorSet = Graphics.COLOR_DK_GREEN;
                } else if (clockColorNum == 6) {
				    clockColorSet = Graphics.COLOR_RED;
                } else if (clockColorNum == 7) {
				    clockColorSet = Graphics.COLOR_DK_RED;
				} else if (clockColorNum == 8) {
				    clockColorSet = Graphics.COLOR_PURPLE;
                } else if (clockColorNum == 9) {
				    clockColorSet = Graphics.COLOR_YELLOW;
                } else {
				    clockColorSet = Graphics.COLOR_WHITE;
                }

            //Select shadowing
                if (clockShadNum == 0) {
                    clockShadSet = Graphics.COLOR_TRANSPARENT;
                } else if (clockShadNum == 1) {
                    clockShadSet = Graphics.COLOR_BLACK;
                } else if (clockShadNum == 2) {
                    clockShadSet = Graphics.COLOR_WHITE;
                } else {
                    clockShadSet = Graphics.COLOR_LT_GRAY;
                }

            //Select Sub items color
                if (subColorNum == 0) {
                    subColorSet = Graphics.COLOR_LT_GRAY;
                } else if (subColorNum == 1) {
                    subColorSet = Graphics.COLOR_DK_GRAY;
                } else if (subColorNum == 2) {
                    subColorSet = Graphics.COLOR_BLACK;
                } else {
                    subColorSet = Graphics.COLOR_WHITE;
                }

            //Show either zulu time or steps
            timeOrStep = Properties.getValue("TimeStep");

            //Show the battery or not
            showBat = Properties.getValue("DispBatt");
        
        }

}

function getApp() as AviationImagesApp {
    return Application.getApp() as AviationImagesApp;
}
