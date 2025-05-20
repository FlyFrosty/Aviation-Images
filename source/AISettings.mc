import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class AISettings{

    function initialize();

}

class AISettingsMenu extends WatchUi.Menu2 {

    var mySettings;

    function initialize () {
        Menu2.initialize(null);
        mySettings=new AISettings();
        Menu2.setTitle("Option");
        Menu2.addItem(new WatchUi.MenuItem("Steps", null, "steps", null));
        Menu2.addItem(new WatchUi.MenuItem("Zulu", null, "zulu", null));
    }

}

class AISettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    var menuSelector;

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();

        if (id.equals("steps")) {
            timeOrStep = 1;
        } else {
            timeOrStep = 0;
        }
        Application.Properties.setValue("TimeStep", menuSelector);
        onBack();
    }

}